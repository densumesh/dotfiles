#!/bin/sh

front_app=(
  icon="􀣺"
  icon.color=$SPACE_FOCUSED_ICON_COLOR
  icon.font="SF Pro:Semibold:13.0"
  label.font="SF Pro:Semibold:12.0"
  label.color=0xfff5f9ff
  label.max_chars=42
  background.drawing=on
  background.color=$SPACE_FOCUSED_BG_COLOR
  background.border_color=$SPACE_FOCUSED_BORDER_COLOR
  background.border_width=1
  background.corner_radius=9
  background.height=20
  icon.padding_left=8
  icon.padding_right=6
  label.padding_left=0
  label.padding_right=10
  y_offset=0
  display=active
  script="$PLUGIN_DIR/front_app.sh"
  click_script="open -a 'Mission Control'"
)
sketchybar --add item front_app left         \
           --set front_app "${front_app[@]}" \
           --subscribe front_app front_app_switched
