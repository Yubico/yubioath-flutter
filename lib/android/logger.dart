import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class AndroidLogger {
  final _androidLogger = Logger('android.redirect');
  final MethodChannel _channel = const MethodChannel('android.log.redirect');

  final levelMap = <String, Level>{
    't': Level.FINE,
    'd': Level.CONFIG,
    'i': Level.INFO,
    'w': Level.WARNING,
    'e': Level.SEVERE,
    'wtf': Level.SHOUT,
    'v': Level.ALL,
  };

  static AndroidLogger? instance;
  static void initialize() {
    instance = AndroidLogger();
  }

  AndroidLogger() {
    _channel.setMethodCallHandler((call) async {
      var level = call.arguments['level'];
      var message = call.arguments['message'];
      var error = call.arguments['error'];
      _androidLogger.log(levelMap[level] ?? Level.INFO, message, error);
      return 0;
    });
  }
}
