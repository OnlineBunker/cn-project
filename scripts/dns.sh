#!/usr/bin/env bash
# usage: sudo dns.sh start primary|backup | stop | status | set-record <ip> | reset-record
# Records file is shared by primary and backup; set-record is used for the TTL / cutover demos.
. "$(dirname "$0")/lib.sh"
write_records() { printf '%s %s %s\n' "$1" "$APP_HOST" "$API_HOST" > "$RUN_DIR/records.hosts"; }
case $1 in
  start) cfg=$ROOT/configs/dnsmasq-$2.conf; [ -f "$cfg" ] || { echo "usage: $0 start primary|backup"; exit 1; }
         [ -f "$RUN_DIR/records.hosts" ] || write_records "$MAC2_IP"
         dnsmasq --test -C "$cfg" && dnsmasq -C "$cfg" && echo "dnsmasq ($2) up on :53";;
  stop)  [ -f "$RUN_DIR/dnsmasq.pid" ] && kill "$(cat $RUN_DIR/dnsmasq.pid)" && echo "dnsmasq stopped" || echo "not running";;
  status) pgrep -fl dnsmasq || echo "dnsmasq DOWN";;
  set-record) write_records "$2"; kill -HUP "$(cat $RUN_DIR/dnsmasq.pid)"; echo "$APP_HOST -> $2";;
  reset-record) write_records "$MAC2_IP"; kill -HUP "$(cat $RUN_DIR/dnsmasq.pid)"; echo "$APP_HOST -> $MAC2_IP";;
  *) echo "usage: sudo $0 start primary|backup | stop | status | set-record <ip> | reset-record";;
esac
