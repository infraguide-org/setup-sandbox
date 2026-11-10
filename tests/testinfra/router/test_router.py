# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
"""Router profile, for the server set up by scripts/infra/router.sh."""
import ipaddress

import pytest

WAN_IF = "eth0"


@pytest.fixture(scope="module")
def ruleset(host):
    with host.sudo():
        return host.check_output("nft list ruleset")


def test_internet_reachable(host):
    # ifconfig.io answers with the public IP of the caller
    cmd = host.run("curl -sS --max-time 10 ifconfig.io")
    assert cmd.rc == 0, cmd.stderr
    try:
        ipaddress.ip_address(cmd.stdout.strip())
    except ValueError:
        pytest.fail(f"curl ifconfig.io: {cmd.stdout!r}")


def test_ip_forward(host):
    assert host.sysctl("net.ipv4.ip_forward") == 1


def test_nftables_active(host):
    nftables = host.service("nftables")
    assert nftables.is_enabled
    # oneshot unit, "active (exited)" once the ruleset is loaded
    assert host.run("systemctl is-active nftables").stdout.strip() == "active"


def test_nat_masquerade(ruleset):
    assert f'oifname "{WAN_IF}" masquerade' in ruleset, ruleset


def test_forward_to_wan(ruleset):
    assert "ct state established,related accept" in ruleset, ruleset
    assert f'oifname "{WAN_IF}" accept' in ruleset, ruleset
