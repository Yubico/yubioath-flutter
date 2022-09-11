import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/oath/views/account_list.dart';
import 'package:yubico_authenticator/oath/views/account_view.dart';
import 'package:yubico_authenticator/oath/views/oath_screen.dart';

import 'test_util.dart';

Future<void> addDelay(int ms) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
}

String generateIssuer(int index) {
  return 'issuer_${index.toString().padLeft(4, '0')}';
}

String generateName(int index) {
  return 'name_${index.toString().padLeft(4, '0')}';
}

String base32(int i) {
  var m = (i % 32);
  return m < 26 ? String.fromCharCode(65 + m) : '${2 + m - 26}';
}

/// generates 16 chars Base32 string
String generateSecret(int index) {
  return List.generate(16, (_) => base32(index)).toString();
}

class OathDeviceMenu {
  static const addAccountKey = Key('add oath account');
  static const setManagePasswordKey = Key('set or manage oath password');
  static const resetKey = Key('reset oath app');
}

const qrScannerEnterManuallyKey = Key('android.qr_scanner.btn.enter_manually');
const deleteAccountBtnKey = Key('oath.dlg.delete_account.btn.delete');
const renameAccountBtnSaveKey = Key('oath.dlg.rename_account.btn.save');
const renameAccountEditIssuerKey = Key('oath.dlg.rename_account.edit.issuer');
const renameAccountEditNameKey = Key('oath.dlg.rename_account.edit.name');

const shortestWaitMs = 10;
const shortWaitMs = 50;
const longWaitMs = 200;
const veryLongWaitS = 10; // seconds

class Account {
  final String? issuer;
  final String name;
  final String secret;

  const Account({
    this.issuer,
    this.name = '',
    this.secret = 'abcdefghabcdefgh',
  });

  @override
  String toString() => '$issuer/$name';
}

extension OathHelper on WidgetTester {
  /// Opens the device menu and taps the "Add account" menu item

  Future<void> shortestWait() async {
    testLog(false, 'shortestWait ${shortestWaitMs}ms');
    await pump(const Duration(milliseconds: shortestWaitMs));
  }

  Future<void> shortWait() async {
    testLog(false, 'shortWait ${shortWaitMs}ms');
    await pump(const Duration(milliseconds: shortWaitMs));
  }

  Future<void> longWait() async {
    testLog(false, 'longWait ${longWaitMs}ms');
    await pump(const Duration(milliseconds: longWaitMs));
  }

  Future<void> veryLongWait() async {
    testLog(false, 'veryLongWait ${veryLongWaitS}s');
    await pump(const Duration(seconds: veryLongWaitS));
  }

  Future<void> tapAddAccount() async {
    await tapDeviceButton();
    await tap(find.byKey(OathDeviceMenu.addAccountKey).hitTestable());
    await longWait();
  }

  /// Opens the device menu and taps the "Set/Manage password" menu item
  Future<void> tapSetOrManagePassword() async {
    await shortWait();
    await tapDeviceButton();
    await tap(find.byKey(OathDeviceMenu.setManagePasswordKey));
    await longWait();
  }

  Future<void> addAccount(Account a, {bool quiet = true}) async {
    var accountView = await findAccount(a);
    if (accountView != null) {
      testLog(quiet, 'Account already exists: $a');
      return;
    }

    await tapAddAccount();

    if (isAndroid) {
      // on android a QR Scanner starts
      // we want to do a manual addition
      var manualEntryBtn = find.byKey(qrScannerEnterManuallyKey).hitTestable();
      if (manualEntryBtn.evaluate().isEmpty) {
        printToConsole('Allow camera permission');
        await pump(const Duration(seconds: 2));
        manualEntryBtn = find.byKey(qrScannerEnterManuallyKey).hitTestable();
      }

      await tap(manualEntryBtn);
      await longWait();
    }

    var issuerText = find.byKey(const Key('issuer')).hitTestable();
    await tap(issuerText);
    await enterText(issuerText, a.issuer ?? '');
    await shortWait();
    var nameText = find.byKey(const Key('name')).hitTestable();
    await tap(nameText);
    await enterText(nameText, a.name);
    await shortWait();
    var secretText = find.byKey(const Key('secret')).hitTestable();
    await tap(secretText);
    await enterText(secretText, a.secret);
    await shortWait();

    await tap(find.byKey(const Key('save_btn')));

    await longWait();

    accountView = await findAccount(a);
    expect(accountView, isNotNull);
    if (accountView != null) {
      testLog(quiet, 'Added account $a');
    }
  }

  Future<AccountList?> getAccountList() async {
    var accountList = find.byType(AccountList).hitTestable();
    expect(accountList, findsOneWidget);
    return accountList.evaluate().single.widget as AccountList;
  }

  Future<AccountView?> findAccount(Account a, {bool quiet = true}) async {
    var accountList = find.byType(AccountList);
    expect(accountList, findsOneWidget);

    // find an AccountView with issuer/name in the account list
    var matchingAccounts = find.descendant(
        of: accountList,
        matching: find.byWidgetPredicate(
            (widget) =>
                widget is AccountView &&
                widget.credential.name == a.name &&
                widget.credential.issuer == a.issuer,
            skipOffstage: false));

    matchingAccounts.evaluate().forEach((element) {
      var widget = element.widget;
      if (widget is AccountView) {
        testLog(quiet,
            'Found ${widget.credential.issuer}/${widget.credential.name} matching account');
      } else {
        printToConsole('Unexpected widget type found: $widget');
      }
    });

    // return the AccountView if there is only one found
    var evaluated = matchingAccounts.evaluate();
    return evaluated.isEmpty
        ? null
        : evaluated.length != 1
            ? null
            : evaluated.single.widget as AccountView;
  }

  Future<void> openAccountDialog(Account a) async {
    var accountView = await findAccount(a);
    expect(accountView, isNotNull);

    if (accountView != null) {
      await ensureVisible(find.byWidget(accountView));
      await tap(find.byWidget(accountView));
      await shortWait();
    }
  }

  Future<void> deleteAccount(Account a, {bool quiet = true}) async {
    // only delete account if it exists
    var accountView = await findAccount(a);
    if (accountView == null) {
      testLog(quiet, 'Account to delete does not exist: $a');
      return;
    }

    await openAccountDialog(a);
    var deleteIconButton = find.byIcon(Icons.delete_outline).hitTestable();
    expect(deleteIconButton, findsOneWidget);
    await tap(deleteIconButton);
    await longWait();

    // TODO check dialog shows correct information about account
    var deleteButton = find.byKey(deleteAccountBtnKey).hitTestable();
    expect(deleteButton, findsOneWidget);
    await tap(deleteButton);
    await longWait();

    // try to find account
    var deletedAccountView = await findAccount(a);
    expect(deletedAccountView, isNull);
    if (deletedAccountView == null) {
      testLog(quiet, 'Deleted account $a');
    }
  }

  Future<void> renameAccount(
    Account a,
    String? newIssuer,
    String newName, {
    bool quiet = true,
  }) async {
    var accountView = await findAccount(a);
    if (accountView == null) {
      testLog(quiet, 'Account to rename does not exist: $a');
      return;
    }

    await openAccountDialog(a);
    var renameIconButton = find.byIcon(Icons.edit_outlined).hitTestable();
    expect(renameIconButton, findsOneWidget);
    await tap(renameIconButton);
    await longWait();

    // fill new info
    var issuerTextField = find.byKey(renameAccountEditIssuerKey).hitTestable();
    await tap(issuerTextField);
    await enterText(issuerTextField, newIssuer ?? '');
    var nameTextField = find.byKey(renameAccountEditNameKey).hitTestable();
    await tap(nameTextField);
    await enterText(nameTextField, newName);
    await shortestWait();

    var saveButton = find.byKey(renameAccountBtnSaveKey).hitTestable();
    expect(saveButton, findsOneWidget);
    await tap(saveButton);
    await longWait();

    // now the account dialog is shown
    // TODO verify it shows correct issuer and name

    // close the account dialog by tapping out of it
    await tapAt(const Offset(10, 10));
    await longWait();

    // verify accounts in the list
    var renamedAccount = Account(issuer: newIssuer, name: newName);
    var renamedAccountView = await findAccount(renamedAccount);
    await shortWait();
    var originalAccountView = await findAccount(a);
    expect(renamedAccountView, isNotNull);
    expect(originalAccountView, isNull);
    if (renamedAccountView != null && originalAccountView == null) {
      testLog(quiet, 'Renamed account from $a to $renamedAccount');
    }
  }

  void testLog(bool quiet, String message) {
    if (!quiet) {
      printToConsole(message);
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  var startupParams = {};

  if (isAndroid) {
    // default android parameters
    startupParams = {'dlg.beta.enabled': false, 'delay.startup': 5};
    testWidgets('', (WidgetTester tester) async {
      // delay first start
      await tester.startUp(startupParams);
      // remove delay.startup
      startupParams = {'dlg.beta.enabled': false};
    });
  }

  group('OATH UI tests', () {
    // Validates that expected UI is present
    testWidgets('Menu items exist', (WidgetTester tester) async {
      await tester.startUp(startupParams);
      await tester.tapDeviceButton();
      expect(find.byKey(OathDeviceMenu.addAccountKey), findsOneWidget);
      expect(find.byKey(OathDeviceMenu.setManagePasswordKey), findsOneWidget);
      expect(find.byKey(OathDeviceMenu.resetKey), findsOneWidget);
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

    // deletes accounts created in previous test
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

    // adds an account, renames, verifies
    testWidgets('Rename account', (WidgetTester tester) async {
      await tester.startUp(startupParams);

      var testAccount =
          const Account(issuer: 'IssuerToRename', name: 'NameToRename');

      // delete account if it exists
      await tester.deleteAccount(testAccount);
      await tester.deleteAccount(
          const Account(issuer: 'RenamedIssuer', name: 'RenamedName'));

      await tester.addAccount(testAccount);
      await tester.renameAccount(testAccount, 'RenamedIssuer', 'RenamedName');
    });
  });

  group('OATH Password tests', skip: true, () {
    /*
  These tests verify that all oath options are verified to function correctly by:
    1. setting firsPassword and verifying it
    2. logging in and changing to secondPassword and verifying it
    3. changing to thirdPassword
    4. removing thirdPassword
   */
    testWidgets('OATH: set firstPassword', (WidgetTester tester) async {
      await tester.startUp();

      var firstPassword = 'aaa111';

      await tester.tapSetOrManagePassword();

      await tester.enterText(
          find.byKey(const Key('new oath password')), firstPassword);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('confirm oath password')), firstPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: verify firstPassword', (WidgetTester tester) async {
      await tester.startUp();

      var firstPassword = 'aaa111';

      await tester.enterText(
          find.byKey(const Key('oath password')), firstPassword);
      await tester.pump();

      /// TODO: verification of state here: see that list of accounts is shown
      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: set secondPassword', (WidgetTester tester) async {
      await tester.startUp();

      var firstPassword = 'aaa111';
      var secondPassword = 'bbb222';

      await tester.enterText(
          find.byKey(const Key('oath password')), firstPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));

      await tester.tapSetOrManagePassword();

      await tester.enterText(
          find.byKey(const Key('current oath password')), firstPassword);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('new oath password')), secondPassword);

      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('confirm oath password')), secondPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: set thirdPassword', (WidgetTester tester) async {
      await tester.startUp();

      var secondPassword = 'bbb222';
      var thirdPassword = 'ccc333';

      await tester.enterText(
          find.byKey(const Key('oath password')), secondPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));

      await tester.tapSetOrManagePassword();

      await tester.enterText(
          find.byKey(const Key('current oath password')), secondPassword);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('new oath password')), thirdPassword);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('confirm oath password')), thirdPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));

      /// TODO: verification of state here: see that list of accounts is shown
    });

    testWidgets('OATH: remove thirdPassword', (WidgetTester tester) async {
      await tester.startUp();

      var thirdPassword = 'ccc333';

      await tester.enterText(
          find.byKey(const Key('oath password')), thirdPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));

      await tester.tapSetOrManagePassword();

      await tester.enterText(
          find.byKey(const Key('current oath password')), thirdPassword);
      await tester.pump();

      await tester.tap(find.text('Remove password'));

      /// TODO: verification of state here: see that list of accounts is shown
      await tester.pump(const Duration(milliseconds: 1000));
    });
  });
  group('TOTP tests', () {
    /*
  Tests will verify all TOTP functionality, not yet though:
    1. Add 32 TOTP accounts
     */
    testWidgets('TOTP: Add 32 accounts', skip: true,
        (WidgetTester tester) async {
      await tester.startUp();

      for (var i = 0; i < 32; i++) {
        await tester.tapAddAccount();

        var issuer = generateIssuer(i);
        var name = generateName(i);
        var secret = generateSecret(i);

        await tester.enterText(find.byKey(const Key('issuer')), issuer);
        await tester.pump(const Duration(milliseconds: 40));
        await tester.enterText(find.byKey(const Key('name')), name);
        await tester.pump(const Duration(milliseconds: 40));
        await tester.enterText(find.byKey(const Key('secret')), secret);

        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byKey(const Key('save_btn')));

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(OathScreen), findsOneWidget);

        await tester.enterText(
            find.byKey(const Key('search_accounts')), issuer);

        await tester.pump(const Duration(milliseconds: 100));

        expect(
            find.descendant(
                of: find.byType(AccountList),
                matching: find.textContaining(issuer)),
            findsOneWidget);

        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 3000));
      /*
      TODO:
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Reset OATH'));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(milliseconds: 500));

      */
    });
  });
}
