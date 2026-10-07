# Feedback for the v2 Yubico .NET SDK team

From a throwaway experiment: we reimplemented Yubico Authenticator's desktop helper (today Python +
yubikey-manager) on the v2 SDK, published it with Native AOT, and ran it inside the real app on
macOS against a YubiKey 5 NFC (firmware 5.8.0 alpha). The experiment won't ship. Its purpose was to
find friction for an app-shaped consumer. Everything below concerns the SDK repository only.

Checked against:
- `Yubico.YubiKit.NET.SDK` `yubikit` at `df1ec06d` (up to date with origin),
- `Yubico.NativeShims` 1.18.1 (tag `nativeshims-1.18.1` = `develop` at `941874e9`, the latest).

Each item includes evidence and a suggested change. "Verified" means reproduced; anything else is
marked.

Contents:
1. Bugs and divergences from canonical yubikit
2. Native AOT on every platform
3. IUserPresencePrompt
4. API additions that would remove consumer workarounds
5. Smaller observations

---

## 1. Bugs and divergences from canonical yubikit

### 1.1 Native AOT publish fails to link on Linux (and very likely Windows) with NativeShims 1.18.1

**Verified.** The SDK's own `verification/NativeAotVerification` host fails on `linux-arm64`
(clean container, `mcr.microsoft.com/dotnet/sdk:10.0`, `clang zlib1g-dev libpcsclite-dev`):

```
undefined reference to `Native_HidInputCancel'
undefined reference to `Native_HidInputCreate'
undefined reference to `Native_HidInputDestroy'
undefined reference to `Native_HidInputStart'
undefined reference to `Native_HidInputWaitShutdown'
error MSB3073: ... clang ... exited with code 1
```

**Cause.**
- `Yubico.NativeShims.targets` turns every NativeShims P/Invoke into a `DirectPInvoke` against the
  static archive for the RID.
- `Core/src/Native/MacOS/HidInput/HidInput.Interop.cs` binds five macOS-only entry points, used by
  `MacOSFidoHidConnection`.
- Those entry points are compiled only `if(APPLE)` (`Yubico.NativeShims/CMakeLists.txt:183-187`).
- So the macOS archive exports them (5 symbols) and the Linux and Windows archives don't (0 symbols;
  checked with `nm`, and with `strings` on `win-x64/Yubico.NativeShims.lib`). Native AOT then
  resolves them at link time on every OS.

**Why CI doesn't catch it.** The recurring Native AOT job only publishes on macOS.
- The binding arrived with `89420aa6` (2026-09-23, "add macOS HID lifetime owners").
- The Linux x64 and Windows x64 publish evidence in `docs/NATIVE-AOT.md` is from `0450766e`
  (2026-08-21), before the binding.

So the support statement is currently stale for those platforms.

**Suggested fix (either):**
- Build no-op stubs for `Native_HidInput*` on non-Apple platforms, returning a "not supported"
  status.
- Keep the macOS HID input entry points out of `DirectPInvoke` on non-macOS RIDs, for example
  per-entry-point `DirectPInvoke` items, or a separate library name for the macOS-only shim.

Also add Linux and Windows publish jobs (no hardware needed) so a link break fails CI.

**Consumer workaround used:** `-Wl,--unresolved-symbols=ignore-in-object-files` on Linux RIDs. This
isn't acceptable to recommend.

### 1.2 `OathSession.CalculateAsync` returns `[digits byte][HMAC]`, not the HMAC

**Verified** on hardware: a SHA-1 credential returned 21 bytes, the first being `06`.
- `IOathSession.CalculateAsync` documents "the full HMAC response".
- `OathSession.cs` returns `tlv.Value.ToArray()` for `TAG_RESPONSE` unchanged.
- Canonical implementations strip the leading digits byte: yubikit-python `calculate()` returns
  `resp[1:]` (`yubikit/oath.py`), and yubikit-android `calculateResponse` returns
  `Arrays.copyOfRange(response, 1, response.length)` (`OathSession.java:475`).
- Consumers that compute Steam codes or raw challenge-response values from this output get wrong
  results.
- The existing unit tests only assert that the command was sent, not the returned bytes.

**Suggested fix:** return `Value[1..]` to match yubikit (or rename and document if raw is
intended), and add a unit test on the returned bytes.

---

## 2. Native AOT on every platform

The goal is that consumers can publish with Native AOT on Windows, Linux and macOS.

**What worked well.**
- All SDK modules linked into a size-optimised, warnings-as-errors Native AOT executable on macOS
  without a single trimming or AOT warning from SDK code.
- The binary is 6.6 MB (arm64).
- `osx-x64` cross-architecture builds from Apple Silicon also worked, so a universal binary is just
  `lipo`.
- On macOS, NativeShims links statically and emits no dylib, so there's nothing extra to sign or
  notarize.

**Friction, in order of impact:**
1. The Linux and Windows link failure (1.1). This is a blocker off macOS.
2. **Build prerequisites aren't documented for consumers.** Linux publish needs `libpcsclite-dev`
   at link time (`-lpcsclite` from NativeShims), on top of the standard `clang`/`zlib1g-dev`.
   - At runtime the binary needs `libpcsclite.so.1`.
   - It also needs `libssl` once `System.Security.Cryptography` is used (for example PIV
     certificate work).
   - Suggest a "Publishing with Native AOT" section in the consumer docs and package readme: per-OS
     build and runtime prerequisites, and that Native AOT needs a native runner per OS.
3. **`nuget.config` maps `Yubico.NativeShims` to the authenticated GitHub Packages feed as well as
   nuget.org.** Anyone building from source without GitHub credentials (external contributors, a
   clean container) gets `NU1301 401 Unauthorized`, even though 1.18.1 is on nuget.org. Suggest
   making the private feed opt-in (for example a `nuget.dev.config`) so the default restore works
   anonymously.
4. **Pre-release firmware surfaces as 0.0.1.** This is minor but visible: `PivSession` and
   `OathSession` report `FirmwareVersion` 0.0.1 on a 5.8.0-alpha key. SDK feature gates handle this
   correctly (`IsAlphaOrBeta` is treated as newest). But consumers who display the version, or
   forward it to their own logic, need the real one. yubikit applies the version qualifier
   globally.
   - Suggest exposing the effective version (for example `DeviceInfo.EffectiveFirmwareVersion`), or
     documenting `SessionCreationOptions.FirmwareVersionOverride` for this case. We used the
     override.

(Out of SDK scope, for context: .NET's MSBuild crashes under QEMU x64 emulation on Apple Silicon.
So `linux-x64` can't be built in an emulated container either, and native runners are required.)

---

## 3. IUserPresencePrompt

**Overall: a clear improvement.** yubikey-manager consumers guess touch with timers ("if this
hasn't returned in 0.5 s, show the touch prompt"). With `SessionCreationOptions.UserPresencePrompt`,
the FIDO reset touch produced an accurate, immediate prompt on hardware with no heuristics. OATH
touch-required credentials use the same mechanism, but we didn't exercise them with a touch
credential. The contract (sessions retain but don't own the prompt; `Application`, `Operation` and
`Basis` on the context) was easy to map to UI.

Gaps we hit:
1. **PIV management-key authentication with a touch policy emits nothing.** A management key can
   have touch policy always or cached, which `GetManagementKeyMetadataAsync().TouchPolicy` reports.
   But `UserPresenceOperations.Piv` only covers `SignOrDecrypt`, `Decrypt` and `CalculateSecret`,
   so `AuthenticateAsync` blocks silently waiting for a touch. Suggest a `Piv.Authenticate`
   operation with `Basis = PolicyRequires` when the metadata says so (`PolicyMayRequire` before
   5.3, when there is no metadata).
2. **HOTP credentials never notify.** OATH notifies only when `Credential.TouchRequired is true`.
   The device doesn't report touch for HOTP in `CALCULATE ALL`, and `ListCredentialsAsync` returns
   `TouchRequired = null`, so a touch-required HOTP credential blocks silently. Consumers still
   need the 0.5 s timer. Suggest notifying with `Basis = PolicyMayRequire` when `TouchRequired` is
   unknown for HOTP (optionally after a short delay), mirroring what FIDO reset does.
3. **FIDO keepalive "processing" isn't surfaced.** python-fido2 exposes `STATUS.PROCESSING` as
   well as `UPNEEDED`. yubikey-manager consumers show "please wait" during long operations, such as
   a reset after the touch. Consider an outcome or extra notification for processing, or document
   that only user presence is reported.
4. **Routing a session-scoped prompt to the current request is left to the consumer.** An app that
   serves many requests over one long-lived session has to correlate callbacks with the request
   that triggered them. We used an `AsyncLocal` set per request. That works, because callbacks run
   on the caller's async flow, but it isn't documented as guaranteed. Suggest either documenting
   that callbacks run on the calling operation's async context (so `AsyncLocal` is safe), or
   accepting an optional per-call prompt.

---

## 4. API additions that would remove consumer workarounds

Each of these was reimplemented in the experiment. They'd be natural in the SDK because every
UI consumer needs them.

| # | Addition | Why | yubikit reference |
|---|---|---|---|
| 4.1 | **Product name from `DeviceInfo`**, for example `DeviceInfo.GetProductName()` → "YubiKey 5C Nano", "YubiKey 5 NFC - Enhanced PIN", "Security Key NFC - Enterprise Edition" | Every UI shows it. The rules (form factor, NFC, FIPS, Bio editions, SKY, Enhanced PIN, NEO, YK4/Edge/Preview) are non-trivial and change with new products. Only a form-factor formatter exists, in `Cli.Shared`. | `yubikit.support.get_name()` |
| 4.2 | **USB product id (PID) on `IYubiKey`** | It's needed for naming (4.1 needs the key type for Security Key and NEO) and for interface reporting. We rebuilt it from `AvailableConnections`, which can't tell a Security Key from a FIDO-only YubiKey 5. | `ykman.device` `pid` / `PID.yubikey_type` |
| 4.3 | **Expose the discovery `DeviceInfo` on `IYubiKey`** | `YubiKeyDevice.DeviceInfo` is already read during discovery but is internal, so listing names needs an extra Management connection per device. | `list_all_devices()` returns `(device, info)` |
| 4.4 | **Reinsert helper for FIDO reset** | Reset must happen within seconds of insertion. Every app implements "wait for removal, wait for the same key to come back, then reset", including the hard part: refusing to reset a different key, matching by serial, and handling FIDO-only keys without a serial. | `ykman` `YkmanDevice.reinsert(reinsert_cb, event)` |
| 4.5 | **PIV signing for CSRs and self-signed certificates**: an `X509SignatureGenerator` (or `CreateSigningRequestAsync` / `CreateSelfSignedAsync` helpers) backed by `SignOrDecryptAsync` | Consumers otherwise hand-build EMSA-PKCS1-v1_5 padding plus DigestInfo for raw RSA, and the ECDSA hash selection. The working code exists only in `examples/PivTool`. The `PivSlotMetadataExtensions` docs point at `CertificateRequest`, which can't sign without this. | `ykman.piv.generate_csr`, `generate_self_signed_certificate` |
| 4.6 | **Public key from slot metadata as `IPublicKey` / SPKI**, including Ed25519/X25519 | `GenerateKeyAsync` returns `IPublicKey` (SPKI export), but `PivSlotMetadata.PublicKey` is raw PIV TLV. The extensions only cover `RSA`/`ECDsa`, so 25519 slots need hand-built SPKI. | `SlotMetadata.public_key` |
| 4.7 | **Public "PKCS#8 → `IPrivateKey`" for any key type** | `AsnPrivateKeyDecoder.CreatePrivateKey` is internal, so importing a file into PIV means try-RSA-then-EC with the typed factories. | `parse_private_key` |
| 4.8 | **Typed exception for PIV "management key authentication required"** | `PivKeyProtocol` / `PivCertificateProtocol` throw a plain `InvalidOperationException` with a string message before any APDU. Callers that re-authenticate on demand must check `IsManagementKeyAuthenticated` after catching a generic exception. | the device's SW 0x6982 surfaces as `ApduError` |
| 4.9 | **Legacy `SetMode` (YubiKey NEO / 4 interface switching)** | Already tracked in `docs/migration/v1-to-v2-gaps.md`. Listed only to confirm a real consumer needs it. | `ManagementSession.set_mode` |

---

## 5. Smaller observations

- **`DeviceInfo` equality isn't value equality.** The `record struct` has `ReadOnlyMemory<byte>`
  and class-typed members, so `==` compares references. "Did a config change alter the device?"
  needs a hand-written comparison. Consider custom equality, or documenting it.
  `ChallengeResponseTimeout` is a `ReadOnlyMemory<byte>`, not a number.
- **`OathSession.PutCredentialAsync` returns nothing.** Callers rebuild the `Credential` (id,
  touch flag) themselves. Returning the stored `Credential` would match yubikit.
- **`CredentialManagement` takes a concrete `FidoSession`.** `ClientPin`, `AuthenticatorConfig` and
  `FingerprintBioEnrollment` take `IFidoSession`.
- **`PinRetryStatus.PowerCycleRequired` is `bool`.** python-fido2 reports `None` when the
  authenticator omits the field. This is harmless; mentioned only for parity.
- **Choosing `PinUvAuthProtocolV1`/`V2` from `AuthenticatorInfo.PinUvAuthProtocols` is left to the
  caller.** A small factory would avoid every consumer writing the same selection.

---

## How these were found (for reproducibility)

The experiment sent identical command sequences to the existing Python helper (yubikit) and to the
.NET implementation, then diffed the decoded results field by field. With yubikit as the reference,
the diff found 1.2 (different bytes for the same OATH calculation) and 2.4 (version 0.0.1 vs 5.8.0)
mechanically, rather than by code reading.

The rest of that comparison matched: the same OATH codes and derived keys, the same PIV
certificates and metadata, and the same FIDO info and PIN-retry semantics. That's useful
confidence for the team.

If useful, the same technique could be a conformance check in the SDK: run SDK operations and the
equivalent yubikit-python calls against the same test key and compare outputs.
