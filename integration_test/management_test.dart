import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/management/models.dart';
import 'package:yubico_authenticator/management/views/keys.dart' as management;

import 'utils.dart';

extension on PatrolTester {
  Future<void> toggleUsbCapability(Capability capability, bool enabled) async {
    await navigate(Section.home);
    await viewAction(yubikeyApplicationToggleMenuButton);

    final chip = $(
      Key('${management.usbCapabilityKeyPrefix}.${capability.name}'),
    );
    expect(chip.widget<FilterChip>().selected, !enabled);
    await chip.tap();
    expect(chip.widget<FilterChip>().selected, enabled);
    await $(management.saveButtonKey).tap();

    await condition(
      () {
        final info = read(currentDeviceDataProvider).value?.info;
        if (info == null) return false;
        final configured = info.config.enabledCapabilities[Transport.usb] ?? 0;
        return (configured & capability.value != 0) == enabled;
      },
      timeout: const Duration(seconds: 30),
      reason: '${capability.name} did not update after configuration',
      settle: false,
    );
    await condition(
      () => !$(management.saveButtonKey).exists,
      reason: 'Configuration dialog did not close',
      settle: false,
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  appGroup('Management', (params) {
    testKey(
      'Toggle application without reboot',
      params,
      ($, data) async {
        final original =
            data.info.config.enabledCapabilities[Transport.usb] ?? 0;
        final initiallyEnabled = original & Capability.u2f.value != 0;
        try {
          await $.toggleUsbCapability(Capability.u2f, !initiallyEnabled);
          final current = $.read(currentDeviceDataProvider).requireValue;
          expect(current.info.serial, data.info.serial);
          expect(current.node.pid, data.node.pid);
          expect(
            current.info.config.enabledCapabilities[Transport.usb],
            original ^ Capability.u2f.value,
          );
        } finally {
          await $.condition(
            () =>
                $.read(currentDeviceDataProvider).value?.info.serial ==
                data.info.serial,
            settle: false,
          );
          final current = $.read(currentDeviceDataProvider).requireValue.info;
          if ((current.config.enabledCapabilities[Transport.usb] ?? 0) !=
              original) {
            await $.toggleUsbCapability(Capability.u2f, initiallyEnabled);
          }
        }
        expect(
          $
              .read(currentDeviceDataProvider)
              .requireValue
              .info
              .config
              .enabledCapabilities[Transport.usb],
          original,
        );
      },
      skip: params.windowSize != WindowSize.wide || isAndroid,
      condition: (info) =>
          info.version.isAtLeast(5) &&
          !info.isLocked &&
          info.resetBlocked == 0 &&
          info.hasCapability(Capability.u2f) &&
          (info.config.enabledCapabilities[Transport.usb] ?? 0) &
                  Capability.fido2.value !=
              0,
    );

    testKey(
      'Toggle USB interface and restore',
      params,
      ($, data) async {
        final original =
            data.info.config.enabledCapabilities[Transport.usb] ?? 0;
        final initiallyEnabled = original & Capability.otp.value != 0;
        try {
          await $.toggleUsbCapability(Capability.otp, !initiallyEnabled);
          final current = $.read(currentDeviceDataProvider).requireValue;
          expect(current.info.serial, data.info.serial);
          expect(
            current.node.pid,
            isNot(data.node.pid),
            reason: 'USB interface change should re-enumerate the device',
          );
          expect(
            current.info.config.enabledCapabilities[Transport.usb],
            original ^ Capability.otp.value,
          );
        } finally {
          await $.condition(
            () =>
                $.read(currentDeviceDataProvider).value?.info.serial ==
                data.info.serial,
            settle: false,
          );
          final current = $.read(currentDeviceDataProvider).requireValue.info;
          if ((current.config.enabledCapabilities[Transport.usb] ?? 0) !=
              original) {
            await $.toggleUsbCapability(Capability.otp, initiallyEnabled);
          }
        }
        expect(
          $
              .read(currentDeviceDataProvider)
              .requireValue
              .info
              .config
              .enabledCapabilities[Transport.usb],
          original,
        );
      },
      skip: params.windowSize != WindowSize.wide || isAndroid,
      condition: (info) =>
          info.version.isAtLeast(5) &&
          !info.isLocked &&
          info.resetBlocked == 0 &&
          info.hasCapability(Capability.otp) &&
          (info.config.enabledCapabilities[Transport.usb] ?? 0) &
                  Capability.fido2.value !=
              0,
    );
  });
}
