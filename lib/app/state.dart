/*
 * Copyright (C) 2022 Yubico.
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

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../core/state.dart';
import 'models.dart';

final _log = Logger('app.state');

// Override this to alter the set of supported apps.
final supportedAppsProvider =
    Provider<List<Application>>((ref) => Application.values);

// Default implementation is always focused, override with platform specific version.
final windowStateProvider = Provider<WindowState>(
  (ref) => WindowState(focused: true, visible: true, active: true),
);

final supportedThemesProvider = StateProvider<List<ThemeMode>>(
  (ref) => throw UnimplementedError(),
);

final _l10nProvider = StateNotifierProvider<_L10nNotifier, AppLocalizations>(
    (ref) => _L10nNotifier());

final l10nProvider = Provider<AppLocalizations>(
  (ref) => ref.watch(_l10nProvider),
);

class _L10nNotifier extends StateNotifier<AppLocalizations>
    with WidgetsBindingObserver {
  _L10nNotifier() : super(lookupAppLocalizations(window.locale)) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  @protected
  void didChangeLocales(List<Locale>? locales) {
    state = lookupAppLocalizations(window.locale);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(
      ref.watch(prefProvider), ref.read(supportedThemesProvider)),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'APP_STATE_THEME';
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs, List<ThemeMode> supportedThemes)
      : super(_fromName(_prefs.getString(_key), supportedThemes));

  void setThemeMode(ThemeMode mode) {
    _log.debug('Set theme to $mode');
    state = mode;
    _prefs.setString(_key, mode.name);
  }

  static ThemeMode _fromName(String? name, List<ThemeMode> supportedThemes) =>
      supportedThemes.firstWhere((element) => element.name == name,
          orElse: () => supportedThemes.first);
}

// Override with platform implementation
final attachedDevicesProvider =
    NotifierProvider<AttachedDevicesNotifier, List<DeviceNode>>(
  () => throw UnimplementedError(),
);

abstract class AttachedDevicesNotifier extends Notifier<List<DeviceNode>> {
  /// Force a refresh of all device data.
  void refresh() {}
}

// Override with platform implementation
final currentDeviceDataProvider = Provider<AsyncValue<YubiKeyData>>(
  (ref) => throw UnimplementedError(),
);

// Override with platform implementation
final currentDeviceProvider =
    NotifierProvider<CurrentDeviceNotifier, DeviceNode?>(
        () => throw UnimplementedError());

abstract class CurrentDeviceNotifier extends Notifier<DeviceNode?> {
  setCurrentDevice(DeviceNode? device);
}

final currentAppProvider =
    StateNotifierProvider<CurrentAppNotifier, Application>((ref) {
  final notifier = CurrentAppNotifier(ref.watch(supportedAppsProvider));
  ref.listen<AsyncValue<YubiKeyData>>(currentDeviceDataProvider, (_, data) {
    notifier._notifyDeviceChanged(data.whenOrNull(data: ((data) => data)));
  }, fireImmediately: true);
  return notifier;
});

class CurrentAppNotifier extends StateNotifier<Application> {
  final List<Application> _supportedApps;

  CurrentAppNotifier(this._supportedApps) : super(_supportedApps.first);

  void setCurrentApp(Application app) {
    state = app;
  }

  void _notifyDeviceChanged(YubiKeyData? data) {
    if (data == null ||
        state.getAvailability(data) != Availability.unsupported) {
      // Keep current app
      return;
    }

    state = _supportedApps.firstWhere(
      (app) => app.getAvailability(data) == Availability.enabled,
      orElse: () => _supportedApps.first,
    );
  }
}

abstract class QrScanner {
  /// Scans (or searches the given image) for a QR code, and decodes it.
  ///
  /// The contained data is returned as a String, or null, if no QR code is
  /// found.
  Future<String?> scanQr([String? imageData]);
}

final qrScannerProvider = Provider<QrScanner?>(
  (ref) => null,
);

final contextConsumer =
    StateNotifierProvider<ContextConsumer, Function(BuildContext)?>(
        (ref) => ContextConsumer());

class ContextConsumer extends StateNotifier<Function(BuildContext)?> {
  ContextConsumer() : super(null);

  Future<T> withContext<T>(Future<T> Function(BuildContext context) action) {
    final completer = Completer<T>();
    if (mounted) {
      state = (context) async {
        completer.complete(await action(context));
      };
    } else {
      completer.completeError('Not attached');
    }
    return completer.future;
  }
}

abstract class AppClipboard {
  const AppClipboard();

  Future<void> setText(String toClipboard, {bool isSensitive = false});

  bool platformGivesFeedback();
}

final clipboardProvider = Provider<AppClipboard>(
  (ref) => throw UnimplementedError(),
);

/// A callback which will be invoked with a [BuildContext] that can be used to
/// open dialogs, show Snackbars, etc.
///
/// Used with the [withContextProvider] provider.
typedef WithContext = Future<T> Function<T>(
    Future<T> Function(BuildContext context) action);

final withContextProvider = Provider<WithContext>(
    (ref) => ref.watch(contextConsumer.notifier).withContext);
