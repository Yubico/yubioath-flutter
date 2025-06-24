import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/management/models.dart';
import 'package:yubico_authenticator/otp/keys.dart';
import 'package:yubico_authenticator/otp/models.dart';
import 'package:yubico_authenticator/otp/state.dart';
import 'package:yubico_authenticator/widgets/app_text_field.dart';

import 'utils.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  appGroup(
    'OTP',
    (params) {
      testKey('Swap slots', params, ($, data) async {
        await $.navigate(Section.slots);

        // Ensure slot 2 is empty
        final state = $.read(otpStateProvider(data.node.path)).value!;
        expect(
          state.slot2Configured,
          isFalse,
          reason: 'Slot 2 should not be configured initially',
        );

        if (!state.slot1Configured) {
          await $
              .read(otpStateProvider(data.node.path).notifier)
              .configureSlot(
                SlotId.one,
                configuration: SlotConfiguration.chalresp(key: 'cafed00d'),
              );
          await $.pumpAndSettle();
        }

        // Swap slots
        await $.viewAction(swapSlots);
        await $(swapButton).tap();
        await $.condition(
          () =>
              $.read(otpStateProvider(data.node.path)).value?.slot2Configured ==
              true,
        );
        expect(
          $.read(otpStateProvider(data.node.path)).value?.slot1Configured,
          isFalse,
        );

        if (state.slot1Configured) {
          // Slot 1 was pre-programmed, swap back from slot 2
          await $.read(otpStateProvider(data.node.path).notifier).swapSlots();
        } else {
          // Slot 1 was not programmed, delete the test credential in slot 2
          await $
              .read(otpStateProvider(data.node.path).notifier)
              .deleteSlot(SlotId.two);
        }
        await $.pumpAndSettle();

        // Ensure we're back to the initial state
        await $.condition(
          () =>
              $.read(otpStateProvider(data.node.path)).value?.slot2Configured ==
              false,
        );
        expect(
          $.read(otpStateProvider(data.node.path)).value?.slot1Configured,
          state.slot1Configured,
        );
      });

      testKey('Program slots', params, ($, data) async {
        await $.navigate(Section.slots);

        // Ensure slot 2 is empty
        final state = $.read(otpStateProvider(data.node.path)).value!;
        expect(
          state.slot2Configured,
          isFalse,
          reason: 'Slot 2 should not be configured initially',
        );

        final slot2 = $(getAppListItemKey(SlotId.two));

        // Program a challenge-response credential
        await $.itemAction(slot2, configureYubiOtp);

        // Save is disabled from the start
        expect($(saveButton).widget<TextButton>().enabled, isFalse);

        // Use serial for public ID, if available
        if (data.info.serial != null) {
          await $(useSerial).tap();
          expect(
            $(publicIdField).widget<AppTextField>().controller?.text.length,
            equals(12),
          );
        } else {
          // Otherwise, enter a public ID
          await $(publicIdField).enterText('vvincredible');
        }

        await $(generatePrivateId).tap();
        await $(generateSecretKey).tap();

        // Complete the programming successfully
        await $(saveButton).tap();
        await $.condition(
          () =>
              $.read(otpStateProvider(data.node.path)).value?.slot2Configured ==
              true,
        );

        // Close the slot details, if opened
        final close = $(closeButton);
        if (close.exists) {
          await close.tap();
          expect(slot2, findsOneWidget);
        }

        // Program a challenge-response credential, using right-click
        await $.tester.tap(slot2, buttons: kSecondaryButton);
        await $.pumpAndSettle();
        await $(configureChalResp).tap();

        // Save is enabled from the start
        expect($(saveButton).widget<TextButton>().enabled, isTrue);

        // Empty value shows an error and disables the save button
        await $(saveButton).tap();
        expect($(saveButton).widget<TextButton>().enabled, isFalse);

        // Odd-length values show an error and disable the save button
        await $(secretField).enterText('b0b');
        await $(saveButton).tap();
        expect($(saveButton).widget<TextButton>().enabled, isFalse);

        // Complete the programming successfully
        await $(secretField).enterText('cafed00d');
        await $(saveButton).tap();

        // Slot is configured, need overwrite
        await $(overwriteButton).tap();

        // Close the slot details, if opened
        if (close.exists) {
          await close.tap();
          expect(slot2, findsOneWidget);
        }

        // Delete the slot 2 key
        await $.itemAction(slot2, deleteAction);
        await $(deleteButton).tap();
        await $.condition(
          () =>
              $.read(otpStateProvider(data.node.path)).value?.slot2Configured ==
              false,
        );

        // Close the slot details, if opened
        if (close.exists) {
          await close.tap();
          expect(slot2, findsWidgets);
        }

        // Program a static password
        await $.itemAction(slot2, configureStatic);

        // Save is enabled from the start
        expect($(saveButton).widget<TextButton>().enabled, isTrue);

        // Empty value shows an error and disables the save button
        await $(saveButton).tap();
        expect($(saveButton).widget<TextButton>().enabled, isFalse);

        // Invalid modhex shows an error and disables the save button
        await $(secretField).enterText('invalid modhex');
        await $(saveButton).tap();
        expect($(saveButton).widget<TextButton>().enabled, isFalse);

        // Generate a random password and save
        await $(generateSecretKey).tap();
        await $(saveButton).tap();

        // Close the slot details, if opened
        if (close.exists) {
          await close.tap();
          expect(slot2, findsOneWidget);
        }

        // Program a HOTP credential
        await $.itemAction(slot2, configureHotp);

        // Save is enabled from the start
        expect($(saveButton).widget<TextButton>().enabled, isTrue);

        // Empty value shows an error and disables the save button
        await $(saveButton).tap();
        expect($(saveButton).widget<TextButton>().enabled, isFalse);

        // Invalid base32 shows an error and disables the save button
        await $(secretField).enterText('11111111');
        await $(saveButton).tap();
        expect($(saveButton).widget<TextButton>().enabled, isFalse);

        // Complete the programming successfully, overwriting the previous
        await $(secretField).enterText('abba');
        await $(saveButton).tap();
        await $(overwriteButton).tap();

        // Close the slot details, if opened
        if (close.exists) {
          await close.tap();
          expect(slot2, findsOneWidget);
        }

        // Programatically delete the slot 2 credential
        await $
            .read(otpStateProvider(data.node.path).notifier)
            .deleteSlot(SlotId.two);
        await $.pumpAndSettle();
        await $.condition(
          () =>
              $.read(otpStateProvider(data.node.path)).value?.slot2Configured ==
              false,
        );
      });
    },
    skip: isAndroid,
    condition: (info) => info.hasCapability(Capability.otp),
  );
}
