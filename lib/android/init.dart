import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/logger.dart';
import 'package:yubico_authenticator/android/window_state_provider.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../app/app.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/main_page.dart';
import '../core/state.dart';
import '../management/state.dart';
import '../oath/state.dart';
import 'api/impl.dart';
import 'management/state.dart';
import 'oath/state.dart';
import 'qr_scanner/qr_scanner_provider.dart';
import 'state.dart';
import 'views/tap_request_dialog.dart';

Future<Widget> initialize() async {
  if (kDebugMode) {
    Logger.root.level = Levels.DEBUG;
  }

  return ProviderScope(
    overrides: [
      supportedAppsProvider.overrideWithValue([
        Application.oath,
      ]),
      prefProvider.overrideWithValue(await SharedPreferences.getInstance()),
      logLevelProvider.overrideWithProvider(androidLogProvider),
      attachedDevicesProvider
          .overrideWithProvider(androidAttachedDevicesProvider),
      currentDeviceDataProvider.overrideWithProvider(androidDeviceDataProvider),
      oathStateProvider.overrideWithProvider(androidOathStateProvider),
      credentialListProvider
          .overrideWithProvider(androidCredentialListProvider),
      currentAppProvider.overrideWithProvider(androidSubPageProvider),
      managementStateProvider.overrideWithProvider(androidManagementState),
      currentDeviceProvider.overrideWithProvider(androidCurrentDeviceProvider),
      qrScannerProvider.overrideWithProvider(androidQrScannerProvider),
      windowStateProvider.overrideWithProvider(androidWindowStateProvider)
    ],
    child: YubicoAuthenticatorApp(page: Consumer(
      builder: (context, ref, child) {
        // activates the sub page provider
        ref.read(androidSubPageProvider);

        // activates window state provider
        ref.read(androidWindowStateProvider);

        /// initializes global handler for dialogs
        FDialogApi.setup(FDialogApiImpl(ref.watch(withContextProvider)));
        return const MainPage();
      },
    )),
  );
}
