# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
"""cloud-init profile, provisioning by create-vm is finished."""


def test_cloud_init_disabled(host):
    # create-vm touches /etc/cloud/cloud-init.disabled at the end of provisioning
    out = host.run("cloud-init status").stdout.strip()
    assert out == "status: disabled", out
