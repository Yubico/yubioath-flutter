import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/main_page.dart';
import '../core/state.dart';
import '../management/state.dart';
import '../oath/state.dart';
import 'management/state.dart';
import 'oath/state.dart';
import 'qr_scanner/qr_scanner_provider.dart';
import 'state.dart';
import 'views/tap_request_dialog.dart';

final _log = Logger('android.init');

Future<Widget> initialize() async {
  Logger.root.onRecord.listen((record) {
    if (record.level >= Logger.root.level) {
      debugPrint('[${record.loggerName}] ${record.level}: ${record.message}');
      if (record.error != null) {
        debugPrint(record.error.toString());
      }
    }
  });
  _log.info('Logging initialized, outputting to stderr');

  /// initializes global handler for dialogs
  TapRequestDialog.initialize();

  return ProviderScope(
    overrides: [
      supportedAppsProvider.overrideWithValue([
        Application.oath,
      ]),
      prefProvider.overrideWithValue(await SharedPreferences.getInstance()),
      attachedDevicesProvider
          .overrideWithProvider(androidAttachedDevicesProvider),
      currentDeviceDataProvider.overrideWithProvider(androidDeviceDataProvider),
      oathStateProvider.overrideWithProvider(androidOathStateProvider),
      credentialListProvider
          .overrideWithProvider(androidCredentialListProvider),
      currentAppProvider.overrideWithProvider(androidSubPageProvider),
      managementStateProvider.overrideWithProvider(androidManagementState),
      currentDeviceProvider.overrideWithProvider(androidCurrentDeviceProvider),
      qrScannerProvider.overrideWithProvider(androidQrScannerProvider)
    ],
    child: YubicoAuthenticatorApp(page: Consumer(
      builder: (context, ref, child) {
        // activates the sub page provider
        ref.watch(androidSubPageProvider);
        return const MainPage();
      },
    )),
  );
}
