# Evaluation: a .NET Native AOT helper for Yubico Authenticator

**Question.** Can the desktop app's Python/yubikey-manager helper be replaced by a Native AOT .NET
helper on the v2 Yubico.YubiKit.NET.SDK, without changing the Flutter UI?

**Answer.** Yes for FIDO, OATH and PIV. The prototype in `helper-dotnet/` is wire-compatible with
the app's existing RPC contract:
- It ran inside an unmodified Yubico Authenticator 7.4.1 release build on macOS, in the app sandbox.
- Through the real UI it completed hardware-backed workflows for all three areas, including the
  FIDO reset reinsert flow.
- Scripted workflows return the same responses as the Python helper, except for documented gaps.

Before production, the remaining work is:
- the features this story scoped out (keychain storage, QR, diagnostics),
- YubiOTP and NFC readers,
- Windows and Linux hardware verification,
- a handful of SDK fixes found along the way (section 5).

Contents:
1. Design: build, launch, packaging, device access, errors
2. Prototype and verification
3. Platform verification status
4. Feature-gap list
5. SDK and platform findings
6. Implementation estimate

The contract and the per-workflow SDK mapping are in [`rpc-contract.md`](rpc-contract.md).

---

## 1. Design

### 1.1 Shape: keep the process boundary and the protocol

The Flutter side talks to the helper only through `lib/desktop/rpc.dart`. Keeping that contract
byte-compatible means:
- **No Dart changes** are needed to switch helpers. Both helpers can ship side by side during a
  migration, chosen by path or by `_HELPER_PATH`.
- The Python helper is a **ready-made oracle**. `tools/rpc_probe.py` and `tools/compare.py` replay
  the same commands against both helpers and diff the responses. That is the main regression
  harness.
- The node-tree lifecycle (`RpcNode` in `helper/helper/base.py`) is ported as is
  (`Rpc/RpcNode.cs`). That lifecycle decides when connections and sessions open and close. Copying
  it avoids subtle behaviour changes, such as releasing the key when the window loses focus, or
  dropping authentication after `device_info`, which the app relies on.

An in-process FFI (Dart to a Native AOT shared library) was considered and rejected for this phase:
- It would require Dart changes everywhere `RpcSession` is used.
- It would give up the Windows elevation design, which needs a separate process.
- It would lose the oracle.
- The process boundary costs about 2 ms per round trip (measured `scan` latency), which is
  irrelevant at the app's 500 ms polling rate.

### 1.2 Code structure

| Python (`helper/helper/`) | .NET (`helper-dotnet/src/AuthenticatorHelper/`) |
|---|---|
| `__init__.py` `process()`: threads, cancel event | `Rpc/RpcServer.cs`: reader loop, one command at a time, `CancellationTokenSource` per command |
| `base.py` `RpcNode`, exceptions | `Rpc/RpcNode.cs`, `Rpc/RpcErrors.cs` |
| logging to stderr JSON | `Rpc/Log.cs`, also an `ILoggerFactory` plugged into `YubiKitLogging` |
| `device.py` | `Nodes/RootNode.cs`, `DevicesNode.cs`, `UsbDeviceNode.cs`, `ConnectionNode.cs`, `DeviceInfoJson.cs` |
| `management.py` | `Nodes/ManagementNode.cs` |
| `fido.py` | `Nodes/Fido/*` |
| `oath.py` | `Nodes/Oath/*` |
| `piv.py` + `ykman.piv` + `cryptography` | `Nodes/Piv/*` (CSR and certificate signing through `CertificateRequest` + `X509SignatureGenerator` over `SignOrDecryptAsync`) |
| 0.5 s "probably needs touch" timers | `TouchSignalPrompt`, an `IUserPresencePrompt` that sends `touch` (or `reset/touch`). The HOTP timer is kept because touch isn't known up front. |

JSON uses `System.Text.Json.Nodes` only, with no reflection serializers. Two AOT warnings
(`JsonArray.Add<T>`) were caught by ILC and fixed. The build treats warnings as errors.

### 1.3 Build

- **Toolchain.** .NET 10 SDK (10.0.300 or later), `PublishAot=true`, `InvariantGlobalization`,
  size optimisation, stripped symbols. The output is one native executable, with no runtime install
  and no side files.
- **SDK consumption.** The v2 SDK isn't on nuget.org yet, so the prototype uses `ProjectReference`
  to an SDK checkout (`YubiKitSdkRoot`). For production, consume the published `Yubico.YubiKit.*`
  packages and pin versions.
- **Native AOT can't cross-compile across operating systems.** Each OS needs its own CI job, which
  matches the existing `macos.yml`, `windows.yml`, `linux.yml` and `linux-arm64.yml` workflows. A
  job replaces the `build-helper.sh`/`.bat` PyInstaller step with `dotnet publish`.

| Target | Command | Notes |
|---|---|---|
| macOS (universal) | `RID=osx-universal ./build.sh` | Builds osx-arm64 and osx-x64 on one Mac, then `lipo`. Verified. |
| Windows x64/arm64 | `dotnet publish -r win-x64` / `win-arm64` on a Windows runner | Not built (no Windows host available). See 5.2. |
| Linux x64/arm64 | `tools/build-linux-docker.sh <rid>` or a native runner | arm64 verified in Docker. x64 not built: MSBuild crashes under QEMU emulation. Needs `clang`, `zlib1g-dev`, `libpcsclite-dev`. |

| | Python helper (PyInstaller) | .NET helper (Native AOT) |
|---|---|---|
| Files shipped | `authenticator-helper` + `_internal/` | one executable |
| Size, macOS | 95 MB (universal) | 6.6 MB arm64, 13.3 MB universal |
| Size, Linux arm64 | n/a | 7.2 MB |
| Cold start to first response | 260–360 ms | 10–20 ms |
| Resident memory after device enumeration | 58 MB (2 processes) | 13–19 MB |
| Runtime dependencies, Linux | bundled Python, pyscard, libpcsclite | libc, libm, libpcsclite.so.1 (+ libssl at runtime for PIV certificate operations) |

### 1.4 Launch and packaging

There's no change to how the app finds the helper: `_HELPER_PATH`, otherwise
`helper/authenticator-helper[.exe]` next to the app executable.

- **macOS.** Ship the binary as `Contents/Resources/helper/authenticator-helper`.
  - Sign it with the existing `macos/helper.entitlements` (`smartcard`, `device.usb`). It has no
    sandbox entitlement of its own and inherits the app sandbox.
  - Verified: `tools/make-eval-app-macos.sh` builds exactly this layout from the installed release.
    The helper then works inside the sandbox (PC/SC and IOHID).
  - `allow-unsigned-executable-memory` is no longer needed by the helper (no JIT). It can be dropped
    once the Python helper is gone.
  - Note: the sandbox blocks executing a helper outside the bundle or container. So `_HELPER_PATH`
    only works for unsandboxed (debug) builds on macOS.
- **Windows.** Ship `helper\authenticator-helper.exe`.
  - Keep `--tcp <port> <nonce>` for elevation; it's implemented in `Program.cs`.
  - FIDO HID access on Windows needs administrator rights. The helper maps
    `UnauthorizedAccessException` on the FIDO connection, when not elevated, to
    `fido-blocked-error`, which triggers the app's existing elevate flow. This path is unverified.
  - The `.exe.manifest` and `version_info.txt` can move into csproj properties (`ApplicationManifest`, version attributes).
- **Linux.** Ship `helper/authenticator-helper`.
  - Runtime needs `pcscd` + `libpcsclite1` for CCID, which is the same as today.
  - FIDO HID needs `hidraw` permissions (udev rules), also the same as today.
- **Licenses.** `build-helper.sh` generates `assets/licenses/helper.json` with pip-licenses.
  Replace it with a NuGet license export (for example dotnet-project-licenses) over the publish
  closure.

### 1.5 Device access

| Concern | Python helper | .NET helper |
|---|---|---|
| Enumeration | `ykman.device.scan_devices` (cheap USB scan) + `list_all_devices` | `YubiKeyManager.FindAllAsync(ConnectionType.All, forceRescan: true)` on every `scan` (about 2 ms, no device I/O for known devices). Devices are identified by serial, otherwise by `sha256(DeviceId)[:16]`. |
| USB PID | from the USB descriptor | rebuilt from exposed interfaces (`0x0400 \| OTP=1 \| FIDO=2 \| CCID=4`). The SDK doesn't expose the PID. |
| Product name | `yubikit.support.get_name` | ported (`DeviceInfoJson.GetName`) |
| Interfaces | pyscard (PC/SC), hidapi-like HID via ykman | SDK Core: PC/SC (winscard / pcsclite / PCSC.framework), HID (Windows HID, Linux hidraw, macOS IOHIDManager via NativeShims) |
| Connection lifetime | one connection per `ccid`/`fido`/`otp` node, sessions on top | the same. `IYubiKey.ConnectAsync<T>()` is held by `ConnectionNode`, and sessions are created over that caller-owned connection. |
| Pre-release firmware | `_override_version()` globally | `SessionCreationOptions.FirmwareVersionOverride` per session, from DeviceInfo's version qualifier (see 5.1) |
| Reinsert (FIDO reset) | `device.reinsert()` | polls `FindAllAsync` for the device count to drop and come back, then `SameDeviceAs` / connection match |

### 1.6 Error reporting

Errors keep the Python helper's status strings and bodies, so every existing Dart handler keeps
working. The mapping lives in each node's `CallAsync` override, mirroring the Python `__call__`
overrides.

| SDK exception | RPC error |
|---|---|
| `SCardException`, `PlatformApiException`, `PlatformInteropException`, `IOException` inside a connection | `state-reset` (the node re-opens). At device level: `invalid-command` "No such node", so the app re-enumerates. |
| Failure to open an interface | `connection-error {device, connection, exc_type}`. The first 2 repeats become `state-reset`, as in Python. |
| `UnauthorizedAccessException` opening FIDO on Windows, not admin | `fido-blocked-error` |
| `ApduException` SW 0x6982, `OathException(Locked)` | `auth-required` |
| PIV `InvalidOperationException` with `!IsManagementKeyAuthenticated` | `auth-required` (see 5.1) |
| `ApduException` SW 0x6D00, other unexpected SW in OATH/PIV | `state-reset` |
| `CtapException` `PinInvalid` / `PinBlocked` / `PinAuthBlocked` | `pin-validation {retries, auth_blocked}` |
| `CtapException` `PinPolicyViolation`, PIV SW 0x6985 on PIN change | `pin-complexity` |
| `CtapException` `PinAuthInvalid` | `auth-required` (token dropped) |
| `CtapException` `UserActionTimeout` / `ActionTimeout` | `user-action-timeout` |
| PIV `InvalidPinException` | `invalid-pin {attempts_remaining}` |
| `ArgumentException` from bad input, unknown node or action | `invalid-command` |
| anything else | `exception` with `Type(message)`, logged with the stack trace to stderr |

---

## 2. Prototype and verification

Test device: YubiKey 5 NFC Enhanced PIN, firmware 5.8.0 alpha 2, serial 125, a dedicated test key
from the SDK's allow-list. Host: macOS 15.7 on Apple Silicon. App: Yubico Authenticator 7.4.1
release. The key was returned to its starting state after every workflow.

### 2.1 Through the real Flutter app (macOS, sandboxed, helper inside the bundle)

| Area | Workflow completed in the UI | Helper calls involved |
|---|---|---|
| Device | Device detected, Home page with name, serial, firmware and capabilities. Survived unplug and replug. | `scan`, `get usb`, `get usb/125`, DeviceInfo |
| **FIDO** | Passkeys: unlock with PIN, list one passkey (created with one touch), view details, delete it. Factory reset → FIDO: "Unplug" → "Insert" → "Touch" → success. Set a new PIN. | `ctap2 get`, `unlock`, `credentials`, `credentials/<rp>`, `delete`, `reset` with `remove`/`insert`/`touch` signals, `set_pin` |
| **OATH** | Accounts listed with live codes (checked against RFC 6238). Added an account by manual entry, then deleted it. | `oath get`, `calculate_all`, `put {uri}`, `delete` |
| **PIV** | Certificates page with PIN/PUK/management-key status and slot list (existing 9c certificate shown). Generated a P-256 key and self-signed certificate in 9a: the app got `auth-required`, authenticated with the default management key and retried. Viewed the certificate, then deleted the key and certificate. | `piv get`, `slots`, `verify_pin`, `validate_rfc4514`, `generate`, `authenticate`, `delete` |

Screenshots of each step were taken during the run. They aren't committed, because they contain
the test key's identifiers.

### 2.2 Scripted comparison against the Python helper

`tools/verify.sh readonly authenticated-reads workflow-oath workflow-piv workflow-fido examine-files` runs 92
RPC steps against both helpers and diffs the responses. Transcripts are in `golden/`. Volatile
values are ignored: generated keys and certificates, state hashes, timestamps.

| Script | Steps | Differences | Coverage |
|---|---|---|---|
| readonly | 19 | 3 expected (see below) | discovery, DeviceInfo, OATH/PIV/FIDO state, slots, errors for unknown node and action |
| authenticated-reads | 10 | 1 expected | OATH `calculate_all` at a fixed timestamp (identical code), `derive` (identical key), PIV `verify_pin`, slot certificate (identical PEM), FIDO `unlock` + credentials |
| workflow-oath | 25 | 0 | put (URI, TOTP and HOTP, duplicate rejected), code, Steam `calculate`, rename, delete, `set_key`, wrong and right `validate`, locked → `auth-required`, `unset_key` |
| workflow-piv | 18 | 0 | wrong PIN → `invalid-pin {attempts_remaining: 2}`, wrong management key → `{status: false}`, generate a P-256 certificate and an RSA-2048 CSR (both pass `openssl verify`), `auth-required` after `device_info`, delete key and certificate |
| workflow-fido | 14 | 3 expected | wrong PIN → `pin-validation {retries: 7}`, unlock, credential listing, weak PIN → `pin-complexity`, change PIN and back |
| examine-files | 6 | 0 | PIV `examine_file` on PEM certificate, PEM certificate + key, PKCS#12 without, wrong and right password, multi-valued RDN subject |

Expected differences:
- the root `actions` list lacks `diagnose`/`qr`,
- `ccid` lacks `yubiotp`,
- `power_cycle` is `false` instead of `null` (5.1).

### 2.3 Not verified on hardware

- Bio enrollment (no YubiKey Bio available).
- FIDO over CCID (`["ccid", "ctap2"]`).
- `configure` and `device_reset` (Management).
- PIV `move_key`, `import_file`, `set_key`, PIN/PUK change, `reset`.
- OATH `reset`.
- Touch-policy credentials (touch signals work for FIDO reset; OATH and PIV touch-policy paths weren't exercised).
- Pre-5.x and non-alpha firmware.
- More than one key attached.

---

## 3. Platform verification status

| Platform | Build | Runs | Hardware workflows | Inside the app | Status |
|---|---|---|---|---|---|
| macOS arm64 | yes | yes | yes, all of section 2 | yes (sandboxed release bundle) | **verified** |
| macOS x64 | yes (cross-arch from arm64) | yes (Rosetta) | device listing only | no | partially verified: an Intel Mac run is still needed |
| macOS universal | yes (`lipo`) | n/a | n/a | n/a | build verified |
| Linux arm64 | yes (Docker) | yes, no hardware: empty device list, graceful with and without `pcscd` | **no** | no | build and startup verified. Hardware unverified: Docker on macOS can't pass USB through. |
| Linux x64 | **no** | no | no | no | unverified: MSBuild crashes under QEMU x64 emulation on Apple Silicon. Expected to work on a native x64 runner (same toolchain as arm64). |
| Windows x64/arm64 | **no** | no | no | no | unverified: no Windows host was available, and Native AOT can't cross-compile from macOS. Expect the NativeShims link issue in 5.2. Elevation (`--tcp`) and `fido-blocked-error` are implemented but untested. |

Next steps to close the gaps:
- Run `dotnet publish` plus `tools/verify.sh` on Windows and Linux runners with a test key.
- Run a smoke test of the elevated FIDO path on Windows.

---

## 4. Feature-gap list (prototype vs Python helper)

| # | Gap | Area | In story scope? | Effort to close | Notes |
|---|---|---|---|---|---|
| 1 | Remember OATH password (`validate remember`, `forget`, `keystore`) | OATH | out (secret storage) | M | Needs OS keychain access from .NET: Keychain, DPAPI/Credential Manager, libsecret. ykman uses `keyring`. |
| 2 | Persistent FIDO PPUAT ("Persist read-only access") | FIDO | out (secret storage) | M | The SDK has `CredentialManagementRO` and `EncIdentifier`. Storage is the same keychain work as #1. |
| 3 | QR scanning (`qr`) | root | out | S–M | Move to Flutter (screen capture + a zxing Dart package) or use ZXing.Net. Manual entry works. |
| 4 | Diagnostics (`diagnose`) | root | out | S | Compose from SDK device info + PC/SC reader list + OS info. |
| 5 | NFC readers (`nfc` subtree) | device | not prioritised | M | Needs PC/SC reader listing for non-YubiKey readers, card-presence polling, and the restricted-NFC NDEF check. Confirm the SDK surfaces external NFC readers. |
| 6 | YubiOTP slots (`yubiotp`) | OTP | not prioritised | M | `Yubico.YubiKit.YubiOtp` exists and wasn't wired. |
| 7 | Legacy `set_mode` (YubiKey NEO / 4) | Management | not prioritised | S (SDK) | Not public in v2 (5.1). |
| 8 | PIV `set_key` with `store_key` (PIN-protected management key), PIN change updating a PIN-derived key | PIV | partial | S | `SetPinOnlyModeAsync` / `RecoverPinOnlyModeAsync` exist. Wire them like `pivman_set_mgm_key` / `pivman_change_pin`. |
| 9 | PIV Ed25519/X25519 self-signed certificates and CSRs | PIV | partial | S–M | .NET `CertificateRequest` has no Ed25519. Needs a small DER builder. Key generation itself works. |
| 10 | PIV import of legacy PKCS#12 encryption / X25519 keys | PIV | partial | S | Uses .NET loaders. Validate against ykman's test vectors. |
| 11 | BIO MPE `default_value` quirk, PIV `supports_bio` edge cases | PIV | partial | XS | Port the 5-line workaround from `piv.py`. |
| 12 | Device change detection via polling `FindAllAsync(forceRescan)` | device | works | S | Consider `YubiKeyManager.WatchAsync` to avoid rescans. Measure CPU on Windows and Linux. |

Effort: XS < 1 day, S 1–3 days, M 1–2 weeks.

---

## 5. SDK and platform findings

Status is **verified** (reproduced in this evaluation) unless marked otherwise.

### 5.1 v2 SDK API findings

1. **Pre-release firmware reports 0.0.1 to applet sessions.** `PivSession` and `OathSession` on a
   5.8.0-alpha key report `FirmwareVersion` 0.0.1, so version-gated behaviour is wrong unless the
   caller passes `SessionCreationOptions.FirmwareVersionOverride`. yubikit applies the
   version-qualifier override globally. Suggest a helper on `DeviceInfo`, or doing it automatically
   when sessions are created from an `IYubiKey`.
2. **`OathSession.CalculateAsync` returns `[digits byte][HMAC]`.** The XML doc says "the full HMAC
   response", and yubikit's `calculate()` returns only the HMAC. The app's Steam codes depend on
   it. The helper strips byte 0. **Probable SDK bug.**
3. **PIV management-key preconditions throw an untyped `InvalidOperationException`** (string
   message) before sending any APDU. Callers can't distinguish this from other invalid states
   without checking `IsManagementKeyAuthenticated`. Suggest a typed exception or the device's SW
   0x6982.
4. **No public USB PID or product name.** `IYubiKey` has `DeviceId` and `AvailableConnections` but
   no PID, and there's no `get_name` equivalent. The helper reconstructs both. That's ambiguous for
   Security Key / FIDO-only and NEO PIDs.
5. **DeviceInfo from discovery is internal.** `YubiKeyDevice.DeviceInfo` exists but isn't exposed
   on `IYubiKey`, so listing names needs an extra connection per device.
6. **`DeviceInfo` equality isn't value equality.** It's a `record struct` with `ReadOnlyMemory<byte>`
   and class-typed members, so `==` compares references. `ChallengeResponseTimeout` is a
   `ReadOnlyMemory<byte>` instead of a number.
7. **Legacy mode switching (`SetMode`) isn't public** (`docs/migration/v1-to-v2-gaps.md`), so the
   app's mode dialog for YubiKey NEO/4 can't be supported.
8. `PinRetryStatus.PowerCycleRequired` is `bool`, while python-fido2 reports `None` when the
   authenticator omits it. This is harmless for the app.
9. Strengths seen:
   - `IUserPresencePrompt` replaces timing heuristics for touch prompts.
   - The PIV `RecoverPinOnlyModeAsync` and `GetPinOnlyModeAsync` helpers.
   - Sessions over caller-owned connections map cleanly to the app's node lifecycle.
   - The SDK's AOT analyzers caught nothing, and the published binary needed no trimming
     workarounds for SDK code.

### 5.2 Platform and packaging findings

1. **Linux Native AOT link fails with Yubico.NativeShims 1.18.1** (verified on linux-arm64). The
   package makes every NativeShims P/Invoke a `DirectPInvoke` against a static archive. The Linux
   archive lacks the macOS-only `Native_HidInput*` symbols that Core's `MacOSFidoHidConnection`
   references, which gives "undefined reference" at link time. The helper works around it with
   `-Wl,--unresolved-symbols=ignore-in-object-files` for Linux RIDs.
   - The real fix belongs in NativeShims: export stubs on every platform, or limit `DirectPInvoke`
     per entry point.
   - The SDK's own `docs/NATIVE-AOT.md` reports a Linux publish, which predates 1.18.1 or used a
     different shim build.
   - **Windows is likely affected the same way (unverified).**
2. The SDK's `nuget.config` maps `Yubico.NativeShims` to an authenticated GitHub feed as well as
   nuget.org. Unauthenticated CI must override it. The release package is on nuget.org.
3. macOS publish links NativeShims statically and emits no dylib, so there's nothing extra to sign.
4. The macOS app sandbox only allows executing the helper from inside the bundle. Development
   overrides need an unsandboxed build or a re-signed bundle (`tools/make-eval-app-macos.sh`).
5. Native AOT can't cross-compile across operating systems, and .NET MSBuild crashes under QEMU
   x64 emulation. Linux x64 and Windows need native runners.

### 5.3 Behavioural parity notes (kept on purpose)

- After any `device_info` action, the application session closes (PIV authentication, FIDO token
  and OATH unlock are lost), exactly like the Python helper. The app re-authenticates silently.
- On EOF the helper cancels the in-flight command, as the Python helper sets its cancel event.

### 5.4 Review

A cross-vendor code review (GPT-family reviewer) of the prototype found 12 issues. All are fixed
and re-verified with the full transcript suite and a UI smoke run:
- FIDO reset could, in theory, pick a different key on reinsert. It now matches by serial, or
  refuses unless exactly one key is attached.
- An interrupted reset left a disposed connection behind. It now triggers `state-reset`.
- `change_pin` on a PIN-derived management key would have orphaned the key. It's now refused up front.
- PIN, PUK and private-key buffers are now zeroed.
- PKCS#12 keys are loaded ephemerally where the OS allows it.
- Multi-valued RDNs are now formatted.
- Root and devices-node child bookkeeping now matches the Python node lifecycle.
- The request loop is now hardened against malformed fields.

---

## 6. Implementation estimate

The estimate assumes one engineer familiar with the app and the SDK, and that the SDK fixes in
section 5 are done by the SDK team in parallel. Ranges include tests and review.

| Work item | Estimate |
|---|---|
| **A. Production-ready FIDO, OATH and PIV (this story's scope)** | |
| Harden core: logging levels, cancellation, error mapping review, unit tests for the node lifecycle, golden-transcript suite in CI | 1.5–2 weeks |
| Close in-scope partial gaps #8–#11 (PIV pivman, Ed25519 certificates, import vectors), FIDO-over-CCID, touch-policy paths | 1–1.5 weeks |
| CI packaging for macOS universal (sign and notarize), Windows x64/arm64, Linux x64/arm64; license generation; replace `build-helper.*` | 1.5–2 weeks |
| Platform verification with test keys (Windows elevation and FIDO, Linux pcscd/udev, Intel Mac, older firmware 4.x/5.2–5.7, Bio) | 1.5–2 weeks |
| **Subtotal A** | **5.5–7.5 engineer-weeks** |
| **B. Full parity, so the Python helper can be removed** | |
| Keychain-backed secret storage (OATH remember, FIDO PPUAT) on 3 OSes | 1.5–2 weeks |
| NFC readers subtree | 1–1.5 weeks |
| YubiOTP slots | 1–1.5 weeks |
| QR scanning (move to Flutter or ZXing.Net) and diagnostics | 1–1.5 weeks |
| Legacy `set_mode`, PID/name edge cases (depends on SDK) | 0.5 week |
| **Subtotal B** | **5–7 engineer-weeks** |
| **SDK team (parallel)**: findings 5.1.1–5.1.5, 5.1.7 and the NativeShims link fix 5.2.1 | 1.5–2.5 weeks |

**Total to retire the Python helper: about 10.5–14.5 engineer-weeks on the app side.** The
largest risks are:
- Windows: the HID elevation path and the NativeShims link issue.
- Older firmware behaviour that wasn't covered here.
- Secret storage, which needs a security review.
