import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('android.logger');

class AndroidLogger {
  final MethodChannel _channel = const MethodChannel('android.log.redirect');

  AndroidLogger() {
    Logger.root.onRecord.listen((record) {
      if (record.level >= Logger.root.level) {
        log(record);
      }
    });
    _log.info('Logging initialized, outputting to Android/logcat');
  }

  void setLogLevel(Level level) async {
    await _channel.invokeMethod('setLevel', {
      'level': level.value,
    });
  }

  void log(LogRecord record) async {
    await _channel.invokeMethod('log', {
      'loggerName': record.loggerName,
      'level': record.level.value,
      'message': record.message,
      'error': record.error
    });
  }
}
