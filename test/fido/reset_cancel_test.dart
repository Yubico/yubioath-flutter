import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/app/views/reset_dialog.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/desktop/fido/state.dart';
import 'package:yubico_authenticator/desktop/models.dart';
import 'package:yubico_authenticator/desktop/rpc.dart';
import 'package:yubico_authenticator/desktop/state.dart';
import 'package:yubico_authenticator/fido/models.dart';
import 'package:yubico_authenticator/fido/state.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations_en.dart';
import 'package:yubico_authenticator/management/models.dart';

final _path = DevicePath(['devices', '1234']);
final _info = DeviceInfo(
  DeviceConfig({Transport.usb: Capability.fido2.value}, null, null, null),
  1234,
  const Version(5, 7, 1),
  FormFactor.usbCKeychain,
  {Transport.usb: Capability.fido2.value},
  false,
  false,
  false,
  false,
  0,
  0,
  0,
  VersionQualifier(const Version(5, 7, 1), ReleaseType.release, 0),
);
final _device = DeviceNode.yubiKey(
  _path,
  'YubiKey',
  null,
  Transport.usb,
  _info,
);
final _data = YubiKeyData(_device, 'YubiKey', _info);
final _state = {
  'info': {
    'options': {'clientPin': true, 'credMgmt': true},
  },
  'pin_retries': 8,
  'unlocked': false,
  'unlocked_read': false,
};

class _CurrentDevice extends CurrentDeviceNotifier {
  @override
  DeviceNode build() => _device;

  @override
  void setCurrentDevice(DeviceNode? device) => state = device;
}

class _ResetRpc extends RpcSession {
  final response = Completer<Map<String, dynamic>>();
  final started = Completer<void>();
  final closed = Completer<void>();
  int closes = 0;

  _ResetRpc() : super('unused');

  @override
  Future<Map<String, dynamic>> command(
    String action,
    List<String>? target, {
    Map? params,
    Signaler? signal,
  }) async {
    if (action == 'reset') {
      started.complete();
      return response.future;
    }
    if (action == 'close') {
      expect(target, [..._path.segments]);
      expect(params, {'child': 'fido'});
      closes++;
      closed.complete();
      return {};
    }
    return {'data': _state};
  }
}

class _ResetState extends FidoStateNotifier {
  final InteractionEvent phase;
  bool cancelled = false;

  _ResetState(this.phase) : super(_path);

  @override
  FidoState build() => FidoState.fromJson(_state);

  @override
  Stream<InteractionEvent> reset() {
    final controller = StreamController<InteractionEvent>();
    controller.onListen = () => controller.add(phase);
    controller.onCancel = () {
      cancelled = true;
      unawaited(controller.close());
    };
    return controller.stream;
  }

  @override
  Future<PinResult> setPin(String newPin, {String? oldPin}) =>
      throw UnimplementedError();

  @override
  Future<PinResult> unlock(String pin, {bool remember = false}) =>
      throw UnimplementedError();

  @override
  Future<void> enableEnterpriseAttestation() => throw UnimplementedError();
}

void main() {
  test('cancelled reset closes its transport and reloads state', () async {
    final rpc = _ResetRpc();
    final container = ProviderContainer(
      overrides: [
        rpcProvider.overrideWithValue(AsyncData(rpc)),
        currentDeviceProvider.overrideWith(_CurrentDevice.new),
        fidoStateProvider(_path)
            .overrideWith(() => DesktopFidoStateNotifier(_path)),
      ],
    );
    addTearDown(container.dispose);
    final state = container.listen(fidoStateProvider(_path), (_, _) {});
    addTearDown(state.close);
    await container.read(fidoStateProvider(_path).future);
    final subscription = container
        .read(fidoStateProvider(_path).notifier)
        .reset()
        .listen(
          (_) {},
          onError: (Object error) => fail('Unexpected reset error: $error'),
        );
    await rpc.started.future;
    await subscription.cancel();
    rpc.response.completeError(
      RpcResponse.error('cancelled', 'Operation cancelled', {}),
    );
    await rpc.closed.future;
    await Future<void>.delayed(Duration.zero);
    expect(rpc.closes, 1);
    expect(
      (await container.read(fidoStateProvider(_path).future)).pinRetries,
      8,
    );
  });

  test(
    'reset completion after provider disposal does not access disposed state',
    () async {
      final rpc = _ResetRpc();
      final container = ProviderContainer(
        overrides: [
          rpcProvider.overrideWithValue(AsyncData(rpc)),
          currentDeviceProvider.overrideWith(_CurrentDevice.new),
          fidoStateProvider(_path)
              .overrideWith(() => DesktopFidoStateNotifier(_path)),
        ],
      );
      container.listen(fidoStateProvider(_path), (_, _) {});
      await container.read(fidoStateProvider(_path).future);
      final subscription = container
          .read(fidoStateProvider(_path).notifier)
          .reset()
          .listen((_) {});
      await rpc.started.future;
      await subscription.cancel();
      container.dispose();
      rpc.response.completeError(
        RpcResponse.error('cancelled', 'Operation cancelled', {}),
      );
      await rpc.closed.future;
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('reset failures remain visible and close the stream', () async {
    final rpc = _ResetRpc();
    final container = ProviderContainer(
      overrides: [
        rpcProvider.overrideWithValue(AsyncData(rpc)),
        currentDeviceProvider.overrideWith(_CurrentDevice.new),
        fidoStateProvider(_path)
            .overrideWith(() => DesktopFidoStateNotifier(_path)),
      ],
    );
    addTearDown(container.dispose);
    final state = container.listen(fidoStateProvider(_path), (_, _) {});
    addTearDown(state.close);
    await container.read(fidoStateProvider(_path).future);
    final errors = <Object>[];
    final done = Completer<void>();
    container
        .read(fidoStateProvider(_path).notifier)
        .reset()
        .listen((_) {}, onError: errors.add, onDone: done.complete);
    await rpc.started.future;
    final error = RpcResponse.error(
      'user-action-timeout',
      'Reset timed out',
      {},
    );
    rpc.response.completeError(error);
    await done.future;
    expect(errors, [same(error)]);
    expect(rpc.closes, 1);
  });

  for (final phase in [
    InteractionEvent.remove,
    InteractionEvent.insert,
    InteractionEvent.touch,
  ]) {
    for (final width in [360.0, 1000.0]) {
      testWidgets(
        'cancelling reset at $phase with width $width releases dialog state',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final reset = _ResetState(phase);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                featureProvider.overrideWithValue((_) => true),
                fidoStateProvider(_path).overrideWith(() => reset),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            ResetDialog(_data, application: Capability.fido2),
                      ),
                      child: const Text('Open reset'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open reset'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(factoryResetReset));
          await tester.pump();
          final container = ProviderScope.containerOf(
            tester.element(find.byType(ResetDialog)),
          );
          expect(container.read(fidoResetInProgressProvider), isTrue);
          final l10n = AppLocalizationsEn();
          final message = fidoResetInstruction(
            l10n,
            phase,
            nfc: false,
            longTouch: false,
          );
          expect(find.textContaining(message), findsOneWidget);
          await tester.tap(find.byKey(closeButton));
          await tester.pumpAndSettle();
          expect(find.byType(ResetDialog), findsNothing);
          expect(reset.cancelled, isTrue);
          expect(container.read(fidoResetInProgressProvider), isFalse);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant({TargetPlatform.linux}),
      );
    }
  }
}
