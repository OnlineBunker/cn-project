#!/usr/bin/env bash
# Renders configs/templates/*.tmpl -> configs/* using values from team.env
. "$(dirname "$0")/lib.sh"
args=()
while IFS='=' read -r k v; do args+=(-e "s|@$k@|$v|g"); done < <(grep -E '^[A-Z0-9_]+=' "$ROOT/team.env")
for t in "$ROOT"/configs/templates/*.tmpl; do
  out="$ROOT/configs/$(basename "${t%.tmpl}")"
  sed "${args[@]}" "$t" > "$out" && echo "rendered $out"
done
