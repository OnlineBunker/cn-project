#!/usr/bin/env bash
# Shared helpers. Source this from other scripts.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; . "$ROOT/team.env"; set +a
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
mkdir -p "$RUN_DIR"
URL="https://$APP_HOST:$EDGE_PORT"
CURL="curl -s --cacert $ROOT/tls/team-ca.crt"   # validates the cert; never -k
sshk() { ssh -i "$HOME/.ssh/cn_team_ed25519" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 "$@"; }
sshkt() { ssh -t -i "$HOME/.ssh/cn_team_ed25519" -o IdentitiesOnly=yes -o ConnectTimeout=5 "$@"; }   # with a tty, for sudo prompts typed on this Mac
PHALAK=phalaksharma@$MAC3_IP; ARCHIT=architgosain@$MAC4_IP; PREET=preetvardhan@$MAC2_IP
h(){ printf '\n\033[1m== %s\033[0m\n' "$*"; }
resolve_cached(){ dscacheutil -q host -a name $APP_HOST | awk '/ip_address/{print $2; exit}'; }   # client resolver (honours TTL cache)
