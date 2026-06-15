/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

// iOS app bootstrap. Mirrors `lib/android/init.dart`.
//
// Tier 1 scope: render `MainPage` driven by `ManagementManager` events.
// Per-application state (oath/fido/piv/management) ships in later tiers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/main_page.dart';
import '../core/state.dart';
import 'state.dart';

Future<Widget> initialize() async {
  final prefs = await SharedPreferences.getInstance();
  final localeStatus = await loadLocaleStatus();

  return ProviderScope(
    overrides: [
      prefProvider.overrideWithValue(prefs),
      localeStatusProvider.overrideWithValue(localeStatus),
      supportedThemesProvider.overrideWith((ref) => ThemeMode.values),
      supportedSectionsProvider.overrideWithValue(const [
        Section.home,
        Section.accounts,
        Section.passkeys,
        Section.certificates,
        Section.settings,
      ]),
      attachedDevicesProvider.overrideWith(() => IosAttachedDevicesNotifier()),
      currentDeviceProvider.overrideWith(() => IosCurrentDeviceNotifier()),
      currentDeviceDataProvider.overrideWith(
        (ref) => ref.watch(iosDeviceDataProvider),
      ),
      currentSectionProvider.overrideWith(
        (ref) => iosCurrentSectionNotifier(ref),
      ),
      clipboardProvider.overrideWith((ref) => ref.watch(iosClipboardProvider)),
    ],
    child: const YubicoAuthenticatorApp(page: MainPage()),
  );
}
