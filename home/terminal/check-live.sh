#!/usr/bin/env bash
set -euo pipefail
root=$(realpath "$(dirname "$0")/../..")
tmp=$(mktemp -d)
trap 'tmux -S "$tmp/tmux.sock" kill-server 2>/dev/null || true; rm -rf "$tmp"' EXIT

# A separate server: never reload or kill the user's sessions.
TMUX= tmux -S "$tmp/tmux.sock" -f /dev/null new-session -d -s config-check 'sleep 60'
tmux -S "$tmp/tmux.sock" source-file "$root/home/themed/tmux.conf"
[[ $(tmux -S "$tmp/tmux.sock" show-options -gv default-terminal) == tmux-256color ]]
[[ $(tmux -S "$tmp/tmux.sock" show-options -gv prefix) == C-Space ]]
before=$(tmux -S "$tmp/tmux.sock" show-options -s terminal-features)
tmux -S "$tmp/tmux.sock" source-file "$root/home/themed/tmux.conf"
[[ $(tmux -S "$tmp/tmux.sock" show-options -s terminal-features) == "$before" ]]

XDG_CONFIG_HOME="$tmp" ghostty +validate-config --config-file="$root/home/terminal/ghostty/config"
