import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../app/state.dart';
import '../core/state.dart';
import '../app/models.dart';
import 'models.dart';
import 'rpc.dart';

final _log = Logger('state');

// This must be initialized before use in initialize.dart.
final rpcProvider = Provider<RpcSession>((ref) {
  throw UnimplementedError();
});

final rpcStateProvider = StateNotifierProvider<_RpcStateNotifier, RpcState>(
  (ref) => _RpcStateNotifier(ref.watch(rpcProvider)),
);

class _RpcStateNotifier extends StateNotifier<RpcState> {
  final RpcSession rpc;
  _RpcStateNotifier(this.rpc) : super(const RpcState('unknown', false)) {
    _init();
  }

  _init() async {
    final response = await rpc.command('get', []);
    if (mounted) {
      state = RpcState.fromJson(response['data']);
    }
  }
}

final _windowStateProvider =
    StateNotifierProvider<_WindowStateNotifier, WindowState>(
        (ref) => _WindowStateNotifier());

final desktopWindowStateProvider = Provider<WindowState>(
  (ref) => ref.watch(_windowStateProvider),
);

class _WindowStateNotifier extends StateNotifier<WindowState>
    with WindowListener {
  Timer? _idleTimer;
  _WindowStateNotifier()
      : super(WindowState(focused: true, visible: true, active: true)) {
    _init();
  }

  void _init() async {
    windowManager.addListener(this);
    // isFocused is not supported on Linux, assume focused
    if (!Platform.isLinux) {
      _idleTimer = Timer(const Duration(seconds: 5), () async {
        final focused = await windowManager.isFocused();
        if (mounted && !focused) {
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
    _log.debug('Window state changed: $value');
    super.state = value;
  }

  @override
  void onWindowEvent(String eventName) {
    if (mounted) {
      switch (eventName) {
        case 'blur':
          state = state.copyWith(focused: false);
          _idleTimer?.cancel();
          _idleTimer = Timer(const Duration(seconds: 5), () async {
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
          _idleTimer?.cancel();
          break;
        default:
          _log.traffic('Window event ignored: $eventName');
      }
    }
  }
}

final desktopCurrentDeviceProvider =
    StateNotifierProvider<CurrentDeviceNotifier, DeviceNode?>((ref) {
  final provider = _DesktopCurrentDeviceNotifier(ref.watch(prefProvider));
  ref.listen(attachedDevicesProvider, provider._updateAttachedDevices);
  return provider;
});

class _DesktopCurrentDeviceNotifier extends CurrentDeviceNotifier {
  static const String _lastDevice = 'APP_STATE_LAST_DEVICE';
  final SharedPreferences _prefs;
  _DesktopCurrentDeviceNotifier(this._prefs) : super(null);

  _updateAttachedDevices(List<DeviceNode>? previous, List<DeviceNode> devices) {
    if (!devices.contains(state)) {
      final lastDevice = _prefs.getString(_lastDevice) ?? '';
      try {
        state = devices.firstWhere((dev) => dev.path.key == lastDevice,
            orElse: () => devices.whereType<UsbYubiKeyNode>().first);
      } on StateError {
        state = null;
      }
    }
  }

  @override
  setCurrentDevice(DeviceNode? device) {
    state = device;
    _prefs.setString(_lastDevice, device?.path.key ?? '');
  }
}
