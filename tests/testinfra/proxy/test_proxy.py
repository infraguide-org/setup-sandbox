# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
"""Proxy profile, for the squid server set up by scripts/infra/proxy.sh."""
import ipaddress

import pytest


def test_squid_running(host):
    squid = host.service("squid")
    assert squid.is_running
    assert squid.is_enabled


def test_port_3128_listening(host):
    sockets = host.socket.get_listening_sockets()
    assert any(s.startswith("tcp://") and s.endswith(":3128") for s in sockets), sockets


# ifconfig.io answers with the public IP of the caller
@pytest.mark.parametrize("proxy", ["", "--proxy http://localhost:3128"], ids=["direct", "via-squid"])
def test_curl_ifconfig_io(host, proxy):
    cmd = host.run(f"curl -sS --max-time 10 {proxy} ifconfig.io")
    assert cmd.rc == 0, cmd.stderr
    try:
        ipaddress.ip_address(cmd.stdout.strip())
    except ValueError:
        pytest.fail(f"curl {proxy} ifconfig.io: {cmd.stdout!r}")
