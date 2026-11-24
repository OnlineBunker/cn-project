#!/usr/bin/env bash
# usage: inventory.sh <name>   Records this Mac's network facts (Task A) into evidence/inventory-<name>.txt
. "$(dirname "$0")/lib.sh"
out=$ROOT/evidence/inventory-$1.txt
{
echo "# Network inventory - $1 - $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "hostname:   $(scutil --get LocalHostName 2>/dev/null || hostname)"
echo "interface:  en0"
echo "ipv4:       $(ipconfig getifaddr en0)"
echo "netmask:    $(ifconfig en0 | awk '/inet /{print $4}')  (hex; 0xffffe000 = /19)"
echo "mac addr:   $(ifconfig en0 | awk '/ether/{print $2}')"
echo "gateway:    $(route -n get default 2>/dev/null | awk '/gateway/{print $2}')"
echo "dns order:  $(scutil --dns | awk '/nameserver\[/{print $3}' | awk '!s[$0]++' | tr '\n' ' ')"
echo; echo "## reachability (ping -c2)"
for m in "Mac1 $MAC1_IP" "Mac2 $MAC2_IP" "Mac3 $MAC3_IP" "Mac4 $MAC4_IP"; do set -- $m; printf '%s %-14s ' $1 $2; ping -c2 -t3 $2 2>/dev/null | awk '/packets transmitted/{printf "%s ", $0} /round-trip/{print "avg " $4}' | sed 's|/[0-9.]* ms||'; echo; done
echo; echo "## listening services of interest"
lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==1 || /:(3001|3002|8443)/' | cut -c1-110
echo; echo "## name resolution from this Mac"; dig +short $APP_HOST | head -2
} > "$out" 2>&1; echo "wrote $out"
