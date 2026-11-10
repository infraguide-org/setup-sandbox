# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
"""Registry profile, for the Harbor server set up by scripts/infra/registry.sh."""


def test_harbor_containers(host):
    # deploy is not in the docker group, so the daemon is asked as root
    with host.sudo():
        names = host.check_output("docker ps --format '{{.Names}}'").split()
    assert any("harbor" in n for n in names), names


def test_port_80_listening(host):
    sockets = host.socket.get_listening_sockets()
    assert any(s.startswith("tcp://") and s.endswith(":80") for s in sockets), sockets


def test_portal_answers(host):
    cmd = host.run("curl -sS -f --max-time 10 http://localhost")
    assert cmd.rc == 0, cmd.stderr
    assert "Harbor" in cmd.stdout, cmd.stdout[:200]
