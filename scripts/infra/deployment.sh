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
  pipx             \
  </dev/null

SYS_USER_NAME=deploy

sudo -i -u $SYS_USER_NAME bash << "AS_SYS_USER"
cat >> ~/.ssh/config <<EOF
Host hypervisor hypervisor.lab.nfgd.net
  User root

Host *.mgmt
  HostName %h.lab.nfgd.net

Host *
  User                  deploy
  StrictHostKeyChecking no
  UserKnownHostsFile    /dev/null
EOF

pipx install tmuxp

AS_SYS_USER
