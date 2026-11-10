#!/bin/bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License

set -e

# Router: everything that comes in on any interface except WAN_IF and MGMT_IF
# is forwarded to WAN_IF and NATed behind its address.
WAN_IF="eth0"
MGMT_IF="mgmt0"

# no dialogs (debconf, needrestart) and no reading from stdin: the script itself
# comes through the pipe of "curl | bash" and must not be consumed by apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

netplan apply

apt-get update
apt-get install -y nftables </dev/null

##############################################################################
# IP forwarding, persistent and right now
cat > /etc/sysctl.d/90-router.conf <<EOF
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null

##############################################################################
# Firewall / NAT
cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter;
    }
    chain forward {
        type filter hook forward priority filter; policy drop;
        # answers to connections opened from inside
        ct state established,related accept
        # all interfaces except WAN and management may go out via WAN
        iifname != { "lo", "${WAN_IF}", "${MGMT_IF}" } oifname "${WAN_IF}" accept
    }
    chain output {
        type filter hook output priority filter;
    }
}

table ip nat {
    chain postrouting {
        type nat hook postrouting priority srcnat;
        oifname "${WAN_IF}" masquerade
    }
}
EOF

nft -c -f /etc/nftables.conf
systemctl enable  nftables
systemctl restart nftables
