#!/bin/bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
set -e
##############################################################################
# vars
NFGD_HOME="/infraguide/setup-sandbox"
REF="main"

LAB_NAME="$1"
if [ -z "$1" ]
then
  echo "Lab name not set, exiting ..."
  exit 1
fi

##############################################################################
mkdir -p $NFGD_HOME
cd $NFGD_HOME

mkdir -p /var/lib/dnsmasq/hosts.d

echo "Creating DNS Records"
curl -fsSL -O https://nfgd.net/raw/setup-sandbox/scripts/dns/dns_conf-to-hosts.py
curl -fsSL -O https://nfgd.net/raw/setup-sandbox/scripts/dns/server_conf-to-hosts.py
curl -fsSL -O https://nfgd.net/raw/$LAB_NAME/conf/env.yaml

python3 dns_conf-to-hosts.py    env.yaml
python3 server_conf-to-hosts.py env.yaml

##############################################################################
# no dialogs (debconf, needrestart) and no reading from stdin: the script itself
# comes through the pipe of "curl | bash" and must not be consumed by apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Disable systemd-resolved to free up Port 53
echo "Stopping systemd-resolved..."
systemctl stop systemd-resolved    || true
systemctl disable systemd-resolved || true

# Ensure /etc/resolv.conf is a real file for the host to use
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Install Dnsmasq
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

# log-queries
EOF

systemctl enable  dnsmasq
systemctl restart dnsmasq
