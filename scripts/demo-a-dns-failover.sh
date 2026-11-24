#!/usr/bin/env bash
# Extension A (run on a client Mac that lists primary + backup DNS; primary runs on THIS Mac, needs sudo)
. "$(dirname "$0")/lib.sh"
h(){ printf '\n\033[1m== %s\033[0m\n' "$*"; }
h "Client DNS order"; networksetup -getdnsservers Wi-Fi
h "1. Primary up:  dig @$MAC1_IP"; dig +noall +answer +stats $APP_HOST @$MAC1_IP | grep -E "IN|SERVER"
h "2. STOP primary dnsmasq (Mac 1)"; sudo bash "$ROOT/scripts/dns.sh" stop; sleep 1
h "3. Direct query to primary now fails (DNS service down)"; dig +time=2 +tries=1 +noall +answer $APP_HOST @$MAC1_IP; echo "exit=$?  (no answer / timed out)"
h "4. Client still resolves via backup ($MAC4_IP), default resolver order"; dig +time=2 +tries=1 +noall +answer +stats $APP_HOST | grep -E "IN|SERVER"
h "5. Service still reachable BY NAME over HTTPS"; bash "$ROOT/scripts/lb-test.sh" 2
h "6. Restore primary"; sudo bash "$ROOT/scripts/dns.sh" start primary; sleep 1; dig +noall +answer $APP_HOST @$MAC1_IP
