# iOS scaffold

This branch contains the iOS host project and Flutter launch path for Yubico
Authenticator. It is an applet-by-applet starting point; no YubiKey applet
operations are implemented.

The Accounts (OATH), Passkeys (FIDO), Certificates (PIV), Slots (OTP), and
Settings sections display **Currently not implemented**.
The app does not open NFC, USB, or YubiKit connections.

## Run on iPhone

1. Install Flutter and Xcode, then run `flutter pub get` from the repository root.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select the Runner target, configure signing with an Apple development team,
   and select a connected iPhone.
4. Build and run the Runner scheme.

The project uses the standard Flutter iOS host and links YubiKit Swift from
the `release/1.5.0` branch through Swift Package Manager. Implement applets in
separate changes while keeping this scaffold buildable.
