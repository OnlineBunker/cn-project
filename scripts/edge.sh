#!/usr/bin/env bash
# usage: edge.sh start|stop|reload|status     (port 8443, no sudo needed)
. "$(dirname "$0")/lib.sh"
conf=$ROOT/configs/nginx-edge.conf
# EDGE_SUDO=1: run nginx as root. macOS "Local Network" privacy can block a user-launched nginx from reaching some LAN hosts (EHOSTUNREACH); root is not subject to it.
S=""; [ "$EDGE_SUDO" = 1 ] && S="sudo"
case $1 in
  start)  mkdir -p $RUN_DIR; $S nginx -t -c "$conf" && $S nginx -c "$conf" && echo "edge up on :$EDGE_PORT";;
  stop)   $S nginx -c "$conf" -s stop && echo "edge stopped";;
  reload) $S nginx -t -c "$conf" && $S nginx -c "$conf" -s reload;;
  status) nc -z 127.0.0.1 $EDGE_PORT && echo "edge listening on :$EDGE_PORT" || echo "edge DOWN";;
  *) echo "usage: $0 start|stop|reload|status";;
esac
