import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../core/models.dart';
import '../core/state.dart';
import '../core/rpc.dart';
import '../oath/menu_actions.dart';
import 'models.dart';

const _usbPollDelay = Duration(milliseconds: 500);

const _nfcPollDelay = Duration(milliseconds: 2500);
const _nfcAttachPollDelay = Duration(seconds: 1);
const _nfcDetachPollDelay = Duration(seconds: 5);

final log = Logger('app.state');

final windowStateProvider =
    StateNotifierProvider<WindowStateNotifier, WindowState>(
        (ref) => WindowStateNotifier());

class WindowStateNotifier extends StateNotifier<WindowState>
    with WindowListener {
  Timer? _idleTimer;
  WindowStateNotifier()
      : super(WindowState(focused: true, visible: true, active: true)) {
    _init();
  }

  void _init() async {
    windowManager.addListener(this);
    if (!await windowManager.isVisible() && mounted) {
      state = WindowState(focused: false, visible: false, active: true);
      _idleTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          state = state.copyWith(active: false);
        }
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  set state(WindowState value) {
    log.config('Window state changed: $value');
    super.state = value;
  }

  @override
  void onWindowEvent(String eventName) {
    if (mounted) {
      switch (eventName) {
        case 'blur':
          state = state.copyWith(focused: false);
          _idleTimer?.cancel();
          _idleTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) {
              state = state.copyWith(active: false);
            }
          });
          break;
        case 'focus':
          state = state.copyWith(focused: true, active: true);
          _idleTimer?.cancel();
          break;
        case 'minimize':
          state = state.copyWith(visible: false, active: false);
          _idleTimer?.cancel();
          break;
        case 'restore':
          state = state.copyWith(visible: true, active: true);
          break;
        default:
          log.fine('Window event ignored: $eventName');
      }
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
    (ref) => ThemeModeNotifier(ref.watch(prefProvider)));

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'APP_STATE_THEME';
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs) : super(_fromName(_prefs.getString(_key)));

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setString(_key, mode.name);
  }

  static ThemeMode _fromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, String>((ref) => SearchNotifier());

class SearchNotifier extends StateNotifier<String> {
  SearchNotifier() : super('');

  setFilter(String value) {
    state = value;
  }
}

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

      if (_usbState != scan['state'] || state.length != scan['pids'].length) {
        var usbResult = await _rpc.command('get', ['usb']);
        log.info('USB state change', jsonEncode(usbResult));
        _usbState = usbResult['data']['state'];
        List<UsbYubiKeyNode> usbDevices = [];

        for (String id in (usbResult['children'] as Map).keys) {
          var path = ['usb', id];
          var deviceResult = await _rpc.command('get', path);
          var deviceData = deviceResult['data'];
          usbDevices.add(DeviceNode.usbYubiKey(
            path,
            deviceData['name'],
            deviceData['pid'],
            DeviceInfo.fromJson(deviceData['info']),
          ) as UsbYubiKeyNode);
        }

        log.info('USB state updated');
        if (mounted) {
          state = usbDevices;
        }
      }
    } on RpcError catch (e) {
      log.severe('Error polling USB', jsonEncode(e));
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
        log.info('NFC state change', jsonEncode(children));
        _nfcState = newState;
        state = children.entries
            .map((e) =>
                DeviceNode.nfcReader(['nfc', e.key], e.value['name'] as String)
                    as NfcReaderNode)
            .toList();
      }
    } on RpcError catch (e) {
      log.severe('Error polling NFC', jsonEncode(e));
    }

    if (mounted) {
      _pollTimer = Timer(_nfcPollDelay, _pollReaders);
    }
  }
}

final attachedDevicesProvider = Provider<List<DeviceNode>>((ref) {
  final usbDevices = ref.watch(_usbDevicesProvider).toList();
  final nfcDevices = ref.watch(_nfcDevicesProvider).toList();
  usbDevices.sort((a, b) => a.name.compareTo(b.name));
  nfcDevices.sort((a, b) => a.name.compareTo(b.name));
  return [...usbDevices, ...nfcDevices];
});

final currentDeviceProvider =
    StateNotifierProvider<CurrentDeviceNotifier, DeviceNode?>((ref) {
  final provider = CurrentDeviceNotifier(ref.watch(prefProvider));
  ref.listen(attachedDevicesProvider, provider._updateAttachedDevices);
  return provider;
});

class CurrentDeviceNotifier extends StateNotifier<DeviceNode?> {
  static const String _lastDevice = 'APP_STATE_LAST_DEVICE';
  final SharedPreferences _prefs;
  CurrentDeviceNotifier(this._prefs) : super(null);

  _updateAttachedDevices(List<DeviceNode>? previous, List<DeviceNode> devices) {
    if (!devices.contains(state)) {
      final lastDevice = _prefs.getString(_lastDevice) ?? '';
      try {
        state = devices.firstWhere(
            (dev) => dev.when(
                  usbYubiKey: (path, name, pid, info) =>
                      lastDevice == 'serial:${info.serial}',
                  nfcReader: (path, name) => lastDevice == 'name:$name',
                ),
            orElse: () => devices.whereType<UsbYubiKeyNode>().first);
      } on StateError {
        state = null;
      }
    }
  }

  setCurrentDevice(DeviceNode device) {
    state = device;
    device.when(
      usbYubiKey: (path, name, pid, info) {
        final serial = info.serial;
        if (serial != null) {
          _prefs.setString(_lastDevice, 'serial:$serial');
        }
      },
      nfcReader: (path, name) {
        _prefs.setString(_lastDevice, 'name:$name');
      },
    );
  }
}

final currentDeviceDataProvider =
    StateNotifierProvider<CurrentDeviceDataNotifier, YubiKeyData?>((ref) {
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

class CurrentDeviceDataNotifier extends StateNotifier<YubiKeyData?> {
  final RpcSession _rpc;
  final DeviceNode? _deviceNode;
  Timer? _pollTimer;

  CurrentDeviceDataNotifier(this._rpc, this._deviceNode) : super(null) {
    final dev = _deviceNode;
    if (dev is UsbYubiKeyNode) {
      state = YubiKeyData(dev, dev.name, dev.info);
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
      var result = await _rpc.command('get', node.path);
      if (mounted) {
        if (result['data']['present']) {
          state = YubiKeyData(node, result['data']['name'],
              DeviceInfo.fromJson(result['data']['info']));
        } else {
          state = null;
        }
      }
    } on RpcError catch (e) {
      log.severe('Error polling NFC', jsonEncode(e));
    }
    if (mounted) {
      _pollTimer = Timer(
          state == null ? _nfcAttachPollDelay : _nfcDetachPollDelay,
          _pollReader);
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

typedef BuildActions = List<MenuAction> Function(BuildContext);

final menuActionsProvider = Provider.autoDispose<BuildActions>((ref) {
  switch (ref.watch(subPageProvider)) {
    case SubPage.authenticator:
      return (context) => buildOathMenuActions(context, ref);
    case SubPage.yubikey:
      // TODO: Handle this case.
      break;
  }
  return (_) => [];
});
