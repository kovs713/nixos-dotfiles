#!/usr/bin/env bash
# Run: ./lint.sh [file.qml ...]
#
# The qmllint loop from CONTEXT.md, as a script. qmllint needs both Qt's and
# Quickshell's QML paths on -I or it cannot resolve anything, and without both
# it reports nothing useful. The per-file warning counts are the point: the tree
# sits at a baseline of 344 warnings and 0 errors, almost all of them
# `Unqualified access` and `PanelWindow is not creatable`, so a change is judged
# by the diff against that number and not by expecting zero.
set -u

cd "$(dirname "$0")/config" || exit 1

QD=$(dirname "$(readlink -f "$(command -v qmllint)")")/../lib/qt-6/qml
QS=$(dirname "$(readlink -f "$(command -v qs)")")/../lib/qt-6/qml

files=("$@")
if [ ${#files[@]} -eq 0 ]; then
    files=(shell.qml core/*.qml modules/*.qml services/*.qml)
fi

total=0
errors=0

for f in "${files[@]}"; do
    out=$(QMLPATH="$QD:$QS" qmllint -I "$QD" -I "$QS" "$f" 2>&1)
    warnings=$(printf '%s' "$out" | grep -c 'Warning:')
    errs=$(printf '%s' "$out" | grep -c 'Error:')
    total=$((total + warnings))
    errors=$((errors + errs))
    printf '%4d warn %4d err  %s\n' "$warnings" "$errs" "$f"
done

printf '\n%4d warnings, %d errors\n' "$total" "$errors"
[ "$errors" -eq 0 ]
