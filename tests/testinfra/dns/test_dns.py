# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
"""DNS profile, for the server set up by scripts/infra/dns.sh."""
import ipaddress

import pytest

MGMT_IFACE = "mgmt0"


def is_ipv4(value):
    try:
        return isinstance(ipaddress.ip_address(value), ipaddress.IPv4Address)
    except ValueError:
        return False


def test_dnsmasq_running(host):
    dnsmasq = host.service("dnsmasq")
    assert dnsmasq.is_running
    assert dnsmasq.is_enabled


@pytest.mark.parametrize("proto", ["tcp", "udp"])
def test_port_53_listening(host, proto):
    # bind-interfaces: dnsmasq listens on the interface addresses, not on 0.0.0.0
    sockets = host.socket.get_listening_sockets()
    assert any(s.startswith(f"{proto}://") and s.endswith(":53") for s in sockets), sockets


@pytest.mark.parametrize("name", ["dns.lab.nfgd.net", "ifconfig.io"])
def test_resolve_via_mgmt_ip(host, name):
    mgmt_ip = next(a for a in host.interface(MGMT_IFACE).addresses if is_ipv4(a))
    out = host.check_output(f"dig +short +time=2 +tries=1 @{mgmt_ip} {name}")
    assert any(is_ipv4(line) for line in out.splitlines()), f"{name} via {mgmt_ip}: {out!r}"


def test_curl_ifconfig_io(host):
    # ifconfig.io answers with the public IP of the caller
    out = host.check_output("curl -sS --max-time 10 ifconfig.io").strip()
    try:
        ipaddress.ip_address(out)
    except ValueError:
        pytest.fail(f"curl ifconfig.io: {out!r}")
