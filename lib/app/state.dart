import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../core/models.dart';
import '../core/state.dart';
import '../core/rpc.dart';
import '../oath/menu_actions.dart';
import 'models.dart';

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

final attachedDevicesProvider =
    StateNotifierProvider<AttachedDeviceNotifier, List<DeviceNode>>((ref) {
  final notifier = AttachedDeviceNotifier(ref.watch(rpcProvider));
  ref.listen<WindowState>(windowStateProvider, (_, windowState) {
    notifier._notifyWindowState(windowState);
  }, fireImmediately: true);
  return notifier;
});

class AttachedDeviceNotifier extends StateNotifier<List<DeviceNode>> {
  final RpcSession _rpc;
  Timer? _pollTimer;
  int _usbState = -1;
  AttachedDeviceNotifier(this._rpc) : super([]);

  void _notifyWindowState(WindowState windowState) {
    if (windowState.active) {
      _pollUsb();
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

  void _pollUsb() async {
    _pollTimer?.cancel();
    try {
      var scan = await _rpc.command('scan', ['usb']);

      if (_usbState != scan['state'] || state.length != scan['pids'].length) {
        var usbResult = await _rpc.command('get', ['usb']);
        log.info('USB state change', jsonEncode(usbResult));

        List<DeviceNode> devices = [];
        for (String id in (usbResult['children'] as Map).keys) {
          var path = ['usb', id];
          var deviceResult = await _rpc.command('get', path);
          devices.add(
              DeviceNode.fromJson({'path': path, ...deviceResult['data']}));
        }
        _usbState = usbResult['data']['state'];
        log.info('USB state updated');
        if (mounted) {
          state = devices;
        }
      }
    } on RpcError catch (e) {
      log.severe('Error polling USB', jsonEncode(e));
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

final sortedDevicesProvider = Provider<List<DeviceNode>>((ref) {
  final devices = ref.watch(attachedDevicesProvider).toList();
  devices.sort((a, b) => a.name.compareTo(b.name));
  final device = ref.watch(currentDeviceProvider);
  if (device != null) {
    return [device, ...devices.where((e) => e != device)];
  }
  return devices;
});

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
