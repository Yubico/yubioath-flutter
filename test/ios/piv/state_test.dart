/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/ios/piv/state.dart';
import 'package:yubico_authenticator/piv/models.dart';
import 'package:yubico_authenticator/piv/state.dart';

class _Device extends CurrentDeviceNotifier {
  @override
  DeviceNode? build() => DeviceNode.nfcReader(DevicePath([]), 'YubiKey');

  @override
  void setCurrentDevice(DeviceNode? device) => state = device;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.yubico.authenticator/piv');
  final path = DevicePath([]);
  late ProviderContainer container;
  final calls = <MethodCall>[];
  late FutureOr<String> Function(MethodCall) handler;

  const metadata = {
    'key_type': 17,
    'pin_policy': 2,
    'touch_policy': 1,
    'generated': true,
    'public_key': 'public-key-pem',
  };
  String snapshot({
    Object? result,
    bool authenticated = false,
    int attempts = 3,
    bool populated = false,
  }) => jsonEncode({
    'state': {
      'version': [5, 7, 0],
      'authenticated': authenticated,
      'derived_key': false,
      'stored_key': false,
      'pin_attempts': attempts,
      'supports_bio': false,
    },
    'slots': [
      {
        'slot': 0x9a,
        'metadata': populated ? metadata : null,
        'cert_info': null,
        'public_key_match': null,
      },
    ],
    'result': result,
  });

  setUp(() {
    calls.clear();
    handler = (_) => snapshot();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return await handler(call);
        });
    container = ProviderContainer(
      overrides: [
        currentDeviceDataProvider.overrideWithValue(const AsyncLoading()),
        currentDeviceProvider.overrideWith(_Device.new),
        pivStateProvider.overrideWith2(IosPivStateNotifier.new),
        pivSlotsProvider.overrideWith2(IosPivSlotsNotifier.new),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> start() async {
    container.listen(pivStateProvider(path), (_, _) {});
    container.listen(pivSlotsProvider(path), (_, _) {});
    await container.read(pivStateProvider(path).future);
    await container.read(pivSlotsProvider(path).future);
  }

  test('state and slots share a single NFC snapshot', () async {
    await start();
    expect(
      container.read(pivSlotsProvider(path)).requireValue.single.slot,
      SlotId.authentication,
    );
    expect(calls.map((call) => call.method), ['get']);
  });

  test(
    'authentication and PIN attempts update without an extra scan',
    () async {
      await start();
      final notifier = container.read(pivStateProvider(path).notifier);
      handler = (_) => snapshot(authenticated: true, result: true);
      expect(await notifier.authenticate(defaultManagementKey), isTrue);
      expect(
        (await container.read(pivStateProvider(path).future)).authenticated,
        isTrue,
      );
      handler = (_) => snapshot(
        attempts: 2,
        result: {'status': 'invalid-pin', 'attemptsRemaining': 2},
      );
      final result = await notifier.verifyPin('wrong');
      expect(
        result,
        PinVerificationStatus.failure(PivPinFailureReason.invalidPin(2)),
      );
      expect(
        (await container.read(pivStateProvider(path).future)).pinAttempts,
        2,
      );
      expect(calls.map((call) => call.method), [
        'get',
        'authenticate',
        'verifyPin',
      ]);
    },
  );

  test(
    'key generation publishes slots and sends policies and UTC validity',
    () async {
      await start();
      handler = (_) => snapshot(
        populated: true,
        result: {
          'generate_type': 'certificate',
          'public_key': 'public-key-pem',
          'result': 'certificate-pem',
        },
      );
      final slots = container.read(pivSlotsProvider(path).notifier);
      final result = await slots.generate(
        SlotId.authentication,
        KeyType.eccp256,
        pinPolicy: PinPolicy.once,
        touchPolicy: TouchPolicy.cached,
        parameters: PivGenerateParameters.certificate(
          subject: 'CN=Alice',
          validFrom: DateTime.utc(2026, 1, 1),
          validTo: DateTime.utc(2027, 1, 1),
        ),
      );
      expect(result.result, 'certificate-pem');
      expect(calls.last.arguments, {
        'serial': null,
        'slot': '9a',
        'keyType': 17,
        'pinPolicy': 2,
        'touchPolicy': 3,
        'pin': null,
        'generateType': 'certificate',
        'subject': 'CN=Alice',
        'validFrom': '2026-01-01T00:00:00.000Z',
        'validTo': '2027-01-01T00:00:00.000Z',
      });
      expect(
        (await container.read(pivSlotsProvider(path).future)).single.metadata,
        isNotNull,
      );
      expect(calls, hasLength(2));
    },
  );

  test(
    'file examination and subject validation do not request device state',
    () async {
      final notifier = container.read(pivSlotsProvider(path).notifier);
      await container.read(pivSlotsProvider(path).future);
      calls.clear();
      handler = (call) => jsonEncode(
        call.method == 'validateRfc4514'
            ? {'status': true}
            : {'runtimeType': 'invalidPassword'},
      );
      expect(await notifier.validateRfc4514('CN=Alice'), isTrue);
      expect(
        await notifier.examine(SlotId.authentication, '010203'),
        isA<PivExamineResultInvalidPassword>(),
      );
      expect(calls.map((call) => call.method), [
        'validateRfc4514',
        'examineFile',
      ]);
    },
  );

  test('initial transport failures are visible and never retry NFC', () async {
    handler = (_) =>
        throw PlatformException(code: 'piv_error', message: 'Connection lost');
    container.listen(pivStateProvider(path), (_, _) {});
    await expectLater(
      container.read(pivStateProvider(path).future),
      throwsA(isA<PivStateReadException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(calls, hasLength(1));
  });
}
