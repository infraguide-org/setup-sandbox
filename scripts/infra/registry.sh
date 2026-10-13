#!/usr/bin/env bash
HARBOR_USER="admin"
HARBOR_PASS="Harbor12345"
HARBOR_VERSION="2.10.0"
HARBOR_DATA_PATH="/var/lib/docker/volumes/data/_data/"


docker volume create data

# Download
wget https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-online-installer-v${HARBOR_VERSION}.tgz
tar xzvf harbor-online-installer-v${HARBOR_VERSION}.tgz

# Configure
cd harbor
cp harbor.yml.tmpl harbor.yml

# set admin password
sed -e "s/^harbor_admin_password:.*/harbor_admin_password: $HARBOR_PASS/" -i harbor.yml
# change default data path
sed -e "s#^data_volume:.*#data_volume: $HARBOR_DATA_PATH#" -i harbor.yml
# change the hostname
sed -e "s/^hostname:.*/hostname: registry.wrx.sckt.net/"   -i harbor.yml
# switch off https
sed '/^https:/,/private_key:/ s/^/#/'                      -i harbor.yml

# Install
./install.sh ; sleep 15;


# Setupt Proxy Repository
curl -sS -u "$HARBOR_USER:$HARBOR_PASS" -X POST "http://localhost/api/v2.0/registries" \
 -H "Content-Type: application/json" \
 -d '{
   "name": "quay-upstream",
   "type": "quay",
   "url": "https://quay.io"
 }'

curl -sS -u "$HARBOR_USER:$HARBOR_PASS" -X POST "http://localhost/api/v2.0/projects" \
 -H "Content-Type: application/json" \
 -d '{
   "project_name": "quay",
   "public": true,
   "metadata": {
     "public": "true",
     "proxy_cache": "true"
   },
   "registry_id": 1
 }'
