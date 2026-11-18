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
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logging/logging.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../core/models.dart';
import '../management/models.dart';

final _log = Logger('ios.state');

/// MethodChannel matching `ios/Management/ManagementManager.swift`.
const managementChannel = MethodChannel('com.yubico.authenticator/management');

/// EventChannel matching `ios/Management/ManagementManager.swift`.
const _deviceEventsChannel = EventChannel('ios.devices.deviceInfo');

typedef _IosDevices = ({
  AsyncValue<YubiKeyData> wired,
  AsyncValue<YubiKeyData> nfc,
  Transport selected,
});

final _iosDevicesProvider =
    StateNotifierProvider<_IosDevicesNotifier, _IosDevices>(
      (_) => _IosDevicesNotifier(),
    );

final iosYubikeyProvider = Provider<AsyncValue<YubiKeyData>>((ref) {
  final devices = ref.watch(_iosDevicesProvider);
  return devices.selected == Transport.usb ? devices.wired : devices.nfc;
});

class _IosDevicesNotifier extends StateNotifier<_IosDevices> {
  late final StreamSubscription _sub;

  _IosDevicesNotifier()
    : super((
        wired: const AsyncLoading(),
        nfc: const AsyncLoading(),
        selected: Transport.usb,
      )) {
    _sub = _deviceEventsChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: _onError,
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  /// Recursively re-types `Map<Object?, Object?>` (the shape the iOS platform
  /// channel uses for nested dictionaries) into `Map<String, dynamic>` so
  /// generated `fromJson` factories can do their `as Map<String, dynamic>`
  /// casts.
  Object? _deepCast(Object? value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (k, v) => MapEntry(k as String, _deepCast(v)),
      );
    }
    if (value is List) {
      return value.map(_deepCast).toList();
    }
    return value;
  }

  void _onEvent(Object? event) {
    if (!mounted) return;
    try {
      final snapshot = _deepCast(event) as Map<String, dynamic>;
      final wired = _decodeSlot(snapshot['wired'], Transport.usb);
      final nfc = _decodeSlot(snapshot['nfc'], Transport.nfc);
      var selected = state.selected;
      if (snapshot['scanned_nfc'] == true && nfc.hasValue) {
        selected = Transport.nfc;
      } else if (selected == Transport.usb && wired.isLoading && nfc.hasValue) {
        selected = Transport.nfc;
      } else if (selected == Transport.nfc && nfc.isLoading) {
        selected = Transport.usb;
      }
      state = (wired: wired, nfc: nfc, selected: selected);
    } catch (error, stack) {
      _onError(error, stack);
    }
  }

  AsyncValue<YubiKeyData> _decodeSlot(Object? entry, Transport transport) {
    if (entry == null) return const AsyncLoading();
    final slot = entry as Map<String, dynamic>;
    if (slot['error'] case final Map<String, dynamic> error) {
      return AsyncError(
        PlatformException(
          code: error['code'] as String,
          message: error['message'] as String?,
        ),
        StackTrace.current,
      );
    }

    final json = slot['device'] as Map<String, dynamic>;
    final info = DeviceInfo.fromJson(json);
    final name = json['name'] as String? ?? 'YubiKey';
    final usbPid = json['usb_pid'] as int?;
    final identity = info.serial != null
        ? info.serial.toString()
        : jsonEncode([
            info.version.toString(),
            info.formFactor.index,
            info.supportedCapabilities[Transport.usb],
            info.supportedCapabilities[Transport.nfc],
            info.isFips,
            info.isSky,
          ]);
    final path = DevicePath(['ios', transport.name, identity]);
    final node = transport == Transport.nfc
        ? DeviceNode.nfcReader(path, name)
        : DeviceNode.usbYubiKey(
            path,
            name,
            usbPid != null ? UsbPid.fromValue(usbPid) : null,
            info,
          );
    return AsyncData(YubiKeyData(node, name, info));
  }

  void _onError(Object error, StackTrace stack) {
    _log.warning('device event error', error, stack);
    if (!mounted) return;
    state = (
      wired: AsyncError(error, stack),
      nfc: const AsyncLoading(),
      selected: Transport.usb,
    );
  }

  void select(DeviceNode device) {
    final data = device.transport == Transport.usb ? state.wired : state.nfc;
    if (data.value?.node.path == device.path) {
      state = (wired: state.wired, nfc: state.nfc, selected: device.transport);
    }
  }
}

class IosAttachedDevicesNotifier extends AttachedDevicesNotifier {
  @override
  List<DeviceNode> build() {
    final devices = ref.watch(_iosDevicesProvider);
    return [?devices.wired.value?.node, ?devices.nfc.value?.node];
  }
}

class IosCurrentDeviceNotifier extends CurrentDeviceNotifier {
  @override
  DeviceNode? build() {
    return ref.watch(iosYubikeyProvider).whenOrNull(data: (data) => data.node);
  }

  @override
  void setCurrentDevice(DeviceNode? device) {
    if (device != null) ref.read(_iosDevicesProvider.notifier).select(device);
  }
}

/// Starts on Home. Other sections are only reachable while a YubiKey is
/// displayed, so fall back to Home when it disappears or lacks the section.
class IosCurrentSectionNotifier extends CurrentSectionNotifier {
  IosCurrentSectionNotifier() : super(Section.home);

  @override
  void setCurrentSection(Section section) {
    state = section;
  }

  void _onDeviceChanged(YubiKeyData? data) {
    if (state == Section.home || state == Section.settings) return;
    if (data == null || state.getAvailability(data) != Availability.enabled) {
      state = Section.home;
    }
  }
}

/// Provides the `currentSectionProvider` override.
CurrentSectionNotifier iosCurrentSectionNotifier(Ref ref) {
  final notifier = IosCurrentSectionNotifier();
  ref.listen<AsyncValue<YubiKeyData>>(
    currentDeviceDataProvider,
    (_, next) => notifier._onDeviceChanged(next.value),
  );
  return notifier;
}

/// Uses Flutter's standard clipboard. iOS does not have an Android-style
/// "system shows feedback" capability — the toast confirmation is handled
/// in-app like on desktop.
final iosClipboardProvider = Provider<AppClipboard>(
  (ref) => const _IosClipboard(),
);

class _IosClipboard extends AppClipboard {
  const _IosClipboard();

  @override
  bool platformGivesFeedback() => false;

  @override
  Future<void> setText(String toClipboard, {bool isSensitive = false}) async {
    await Clipboard.setData(ClipboardData(text: toClipboard));
  }
}

/// Triggers an NFC scan via `ManagementManager.readDeviceInfoNfc` on the
/// Swift side. The result is delivered through the device event channel.
Future<void> triggerNfcDeviceInfoScan() =>
    managementChannel.invokeMethod<void>('readDeviceInfoNfc');

/// Identity and transport of [target], used by native code to verify that an
/// operation runs against the selected YubiKey.
Map<String, Object?> iosExpectedDevice(YubiKeyData target) => {
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
