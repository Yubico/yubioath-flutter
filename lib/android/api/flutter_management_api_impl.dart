import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../command_providers.dart';
import 'impl.dart';

class FManagementApiImpl extends FManagementApi {
  final StateNotifierProviderRef _ref;

  FManagementApiImpl(this._ref) : super();

  @override
  Future<void> updateDeviceInfo(String deviceInfoJson) async {
    _ref.read(androidYubikeyProvider.notifier).set(deviceInfoJson);
  }
}
