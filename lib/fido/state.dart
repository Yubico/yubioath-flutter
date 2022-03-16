import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'models.dart';

final fidoStateProvider = StateNotifierProvider.autoDispose
    .family<FidoStateNotifier, ApplicationStateResult<FidoState>, DevicePath>(
  (ref, devicePath) => throw UnimplementedError(),
);

abstract class FidoStateNotifier extends ApplicationStateNotifier<FidoState> {
  Future<void> reset();
  Future<void> unlock(String pin);
  Future<void> setPin(String newPin, {String? oldPin});
}
