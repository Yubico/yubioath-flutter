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
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../core/state.dart';
import 'features.dart' as features;
import 'models.dart';

part 'state.g.dart';

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
@Riverpod(keepAlive: true)
WindowState windowState(WindowStateRef ref) =>
    WindowState(focused: true, visible: true, active: true);

@Riverpod(keepAlive: true, dependencies: [])
List<ThemeMode> supportedThemes(SupportedThemesRef ref) =>
    throw UnimplementedError();

@Riverpod(keepAlive: true, dependencies: [pref])
class CommunityTranslations extends _$CommunityTranslations {
  static const String _key = 'APP_STATE_ENABLE_COMMUNITY_TRANSLATIONS';

  @override
  bool build() {
    return ref.read(prefProvider).getBool(_key) == true;
  }

  void setEnableCommunityTranslations(bool value) {
    state = value;
    final prefs = ref.read(prefProvider);
    prefs.setBool(_key, value);
  }
}

@Riverpod(keepAlive: true, dependencies: [CommunityTranslations])
List<Locale> supportedLocales(SupportedLocalesRef ref) {
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
}

@Riverpod(keepAlive: true, dependencies: [supportedLocales])
Locale currentLocale(CurrentLocaleRef ref) {
  final localeStr = Platform.environment['_YA_LOCALE'];
  if (localeStr != null) {
    // Force locale
    final locale = Locale(localeStr, '');
    return basicLocaleListResolution(
        [locale], AppLocalizations.supportedLocales);
  }
  // Choose from supported
  return basicLocaleListResolution(
      PlatformDispatcher.instance.locales, ref.watch(supportedLocalesProvider));
}

@Riverpod(keepAlive: true)
AppLocalizations l10n(L10nRef ref) =>
    lookupAppLocalizations(ref.watch(currentLocaleProvider));

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
@Riverpod(keepAlive: true, dependencies: [])
AsyncValue<YubiKeyData> currentDeviceData(CurrentDeviceDataRef ref) =>
    throw UnimplementedError();

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

@Riverpod(keepAlive: true)
QrScanner? qrScanner(QrScannerRef ref) => null;

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

@Riverpod(keepAlive: true, dependencies: [])
class AppClipboard extends _$AppClipboard {
  @override
  void build() => throw UnimplementedError();

  Future<void> setText(String toClipboard, {bool isSensitive = false}) =>
      throw UnimplementedError();

  bool platformGivesFeedback() => throw UnimplementedError();
}

/// A callback which will be invoked with a [BuildContext] that can be used to
/// open dialogs, show Snackbars, etc.
///
/// Used with the [withContextProvider] provider.
typedef WithContext = Future<T> Function<T>(
    Future<T> Function(BuildContext context) action);

@Riverpod(keepAlive: true)
WithContext withContext(WithContextRef ref) =>
    ref.watch(contextConsumer.notifier).withContext;
