/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

// iOS-specific cross-cutting providers. Mirrors `lib/android/state.dart`.
//
// Tier 1 scope: surface the device announced by the Swift `ManagementManager`
// over MethodChannel + EventChannel and expose the providers required by
// `MainPage`. Per-application state (oath/fido/piv/management) ships in
// later tiers.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../management/models.dart';

final _log = Logger('ios.state');

/// MethodChannel matching `ios/Management/ManagementManager.swift`.
const managementChannel = MethodChannel('com.yubico.authenticator/management');

/// EventChannel matching `ios/Management/ManagementManager.swift`.
const _deviceEventsChannel = EventChannel('ios.devices.deviceInfo');

/// Streams `YubiKeyData` derived from `ManagementManager`'s event channel.
///
/// The channel emits either a `Map<String, Object?>` (device attached) or
/// `null` (device detached). For robustness we also accept a JSON string,
/// matching the Android shape.
final iosYubikeyProvider =
    StateNotifierProvider<_IosYubikeyNotifier, AsyncValue<YubiKeyData>>(
      (ref) => _IosYubikeyNotifier(),
    );

class _IosYubikeyNotifier extends StateNotifier<AsyncValue<YubiKeyData>> {
  late final StreamSubscription _sub;

  _IosYubikeyNotifier() : super(const AsyncValue.loading()) {
    // ignore: avoid_print
    print('[ios.state] _IosYubikeyNotifier subscribing to device events');
    _sub = _deviceEventsChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object error, StackTrace stack) {
        // ignore: avoid_print
        print('[ios.state] device event stream error: $error');
        _log.warning('device event error', error);
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _decode(Object? event) {
    if (event == null) return null;
    if (event is String) {
      return _deepCast(jsonDecode(event)) as Map<String, dynamic>;
    }
    if (event is Map) {
      return _deepCast(event) as Map<String, dynamic>;
    }
    return null;
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

  Future<void> _onEvent(Object? event) async {
    // ignore: avoid_print
    print(
      '[ios.state] _onEvent type=${event.runtimeType} isNull=${event == null}',
    );
    final json = _decode(event);
    if (json == null) {
      // ignore: avoid_print
      print('[ios.state] YubiKey detached -> AsyncLoading');
      state = const AsyncValue.loading();
      return;
    }

    final next = await AsyncValue.guard(() async {
      final info = DeviceInfo.fromJson(json);
      final name = json['name'] as String? ?? 'YubiKey';
      final isNfc = json['is_nfc'] as bool? ?? false;
      final usbPid = json['usb_pid'] as int?;

      final node = isNfc
          ? DeviceNode.nfcReader(DevicePath(const []), name)
          : DeviceNode.usbYubiKey(
              DevicePath(const []),
              name,
              usbPid != null ? UsbPid.fromValue(usbPid) : UsbPid.yk4OtpFidoCcid,
              info,
            );
      // ignore: avoid_print
      print('[ios.state] decoded YubiKey name=$name nfc=$isNfc');
      return YubiKeyData(node, name, info);
    });
    // ignore: avoid_print
    print(
      '[ios.state] new state isError=${next is AsyncError} mounted=$mounted',
    );
    if (next is AsyncError) {
      // ignore: avoid_print
      print('[ios.state] decode error: ${(next).error}');
      _log.warning('failed to decode YubiKey event', next.error);
    }
    if (mounted) state = next;
  }
}

/// Adapts `iosYubikeyProvider` into the shape expected by the app-level
/// `currentDeviceDataProvider`.
final iosDeviceDataProvider = Provider<AsyncValue<YubiKeyData>>(
  (ref) => ref.watch(iosYubikeyProvider),
);

class IosAttachedDevicesNotifier extends AttachedDevicesNotifier {
  @override
  List<DeviceNode> build() => ref
      .watch(iosYubikeyProvider)
      .maybeWhen(data: (data) => [data.node], orElse: () => []);
}

class IosCurrentDeviceNotifier extends CurrentDeviceNotifier {
  @override
  DeviceNode? build() {
    final node = ref
        .watch(iosYubikeyProvider)
        .whenOrNull(data: (data) => data.node);
    // ignore: avoid_print
    print('[ios.state] IosCurrentDeviceNotifier.build -> ${node != null}');
    return node;
  }

  @override
  void setCurrentDevice(DeviceNode? device) {
    state = device;
  }
}

class IosCurrentSectionNotifier extends CurrentSectionNotifier {
  static const String _key = 'APP_STATE_LAST_SECTION';

  final SharedPreferences _prefs;

  IosCurrentSectionNotifier(this._prefs, List<Section> supportedSections)
    : super(_fromName(_prefs.getString(_key), supportedSections));

  @override
  void setCurrentSection(Section section) {
    if (section != Section.home) {
      _prefs.setString(_key, section.name);
    }
    state = section;
  }

  static Section _fromName(String? name, List<Section> supportedSections) =>
      supportedSections.firstWhere(
        (element) => element.name == name,
        orElse: () => supportedSections.first,
      );
}

/// Provides the `currentSectionProvider` override.
CurrentSectionNotifier iosCurrentSectionNotifier(Ref ref) {
  return IosCurrentSectionNotifier(
    ref.watch(prefProvider),
    ref.watch(supportedSectionsProvider),
  );
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
/// Swift side. Returns the resulting raw map (same shape as the event
/// channel), or throws a `PlatformException`.
Future<Map<String, dynamic>?> triggerNfcDeviceInfoScan() async {
  final result = await managementChannel.invokeMethod<dynamic>(
    'readDeviceInfoNfc',
  );
  if (result == null) return null;
  if (result is Map) return Map<String, dynamic>.from(result);
  if (result is String) {
    return Map<String, dynamic>.from(jsonDecode(result) as Map);
  }
  return null;
}
