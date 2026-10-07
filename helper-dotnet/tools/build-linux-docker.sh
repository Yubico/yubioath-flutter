#!/usr/bin/env bash
# Builds the Native AOT helper for Linux inside a container (Native AOT cannot cross-compile
# across operating systems). Sources are copied into the container so host bin/obj stay intact.
#
#   tools/build-linux-docker.sh [linux-arm64|linux-x64]
#
# Expects the SDK checkout at ../../Yubico.YubiKit.NET.SDK relative to the repository root, or
# YUBIKIT_SDK=/path. Output: helper-dotnet/dist/<rid>/authenticator-helper
set -euo pipefail
cd "$(dirname "$0")/.."
RID="${1:-linux-arm64}"
PLATFORM=$([[ "$RID" == linux-x64 ]] && echo linux/amd64 || echo linux/arm64)
HELPER_DIR="$PWD"
SDK_DIR="$(cd "${YUBIKIT_SDK:-$HELPER_DIR/../../../Yubico.YubiKit.NET.SDK}" && pwd)"
mkdir -p "dist/$RID"

docker run --rm --platform "$PLATFORM" \
  -v "$HELPER_DIR:/in/helper:ro" -v "$SDK_DIR:/in/sdk:ro" -v "$HELPER_DIR/dist/$RID:/out" \
  mcr.microsoft.com/dotnet/sdk:10.0 bash -euo pipefail -c "
    apt-get update -qq && apt-get install -y -qq clang zlib1g-dev libpcsclite-dev rsync >/dev/null
    mkdir -p /work
    rsync -a --exclude bin --exclude obj --exclude dist /in/helper/ /work/helper/
    rsync -a --exclude bin --exclude obj --exclude artifacts --exclude .git /in/sdk/ /work/sdk/
    # The SDK's nuget.config also lists Yubico's authenticated GitHub feed; released
    # Yubico.NativeShims is on nuget.org, which is all an unauthenticated build needs.
    printf '%s' '<configuration><packageSources><clear /><add key=\"nuget.org\" value=\"https://api.nuget.org/v3/index.json\" /></packageSources></configuration>' > /work/sdk/nuget.config
    dotnet publish /work/helper/src/AuthenticatorHelper/AuthenticatorHelper.csproj -c Release -r $RID \
      -p:YubiKitSdkRoot=/work/sdk -o /work/out
    cp /work/out/authenticator-helper /out/
    ls -l /work/out
  "
