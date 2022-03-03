import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../command_providers.dart';
import 'impl.dart';

final _log = Logger('android.FManagementApiImpl');

class FManagementApiImpl extends FManagementApi {
  final StateNotifierProviderRef _ref;

  FManagementApiImpl(this._ref) : super();

  @override
  Future<void> updateDeviceInfo(String deviceInfoJson) async {
    _log.info('Received: $deviceInfoJson');
    _ref.read(androidYubikeyProvider.notifier).set(deviceInfoJson);
  }
}
