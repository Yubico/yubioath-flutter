import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/rpc.dart';
import '../../core/state.dart';

import 'models.dart';

final log = Logger('app.state');

final attachedDevicesProvider =
    StateNotifierProvider<AttachedDeviceNotifier, List<DeviceNode>>(
        (ref) => AttachedDeviceNotifier(ref.watch(rpcProvider)));

class AttachedDeviceNotifier extends StateNotifier<List<DeviceNode>> {
  final RpcSession _rpc;
  late Timer _pollTimer;
  int _usbState = -1;
  AttachedDeviceNotifier(this._rpc) : super([]) {
    _pollTimer = Timer(const Duration(milliseconds: 500), _pollUsb);
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    super.dispose();
  }

  void _pollUsb() async {
    var scan = await _rpc.command('scan', ['usb']);

    if (_usbState != scan['state']) {
      var usbResult = await _rpc.command('get', ['usb']);
      log.info('USB state change', jsonEncode(usbResult));

      _usbState = usbResult['data']['state'];

      List<DeviceNode> devices = [];
      for (String id in (usbResult['children'] as Map).keys) {
        var path = ['usb', id];
        var deviceResult = await _rpc.command('get', path);
        devices
            .add(DeviceNode.fromJson({'path': path, ...deviceResult['data']}));
      }
      if (mounted) {
        state = devices;
      }
    }
    if (mounted) {
      _pollTimer = Timer(const Duration(milliseconds: 500), _pollUsb);
    }
  }
}

final currentDeviceProvider =
    StateNotifierProvider<CurrentDeviceNotifier, DeviceNode?>((ref) {
  final provider = CurrentDeviceNotifier(ref.watch(prefProvider));
  ref.listen(attachedDevicesProvider, provider._updateAttachedDevices);
  return provider;
});

class CurrentDeviceNotifier extends StateNotifier<DeviceNode?> {
  static const String _lastDeviceSerial = 'APP_STATE_LAST_SERIAL';
  final SharedPreferences _prefs;
  CurrentDeviceNotifier(this._prefs) : super(null);

  _updateAttachedDevices(List<DeviceNode>? previous, List<DeviceNode> devices) {
    if (devices.isEmpty) {
      state = null;
    } else if (!devices.contains(state)) {
      // Prefer last selected device
      final serial = _prefs.getInt(_lastDeviceSerial) ?? -1;
      state = devices.firstWhere(
        (element) => element.info.serial == serial,
        orElse: () => devices.first,
      );
    }
  }

  setCurrentDevice(DeviceNode device) {
    state = device;
    final serial = device.info.serial;
    if (serial != null) {
      _prefs.setInt(_lastDeviceSerial, serial);
    }
  }
}

final subPageProvider = StateNotifierProvider<SubPageNotifier, SubPage>(
    (ref) => SubPageNotifier(SubPage.authenticator));

class SubPageNotifier extends StateNotifier<SubPage> {
  SubPageNotifier(SubPage state) : super(state);

  void setSubPage(SubPage page) {
    state = page;
  }
}
