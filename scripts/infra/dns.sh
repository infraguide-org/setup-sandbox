#!/bin/bash

# 1. Disable systemd-resolved to free up Port 53
echo "Stopping systemd-resolved..."
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Ensure /etc/resolv.conf is a real file for the host to use
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. Install Dnsmasq
echo "Installing Dnsmasq..."
apt update && apt install -y dnsmasq

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
local=/wrx.sckt.net/
domain=wrx.sckt.net
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
10.14.0.10   dns.mgmt.wrx.sckt.net
10.14.0.17   registry.mgmt.wrx.sckt.net
10.14.0.19   proxy.mgmt.wrx.sckt.net
10.14.0.24   deployment.mgmt.wrx.sckt.net
10.14.0.25   recorder.mgmt.wrx.sckt.net
10.14.0.32   controller01.mgmt.wrx.sckt.net
10.14.0.33   controller02.mgmt.wrx.sckt.net
10.14.0.34   controller03.mgmt.wrx.sckt.net
10.14.0.40   network01.mgmt.wrx.sckt.net
10.14.0.41   network02.mgmt.wrx.sckt.net
10.14.0.42   network03.mgmt.wrx.sckt.net
10.14.0.48   monitor01.mgmt.wrx.sckt.net
10.14.0.52   testing.mgmt.wrx.sckt.net
10.14.0.64   compute01.mgmt.wrx.sckt.net
10.14.0.65   compute02.mgmt.wrx.sckt.net
10.14.0.66   compute03.mgmt.wrx.sckt.net
10.14.0.67   compute04.mgmt.wrx.sckt.net
10.14.0.72   compute11.mgmt.wrx.sckt.net
10.14.0.73   compute12.mgmt.wrx.sckt.net
10.14.0.74   compute13.mgmt.wrx.sckt.net
10.14.0.75   compute14.mgmt.wrx.sckt.net
10.14.0.128  cephmon01.mgmt.wrx.sckt.net
10.14.0.129  cephmon02.mgmt.wrx.sckt.net
10.14.0.130  cephmon03.mgmt.wrx.sckt.net
10.14.0.136  cephgra01.mgmt.wrx.sckt.net
10.14.0.144  cephosd01.mgmt.wrx.sckt.net
10.14.0.145  cephosd02.mgmt.wrx.sckt.net
10.14.0.146  cephosd03.mgmt.wrx.sckt.net
10.14.0.147  cephosd04.mgmt.wrx.sckt.net
10.14.0.148  cephosd05.mgmt.wrx.sckt.net
10.14.0.149  cephosd06.mgmt.wrx.sckt.net
10.14.0.150  cephosd07.mgmt.wrx.sckt.net
10.14.0.151  cephosd08.mgmt.wrx.sckt.net

# strg
10.20.21.128  cephmon01.strg.wrx.sckt.net
10.20.21.129  cephmon02.strg.wrx.sckt.net
10.20.21.130  cephmon03.strg.wrx.sckt.net
10.20.21.136  cephgra01.strg.wrx.sckt.net
10.20.21.144  cephosd01.strg.wrx.sckt.net
10.20.21.145  cephosd02.strg.wrx.sckt.net
10.20.21.128  cephmon01.strg.wrx.sckt.net
10.20.21.146  cephosd03.strg.wrx.sckt.net
10.20.21.147  cephosd04.strg.wrx.sckt.net
10.20.21.148  cephosd05.strg.wrx.sckt.net
10.20.21.149  cephosd06.strg.wrx.sckt.net
10.20.21.150  cephosd07.strg.wrx.sckt.net
10.20.21.151  cephosd08.strg.wrx.sckt.net
# strg services
10.20.21.135  s3.strg.wrx.sckt.net

# os

# os services
10.20.8.35    int.os.wrx.sckt.net

# services
10.34.10.10   dns.services.wrx.sckt.net
10.34.10.17   registry.services.wrx.sckt.net
10.34.10.19   proxy.services.wrx.sckt.net
10.34.10.25   recorder.services.wrx.sckt.net
10.34.10.35   dashboard.openstack.services.wrx.sckt.net
10.34.10.35   keystone.os.svc.wrx.sckt.net
# 10.34.10.35    novncproxy.os.svc.wrx.sckt.net
10.20.8.35    novncproxy.os.svc.wrx.sckt.net
10.34.10.135  dashboard.ceph.services.wrx.sckt.net
10.34.10.135  s3.storage.wrx.sckt.net s3.svc.wrx.sckt.net s3.services.wrx.sckt.net

# infra nodes
10.14.0.8     hypervisor.wrx.sckt.net
10.14.0.10    dns.wrx.sckt.net
10.14.0.17    registry.wrx.sckt.net
10.14.0.19    proxy.wrx.sckt.net
10.14.0.24    deployment.wrx.sckt.net
10.14.0.25    recorder.wrx.sckt.net
EOF

echo "Restarting Dnsmasq..."
systemctl restart dnsmasq
systemctl enable dnsmasq
