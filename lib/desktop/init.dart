import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yubico_authenticator/desktop/devices.dart';
import 'package:yubico_authenticator/desktop/oath/state.dart';
import 'package:yubico_authenticator/desktop/state.dart';
import 'package:yubico_authenticator/oath/state.dart';

import '../app/state.dart';
import 'rpc.dart';

final log = Logger('desktop.init');

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

  log.info('Starting subprocess: $exe');
  var rpc = await RpcSession.launch(exe!);
  log.info('ykman-rpc process started', exe);
  rpc.setLogLevel(Logger.root.level);

  return [
    rpcProvider.overrideWithValue(rpc),
    windowStateProvider.overrideWithProvider(desktopWindowStateProvider),
    attachedDevicesProvider.overrideWithProvider(desktopDevicesProvider),
    currentDeviceDataProvider.overrideWithProvider(desktopDeviceDataProvider),
    oathStateProvider.overrideWithProvider(desktopOathState),
    credentialListProvider
        .overrideWithProvider(desktopOathCredentialListProvider),
  ];
}
