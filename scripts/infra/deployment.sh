#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License

set -e

# no dialogs (debconf, needrestart) and no reading from stdin: the script itself
# comes through the pipe of "curl | bash" and must not be consumed by apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

apt-get update

apt-get install -y \
  crudini          \
  pipx </dev/null

SYS_USER_NAME=deploy

sudo -i -u $SYS_USER_NAME bash << "AS_SYS_USER"
cat >> ~/.ssh/config <<EOF
Host hypervisor hypervisor.lab.nfgd.net
  User root

Host *.mgmt *.mgmt.lab.nfgd.net *.lab.nfgd.net
  User  deploy

Host *
  User                  deploy
  StrictHostKeyChecking no
  UserKnownHostsFile    /dev/null
EOF

pipx install tmuxp

cat >> ~/.profile <<EOF

alias lab-stack='tmuxp load -y ~/lab-openstack/conf/tmuxp.yaml'
EOF

# cd ~
# git clone https://github.com/infraguide-org/lab-openstack.git

mkdir -p lab-openstack && \
curl -sSL https://github.com/infraguide-org/lab-openstack/archive/HEAD.tar.gz | \
tar -xz -C lab-openstack --strip-components=1



ln -s ~/lab-openstack/deploy/kolla-ansible openstack
ln -s ~/lab-openstack/deploy/cephadm       ceph

cat >> ~/.profile <<"EOF"
##############################################################################
# openstack vars

export OPENSTACK_DIR=~/openstack
KOLLA_ANSIBLE_RELEASE=20 # OS 2025.1
VENV_PATH=~/venv/kolla-ansible-$KOLLA_ANSIBLE_RELEASE

if [ -z "$VIRTUAL_ENV" -a -L ~/venv/openstack ]
then
  source ~/venv/openstack/bin/activate
fi
export ARA_HOME=$VIRTUAL_ENV/lib/python3.12/site-packages/ara


ADMIN_OPENRC_FILE=$OPENSTACK_DIR/custom-config/lab/admin-openrc.sh
if [ -f $ADMIN_OPENRC_FILE ]
then
  source  $ADMIN_OPENRC_FILE
fi

export PATH=~/openstack/bin/:$PATH
export PS1="[\u@\h \W|\[\e[1;32m\]\$OS_USERNAME.\$OS_PROJECT_NAME\[\e[m\]]\$"
source <(openstack complete)
EOF

AS_SYS_USER
