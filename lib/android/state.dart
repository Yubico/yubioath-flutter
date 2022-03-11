import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../app/state.dart';
import 'api/flutter_management_api_impl.dart';
import 'api/flutter_oath_api_impl.dart';
import 'api/impl.dart';
import 'command_providers.dart';

final androidSubPageProvider =
    StateNotifierProvider<SubPageNotifier, SubPage>((ref) {
  FOathApi.setup(FOathApiImpl(ref));
  FManagementApi.setup(FManagementApiImpl(ref));
  return _AndroidSubPageNotifier();
});

class _AndroidSubPageNotifier extends SubPageNotifier {
  final AppApi _api = AppApi();

  _AndroidSubPageNotifier() : super(SubPage.oath) {
    _handleSubPage(SubPage.oath);
  }

  @override
  void setSubPage(SubPage page) {
    super.setSubPage(page);
    _handleSubPage(page);
  }

  void _handleSubPage(SubPage subPage) async {
    await _api.setContext(subPage.index);
  }
}

final androidAttachedDevicesProvider =
    StateNotifierProvider<AttachedDevicesNotifier, List<DeviceNode>>((ref) {
  var currentDeviceData = ref.watch(androidDeviceDataProvider);
  if (currentDeviceData != null) {
    return _AndroidAttachedDevicesNotifier([currentDeviceData.node]);
  }
  return _AndroidAttachedDevicesNotifier([]);
});

class _AndroidAttachedDevicesNotifier extends AttachedDevicesNotifier {
  _AndroidAttachedDevicesNotifier(List<DeviceNode> state) : super(state);
}

final androidDeviceDataProvider =
    Provider<YubiKeyData?>((ref) => ref.watch(androidYubikeyProvider));
