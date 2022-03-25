import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../app/app.dart';
import '../app/views/main_page.dart';
import '../core/state.dart';
import '../fido/state.dart';
import '../oath/state.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../management/state.dart';
import 'fido/state.dart';
import 'management/state.dart';
import 'oath/state.dart';
import 'rpc.dart';
import 'devices.dart';
import 'qr_scanner.dart';
import 'state.dart';

final _log = Logger('desktop.init');
const String _keyWidth = 'DESKTOP_WINDOW_WIDTH';
const String _keyHeight = 'DESKTOP_WINDOW_HEIGHT';

class _WindowResizeListener extends WindowListener {
  final SharedPreferences _prefs;
  _WindowResizeListener(this._prefs);

  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    await _prefs.setDouble(_keyWidth, size.width);
    await _prefs.setDouble(_keyHeight, size.height);
  }
}

Future<Widget> initialize() async {
  _initLogging();

  await windowManager.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  unawaited(windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setMinimumSize(const Size(270, 0));
    // Linux doesn't currently support hiding the window at start currently.
    // For now, size on Linux is in linux/flutter/my_application.cc to avoid window flicker at startup.
    if (!Platform.isLinux) {
      final width = prefs.getDouble(_keyWidth) ?? 400;
      final height = prefs.getDouble(_keyHeight) ?? 720;
      await windowManager.setSize(Size(width, height));
      await windowManager.show();
      windowManager.addListener(_WindowResizeListener(prefs));
    }
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
  final rpc = await RpcSession.launch(exe!);
  _log.info('ykman-rpc process started', exe);
  rpc.setLogLevel(Logger.root.level);

  return ProviderScope(
    overrides: [
      supportedAppsProvider.overrideWithValue([
        Application.oath,
        Application.fido,
        Application.otp,
        Application.piv,
        Application.management,
      ]),
      prefProvider.overrideWithValue(prefs),
      rpcProvider.overrideWithValue(rpc),
      windowStateProvider.overrideWithProvider(desktopWindowStateProvider),
      attachedDevicesProvider.overrideWithProvider(desktopDevicesProvider),
      currentDeviceDataProvider.overrideWithProvider(desktopDeviceDataProvider),
      oathStateProvider.overrideWithProvider(desktopOathState),
      credentialListProvider
          .overrideWithProvider(desktopOathCredentialListProvider),
      qrScannerProvider.overrideWithProvider(desktopQrScannerProvider),
      managementStateProvider.overrideWithProvider(desktopManagementState),
      fidoStateProvider.overrideWithProvider(desktopFidoState),
      fidoPinProvider.overrideWithProvider(desktopFidoPinProvider),
      fingerprintProvider.overrideWithProvider(desktopFingerprintProvider),
      credentialProvider.overrideWithProvider(desktopCredentialProvider),
      currentDeviceProvider.overrideWithProvider(desktopCurrentDeviceProvider)
    ],
    child: YubicoAuthenticatorApp(page: Consumer(
      builder: (context, ref, child) {
        // Keep RPC log level synced with main app.
        ref.listen<Level>(logLevelProvider, (_, level) {
          rpc.setLogLevel(level);
        });
        return const MainPage();
      },
    )),
  );
}

void _initLogging() {
  Logger.root.onRecord.listen((record) {
    stderr.writeln('[${record.loggerName}] ${record.level}: ${record.message}');
    if (record.error != null) {
      stderr.writeln(record.error);
    }
  });

  final arguments = Platform.executableArguments;
  final logLevelIndex = arguments.indexOf('--log-level');
  if (logLevelIndex != -1) {
    try {
      final levelName = arguments[logLevelIndex + 1];
      Level level = Level.LEVELS
          .firstWhere((level) => level.name == levelName.toUpperCase());
      Logger.root.level = level;
      _log.info('Log level initialized from command line argument');
    } catch (error) {
      _log.severe('Failed to set log level', error);
    }
  }

  _log.info('Logging initialized, outputting to stderr');
}
