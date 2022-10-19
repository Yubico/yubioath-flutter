/*
 * Copyright (C) 2022 Yubico.
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
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../core/models.dart';
import '../management/models.dart';
import 'models.dart';
import 'rpc.dart';
import 'state.dart';

const _usbPollDelay = Duration(milliseconds: 500);

const _nfcPollDelay = Duration(milliseconds: 2500);
const _nfcAttachPollDelay = Duration(seconds: 1);
const _nfcDetachPollDelay = Duration(seconds: 5);

final _log = Logger('desktop.devices');

final _usbDevicesProvider =
    StateNotifierProvider<UsbDeviceNotifier, List<UsbYubiKeyNode>>((ref) {
  final notifier = UsbDeviceNotifier(ref.watch(rpcProvider));
  ref.listen<WindowState>(windowStateProvider, (_, windowState) {
    notifier._notifyWindowState(windowState);
  }, fireImmediately: true);
  return notifier;
});

class UsbDeviceNotifier extends StateNotifier<List<UsbYubiKeyNode>> {
  final RpcSession _rpc;
  Timer? _pollTimer;
  int _usbState = -1;
  UsbDeviceNotifier(this._rpc) : super([]);

  void refresh() {
    _log.debug('Refreshing all USB devices');
    _usbState = -1;
    _pollDevices();
  }

  void _notifyWindowState(WindowState windowState) {
    if (windowState.active) {
      _pollDevices();
    } else {
      _pollTimer?.cancel();
      // Release any held device
      _rpc.command('get', ['usb']);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _pollDevices() async {
    _pollTimer?.cancel();

    try {
      var scan = await _rpc.command('scan', ['usb']);
      final pids = {
        for (var e in (scan['pids'] as Map).entries)
          UsbPid.fromValue(int.parse(e.key)): e.value as int
      };
      final numDevices = pids.values.fold<int>(0, (a, b) => a + b);
      if (_usbState != scan['state'] || state.length != numDevices) {
        var usbResult = await _rpc.command('get', ['usb']);
        _log.info('USB state change', jsonEncode(usbResult));
        _usbState = usbResult['data']['state'];
        List<UsbYubiKeyNode> usbDevices = [];

        for (String id in (usbResult['children'] as Map).keys) {
          final path = ['usb', id];
          final deviceResult = await _rpc.command('get', path);
          final deviceData = deviceResult['data'];
          final pid = UsbPid.fromValue(deviceData['pid'] as int);
          usbDevices.add(DeviceNode.usbYubiKey(
            DevicePath(path),
            deviceData['name'],
            pid,
            DeviceInfo.fromJson(deviceData['info']),
          ) as UsbYubiKeyNode);
          pids.update(pid, (value) => value - 1);
        }
        pids.removeWhere((_, value) => value == 0);

        if (pids.isNotEmpty) {
          pids.forEach((pid, count) {
            for (var i = 0; i < count; i++) {
              usbDevices.add(DeviceNode.usbYubiKey(
                  DevicePath(['invalid', '$pid-$i']),
                  pid.displayName,
                  pid,
                  null) as UsbYubiKeyNode);
            }
          });
        }

        _log.info('USB state updated, unaccounted for: $pids');
        if (mounted) {
          state = usbDevices;
        }
      }
    } on RpcError catch (e) {
      _log.error('Error polling USB', jsonEncode(e));
    }

    if (mounted) {
      _pollTimer = Timer(_usbPollDelay, _pollDevices);
    }
  }
}

final _nfcDevicesProvider =
    StateNotifierProvider<NfcDeviceNotifier, List<NfcReaderNode>>((ref) {
  final notifier = NfcDeviceNotifier(ref.watch(rpcProvider));
  ref.listen<WindowState>(windowStateProvider, (_, windowState) {
    notifier._notifyWindowState(windowState);
  }, fireImmediately: true);
  return notifier;
});

class NfcDeviceNotifier extends StateNotifier<List<NfcReaderNode>> {
  final RpcSession _rpc;
  Timer? _pollTimer;
  String _nfcState = '';
  NfcDeviceNotifier(this._rpc) : super([]);

  void _notifyWindowState(WindowState windowState) {
    if (windowState.active) {
      _pollReaders();
    } else {
      _pollTimer?.cancel();
      // Release any held device
      _rpc.command('get', ['nfc']);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _pollReaders() async {
    _pollTimer?.cancel();

    try {
      var children = await _rpc.command('scan', ['nfc']);
      var newState = children.keys.join(':');

      if (mounted && newState != _nfcState) {
        _log.info('NFC state change', jsonEncode(children));
        _nfcState = newState;
        state = children.entries
            .map((e) => DeviceNode.nfcReader(
                    DevicePath(['nfc', e.key]), e.value['name'] as String)
                as NfcReaderNode)
            .toList();
      }
    } on RpcError catch (e) {
      _log.error('Error polling NFC', jsonEncode(e));
    }

    if (mounted) {
      _pollTimer = Timer(_nfcPollDelay, _pollReaders);
    }
  }
}

final desktopDevicesProvider =
    StateNotifierProvider<AttachedDevicesNotifier, List<DeviceNode>>((ref) {
  final usbDevices = ref.watch(_usbDevicesProvider).toList();
  final nfcDevices = ref.watch(_nfcDevicesProvider).toList();
  usbDevices.sort((a, b) => a.name.compareTo(b.name));
  nfcDevices.sort((a, b) => a.name.compareTo(b.name));
  return _DesktopDevicesNotifier(ref, [...usbDevices, ...nfcDevices]);
});

class _DesktopDevicesNotifier extends AttachedDevicesNotifier {
  final Ref _ref;
  _DesktopDevicesNotifier(this._ref, List<DeviceNode> state) : super(state);

  @override
  refresh() {
    _ref.read(_usbDevicesProvider.notifier).refresh();
  }
}

final _desktopDeviceDataProvider =
    StateNotifierProvider<CurrentDeviceDataNotifier, AsyncValue<YubiKeyData>>(
        (ref) {
  final notifier = CurrentDeviceDataNotifier(
    ref.watch(rpcProvider),
    ref.watch(currentDeviceProvider),
  );
  if (notifier._deviceNode is NfcReaderNode) {
    // If this is an NFC reader, listen on WindowState.
    ref.listen<WindowState>(windowStateProvider, (_, windowState) {
      notifier._notifyWindowState(windowState);
    }, fireImmediately: true);
  }
  return notifier;
});

final desktopDeviceDataProvider = Provider<AsyncValue<YubiKeyData>>(
  (ref) {
    return ref.watch(_desktopDeviceDataProvider);
  },
);

class CurrentDeviceDataNotifier extends StateNotifier<AsyncValue<YubiKeyData>> {
  final RpcSession _rpc;
  final DeviceNode? _deviceNode;
  Timer? _pollTimer;

  CurrentDeviceDataNotifier(this._rpc, this._deviceNode)
      : super(const AsyncValue.loading()) {
    final dev = _deviceNode;
    if (dev is UsbYubiKeyNode) {
      final info = dev.info;
      if (info != null) {
        state = AsyncValue.data(YubiKeyData(dev, dev.name, info));
      } else {
        state = AsyncValue.error('device-inaccessible', StackTrace.current);
      }
    }
  }

  void _notifyWindowState(WindowState windowState) {
    if (windowState.active) {
      _pollReader();
    } else {
      _pollTimer?.cancel();
      // TODO: Should we clear the key here?
      /*if (mounted) {
        state = null;
      }*/
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _pollReader() async {
    _pollTimer?.cancel();
    final node = _deviceNode!;
    try {
      _log.debug('Polling for USB device changes...');
      var result = await _rpc.command('get', node.path.segments);
      if (mounted) {
        if (result['data']['present']) {
          state = AsyncValue.data(YubiKeyData(node, result['data']['name'],
              DeviceInfo.fromJson(result['data']['info'])));
        } else {
          state = AsyncValue.error(result['data']['status'], StackTrace.current);
        }
      }
    } on RpcError catch (e) {
      _log.error('Error polling NFC', jsonEncode(e));
    }
    if (mounted) {
      _pollTimer = Timer(
          state is AsyncData ? _nfcDetachPollDelay : _nfcAttachPollDelay,
          _pollReader);
    }
  }
}
