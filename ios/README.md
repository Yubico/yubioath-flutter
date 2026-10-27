# Yubico Authenticator for iOS

## Status and scope

This iOS implementation reuses the Flutter interface and application models from
the Android and desktop apps. Native Swift bridges implement YubiKey operations
using YubiKit Swift instead of Android's Kotlin/YubiKit implementation or the
desktop Python helper.

All main sections are now wired up: **Home, Accounts, Passkeys, Fingerprints,
Certificates, Slots, and Settings**. This does not mean complete feature or
device compatibility parity. In particular, the newly added native operations
still need verification on physical iPhones and YubiKeys.

## What has been ported

| Area | Implemented on iOS |
|---|---|
| Shared interface | Existing Flutter navigation, application views, localization, themes, and saved preferences. |
| Home and device discovery | Read device information through NFC or supported wired connections; publish attach/detach events to Flutter. |
| Device management | Configure enabled applications and supported device configuration fields, configuration lock codes, and device reset where the device supports it. |
| Accounts (OATH) | List, add manually or from QR codes, rename, and delete accounts; calculate TOTP, HOTP, and Steam codes; handle touch-required calculations; set, change, remove, and remember the OATH password; reset OATH. Remembered derived access keys are stored in the iOS Keychain. Imported Base32 secrets are normalized to accept uppercase, lowercase, and space-separated groups. |
| QR scanning | Scan with the rear camera or select an image from the system photo picker. AVFoundation handles the live preview and Vision decodes images. Results feed the shared account/migration parser; manual entry remains available. |
| OATH refresh | Refresh eligible TOTP codes while a wired key is connected and Accounts is active. NFC uses explicit scans rather than continuous polling. |
| Passkeys (FIDO2) | Read authenticator capabilities and PIN state, set/change/verify the PIN, enumerate and delete discoverable credentials, and enable enterprise attestation on compatible keys. |
| Fingerprints (FIDO2) | Enumerate, enroll, rename, and delete fingerprints on compatible keys, including enrollment progress and cancellation. |
| FIDO reset | Reset through an NFC-specific flow. USB reset is not implemented. |
| Certificates (PIV) | Read PIV state and certificate slots; show certificate information; export certificates; import certificates and private keys; generate private keys on the YubiKey, self-signed certificates, and certificate signing requests (CSRs). |
| PIV administration | Verify/change/unblock the PIN, change the PUK, authenticate/change the management key, handle stored or derived PIN-protected management keys, reset PIV, and move/delete keys where supported by firmware. |
| Certificate and key files | Parse PEM/DER certificates, RSA/EC private keys, supported PKCS#8 keys including Ed25519/X25519, common encrypted PEM/PKCS#8 formats, and PKCS#12 identities. Match a certificate to an imported private key. X25519 cannot sign a certificate or CSR. |
| Slots (OTP) | Read both slots; configure Yubico OTP, HOTP, HMAC-SHA1 challenge-response, and static passwords; delete configurations using access codes; swap slots. |
| OTP utilities | Keyboard layouts, random static-password generation, serial-to-modhex encoding, and Yubico OTP CSV export. |
| File handling | Import through the file picker and export certificate, CSR, and OTP CSV bytes through the iOS document picker. |

Passkey management here means managing credentials stored on the YubiKey.
Website registration and sign-in are handled by the browser or operating system,
not by this tab.

### Using the iOS QR scanner

Open **Accounts > Add account > QR scan**. Scan with the rear camera or use
**Read from file** to select an image from the system photo picker. The scanner
does not upload images or account secrets to a service.

Camera access requires permission. If permission is denied, the scanner provides
an action to open Settings; image selection and manual account entry remain
available. Cancelling returns to the account form without saving anything.
Decoded text is passed to the existing shared OATH parser, including its
supported migration-account import flow.

This uses Apple AVFoundation, Vision, and PhotosUI, not the Android-only
`android/flutter_plugins/qrscanner_zxing` plugin. It adds no third-party scanner
dependency and does not change the Android scanner.

## Remaining gaps and differences compared with Android

| Feature | Android implementation | iOS gap or difference |
|---|---|---|
| Camera QR scanning | A native scanner is connected to account setup, including supported migration QR codes. | Implemented using Apple APIs instead of the Android ZXing plugin. Physical camera and permission flows still require device verification. |
| Account setup links | Handles `otpauth://` and `otpauth-migration://` links from other apps. | No equivalent URL registration or link handler is wired up. |
| FIPS secure channels | Discovers SCP11b parameters and supplies secure channels to relevant Management, OATH, PIV, and OTP sessions. | No equivalent secure-channel discovery/setup. Some operations on FIPS keys may therefore fail even though the view exists. |
| Persistent FIDO authorization | Stores supported persistent read-only PIN/UV authentication tokens for later credential management. | Persistent read-only tokens are not stored; the corresponding capability is explicitly disabled. OATH password remembering is separate and is implemented. |
| FIDO reset over USB | Includes USB reset handling on supported devices. | The implemented reset flow advertises NFC only. |
| USB FIDO transport | Uses the FIDO connection interface. | The current bridge runs CTAP2 over the shared smart-card connection; it does not provide equivalent USB FIDO-HID access. FIDO-only keys/interfaces need particular compatibility verification. |
| OTP-HID fallback | Chooses a smart-card or OTP-HID connection depending on the device. | OTP management uses smart-card/CCID access only. No OTP-HID fallback. |
| Legacy USB mode changes | Implements the legacy `setMode` operation. | The native `setMode` handler returns an unsupported error. Newer-device application configuration is a separate, implemented operation. |
| System NFC tap integration | Handles NFC intents and offers tap actions such as launching/copying, plus related preferences. | Uses explicit Core NFC scan sessions. Android's system intent behavior is not a direct iOS port. |
| Native diagnostic logs | Integrates Kotlin/native logs with the app's logging controls and export. | Flutter logging exists, but Swift logs are not integrated into the same pipeline. |
| Android-specific settings | USB launch preferences, NFC preferences, screenshot-protection controls, and system-derived colors. | No equivalent integrations. These require iOS-specific designs where the OS permits them, rather than copying Android settings. |

## Remaining gaps and differences compared with desktop

Desktop means the Windows, macOS, and Linux Flutter app backed by the Python
helper. Some desktop capabilities also depend on OS permissions or installed
drivers.

| Feature | Desktop implementation | iOS gap or difference |
|---|---|---|
| QR import | Decodes QR codes from image data or a screen capture, subject to OS capture support/permissions. | Camera scanning and image decoding are implemented. The scanner offers photo-library selection, not desktop screen capture. |
| Device and reader selection | Enumerates USB devices and external PC/SC smart-card readers, with device-specific paths. | The iOS provider exposes one current device; no equivalent multi-key/external-reader selection. |
| Transport coverage | Uses smart-card, FIDO-HID, and OTP-HID connections as available. FIDO can try its dedicated interface and smart-card transport. | Uses the shared YubiKit Swift smart-card connection path. No equivalent general HID or external PC/SC transport layer. |
| Secure channels | The helper includes SCP11b connection setup. | No corresponding secure-channel setup in the iOS bridges. |
| FIDO USB reset and legacy mode changes | Implements these through the desktop back end where supported. | FIDO reset is NFC-only; legacy `setMode` is unsupported. |
| Desktop integration | Tray/menu-bar behavior, hidden startup, desktop notifications, and saved window position/size. | Not ported. These are desktop-specific conveniences, not missing YubiKey application operations. |
| Diagnostics and launch options | Helper logging, log files, and command-line launch options. | No Python helper or equivalent command-line interface. Swift diagnostics still need app-level integration. |

### Compatibility that is not yet equivalent

- **Certificate imports:** iOS has explicit support for common formats, not the
  full set of encryption algorithms and parsing behavior available through the
  Android and desktop dependencies. Unsupported formats should report an error.
  More fixture-based compatibility testing is needed before claiming parity.
- **Firmware and model differences:** key algorithms, biometric features,
  enterprise attestation, key movement/deletion, and reset support vary by key.
  Implementing an operation does not make it available on every model.
- **Hardware verification:** the new PIV and OTP flows have not yet been verified
  end-to-end on physical hardware. Error recovery, cancellation, older firmware,
  FIPS devices, and wired device combinations need a hardware test matrix.
- **QR verification:** camera permissions, camera lifecycle, and photo selection
  still need physical-device verification. Vision image decoding encountered
  inference limitations in the Simulator; a successful build does not establish
  end-to-end scanner compatibility.

## Where future parity work belongs

| Area | Work in this app | Work in YubiKit Swift or platform constraints |
|---|---|---|
| Account setup links | Register URL schemes, handle cold/warm starts, and route links into shared account import. | No YubiKit changes required. |
| FIPS/SCP11b | Discover Security Domain parameters and supply them to application sessions. | The pinned SDK already exposes Security Domain and SCP11 APIs; the missing integration is primarily local. |
| Persistent FIDO authorization | Keychain storage, device matching, forget behavior, and token invalidation. | A supported token persistence/restoration API is needed: the current token data and initializer are not public. |
| PIV object access | Replace raw Pivman/object commands when SDK APIs become available, including secure-channel-aware handling. | Public object read/write methods or higher-level Pivman helpers would avoid app-side raw commands. |
| Older-key management keys | Remove the local compatibility workaround after upgrading to a fixed SDK. | The pinned SDK incorrectly gates setting 3DES management keys on AES support. |
| Legacy USB mode changes | Connect the existing Flutter operation and handle reconnection if supported. | No public equivalent is exposed by the current Management session; transport support is also required. |
| USB HID and USB FIDO reset | Add connection routing/reset UX only after transport feasibility is established. | SDK HID implementations are macOS-only. iOS access depends on permitted OS APIs, not just adding a Flutter bridge. The CTAP reset command itself already exists. |
| Native logs and import compatibility | Integrate Swift diagnostics and expand certificate/key format fixtures and parsers. | Primarily app work; report concrete SDK defects discovered during hardware testing separately. |

Android background NFC actions and desktop tray/window behavior need
platform-appropriate designs, rather than a direct SDK port.

## Architecture and source map

```text
iOS host: AppDelegate / SceneDelegate
    |
Flutter entry: lib/main.dart -> lib/ios/init.dart
    |
Shared views and models: lib/app/, lib/oath/, lib/fido/, lib/piv/, lib/otp/
    |
Shared provider contracts -> iOS overrides in lib/ios/
    |
Flutter MethodChannels / EventChannels
    |
Swift application managers -> YubiKit Swift -> YubiKey
```

`lib/ios/init.dart` supplies platform implementations through Riverpod overrides.
The existing screens continue to use shared providers rather than calling Swift
directly. iOS does not use Android's Kotlin back end or the desktop Python helper.

| Location | Responsibility |
|---|---|
| `lib/main.dart` | Selects iOS initialization before launching the shared Flutter app. |
| `lib/ios/init.dart` | Registers iOS provider overrides and supported sections. |
| `lib/ios/state.dart` | Adapts native device events to shared Flutter state, section preferences, and the clipboard. |
| `ios/Runner/AppDelegate.swift` | Registers and retains native application managers. |
| `ios/Runner/SceneDelegate.swift` | Uses Flutter's scene lifecycle implementation. |
| `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements` | Application metadata, camera/NFC usage declarations, selected NFC application identifiers, and native capabilities. |
| `ios/Runner.xcodeproj/project.pbxproj` | Native source membership, build settings, signing configuration, and YubiKit dependency. |
| `ios/Runner/QrScanner.swift`, `lib/ios/qr_scanner.dart` | Native camera/photo scanner, Vision image decoding, and shared `QrScanner` adapter. |
| `ios/Management/ManagementManager.swift` | Device discovery/configuration and shared wired connection coordination. |
| `ios/Yubikit/ConnectionHelper.swift` | Connection helpers, including one-shot NFC sessions. |
| `ios/Fido/FidoManager.swift`, `lib/ios/fido/state.dart` | FIDO2, PIN, passkey, fingerprint, and reset bridges. |
| `ios/Oath/OathManager.swift`, `lib/ios/oath/state.dart` | OATH accounts, calculation, password handling, and refresh state. |
| `ios/Piv/PivManager.swift`, `lib/ios/piv/state.dart` | PIV operations, authentication state, and slot snapshots. |
| `ios/Piv/PivCrypto.swift` | Certificate/key parsing, encrypted imports, distinguished names, and certificate/CSR construction. |
| `ios/Otp/`, `lib/ios/otp/state.dart` | OTP slot operations, keyboard layouts, and local utilities. |
| `test/ios/`, `ios/RunnerTests/RunnerTests.swift` | Flutter bridge/provider tests and native certificate/key and QR image-decoding tests. |

The unused prototype serial-reading channel, `DeviceInfoHelper`, `DeviceManager`
stub, and `AppContextManager` protocol have been removed. Active device discovery
and wired connection ownership live in `ManagementManager`, not a separate
device-manager scaffold.

The managers share Management's wired connection coordinator rather than starting
competing USB monitors. Initial OATH and PIV reads return snapshots shared by
their related providers; mutations publish updated snapshots instead of opening
another NFC scan just to refresh. Initial read failures are surfaced without
automatic provider retries repeatedly reopening the NFC prompt. Individual
application busy guards exist, but cross-application NFC serialization is not
yet a shared coordinator.

Native application responses use JSON strings with the field names expected by
the shared models. This avoids nested platform-channel map conversion issues.
Local operations such as file inspection, subject validation, and OTP utilities
do not require an NFC scan.

YubiKit Swift is pinned to revision
`e19212f2efbca9af280e57542e669885de5acdc1`.