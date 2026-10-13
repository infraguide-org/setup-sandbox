#!/bin/bash
neplan apply

apt update
apt install squid -y
mkdir     /etc/squid/conf.d
chmod 644 /etc/squid/conf.d
echo "http_access allow localnet" > /etc/squid/conf.d/60-wrx.conf
systemctl enable  squid
systemctl restart squid


apt install chrony -y
mkdir -p /etc/chrony/conf.d
cat > /etc/chrony/conf.d/70-wrx.conf <<EOF
allow 10.14.0.0/24
local stratum 10
bindaddress $(ip -br a | grep mgmt0 | awk '{print $NF}' | cut -d / -f1)
EOF
systemctl enable  chrony
systemctl restart chrony
