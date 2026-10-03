#!/usr/bin/env bash
# re-encrypt every secret to the machines listed in secrets/recipients.
# usage: secrets/rekey.sh [identity]   (default: this machine's own key)
set -euo pipefail
cd "$(dirname "$0")/.."

recipients=()
while read -r key; do
  recipients+=(-r "$key")
done < secrets/recipients
keys=$(( ${#recipients[@]} / 2 ))

for secret in secrets/*.age; do
  # through a temp file: `age -o "$secret"` would truncate the file being read
  cleartext=$(mktemp)
  age --decrypt -i "${1:-$HOME/.config/agenix/id_ed25519}" -o "$cleartext" "$secret"
  age "${recipients[@]}" -o "$secret" "$cleartext"
  rm -f "$cleartext"
  echo "$(basename "$secret"): $keys keys"
done
