import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../app/state.dart';
import 'api/flutter_management_api_impl.dart';
import 'api/flutter_oath_api_impl.dart';
import 'api/impl.dart';
import 'command_providers.dart';

final androidSubPageProvider =
    StateNotifierProvider<CurrentAppNotifier, Application>((ref) {
  FOathApi.setup(FOathApiImpl(ref));
  FManagementApi.setup(FManagementApiImpl(ref));
  return _AndroidSubPageNotifier(ref.watch(supportedAppsProvider));
});

class _AndroidSubPageNotifier extends CurrentAppNotifier {
  final AppApi _api = AppApi();

  _AndroidSubPageNotifier(super.supportedApps) {
    _handleSubPage(state);
  }

  @override
  void setCurrentApp(Application app) {
    super.setCurrentApp(app);
    _handleSubPage(app);
  }

  void _handleSubPage(Application subPage) async {
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
  _AndroidAttachedDevicesNotifier(super.state);
}

final androidDeviceDataProvider =
    Provider<YubiKeyData?>((ref) => ref.watch(androidYubikeyProvider));

final androidCurrentDeviceProvider =
    StateNotifierProvider<CurrentDeviceNotifier, DeviceNode?>((ref) {
  final provider = _AndroidCurrentDeviceNotifier();
  ref.listen(attachedDevicesProvider, provider._updateAttachedDevices);
  return provider;
});

class _AndroidCurrentDeviceNotifier extends CurrentDeviceNotifier {
  _AndroidCurrentDeviceNotifier() : super(null);

  _updateAttachedDevices(
      List<DeviceNode>? previous, List<DeviceNode?> devices) {
    if (devices.isNotEmpty) {
      state = devices.first;
    } else {
      state = null;
    }
  }

  @override
  setCurrentDevice(DeviceNode device) {
    state = device;
  }
}
