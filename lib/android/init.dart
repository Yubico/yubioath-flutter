import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/oath/state.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/android/views/tap_request_dialog.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/oath/state.dart';

final _log = Logger('android.init');

const methodChannel = MethodChannel('com.yubico.yubikit_android/channel');

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
    attachedDevicesProvider
        .overrideWithProvider(androidAttachedDevicesProvider),
    currentDeviceDataProvider.overrideWithProvider(androidDeviceDataProvider),
    oathStateProvider.overrideWithProvider(androidOathStateProvider),
    credentialListProvider.overrideWithProvider(androidCredentialListProvider),
    subPageProvider.overrideWithProvider(androidSubPageProvider),
  ];
}
