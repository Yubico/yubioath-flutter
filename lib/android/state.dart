import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../app/state.dart';
import 'devices.dart';

const _contextChannel =
    MethodChannel('com.yubico.authenticator.channel.appContext');

final androidSubPageProvider =
    StateNotifierProvider<CurrentAppNotifier, Application>((ref) {
  return _AndroidSubPageNotifier(ref.watch(supportedAppsProvider));
});

class _AndroidSubPageNotifier extends CurrentAppNotifier {
  _AndroidSubPageNotifier(super.supportedApps) {
    _handleSubPage(state);
  }

  @override
  void setCurrentApp(Application app) {
    super.setCurrentApp(app);
    _handleSubPage(app);
  }

  void _handleSubPage(Application subPage) async {
    await _contextChannel.invokeMethod('setContext', {'index': subPage.index});
  }
}

final androidAttachedDevicesProvider =
    StateNotifierProvider<AttachedDevicesNotifier, List<DeviceNode>>((ref) {
  var currentDeviceData = ref.watch(androidDeviceDataProvider);
  List<DeviceNode> devs = currentDeviceData.maybeWhen(
      data: (data) => [data.node], orElse: () => []);
  return _AndroidAttachedDevicesNotifier(devs);
});

class _AndroidAttachedDevicesNotifier extends AttachedDevicesNotifier {
  _AndroidAttachedDevicesNotifier(super.state);
}

final androidDeviceDataProvider = Provider<AsyncValue<YubiKeyData>>(
    (ref) => ref.watch(androidYubikeyProvider));

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
  setCurrentDevice(DeviceNode? device) {
    state = device;
  }
}
