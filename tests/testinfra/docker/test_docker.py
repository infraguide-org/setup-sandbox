# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
"""Docker profile, for servers that run containers (docker-ce comes from create-vm)."""

# ~2 MB image from quay.io, through the Harbor proxy cache project "quay"
# (registry.sh), plain http via insecure-registries in /etc/docker/daemon.json
PULL_IMAGE = "registry.lab.nfgd.net/quay/prometheus/busybox:latest"


def test_docker_running(host):
    docker = host.service("docker")
    assert docker.is_running
    assert docker.is_enabled


def test_docker_ps(host):
    # deploy is not in the docker group, so the daemon is asked as root
    with host.sudo():
        cmd = host.run("docker ps")
    assert cmd.rc == 0, cmd.stderr
    assert cmd.stdout.startswith("CONTAINER ID"), cmd.stdout


def test_pull_from_registry(host):
    with host.sudo():
        cmd = host.run(f"docker pull {PULL_IMAGE}")
        # leave the server as it was, the next run pulls again
        host.run(f"docker rmi {PULL_IMAGE}")
    assert cmd.rc == 0, cmd.stderr
