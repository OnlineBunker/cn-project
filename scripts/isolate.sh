#!/usr/bin/env bash
# Extension C: only the edge (Mac 2) may reach this backend's port.
# usage: sudo isolate.sh apply A|B | rollback | status
. "$(dirname "$0")/lib.sh"
BK=/var/tmp/cn-pf-backup
case $1 in
  apply)
    id=$(echo "$2" | tr a-z A-Z); case $id in A) port=$BACKEND_A_PORT;; B) port=$BACKEND_B_PORT;; *) echo "need A|B"; exit 1;; esac
    mkdir -p $BK
    [ -f $BK/pf.conf.orig ] || cp /etc/pf.conf $BK/pf.conf.orig               # rollback copy of the config
    pfctl -sr > $BK/rules.before.txt 2>&1                                       # rollback copy of the live rules
    pfctl -s info 2>/dev/null | grep -i "^Status" > $BK/state.before.txt
    { cat /etc/pf.conf
      echo "# --- CN project isolation (port $port) ---"
      echo "pass in quick on lo0 all"
      echo "pass in quick inet proto tcp from $MAC2_IP to any port $port"
      echo "block return in quick inet proto tcp from any to any port $port"
    } > $BK/pf.cn.conf
    pfctl -nf $BK/pf.cn.conf 2>/dev/null && pfctl -f $BK/pf.cn.conf 2>&1 | grep -viE "ALTQ|flushing|ruleset added|pf.conf for further|^$"; pfctl -e 2>&1 | grep -viE "already|ALTQ|^$"
    echo "isolation active: only $MAC2_IP may reach :$port"; pfctl -sr 2>/dev/null | tail -3;;
  rollback)
    [ -f $BK/pf.conf.orig ] || { echo "no backup found"; exit 1; }
    pfctl -f $BK/pf.conf.orig 2>&1 | grep -viE "ALTQ|flushing|ruleset added|pf.conf for further|^$"
    grep -qi disabled $BK/state.before.txt && pfctl -d 2>&1 | grep -viE "ALTQ|^$"
    echo "rolled back to original firewall config"; pfctl -s info 2>/dev/null | grep -i "^Status";;
  status) pfctl -s info 2>/dev/null | grep -i "^Status"; pfctl -sr 2>/dev/null | grep -i "port = " || echo "(no CN rules)";;
  *) echo "usage: sudo $0 apply A|B | rollback | status";;
esac
