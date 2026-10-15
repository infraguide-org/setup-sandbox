#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
#
##############################################################################
# vars
DIR="conf"
REF="main"
DEST="$DIR"

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
cd /root
git clone https://github.com/infraguide-org/setup-sandbox.git

cd setup-sandbox

###############################################################################
# Fetch the configs for the lab
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "https://codeload.github.com/${REPO}/tar.gz/${REF}" \
  | tar -xz -C "$tmp" --strip-components=1

if [ ! -d "${tmp}/${DIR}" ]
then
  echo "Directory '${DIR}' not found in ${REPO}@${REF}" >&2
  exit 1
fi

mkdir -p "$DEST"
cp -a ${tmp}/${DIR}/* $DEST/

##############################################################################
# ssh config
./scripts/print-ssh-config  >> ~/.ssh/config
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
cat /root/.ssh/id_ed25519.pub >> /home/debian/.ssh/authorized_keys

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
