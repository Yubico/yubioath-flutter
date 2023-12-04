/*
 * Copyright (C) 2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/oath/keys.dart' as keys;
import 'package:yubico_authenticator/oath/models.dart';
import 'package:yubico_authenticator/oath/views/account_list.dart';
import 'package:yubico_authenticator/oath/views/account_view.dart';

import '../utils/test_util.dart';
import 'android/util.dart';

class Account {
  final String? issuer;
  final String name;
  final String secret;
  final bool? touch;
  final OathType? oathType;
  final HashAlgorithm? hashAlgorithm;

  // final PeriodValues? periodValues;
  // final bool? digits;

  const Account({
    this.issuer,
    this.name = '',
    this.secret = 'abba',
    this.touch,
    this.oathType,
    this.hashAlgorithm,
    //    this.periodValues,
    //    this.digits
  });

  @override
  String toString() => '$issuer/$name';
}

extension OathFunctions on WidgetTester {
  /// Opens the device menu and taps the "Add account" menu item
  Future<void> tapAddAccount() async {
    await tapActionIconButton();
    await longWait();
    await tap(find.byKey(keys.addAccountAction).hitTestable());
    await longWait();
    if (isDesktop) {
      await tap(find.byKey(keys.addAccountManuallyButton).hitTestable());
      await longWait();
    }
  }

  Future<void> addAccount(Account a, {bool quiet = true}) async {
    var accountView = await findAccount(a);
    if (accountView != null) {
      testLog(quiet, 'Account already exists: $a');
      return;
    }

    await tapAddAccount();

    if (isAndroid) {
      await grantCameraPermissions(this);
    }

    var issuerText = find.byKey(keys.issuerField).hitTestable();
    await tap(issuerText);
    await enterText(issuerText, a.issuer ?? '');
    await shortWait();
    var nameText = find.byKey(keys.nameField).hitTestable();
    await tap(nameText);
    await enterText(nameText, a.name);
    await shortWait();
    var secretText = find.byKey(keys.secretField).hitTestable();
    await tap(secretText);
    await enterText(secretText, a.secret);
    await shortWait();
    if (isAndroid) {
      FocusManager.instance.primaryFocus?.unfocus();
      await shortWait();
    }
    if (a.touch != null && a.touch == true) {
      var requireTouchFilterChip =
          find.byKey(keys.requireTouchFilterChip).hitTestable();
      await tap(requireTouchFilterChip);
    }
    await shortWait();
    if (a.oathType != null) {
      var oathTypeFilterChip =
          find.byKey(keys.oathTypeFilterChip).hitTestable();
      await tap(oathTypeFilterChip);
      await shortWait();
      if (a.oathType == OathType.hotp) {
        var hotp = find.byKey(keys.oathTypeHotpFilterValue).hitTestable();
        await tap(hotp);
      } else {
        var totp = find.byKey(keys.oathTypeTotpFilterValue).hitTestable();
        await tap(totp);
      }
    }
    await shortWait();
    if (a.hashAlgorithm != null) {
      var algoTypeFilterChip =
          find.byKey(keys.hashAlgorithmFilterChip).hitTestable();
      await tap(algoTypeFilterChip);
      await shortWait();
      if (a.hashAlgorithm == HashAlgorithm.sha1) {
        var sha1 = find.byKey(keys.hashAlgorithmSha1FilterValue).hitTestable();
        await tap(sha1);
      } else if (a.hashAlgorithm == HashAlgorithm.sha256) {
        var sha256 =
            find.byKey(keys.hashAlgorithmSha256FilterValue).hitTestable();
        await tap(sha256);
      } else {
        var sha512 =
            find.byKey(keys.hashAlgorithmSha512FilterValue).hitTestable();
        await tap(sha512);
      }
    }
    await shortWait();
    await tap(find.byKey(keys.saveButton));

    /// the following pump is because of NEO keys
    await pump(const Duration(seconds: 1));

    accountView = await findAccount(a);
    if (accountView != null) {
      testLog(quiet, 'Added account $a');
    }
  }

  Finder findAccountList() {
    var accountList =
        find.byType(AccountList).hitTestable(at: Alignment.topCenter);
    expect(accountList, findsOneWidget);
    return accountList;
  }

  Future<AccountList?> getAccountList() async {
    return findAccountList().evaluate().single.widget as AccountList;
  }

  Future<AccountView?> findAccount(Account a, {bool quiet = true}) async {
    if (find.byKey(keys.noAccountsView).hitTestable().evaluate().isNotEmpty) {
      /// if there is no OATH account on the YubiKey, the app shows
      /// No accounts [MessagePage]
      return null;
    }

    await shortWait();

    /// find an AccountView with issuer/name in the account list
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

    /// return the AccountView if there is only one found
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
      final accountFinder = find.byWidget(accountView);
      await ensureVisible(accountFinder);
      final codeButtonFinder = find.descendant(
          of: accountFinder, matching: find.bySubtype<FilledButton>());
      await tap(codeButtonFinder);
      await shortWait();
    }
  }

  Future<void> deleteAccount(Account a, {bool quiet = true}) async {
    /// only delete account if it exists
    var accountView = await findAccount(a);
    if (accountView == null) {
      testLog(quiet, 'Account to delete does not exist: $a');
      return;
    }

    await openAccountDialog(a);

    /// click the delete IconButton in the account dialog
    var deleteIconButton = find.byIcon(Icons.delete_outline).hitTestable();
    expect(deleteIconButton, findsOneWidget);
    await tap(deleteIconButton);
    await longWait();

    /// click the delete Button in the delete dialog
    var deleteButton = find.byKey(keys.deleteButton).hitTestable();
    expect(deleteButton, findsOneWidget);
    await tap(deleteButton);
    await longWait();
    await longWait();

    /// try to find account
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

    /// only newer FW supports renaming
    if (renameIconButton.evaluate().isEmpty) {
      /// close the dialog and return
      testLog(false, 'This YubiKey does not support account renaming');
      await tapAt(const Offset(10, 10));
      await shortWait();
      return;
    }

    expect(renameIconButton, findsOneWidget);
    await tap(renameIconButton);
    await longWait();

    /// fill new info
    var issuerTextField = find.byKey(keys.issuerField).hitTestable();
    await tap(issuerTextField);
    await enterText(issuerTextField, newIssuer ?? '');
    var nameTextField = find.byKey(keys.nameField).hitTestable();
    await tap(nameTextField);
    await enterText(nameTextField, newName);
    await longWait();

    var saveButton = find.byKey(keys.saveButton).hitTestable();
    expect(saveButton, findsOneWidget);
    await tap(saveButton);
    await longWait();

    /// close the account dialog by tapping the close button
    var closeButton = find.byKey(app_keys.closeButton).hitTestable();
    // Wait for toast to clear
    await waitForFinder(closeButton);

    await tap(closeButton);
    await longWait();

    /// verify accounts in the list
    var renamedAccount = Account(issuer: newIssuer, name: newName);
    var renamedAccountView = await findAccount(renamedAccount);
    await longWait();
    var originalAccountView = await findAccount(a);
    expect(renamedAccountView, isNotNull);
    expect(originalAccountView, isNull);
    if (renamedAccountView != null && originalAccountView == null) {
      testLog(quiet, 'Renamed account from $a to $renamedAccount');
    }
  }

  /// Factory reset OATH application
  Future<void> resetOATH() async {
    await tapActionIconButton();
    await shortWait();
    await tap(find.byKey(keys.resetAction));
    await shortWait();
    await tap(find.text('Reset'));
    await shortWait();
  }

  /// Opens the device menu and taps the "Set/Manage password" menu item
  Future<void> tapSetOrManagePassword() async {
    await tapActionIconButton();
    await tap(find.byKey(keys.setOrManagePasswordAction));
    await longWait();
  }

  Future<void> setOathPassword(String newPassword) async {
    await tapSetOrManagePassword();

    await longWait();

    var newPasswordEntry = find.byKey(keys.newPasswordField);
    await tap(newPasswordEntry);
    await enterText(newPasswordEntry, newPassword);
    await shortWait();
    var confirmPasswordEntry = find.byKey(keys.confirmPasswordField);
    await tap(confirmPasswordEntry);
    await enterText(confirmPasswordEntry, newPassword);
    await shortWait();

    await tap(find.byKey(keys.savePasswordButton));

    /// the following pause is because of NEO keys
    await pump(const Duration(seconds: 1));

    /// after tapping Save, the dialog is closed and the save button does not exist
    expect(find.byKey(keys.savePasswordButton).hitTestable(), findsNothing);
  }

  Future<void> replaceOathPassword(
      String currentPassword, String newPassword) async {
    await tapSetOrManagePassword();

    await shortWait();

    var currentPasswordEntry = find.byKey(keys.currentPasswordField);
    await tap(currentPasswordEntry);
    await enterText(currentPasswordEntry, currentPassword);
    await shortWait();
    var newPasswordEntry = find.byKey(keys.newPasswordField);
    await tap(newPasswordEntry);
    await enterText(newPasswordEntry, newPassword);
    await shortWait();
    var confirmPasswordEntry = find.byKey(keys.confirmPasswordField);
    await tap(confirmPasswordEntry);
    await enterText(confirmPasswordEntry, newPassword);
    await shortWait();

    await tap(find.byKey(keys.savePasswordButton));
    await longWait();

    expect(find.byKey(keys.savePasswordButton).hitTestable(), findsNothing);
  }

  Future<void> unlockOathSession(String newPassword) async {
    var validatePasswordEntry = find.byKey(keys.passwordField);
    await tap(validatePasswordEntry);
    await enterText(validatePasswordEntry, newPassword);
    await shortWait();
    var unlockButton = find.byKey(keys.unlockButton);
    await tap(unlockButton);

    /// the following pump is because of NEO keys
    await pump(const Duration(seconds: 1));

    expect(find.byKey(keys.unlockButton).hitTestable(), findsNothing);
  }

  Future<void> removeOathPassword(String currentPassword) async {
    await tapSetOrManagePassword();

    await longWait();

    var currentPasswordEntry = find.byKey(keys.currentPasswordField);
    await tap(currentPasswordEntry);
    await enterText(currentPasswordEntry, currentPassword);
    await shortWait();
    await tap(find.byKey(keys.removePasswordButton));

    /// the following pump is because of NEO keys
    await pump(const Duration(seconds: 1));

    expect(find.byKey(keys.removePasswordButton).hitTestable(), findsNothing);
  }
}
