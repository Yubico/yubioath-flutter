import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/state.dart';
import '../oath/menu_actions.dart';
import 'models.dart';

final log = Logger('app.state');

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
final currentDeviceDataProvider = Provider<YubiKeyData?>(
  (ref) => null,
);

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
    (ref) => SubPageNotifier(SubPage.authenticator));

class SubPageNotifier extends StateNotifier<SubPage> {
  SubPageNotifier(SubPage state) : super(state);

  void setSubPage(SubPage page) {
    state = page;
  }
}

final menuActionsProvider = Provider.autoDispose<List<MenuAction>>((ref) {
  switch (ref.watch(subPageProvider)) {
    case SubPage.authenticator:
      return buildOathMenuActions(ref);
    case SubPage.yubikey:
      // TODO: Handle this case.
      break;
  }
  return [];
});

abstract class QrScanner {
  Future<String> scanQr();
}

final qrScannerProvider = Provider<QrScanner?>(
  (ref) => null,
);
