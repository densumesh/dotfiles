#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

#if [ "$SENDER" = "front_app_switched" ]; then
#  sketchybar --set "$NAME" label="$INFO"
#fi

focused_window=$(aerospace list-windows --focused --format "%{app-name}|%{window-title}")

if [ -n "$focused_window" ]; then
  app=$(printf "%s" "$focused_window" | awk -F'|' '{print $1}' | sed 's/^ *//; s/ *$//')
  title=$(printf "%s" "$focused_window" | awk -F'|' '{print $2}' | sed 's/^ *//; s/ *$//')
  icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"

  if [ -n "$title" ]; then
    sketchybar --set "$NAME" icon="$icon" label="$title"
  else
    sketchybar --set "$NAME" icon="$icon" label="$app"
  fi
else
  sketchybar --set "$NAME" icon="􀣺" label="No Active Window"
fi