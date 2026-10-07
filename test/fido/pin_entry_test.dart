import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/desktop/fido/state.dart';
import 'package:yubico_authenticator/desktop/models.dart';
import 'package:yubico_authenticator/desktop/rpc.dart';
import 'package:yubico_authenticator/desktop/state.dart';
import 'package:yubico_authenticator/fido/keys.dart' as keys;
import 'package:yubico_authenticator/fido/state.dart';
import 'package:yubico_authenticator/fido/views/key_actions.dart';
import 'package:yubico_authenticator/fido/views/pin_confirmation_dialog.dart';
import 'package:yubico_authenticator/fido/views/pin_dialog.dart';
import 'package:yubico_authenticator/fido/views/pin_entry_form.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations_en.dart';
import 'package:yubico_authenticator/management/models.dart';

class _PinRpc extends RpcSession {
  final String correctPin;
  final unlockPins = <String>[];
  final changedPins = <String>[];
  int retries = 8;
  bool unlocked = false;

  _PinRpc({this.correctPin = '123456'}) : super('unused');

  @override
  Future<Map<String, dynamic>> command(
    String action,
    List<String>? target, {
    Map? params,
    Signaler? signal,
  }) async {
    if (action == 'unlock') {
      final pin = params!['pin'] as String;
      unlockPins.add(pin);
      if (pin != correctPin) {
        retries--;
        throw RpcResponse.error('pin-validation', 'Wrong PIN', {
          'retries': retries,
          'auth_blocked': false,
        });
      }
      retries = 8;
      unlocked = true;
      return {};
    }
    if (action == 'set_pin') {
      changedPins.add(params!['pin'] as String);
      return {};
    }
    return {
      'data': {
        'info': {
          'options': {'clientPin': true, 'credMgmt': true},
          'min_pin_length': 6,
        },
        'unlocked': unlocked,
        'unlocked_read': unlocked,
        'pin_retries': retries,
      },
    };
  }
}

class _CurrentDevice extends CurrentDeviceNotifier {
  final DeviceNode device;
  _CurrentDevice(this.device);

  @override
  DeviceNode build() => device;

  @override
  void setCurrentDevice(DeviceNode? device) => state = device;
}

final _path = DevicePath(['devices', '1234']);
final _info = DeviceInfo(
  DeviceConfig({Transport.usb: Capability.fido2.value}, null, null, null),
  1234,
  const Version(5, 2, 6),
  FormFactor.usbCKeychain,
  {Transport.usb: Capability.fido2.value},
  false,
  false,
  false,
  false,
  0,
  0,
  0,
  VersionQualifier(const Version(5, 2, 6), ReleaseType.release, 0),
);
final _device = DeviceNode.yubiKey(
  _path,
  'YubiKey',
  null,
  Transport.usb,
  _info,
);
final _data = YubiKeyData(_device, 'YubiKey', _info);

Future<void> _pumpApp(WidgetTester tester, _PinRpc rpc) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rpcProvider.overrideWithValue(AsyncData(rpc)),
        currentDeviceProvider.overrideWith(() => _CurrentDevice(_device)),
        currentDeviceDataProvider.overrideWithValue(AsyncData(_data)),
        featureProvider.overrideWithValue((_) => true),
        fidoStateProvider(_path)
            .overrideWith(() => DesktopFidoStateNotifier(_path)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(fidoStateProvider(_path)).value;
            return Scaffold(
              body: state == null
                  ? const SizedBox()
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          PinEntryForm(state, _data),
                          passkeysBuildActions(context, ref, _device, state),
                          TextButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => FidoPinConfirmationDialog(
                                devicePath: _path,
                                state: state,
                              ),
                            ),
                            child: const Text('Confirm PIN'),
                          ),
                          TextButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => FidoPinDialog(_path, state),
                            ),
                            child: const Text('Open PIN change'),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('short PIN is inline and actions track wrong then correct PIN', (
    tester,
  ) async {
    final rpc = _PinRpc();
    await _pumpApp(tester, rpc);
    await tester.enterText(find.byKey(keys.pinEntry), '123');
    await tester.tap(find.byKey(keys.unlockFido2WithPin));
    await tester.pumpAndSettle();
    expect(find.text(l10n.s_invalid_length), findsOneWidget);
    expect(rpc.unlockPins, isEmpty);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byKey(keys.pinEntry), '654321');
    await tester.tap(find.byKey(keys.unlockFido2WithPin));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(keys.managePinAction),
        matching: find.text(l10n.l_attempts_remaining(7)),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(keys.pinEntry), '123456');
    await tester.tap(find.byKey(keys.unlockFido2WithPin));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(keys.managePinAction),
        matching: find.text(l10n.l_attempts_remaining(8)),
      ),
      findsOneWidget,
    );
    expect(rpc.unlockPins, ['654321', '123456']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation rejects short PIN and then accepts correct PIN', (
    tester,
  ) async {
    final rpc = _PinRpc();
    await _pumpApp(tester, rpc);
    await tester.tap(find.text('Confirm PIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(keys.pinConfirmationEntry), '123');
    await tester.tap(find.byKey(keys.unlockFido2WithPinConfirmation));
    await tester.pumpAndSettle();
    expect(find.text(l10n.s_invalid_length), findsOneWidget);
    expect(rpc.unlockPins, isEmpty);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byKey(keys.pinConfirmationEntry), '123456');
    await tester.tap(find.byKey(keys.unlockFido2WithPinConfirmation));
    await tester.pumpAndSettle();
    expect(find.byType(FidoPinConfirmationDialog), findsNothing);
    expect(rpc.unlockPins, ['123456']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN change rejects a too-short current PIN inline', (
    tester,
  ) async {
    final rpc = _PinRpc();
    await _pumpApp(tester, rpc);
    await tester.tap(find.text('Open PIN change'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(keys.currentPin), '123');
    await tester.enterText(find.byKey(keys.newPin), '123456');
    await tester.enterText(find.byKey(keys.confirmPin), '123456');
    await tester.tap(find.byKey(keys.saveButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.s_invalid_length), findsOneWidget);
    expect(rpc.changedPins, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing PIN need not meet the new-PIN minimum', (tester) async {
    final rpc = _PinRpc(correctPin: '1234');
    await _pumpApp(tester, rpc);
    await tester.enterText(find.byKey(keys.pinEntry), '1234');
    await tester.tap(find.byKey(keys.unlockFido2WithPin));
    await tester.pumpAndSettle();
    expect(rpc.unlockPins, ['1234']);
    expect(rpc.unlocked, isTrue);
    expect(tester.takeException(), isNull);
  });
}
