/*
 * Copyright (C) 2022-2025 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:logging/logging.dart';

import '../app/logging.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../core/models.dart';
import '../management/models.dart';
import 'models.dart';
import 'rpc.dart';
import 'state.dart';

const _pollDelay = Duration(milliseconds: 500);

final _log = Logger('desktop.devices');

final _devicesProvider =
    StateNotifierProvider<DevicesNotifier, List<YubiKeyDeviceNode>>((ref) {
      final notifier = DevicesNotifier(ref.watch(rpcProvider).value);
      ref.listen<WindowState>(windowStateProvider, (_, windowState) {
        notifier._notifyWindowState(windowState);
      }, fireImmediately: true);
      return notifier;
    });

class DevicesNotifier extends StateNotifier<List<YubiKeyDeviceNode>> {
  final RpcSession? _rpc;
  Timer? _pollTimer;
  int _devicesState = -1;
  bool _unaccountedRetry = false;
  DevicesNotifier(this._rpc) : super([]);

  void refresh() {
    _log.debug('Refreshing all devices');
    _devicesState = -1;
    _pollDevices();
  }

  void _notifyWindowState(WindowState windowState) {
    if (windowState.active) {
      _pollDevices();
    } else {
      _pollTimer?.cancel();
      // Release any held device
      _rpc?.command('get', ['devices']);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _pollDevices() async {
    _pollTimer?.cancel();
    final rpc = _rpc;
    if (rpc == null) {
      return;
    }

    try {
      var scan = await rpc.command('scan', ['devices']);

      if (!mounted) {
        return;
      }

      if (_devicesState != scan['state'] || _unaccountedRetry) {
        var devicesResult = await rpc.command('get', ['devices']);
        _log.info('Devices state change', jsonEncode(devicesResult));
        _devicesState = devicesResult['data']['state'];
        final pids = {
          for (var e in ((devicesResult['data']['pids'] as Map?) ?? {}).entries)
            UsbPid.fromValue(int.parse(e.key)): e.value as int,
        };
        List<YubiKeyDeviceNode> devices = [];

        for (String id in (devicesResult['children'] as Map).keys) {
          final path = ['devices', id];
          final deviceResult = await rpc.command('get', path);
          final deviceData = deviceResult['data'];
          final pidValue = deviceData['pid'];
          final pid =
              pidValue != null ? UsbPid.fromValue(pidValue as int) : null;
          final transport = deviceData['transport'] == 'nfc'
              ? Transport.nfc
              : Transport.usb;
          devices.add(
            DeviceNode.yubiKey(
                  DevicePath(path),
                  deviceData['name'],
                  pid,
                  transport,
                  DeviceInfo.fromJson(deviceData['info']),
                )
                as YubiKeyDeviceNode,
          );
          if (transport == Transport.usb && pid != null) {
            pids.update(pid, (value) => value - 1, ifAbsent: () => 0);
          }
        }
        pids.removeWhere((_, value) => value <= 0);

        if (pids.isNotEmpty) {
          pids.forEach((pid, count) {
            for (var i = 0; i < count; i++) {
              devices.add(
                DeviceNode.yubiKey(
                      DevicePath(
                          ['pid', pid.value.toString(), i.toString()]),
                      pid.displayName,
                      pid,
                      Transport.usb,
                      null,
                    )
                    as YubiKeyDeviceNode,
              );
            }
          });
          _unaccountedRetry = !_unaccountedRetry;
        } else {
          _unaccountedRetry = false;
        }

        _log.info('Devices state updated, unaccounted for: $pids');
        if (mounted) {
          state = devices;
        }
      }
    } on RpcError catch (e) {
      _log.error('Error polling devices', jsonEncode(e));
    }

    if (mounted) {
      _pollTimer = Timer(_pollDelay, _pollDevices);
    }
  }
}

class DesktopDevicesNotifier extends AttachedDevicesNotifier {
  @override
  List<DeviceNode> build() {
    final devices = ref.watch(_devicesProvider).toList();
    devices.sort((a, b) => a.name.compareTo(b.name));
    return devices;
  }

  @override
  refresh() {
    ref.read(_devicesProvider.notifier).refresh();
  }
}

final _desktopDeviceDataProvider =
    StateNotifierProvider<CurrentDeviceDataNotifier, AsyncValue<YubiKeyData>>((
      ref,
    ) {
      final notifier = CurrentDeviceDataNotifier(
        ref.watch(rpcProvider).value,
        ref.watch(currentDeviceProvider),
      );
      ref.listen<WindowState>(windowStateProvider, (_, windowState) {
        notifier._notifyWindowState(windowState);
      });
      return notifier;
    });

final desktopDeviceDataProvider = Provider<AsyncValue<YubiKeyData>>((ref) {
  return ref.watch(_desktopDeviceDataProvider);
});

class CurrentDeviceDataNotifier extends StateNotifier<AsyncValue<YubiKeyData>> {
  final RpcSession? _rpc;
  final DeviceNode? _deviceNode;
  StreamSubscription? _flagSubscription;

  CurrentDeviceDataNotifier(this._rpc, this._deviceNode)
    : super(const AsyncValue.loading()) {
    final dev = _deviceNode;
    if (dev is YubiKeyDeviceNode) {
      final info = dev.info;
      if (info != null) {
        state = AsyncValue.data(YubiKeyData(dev, dev.name, info));
      } else {
        state = AsyncValue.error('device-inaccessible', StackTrace.current);
      }
    }
    _flagSubscription = _rpc?.flags.listen((flag) {
      if (flag == 'device_info') {
        _refreshDevice();
      }
    });
  }

  void _refreshDevice() async {
    final node = _deviceNode;
    if (node == null) return;
    var result = await _rpc?.command('get', node.path.segments);
    if (mounted && result != null) {
      final newState = YubiKeyData(
        node,
        result['data']['name'],
        DeviceInfo.fromJson(result['data']['info']),
      );
      if (state.value != newState) {
        _log.info('Configuration change in current device');
        state = AsyncValue.data(newState);
      }
    }
  }

  void _notifyWindowState(WindowState windowState) {
    if (windowState.active) {
      _refreshDevice();
    }
  }

  @override
  void dispose() {
    _flagSubscription?.cancel();
    super.dispose();
  }
}
