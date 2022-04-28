import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/state.dart';
import 'models.dart';

final _log = Logger('app.state');

// Override this to alter the set of supported apps.
final supportedAppsProvider =
    Provider<List<Application>>((ref) => Application.values);

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

// Override with platform implementation
final attachedDevicesProvider =
    StateNotifierProvider<AttachedDevicesNotifier, List<DeviceNode>>(
  (ref) => AttachedDevicesNotifier([]),
);

class AttachedDevicesNotifier extends StateNotifier<List<DeviceNode>> {
  AttachedDevicesNotifier(List<DeviceNode> state) : super(state);

  /// Force a refresh of all device data.
  void refresh() {}
}

// Override with platform implementation
final currentDeviceDataProvider = Provider<YubiKeyData?>(
  (ref) => throw UnimplementedError(),
);

// Override with platform implementation
final currentDeviceProvider =
    StateNotifierProvider<CurrentDeviceNotifier, DeviceNode?>(
        (ref) => throw UnimplementedError());

abstract class CurrentDeviceNotifier extends StateNotifier<DeviceNode?> {
  CurrentDeviceNotifier(DeviceNode? state) : super(state);
  setCurrentDevice(DeviceNode device);
}

final currentAppProvider =
    StateNotifierProvider<CurrentAppNotifier, Application>((ref) {
  final notifier = CurrentAppNotifier(ref.watch(supportedAppsProvider));
  ref.listen<YubiKeyData?>(currentDeviceDataProvider, (_, data) {
    notifier._notifyDeviceChanged(data);
  }, fireImmediately: true);
  return notifier;
});

class CurrentAppNotifier extends StateNotifier<Application> {
  final List<Application> _supportedApps;
  CurrentAppNotifier(this._supportedApps) : super(_supportedApps.first);

  void setCurrentApp(Application app) {
    state = app;
  }

  void _notifyDeviceChanged(YubiKeyData? data) {
    if (data == null ||
        state.getAvailability(data) != Availability.unsupported) {
      // Keep current app
      return;
    }

    state = _supportedApps.firstWhere(
      (app) => app.getAvailability(data) == Availability.enabled,
      orElse: () => _supportedApps.first,
    );
  }
}

abstract class QrScanner {
  Future<String> scanQr([String? imageData]);
}

final qrScannerProvider = Provider<QrScanner?>(
  (ref) => null,
);

final contextProvider =
    StateNotifierProvider<ContextProvider, Function(BuildContext)?>(
        (ref) => ContextProvider());

typedef WithContext = Future<T> Function<T>(
    Future<T> Function(BuildContext context) action);

class ContextProvider extends StateNotifier<Function(BuildContext)?> {
  ContextProvider() : super(null);

  Future<T> withContext<T>(Future<T> Function(BuildContext context) action) {
    final completer = Completer<T>();
    if (mounted) {
      state = (context) async {
        completer.complete(await action(context));
      };
    } else {
      completer.completeError('Not attached');
    }
    return completer.future;
  }
}
