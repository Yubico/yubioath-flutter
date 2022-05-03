import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
final isAndroid = Platform.isAndroid;

// This must be initialized before use, in main.dart.
final prefProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

abstract class ApplicationStateNotifier<T>
    extends StateNotifier<AsyncValue<T>> {
  ApplicationStateNotifier() : super(const AsyncValue.loading());

  @protected
  Future<void> updateState(Future<T> Function() guarded) async {
    final result = await AsyncValue.guard(guarded);
    if (mounted) {
      state = result;
    }
  }

  @protected
  void setData(T value) {
    if (mounted) {
      state = AsyncValue.data(value);
    }
  }
}
