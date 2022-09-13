import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/android/init.dart' as android;
import 'package:yubico_authenticator/app/views/device_button.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/desktop/init.dart' as desktop;

import 'android/util.dart';
import 'approved_yubikeys.dart';

Future<Widget> getAuthenticatorApp() async => isDesktop
    ? await desktop.initialize([])
    : isAndroid
        ? await android.initialize()
        : throw UnimplementedError('Platform not supported');

const shortestWaitMs = 10;
const shortWaitMs = 50;
const longWaitMs = 200;
const veryLongWaitS = 10; // seconds

/// information about YubiKey as seen by the app
String? yubiKeyName;
String? yubiKeyFirmware;
String? yubiKeySerialNumber;
bool collectedYubiKeyInformation = false;

extension AppWidgetTester on WidgetTester {
  Future<void> shortestWait() async {
    await pump(const Duration(milliseconds: shortestWaitMs));
  }

  Future<void> shortWait() async {
    await pump(const Duration(milliseconds: shortWaitMs));
  }

  Future<void> longWait() async {
    await pump(const Duration(milliseconds: longWaitMs));
  }

  Future<void> veryLongWait() async {
    await pump(const Duration(seconds: veryLongWaitS));
  }

  Finder findDeviceButton() {
    return find.byType(DeviceButton).hitTestable();
  }

  /// Taps the device button
  Future<void> tapDeviceButton() async {
    await tap(findDeviceButton());
    await pump(const Duration(milliseconds: 500));
  }

  Future<void> startUp([Map<dynamic, dynamic>? startUpParams]) async {
    var result = isAndroid == true
        ? await AndroidTestUtils.startUp(this, startUpParams)
        : await pumpWidget(
            await getAuthenticatorApp(), const Duration(milliseconds: 2000));

    await getDeviceInfo();

    if (!approvedYubiKeys.contains(yubiKeySerialNumber)) {
      testLog(false,
          'The connected key is refused by the tests: $yubiKeySerialNumber');
      expect(approvedYubiKeys.contains(yubiKeySerialNumber), equals(true));
    }

    return result;
  }

  void testLog(bool quiet, String message) {
    if (!quiet) {
      printToConsole(message);
    }
  }

  /// get key information
  Future<void> getDeviceInfo() async {
    if (collectedYubiKeyInformation) {
      return;
    }

    await tapDeviceButton();

    var deviceInfo = find.byKey(app_keys.deviceInfoListTile);
    if (deviceInfo.evaluate().isNotEmpty) {
      ListTile lt = deviceInfo.evaluate().single.widget as ListTile;
      yubiKeyName = (lt.title as Text).data;
      var subtitle = (lt.subtitle as Text?)?.data;

      if (subtitle != null) {
        RegExpMatch? match = RegExp(r'S/N: (?<SN>\d.*) F/W: (?<FW>\d\.\d\.\d)')
            .firstMatch(subtitle);
        if (match != null) {
          yubiKeySerialNumber = match.namedGroup('SN');
          yubiKeyFirmware = match.namedGroup('FW');
        } else {
          match = RegExp(r'F/W: (?<FW>\d\.\d\.\d)').firstMatch(subtitle);
          if (match != null) {
            yubiKeyFirmware = match.namedGroup('FW');
          }
        }
      }
    }

    // close the opened menu
    await tapAt(const Offset(0, 0));
    await longWait();

    testLog(false,
        'Connected YubiKey: $yubiKeySerialNumber/$yubiKeyFirmware - $yubiKeyName');

    if (!approvedYubiKeys.contains(yubiKeySerialNumber)) {
      testLog(false,
          'Connected YubiKey (SN: $yubiKeySerialNumber) is not approved for integration tests');
      exit(-1);
    }

    collectedYubiKeyInformation = true;
  }
}
