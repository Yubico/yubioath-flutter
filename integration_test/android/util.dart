import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/init.dart';

import 'constants.dart';

// track the first start and use longer delay
bool _firstStart = true;
const int _firstStartDelaySec = 5;

void _setShowBetaDialogPref(bool value) async {
  SharedPreferences.setMockInitialValues({betaDialogPrefName: value});
}

Future<void> startUp(WidgetTester tester,
    [Map<dynamic, dynamic> startUpParams = const {}]) async {
  // on Android disable Beta welcome dialog
  // we need to do it before we pump the app
  var betaDlgEnabled = startUpParams['dlg.beta.enabled'] ?? false;
  _setShowBetaDialogPref(betaDlgEnabled);

  if (_firstStart) {
    tester.printToConsole('First app start: Connect YubiKey and approve USB Connection');
  }

  await tester.pumpWidget(
      await initialize(),
      _firstStart
          ? const Duration(seconds: _firstStartDelaySec)
          : const Duration(milliseconds: 500));

  if (_firstStart) {
    _firstStart = false;
  }
}
