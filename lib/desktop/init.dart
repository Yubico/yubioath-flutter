/*
 * Copyright (C) 2022-2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../app/app.dart';
import '../app/logging.dart';
import '../app/message.dart';
import '../app/state.dart';
import '../app/views/app_failure_page.dart';
import '../app/views/main_page.dart';
import '../app/views/message_page.dart';
import '../core/state.dart';
import '../fido/state.dart';
import '../management/state.dart';
import '../oath/state.dart';
import '../otp/state.dart';
import '../piv/state.dart';
import '../version.dart';
import 'devices.dart';
import 'fido/state.dart';
import 'management/state.dart';
import 'oath/state.dart';
import 'otp/state.dart';
import 'piv/state.dart';
import 'qr_scanner.dart';
import 'rpc.dart';
import 'state.dart';
import 'systray.dart';
import 'window_manager_helper/defaults.dart';
import 'window_manager_helper/window_manager_helper.dart';

final _log = Logger('desktop.init');

const String _keyLeft = 'DESKTOP_WINDOW_LEFT';
const String _keyTop = 'DESKTOP_WINDOW_TOP';
const String _keyWidth = 'DESKTOP_WINDOW_WIDTH';
const String _keyHeight = 'DESKTOP_WINDOW_HEIGHT';
const String _logLevel = 'log-level';
const String _logFile = 'log-file';
const String _hidden = 'hidden';
const String _shown = 'shown';

void _saveWindowBounds(WindowManagerHelper helper) async {
  final bounds = await helper.getBounds();
  await helper.sharedPreferences.setDouble(_keyWidth, bounds.width);
  await helper.sharedPreferences.setDouble(_keyHeight, bounds.height);
  await helper.sharedPreferences.setDouble(_keyLeft, bounds.left);
  await helper.sharedPreferences.setDouble(_keyTop, bounds.top);
  _log.debug('Saving window bounds: $bounds');
}

class _ScreenRetrieverListener extends ScreenListener {
  final WindowManagerHelper _helper;

  _ScreenRetrieverListener(this._helper);

  @override
  void onScreenEvent(String eventName) async {
    _log.debug('Screen event: $eventName');
    _saveWindowBounds(_helper);
  }
}

class _WindowEventListener extends WindowListener {
  final WindowManagerHelper _helper;

  _WindowEventListener(this._helper);

  @override
  void onWindowResize() async {
    _log.debug('Window event: onWindowResize');
    _saveWindowBounds(_helper);
  }

  @override
  void onWindowMoved() async {
    _log.debug('Window event: onWindowMoved');
    _saveWindowBounds(_helper);
  }

  @override
  void onWindowClose() async {
    if (Platform.isMacOS) {
      await windowManager.destroy();
    }
  }
}

Future<Widget> initialize(List<String> argv) async {
  final parser = ArgParser();
  parser.addOption(_logFile);
  parser.addOption(_logLevel);
  parser.addFlag(_hidden);
  parser.addFlag(_shown);
  final args = parser.parse(argv);
  _initLogging(args);

  await windowManager.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final windowManagerHelper = WindowManagerHelper.withPreferences(prefs);
  final isHidden = _getIsHidden(args, prefs);

  _log.info('Window hidden on startup: $isHidden');

  final bounds = Rect.fromLTWH(
    prefs.getDouble(_keyLeft) ?? WindowDefaults.bounds.left,
    prefs.getDouble(_keyTop) ?? WindowDefaults.bounds.top,
    prefs.getDouble(_keyWidth) ?? WindowDefaults.bounds.width,
    prefs.getDouble(_keyHeight) ?? WindowDefaults.bounds.height,
  );

  _log.debug('Using saved window bounds (or defaults): $bounds');

  unawaited(windowManager
      .waitUntilReadyToShow(
          const WindowOptions(minimumSize: WindowDefaults.minSize))
      .then((_) async {
    await windowManagerHelper.setBounds(bounds);

    if (isHidden) {
      await windowManager.setSkipTaskbar(true);
    } else {
      await windowManager.show();
    }
    windowManager.addListener(_WindowEventListener(windowManagerHelper));
    screenRetriever.addListener(_ScreenRetrieverListener(windowManagerHelper));
  }));

  // Either use the _HELPER_PATH environment variable, or look relative to executable.
  var exe = Platform.environment['_HELPER_PATH'];
  if (exe?.isEmpty ?? true) {
    var relativePath = 'helper/authenticator-helper';
    if (Platform.isMacOS) {
      relativePath = '../Resources/$relativePath';
    } else if (Platform.isWindows) {
      relativePath += '.exe';
    }
    exe = Uri.file(Platform.resolvedExecutable)
        .resolve(relativePath)
        .toFilePath();
  }

  // Locate feature flags file
  final featureFile = File(Uri.file(Platform.resolvedExecutable)
      .resolve('features.json')
      .toFilePath());

  final rpcFuture = _initHelper(exe!);
  _initLicenses();

  await localNotifier.setup(
    appName: 'Yubico Authenticator',
    shortcutPolicy: ShortcutPolicy.ignore,
  );

  return ProviderScope(
    overrides: [
      prefProvider.overrideWithValue(prefs),
      rpcProvider.overrideWith((_) => rpcFuture),
      windowStateProvider.overrideWith(
        (ref) => ref.watch(desktopWindowStateProvider),
      ),
      clipboardProvider.overrideWith(
        (ref) => ref.watch(desktopClipboardProvider),
      ),
      supportedThemesProvider.overrideWith(
        (ref) => ref.watch(desktopSupportedThemesProvider),
      ),
      attachedDevicesProvider.overrideWith(
        () => DesktopDevicesNotifier(),
      ),
      currentDeviceProvider.overrideWith(
        () => DesktopCurrentDeviceNotifier(),
      ),
      currentDeviceDataProvider.overrideWith(
        (ref) => ref.watch(desktopDeviceDataProvider),
      ),
      currentSectionProvider.overrideWith(
        (ref) => desktopCurrentSectionNotifier(ref),
      ),
      // OATH
      oathStateProvider.overrideWithProvider(desktopOathState.call),
      credentialListProvider
          .overrideWithProvider(desktopOathCredentialListProvider.call),
      qrScannerProvider.overrideWith(
        (ref) => ref.watch(desktopQrScannerProvider),
      ),
      // Management
      managementStateProvider.overrideWithProvider(desktopManagementState.call),
      // FIDO
      fidoStateProvider.overrideWithProvider(desktopFidoState.call),
      fingerprintProvider.overrideWithProvider(desktopFingerprintProvider.call),
      credentialProvider.overrideWithProvider(desktopCredentialProvider.call),
      // PIV
      pivStateProvider.overrideWithProvider(desktopPivState.call),
      pivSlotsProvider.overrideWithProvider(desktopPivSlots.call),
      // OTP
      otpStateProvider.overrideWithProvider(desktopOtpState.call)
    ],
    child: YubicoAuthenticatorApp(
      page: Consumer(
        builder: ((context, ref, child) {
          // keep RPC log level in sync with app
          ref.listen<Level>(logLevelProvider, (_, level) {
            ref.read(rpcProvider).valueOrNull?.setLogLevel(level);
          });

          // Load feature flags, if they exist
          featureFile.exists().then(
            (exists) async {
              final featureFlag = ref.read(featureFlagProvider.notifier);
              if (exists) {
                try {
                  final featureConfig =
                      jsonDecode(await featureFile.readAsString());
                  featureFlag.loadConfig(featureConfig);
                } catch (error) {
                  _log.error('Failed to parse feature flags', error);
                }
              }
              // Hardcode features here:
              // featureFlag.setFeature(feature, false);
            },
          );

          // Initialize systray
          ref.watch(systrayProvider);

          // Show a loading or error page while the Helper isn't ready
          return Consumer(
              builder: (context, ref, child) => ref.watch(rpcProvider).when(
                    data: (data) => const MainPage(),
                    error: (error, stackTrace) => AppFailurePage(cause: error),
                    loading: () => _HelperWaiter(),
                  ));
        }),
      ),
    ),
  );
}

Future<RpcSession> _initHelper(String exe) async {
  _log.info('Starting Helper subprocess: $exe');
  final rpc = RpcSession(exe);
  await rpc.initialize();
  _log.info('Helper process started');
  await rpc.setLogLevel(Logger.root.level);
  _log.info('Helper log level set');
  return rpc;
}

void _initLogging(ArgResults args) {
  final path = args[_logFile];
  final levelName = args[_logLevel];

  File? file;
  if (path != null) {
    file = File(path);
  }

  Logger.root.onRecord.listen((record) {
    if (file != null) {
      file.writeAsStringSync(
          '${record.time.logFormat} [${record.loggerName}] ${record.level}: ${record.message}${Platform.lineTerminator}',
          mode: FileMode.append);
      if (record.error != null) {
        file.writeAsStringSync('${record.error}${Platform.lineTerminator}',
            mode: FileMode.append);
      }
    }
    stderr.writeln(
        '${record.time.logFormat} [${record.loggerName}] ${record.level}: ${record.message}');
    if (record.error != null) {
      stderr.writeln(record.error);
    }
  });

  if (levelName != null) {
    try {
      Level level = Levels.LEVELS
          .firstWhere((level) => level.name == levelName.toUpperCase());
      Logger.root.level = level;
      _log.info('Log level initialized from command line argument');
    } catch (error) {
      _log.error('Failed to set log level', error);
    }
  }

  _log.info('Logging initialized, outputting to stderr');
}

void _initLicenses() async {
  LicenseRegistry.addLicense(() async* {
    final python =
        await rootBundle.loadString('assets/licenses/raw/python.txt');
    yield LicenseEntryWithLineBreaks(['Python'], python);

    final zxingcpp =
        await rootBundle.loadString('assets/licenses/raw/apache-2.0.txt');
    yield LicenseEntryWithLineBreaks(['zxing-cpp'], zxingcpp);

    final helper = await rootBundle.loadStructuredData<List>(
      'assets/licenses/helper.json',
      (value) async => jsonDecode(value),
    );

    for (final e in helper) {
      yield LicenseEntryWithLineBreaks([e['Name']], e['LicenseText']);
    }
  });
}

bool _getIsHidden(ArgResults args, SharedPreferences prefs) {
  bool isHidden = false;
  if (args[_hidden] || args[_shown]) {
    isHidden = args[_hidden] && !args[_shown];
  }
  prefs.setBool(windowHidden, isHidden);
  return isHidden;
}

class _HelperWaiter extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HelperWaiter> createState() => _HelperWaiterState();
}

class _HelperWaiterState extends ConsumerState<_HelperWaiter> {
  bool slow = false;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      setState(() {
        slow = true;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (slow) {
      final l10n = AppLocalizations.of(context)!;
      return MessagePage(
        centered: true,
        graphic: const CircularProgressIndicator(),
        message: l10n.l_helper_not_responding,
        actionsBuilder: (context, expanded) => [
          ActionChip(
            avatar: const Icon(Symbols.content_copy),
            label: Text(l10n.s_copy_log),
            onPressed: () async {
              _log.info('Copying log to clipboard ($version)...');
              final logs = await ref.read(logLevelProvider.notifier).getLogs();
              var clipboard = ref.read(clipboardProvider);
              await clipboard.setText(logs.join('\n'));
              if (!clipboard.platformGivesFeedback()) {
                await ref.read(withContextProvider)(
                  (context) async {
                    showMessage(
                      context,
                      l10n.l_log_copied,
                    );
                  },
                );
              }
            },
          ),
        ],
      );
    } else {
      return const MessagePage(
        centered: true,
        delayedContent: true,
        graphic: CircularProgressIndicator(),
      );
    }
  }
}
