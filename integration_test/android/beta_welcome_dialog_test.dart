import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/keys.dart' as keys;

import '../android/util.dart' as android_test_util;
import 'constants.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Beta welcome dialog', () {
    testWidgets('shows welcome screen', (WidgetTester tester) async {
      await android_test_util.startUp(tester, {
        'dlg.beta.enabled': true,
        'needs_yubikey': false,
      });

      expect(find.byKey(keys.betaDialogView), findsOneWidget);
    });

    testWidgets('does not show welcome dialog', (WidgetTester tester) async {
      await android_test_util.startUp(tester, {
        'dlg.beta.enabled': false,
        'needs_yubikey': false,
      });
      expect(find.byKey(keys.betaDialogView), findsNothing);
    });

    testWidgets('updates preferences', (WidgetTester tester) async {
      await android_test_util.startUp(tester, {
        'dlg.beta.enabled': true,
        'needs_yubikey': false,
      });
      var prefs = await SharedPreferences.getInstance();
      await tester.tap(find.byKey(keys.okButton));
      await expectLater(prefs.getBool(betaDialogPrefName), equals(false));
    });
  });
}
