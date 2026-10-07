#!/usr/bin/env bash
# Runs every probe script against the Python helper and the .NET helper and diffs the responses.
#
#   tools/verify.sh [readonly|authenticated-reads|examine-files|workflow-oath|workflow-piv|workflow-fido ...]
#
# Needs exactly one YubiKey attached. The workflow-* scripts MODIFY the key (they add and remove
# OATH accounts, generate and delete PIV keys in slots 9a/9e, change the FIDO PIN and back) and
# assume test-key defaults: FIDO PIN 11234567, PIV PIN 123456, default PIV management key.
# authenticated-reads doesn't modify the key, but it tries those PINs, which costs PIN attempts if
# they're wrong. Only run these scripts against a dedicated test key.
set -euo pipefail
cd "$(dirname "$0")/.."

PY="${PYTHON_HELPER:-/Applications/Yubico Authenticator.app/Contents/Resources/helper/authenticator-helper}"
NET="${DOTNET_HELPER:-dist/osx-arm64/authenticator-helper}"
OUT="${OUT:-${TMPDIR:-/tmp}/helper-verify}"
IGNORE="public_key,result,certificate,fingerprint,serial,chuid,not_valid_before,not_valid_after"
mkdir -p "$OUT"

scripts=("$@")
[[ ${#scripts[@]} -eq 0 ]] && scripts=(readonly examine-files)

status=0
for name in "${scripts[@]}"; do
  echo "=== $name"
  python3 tools/rpc_probe.py "$PY" "tools/scripts/$name.json" --out "$OUT/python-$name.json" > /dev/null
  python3 tools/rpc_probe.py "$NET" "tools/scripts/$name.json" --out "$OUT/dotnet-$name.json" > /dev/null
  python3 tools/compare.py "$OUT/python-$name.json" "$OUT/dotnet-$name.json" --ignore "$IGNORE" || status=1
done
exit $status
