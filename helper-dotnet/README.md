# authenticator-helper (.NET Native AOT prototype)

This is an evaluation prototype that replaces `helper/` (Python + yubikey-manager) with a
Native AOT executable built on the v2 Yubico .NET SDK (`Yubico.YubiKit.*`). It speaks the same
stdin/stdout JSON RPC as the Python helper, so the Flutter app runs unchanged.

- [`docs/rpc-contract.md`](docs/rpc-contract.md) covers the app-to-helper contract and maps each in-scope workflow to v2 SDK APIs.
- [`docs/evaluation.md`](docs/evaluation.md) covers the design, the verification results, feature gaps, SDK and platform findings, and the estimate.

## Layout

```
src/AuthenticatorHelper/
  Program.cs           stdio / --tcp entry point
  Rpc/                 framing, node tree (port of helper/helper/base.py), errors, JSON log sink
  Nodes/               root, usb devices, connections, management
  Nodes/Fido|Oath|Piv  application nodes (ports of fido.py, oath.py, piv.py)
tools/
  rpc_probe.py         drives any helper over the wire and records a transcript
  compare.py           diffs two transcripts (Python vs .NET)
  verify.sh            runs the probe scripts against both helpers
  scripts/*.json       read-only and workflow scripts (workflow-* MODIFY the key)
  make-eval-app-macos.sh   side-by-side app bundle with the .NET helper inside
  build-linux-docker.sh    Linux Native AOT build in a container
golden/                transcripts captured from both helpers on a YubiKey 5.8 test key
```

## Build

You need the .NET 10 SDK (10.0.300 or later) and a checkout of the v2 SDK. By default the build
expects it next to this repository's parent folder, at `../../Yubico.YubiKit.NET.SDK` relative to
the repository root. Override it with `YUBIKIT_SDK=/path` or `-p:YubiKitSdkRoot=/path`.

```sh
./build.sh                          # host platform -> dist/<rid>/authenticator-helper
RID=osx-universal ./build.sh        # macOS arm64 + x64, merged with lipo
tools/build-linux-docker.sh linux-x64   # Linux, needs Docker
```

On Windows, run `dotnet publish src/AuthenticatorHelper -c Release -r win-x64`. This hasn't been
verified (see `docs/evaluation.md`).

## Run with the app

```sh
# Any desktop build of the app without a sandbox (Linux, Windows, a local macOS debug build):
_HELPER_PATH="$PWD/dist/<rid>/authenticator-helper" <path to app executable>

# Installed macOS release (sandboxed, so the helper must be inside the bundle):
tools/make-eval-app-macos.sh "/Applications/Yubico Authenticator.app" "$TMPDIR"
"$TMPDIR/Yubico Authenticator (.NET helper).app/Contents/MacOS/Yubico Authenticator" --log-level traffic
```

## Verify against the Python helper

```sh
tools/verify.sh                                          # read-only, safe on any key
tools/verify.sh workflow-oath workflow-piv workflow-fido # TEST KEY ONLY, see the script header
```
