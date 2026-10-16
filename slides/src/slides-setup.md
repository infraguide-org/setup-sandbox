---
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
title:       Setup Sandbox
description: Setup a sandbox for infraguid labs
author:      infraguide.org
keywords:    openstack,ceph,workshops,operations,troubleshoouting
transition: cover
order: 1
backgroundImage: url(assets/background.jpg)
paginate: true
footer: "[infraguide.org](https://infraguide.org) | Questions or need a guided workshop? → ping@infraguide.org | [Imprint](https://infraguide.org/imprint/) · [Privacy](https://infraguide.org/privacy/)"
style: |
  footer {
    font-size: 7px;
    text-align: left;
  }
  .mermaid {
    text-align: center;
  }
  .mermaid svg {
    width:  50%;
    height: 50%;    
  }
  table {
    border-collapse: collapse;
  }
  th, td {
    border: 1px solid #9fc9de;
  }
  th {
    background-color: #2b6f94;
    color: #ffffff;
  }
  tr:nth-child(odd) td {
    background-color: #ffffff;
  }
  tr:nth-child(even) td {
    background-color: #e3f1f8;
  }
---
<script type="module">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
mermaid.initialize({ startOnLoad: true, theme: 'default' });

// Register the "logos" pack (contains AWS, GCP, tech logos)
// https://icones.js.org/collection/logos
// https://icones.js.org/collection/mdi
  mermaid.registerIconPacks([
    {
      name: 'logos:laptop',
      loader: () => fetch('https://unpkg.com/@iconify-json/logos@1/icons.json').then(res => res.json()),
    },
    {
      name: 'mdi',
      loader: () => fetch('https://unpkg.com/@iconify-json/mdi@1/icons.json').then(res => res.json()),
    }
  ]);

</script>


# Prepare a Bare-Metal Server to Host the Labs
![bg right:45% 25%](https://infraguide.org/assets/logo/icon.svg)

---
# Deployment

<div class="mermaid">
architecture-beta
    group deployment[Deployment]
      service deploy(mdi:laptop)[deploy] in deployment
    group env[Environment]
      group os[OpenStack] in env
        service server_os(mdi:server) in os
      group ceph[Ceph]    in env
        service server_ceph(mdi:server) in ceph
    %% connections
    deploy{group}:R -- L:server_os{group}
    deploy{group}:R -- L:server_ceph{group}
</div>

---
# Configuration Data
![bg right:45% 25%](assets/pics/preparations/icon-config.svg)
[Link](https://github.com/infraguide-org/lab-openstack/blob/main/conf/env.yaml)
```yaml
resolve_conf:
  nameservers:
    - 10.14.0.10
  searchdomains: []
##############################################################################
network_conf:
  public:
    iface:       pblc0
    bridgename:  vimbr0
    addr:        10.10.61.0/24
    netmask:     255.255.255.0
    gateway:     10.10.61.1/24
    nameservers: [10.10.11.99]
  management:
    iface:   mgmt0
    addr:    10.14.0.0/24
  services:
    iface:   srvc0
    addr:    10.34.10.0/24
...
##############################################################################
server_conf:
  - hostname:    "dns"
...
```

---
# Scripts
![bg right:45% 25%](https://infraguide.org/assets/logo/icon.svg)

<style scoped>
td:first-child {
  white-space: nowrap !important;
  vertical-align: top; 
}
pre {
  font-size: 0.6em;
}
</style>

| Script | Description |
| :--- | :--- |
| ⚙️ **create-vm**    | creates a new VM defined by parameters                    |
| ⚙️ **print-create-env-commands**  | reads `conf/env.yaml` file and prints the commands required to create the full environment  |
| ⚙️ **print-destroy-env-commands** | reads `conf/env.yaml` file, queries the current state, and prints the commands required to destroy the entire environment |


```bash
create-vm --id 10 --name dns.lab.nfgd.net \
          --cpu 1 --ram 4096 --disks '[8]' \
          --netconf '{
  "mgmt0": {"ip": "10.14.0.10/24",  "macaddr": "bc:24:11:99:04:0a"},
  "srvc0": {"ip": "10.34.10.10/24", "macaddr": "bc:24:11:99:06:0a"}
}'
```

---
# How to use scripts
![bg right:45% 25%](assets/pics/preparations/icon-easybuild.svg)

```bash
# Create a new environment
print-create-env-commands | bash

# Destroy the whole environment
print-destroy-env-commands | bash

# If you need to rebuild only a set or a single server, use grep with a matching filter
print-destroy-env-commands | grep <NODE_FILTER> | bash
print-create-env-commands  | grep <NODE_FILTER> | bash
```


---
# Prepare the lab environment
![bg right:40% 30%](assets/pics/preparations/icon-tools-hammer.svg)

```bash
export LAB_NAME=<LAB_NAME> # lab-openstack, lab-ceph, ...

# Install and Configure 
curl -sSL nfgd.net/setup/sandbox     | bash; reboot

# Import a VM to be used as template
curl -sSL nfgd.net/setup/template-vm | bash

# Create the full lab environment
curl -sSL nfgd.net/setup/$LAB_NAME   | bash
```

---
# Access the Lab Environment
![bg right:40% 40%](assets/pics/preparations/icon-identity-aware-proxy.svg)

Browser traffic is sent to **127.0.0.1:8888**<br/>
SSH carries it through the hypervisor into the lab network.<br/>

```text
+-----------+  SSH  +------------+  SSH  +------------+     +-------------+
| Browser   |------>| hypervisor |------>| deployment |---->| Lab         |
|           |       |            |       |            |     | Environment |
+-----------+       +------------+       +------------+     +-------------+
Your PC             Bare-metal
                    server
```

---
# Configure a Tunnel
## Windows (PuTTY)
![bg right:45% 25%](https://infraguide.org/assets/logo/icon.svg)

<style scoped>
section { font-size: 22px; }
</style>

* Generate a new ECDSA key with **PuTTYgen** and save it on your system
* Put the public key in `~/.ssh/authorized_keys` on:
  * hypervisor (`root`)
  * deployment (`deploy`)
* Create the two PuTTY sessions, `hypervisor` first, then `deployment`

---
# Configure a Tunnel
## Windows (PuTTY) - sessions

<style scoped>
section { font-size: 18px; }
table { font-size: 18px; }
</style>

| PuTTY category             | Field               | `hypervisor`         | `deployment`                  |
|----------------------------|---------------------|----------------------|-------------------------------|
| Session                    | Host Name           | IP of the hypervisor | IP of the deployment node     |
| Connection -> Data         | Auto-login username | `root`               | `deploy`                      |
| SSH -> Auth -> Credentials | Private key file    | your private key     | your private key              |
| SSH -> Tunnels             | Source port         |                      | `8888`                        |
| SSH -> Tunnels             | Type                |                      | Dynamic                       |
| Connection -> Proxy        | Proxy type          |                      | SSH to proxy and port forward |
| Connection -> Proxy        | Proxy hostname      |                      | `hypervisor`                  |
| Connection -> Proxy        | Port                |                      | `22`                          |
| Session                    | Saved Sessions      | `hypervisor`         | `deployment`                  |

In "SSH -> Tunnels" press "Add" after setting source port and type.
In "Session" press "Save" after entering the session name.

---
# Configure a Tunnel
## Windows (PuTTY) - check
![bg right:45% 25%](https://infraguide.org/assets/logo/icon.svg)

<style scoped>
section { font-size: 22px; }
</style>

Check that the SOCKS5 port is listening:

```bat
:: In cmd on your PC, with the deployment session open
:: 127.0.0.1:8888 LISTENING means the tunnel is up, no line means it is not
netstat -an | findstr 8888
```

---
# Configure a Tunnel
## Linux and macOS (OpenSSH)
![bg right:45% 25%](https://infraguide.org/assets/logo/icon.svg)

<style scoped>
section { font-size: 20px; }
</style>

```bash
# On your PC
HYPERVISOR_IP=<IP of the hypervisor>
DEPLOYMENT_IP=<IP of the deployment node>
KEY=~/.ssh/infraguide-lab

# Generate the key, readable only by you
ssh-keygen -t ed25519 -f "$KEY"
chmod 600 "$KEY"

# Add the sessions to ~/.ssh/config
cat >> ~/.ssh/config <<EOF
Host hypervisor
    HostName $HYPERVISOR_IP
    User root
    IdentityFile $KEY

Host deployment
    HostName $DEPLOYMENT_IP
    User deploy
    IdentityFile $KEY
    ProxyJump hypervisor
    DynamicForward 8888
EOF

# Show the public key, add it by hand to ~/.ssh/authorized_keys of root on the
# hypervisor and of deploy on the deployment node
cat "$KEY.pub"
```

---
# Configure your Browser
## To use the SOCKS5 Proxy

<style scoped>
section { font-size: 20px; }
table { font-size: 20px; }
</style>

| Browser | Windows          | Linux            | macOS            |
|---------|------------------|------------------|------------------|
| Firefox | Network Settings | Network Settings | Network Settings |
| Chrome  | Launch flag      | Launch flag      | System proxy     |
| Edge    | Launch flag      | Launch flag      | System proxy     |
| Safari  | not available    | not available    | System proxy     |

---
# Configure your Browser
## Proxy settings
![bg right:45% 25%](https://infraguide.org/assets/logo/icon.svg)

<style scoped>
section { font-size: 20px; }
table { font-size: 20px; }
</style>

| Setting                                 | Value       |
|-----------------------------------------|-------------|
| Proxy mode                              | Manual      |
| SOCKS Host                              | 127.0.0.1   |
| Port                                    | 8888        |
| SOCKS version                           | v5          |
| Proxy DNS when using SOCKS v5 (Firefox) | on          |
| HTTP, HTTPS and FTP proxy               | empty       |

---
# Configure your Browser
## Chrome and Edge launch flags
![bg right:45% 25%](https://infraguide.org/assets/logo/icon.svg)

<style scoped>
section { font-size: 20px; }
</style>

Start the browser with a separate profile and the proxy flag.

```bat
:: Windows
chrome.exe     --proxy-server="socks5://127.0.0.1:8888" --user-data-dir="%TEMP%\lab-profile"
msedge.exe     --proxy-server="socks5://127.0.0.1:8888" --user-data-dir="%TEMP%\lab-profile"
```
```bash
# Linux
google-chrome  --proxy-server="socks5://127.0.0.1:8888" --user-data-dir=/tmp/lab-profile
microsoft-edge --proxy-server="socks5://127.0.0.1:8888" --user-data-dir=/tmp/lab-profile
```
