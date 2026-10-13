#!/usr/bin/env bash

apt-get update

apt-get install -y \
  crudini          \
  pipx

SYS_USER_NAME=deploy

sudo -i -u $SYS_USER_NAME bash << "AS_SYS_USER"
cat >> ~/.ssh/config <<EOF
Host hypervisor hypervisor.wrx.sckt.net
  User root

Host *.mgmt *.mgmt.wrx.sckt.net *.wrx.sckt.net
  User  deploy

Host *
  User                  deploy
  StrictHostKeyChecking no
  UserKnownHostsFile    /dev/null
EOF

pipx install tmuxp

cat >> ~/.profile <<EOF

alias wrx-stack='tmuxp load -y ~/openstack-workshop/conf/tmuxp.yaml'
EOF

# cd ~
# git clone https://github.com/codecap/openstack-workshop.git

mkdir -p openstack-workshop && \
curl -sSL https://github.com/codecap/openstack-workshop/archive/HEAD.tar.gz | \
tar -xz -C openstack-workshop --strip-components=1



ln -s ~/openstack-workshop/kolla-ansible openstack
ln -s ~/openstack-workshop/cephadm       ceph

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


ADMIN_OPENRC_FILE=$OPENSTACK_DIR/custom-config/wrx/admin-openrc.sh
if [ -f $ADMIN_OPENRC_FILE ]
then
  source  $ADMIN_OPENRC_FILE
fi

export PATH=~/openstack/bin/:$PATH
export PS1="[\u@\h \W|\[\e[1;32m\]\$OS_USERNAME.\$OS_PROJECT_NAME\[\e[m\]]\$"
source <(openstack complete)
EOF

AS_SYS_USER
