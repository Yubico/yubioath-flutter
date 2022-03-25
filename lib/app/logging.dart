import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

extension LoggerExt on Logger {
  void critical(Object? message, [Object? error, StackTrace? stackTrace]) =>
      shout(message, error, stackTrace);
  void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
      severe(message, error, stackTrace);
  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
      config(message, error, stackTrace);
  void traffic(Object? message, [Object? error, StackTrace? stackTrace]) =>
      fine(message, error, stackTrace);
}

List<String> initLogBuffer(int maxSize) {
  final List<String> _buffer = [];
  Logger.root.onRecord.listen((record) {
    _buffer.add('[${record.loggerName}] ${record.level}: ${record.message}');
    if (record.error != null) {
      _buffer.add('${record.error}');
    }
    while (_buffer.length > maxSize) {
      _buffer.removeAt(0);
    }
  });
  return _buffer;
}

class LogBuffer extends InheritedWidget {
  final List<String> _buffer;
  const LogBuffer(this._buffer, {required Widget child, Key? key})
      : super(child: child, key: key);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  static LogBuffer of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<LogBuffer>();
    assert(result != null, 'No LogBuffer found in context');
    return result!;
  }

  List<String> getLogs() {
    return List.unmodifiable(_buffer);
  }
}
