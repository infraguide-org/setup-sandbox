#!/usr/bin/env python3
"""Generate dnsmasq hosts file <hostname>.<domain> from server_conf in env.yml.

Usage: generate-server-hosts-entries.py env.yml [/var/lib/dnsmasq/hosts.d]
Output: <outdir>/servers
"""
import ipaddress
import os
import sys
import tempfile

import yaml

MGMT_PREFIX = "10.14.0"   # management network, last octet = id


def main():
    src = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "/var/lib/dnsmasq/hosts.d"

    with open(src) as f:
        servers = yaml.safe_load(f)["server_conf"]

    lines = []
    for s in servers:
        ip = f"{MGMT_PREFIX}.{int(s['id'])}"
        ipaddress.ip_address(ip)  # sanity check
        lines.append((ip, f"{s['hostname']}.{s['domain']}"))

    lines.sort(key=lambda x: ipaddress.ip_address(x[0]))

    os.makedirs(outdir, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=outdir, prefix=".servers.")
    with os.fdopen(fd, "w") as out:
        out.write(f"# generated from {os.path.basename(src)}, do not edit\n")
        for ip, name in lines:
            out.write(f"{ip}\t{name}\n")
    os.chmod(tmp, 0o644)
    os.replace(tmp, os.path.join(outdir, "servers"))
    print(f"servers: {len(lines)} entries")


if __name__ == "__main__":
    main()
