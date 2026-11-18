import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/desktop/models.dart';
import 'package:yubico_authenticator/desktop/oath/state.dart';
import 'package:yubico_authenticator/desktop/rpc.dart';
import 'package:yubico_authenticator/desktop/state.dart';
import 'package:yubico_authenticator/oath/state.dart';

const _derivedKey = 'derived-key';

/// A password-protected OATH application that can be locked again behind the
/// app's back, as happens when the connection is released while the window
/// is inactive.
class _FakeOathRpc extends RpcSession {
  final actions = <String>[];
  bool locked;

  _FakeOathRpc({required this.locked}) : super('unused');

  @override
  Future<Map<String, dynamic>> command(
    String action,
    List<String>? target, {
    Map? params,
    Signaler? signal,
  }) async {
    actions.add(action);
    switch (action) {
      case 'get':
        return {
          'data': {
            'device_id': 'device',
            'version': [5, 7, 0],
            'has_key': true,
            'remembered': false,
            'locked': locked,
            'keystore': 'allowed',
          },
        };
      case 'derive':
        return {'key': _derivedKey};
      case 'validate':
        final valid = params?['key'] == _derivedKey;
        if (valid) locked = false;
        return {'valid': valid, 'remembered': false};
      case 'calculate_all':
        if (locked) {
          throw RpcResponse.error(
            'auth-required',
            'Authentication required',
            {},
          );
        }
        return {'entries': []};
      default:
        throw StateError('Unexpected action $action');
    }
  }
}

class _FixedSectionNotifier extends CurrentSectionNotifier {
  _FixedSectionNotifier(super.initial);

  @override
  void setCurrentSection(Section section) => state = section;
}

final _windowState = StateProvider<WindowState>(
  (ref) => WindowState(focused: true, visible: true, active: true),
);

final _devicePath = DevicePath(['devices', '12345678']);

Future<ProviderContainer> _createContainer(_FakeOathRpc rpc) async {
  final container = ProviderContainer(
    overrides: [
      rpcProvider.overrideWith((ref) async => rpc),
      currentDeviceDataProvider.overrideWithValue(const AsyncLoading()),
      currentSectionProvider.overrideWith(
        (ref) => _FixedSectionNotifier(Section.accounts),
      ),
      windowStateProvider.overrideWith((ref) => ref.watch(_windowState)),
      withContextProvider.overrideWithValue(
        <T>(action) => throw UnimplementedError(),
      ),
      oathStateProvider.overrideWith2(DesktopOathStateNotifier.new),
      credentialListProvider.overrideWith(
        (ref, devicePath) =>
            buildDesktopOathCredentialListProvider(ref, devicePath),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(rpcProvider.future);
  container.listen(oathStateProvider(_devicePath), (_, _) {});
  return container;
}

Future<bool> _isLocked(ProviderContainer container) async =>
    (await container.read(oathStateProvider(_devicePath).future)).locked;

Future<void> _leaveAndReturn(ProviderContainer container) async {
  container.read(_windowState.notifier).state = WindowState(
    focused: false,
    visible: true,
    active: false,
  );
  await Future<void>.delayed(Duration.zero);
  container.read(_windowState.notifier).state = WindowState(
    focused: true,
    visible: true,
    active: true,
  );
  await Future<void>.delayed(const Duration(milliseconds: 100));
}

void main() {
  test(
    'asks for the password when a refresh hits auth-required without a key',
    () async {
      final rpc = _FakeOathRpc(locked: false);
      final container = await _createContainer(rpc);
      expect(await _isLocked(container), isFalse);

      rpc.locked = true;
      // The unlocked state starts the code refresh, which hits auth-required.
      container.listen(credentialListProvider(_devicePath), (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(await _isLocked(container), isTrue);
      // The locked state stops the refresh instead of retrying every second.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(rpc.actions.where((a) => a == 'calculate_all'), hasLength(1));
    },
  );

  test('shows the lock when the window becomes active again', () async {
    final rpc = _FakeOathRpc(locked: false);
    final container = await _createContainer(rpc);
    expect(await _isLocked(container), isFalse);

    rpc.locked = true;
    await _leaveAndReturn(container);

    expect(await _isLocked(container), isTrue);
  });

  test('unlocks with the cached key when the window becomes active', () async {
    final rpc = _FakeOathRpc(locked: true);
    final container = await _createContainer(rpc);
    expect(await _isLocked(container), isTrue);

    final notifier = container.read(oathStateProvider(_devicePath).notifier);
    final (valid, _) = await notifier.unlock('password');
    expect(valid, isTrue);
    expect(await _isLocked(container), isFalse);

    rpc.locked = true;
    await _leaveAndReturn(container);

    expect(await _isLocked(container), isFalse);
    expect(rpc.locked, isFalse);
  });
}
