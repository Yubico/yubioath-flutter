import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/views/app_list_item.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/fido/keys.dart';
import 'package:yubico_authenticator/fido/models.dart';
import 'package:yubico_authenticator/fido/state.dart';
import 'package:yubico_authenticator/management/models.dart';
import 'package:yubico_authenticator/widgets/responsive_dialog.dart';

import 'utils.dart';

const normalPin = '23452345';
const changedPin = '54325432';

extension on PatrolTester {
  Future<void> elevate() async {
    final elevate = $(elevateFidoButton);
    if (elevate.exists) {
      await elevate.tap();
      final toast = $(l10n.l_elevating_permissions);
      await toast.waitUntilVisible();
      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (!toast.exists) {
          await pumpAndSettle();
          return;
        }
      }
      fail('Timed out waiting for FIDO elevation to complete');
    }
  }

  Future<void> navigateElevate(Section section) async {
    await navigate(section);
    await elevate();
  }
}

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  appGroup('FIDO', (params) {
    testKey('Change PIN', params, ($, data) async {
      await $.navigateElevate(Section.passkeys);

      // Ensure we have a PIN set
      var state = $.read(fidoStateProvider(data.node.path)).value!;
      if (!state.hasPin) {
        await $
            .read(fidoStateProvider(data.node.path).notifier)
            .setPin(normalPin);
        await $.pumpAndSettle();
        state = $.read(fidoStateProvider(data.node.path)).value!;
      }
      expect(state.hasPin, isTrue, reason: 'FIDO PIN not set');
      expect(state.pinRetries, 8, reason: 'FIDO PIN attempts not full');

      // Change the PIN
      await $.viewAction(managePinAction);
      expect($(saveButton).widget<TextButton>().enabled, isFalse);
      await $(currentPin).enterText(normalPin);
      expect($(saveButton).widget<TextButton>().enabled, isFalse);
      await $(newPin).enterText(changedPin);
      expect($(saveButton).widget<TextButton>().enabled, isFalse);
      await $(confirmPin).enterText(normalPin);
      expect($(saveButton).widget<TextButton>().enabled, isFalse);
      await $(confirmPin).enterText(changedPin);
      expect($(saveButton).widget<TextButton>().enabled, isTrue);
      await $(saveButton).tap();

      await $.condition(() => !$(ResponsiveDialog).exists);
      state = $.read(fidoStateProvider(data.node.path)).value!;
      expect(state.pinRetries, 8);

      // Try to change the PIN with wrong current PIN
      await $.viewAction(managePinAction);
      await $(currentPin).enterText(normalPin);
      await $(newPin).enterText(changedPin);
      await $(confirmPin).enterText(changedPin);
      await $(saveButton).tap();
      await $(closeButton).tap();
      await $.condition(() => !$(ResponsiveDialog).exists);

      state = $.read(fidoStateProvider(data.node.path)).value!;
      expect(state.pinRetries, 7);

      // Change back to original PIN
      await $.viewAction(managePinAction);
      await $(currentPin).enterText(changedPin);
      await $(newPin).enterText(normalPin);
      await $(confirmPin).enterText(normalPin);
      await $(saveButton).tap();
      await $.condition(() => !$(ResponsiveDialog).exists);

      state = $.read(fidoStateProvider(data.node.path)).value!;
      expect(state.pinRetries, 8);
    });

    testKey('Check PIN attempts', params, ($, data) async {
      await $.navigateElevate(Section.passkeys);

      final state = $.read(fidoStateProvider(data.node.path)).value!;

      final pinButton = $(managePinAction);
      if (!pinButton.exists) {
        await $(actionsIconButtonKey).tap();
      }

      if (state.hasPin) {
        expect(
          pinButton.$($.l10n.l_attempts_remaining(state.pinRetries!)).exists,
          isTrue,
        );
      } else {
        expect(pinButton.$($.l10n.s_fido_pin_protection).exists, isTrue);
      }
    });

    testKey('Delete passkeys', params, ($, data) async {
      await $.navigateElevate(Section.passkeys);

      final state = $.read(fidoStateProvider(data.node.path)).value!;
      expect(
        state.credMgmt,
        isTrue,
        reason: 'Key does not support credential management',
      );

      // Unlock with PIN if needed
      final pinField = $(pinEntry);
      if (pinField.exists) {
        await pinField.enterText(normalPin);
        await $(unlockFido2WithPin).tap();
      }

      final passkeys = $(AppListItem<FidoCredential>)
          .which<AppListItem<FidoCredential>>(
            (widget) => widget.item.rpId == 'delete.example.com',
          );
      await $.condition(() => passkeys.exists);

      final passkey = passkeys.first;
      final cred = passkey.widget<AppListItem<FidoCredential>>().item;
      await $.selectOrOpenItem(passkey);
      expect($(cred.rpId), findsAny);
      expect($(cred.userName), findsAny);
      expect($(cred.userId), findsAny);
      expect($(cred.credentialId), findsAny);

      await $(deleteCredentialAction).tap();

      // Unlock with PIN if needed (can happen when using PPUAT)
      final pinConfirmationField = $(pinConfirmationEntry);
      if (pinConfirmationField.exists) {
        await pinConfirmationField.enterText(normalPin);
        await $(unlockFido2WithPinConfirmation).tap();
      }
      await $(deleteButton).tap();

      expect(
        $(AppListItem<FidoCredential>).which<AppListItem<FidoCredential>>(
          (widget) => widget.item.credentialId == cred.credentialId,
        ),
        findsNothing,
      );
    });
  }, condition: (info) => info.hasCapability(Capability.fido2));

  appGroup('FIDO - manual', (params) {
    testKey('Factory Reset', params, ($, data) async {
      // Reset via Home screen
      await $.navigate(Section.home);

      await $.viewAction(yubikeyFactoryResetMenuButton);
      await $(factoryResetPickResetFido2).tap();
      await $.elevate();

      await $(factoryResetReset).tap();

      // Wait for the user to complete manual steps
      await $(LinearProgressIndicator)
          .which<LinearProgressIndicator>((widget) => widget.value == 1.0)
          .waitUntilVisible(timeout: Duration(seconds: 30));

      await $(closeButton).tap();

      // Check that the FIDO state has been reset
      await $.navigate(Section.passkeys);
      final state = $.read(fidoStateProvider(data.node.path)).value!;
      expect(state.hasPin, isFalse);
    }, tags: 'manual');

    // Manual since it requires a fresh factory reset state
    testKey('Set a PIN', params, ($, data) async {
      await $.navigateElevate(Section.passkeys);

      var state = $.read(fidoStateProvider(data.node.path)).value!;
      expect(state.hasPin, isFalse, reason: 'FIDO PIN already set');

      await $.viewAction(managePinAction);

      expect($(saveButton).widget<TextButton>().enabled, isFalse);
      await $(newPin).enterText(normalPin);
      expect($(saveButton).widget<TextButton>().enabled, isFalse);
      await $(confirmPin).enterText(changedPin);
      expect($(saveButton).widget<TextButton>().enabled, isFalse);
      await $(confirmPin).enterText(normalPin);
      expect($(saveButton).widget<TextButton>().enabled, isTrue);
      await $(saveButton).tap();
      await $.condition(() => !$(ResponsiveDialog).exists);

      state = $.read(fidoStateProvider(data.node.path)).value!;
      expect(state.hasPin, isTrue);
    }, tags: 'manual');
  }, condition: (info) => info.hasCapability(Capability.fido2));
}
