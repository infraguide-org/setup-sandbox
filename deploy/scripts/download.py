#!/usr/bin/env python3
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
import functools
import http.server
import os
import ssl

PUB_DIR = os.environ.get("PUB_DIR", "/infraguide/setup-sandbox/public")
PORT = int(os.environ.get("PORT", "8443"))
TLS_CERT = os.environ.get("TLS_CERT", "/infraguide/setup-sandbox/conf/download.crt")
TLS_KEY = os.environ.get("TLS_KEY", "/infraguide/setup-sandbox/conf/download.key")

handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=PUB_DIR)
httpd = http.server.HTTPServer(("0.0.0.0", PORT), handler)

ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(TLS_CERT, TLS_KEY)
httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

httpd.serve_forever()
