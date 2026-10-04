#!/usr/bin/env bash
# the checks, as `x ch` runs them. $1 is the live target, and the flake is this
# repo, so neither is an argument here. needs nixfmt and qmllint on PATH:
# x sh quickshell
set -e
cd "$(dirname "$0")/../.."

files=$(find modules home packages -name '*.nix')
for file in $files; do nix-instantiate --parse "$file" >/dev/null; done
nixfmt --check $files
nix eval --no-update-lock-file ".#nixosConfigurations.$1.config.system.build.toplevel.drvPath"
home/quickshell/lint.sh
