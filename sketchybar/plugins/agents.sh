#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
STATE_DIR="$HOME/.claude/agent-status"

update() {
  source "$CONFIG_DIR/colors.sh"

  GREEN=0xff8bd5a0
  YELLOW=0xffe5c07b

  rows=$(python3 - "$STATE_DIR" <<'EOF'
import glob, json, os, sys, time

d = sys.argv[1]
names = {}
for f in glob.glob(os.path.expanduser("~/.claude/sessions/*.json")):
    try:
        with open(f) as fh:
            r = json.load(fh)
        if r.get("sessionId") and r.get("name"):
            names[r["sessionId"]] = r["name"]
    except Exception:
        pass

sessions = []
if os.path.isdir(d):
    for f in os.listdir(d):
        if not f.endswith(".json"):
            continue
        p = os.path.join(d, f)
        try:
            with open(p) as fh:
                s = json.load(fh)
            os.kill(int(s["pid"]), 0)
        except Exception:
            try:
                os.remove(p)
            except OSError:
                pass
            continue
        sessions.append(s)

order = {"waiting": 0, "working": 1, "idle": 2}
sessions.sort(key=lambda s: (order.get(s.get("status"), 3), -s.get("updated_at", 0)))
working = sum(1 for s in sessions if s.get("status") == "working")
waiting = sum(1 for s in sessions if s.get("status") == "waiting")
print(f"{working}\t{waiting}\t{len(sessions)}")

now = time.time()
for s in sessions:
    status = s.get("status", "?")
    mins = int((now - s.get("turn_started_at", now)) // 60)
    elapsed = f" · {mins}m" if status == "working" and mins > 0 else ""
    text = {"working": "working", "waiting": "needs input", "idle": "idle"}.get(status, status)
    name = names.get(s.get("session_id")) or s.get("project", "?")
    print("\x1f".join([
        status,
        f"{name}  —  {text}{elapsed}",
        s.get("tmux_pane", ""),
        s.get("cwd", ""),
        s.get("term", ""),
    ]))
EOF
)

  counts=$(head -n1 <<<"$rows")
  working=$(cut -f1 <<<"$counts")
  waiting=$(cut -f2 <<<"$counts")
  total=$(cut -f3 <<<"$counts")

  icon_color=$DIM_LABEL_COLOR
  [ "${working:-0}" -gt 0 ] && icon_color=$GREEN
  [ "${waiting:-0}" -gt 0 ] && icon_color=$YELLOW

  args=(--set agents label="${total:-0}" icon.color=$icon_color --remove '/agents\.row\..*/')

  i=0
  while IFS=$'\x1f' read -r status label pane cwd term; do
    [ -z "$status" ] && continue
    case "$status" in
      working) icon="●" ; col=$GREEN ;;
      waiting) icon="●" ; col=$YELLOW ;;
      *)       icon="○" ; col=$DIM_LABEL_COLOR ;;
    esac
    args+=(--clone agents.row.$i agents.template
      --set agents.row.$i position=popup.agents drawing=on
      icon="$icon" icon.color="$col" label="$label"
      click_script="$CONFIG_DIR/plugins/agent_focus.sh '$pane' '$cwd' '$term'; sketchybar --set agents popup.drawing=off")
    i=$((i + 1))
  done < <(tail -n +2 <<<"$rows")

  if [ "$i" = "0" ]; then
    args+=(--clone agents.row.none agents.template
      --set agents.row.none position=popup.agents drawing=on
      icon="○" icon.color=$DIM_LABEL_COLOR
      label="No agents running" label.color=$DIM_LABEL_COLOR)
  fi

  sketchybar -m "${args[@]}" >/dev/null
}

case "$SENDER" in
  "routine" | "forced" | "agents.update") update ;;
  "system_woke") sleep 5 && update ;;
esac
