#!/bin/bash

# Install post-pve-install.sh                                               📋
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"

# Prepare a new template for VMs
# https://www.croit.io/blog/how-to-use-cloud-images-for-faster-vm-deployment-in-proxmox-ve

TEMPL_ID=9000

curl -sS -o /tmp/noble-server-cloudimg-amd64.img \
https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

qm create $TEMPL_ID \
--name ubuntu-2404-cloud-init \
--description "Ubuntu 24.04 Cloud Init template" \
--ostype l26 \
--cpu cputype=host \
--cores 1 \
--sockets 1 \
--memory 2048 \
--scsihw virtio-scsi-pci \
--net0 virtio,bridge=vmbr0

qm importdisk $TEMPL_ID /tmp/noble-server-cloudimg-amd64.img local

qm set $TEMPL_ID --scsi0 local:$TEMPL_ID/vm-$TEMPL_ID-disk-0.raw
qm set $TEMPL_ID --boot c --bootdisk scsi0

qm set $TEMPL_ID --serial0 socket --vga serial0

qm set $TEMPL_ID --ide2 local:cloudinit

qm set $TEMPL_ID --ipconfig0 ip=dhcp
qm cloudinit update $TEMPL_ID

qm template $TEMPL_ID
