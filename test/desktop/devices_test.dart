import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/desktop/devices.dart';
import 'package:yubico_authenticator/desktop/rpc.dart';

class _DeviceRpc extends RpcSession {
  int enabled = 0x231;
  int pid = 0x407;
  String transport = 'usb';
  bool present = true;

  _DeviceRpc() : super('unused');

  @override
  Future<Map<String, dynamic>> command(
    String action,
    List<String>? target, {
    Map? params,
    Signaler? signal,
  }) async {
    if (target?.length == 2) {
      return {
        'data': {
          'name': 'YubiKey',
          'pid': transport == 'usb' ? pid : null,
          'transport': transport,
          'info': {
            'serial': 1234,
            'version': [5, 7, 0],
            'form_factor': 1,
            'supported_capabilities': {
              'usb': 0x231,
              if (transport == 'nfc') 'nfc': 0x231,
            },
            'config': {
              'enabled_capabilities': {
                'usb': enabled,
                if (transport == 'nfc') 'nfc': enabled,
              },
              'auto_eject_timeout': null,
              'challenge_response_timeout': null,
              'device_flags': null,
            },
            'is_locked': false,
            'is_fips': false,
            'is_sky': false,
            'pin_complexity': false,
            'fips_capable': 0,
            'fips_approved': 0,
            'reset_blocked': 0,
            'version_qualifier': {
              'version': [5, 7, 0],
              'type': 2,
              'iteration': 0,
            },
          },
        },
      };
    }
    return {
      'data': {'pids': <String, int>{}},
      'children': {
        if (present)
          '1234': {
            'name': 'YubiKey',
            'serial': 1234,
            'transport': transport,
            'pid': transport == 'usb' ? pid : null,
            'enabled_capabilities': {
              'usb': enabled,
              if (transport == 'nfc') 'nfc': enabled,
            },
          },
      },
    };
  }
}

void main() {
  test(
    'updates device info when capabilities change without changing ID',
    () async {
      final rpc = _DeviceRpc();
      final notifier = DevicesNotifier(rpc, () => false);
      addTearDown(notifier.dispose);

      final initial = notifier.stream.firstWhere(
        (devices) => devices.isNotEmpty,
      );
      notifier.refresh();
      await initial.timeout(const Duration(seconds: 2));

      rpc.enabled = 0x221;
      final refreshed = await notifier.stream
          .firstWhere(
            (devices) =>
                devices.isNotEmpty &&
                devices.first.info?.config.enabledCapabilities[Transport.usb] ==
                    rpc.enabled,
          )
          .timeout(const Duration(seconds: 3));
      expect(
        refreshed.single.info?.config.enabledCapabilities[Transport.usb],
        0x221,
      );
      expect(refreshed.single.path.key, 'devices/1234');
    },
  );

  test('refreshes interfaces when the serial stays the same', () async {
    final rpc = _DeviceRpc();
    final notifier = DevicesNotifier(rpc, () => false);
    addTearDown(notifier.dispose);

    final initial = notifier.stream.firstWhere((devices) => devices.isNotEmpty);
    notifier.refresh();
    await initial.timeout(const Duration(seconds: 2));

    rpc.enabled = 0x230;
    rpc.pid = 0x406;
    final refreshed = await notifier.stream
        .firstWhere(
          (devices) =>
              devices.isNotEmpty &&
              devices.first.info?.config.enabledCapabilities[Transport.usb] ==
                  0x230,
        )
        .timeout(const Duration(seconds: 3));
    expect(refreshed.single.pid?.value, 0x406);
    expect(refreshed.single.path.key, 'devices/1234');
  });

  test(
    'discovers service NFC keys without a USB PID and tracks removal',
    () async {
      final rpc = _DeviceRpc()..transport = 'nfc';
      final notifier = DevicesNotifier(rpc, () => false);
      addTearDown(notifier.dispose);

      final initial = notifier.stream.firstWhere(
        (devices) => devices.isNotEmpty,
      );
      notifier.refresh();
      final devices = await initial.timeout(const Duration(seconds: 2));
      expect(devices.single.transport, Transport.nfc);
      expect(devices.single.pid, isNull);
      expect(devices.single.path.key, 'devices/1234');
      expect(
        devices.single.info?.config.enabledCapabilities[Transport.nfc],
        rpc.enabled,
      );

      rpc.present = false;
      await notifier.stream
          .firstWhere((devices) => devices.isEmpty)
          .timeout(const Duration(seconds: 3));
      expect(notifier.state, isEmpty);

      rpc.present = true;
      final reinserted = await notifier.stream
          .firstWhere((devices) => devices.isNotEmpty)
          .timeout(const Duration(seconds: 3));
      expect(reinserted.single.transport, Transport.nfc);
      expect(reinserted.single.pid, isNull);
    },
  );
}
