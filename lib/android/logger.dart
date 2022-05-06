import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../app/logging.dart';

class AndroidLogger {
  final _androidLogger = Logger('android.redirect');
  final MethodChannel _channel = const MethodChannel('android.log.redirect');

  static AndroidLogger? instance;
  static void initialize() {
    instance = AndroidLogger();
  }

  AndroidLogger() {
    _channel.setMethodCallHandler((call) async {
      var level = call.arguments['level'];
      var message = call.arguments['message'];
      var error = call.arguments['error'];

      switch (level) {
        case 't':
        case 'v':
          _androidLogger.traffic(message, error);
          break;
        case 'd':
          _androidLogger.debug(message, error);
          break;
        case 'w':
          _androidLogger.warning(message, error);
          break;
        case 'e':
        case 'wtf':
          _androidLogger.error(message, error);
          break;
        case 'i':
        default:
          _androidLogger.info(message, error);
          break;
      }

      return 0;
    });
  }
}
