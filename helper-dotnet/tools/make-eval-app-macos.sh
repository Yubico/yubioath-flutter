#!/usr/bin/env bash
# Builds a side-by-side copy of an installed Yubico Authenticator.app whose Python helper is
# replaced by the Native AOT .NET helper, keeping the app sandbox and entitlements. This mirrors
# how the helper would ship inside the bundle (Contents/Resources/helper/authenticator-helper)
# and is how the prototype was verified without a Flutter toolchain.
#
#   tools/make-eval-app-macos.sh [SOURCE_APP] [OUT_DIR]
#
# The copy gets bundle id com.yubico.yubioath.dotneteval, so it has its own sandbox container and
# preferences and never touches the installed app's data. It is ad-hoc signed (local use only).
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="${1:-/Applications/Yubico Authenticator.app}"
OUT="${2:-${TMPDIR:-/tmp}}"
HELPER="dist/osx-arm64/authenticator-helper"
APP="$OUT/Yubico Authenticator (.NET helper).app"
ENT_APP="$OUT/app.entitlements"

[[ -x "$HELPER" ]] || { echo "Build the helper first: ./build.sh" >&2; exit 1; }

rm -rf "$APP"
cp -R "$SRC" "$APP"
rm -rf "$APP/Contents/Resources/helper"
mkdir -p "$APP/Contents/Resources/helper"
cp "$HELPER" "$APP/Contents/Resources/helper/authenticator-helper"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.yubico.yubioath.dotneteval" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName Yubico Authenticator (.NET helper)" "$APP/Contents/Info.plist" || true

codesign -d --entitlements :- "$SRC" > "$ENT_APP" 2>/dev/null
# The helper has no sandbox entitlement of its own, so it inherits the app's sandbox at spawn.
codesign -f --sign - --entitlements ../macos/helper.entitlements "$APP/Contents/Resources/helper/authenticator-helper"
codesign -f --deep --sign - --entitlements "$ENT_APP" "$APP"
codesign --verify --deep --strict "$APP" && echo "OK: $APP"
