/*
 * Copyright (C) 2022-2023 Yubico.
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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../core/state.dart';
import 'app_methods.dart';
import 'devices.dart';
import 'models.dart';

part 'state.g.dart';

const _contextChannel = MethodChannel('android.state.appContext');

@Riverpod(keepAlive: true)
class AndroidAllowScreenshots extends _$AndroidAllowScreenshots {
  @override
  bool build() => false;

  void setAllowScreenshots(bool value) async {
    final result =
        await appMethodsChannel.invokeMethod('allowScreenshots', value);
    state = result;
  }
}

@Riverpod(keepAlive: true)
AppClipboard androidClipboard(AndroidClipboardRef ref) =>
    _AndroidClipboard(ref);

class _AndroidClipboard extends AppClipboard {
  final ProviderRef<AppClipboard> _ref;

  const _AndroidClipboard(this._ref);

  @override
  bool platformGivesFeedback() {
    return _ref.read(androidSdkVersionProvider) >= 33;
  }

  @override
  Future<void> setText(String toClipboard, {bool isSensitive = false}) async {
    await setPrimaryClip(toClipboard, isSensitive);
  }
}

class NfcStateNotifier extends StateNotifier<bool> {
  NfcStateNotifier() : super(false);

  void setNfcEnabled(bool value) {
    state = value;
  }
}

final androidSdkVersionProvider = Provider<int>((ref) => -1);

final androidNfcSupportProvider = Provider<bool>((ref) => false);

final androidNfcStateProvider =
    StateNotifierProvider<NfcStateNotifier, bool>((ref) => NfcStateNotifier());

final androidSupportedThemesProvider = StateProvider<List<ThemeMode>>((ref) {
  if (ref.read(androidSdkVersionProvider) < 29) {
    // the user can select from light or dark theme of the app
    return [ThemeMode.light, ThemeMode.dark];
  } else {
    // the user can also select system theme on newer Android versions
    return ThemeMode.values;
  }
});

class AndroidSubPageNotifier extends CurrentAppNotifier {
  AndroidSubPageNotifier(super.supportedApps) {
    _handleSubPage(state);
  }

  @override
  void setCurrentApp(Application app) {
    super.setCurrentApp(app);
    _handleSubPage(app);
  }

  void _handleSubPage(Application subPage) async {
    await _contextChannel.invokeMethod('setContext', {'index': subPage.index});
  }
}

class AndroidAttachedDevicesNotifier extends AttachedDevicesNotifier {
  @override
  List<DeviceNode> build() => ref
      .watch(androidDeviceDataProvider)
      .maybeWhen(data: (data) => [data.node], orElse: () => []);
}

final androidDeviceDataProvider = Provider<AsyncValue<YubiKeyData>>(
    (ref) => ref.watch(androidYubikeyProvider));

class AndroidCurrentDeviceNotifier extends CurrentDeviceNotifier {
  @override
  DeviceNode? build() =>
      ref.watch(androidYubikeyProvider).whenOrNull(data: (data) => data.node);

  @override
  setCurrentDevice(DeviceNode? device) {
    state = device;
  }
}

final androidNfcTapActionProvider =
    StateNotifierProvider<NfcTapActionNotifier, NfcTapAction>(
        (ref) => NfcTapActionNotifier(ref.watch(prefProvider)));

class NfcTapActionNotifier extends StateNotifier<NfcTapAction> {
  static const _prefNfcOpenApp = 'prefNfcOpenApp';
  static const _prefNfcCopyOtp = 'prefNfcCopyOtp';
  final SharedPreferences _prefs;

  NfcTapActionNotifier._(this._prefs, super._state);

  factory NfcTapActionNotifier(SharedPreferences prefs) {
    final launchApp = prefs.getBool(_prefNfcOpenApp) ?? true;
    final copyOtp = prefs.getBool(_prefNfcCopyOtp) ?? false;
    final NfcTapAction action;
    if (launchApp && copyOtp) {
      action = NfcTapAction.launchAndCopy;
    } else if (copyOtp) {
      action = NfcTapAction.copy;
    } else if (launchApp) {
      action = NfcTapAction.launch;
    } else {
      action = NfcTapAction.noAction;
    }
    return NfcTapActionNotifier._(prefs, action);
  }

  Future<void> setTapAction(NfcTapAction value) async {
    if (state != value) {
      state = value;
      await _prefs.setBool(_prefNfcOpenApp,
          value == NfcTapAction.launch || value == NfcTapAction.launchAndCopy);
      await _prefs.setBool(_prefNfcCopyOtp,
          value == NfcTapAction.copy || value == NfcTapAction.launchAndCopy);
    }
  }
}

// TODO: Get these from Android
final androidNfcSupportedKbdLayoutsProvider =
    Provider<List<String>>((ref) => ['US', 'DE', 'DE-CH']);

final androidNfcKbdLayoutProvider =
    StateNotifierProvider<NfcKbdLayoutNotifier, String>(
        (ref) => NfcKbdLayoutNotifier(ref.watch(prefProvider)));

class NfcKbdLayoutNotifier extends StateNotifier<String> {
  static const String _defaultClipKbdLayout = 'US';
  static const _prefClipKbdLayout = 'prefClipKbdLayout';
  final SharedPreferences _prefs;

  NfcKbdLayoutNotifier(this._prefs)
      : super(_prefs.getString(_prefClipKbdLayout) ?? _defaultClipKbdLayout);

  Future<void> setKeyboardLayout(String value) async {
    if (state != value) {
      state = value;
      await _prefs.setString(_prefClipKbdLayout, value);
    }
  }
}

final androidNfcBypassTouchProvider =
    StateNotifierProvider<NfcBypassTouchNotifier, bool>(
        (ref) => NfcBypassTouchNotifier(ref.watch(prefProvider)));

class NfcBypassTouchNotifier extends StateNotifier<bool> {
  static const _prefNfcBypassTouch = 'prefNfcBypassTouch';
  final SharedPreferences _prefs;

  NfcBypassTouchNotifier(this._prefs)
      : super(_prefs.getBool(_prefNfcBypassTouch) ?? false);

  Future<void> setNfcBypassTouch(bool value) async {
    if (state != value) {
      state = value;
      await _prefs.setBool(_prefNfcBypassTouch, value);
    }
  }
}

final androidNfcSilenceSoundsProvider =
    StateNotifierProvider<NfcSilenceSoundsNotifier, bool>(
        (ref) => NfcSilenceSoundsNotifier(ref.watch(prefProvider)));

class NfcSilenceSoundsNotifier extends StateNotifier<bool> {
  static const _prefNfcSilenceSounds = 'prefNfcSilenceSounds';
  final SharedPreferences _prefs;

  NfcSilenceSoundsNotifier(this._prefs)
      : super(_prefs.getBool(_prefNfcSilenceSounds) ?? false);

  Future<void> setNfcSilenceSounds(bool value) async {
    if (state != value) {
      state = value;
      await _prefs.setBool(_prefNfcSilenceSounds, value);
    }
  }
}

final androidUsbLaunchAppProvider =
    StateNotifierProvider<UsbLaunchAppNotifier, bool>(
        (ref) => UsbLaunchAppNotifier(ref.watch(prefProvider)));

class UsbLaunchAppNotifier extends StateNotifier<bool> {
  static const _prefUsbOpenApp = 'prefUsbOpenApp';
  final SharedPreferences _prefs;

  UsbLaunchAppNotifier(this._prefs)
      : super(_prefs.getBool(_prefUsbOpenApp) ?? false);

  Future<void> setUsbLaunchApp(bool value) async {
    if (state != value) {
      state = value;
      await _prefs.setBool(_prefUsbOpenApp, value);
    }
  }
}
