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


# Preparations

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

<style scoped>
table, thead, tbody, tr, th, td {
  background-color: transparent !important;
  border: none !important;
}
td:first-child {
  white-space: nowrap !important;
  vertical-align: top; 
}
</style>

| | |
| :--- | :--- |
| ⚙️ **create-vm**    | creates a new VM defined by parameters                    |
| ⚙️ **print-create-env-commands**  | reads `conf/env.yaml` file and prints the commands required to create the full environment  |
| ⚙️ **print-destroy-env-commands** | reads `conf/env.yaml` file, queries the current state, and prints the commands required to destroy the entire environment |


```bash
create-vm --id 10 --name dns.lab.nfgd.net --cpu 1 --ram 4096 --disks '[8]' --netconf '
     {
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
# Configure a Tunnel
## To access environment
![bg right:40% 30%](assets/pics/preparations/icon-identity-aware-proxy.svg)

```bash
* Generate a new ECDSA key with **PuTTYgen** and save it on your system
* Put the public key in ~/.ssh/authorized_keys on:
  * hypervisor (root)
  * deployment (deploy)

* Start PuTTY. Go to Connection -> SSH -> Auth -> Credentials. Load the Private Key
* Go to Connection -> Data. Put "root" for "Auto-login username"
* Go to Session. Put the IP of your hypervisor
* Put the name for the session - "hypervisor". Save.
* Press "Open" button, a new session should be opened

* Create a new session with PuTTY
  * Put 10.14.0.24 into "Host Name" field
  * Under Connection -> Data, put "deploy" for "Auto-login username"
  * Under Connection -> SSH -> Auth -> Credentials load the private key
* Go to Connection -> SSH -> Tunnels
  * Choose Dynamic
  * Source Port: 8888
  * Press "Add" button
* Go to Connection -> Proxy
  * Set type to "SSH to proxy and port forward"
  * Set Proxy hostname to "hypervisor"
  * Set port to 22
* Go to Session
  * Put "deployment" in "Saved Sessions"
  * Press "Save"
  * Press "Open"
```

---
# Configure Proxy
![bg right:40% 30%](assets/pics/preparations/icon-identity-aware-proxy.svg)
```bash
* Open Firefox
* Go to Settings
* Search for "proxy"
* Choose "Manual Configuration"
* Put "127.0.0.1" in SOCKS Host field, Port: 8888
* Choose SOCKS v5
```
