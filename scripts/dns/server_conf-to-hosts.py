#!/usr/bin/env python3
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
"""Generate dnsmasq hosts files from server_conf in env.yaml.

Each server gets two entries, last octet of the IP = id:
  * <hostname>.<domain>       IP from the network whose `domain` matches the server's domain
  * <hostname>.<mgmt domain>  IP from the management network, always generated,
                              every host has an interface there
The mgmt domain is network_conf.management.domain (required). A primary
entry is skipped if no network in network_conf carries the server's domain.

Usage: server_conf-to-hosts.py env.yaml [/var/lib/dnsmasq/hosts.d]
Output: one file per domain, <outdir>/<domain>
"""
import ipaddress
import os
import sys
import tempfile
from collections import defaultdict

import yaml

MGMT_NETWORK = "management"


def main():
    src = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "/var/lib/dnsmasq/hosts.d"

    with open(src) as f:
        conf = yaml.safe_load(f)

    networks = conf["network_conf"]
    mgmt_domain = networks[MGMT_NETWORK].get("domain")
    if not mgmt_domain:
        sys.exit(f"network_conf.{MGMT_NETWORK}.domain is not set")
    domain_to_net = {n["domain"]: name for name, n in networks.items() if n.get("domain")}

    records = defaultdict(set)  # domain -> {(ip, fqdn)}
    for s in conf["server_conf"]:
        for domain in (s["domain"], mgmt_domain):
            net_name = domain_to_net.get(domain)
            if net_name is None:
                continue
            if net_name not in s.get("networks", []):
                sys.exit(f"{s['hostname']}: not attached to network '{net_name}'")
            net = ipaddress.ip_network(networks[net_name]["addr"])
            ip = net.network_address + int(s["id"])
            if ip not in net:
                sys.exit(f"{s['hostname']}: id {s['id']} outside of {net}")
            records[domain].add((ip, f"{s['hostname']}.{domain}"))

    os.makedirs(outdir, exist_ok=True)
    for domain, entries in sorted(records.items()):
        # write atomically so dnsmasq never reads a half-written file
        fd, tmp = tempfile.mkstemp(dir=outdir, prefix=f".{domain}.")
        with os.fdopen(fd, "w") as out:
            out.write(f"# generated from {os.path.basename(src)}, do not edit\n")
            for ip, name in sorted(entries):
                out.write(f"{ip}\t{name}\n")
        os.chmod(tmp, 0o644)
        os.replace(tmp, os.path.join(outdir, domain))
        print(f"{domain}: {len(entries)} entries")


if __name__ == "__main__":
    main()
