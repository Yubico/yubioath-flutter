/*
 * Copyright (C) 2022,2024 Yubico.
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
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/state.dart';
import '../theme.dart';
import 'features.dart' as features;
import 'key_customization/state.dart';
import 'logging.dart';
import 'models.dart';

final _log = Logger('app.state');

// Officially supported translations
const officialLocales = [
  Locale('en', ''),
];

// Override this to alter the set of supported apps.
final supportedAppsProvider =
    Provider<List<Application>>(implementedApps(Application.values));

extension on Application {
  Feature get _feature => switch (this) {
        Application.oath => features.oath,
        Application.fido => features.fido,
        Application.otp => features.otp,
        Application.piv => features.piv,
        Application.management => features.management,
        Application.openpgp => features.openpgp,
        Application.hsmauth => features.oath,
      };
}

List<Application> Function(Ref) implementedApps(List<Application> apps) =>
    (ref) {
      final hasFeature = ref.watch(featureProvider);
      return apps.where((app) => hasFeature(app._feature)).toList();
    };

// Default implementation is always focused, override with platform specific version.
final windowStateProvider = Provider<WindowState>(
  (ref) => WindowState(focused: true, visible: true, active: true),
);

final supportedThemesProvider = StateProvider<List<ThemeMode>>(
  (ref) => throw UnimplementedError(),
);

final communityTranslationsProvider =
    StateNotifierProvider<CommunityTranslationsNotifier, bool>(
        (ref) => CommunityTranslationsNotifier(ref.watch(prefProvider)));

class CommunityTranslationsNotifier extends StateNotifier<bool> {
  static const String _key = 'APP_STATE_ENABLE_COMMUNITY_TRANSLATIONS';
  final SharedPreferences _prefs;

  CommunityTranslationsNotifier(this._prefs)
      : super(_prefs.getBool(_key) == true);

  void setEnableCommunityTranslations(bool value) {
    state = value;
    _prefs.setBool(_key, value);
  }
}

final supportedLocalesProvider = Provider<List<Locale>>((ref) {
  final locales = [...officialLocales];
  final localeStr = Platform.environment['_YA_LOCALE'];
  if (localeStr != null) {
    // Force locale
    final locale = Locale(localeStr, '');
    locales.add(locale);
  }
  return ref.watch(communityTranslationsProvider)
      ? AppLocalizations.supportedLocales
      : locales;
});

final currentLocaleProvider = Provider<Locale>(
  (ref) {
    final localeStr = Platform.environment['_YA_LOCALE'];
    if (localeStr != null) {
      // Force locale
      final locale = Locale(localeStr, '');
      return basicLocaleListResolution(
          [locale], AppLocalizations.supportedLocales);
    }
    // Choose from supported
    return basicLocaleListResolution(PlatformDispatcher.instance.locales,
        ref.watch(supportedLocalesProvider));
  },
);

final l10nProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(currentLocaleProvider)),
);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) {
    // initialize the keyCustomizationManager
    ref.read(keyCustomizationManagerProvider);
    return ThemeModeNotifier(
        ref.watch(prefProvider), ref.read(supportedThemesProvider));
  },
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

final primaryColorProvider = Provider<Color?>((ref) => null);

final darkThemeProvider = NotifierProvider<ThemeNotifier, ThemeData>(
  () => ThemeNotifier(ThemeMode.dark),
);

final lightThemeProvider = NotifierProvider<ThemeNotifier, ThemeData>(
  () => ThemeNotifier(ThemeMode.light),
);

class ThemeNotifier extends Notifier<ThemeData> {
  final ThemeMode _themeMode;

  ThemeNotifier(this._themeMode);

  @override
  ThemeData build() {
    return _get(
      _themeMode,
      yubiKeyData: ref.watch(currentDeviceDataProvider).valueOrNull,
    );
  }

  static ThemeData _getDefault(ThemeMode themeMode) =>
      themeMode == ThemeMode.light ? AppTheme.lightTheme : AppTheme.darkTheme;

  ThemeData _get(ThemeMode themeMode,
      {Color? color, YubiKeyData? yubiKeyData}) {
    Color? primaryColor = color;
    if (yubiKeyData != null) {
      final manager = ref.read(keyCustomizationManagerProvider);
      final customization = manager.get(yubiKeyData.info.serial?.toString());
      primaryColor = customization?.getColor() ?? color;
    }

    primaryColor ??= ref.read(primaryColorProvider);

    return (primaryColor != null)
        ? _getDefault(themeMode).copyWith(
            colorScheme: ColorScheme.fromSeed(
                brightness: themeMode == ThemeMode.dark
                    ? Brightness.dark
                    : Brightness.light,
                seedColor: primaryColor))
        : _getDefault(themeMode);
  }

  void setColor(Color? color) {
    _log.debug('Set color to $color');
    state = _get(_themeMode, color: color);
  }
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
