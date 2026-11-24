#!/usr/bin/env bash
# usage: edge.sh start|stop|reload|status     (port 8443, no sudo needed)
. "$(dirname "$0")/lib.sh"
conf=$ROOT/configs/nginx-edge.conf
case $1 in
  start)  mkdir -p $RUN_DIR; nginx -t -c "$conf" && nginx -c "$conf" && echo "edge up on :$EDGE_PORT";;
  stop)   nginx -c "$conf" -s stop && echo "edge stopped";;
  reload) nginx -t -c "$conf" && nginx -c "$conf" -s reload;;
  status) nc -z 127.0.0.1 $EDGE_PORT && echo "edge listening on :$EDGE_PORT" || echo "edge DOWN";;
  *) echo "usage: $0 start|stop|reload|status";;
esac
