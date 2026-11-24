#!/usr/bin/env bash
# Extension E: DNS-based edge cutover from primary edge (Mac 2) to standby edge (Mac 1). Needs sudo here.
. "$(dirname "$0")/lib.sh"
edge(){ $CURL -m 5 -D - -o /dev/null $URL/api/status | awk -F': ' 'tolower($1)=="x-edge"{print $2}' | tr -d '\r'; }
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; sleep 1
h "1. Before: name -> $(resolve_cached), answered by edge: $(edge)"
h "2. Cutover: repoint $APP_HOST to the standby edge ($STANDBY_IP)"; sudo bash "$ROOT/scripts/dns.sh" set-record $STANDBY_IP; T0=$(date +%s)
h "3. Poll: cached clients keep hitting the old edge until the TTL ($DNS_TTL s) expires"
for i in $(seq 1 9); do printf '%2ss  dnsmasq=%-13s client cache=%-13s served by: %s\n' "$(( $(date +%s)-T0 ))" "$(dig +short $APP_HOST @$MAC1_IP)" "$(resolve_cached)" "$(edge)"; sleep 5; done
h "4. After TTL: new lookups go to the standby; service still balanced"; bash "$ROOT/scripts/lb-test.sh" 4
h "5. Cut back to the primary edge"; sudo bash "$ROOT/scripts/dns.sh" reset-record; sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; sleep 1; echo "served by: $(edge)"
