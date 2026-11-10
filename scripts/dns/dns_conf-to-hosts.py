#!/usr/bin/env python3
"""Generate dnsmasq hosts files from dns_conf YAML.

Usage: generate-host-entries.py dns.yml [/var/lib/dnsmasq/hosts.d]
"""
import ipaddress
import os
import sys
import tempfile

import yaml


def main():
    src = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "/var/lib/dnsmasq/hosts.d"

    with open(src) as f:
        entries = yaml.safe_load(f)["dns_conf"]["entries"]

    os.makedirs(outdir, exist_ok=True)

    for group, hosts in entries.items():
        lines = []
        for name, ip in sorted((hosts or {}).items()):
            ipaddress.ip_address(str(ip))  # fail early on a bad address
            lines.append(f"{ip}\t{name}")

        # write atomically so dnsmasq never reads a half-written file
        fd, tmp = tempfile.mkstemp(dir=outdir, prefix=f".{group}.")
        with os.fdopen(fd, "w") as out:
            out.write(f"# generated from {os.path.basename(src)}, do not edit\n")
            out.write("\n".join(lines) + "\n")
        os.chmod(tmp, 0o644)
        os.replace(tmp, os.path.join(outdir, group))
        print(f"{group}: {len(lines)} entries")


if __name__ == "__main__":
    main()
