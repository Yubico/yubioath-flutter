import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/core/state.dart';

import 'oath_test_util.dart';
import 'test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  var startupParams = {};

  if (isAndroid) {
    /// default android parameters
    startupParams = {'dlg.beta.enabled': false, 'delay.startup': 5};
    testWidgets('Android app boot', (WidgetTester tester) async {
      /// delay first start
      await tester.startUp(startupParams);

      /// remove delay.startup
      startupParams = {'dlg.beta.enabled': false};
    });
  }

  group('OATH UI validation', () {
    testWidgets('Menu items exist', (WidgetTester tester) async {
      await tester.startUp(startupParams);
      await tester.tapDeviceButton();
      expect(find.byKey(deviceMenuAddAccountKey), findsOneWidget);
      expect(find.byKey(deviceMenuSetManagePasswordKey), findsOneWidget);
      expect(find.byKey(deviceMenuResetOathKey), findsOneWidget);
    });
  });

  group('OATH Account tests', () {
    testWidgets('Create account', (WidgetTester tester) async {
      await tester.startUp(startupParams);

      // account with issuer
      var testAccount = const Account(
        issuer: 'IssuerForTests',
        name: 'NameForTests',
        secret: 'aaaaaaaaaaaaaaaa',
      );

      await tester.deleteAccount(testAccount);
      await tester.addAccount(testAccount, quiet: false);

      // account without issuer
      testAccount = const Account(
        name: 'NoIssuerName',
        secret: 'bbbbbbbbbbbbbbbb',
      );

      await tester.deleteAccount(testAccount);
      await tester.addAccount(testAccount, quiet: false);
    });

    /// deletes accounts created in previous test
    testWidgets('Delete account', (WidgetTester tester) async {
      await tester.startUp(startupParams);

      var testAccount =
          const Account(issuer: 'IssuerForTests', name: 'NameForTests');

      await tester.deleteAccount(testAccount, quiet: false);
      expect(await tester.findAccount(testAccount), isNull);

      testAccount = const Account(issuer: null, name: 'NoIssuerName');
      await tester.deleteAccount(testAccount, quiet: false);
      expect(await tester.findAccount(testAccount), isNull);
    });

    /// adds an account, renames, verifies
    testWidgets('Rename account', (WidgetTester tester) async {
      await tester.startUp(startupParams);

      var testAccount =
          const Account(issuer: 'IssuerToRename', name: 'NameToRename');

      /// delete account if it exists
      await tester.deleteAccount(testAccount);
      await tester.deleteAccount(
          const Account(issuer: 'RenamedIssuer', name: 'RenamedName'));

      await tester.addAccount(testAccount);
      await tester.renameAccount(testAccount, 'RenamedIssuer', 'RenamedName');
    });
  });

  group('OATH Password Quick tests', () {
    /// note that the password groups should be run as whole
    /// this is quick test as we cannot restart android app during 1 testrun
    testWidgets('OATH: set oath password', (WidgetTester tester) async {
      await tester.startUp(startupParams);
      await tester.setOathPassword('aaa111');
    });

    /// note - we cannot 'restart' the app to [unlockOathApp]

    /// testWidgets('OATH: replace oath password', (WidgetTester tester) async {
    ///   await tester.startUp(startupParams);
    ///   await tester.replaceOathPassword('aaa111', 'bbb222');
    /// });

    testWidgets('OATH: remove oath password', (WidgetTester tester) async {
      await tester.startUp(startupParams);
      await tester.removeOathPassword('aaa111');
    });
  });
}
