/*
 * Copyright (C) 2022 Yubico.
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

import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'android/init.dart' as android;
import 'app/app.dart';
import 'app/state.dart';
import 'core/state.dart';
import 'desktop/init.dart' as desktop;
import 'error_page.dart';
import 'ios/yubikit_channel.dart';
import 'version.dart';

final _log = Logger('main');

void main(List<String> argv) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final Widget initializedApp;
    if (isDesktop) {
      initializedApp = await desktop.initialize(argv);
    } else if (isAndroid) {
      initializedApp = await android.initialize();
    } else if (Platform.isIOS) {
      _initializeDebugLogging();
      initializedApp = ProviderScope(
        overrides: [
          prefProvider.overrideWithValue(await SharedPreferences.getInstance()),
          supportedThemesProvider.overrideWith((ref) => ThemeMode.values),
          localeStatusProvider.overrideWithValue(await loadLocaleStatus()),
          currentDeviceDataProvider.overrideWith(
            (ref) => const AsyncValue.loading(),
          ),
        ],
        child: const YubicoAuthenticatorApp(page: _IosPlaceholder()),
      );
    } else {
      _initializeDebugLogging();
      throw UnimplementedError('Platform not supported');
    }
    _log.info('Running Yubico Authenticator...', {
      'app_version': version,
      'dart': Platform.version,
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
    });
    runApp(initializedApp);
  } catch (e) {
    _log.warning('Platform initialization failed: $e');
    runApp(
      ProviderScope(
        overrides: [
          prefProvider.overrideWithValue(await SharedPreferences.getInstance()),
          supportedThemesProvider.overrideWith((ref) => ThemeMode.values),
        ],
        child: YubicoAuthenticatorApp(page: ErrorPage(error: e.toString())),
      ),
    );
  }
}

void _initializeDebugLogging() {
  Logger.root.onRecord.listen((record) {
    developer.log(
      '${record.level}: ${record.message}',
      error: record.error,
      name: record.loggerName,
      time: record.time,
      level: record.level.value,
    );
  });
}

class _IosPlaceholder extends StatefulWidget {
  const _IosPlaceholder();

  @override
  State<_IosPlaceholder> createState() => _IosPlaceholderState();
}

class _IosPlaceholderState extends State<_IosPlaceholder> {
  String _status = 'Press a button to read the YubiKey serial.';
  bool _busy = false;

  Future<void> _readSerial(String via) async {
    debugPrint('[ios placeholder] read serial via $via');
    setState(() {
      _busy = true;
      _status = via == 'usb' ? 'Reading over USB…' : 'Scanning NFC…';
    });
    try {
      final serial = await YubiKitChannel.readSerial(via: via);
      if (!mounted) return;
      setState(() => _status = 'Serial ($via): $serial');
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yubico Authenticator (iOS)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : () => _readSerial('usb'),
              child: const Text('Read YubiKey serial (USB)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : () => _readSerial('nfc'),
              child: const Text('Read YubiKey serial (NFC)'),
            ),
          ],
        ),
      ),
    );
  }
}
