#!/usr/bin/env bash

##############################################################################
# Tools

# On the baremetal node as root
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
git clone https://github.com/codecap/openstack-workshop.git

# ssh
cd openstack-workshop
./scripts/print-ssh-config  >> ~/.ssh/config
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
cat /root/.ssh/id_ed25519.pub >> /home/debian/.ssh/authorized_keys

##############################################################################
# Install proxmox

# ansible
cd  010_preparations/ansible/

python3 -m venv ~/venv/lab
source ~/venv/lab/bin/activate

# Install ansible
pip3 install -U pip
pip3 install -r requirements.txt

# Install requiremnets for ansible
ansible-galaxy role       install -r requirements.yml
ansible-galaxy collection install -r requirements.yml

ansible-playbook playbooks/proxmox/install.yml
