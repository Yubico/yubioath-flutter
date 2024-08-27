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
import 'dart:convert';
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
import 'logging.dart';
import 'models.dart';

final _log = Logger('app.state');

// Officially supported translations
const officialLocales = [
  Locale('en', ''),
  Locale('fr', ''),
  Locale('ja', ''),
];

extension on Section {
  Feature get _feature => switch (this) {
        Section.home => features.home,
        Section.accounts => features.oath,
        Section.securityKey => features.fido,
        Section.passkeys => features.fido,
        Section.fingerprints => features.fingerprints,
        Section.slots => features.otp,
        Section.certificates => features.piv,
      };
}

final supportedSectionsProvider = Provider<List<Section>>(
  (ref) {
    final hasFeature = ref.watch(featureProvider);
    return Section.values
        .where((section) => hasFeature(section._feature))
        .toList();
  },
);

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

final defaultColorProvider = Provider<Color>((ref) => defaultPrimaryColor);

final primaryColorProvider = Provider<Color>((ref) {
  const prefLastUsedColor = 'LAST_USED_COLOR';
  final prefs = ref.watch(prefProvider);
  final data = ref.watch(currentDeviceDataProvider).valueOrNull;
  final defaultColor = ref.watch(defaultColorProvider);
  if (data != null) {
    final serial = data.info.serial;
    if (serial != null) {
      final customization = ref.watch(keyCustomizationManagerProvider)[serial];
      final deviceColor = customization?.color;
      if (deviceColor != null) {
        prefs.setInt(prefLastUsedColor, deviceColor.value);
        return deviceColor;
      } else {
        prefs.remove(prefLastUsedColor);
        return defaultColor;
      }
    }
  }

  final lastUsedColor = prefs.getInt(prefLastUsedColor);
  return lastUsedColor != null ? Color(lastUsedColor) : defaultColor;
});

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

final currentSectionProvider =
    StateNotifierProvider<CurrentSectionNotifier, Section>(
        (ref) => throw UnimplementedError());

abstract class CurrentSectionNotifier extends StateNotifier<Section> {
  CurrentSectionNotifier(super.initial);

  setCurrentSection(Section section);
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

final keyCustomizationManagerProvider =
    StateNotifierProvider<KeyCustomizationNotifier, Map<int, KeyCustomization>>(
        (ref) => KeyCustomizationNotifier(ref.watch(prefProvider)));

class KeyCustomizationNotifier
    extends StateNotifier<Map<int, KeyCustomization>> {
  static const _prefKeyCustomizations = 'KEY_CUSTOMIZATIONS';
  final SharedPreferences _prefs;

  KeyCustomizationNotifier(this._prefs)
      : super(_readCustomizations(_prefs.getString(_prefKeyCustomizations)));

  static Map<int, KeyCustomization> _readCustomizations(String? pref) {
    if (pref == null) {
      return {};
    }

    try {
      final retval = <int, KeyCustomization>{};
      for (var element in json.decode(pref)) {
        final keyCustomization = KeyCustomization.fromJson(element);
        retval[keyCustomization.serial] = keyCustomization;
      }
      return retval;
    } catch (e) {
      _log.error('Failure reading customizations: $e');
      return {};
    }
  }

  KeyCustomization? get(int serial) {
    _log.debug('Getting key customization for $serial');
    return state[serial];
  }

  Future<void> set({required int serial, String? name, Color? color}) async {
    _log.debug('Setting key customization for $serial: $name, $color');
    if (name == null && color == null) {
      // remove this customization
      state = {...state..remove(serial)};
    } else {
      state = {
        ...state
          ..[serial] =
              KeyCustomization(serial: serial, name: name, color: color)
      };
    }
    await _prefs.setString(
        _prefKeyCustomizations, json.encode(state.values.toList()));
  }
}
