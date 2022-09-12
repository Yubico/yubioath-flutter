import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/oath/views/account_list.dart';
import 'package:yubico_authenticator/oath/views/account_view.dart';

import 'test_util.dart';

class OathDeviceMenu {
  static const addAccountKey = Key('add oath account');
  static const setManagePasswordKey = Key('set or manage oath password');
  static const resetKey = Key('reset oath app');
}

// when connecting YubiKey with OATH password
const passwordValidateEditKey = Key('oath password');
const unlockOathBtnKey = Key('oath unlock');

// when setting or changing existing YubiKey OATH password
const newOathPasswordEntryKey = Key('new oath password');
const currentOathPasswordEntryKey = Key('current oath password');
const confirmOathPasswordEditKey = Key('confirm oath password');
const oathPasswordSaveBntKey = Key('save oath password changes');
const oathPasswordRemoveBntKey = Key('remove oath password btn');

const qrScannerEnterManuallyKey = Key('android.qr_scanner.btn.enter_manually');
const deleteAccountBtnKey = Key('oath.dlg.delete_account.btn.delete');
const renameAccountBtnSaveKey = Key('oath.dlg.rename_account.btn.save');
const renameAccountEditIssuerKey = Key('oath.dlg.rename_account.edit.issuer');
const renameAccountEditNameKey = Key('oath.dlg.rename_account.edit.name');

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

extension OathFunctions on WidgetTester {
  /// Opens the device menu and taps the "Add account" menu item
  Future<void> tapAddAccount() async {
    await tapDeviceButton();
    await tap(find.byKey(OathDeviceMenu.addAccountKey).hitTestable());
    await longWait();
  }

  /// Opens the device menu and taps the "Set/Manage password" menu item
  Future<void> tapSetOrManagePassword() async {
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

  Finder findAccountList() {
    // cannot use hitTestable because Toasts block the Account list
    var accountList = find.byType(AccountList).hitTestable(at: Alignment.topCenter);
    expect(accountList, findsOneWidget);
    return accountList;
  }

  Future<AccountList?> getAccountList() async {
    return findAccountList().evaluate().single.widget as AccountList;
  }

  Future<AccountView?> findAccount(Account a, {bool quiet = true}) async {
    // find an AccountView with issuer/name in the account list
    var matchingAccounts = find.descendant(
        of: findAccountList(),
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

  Future<void> setOathPassword(String newPassword) async {
    await tapSetOrManagePassword();

    await longWait();

    var newPasswordEntry = find.byKey(newOathPasswordEntryKey);
    await tap(newPasswordEntry);
    await enterText(newPasswordEntry, newPassword);
    await shortWait();
    var confirmPasswordEntry = find.byKey(confirmOathPasswordEditKey);
    await tap(confirmPasswordEntry);
    await enterText(confirmPasswordEntry, newPassword);
    await shortWait();

    await tap(find.byKey(oathPasswordSaveBntKey));
    await longWait();

    // after tapping Save, the dialog is closed and the save button does not exist
    expect(find.byKey(oathPasswordSaveBntKey).hitTestable(), findsNothing);
  }

  Future<void> unlockOathSession(String newPassword) async {
    var validatePasswordEntry = find.byKey(passwordValidateEditKey);
    await tap(validatePasswordEntry);
    await enterText(validatePasswordEntry, newPassword);
    await shortWait();
    var unlockButton = find.byKey(unlockOathBtnKey);
    await tap(unlockButton);
    await longWait();

    // after unlocking, the unlock button is not hittable
    expect(find.byKey(unlockOathBtnKey).hitTestable(), findsNothing);
  }

  Future<void> removeOathPassword(String currentPassword) async {
    await tapSetOrManagePassword();

    await longWait();

    var currentPasswordEntry = find.byKey(currentOathPasswordEntryKey);
    await tap(currentPasswordEntry);
    await enterText(currentPasswordEntry, currentPassword);
    await shortWait();
    await tap(find.byKey(oathPasswordRemoveBntKey));
    await longWait();

    // after tapping Save, the dialog is closed and the save button does not exist
    expect(find.byKey(oathPasswordRemoveBntKey).hitTestable(), findsNothing);
  }

}
