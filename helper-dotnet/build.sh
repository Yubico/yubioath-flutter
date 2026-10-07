#!/usr/bin/env bash
# Publishes the Native AOT helper for the current platform into helper-dotnet/dist/<rid>/.
#
#   ./build.sh                 # host RID
#   RID=osx-x64 ./build.sh     # cross-architecture on the same OS (Native AOT cannot cross OS)
#   RID=osx-universal ./build.sh   # arm64 + x64 merged with lipo, as the app bundle needs
#   tools/build-linux-docker.sh linux-arm64|linux-x64   # Linux, from any Docker host
#   YUBIKIT_SDK=/path/to/Yubico.YubiKit.NET.SDK ./build.sh
#
# Run the app against it without repackaging:
#   _HELPER_PATH="$PWD/dist/<rid>/authenticator-helper" "/Applications/Yubico Authenticator.app/Contents/MacOS/Yubico Authenticator"
set -euo pipefail
cd "$(dirname "$0")"

if [[ "${RID:-}" == osx-universal ]]; then
  # The app ships as a universal macOS binary: build both architectures and merge them.
  RID=osx-arm64 "$0" && RID=osx-x64 "$0"
  mkdir -p dist/osx-universal
  lipo -create dist/osx-arm64/authenticator-helper dist/osx-x64/authenticator-helper \
    -output dist/osx-universal/authenticator-helper
  lipo -archs dist/osx-universal/authenticator-helper
  exit 0
fi

if [[ -z "${RID:-}" ]]; then
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) RID=osx-arm64 ;;
    Darwin-x86_64) RID=osx-x64 ;;
    Linux-x86_64) RID=linux-x64 ;;
    Linux-aarch64) RID=linux-arm64 ;;
    *) echo "Unsupported host; set RID" >&2; exit 1 ;;
  esac
fi

args=(-c Release -r "$RID" -o "dist/$RID")
if [[ -n "${YUBIKIT_SDK:-}" ]]; then
  args+=("-p:YubiKitSdkRoot=$YUBIKIT_SDK")
fi

dotnet publish src/AuthenticatorHelper/AuthenticatorHelper.csproj "${args[@]}"
ls -l "dist/$RID/authenticator-helper"
