#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
#
##############################################################################
# vars
NFGD_HOME="/infraguide/setup-sandbox"
REF="main"

##############################################################################
# Tools
apt-get update

apt-get remove grub-cloud-amd64 -y
apt-get dist-upgrade            -y

apt-get  install -y   \
 arping          \
 bind9-dnsutils  \
 curl            \
 dnsmasq         \
 git             \
 htop            \
 iputils-ping    \
 isc-dhcp-client \
 jq              \
 nftables        \
 python3-debian  \
 python3-venv    \
 tcpdump         \
 tmux            \
 vim             \
 yq

##############################################################################
# ssh-keygen
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
cat /root/.ssh/id_ed25519.pub >> /home/debian/.ssh/authorized_keys

##############################################################################
# Checkout
git clone https://github.com/infraguide-org/setup-sandbox.git "$NFGD_HOME"
cd "$NFGD_HOME"

##############################################################################
# Publish the generated keypair for temporary download over HTTPS
# ./public is gitignored - never gets checked in
PUB_DIR="$NFGD_HOME/public"
TOKEN="$(openssl rand -hex 32)"
echo "$TOKEN" > "$NFGD_HOME/conf/token"
touch "$NFGD_HOME/conf/download-enabled"

mkdir -p "$PUB_DIR/$TOKEN"
ln -s ~/.ssh/id_ed25519     "$PUB_DIR/$TOKEN/infraguide"
ln -s ~/.ssh/id_ed25519.pub "$PUB_DIR/$TOKEN/infraguide.pub"

openssl req -x509 -newkey rsa:2048 -keyout "$NFGD_HOME/conf/download.key" -out "$NFGD_HOME/conf/download.crt" \
  -days 1 -nodes -subj "/CN=$(hostname -f 2>/dev/null || hostname)"

cp deploy/scripts/download.service /etc/systemd/system/download.service
systemctl daemon-reload
systemctl enable --now download.service

# Watches download.service's logs every minute; once the private key has
# been fetched successfully it removes conf/download-enabled, which stops
# the service from being (re)started. conf/token is left in place.
chmod +x deploy/scripts/check-download.sh
cp deploy/scripts/check-download.cron /etc/cron.d/check-download

##############################################################################
# Install proxmox

cd  deploy/ansible/

python3 -m venv ~/venv/lab
source ~/venv/lab/bin/activate

# Install ansible
pip3 install -U pip
pip3 install -r requirements.txt

# Install requiremnets for ansible
ansible-galaxy role       install -r requirements.yml
ansible-galaxy collection install -r requirements.yml

# quick fix for lae.proxmox role
touch /etc/default/grub

# Run
ansible-playbook playbooks/proxmox/install.yml
