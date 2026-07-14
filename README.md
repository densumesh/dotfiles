# dotfiles

macOS desktop setup: [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling WM + [SketchyBar](https://github.com/FelixKratz/SketchyBar) with floating black pill styling.

This repo is `~/.config` itself, with a whitelist `.gitignore` — only the directories listed there are tracked. To track another app's config, add a `!/name` line to `.gitignore`.

## What's here

- `aerospace/aerospace.toml` — workspaces per app, gaps, keybindings, and the `exec-on-workspace-change` / `on-focus-changed` hooks that drive the bar
- `sketchybar/` — the bar config
  - Workspace pills with app icons (sketchybar-app-font), focused-workspace highlight that follows monitor focus
  - Apple pill with a popup menu (Settings, Activity Monitor, Sleep, Lock Screen)
  - `calendar` item: Granola-style next-event pill; week-ahead popover with per-day sections and one-click join for Zoom/Meet/Teams links (EventKit helper binary)
  - `github` item: open PR count with a popover of PR statuses (CI, reviews, conflicts) via `gh` GraphQL
  - `agents` item: live Claude Code session tracker (working / needs input / idle) with click-to-focus routing to the session's tmux pane or VS Code window
  - `clock`, `volume`, `battery` in a bracket pill

## Setup

### 1. Clone

```sh
git clone https://github.com/densumesh/dotfiles ~/.config
```

(On a machine with an existing `~/.config`, clone elsewhere and copy `sketchybar/`, `aerospace/`, `.gitignore`, or init-and-pull in place.)

### 2. Install dependencies

```sh
brew install --cask nikitabobko/tap/aerospace
brew install sketchybar gh jq
brew install --cask font-sketchybar-app-font font-hack-nerd-font sf-symbols
```

`gh auth login` is required for the GitHub PR widget.

### 3. Compile the calendar helper

The calendar widget reads events through a small EventKit binary (not tracked in git — its code signature is machine-specific):

```sh
cd ~/.config/sketchybar/helpers
swiftc CalendarEvents.swift -o calendar_events \
  -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker Info.plist
codesign -s - -f calendar_events
```

The embedded `Info.plist` is required — without a calendar usage description, macOS 14+ silently denies EventKit access. Approve the calendar permission prompt (attributed to sketchybar) on first refresh. Optionally create `helpers/calendars.txt` with one calendar name per line to filter which calendars show.

### 4. Start the bar

```sh
brew services start sketchybar
aerospace reload-config
```

### 5. Claude Code agent widget (optional)

The `agents` pill is driven by Claude Code lifecycle hooks writing per-session state files to `~/.claude/agent-status/`. Register `sketchybar/plugins/agent_hook.sh` in `~/.claude/settings.json` for these events (all `"async": true`, `"timeout": 10`):

| Event | Command |
|---|---|
| SessionStart | `.../agent_hook.sh start` |
| UserPromptSubmit | `.../agent_hook.sh prompt` |
| PostToolUse (matcher `*`) | `.../agent_hook.sh tool` |
| Notification (matcher `*`) | `.../agent_hook.sh notify` |
| Stop | `.../agent_hook.sh stop` |
| SessionEnd | `.../agent_hook.sh end` |

### Permissions summary

- **Calendar** → prompted on first calendar refresh (sketchybar)
- **sketchybar-app-font / Nerd Font** → workspace + widget icons render as placeholders without them
