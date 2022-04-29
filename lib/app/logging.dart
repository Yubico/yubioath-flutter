import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final logLevelProvider =
    StateNotifierProvider<LogLevelNotifier, Level>((ref) => LogLevelNotifier());

class LogLevelNotifier extends StateNotifier<Level> {
  final List<String> _buffer = [];
  LogLevelNotifier() : super(Logger.root.level) {
    Logger.root.onRecord.listen((record) {
      _buffer.add('[${record.loggerName}] ${record.level}: ${record.message}');
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

  List<String> getLogs() {
    return List.unmodifiable(_buffer);
  }
}

class LogWarningOverlay extends StatelessWidget {
  final Widget child;

  const LogWarningOverlay({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Consumer(builder: (context, ref, _) {
          if (ref.watch(logLevelProvider
              .select((level) => level.value <= Level.CONFIG.value))) {
            return const Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Text(
                  'WARNING: Potentially sensitive data is being logged!',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        }),
      ],
    );
  }
}
