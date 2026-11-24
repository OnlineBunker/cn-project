#!/usr/bin/env bash
# usage: lb-test.sh [N]   Client-side: N requests by NAME, show which backend/edge answered.
. "$(dirname "$0")/lib.sh"
n=${1:-6}; a=0; b=0; fail=0
for i in $(seq 1 "$n"); do
  h=$($CURL -m 6 -D - -o /dev/null "$URL/api/status") ; code=$(echo "$h" | head -1 | tr -d '\r')
  be=$(echo "$h" | awk -F': ' 'tolower($1)=="x-backend"{print $2}' | tr -d '\r'); ed=$(echo "$h" | awk -F': ' 'tolower($1)=="x-edge"{print $2}' | tr -d '\r')
  echo "req $i: ${code:-NO RESPONSE} | X-Backend: ${be:--} | X-Edge: ${ed:--}"
  case $be in A) a=$((a+1));; B) b=$((b+1));; *) fail=$((fail+1));; esac
done
echo "---- A=$a  B=$b  failed=$fail"
