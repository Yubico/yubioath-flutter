import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../core/state.dart';
import 'scaffold.dart';

Future<Widget> initialize() async {
  final preferences = await SharedPreferences.getInstance();
  final localeStatus = await loadLocaleStatus();

  return ProviderScope(
    overrides: [
      prefProvider.overrideWithValue(preferences),
      localeStatusProvider.overrideWithValue(localeStatus),
      supportedThemesProvider.overrideWith((ref) => ThemeMode.values),
      supportedSectionsProvider.overrideWithValue(const [
        Section.home,
        Section.accounts,
        Section.passkeys,
        Section.certificates,
        Section.slots,
        Section.settings,
      ]),
      attachedDevicesProvider.overrideWith(IOSAttachedDevicesNotifier.new),
      currentDeviceDataProvider.overrideWithValue(
        const AsyncLoading<YubiKeyData>(),
      ),
      currentDeviceProvider.overrideWith(IOSCurrentDeviceNotifier.new),
      currentSectionProvider.overrideWith((ref) => IOSCurrentSectionNotifier()),
    ],
    child: const YubicoAuthenticatorApp(page: IOSScaffoldPage()),
  );
}
