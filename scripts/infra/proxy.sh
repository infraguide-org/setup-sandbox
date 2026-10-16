#!/bin/bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License

set -e

# no dialogs (debconf, needrestart) and no reading from stdin: the script itself
# comes through the pipe of "curl | bash" and must not be consumed by apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

netplan apply

apt-get update
apt-get install -y squid </dev/null
mkdir -p  /etc/squid/conf.d
chmod 644 /etc/squid/conf.d
echo "http_access allow localnet" > /etc/squid/conf.d/60-lab.conf
systemctl enable  squid
systemctl restart squid


apt-get install -y chrony </dev/null
mkdir -p /etc/chrony/conf.d
cat > /etc/chrony/conf.d/70-lab.conf <<EOF
allow 10.14.0.0/24
local stratum 10
bindaddress $(ip -br a | grep mgmt0 | awk '{print $NF}' | cut -d / -f1)
EOF
systemctl enable  chrony
systemctl restart chrony
