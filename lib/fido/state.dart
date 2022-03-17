import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../core/state.dart';
import 'models.dart';

final fidoStateProvider = StateNotifierProvider.autoDispose
    .family<FidoStateNotifier, ApplicationStateResult<FidoState>, DevicePath>(
  (ref, devicePath) => throw UnimplementedError(),
);

abstract class FidoStateNotifier extends ApplicationStateNotifier<FidoState> {
  Stream<InteractionEvent> reset();
  Future<PinResult> unlock(String pin);
  Future<PinResult> setPin(String newPin, {String? oldPin});
}
