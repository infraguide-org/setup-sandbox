#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
set -euo pipefail

ENABLED_FILE="/infraguide/setup-sandbox/conf/download-enabled"
DISABLED_FILE="/infraguide/setup-sandbox/conf/download-disabled"
TOKEN_FILE="/infraguide/setup-sandbox/conf/token"

[ -f "$ENABLED_FILE" ] || exit 0
[ -f "$TOKEN_FILE" ] || exit 0

TOKEN="$(cat "$TOKEN_FILE")"

if journalctl -u download.service --no-pager -q 2>/dev/null \
  | grep -qE "\"GET /${TOKEN}/infraguide HTTP/[0-9.]+\" 200"; then
  systemctl stop download.service
  systemctl disable download.service
  mv "$ENABLED_FILE" "$DISABLED_FILE"
fi
