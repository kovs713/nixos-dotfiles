#!/usr/bin/env bash
# qmllint over the config. ./lint.sh [file.qml ...], all files by default.
set -u

for bin in qmllint qs; do
    command -v "$bin" >/dev/null || {
        echo "$bin not on PATH, run: x sh quickshell" >&2
        exit 1
    }
done

cd "$(dirname "$0")/config" || exit 1

QD=$(dirname "$(readlink -f "$(command -v qmllint)")")/../lib/qt-6/qml
QS=$(dirname "$(readlink -f "$(command -v qs)")")/../lib/qt-6/qml

files=("$@")
if [ ${#files[@]} -eq 0 ]; then
    files=(shell.qml core/*.qml modules/*.qml services/*.qml)
fi

rc=0
for f in "${files[@]}"; do
    out=$(QMLPATH="$QD:$QS" qmllint -I "$QD" -I "$QS" "$f" 2>&1)
    errs=$(printf '%s' "$out" | grep -c 'Error:')
    printf '%4d warn %4d err  %s\n' \
        "$(printf '%s' "$out" | grep -c 'Warning:')" "$errs" "$f"
    [ "$errs" -eq 0 ] || rc=1
done

exit "$rc"
