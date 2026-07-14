#!/usr/bin/env bash

EVENT="$1"
DIR="$HOME/.claude/agent-status"
mkdir -p "$DIR"

changed=$(python3 -c '
import json, os, sys, time

event, dirpath, ppid = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
sid = data.get("session_id")
if not sid:
    sys.exit(0)
path = os.path.join(dirpath, sid + ".json")

if event == "end":
    if os.path.exists(path):
        os.remove(path)
        print("changed")
    sys.exit(0)

state = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            state = json.load(f)
    except Exception:
        state = {}

status = {"start": "idle", "prompt": "working", "tool": "working", "notify": "waiting", "stop": "idle"}.get(event)
if status is None:
    sys.exit(0)

now = int(time.time())
cwd = data.get("cwd") or state.get("cwd") or ""
new = dict(state)
new.update({
    "session_id": sid,
    "pid": int(ppid),
    "cwd": cwd,
    "project": os.path.basename(cwd) if cwd else state.get("project", "?"),
    "status": status,
    "updated_at": now,
})
if os.environ.get("TMUX_PANE"):
    new["tmux_pane"] = os.environ["TMUX_PANE"]
if os.environ.get("TERM_PROGRAM"):
    new.setdefault("term", os.environ["TERM_PROGRAM"])
if event == "prompt" or "turn_started_at" not in new:
    new["turn_started_at"] = now

if new.get("status") != state.get("status"):
    print("changed")
with open(path, "w") as f:
    json.dump(new, f)
' "$EVENT" "$DIR" "$PPID")

if [ "$changed" = "changed" ]; then
  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
  sketchybar --trigger agents.update 2>/dev/null
fi
exit 0
