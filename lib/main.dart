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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'android/init.dart' as android;
import 'app/app.dart';
import 'app/state.dart';
import 'core/state.dart';
import 'desktop/init.dart' as desktop;
import 'error_page.dart';

final _log = Logger('main');

void main(List<String> argv) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final Widget initializedApp;
    if (isDesktop) {
      initializedApp = await desktop.initialize(argv);
    } else if (isAndroid) {
      initializedApp = await android.initialize();
    } else {
      _initializeDebugLogging();
      throw UnimplementedError('Platform not supported');
    }
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
