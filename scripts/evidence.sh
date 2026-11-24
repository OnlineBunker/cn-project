#!/usr/bin/env bash
# usage: evidence.sh <evidence-name> <script-file> [--sudo]
# Opens a Terminal window on THIS Mac, runs the script (which may ssh to other Macs), and screenshots that window.
# --sudo: window first runs `sudo -v` so the person at this Mac types the password, then clears the screen.
. "$(dirname "$0")/lib.sh"
name=$1; script=$2; pre=""; [ "$3" = "--sudo" ] && pre="sudo -v && clear && "
done_f=$RUN_DIR/ev-$name.done; rm -f "$done_f"
out=$ROOT/evidence/$name.png
res=$(osascript -e "tell application \"Terminal\" to activate" \
  -e "tell application \"Terminal\" to do script \"cd $ROOT && ${pre}bash $script; touch $done_f\"")
wid=$(echo "$res" | grep -o 'window id [0-9]*' | grep -o '[0-9]*')
[ -z "$wid" ] && { echo "could not open window"; exit 1; }
osascript -e "tell application \"Terminal\" to set bounds of window id $wid to {40,40,1100,1000}" >/dev/null
for i in $(seq 1 180); do [ -f "$done_f" ] && break; sleep 2; done
[ -f "$done_f" ] || { echo "timed out waiting for window $wid"; exit 1; }
osascript -e "tell application \"Terminal\" to set index of window id $wid to 1" >/dev/null; sleep 1
screencapture -x -o -l "$wid" "$out" && echo "saved $out (window $wid)"
