#!/bin/bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
set -e

# no dialogs (debconf, needrestart) and no reading from stdin: the script itself
# comes through the pipe of "curl | bash" and must not be consumed by apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# 1. Disable systemd-resolved to free up Port 53
echo "Stopping systemd-resolved..."
systemctl stop systemd-resolved    || true
systemctl disable systemd-resolved || true

# Ensure /etc/resolv.conf is a real file for the host to use
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. Install Dnsmasq
echo "Installing Dnsmasq..."
apt-get update
apt-get install -y -o Dpkg::Options::=--force-confold dnsmasq </dev/null

# 3. Create the Configuration
echo "Configuring Dnsmasq..."
cat <<EOF > /etc/dnsmasq.conf
# Basic Settings
domain-needed
bogus-priv
no-resolv
no-hosts
# Upstream DNS (Google)
server=8.8.8.8
# Listen on all interfaces
interface=mgmt0
interface=srvc0
except-interface=eth*
except-interface=lo
bind-interfaces

# Local Domain Settings
local=/lab.nfgd.net/
domain=lab.nfgd.net
expand-hosts
# Cache size
cache-size=1000

hostsdir=/var/lib/dnsmasq/hosts.d
EOF

# 4. Add your A records to /etc/hosts
echo "Adding custom A records to /etc/hosts..."
# We use a marker to make the script repeatable without duplicating lines
mkdir -p /var/lib/dnsmasq/hosts.d

cat > /var/lib/dnsmasq/hosts.d/hosts <<EOF
# mgmt
10.14.0.10   dns.mgmt.lab.nfgd.net
10.14.0.17   registry.mgmt.lab.nfgd.net
10.14.0.19   proxy.mgmt.lab.nfgd.net
10.14.0.24   deployment.mgmt.lab.nfgd.net
10.14.0.25   recorder.mgmt.lab.nfgd.net
10.14.0.32   controller01.mgmt.lab.nfgd.net
10.14.0.33   controller02.mgmt.lab.nfgd.net
10.14.0.34   controller03.mgmt.lab.nfgd.net
10.14.0.40   network01.mgmt.lab.nfgd.net
10.14.0.41   network02.mgmt.lab.nfgd.net
10.14.0.42   network03.mgmt.lab.nfgd.net
10.14.0.48   monitor01.mgmt.lab.nfgd.net
10.14.0.52   testing.mgmt.lab.nfgd.net
10.14.0.64   compute01.mgmt.lab.nfgd.net
10.14.0.65   compute02.mgmt.lab.nfgd.net
10.14.0.66   compute03.mgmt.lab.nfgd.net
10.14.0.67   compute04.mgmt.lab.nfgd.net
10.14.0.72   compute11.mgmt.lab.nfgd.net
10.14.0.73   compute12.mgmt.lab.nfgd.net
10.14.0.74   compute13.mgmt.lab.nfgd.net
10.14.0.75   compute14.mgmt.lab.nfgd.net
10.14.0.128  cephmon01.mgmt.lab.nfgd.net
10.14.0.129  cephmon02.mgmt.lab.nfgd.net
10.14.0.130  cephmon03.mgmt.lab.nfgd.net
10.14.0.136  cephgra01.mgmt.lab.nfgd.net
10.14.0.144  cephosd01.mgmt.lab.nfgd.net
10.14.0.145  cephosd02.mgmt.lab.nfgd.net
10.14.0.146  cephosd03.mgmt.lab.nfgd.net
10.14.0.147  cephosd04.mgmt.lab.nfgd.net
10.14.0.148  cephosd05.mgmt.lab.nfgd.net
10.14.0.149  cephosd06.mgmt.lab.nfgd.net
10.14.0.150  cephosd07.mgmt.lab.nfgd.net
10.14.0.151  cephosd08.mgmt.lab.nfgd.net

# strg
10.20.21.128  cephmon01.strg.lab.nfgd.net
10.20.21.129  cephmon02.strg.lab.nfgd.net
10.20.21.130  cephmon03.strg.lab.nfgd.net
10.20.21.136  cephgra01.strg.lab.nfgd.net
10.20.21.144  cephosd01.strg.lab.nfgd.net
10.20.21.145  cephosd02.strg.lab.nfgd.net
10.20.21.128  cephmon01.strg.lab.nfgd.net
10.20.21.146  cephosd03.strg.lab.nfgd.net
10.20.21.147  cephosd04.strg.lab.nfgd.net
10.20.21.148  cephosd05.strg.lab.nfgd.net
10.20.21.149  cephosd06.strg.lab.nfgd.net
10.20.21.150  cephosd07.strg.lab.nfgd.net
10.20.21.151  cephosd08.strg.lab.nfgd.net
# strg services
10.20.21.135  s3.strg.lab.nfgd.net

# os

# os services
10.20.8.35    int.os.lab.nfgd.net

# services
10.34.10.10   dns.services.lab.nfgd.net
10.34.10.17   registry.services.lab.nfgd.net
10.34.10.19   proxy.services.lab.nfgd.net
10.34.10.25   recorder.services.lab.nfgd.net
10.34.10.35   dashboard.openstack.services.lab.nfgd.net
10.34.10.35   keystone.os.svc.lab.nfgd.net
# 10.34.10.35    novncproxy.os.svc.lab.nfgd.net
10.20.8.35    novncproxy.os.svc.lab.nfgd.net
10.34.10.135  dashboard.ceph.services.lab.nfgd.net
10.34.10.135  s3.storage.lab.nfgd.net s3.svc.lab.nfgd.net s3.services.lab.nfgd.net

# infra nodes
10.14.0.8     hypervisor.lab.nfgd.net
10.14.0.10    dns.lab.nfgd.net
10.14.0.17    registry.lab.nfgd.net
10.14.0.19    proxy.lab.nfgd.net
10.14.0.24    deployment.lab.nfgd.net
10.14.0.25    recorder.lab.nfgd.net
EOF

echo "Restarting Dnsmasq..."
systemctl restart dnsmasq
systemctl enable dnsmasq
