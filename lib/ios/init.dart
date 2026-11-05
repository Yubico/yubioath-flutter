import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../app/features.dart' as features;
import '../app/models.dart';
import '../app/state.dart';
import '../core/state.dart';
import '../management/state.dart';
import 'management/state.dart';
import 'scaffold.dart';
import 'state.dart';

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
      featureFlagProvider.overrideWith(
        (ref) => FeatureFlagsNotifier()
          ..loadConfig({
            features.oath.path: false,
            features.fido.path: false,
            features.piv.path: false,
            features.otp.path: false,
          }),
      ),
      attachedDevicesProvider.overrideWith(IosAttachedDevicesNotifier.new),
      currentDeviceDataProvider.overrideWith(
        (ref) => ref.watch(iosYubikeyProvider),
      ),
      currentDeviceProvider.overrideWith(IosCurrentDeviceNotifier.new),
      currentSectionProvider.overrideWith(iosCurrentSectionNotifier),
      clipboardProvider.overrideWith((ref) => ref.watch(iosClipboardProvider)),
      managementStateProvider.overrideWith2(IosManagementStateNotifier.new),
    ],
    child: const YubicoAuthenticatorApp(page: IOSScaffoldPage()),
  );
}
