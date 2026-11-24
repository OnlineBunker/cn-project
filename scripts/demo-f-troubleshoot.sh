#!/usr/bin/env bash
# Extension F: systematic layer-by-layer diagnosis. Healthy run, then an injected DNS fault found at the TCP layer.
. "$(dirname "$0")/lib.sh"
flush(){ sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; sleep 1; }
h "Healthy system"; bash "$ROOT/scripts/diagnose.sh"
h "FAULT INJECTED: $APP_HOST now points at a machine with no edge on :$EDGE_PORT"; sudo bash "$ROOT/scripts/dns.sh" set-record $MAC3_IP; flush
bash "$ROOT/scripts/diagnose.sh"
h "FIX: restore the correct record"; sudo bash "$ROOT/scripts/dns.sh" reset-record; flush
bash "$ROOT/scripts/diagnose.sh"
