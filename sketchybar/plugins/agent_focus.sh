#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

pane="$1"
cwd="$2"
term="$3"

if [ -n "$pane" ] && tmux has-session 2>/dev/null; then
  session=$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null)
  if [ -n "$session" ]; then
    tmux select-pane -t "$pane" 2>/dev/null
    tmux select-window -t "$pane" 2>/dev/null
    client=$(tmux list-clients -F '#{client_tty}' 2>/dev/null | head -1)
    [ -n "$client" ] && tmux switch-client -c "$client" -t "$session" 2>/dev/null
    open -a Ghostty
    exit 0
  fi
fi

if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  open -a "Visual Studio Code" "$cwd"
  exit 0
fi

open -a Ghostty
