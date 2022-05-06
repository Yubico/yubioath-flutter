import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../management/state.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.management.state');

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) => RpcNodeSession(ref.watch(rpcProvider), devicePath, []),
);

final desktopManagementState = StateNotifierProvider.autoDispose
    .family<ManagementStateNotifier, AsyncValue<DeviceInfo>, DevicePath>(
  (ref, devicePath) {
    // Make sure to rebuild if currentDevice changes (as on reboot)
    ref.watch(currentDeviceProvider);
    final session = ref.watch(_sessionProvider(devicePath));
    final notifier = _DesktopManagementStateNotifier(ref, session);
    session.setErrorHandler('state-reset', (_) async {
      ref.refresh(_sessionProvider(devicePath));
    });
    ref.onDispose(() {
      session.unsetErrorHandler('state-reset');
    });
    return notifier..refresh();
  },
);

class _DesktopManagementStateNotifier extends ManagementStateNotifier {
  final Ref _ref;
  final RpcNodeSession _session;
  List<String> _subpath = [];
  _DesktopManagementStateNotifier(this._ref, this._session) : super();

  Future<void> refresh() => updateState(() async {
        final result = await _session.command('get');
        final info = DeviceInfo.fromJson(result['data']['info']);
        final interfaces = (result['children'] as Map).keys.toSet();
        for (final iface in [
          // This is the preferred order
          UsbInterface.ccid,
          UsbInterface.otp,
          UsbInterface.fido,
        ]) {
          if (interfaces.contains(iface.name)) {
            final path = [iface.name, 'management'];
            try {
              await _session.command('get', target: path);
              _subpath = path;
              _log.debug('Using transport $iface for management');
              return info;
            } catch (e) {
              _log.warning('Failed connecting to management via $iface');
            }
          }
        }
        throw 'Failed connection over all interfaces';
      });

  @override
  Future<void> setMode(
      {required int interfaces,
      int challengeResponseTimeout = 0,
      int? autoEjectTimeout}) async {
    await _session.command('set_mode', target: _subpath, params: {
      'interfaces': interfaces,
      'challenge_response_timeout': challengeResponseTimeout,
      'auto_eject_timeout': autoEjectTimeout,
    });
    _ref.read(attachedDevicesProvider.notifier).refresh();
  }

  @override
  Future<void> writeConfig(DeviceConfig config,
      {String currentLockCode = '',
      String newLockCode = '',
      bool reboot = false}) async {
    if (reboot) {
      state = const AsyncValue.loading();
    }
    await _session.command('configure', target: _subpath, params: {
      ...config.toJson(),
      'cur_lock_code': currentLockCode,
      'new_lock_code': newLockCode,
      'reboot': reboot,
    });
    _ref.read(attachedDevicesProvider.notifier).refresh();
  }
}
