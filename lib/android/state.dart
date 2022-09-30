import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../app/state.dart';
import 'app_methods.dart';
import 'devices.dart';

const _contextChannel = MethodChannel('android.state.appContext');

final androidAllowScreenshotsProvider =
    StateNotifierProvider<AllowScreenshotsNotifier, bool>(
  (ref) => AllowScreenshotsNotifier(),
);

class AllowScreenshotsNotifier extends StateNotifier<bool> {
  AllowScreenshotsNotifier() : super(false);

  void setAllowScreenshots(bool value) async {
    final result =
        await appMethodsChannel.invokeMethod('allowScreenshots', value);
    if (mounted) {
      state = result;
    }
  }
}

final androidClipboardProvider = Provider<AppClipboard>(
  (ref) => _AndroidClipboard(ref),
);

class _AndroidClipboard extends AppClipboard {
  final ProviderRef<AppClipboard> _ref;

  const _AndroidClipboard(this._ref);

  @override
  bool platformGivesFeedback() {
    return _ref.read(androidSdkVersionProvider) >= 33;
  }

  @override
  Future<void> setText(String toClipboard, {bool isSensitive = false}) async {
    await setPrimaryClip(toClipboard, isSensitive);
  }
}

final androidSdkVersionProvider = Provider<int>((ref) => -1);

final androidSupportedThemesProvider = StateProvider<List<ThemeMode>>((ref) {
  if (ref.read(androidSdkVersionProvider) < 29) {
    /// the user can select from light or dark theme of the app
    return [ThemeMode.light, ThemeMode.dark];
  } else {
    /// the user can also select system theme on newer Android versions
    return ThemeMode.values;
  }
});

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
  final provider =
      _AndroidCurrentDeviceNotifier(ref.watch(androidYubikeyProvider));
  return provider;
});

class _AndroidCurrentDeviceNotifier extends CurrentDeviceNotifier {
  _AndroidCurrentDeviceNotifier(AsyncValue<YubiKeyData> device)
      : super(device.whenOrNull(data: (data) => data.node));

  @override
  setCurrentDevice(DeviceNode? device) {
    state = device;
  }
}
