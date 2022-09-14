import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'android/init.dart' as android;
import 'app/app.dart';
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
          prefProvider.overrideWithValue(await SharedPreferences.getInstance())
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
