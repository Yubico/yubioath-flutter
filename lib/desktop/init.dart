import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import '../oath/state.dart';
import '../app/state.dart';
import 'oath/state.dart';
import 'rpc.dart';
import 'devices.dart';
import 'qr_scanner.dart';
import 'state.dart';

final _log = Logger('desktop.init');

initializeLogging() {
  Logger.root.onRecord.listen((record) {
    stderr.writeln('[${record.loggerName}] ${record.level}: ${record.message}');
    if (record.error != null) {
      stderr.writeln(record.error);
    }
  });
  _log.info('Logging initialized, outputting to stderr');
}

Future<List<Override>> initializeAndGetOverrides() async {
  await windowManager.ensureInitialized();

  // Linux doesn't currently support hiding the window at start currently.
  // For now, this size should match linux/flutter/my_application.cc to avoid window flicker at startup.
  unawaited(windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setSize(const Size(400, 720));
    await windowManager.show();
  }));

  // Either use the _YKMAN_EXE environment variable, or look relative to executable.
  var exe = Platform.environment['_YKMAN_PATH'];
  if (exe?.isEmpty ?? true) {
    var relativePath = 'ykman-rpc/ykman-rpc';
    if (Platform.isMacOS) {
      relativePath = '../Resources/' + relativePath;
    } else if (Platform.isWindows) {
      relativePath += '.exe';
    }
    exe = Uri.file(Platform.resolvedExecutable)
        .resolve(relativePath)
        .toFilePath();
  }

  _log.info('Starting subprocess: $exe');
  var rpc = await RpcSession.launch(exe!);
  _log.info('ykman-rpc process started', exe);
  rpc.setLogLevel(Logger.root.level);

  return [
    rpcProvider.overrideWithValue(rpc),
    windowStateProvider.overrideWithProvider(desktopWindowStateProvider),
    attachedDevicesProvider.overrideWithProvider(desktopDevicesProvider),
    currentDeviceDataProvider.overrideWithProvider(desktopDeviceDataProvider),
    oathStateProvider.overrideWithProvider(desktopOathState),
    credentialListProvider
        .overrideWithProvider(desktopOathCredentialListProvider),
    qrScannerProvider.overrideWithProvider(desktopQrScannerProvider),
  ];
}
