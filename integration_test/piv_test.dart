import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/app_list_item.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/management/models.dart';
import 'package:yubico_authenticator/piv/keys.dart';
import 'package:yubico_authenticator/piv/models.dart';
import 'package:yubico_authenticator/piv/state.dart';
import 'package:yubico_authenticator/widgets/choice_filter_chip.dart';

import 'utils.dart';

const changedPin = '23452345';
const changedPuk = '54325432';
const changedManagementKey = '080706050403020108070605040302010807060504030201';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  appGroup(
    'PIV',
    (params) {
      testKey('Factory Reset', params, ($, data) async {
        // Reset via Home screen
        await $.navigate(Section.home);

        await $.viewAction(yubikeyFactoryResetMenuButton);
        await $(factoryResetPickResetPiv).tap();
        await $(factoryResetReset).tap();

        await $.navigate(Section.certificates);
        final state = $.read(pivStateProvider(data.node.path)).value!;

        if (data.info.version.isAtLeast(5, 3)) {
          expect(state.metadata?.managementKeyMetadata.defaultValue, isTrue);
          expect(state.metadata?.pinMetadata.defaultValue, isTrue);
          expect(state.metadata?.pukMetadata.defaultValue, isTrue);
        }
      });

      testKey('Access management', params, ($, data) async {
        await $.navigate(Section.certificates);

        // We always need a reset state to start with
        await $.read(pivStateProvider(data.node.path).notifier).reset();
        await $.pumpAndSettle();

        var state = $.read(pivStateProvider(data.node.path)).value!;
        expect(state.pinAttempts, greaterThanOrEqualTo(3));

        // Change PIN
        await $.viewAction(managePinAction);
        if (state.metadata == null) {
          // We expect the default PIN to be set, but we don't know if it is
          await $(pinPukField).enterText(defaultPin);
        }
        await $(newPinPukField).enterText(changedPin);
        await $(confirmPinPukField).enterText(changedPin);
        await $(saveButton).tap();

        await $.condition(
          () =>
              $
                  .read(pivStateProvider(data.node.path))
                  .value
                  ?.metadata
                  ?.pinMetadata
                  .defaultValue !=
              true,
          reason: 'PIN should not be default',
        );

        // Change PUK
        await $.viewAction(managePukAction);
        if (state.metadata == null) {
          // We expect the default PUK to be set, but we don't know if it is
          await $(pinPukField).enterText(defaultPuk);
        }
        await $(newPinPukField).enterText(changedPuk);
        await $(confirmPinPukField).enterText(changedPuk);
        await $(saveButton).tap();
        await $.condition(
          () =>
              $
                  .read(pivStateProvider(data.node.path))
                  .value
                  ?.metadata
                  ?.pukMetadata
                  .defaultValue !=
              true,
          reason: 'PUK should not be default',
        );

        // Change Management Key
        await $.viewAction(manageManagementKeyAction);
        if (state.metadata == null) {
          // We expect the default management key to be set, but we don't know if it is
          await $(managementKeyField).enterText(defaultManagementKey);
        }
        await $(newManagementKeyField).enterText(changedManagementKey);
        await $(saveButton).tap();

        await $.condition(
          () =>
              $
                  .read(pivStateProvider(data.node.path))
                  .value
                  ?.metadata
                  ?.managementKeyMetadata
                  .defaultValue !=
              true,
          reason: 'Management Key should not be default',
        );

        await $.condition(() {
          final info = $.read(currentDeviceDataProvider).value!.info;
          final (capable, approved) = info.getFipsStatus(Capability.piv);
          return capable == approved;
        }, reason: 'FIPS capable key should be FIPS approved');
      });

      testKey('Key/Certificate management', params, ($, data) async {
        await $.navigate(Section.certificates);

        // This test assumes the previous test has been run
        var state = $.read(pivStateProvider(data.node.path)).value!;
        if (state.metadata != null) {
          for (final isDefault in [
            state.metadata!.pinMetadata.defaultValue,
            state.metadata!.pukMetadata.defaultValue,
            state.metadata!.managementKeyMetadata.defaultValue,
          ]) {
            expect(
              isDefault,
              isFalse,
              reason: 'PIN/PUK/Management Key not set up',
            );
          }
        }

        pivSlot(SlotId slotId) => $(
          $(AppListItem<PivSlot>).which(
            (widget) => (widget as AppListItem<PivSlot>).item.slot == slotId,
          ),
        );

        // Generate a certificate
        await $.itemAction(pivSlot(SlotId.authentication), generateAction);
        await $(managementKeyField).enterText(changedManagementKey);
        await $(unlockButton).tap();
        await $(pinPukField).enterText(changedPin);
        await $(unlockButton).tap();

        await $(subjectField).enterText('CN=Test Certificate');
        await $(saveButton).tap();
        final close = $(closeButton);
        if (close.exists) {
          await close.tap();
        }
        await $('Test Certificate').waitUntilExists();
        expect($('Test Certificate'), findsOneWidget);

        if (data.info.version.isAtLeast(5, 7)) {
          final slotRetired = pivSlot(SlotId.retired1);

          // Move the certificate to a different slot
          await $.itemAction(pivSlot(SlotId.authentication), moveAction);
          await $(ChoiceFilterChip<SlotId?>).tap();
          await $(RegExp(SlotId.retired1.hexId)).tap();
          await $(moveButton).tap();
          if (close.exists) {
            await close.tap();
          }
          await $.pumpAndSettle(); // List may not update immediately
          expect(slotRetired, findsOne);

          // Move the key without the certificate back, using context menu
          await $.itemAction(slotRetired, moveAction);
          await $(ChoiceFilterChip<SlotId?>).tap();
          await $(RegExp(SlotId.authentication.hexId)).tap();
          await $(includeCertificateChip).tap();
          await $(moveButton).tap();
          if (close.exists) {
            await close.tap();
          }
          expect($('Test Certificate'), findsOneWidget);
          expect($($.l10n.l_key_no_certificate), findsOne);
          expect(slotRetired, findsOne);

          // Delete the certificate
          await $.itemAction(slotRetired, deleteAction);
          await $(deleteButton).tap();
          if (close.exists) {
            await close.tap();
          }
          await $.pumpAndSettle(); // List may not update immediately
          expect($('Test Certificate'), findsNothing);
          expect(slotRetired, findsNothing);
        }

        // Delete the key/certificate, using context menu
        await $.tester.tap(
          pivSlot(SlotId.authentication),
          buttons: kSecondaryButton,
        );
        await $.pumpAndSettle();
        await $(deleteAction).tap();
        //await $.itemAction(pivSlot(SlotId.authentication), deleteAction);
        await $(deleteButton).tap();
        if (close.exists) {
          await close.tap();
        }
        await $.condition(() => !$(deleteButton).exists);
        await $.pumpAndSettle(); // List may not update immediately
        expect($('Test Certificate'), findsNothing);
        if (data.info.version.isAtLeast(5, 7)) {
          expect($($.l10n.l_key_no_certificate), findsNothing);
        } else if (data.info.version.isAtLeast(5, 3)) {
          expect($($.l10n.l_key_no_certificate), findsOneWidget);
        }
      });
    },
    skip: isAndroid,
    condition: (info) => info.hasCapability(Capability.piv),
  );
}
