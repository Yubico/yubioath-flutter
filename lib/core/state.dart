import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/models.dart';

final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
final isAndroid = Platform.isAndroid;

// This must be initialized before use, in main.dart.
final prefProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final logLevelProvider = StateNotifierProvider<LogLevelNotifier, Level>(
    (ref) => LogLevelNotifier(Logger.root.level));

class LogLevelNotifier extends StateNotifier<Level> {
  LogLevelNotifier(Level level) : super(level);

  void setLogLevel(Level level) {
    Logger.root.level = level;
    state = level;
  }
}

abstract class ApplicationStateNotifier<T>
    extends StateNotifier<ApplicationStateResult<T>> {
  ApplicationStateNotifier() : super(ApplicationStateResult.none());

  @protected
  T requireState() => state.maybeWhen(
        success: (state) => state,
        orElse: () => throw UnsupportedError('State is not available'),
      );

  @protected
  void setState(T value) {
    if (mounted) {
      state = ApplicationStateResult.success(value);
    }
  }

  @protected
  void setFailure(String reason) {
    if (mounted) {
      state = ApplicationStateResult.failure(reason);
    }
  }

  @protected
  void unsetState() {
    if (mounted) {
      state = ApplicationStateResult.none();
    }
  }
}
