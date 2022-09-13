import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/keys.dart' as keys;

import '../test_util.dart';
import 'constants.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Beta welcome dialog', () {

    // this is here to make sure yubikey is connected before we test the dialog
    testWidgets('startup', (WidgetTester tester) async {
      await tester.startUp({
        'dlg.beta.enabled': false,
      });
    });

    testWidgets('shows welcome screen', (WidgetTester tester) async {
      await tester.startUp({
        'dlg.beta.enabled': true,
      });

      expect(find.byKey(keys.betaDialogView), findsOneWidget);
    });

    testWidgets('does not show welcome dialog', (WidgetTester tester) async {
      await tester.startUp();
      expect(find.byKey(keys.betaDialogView), findsNothing);
    });

    testWidgets('updates preferences', (WidgetTester tester) async {
      await tester.startUp({'dlg.beta.enabled': true});
      var prefs = await SharedPreferences.getInstance();
      await tester.tap(find.byKey(keys.okButton));
      await expectLater(prefs.getBool(betaDialogPrefName), equals(false));
    });
  });
}
