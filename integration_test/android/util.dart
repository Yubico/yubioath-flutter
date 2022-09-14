import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/init.dart';
import 'package:yubico_authenticator/android/keys.dart' as android_keys;
import 'package:yubico_authenticator/android/qr_scanner/qr_scanner_view.dart';
import 'package:yubico_authenticator/app/views/device_avatar.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;

import '../test_util.dart';
import 'constants.dart';

void _setShowBetaDialogPref(bool value) async {
  SharedPreferences.setMockInitialValues({betaDialogPrefName: value});
}

Future<void> startUp(WidgetTester tester,
    [Map<dynamic, dynamic> startUpParams = const {}]) async {
  // on Android disable Beta welcome dialog
  // we need to do it before we pump the app
  var betaDlgEnabled = startUpParams['dlg.beta.enabled'] ?? false;
  _setShowBetaDialogPref(betaDlgEnabled);

  await tester.pumpWidget(await initialize());

  // only wait for yubikey connection when needed
  // needs_yubikey defaults to true
  if (startUpParams['needs_yubikey'] != false) {
    // wait for a YubiKey connection
    await tester.waitForFinder(find.descendant(
        of: tester.findDeviceButton(),
        matching: find.byWidgetPredicate((widget) =>
            widget is DeviceAvatar && widget.key != app_keys.noDeviceAvatar)));
  }

  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> grantCameraPermissions(WidgetTester tester) async {
  await tester.waitForFinder(find.byType(QrScannerView));

  await tester.longWait();

  /// on android a QR Scanner starts
  /// we want to do a manual addition
  var manualEntryBtn = find.byKey(android_keys.manualEntryButton).hitTestable();

  if (manualEntryBtn.evaluate().isEmpty) {
    tester.testLog(false, 'Allow camera permission');
    manualEntryBtn = await tester.waitForFinder(manualEntryBtn);
  }

  await tester.tap(manualEntryBtn);
  await tester.longWait();
}
