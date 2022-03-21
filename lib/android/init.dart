import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../app/models.dart';
import '../management/state.dart';
import 'management/state.dart';
import 'oath/state.dart';
import 'state.dart';
import 'views/tap_request_dialog.dart';
import '../app/state.dart';
import '../oath/state.dart';

final _log = Logger('android.init');

initializeLogging() {
  Logger.root.onRecord.listen((record) {
    if (record.level >= Logger.root.level) {
      debugPrint('[${record.loggerName}] ${record.level}: ${record.message}');
      if (record.error != null) {
        debugPrint(record.error.toString());
      }
    }
  });
  _log.info('Logging initialized, outputting to stderr');
}

Future<List<Override>> initializeAndGetOverrides() async {
  /// initializes global handler for dialogs
  TapRequestDialog.initialize();

  return [
    supportedAppsProvider.overrideWithValue([
      Application.oath,
      Application.management,
    ]),
    attachedDevicesProvider
        .overrideWithProvider(androidAttachedDevicesProvider),
    currentDeviceDataProvider.overrideWithProvider(androidDeviceDataProvider),
    oathStateProvider.overrideWithProvider(androidOathStateProvider),
    credentialListProvider.overrideWithProvider(androidCredentialListProvider),
    currentAppProvider.overrideWithProvider(androidSubPageProvider),
    managementStateProvider.overrideWithProvider(androidManagementState),
    currentDeviceProvider.overrideWithProvider(androidCurrentDeviceProvider)
  ];
}
