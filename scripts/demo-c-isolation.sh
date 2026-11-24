#!/usr/bin/env bash
# Extension C: pf rules on each backend so only the edge (Mac 2) can reach 3001/3002.
# The owner of each Mac types their sudo password in THIS window (ssh -t).
. "$(dirname "$0")/lib.sh"
# Passwords are read from private files in $RUN_DIR (pw-phalak, pw-archit; mode 600, deleted after the run) and fed to `sudo -S`.
# If a file is missing, fall back to typing the password in this window (ssh -t).
rsudo(){ host=$1; who=$2; shift 2; if [ -f "$RUN_DIR/pw-$who" ]; then sshk $host "$*" < "$RUN_DIR/pw-$who" 2>&1; else sshkt $host "${*//sudo -S -p \'\'/sudo}"; fi | grep -v "^Connection\|Warning"; }
probe(){ printf '%-34s' "$1"; curl -s -m 4 -o /dev/null -w '%{http_code}\n' "$2" 2>/dev/null | sed 's/^000$/BLOCKED (connection refused)/'; }
h "BEFORE: this client (Mac 1, $MAC1_IP) can hit the backends directly"
probe "client -> Backend A :$BACKEND_A_PORT" http://$MAC3_IP:$BACKEND_A_PORT/api/status; probe "client -> Backend B :$BACKEND_B_PORT" http://$MAC4_IP:$BACKEND_B_PORT/api/status
h "APPLY pf rules (Phalak = Backend A, Archit = Backend B); rollback copies are saved on each Mac"
echo "-- Phalak Mac (Backend A):"; rsudo $PHALAK phalak "cd ~/cn-project && sudo -S -p '' bash scripts/isolate.sh apply A"
echo "-- Archit Mac (Backend B):"; rsudo $ARCHIT archit "cd ~/cn-project-repo && sudo -S -p '' bash scripts/isolate.sh apply B"
h "AFTER: direct access from the client is blocked"
probe "client -> Backend A :$BACKEND_A_PORT" http://$MAC3_IP:$BACKEND_A_PORT/api/status; probe "client -> Backend B :$BACKEND_B_PORT" http://$MAC4_IP:$BACKEND_B_PORT/api/status
h "...but the edge (Mac 2) still reaches both backends, so the service works by name"
bash "$ROOT/scripts/lb-test.sh" 4
h "ROLLBACK: restore original firewall config on both Macs"
rsudo $PHALAK phalak "sudo -S -p '' bash ~/cn-project/scripts/isolate.sh rollback"
rsudo $ARCHIT archit "sudo -S -p '' bash ~/cn-project-repo/scripts/isolate.sh rollback"
probe "client -> Backend A :$BACKEND_A_PORT (restored)" http://$MAC3_IP:$BACKEND_A_PORT/api/status; probe "client -> Backend B :$BACKEND_B_PORT (restored)" http://$MAC4_IP:$BACKEND_B_PORT/api/status
