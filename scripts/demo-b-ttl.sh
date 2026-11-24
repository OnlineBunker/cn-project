#!/usr/bin/env bash
# Extension B: TTL + controlled record change. Run on a client Mac that uses Mac 1 as DNS (needs sudo here).
. "$(dirname "$0")/lib.sh"
NEW=$MAC3_IP
flush(){ sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; }
flush; sleep 1
h "TTL on the record (dnsmasq local-ttl)"; dig +noall +answer $APP_HOST @$MAC1_IP
h "1. Client resolves and caches the name"; echo "client resolver -> $(resolve_cached)"
h "2. Change the record on the DNS server to $NEW"; sudo bash "$ROOT/scripts/dns.sh" set-record $NEW; T0=$(date +%s)
h "3. Poll every 5s: DNS server (dig) vs client cache (system resolver)"
for i in $(seq 1 9); do
  printf '%2ss  dnsmasq says %-14s | client cache says %s\n' "$(( $(date +%s)-T0 ))" "$(dig +short $APP_HOST @$MAC1_IP)" "$(resolve_cached)"; sleep 5; done
h "4. Change record back, then compare before/after a manual cache flush"
sudo bash "$ROOT/scripts/dns.sh" reset-record; resolve_cached >/dev/null
echo "before flush: client cache -> $(resolve_cached)   (dnsmasq already says $(dig +short $APP_HOST @$MAC1_IP))"
flush; sleep 1; echo "after  flush: client cache -> $(resolve_cached)"
