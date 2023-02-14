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

import '../app/models.dart';
import '../app/state.dart';
import 'app_methods.dart';
import 'devices.dart';

const _contextChannel = MethodChannel('android.state.appContext');

final androidAllowScreenshotsProvider =
    StateNotifierProvider<AllowScreenshotsNotifier, bool>(
  (ref) => AllowScreenshotsNotifier(),
);

class AllowScreenshotsNotifier extends StateNotifier<bool> {
  AllowScreenshotsNotifier() : super(false);

  void setAllowScreenshots(bool value) async {
    final result =
        await appMethodsChannel.invokeMethod('allowScreenshots', value);
    if (mounted) {
      state = result;
    }
  }
}

final androidClipboardProvider = Provider<AppClipboard>(
  (ref) => _AndroidClipboard(ref),
);

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
  NfcStateNotifier(): super(false);

  void setNfcEnabled(bool value) {
    state = value;
  }
}

enum NfcActivity {
  notActive,
  ready,
  tagPresent,
  processingStarted,
  processingFinished,
  processingInterrupted,
}

class NfcActivityNotifier extends StateNotifier<NfcActivity> {
  NfcActivityNotifier() : super(NfcActivity.notActive);

  void setActivityState(int stateValue) {
    switch (stateValue) {
      case 0:
        state = NfcActivity.notActive;
        break;
      case 1:
        state = NfcActivity.ready;
        break;
      case 2:
        state = NfcActivity.tagPresent;
        break;
      case 3:
        state = NfcActivity.processingStarted;
        break;
      case 4:
        state = NfcActivity.processingFinished;
        break;
      case 5:
        state = NfcActivity.processingInterrupted;
        break;
      default:
        state = NfcActivity.notActive;
        break;
    }
  }
}

final androidSdkVersionProvider = Provider<int>((ref) => -1);

final androidNfcSupportProvider = Provider<bool>((ref) => false);

final androidNfcStateProvider = StateNotifierProvider<NfcStateNotifier, bool>((ref) =>
  NfcStateNotifier()
);

final androidNfcActivityProvider = StateNotifierProvider<NfcActivityNotifier, NfcActivity>((ref) =>
  NfcActivityNotifier()
);

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
