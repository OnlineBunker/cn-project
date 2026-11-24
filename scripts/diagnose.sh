#!/usr/bin/env bash
# Extension F: layer-by-layer diagnosis from a client. Stops at the first broken layer.
. "$(dirname "$0")/lib.sh"
ok(){ echo "  [ OK ] $*"; }; bad(){ echo "  [FAIL] $*"; echo ">>> Broken layer: $LAYER"; exit 1; }
echo "1) DNS - does the name resolve, and to what?"; LAYER=DNS
for s in $MAC1_IP $MAC4_IP; do r=$(dig +short +time=2 +tries=1 $APP_HOST @$s | head -1); [ -n "$r" ] && echo "     @$s -> $r" || echo "     @$s -> (no answer)"; done
ip=$(dig +short +time=2 +tries=1 $APP_HOST | head -1); [ -z "$ip" ] && ip=$(dscacheutil -q host -a name $APP_HOST | awk '/ip_address/{print $2; exit}')
[ -n "$ip" ] && ok "client resolves $APP_HOST -> $ip" || bad "client cannot resolve $APP_HOST (check System DNS servers / dnsmasq)"
[ "$ip" = "$MAC2_IP" ] && ok "answer is the expected edge $MAC2_IP" || echo "  [WARN] expected $MAC2_IP (wrong record or standby active?)"
echo "2) TCP - can we open a socket to $ip:$EDGE_PORT?"; LAYER="TCP (network/port/firewall)"
nc -z -G 3 $ip $EDGE_PORT && ok "port $EDGE_PORT open" || bad "no TCP connection (service down, wrong port, or firewall)"
echo "3) TLS - handshake and certificate validation"; LAYER="TLS (certificate/handshake)"
o=$(echo | openssl s_client -connect $ip:$EDGE_PORT -servername $APP_HOST -CAfile $ROOT/tls/team-ca.crt -verify_return_error 2>&1)
echo "$o" | grep -q "Verify return code: 0" && ok "certificate valid ($(echo "$o" | grep -m1 'subject=' ))" || bad "TLS failed: $(echo "$o" | grep -m1 -E 'Verify return code|error')"
echo "4) HTTP/application"; LAYER="Application (edge or backends)"
code=$($CURL -m 6 -o /dev/null -w '%{http_code}' $URL/api/status)
[ "$code" = 200 ] && ok "HTTP 200" || bad "HTTP $code (502 = edge works but backends down; 404/other = app/config)"
echo "All layers healthy."
