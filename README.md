# dotfiles

macOS desktop setup: [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling WM + [SketchyBar](https://github.com/FelixKratz/SketchyBar) with floating black pill styling.

This repo is `~/.config` itself, with a whitelist `.gitignore` — only the directories listed there are tracked. To track another app's config, add a `!/name` line to `.gitignore`.

## What's here

- `aerospace/aerospace.toml` — workspaces per app, gaps, keybindings, and the `exec-on-workspace-change` / `on-focus-changed` hooks that drive the bar
- `sketchybar/` — the bar config
  - Workspace pills with app icons (sketchybar-app-font), focused-workspace highlight that follows monitor focus
  - `github` item: open PR count with a popover of PR statuses (CI, reviews, conflicts) via `gh` GraphQL
  - `agents` item: live Claude Code session tracker (working / needs input / idle) driven by Claude lifecycle hooks writing to `~/.claude/agent-status/`; clicking a session focuses its tmux pane in Ghostty or its VS Code window

## Setup

```sh
git clone https://github.com/densumesh/dotfiles ~/.config
brew install --cask nikitabobko/tap/aerospace
brew install sketchybar gh jq
brew install --cask font-sketchybar-app-font
brew services start sketchybar
```

The Claude Code agent widget also needs the hooks from `sketchybar/plugins/agent_hook.sh` registered in `~/.claude/settings.json` (SessionStart/UserPromptSubmit/PostToolUse/Notification/Stop/SessionEnd, all `async`).
