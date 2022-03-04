import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../core/models.dart';
import '../core/state.dart';
import '../oath/menu_actions.dart';
import 'models.dart';

final _log = Logger('app.state');

// Default implementation is always focused, override with platform specific version.
final windowStateProvider = Provider<WindowState>(
  (ref) => WindowState(focused: true, visible: true, active: true),
);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
    (ref) => ThemeModeNotifier(ref.watch(prefProvider)));

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'APP_STATE_THEME';
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs) : super(_fromName(_prefs.getString(_key)));

  void setThemeMode(ThemeMode mode) {
    _log.config('Set theme to $mode');
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

// Override with platform implementation
final attachedDevicesProvider = Provider<List<DeviceNode>>(
  (ref) => [],
);

// Override with platform implementation
final currentDeviceDataProvider =
    StateNotifierProvider<DeviceDataNotifier, YubiKeyData?>(
  (ref) => throw UnimplementedError(),
);

abstract class DeviceDataNotifier extends StateNotifier<YubiKeyData?> {
  DeviceDataNotifier(YubiKeyData? state) : super(state);

  void updateDeviceConfig(DeviceConfig config);
}

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

final subPageProvider = StateNotifierProvider<SubPageNotifier, SubPage>(
    (ref) => SubPageNotifier(SubPage.oath));

class SubPageNotifier extends StateNotifier<SubPage> {
  SubPageNotifier(SubPage state) : super(state);

  void setSubPage(SubPage page) {
    state = page;
  }
}

final currentCapabilitiesProvider = Provider<Pair<int, int>>(
  (ref) {
    final data = ref.watch(currentDeviceDataProvider);
    if (data != null) {
      final transport = data.node.map(
        usbYubiKey: (_) => Transport.usb,
        nfcReader: (_) => Transport.nfc,
      );
      return Pair(
        data.info.supportedCapabilities[transport] ?? 0,
        data.info.config.enabledCapabilities[transport] ?? 0,
      );
    }
    return Pair(0, 0);
  },
);

final menuActionsProvider = Provider.autoDispose<List<MenuAction>>((ref) {
  switch (ref.watch(subPageProvider)) {
    case SubPage.oath:
      return buildOathMenuActions(ref);
    // TODO: Handle other cases.
    default:
      return [];
  }
});

abstract class QrScanner {
  Future<String> scanQr();
}

final qrScannerProvider = Provider<QrScanner?>(
  (ref) => null,
);
