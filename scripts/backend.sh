#!/usr/bin/env bash
# usage: backend.sh start|stop|status A|B     (no sudo needed)
. "$(dirname "$0")/lib.sh"
act=$1; id=$(echo "$2" | tr a-z A-Z)
case $id in A) f=server-a.py; port=$BACKEND_A_PORT;; B) f=server-b.py; port=$BACKEND_B_PORT;; *) echo "usage: $0 start|stop|status A|B"; exit 1;; esac
pidf=$RUN_DIR/backend-$id.pid
case $act in
  start) [ -f "$pidf" ] && kill -0 "$(cat $pidf)" 2>/dev/null && { echo "backend $id already running"; exit 0; }
         nohup python3 "$ROOT/source/$f" >"$RUN_DIR/backend-$id.log" 2>&1 & echo $! > "$pidf"; sleep 1
         curl -sI "http://127.0.0.1:$port/api/status" | grep -i "x-backend" && echo "backend $id up on :$port";;
  stop)  [ -f "$pidf" ] && kill "$(cat $pidf)" 2>/dev/null; rm -f "$pidf"; lsof -ti tcp:$port | xargs kill 2>/dev/null; echo "backend $id stopped";;
  status) curl -sI -m 2 "http://127.0.0.1:$port/api/status" | grep -i "x-backend" || echo "backend $id DOWN";;
esac
