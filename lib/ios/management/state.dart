/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import 'dart:async';

import 'package:flutter/services.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../management/models.dart';
import '../../management/state.dart';
import '../state.dart';

class IosManagementStateNotifier extends ManagementStateNotifier {
  IosManagementStateNotifier(super.devicePath);
  YubiKeyData? _targetDevice;

  YubiKeyData _displayedDevice() {
    final data = ref.read(currentDeviceDataProvider).value;
    if (data == null || data.node.path != devicePath) {
      throw PlatformException(
        code: 'device_changed',
        message: 'The displayed YubiKey has changed. Open the operation again.',
      );
    }
    return data;
  }

  Map<String, Object?> _expectedDevice() {
    _displayedDevice();
    final target = _targetDevice;
    if (target == null) {
      throw PlatformException(
        code: 'device_unavailable',
        message: 'No YubiKey is selected for this operation.',
      );
    }
    return {
      'transport': target.node.transport.name,
      'serial': target.info.serial,
      'version': target.info.version.toJson(),
      'formFactor': target.info.toJson()['form_factor'],
      'supportedCapabilities': {
        for (final entry in target.info.supportedCapabilities.entries)
          entry.key.name: entry.value,
      },
      'isFips': target.info.isFips,
      'isSky': target.info.isSky,
    };
  }

  @override
  FutureOr<DeviceInfo> build() {
    // Rebuild whenever the active device changes.
    ref.watch(currentDeviceProvider);

    ref.watch(currentDeviceDataProvider);
    final data = _displayedDevice();
    _targetDevice ??= data;
    return data.info;
  }

  @override
  Future<void> writeConfig(
    DeviceConfig config, {
    String? currentLockCode,
    String? newLockCode,
    bool reboot = false,
  }) async {
    final expectedDevice = _expectedDevice();
    final usbEnabled = config.enabledCapabilities[Transport.usb];
    if (usbEnabled != null &&
        UsbInterface.forCapabilities(usbEnabled) & UsbInterface.ccid.value ==
            0) {
      throw PlatformException(
        code: 'unsupported_configuration',
        message:
            'Keep at least one USB smart card application enabled '
            '(OATH, PIV, OpenPGP, or YubiHSM Auth) to preserve iOS USB access.',
      );
    }
    await managementChannel.invokeMethod('configure', {
      'expectedDevice': expectedDevice,
      'config': config.toJson(),
      'currentLockCode': currentLockCode,
      'newLockCode': newLockCode,
      'reboot': reboot,
    });
    ref.read(attachedDevicesProvider.notifier).refresh();
  }

  @override
  Future<void> setMode({
    required int interfaces,
    int challengeResponseTimeout = 0,
    int? autoEjectTimeout,
  }) async {
    await managementChannel.invokeMethod('setMode', {
      'interfaces': interfaces,
      'challengeResponseTimeout': challengeResponseTimeout,
      'autoEjectTimeout': autoEjectTimeout,
    });
    ref.read(attachedDevicesProvider.notifier).refresh();
  }

  @override
  Future<void> deviceReset() async {
    await managementChannel.invokeMethod('deviceReset', {
      'expectedDevice': _expectedDevice(),
    });
  }
}
