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

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

final _log = Logger('android.logger');

class AndroidLogger extends LogLevelNotifier {
  final MethodChannel _channel = const MethodChannel('android.log.redirect');

  AndroidLogger() : super() {
    Logger.root.onRecord.listen((record) {
      if (record.level >= Logger.root.level) {
        log(record);
      }
    });
    _log.info('Logging initialized, outputting to Android/logcat');
  }

  @override
  void setLogLevel(Level level) {
    super.setLogLevel(level);
    _channel.invokeMethod('setLevel', {
      'level': level.name,
    });
  }

  @override
  Future<List<String>> getLogs() async {
    _log.debug('Getting logs...');
    var buffer = await _channel.invokeMethod('getLogs', {});
    return List.unmodifiable(buffer);
  }

  void log(LogRecord record) {
    final error = record.error == null
        ? null
        : record.error is Exception
            ? record.error.toString()
            : record.error is String
                ? record.error
                : 'Invalid error type: ${record.error.runtimeType.toString()}';
    _channel.invokeMethod('log', {
      'loggerName': record.loggerName,
      'level': record.level.name,
      'message': record.message,
      'error': error
    });
  }
}
