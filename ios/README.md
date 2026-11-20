# iOS scaffold

This branch contains the iOS host project and Flutter launch path for Yubico
Authenticator. Device management and the shared connection layer are
implemented; other applets will be introduced separately.

The Accounts (OATH), Passkeys (FIDO), Certificates (PIV), Slots (OTP), and
Settings sections display **Currently not implemented**.

Home detects wired YubiKeys and starts an NFC scan when pulled down, including
when a key is already displayed. It displays device
information and exposes application configuration through the shared management
dialog, including SCP11b for FIPS-capable keys over NFC. Global device reset is
available on supported multi-protocol YubiKey Bio devices. Individual applet
resets remain disabled. Legacy `setMode` is not supported by YubiKit Swift and
returns an explicit unsupported error.

Configuration and reset operations stay on the displayed key's transport and
verify its serial number before changing the device. If neither the displayed
nor connected key has a readable serial, firmware version, form factor,
supported capabilities, and FIPS/Security Key flags are compared instead.
That fallback cannot distinguish two identical keys without serial numbers.
A disconnected USB target is rejected rather than falling back to NFC.

The wired monitor retains its connection for normal operations. NFC scans and
management operations share a single operation gate; overlapping requests return
a busy error. Configuration changes requiring a reboot close the old wired
connection and let the monitor reconnect. The manager owns the monitor task and
can cancel operations and close connections explicitly during shutdown.

iOS USB management currently supports smart card (CCID) connections only.
Configuration must retain at least one USB smart card application: OATH, PIV,
OpenPGP, or YubiHSM Auth. This restriction also applies when configuring over NFC,
so a scanned key is not left inaccessible over USB. Android's existing
transport restrictions are unchanged.

Cancelling an NFC scan dismisses it without an error message. Cancelling a
configuration or reset leaves the dialog open without reporting success.
Wired connection and initial metadata-read failures appear on Home instead of
being shown as no key connected.

Device events are stored and delivered synchronously on the main actor. Removing
a wired key does not clear a key displayed from an NFC scan. A successful
configuration or reset remains successful if the follow-up metadata read fails;
Home then reports that updated information could not be read. A reboot clears
the displayed key until reconnection or another NFC scan rather than publishing
the pre-write configuration.

Product names come from YubiKit's connection API. USB PID remains unavailable
instead of being inferred from the enabled applications. Native failures use
level-controlled system logging; Dart failures use the app's named loggers.

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
