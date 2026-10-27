/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/main_page.dart';
import '../core/state.dart';
import '../fido/state.dart';
import '../management/state.dart';
import '../oath/state.dart';
import '../otp/state.dart';
import '../piv/state.dart';
import 'fido/state.dart';
import 'management/state.dart';
import 'oath/state.dart';
import 'otp/state.dart';
import 'piv/state.dart';
import 'qr_scanner.dart';
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
        Section.fingerprints,
        Section.passkeys,
        Section.certificates,
        Section.slots,
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
      qrScannerProvider.overrideWith(
        (ref) => IosQrScanner(ref.watch(withContextProvider)),
      ),
      managementStateProvider.overrideWith2(IosManagementStateNotifier.new),
      fidoStateProvider.overrideWith2(IosFidoStateNotifier.new),
      fingerprintProvider.overrideWith2(IosFidoFingerprintsNotifier.new),
      credentialProvider.overrideWith2(IosFidoCredentialsNotifier.new),
      oathStateProvider.overrideWith2(IosOathStateNotifier.new),
      credentialListProvider.overrideWith(buildIosCredentialList),
      pivStateProvider.overrideWith2(IosPivStateNotifier.new),
      pivSlotsProvider.overrideWith2(IosPivSlotsNotifier.new),
      otpStateProvider.overrideWith2(IosOtpStateNotifier.new),
    ],
    child: const YubicoAuthenticatorApp(page: MainPage()),
  );
}
