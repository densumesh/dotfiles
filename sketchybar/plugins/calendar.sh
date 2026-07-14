#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
CAL_BIN="$HOME/.config/sketchybar/helpers/calendar_events"

update() {
  source "$CONFIG_DIR/colors.sh"

  YELLOW=0xffe5c07b

  raw=$("$CAL_BIN" 7 2>/dev/null)
  printf '%s\n' "$raw" > "$HOME/.cache/sketchybar-calendar-raw.txt"
  parsed=$(printf '%s\n' "$raw" | python3 -c '
import sys, time
from datetime import datetime, date, timedelta

now = datetime.now()
today = date.today()
events = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if " | " not in line:
        continue
    stamp, rest = line.split(" | ", 1)
    if " | " in rest:
        title, link = rest.rsplit(" | ", 1)
    else:
        title, link = rest.rstrip("| "), ""
    title = title.strip()
    link = link.strip()
    try:
        datepart, times = stamp.split(" ", 1)
        start_s, end_s = times.split("-", 1)
        d = datetime.strptime(datepart, "%Y-%m-%d").date()
        start = datetime.combine(d, datetime.strptime(start_s, "%H:%M").time())
        end = datetime.combine(d, datetime.strptime(end_s, "%H:%M").time())
    except ValueError:
        continue
    events.append((start, end, title, link))

if not events:
    print("")
    sys.exit(0)

def t(dt):
    return dt.strftime("%I:%M %p")

def tp(dt):
    return dt.strftime("%-I:%M %p")

start, end, title, link = events[0]
short = title if len(title) <= 28 else title[:27] + "…"
if start <= now < end:
    pill = f"{short} · now"
elif start.date() == today:
    mins = int((start - now).total_seconds() // 60)
    pill = f"{short} · in {mins}m" if mins < 60 else f"{short} · {tp(start)}"
else:
    day = "tmrw" if (start.date() - today).days == 1 else start.strftime("%a")
    pill = f"{short} · {day} {tp(start)}"
print(pill)

last_date = None
for start, end, title, link in events[:15]:
    if start.date() != last_date:
        last_date = start.date()
        days = (start.date() - today).days
        if days == 0:
            heading = "TODAY"
        elif days == 1:
            heading = "TOMORROW"
        else:
            heading = start.strftime("%A").upper()
        print("\x1f".join(["header", heading, ""]))
    state = "now" if start <= now < end else "event"
    short = title if len(title) <= 32 else title[:31] + "…"
    print("\x1f".join([state, f"{t(start)} – {t(end)}   {short}", link]))
')

  pill=$(head -n1 <<<"$parsed")
  rows_body=$(tail -n +2 <<<"$parsed")
  cache="$HOME/.cache/sketchybar-calendar-rows.txt"
  if [ -z "$pill" ]; then
    sketchybar --set calendar label="No events" label.color=$DIM_LABEL_COLOR
  else
    sketchybar --set calendar label="$pill" label.color=$LABEL_COLOR
  fi
  if [ -f "$cache" ] && [ "$(cat "$cache")" = "$rows_body" ]; then
    return
  fi
  printf '%s' "$rows_body" > "$cache"

  args=(--remove '/calendar\.ev\..*/')

  i=0
  while IFS=$'\x1f' read -r state label link; do
    [ -z "$state" ] && continue
    if [ "$state" = "header" ]; then
      args+=(--clone calendar.ev.$i calendar.template
        --set calendar.ev.$i position=popup.calendar drawing=on
        icon.drawing=off icon.width=0
        label="$label" label.font="SF Pro:Bold:10.0"
        label.color=$DIM_LABEL_COLOR label.padding_left=14)
      i=$((i + 1))
      continue
    fi
    col=$LABEL_COLOR
    [ "$state" = "now" ] && col=$YELLOW
    if [ -n "$link" ]; then
      action="open '$link'"
      row_icon="󰖠"
      icon_col=0xff8bd5a0
    else
      action="open -a Calendar"
      row_icon=""
      icon_col=$DIM_LABEL_COLOR
    fi
    args+=(--clone calendar.ev.$i calendar.template
      --set calendar.ev.$i position=popup.calendar drawing=on
      icon="$row_icon" icon.color="$icon_col"
      label="$label" label.color="$col"
      click_script="$action; sketchybar --set calendar popup.drawing=off")
    i=$((i + 1))
  done < <(tail -n +2 <<<"$parsed")

  if [ "$i" = "0" ]; then
    args+=(--clone calendar.ev.none calendar.template
      --set calendar.ev.none position=popup.calendar drawing=on
      label="Nothing scheduled" label.color=$DIM_LABEL_COLOR)
  fi

  sketchybar -m "${args[@]}" >/dev/null
}

case "$SENDER" in
  "routine" | "forced" | "calendar.update") update ;;
  "system_woke") sleep 5 && update ;;
esac
