#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

sid="$1"

if [ "$SENDER" = "aerospace_workspace_change" ] && [ -n "$FOCUSED_WORKSPACE" ]; then
  focused_workspace="$FOCUSED_WORKSPACE"
  if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" drawing=on background.color=$SPACE_FOCUSED_BG_COLOR icon.color=$SPACE_FOCUSED_ICON_COLOR label.color=$WHITE
  elif [ "$sid" = "$PREV_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.color=$SPACE_BG_COLOR icon.color=$SPACE_ICON_COLOR label.color=$LABEL_COLOR
  else
    exit 0
  fi
else
  focused_workspace=$(aerospace list-workspaces --focused)
  if [ "$SENDER" = "front_app_switched" ] && [ "$sid" != "$focused_workspace" ]; then
    exit 0
  fi

  workspace_monitor=$(aerospace list-workspaces --all --format "%{workspace} %{monitor-appkit-nsscreen-screens-id}" | awk -v sid="$sid" '$1 == sid {print $2; exit}')
  if [ -n "$workspace_monitor" ]; then
    current_mask=$(sketchybar --query "$NAME" | grep -o '"associated_display_mask": *[0-9]*' | grep -o '[0-9]*$')
    target_mask=$((1 << (workspace_monitor - 1)))
    if [ "$current_mask" != "$target_mask" ]; then
      sketchybar --set "$NAME" display="$workspace_monitor"
    fi
  fi
fi

apps=$(aerospace list-windows --workspace "$sid" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

icon_strip=""
if [ "${apps}" != "" ]; then
  app_arr=()
  while read -r app; do
    app_arr+=("$app")
  done <<<"${apps}"
  icon_strip="$($CONFIG_DIR/plugins/icon_map_fn.sh "${app_arr[@]}") "
fi

if [ "$sid" = "$focused_workspace" ]; then
  sketchybar --set "$NAME" drawing=on background.color=$SPACE_FOCUSED_BG_COLOR icon.color=$SPACE_FOCUSED_ICON_COLOR label.color=$WHITE label="$icon_strip"
else
  if [ "${apps}" != "" ]; then
    sketchybar --set "$NAME" drawing=on background.color=$SPACE_BG_COLOR icon.color=$SPACE_ICON_COLOR label.color=$LABEL_COLOR label="$icon_strip"
  else
    sketchybar --set "$NAME" drawing=off background.color=$SPACE_BG_COLOR icon.color=$SPACE_ICON_COLOR label.color=$LABEL_COLOR label=""
  fi
fi
