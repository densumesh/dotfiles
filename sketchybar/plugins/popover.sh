#!/usr/bin/env bash

target="$1"
args=()
for p in apple_logo github agents calendar; do
  if [ "$p" = "$target" ]; then
    args+=(--set "$p" popup.drawing=toggle)
  else
    args+=(--set "$p" popup.drawing=off)
  fi
done
sketchybar -m "${args[@]}"
