#!/usr/bin/env bash
# Task F / demo step 7: Cache-Control + ETag, then a conditional request returning 304.
# Requests are retried until a backend that sends cache headers answers (load balancing alternates backends).
. "$(dirname "$0")/lib.sh"
h "1. Response headers (curl -I): look for Cache-Control and ETag"
for i in 1 2 3 4 5 6; do hdr=$($CURL -I $URL/api/status | tr -d '\r'); echo "$hdr" | grep -qi '^etag:' && break; done
echo "$hdr" | grep -iE '^HTTP|x-backend|cache-control|etag'
etag=$(echo "$hdr" | awk -F': ' 'tolower($1)=="etag"{print $2}')
[ -z "$etag" ] && { echo "no backend returned an ETag"; exit 1; }
h "2. Conditional request: If-None-Match: $etag  (GET; the client already has a copy)"
for i in 1 2 3 4 5 6; do r=$($CURL -D - -o /dev/null -H "If-None-Match: $etag" $URL/api/status | tr -d '\r'); echo "$r" | head -1 | grep -q 304 && break; done
echo "$r" | grep -iE '^HTTP|x-backend|cache-control|etag'
h "3. Explain"
echo "fresh cache hit : within max-age the client reuses its copy, NO request is sent"
echo "conditional     : after max-age the client asks 'still $etag?' -> 304, headers only, no body"
echo "full request    : no cached copy (or ETag changed) -> 200 with the whole body"
