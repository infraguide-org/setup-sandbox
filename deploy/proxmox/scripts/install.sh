#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
#
##############################################################################
# vars
NFGD_HOME="/infraguide/setup-sandbox"
REF="main"

if [ -z "$LAB_NAME" ]
  then
    echo "REPO var is missing" >&2
    exit 1
fi
REPO="infraguide-org/$LAB_NAME"
exit
##############################################################################
# Tools
apt-get update

apt-get remove grub-cloud-amd64 -y
apt-get dist-upgrade            -y

apt-get  install -y   \
 bind9-dnsutils  \
 curl            \
 dnsmasq         \
 git             \
 htop            \
 isc-dhcp-client \
 jq              \
 nftables        \
 python3-venv    \
 tcpdump         \
 tmux            \
 vim             \
 yq

##############################################################################
# Checkout
git clone https://github.com/infraguide-org/setup-sandbox.git "$NFGD_HOME"
cd "$NFGD_HOME"

##############################################################################
# Install proxmox

cd  deploy/proxmox/ansible/

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
