# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
"""Deployment profile, for the server set up by scripts/infra/deployment.sh."""
import ipaddress

import pytest

def test_tmuxp_present(host):
    # installed with pipx for deploy into ~/.local/bin, a login shell puts it on PATH
    cmd = host.run("bash -lc 'tmuxp --version'")
    assert cmd.rc == 0, cmd.stderr


# airgapped: soft, create-vm sets the proxy in /etc/profile.d/proxy.sh,
# testinfra runs commands without a login shell, so they go through bash -l
def test_curl_ifconfig_io_via_proxy(host):
    # ifconfig.io answers with the public IP of the caller, here the proxy
    cmd = host.run("bash -lc 'curl -sS -v --max-time 10 ifconfig.io'")
    assert cmd.rc == 0, cmd.stderr
    # curl -v names the proxy it took from the environment
    assert "Uses proxy env variable" in cmd.stderr, cmd.stderr
    try:
        ipaddress.ip_address(cmd.stdout.strip())
    except ValueError:
        pytest.fail(f"curl ifconfig.io: {cmd.stdout!r}")
