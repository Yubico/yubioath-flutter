import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_util.dart';
import 'constants.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Beta welcome dialog', () {
    testWidgets('startup', (WidgetTester tester) async {
      await tester.startUp({
        'dlg.beta.enabled': false,
        'delay.startup': 5,
      });
    });

    testWidgets('shows welcome screen', (WidgetTester tester) async {
      await tester.startUp({
        'dlg.beta.enabled': true,
      });
      expect(find.byKey(betaDialogKey), findsOneWidget);
    });

    testWidgets('does not show welcome dialog', (WidgetTester tester) async {
      await tester.startUp();
      expect(find.byKey(betaDialogKey), findsNothing);
    });

    testWidgets('updates preferences', (WidgetTester tester) async {
      await tester.startUp({'dlg.beta.enabled': true});
      var prefs = await SharedPreferences.getInstance();
      await tester.tap(find.byKey(gotItBtn));
      await expectLater(prefs.getBool(betaDialogPrefName), equals(false));
    });
  });
}
