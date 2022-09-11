import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_util.dart';
import 'constants.dart';

class AndroidTestUtils {
  static void setShowBetaDialogPref(bool value) async {
    SharedPreferences.setMockInitialValues({betaDialogPrefName: value});
  }

  static Future<void> startUp(WidgetTester tester,
      [Map<dynamic, dynamic>? startUpParams]) async {
    // on Android disable Beta welcome dialog
    // we need to do it before we pump the app
    var betaDlgEnabled = startUpParams?['dlg.beta.enabled'] ?? false;
    setShowBetaDialogPref(betaDlgEnabled);

    await tester.pumpWidget(
        await getAuthenticatorApp(), const Duration(milliseconds: 500));

    var startupDelay = startUpParams?['delay.startup'] ?? 0;
    if (startupDelay != 0) {
      tester.printToConsole('Connect YubiKey and approve USB Connection');
      await tester.pump(Duration(seconds: startupDelay));
      tester.printToConsole('Assuming YubiKey connected');
    }
  }
}
