import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/views/app_list_item.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/management/models.dart';
import 'package:yubico_authenticator/oath/keys.dart';
import 'package:yubico_authenticator/oath/models.dart';
import 'package:yubico_authenticator/oath/state.dart';
import 'package:yubico_authenticator/oath/views/account_view.dart';
import 'package:yubico_authenticator/widgets/responsive_dialog.dart';

import 'utils.dart';

extension on PatrolTester {
  Future<void> addCredential(
    YubiKeyData data,
    CredentialData cred, {
    bool requireTouch = false,
  }) async {
    if (isAndroid) {
      // The camera view breaks the test on Android, add programmatically
      await read(
        credentialListProvider(data.node.path).notifier,
      ).addAccount(cred.toUri(), requireTouch: requireTouch);
      await $.pumpAndSettle();
    } else {
      // Add a credential via the form
      await $.viewAction(addAccountAction);

      await $(issuerField).enterText(cred.issuer ?? '');
      await $(nameField).enterText(cred.name);
      await $(secretField).enterText(cred.secret);

      if (requireTouch) {
        await $(requireTouchFilterChip).tap();
      }

      if (cred.oathType != defaultOathType) {
        await $(oathTypeFilterChip).tap();
        await $(cred.oathType.getDisplayName($.l10n)).tap();
      }

      if (cred.hashAlgorithm != defaultHashAlgorithm) {
        await $(hashAlgorithmFilterChip).tap();
        await $(cred.hashAlgorithm.displayName).tap();
      }

      if (cred.period != defaultPeriod) {
        await $(periodFilterChip).tap();
        await $($.l10n.s_num_sec(cred.period)).tap();
      }

      if (cred.digits != defaultDigits) {
        await $(digitsFilterChip).tap();
        await $($.l10n.s_num_digits(cred.digits)).tap();
      }
      await $(saveButton).tap();
      await $.condition(
        () =>
            read(credentialListProvider(data.node.path))
                ?.where(
                  (pair) =>
                      pair.credential.issuer == cred.issuer &&
                      pair.credential.name == cred.name,
                )
                .length ==
            1,
      );
    }
  }
}

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  appGroup('OATH', (params) {
    // This test must be first, to ensure later tests run with a clean state
    testKey('Factory Reset', params, ($, data) async {
      Future<String> getOathId() async {
        if (isAndroid) {
          // Need to be on the Accounts view for the OATH state to be available
          await $.navigate(Section.accounts);
        }
        return $.read(oathStateProvider(data.node.path)).requireValue.deviceId;
      }

      // Get the initial OATH device ID
      final oldOathId = await getOathId();

      // Reset via Home screen
      await $.navigate(Section.home);

      await $.viewAction(yubikeyFactoryResetMenuButton);
      await $(factoryResetPickResetOath).tap();
      await $(factoryResetReset).tap();

      // Make sure the OATH device ID has changed
      if (data.info.version.isAtLeast(4)) {
        await $.condition(
          () async => await getOathId() != oldOathId,
          reason: 'OATH device ID should change after reset',
        );
      } else {
        // State doesn't update for NEO, instead wait for the dialog to close
        // TODO: Investigate why this is needed
        await $.condition(() => !$(ResponsiveDialog).exists);
      }
    });

    testKey('Add/Rename/Delete Credential', params, ($, data) async {
      // Navigate to OATH add account dialog
      await $.navigate(Section.accounts);

      // Add a credential
      await $.addCredential(
        data,
        CredentialData(
          issuer: 'TOTP',
          name: 'test@example.com',
          secret: 'JBSWY3DPEHPK3PXP',
        ),
      );

      // Ensure the credential is visible
      expect($('TOTP'), findsOneWidget);
      expect($('test@example.com'), findsOneWidget);
      expect($(RegExp(r'^\d{3}\s\d{3}$')), findsOneWidget);

      final totp = $(AppListItem<OathCredential>);
      expect(totp, findsOneWidget);

      if (data.info.version.isAtLeast(5, 3, 1)) {
        // Rename the credential
        await $.itemAction(totp, editAction);

        await $(nameField).enterText('updated@example.com');
        await $(saveButton).tap();
        expect($('updated@example.com'), findsWidgets);

        // Close the credential details, if opened
        final close = $(closeButton);
        if (close.exists) {
          await close.tap();
          expect($('updated@example.com'), findsWidgets);
        }
      }

      // Add a TOTP touch credential (requires a YubiKey >= 4)
      if (data.info.version.isAtLeast(4)) {
        await $.addCredential(
          data,
          CredentialData(
            issuer: 'Touch',
            name: 'test3@example.com',
            secret: 'JBSWY3DPEHPK3PXP',
            hashAlgorithm: HashAlgorithm.sha256,
          ),
          requireTouch: true,
        );

        // Ensure that only one TOTP credential is visible still (touch not shown)
        expect($(AccountView).$(RegExp(r'^\d{3}\s\d{3}$')), findsOneWidget);
      }

      // Add a HOTP credential, using test vector secret
      await $.addCredential(
        data,
        CredentialData(
          issuer: 'HOTP',
          name: 'test2@example.com',
          secret: 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
          oathType: OathType.hotp,
          digits: 8,
        ),
      );

      // Ensure the credential is visible
      final hotp = $(
        AppListItem<OathCredential>,
      ).which((widget) => $(widget).$('HOTP').exists);
      expect($(hotp), findsOneWidget);

      // Select/open the credential view
      await $.selectOrOpenItem(hotp);

      // In a narrow view, this will calculate the first HOTP code
      if (!$('8475 5224').exists) {
        // Otherwise, we need to calculate manually
        await $(calculateAction).tap();
      }
      expect($('8475 5224'), findsWidgets);

      await $(calculateAction).tap();
      expect($('9428 7082'), findsWidgets);

      // Delete the HOTP credential using the action menu
      await $(deleteAction).tap();
      await $(deleteButton).tap();
      expect($('HOTP'), findsNothing);

      // Delete the TOTP credential using the context menu
      await $.tester.tap($('TOTP'), buttons: kSecondaryButton);
      await $.pumpAndSettle();
      await $(deleteAction).tap();
      await $(deleteButton).tap();
      expect($('TOTP'), findsNothing);

      // Delete the rest programatically
      for (final pair in $.read(credentialListProvider(data.node.path))!) {
        await $
            .read(credentialListProvider(data.node.path).notifier)
            .deleteAccount(pair.credential);
      }
      await $.pumpAndSettle();

      expect($(AccountView), findsNothing);
    });

    testKey('Set/Change/Remove password', params, ($, data) async {
      bool hasLock() =>
          $.read(oathStateProvider(data.node.path)).requireValue.hasKey;

      // Navigate to OATH add account dialog
      await $.navigate(Section.accounts);

      expect(hasLock(), isFalse);

      // Set a password, first misstyped
      await $.viewAction(setOrManagePasswordAction);
      await $(newPasswordField).enterText('foo');
      await $(confirmPasswordField).enterText('bar');
      expect($(savePasswordButton).widget<TextButton>().enabled, isFalse);

      // Correct the password and save
      await $(confirmPasswordField).enterText('foo');
      await $(savePasswordButton).tap();
      await $.condition(hasLock);

      // Change password, once with wrong password
      await $.viewAction(setOrManagePasswordAction);
      await $(currentPasswordField).enterText('wrong');
      await $(newPasswordField).enterText('bar');
      await $(confirmPasswordField).enterText('bar');
      await $(savePasswordButton).tap();
      // Ensure the dialog is still open, and the save button disabled
      expect($(currentPasswordField), findsOneWidget);
      expect($(savePasswordButton).widget<TextButton>().enabled, isFalse);

      // Correct the password and save
      await $(currentPasswordField).enterText('foo');
      await $(savePasswordButton).tap();

      expect(hasLock(), isTrue);

      // Remove password
      await $.viewAction(setOrManagePasswordAction);
      await $(currentPasswordField).enterText('bar');
      await $(removePasswordButton).tap();

      await $.condition(() => !hasLock());
    });

    testKey(
      'Require Touch Credential',
      params,
      ($, data) async {
        // Navigate to OATH add account dialog
        await $.navigate(Section.accounts);

        // Add a touch credential, with test vector
        await $.addCredential(
          data,
          CredentialData(
            oathType: OathType.hotp,
            issuer: 'HOTP touch',
            name: 'test@example.com',
            secret: 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
          ),
          requireTouch: true,
        );

        final hotp = $(
          AppListItem<OathCredential>,
        ).which((widget) => $(widget).$('HOTP touch').exists);

        // Ensure the credential is visible, but no code is shown
        expect(hotp, findsOneWidget);
        expect($(RegExp(r'^\d{3}\s\d{3}$')), findsNothing);

        // Calculate the code, which should prompt for touch
        await $.tester.tap(hotp, buttons: kSecondaryButton);
        await $.pumpAndSettle();
        await $(calculateAction).tap();

        // Wait for touch to be confirmed
        await $($.l10n.s_touch_required).waitUntilVisible();
        await $.condition(() => !$($.l10n.s_touch_required).exists);
        expect($('755 224'), findsWidgets);

        // Calculate another code
        await $.itemAction(hotp, calculateAction);

        // Wait for touch to be confirmed
        await $($.l10n.s_touch_required).waitUntilVisible();
        await $.condition(() => !$($.l10n.s_touch_required).exists);
        expect($('287 082'), findsWidgets);

        // Delete the credential(s) programatically
        for (final pair in $.read(credentialListProvider(data.node.path))!) {
          await $
              .read(credentialListProvider(data.node.path).notifier)
              .deleteAccount(pair.credential);
        }
        await $.pumpAndSettle();

        expect($(AccountView), findsNothing);
      },
      tags: 'manual',
      condition: (info) => info.version.isAtLeast(4),
      skip: nfcReader.isNotEmpty,
    );
  }, condition: (info) => info.hasCapability(Capability.oath));
}
