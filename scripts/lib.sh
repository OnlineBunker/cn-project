#!/usr/bin/env bash
# Shared helpers. Source this from other scripts.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; . "$ROOT/team.env"; set +a
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
mkdir -p "$RUN_DIR"
URL="https://$APP_HOST:$EDGE_PORT"
CURL="curl -s --cacert $ROOT/tls/team-ca.crt"   # validates the cert; never -k
