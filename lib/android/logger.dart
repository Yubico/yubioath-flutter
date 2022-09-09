import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

final _log = Logger('android.logger');

final androidLogProvider =
    StateNotifierProvider<LogLevelNotifier, Level>((ref) => AndroidLogger());

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
