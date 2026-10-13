#!/bin/bash
REGISTRY=registry.wrx.sckt.net:80
IMAGE_NAME=$REGISTRY/quay/osism/ara-server:1.6.1

apt-get update; apt-get install podman -y

cat > /etc/containers/registries.conf  <<EOF
[[registry]]
location = "$REGISTRY"
insecure = true
EOF

# FIXME: remove --network host, --publish -> 8000, debugging needed
#        ARA config then needed on ansible side


podman volume create ara

mkdir /etc/ara
cat > /etc/ara/environment <<EOF
ARA_ALLOWED_HOSTS=['127.0.0.1', 'loalhost', '10.14.0.25', 'recorder.services.wrx.sckt.net', 'recorder.wrx.sckt.net']
# ARA_DEBUG=True
ARA_API_CLIENT=http
ARA_API_PASSWORD=P@ssword
ARA_API_SERVER=http://localhost:8000
ARA_API_TIMEOUT=15
ARA_API_USERNAME=ara
ARA_CALLBACK_THREADS=4
ARA_CORS_ORIGIN_ALLOW_ALL=true
ARA_READ_LOGIN_REQUIRED=false
ARA_WORKER_CLASS=sync
ARA_WORKERS=5
ARA_WRITE_LOGIN_REQUIRED=true
EOF

cat > /etc/systemd/system/ara.service <<EOF
[Unit]
Description=Podman container-ara-server.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm \
        -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run \
        --network host \
        --cidfile=%t/%n.ctr-id \
        --cgroups=no-conmon \
        --rm \
        --sdnotify=conmon \
        --replace \
        -d \
        --name=ara-server \
        --env-file /etc/ara/environment \
        --volume ara:/home/ara-server \
        --publish 8000:8000 $IMAGE_NAME
ExecStop=/usr/bin/podman stop \
        --ignore -t 10 \
        --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm \
        -f \
        --ignore -t 10 \
        --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable --now ara.service
