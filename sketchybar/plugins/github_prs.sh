#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

update() {
  source "$CONFIG_DIR/colors.sh"

  GREEN=0xff8bd5a0
  RED=0xfff28fad
  YELLOW=0xffe5c07b

  data=$(gh api graphql -f query='
query {
  viewer {
    open: pullRequests(states: OPEN, first: 20, orderBy: {field: UPDATED_AT, direction: DESC}) {
      totalCount
      nodes {
        title url isDraft reviewDecision mergeable
        repository { nameWithOwner }
        commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
      }
    }
  }
}' 2>/dev/null)

  if [ -z "$data" ]; then
    sketchybar --set github label="?"
    return
  fi

  parsed=$(printf '%s' "$data" | python3 -c '
import json, sys
d = json.load(sys.stdin)["data"]["viewer"]["open"]
print(d["totalCount"])
for n in d["nodes"]:
    commits = n["commits"]["nodes"]
    rollup = commits[0]["commit"]["statusCheckRollup"] if commits else None
    ci = rollup["state"] if rollup else None
    status = {"SUCCESS": "OK", "FAILURE": "FAIL", "ERROR": "FAIL", "PENDING": "WAIT", "EXPECTED": "WAIT"}.get(ci, "NONE")
    tags = []
    if n["isDraft"]:
        tags.append("draft")
    if n["mergeable"] == "CONFLICTING":
        tags.append("merge conflicts")
    review = {"APPROVED": "approved", "CHANGES_REQUESTED": "changes requested"}.get(n["reviewDecision"])
    if review:
        tags.append(review)
    suffix = ("   —  " + ", ".join(tags)) if tags else ""
    repo = n["repository"]["nameWithOwner"].split("/")[-1]
    title = n["title"].replace("\t", " ")
    print("\t".join([status, f"{title}  ·  {repo}{suffix}", n["url"]]))
')

  count=$(head -n1 <<<"$parsed")
  if [ -z "$count" ]; then
    sketchybar --set github label="?"
    return
  fi

  args=(--set github label="$count" --remove '/github\.pr\..*/')

  i=0
  while IFS=$'\t' read -r status label url; do
    [ -z "$status" ] && continue
    case "$status" in
      OK)   icon="✓" ; col=$GREEN ;;
      FAIL) icon="✗" ; col=$RED ;;
      WAIT) icon="◌" ; col=$YELLOW ;;
      *)    icon="○" ; col=$DIM_LABEL_COLOR ;;
    esac
    args+=(--clone github.pr.$i github.template
      --set github.pr.$i position=popup.github drawing=on
      icon="$icon" icon.color="$col" label="$label"
      click_script="open '$url'; sketchybar --set github popup.drawing=off; sleep 2; sketchybar --trigger github.update")
    i=$((i + 1))
  done < <(tail -n +2 <<<"$parsed")

  if [ "$i" = "0" ]; then
    args+=(--clone github.pr.none github.template
      --set github.pr.none position=popup.github drawing=on
      icon="○" icon.color=$DIM_LABEL_COLOR
      label="No open PRs" label.color=$DIM_LABEL_COLOR)
  fi

  sketchybar -m "${args[@]}" >/dev/null
}

case "$SENDER" in
  "routine" | "forced" | "github.update") update ;;
  "system_woke") sleep 10 && update ;;
esac
