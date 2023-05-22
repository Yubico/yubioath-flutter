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

// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../core/state.dart';
import '../android/state.dart';

String _pad(int value, int zeroes) => value.toString().padLeft(zeroes, '0');

extension DateTimeFormat on DateTime {
  String get logFormat =>
      '${_pad(hour, 2)}:${_pad(minute, 2)}:${_pad(second, 2)}.${_pad(millisecond, 3)}';
}

class Levels {
  /// Key for tracing information ([value] = 500).
  static const Level TRAFFIC = Level('TRAFFIC', 500);

  /// Key for static configuration messages ([value] = 700).
  static const Level DEBUG = Level('DEBUG', 700);

  /// Key for informational messages ([value] = 800).
  static const Level INFO = Level.INFO;

  /// Key for potential problems ([value] = 900).
  static const Level WARNING = Level.WARNING;

  /// Key for serious failures ([value] = 1000).
  static const Level ERROR = Level('ERROR', 1000);

  static const List<Level> LEVELS = [
    TRAFFIC,
    DEBUG,
    INFO,
    WARNING,
    ERROR,
  ];
}

extension LoggerExt on Logger {
  void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Levels.ERROR, message, error, stackTrace);
  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Levels.DEBUG, message, error, stackTrace);
  void traffic(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Levels.TRAFFIC, message, error, stackTrace);
}

final logLevelProvider =
    StateNotifierProvider<LogLevelNotifier, Level>((ref) => LogLevelNotifier());

class LogLevelNotifier extends StateNotifier<Level> {
  final List<String> _buffer = [];
  LogLevelNotifier() : super(Logger.root.level) {
    Logger.root.onRecord.listen((record) {
      _buffer.add(
          '${record.time.logFormat} [${record.loggerName}] ${record.level}: ${record.message}');
      if (record.error != null) {
        _buffer.add('${record.error}');
      }
      while (_buffer.length > 1000) {
        _buffer.removeAt(0);
      }
    });
  }

  void setLogLevel(Level level) {
    state = level;
    Logger.root.level = level;
  }

  Future<List<String>> getLogs() async {
    return List.unmodifiable(_buffer);
  }
}

class LogWarningOverlay extends StatelessWidget {
  final Widget child;

  const LogWarningOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Consumer(builder: (context, ref, _) {
          final sensitiveLogs = ref.watch(logLevelProvider
              .select((level) => level.value <= Level.CONFIG.value));
          final allowScreenshots =
              isAndroid ? ref.watch(androidAllowScreenshotsProvider) : false;

          if (!(sensitiveLogs || allowScreenshots)) {
            return const SizedBox();
          }

          final String message;
          if (sensitiveLogs && allowScreenshots) {
            message =
                'Potentially sensitive data is being logged, and other apps can potentially record the screen';
          } else if (sensitiveLogs) {
            message = 'Potentially sensitive data is being logged';
          } else if (allowScreenshots) {
            message = 'Other apps can potentially record the screen';
          } else {
            return const SizedBox();
          }

          var mediaQueryData =
              MediaQueryData.fromView(WidgetsBinding.instance.window);
          var bottomPadding = mediaQueryData.systemGestureInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(5, 0, 5, bottomPadding),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Text(
                  'WARNING: $message!',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      fontSize: 16),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
