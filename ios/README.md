# iOS scaffold

This branch contains the iOS host project and Flutter launch path for Yubico
Authenticator. Device management and the shared connection layer are
implemented; other applets will be introduced separately.

The Accounts (OATH), Passkeys (FIDO), Certificates (PIV), Slots (OTP), and
Settings sections display **Currently not implemented**.

Home detects wired YubiKeys and provides an NFC scan action. It displays device
information and exposes application configuration through the shared management
dialog, including SCP11b for FIPS-capable keys over NFC. Global device reset is
available on supported multi-protocol YubiKey Bio devices. Individual applet
resets remain disabled. Legacy `setMode` is not supported by YubiKit Swift and
returns an explicit unsupported error.

## Run on iPhone

1. Install Flutter and Xcode, then run `flutter pub get` from the repository root.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select the Runner target, configure signing with an Apple development team,
   enable the NFC Tag Reading capability for the signing profile, and select a
   connected iPhone.
4. Build and run the Runner scheme.

The project uses the standard Flutter iOS host and links YubiKit Swift from
the `release/1.5.0` branch through Swift Package Manager. Implement applets in
separate changes while keeping this scaffold buildable.
