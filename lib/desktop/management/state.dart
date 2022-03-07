import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../management/state.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.management.state');

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) {
    final currentDevice = ref.watch(currentDeviceProvider);
    final UsbInterface protocol;
    if (currentDevice is UsbYubiKeyNode && currentDevice.info != null) {
      final interfaces = UsbInterfaces.forCapabilites(
          currentDevice.info!.config.enabledCapabilities[Transport.usb] ?? 0);
      protocol = [UsbInterface.ccid, UsbInterface.otp, UsbInterface.fido]
          .firstWhere((iface) => iface.value & interfaces != 0);
    } else {
      protocol = UsbInterface.ccid;
    }
    return RpcNodeSession(
        ref.watch(rpcProvider), devicePath, [protocol.name, 'management']);
  },
);

final desktopManagementState = StateNotifierProvider.autoDispose
    .family<ManagementStateNotifier, DeviceInfo?, DevicePath>(
  (ref, devicePath) {
    final session = ref.watch(_sessionProvider(devicePath));
    final notifier = _DesktopManagementStateNotifier(ref, session);
    session.setErrorHandler('state-reset', (_) async {
      ref.refresh(_sessionProvider(devicePath));
    });
    ref.onDispose(() {
      session.unserErrorHandler('state-reset');
    });
    return notifier..refresh();
  },
);

class _DesktopManagementStateNotifier extends ManagementStateNotifier {
  final Ref _ref;
  final RpcNodeSession _session;
  _DesktopManagementStateNotifier(this._ref, this._session) : super();

  void refresh() async {
    var result = await _session.command('get');
    _log.config('application status', jsonEncode(result));
    if (mounted) {
      state = DeviceInfo.fromJson(result['data']);
    }
  }

  @override
  Future<void> setMode(int mode,
      {int challengeResponseTimeout = 0, int autoEjectTimeout = 0}) async {
    await _session.command('set_mode', params: {
      'mode': mode,
      'challenge_response_timeout': challengeResponseTimeout,
      'auto_eject_timeout': autoEjectTimeout,
    });
  }

  @override
  Future<void> writeConfig(DeviceConfig config,
      {String currentLockCode = '',
      String newLockCode = '',
      bool reboot = false}) async {
    if (reboot) {
      state = null;
    }
    await _session.command('configure', params: {
      ...config.toJson(),
      'cur_lock_code': currentLockCode,
      'new_lock_code': newLockCode,
      'reboot': reboot,
    });
    _ref.read(attachedDevicesProvider.notifier).refresh();
  }
}
