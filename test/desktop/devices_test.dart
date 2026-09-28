import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/desktop/devices.dart';
import 'package:yubico_authenticator/desktop/rpc.dart';

class _DeviceRpc extends RpcSession {
  int enabled = 0x231;
  int pid = 0x407;

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
          'pid': pid,
          'transport': 'usb',
          'info': {
            'serial': 1234,
            'version': [5, 7, 0],
            'form_factor': 1,
            'supported_capabilities': {'usb': 0x231},
            'config': {
              'enabled_capabilities': {'usb': enabled},
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
        '1234': {
          'name': 'YubiKey',
          'serial': 1234,
          'transport': 'usb',
          'pid': pid,
          'enabled_capabilities': {'usb': enabled},
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
      final notifier = DevicesNotifier(rpc);
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
    final notifier = DevicesNotifier(rpc);
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
}
