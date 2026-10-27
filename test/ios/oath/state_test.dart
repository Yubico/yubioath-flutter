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
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/exception/cancellation_exception.dart';
import 'package:yubico_authenticator/ios/oath/state.dart';
import 'package:yubico_authenticator/oath/models.dart';
import 'package:yubico_authenticator/oath/state.dart';

class _CurrentDevice extends CurrentDeviceNotifier {
  @override
  DeviceNode build() => DeviceNode.nfcReader(DevicePath([]), 'YubiKey');

  @override
  void setCurrentDevice(DeviceNode? device) => state = device;
}

class _CurrentSection extends CurrentSectionNotifier {
  _CurrentSection() : super(Section.accounts);

  @override
  void setCurrentSection(Section section) => state = section;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.yubico.authenticator/oath');
  final path = DevicePath([]);
  final calls = <MethodCall>[];
  late ProviderContainer container;
  late FutureOr<String?> Function(MethodCall) handler;

  Map<String, Object?> credential({
    String id = '74657374',
    String name = 'test',
    int type = 32,
    bool touch = false,
  }) => {
    'device_id': 'oath-device',
    'id': id,
    'issuer': null,
    'name': name,
    'oath_type': type,
    'period': type == 32 ? 30 : 0,
    'touch_required': touch,
  };

  Map<String, Object> code(String value) => {
    'value': value,
    'valid_from': 1800000000,
    'valid_to': 1800000030,
  };

  String snapshot({
    bool locked = false,
    bool hasKey = false,
    bool remembered = false,
    List<Map<String, Object?>>? pairs,
    Object? result,
  }) => jsonEncode({
    'state': {
      'device_id': 'oath-device',
      'version': [5, 7, 0],
      'has_key': hasKey,
      'locked': locked,
      'remembered': remembered,
      'keystore': 'allowed',
    },
    'credentials':
        pairs ??
        [
          {'credential': credential(), 'code': code('123456')},
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
        currentDeviceProvider.overrideWith(_CurrentDevice.new),
        currentSectionProvider.overrideWith((_) => _CurrentSection()),
        oathStateProvider.overrideWith2(IosOathStateNotifier.new),
        credentialListProvider.overrideWith(buildIosCredentialList),
      ],
    );
  });

  void start() {
    container.listen(oathStateProvider(path), (_, _) {});
    container.listen(credentialListProvider(path), (_, _) {});
  }

  tearDown(() {
    container.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'account import accepts uppercase, lowercase and grouped secrets',
    () async {
      start();
      await container.read(oathStateProvider(path).future);
      await container.pump();
      handler = (_) => snapshot(result: credential());
      for (final secret in [
        'JBSWY3DPEHPK3PXP',
        'jbswy3dpehpk3pxp',
        'JbSwY3dP eHpK3pXp',
      ]) {
        await container
            .read(credentialListProvider(path).notifier)
            .addAccount(
              Uri(
                scheme: 'otpauth',
                host: 'totp',
                path: '/test',
                queryParameters: {'secret': secret},
              ),
            );
        final args = calls.last.arguments as Map;
        expect((args['credential'] as Map)['secret'], [
          72,
          101,
          108,
          108,
          111,
          33,
          222,
          173,
          190,
          239,
        ]);
      }
      final previousCalls = calls.length;
      await expectLater(
        container
            .read(credentialListProvider(path).notifier)
            .addAccount(Uri.parse('otpauth://totp/test?secret=INVALID!')),
        throwsFormatException,
      );
      expect(calls, hasLength(previousCalls));
    },
  );

  test('one NFC read supplies state and credentials without polling', () async {
    start();
    final state = await container.read(oathStateProvider(path).future);
    await container.pump();
    expect(state.deviceId, 'oath-device');
    expect(state.locked, isFalse);
    final pairs = container.read(credentialListProvider(path))!;
    expect(pairs.single.credential.name, 'test');
    expect(pairs.single.code!.value, '123456');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(calls.map((call) => call.method), ['get']);
  });

  test(
    'unlock publishes password state and account list from one scan',
    () async {
      handler = (call) => call.method == 'get'
          ? snapshot(locked: true, hasKey: true, pairs: [])
          : snapshot(hasKey: true, remembered: true, result: true);
      start();
      expect(
        (await container.read(oathStateProvider(path).future)).locked,
        isTrue,
      );
      final result = await container
          .read(oathStateProvider(path).notifier)
          .unlock('password', remember: true);
      await container.pump();
      expect(result, (true, true));
      final state = await container.read(oathStateProvider(path).future);
      expect(state.locked, isFalse);
      expect(state.remembered, isTrue);
      expect(container.read(credentialListProvider(path)), hasLength(1));
      expect(calls.last.arguments, {
        'deviceId': 'oath-device',
        'password': 'password',
        'remember': true,
      });
    },
  );

  test(
    'add, rename, calculate and delete update the shared account list',
    () async {
      start();
      await container.read(oathStateProvider(path).future);
      final list = container.read(credentialListProvider(path).notifier);
      final added = credential(id: '6e6577', name: 'new', type: 16);
      handler = (call) {
        switch (call.method) {
          case 'addAccount':
            final args = Map<String, Object?>.from(call.arguments as Map);
            final input = Map<String, Object?>.from(args['credential']! as Map);
            expect(input['secret'], Uint8List.fromList(List.filled(10, 0)));
            expect(input['hash_algorithm'], 1);
            expect(input['oath_type'], 16);
            expect(args['requireTouch'], isTrue);
            return snapshot(
              pairs: [
                {'credential': added, 'code': null},
              ],
              result: added,
            );
          case 'renameAccount':
            final renamed = {
              ...added,
              'id': '72656e616d6564',
              'name': 'renamed',
            };
            return snapshot(
              pairs: [
                {'credential': renamed, 'code': null},
              ],
              result: renamed,
            );
          case 'calculate':
            final renamed = {
              ...added,
              'id': '72656e616d6564',
              'name': 'renamed',
            };
            return snapshot(
              pairs: [
                {'credential': renamed, 'code': code('654321')},
              ],
              result: code('654321'),
            );
          case 'deleteAccount':
            return snapshot(pairs: []);
          default:
            fail('Unexpected call ${call.method}');
        }
      };
      final account = await list.addAccount(
        Uri.parse('otpauth://hotp/new?secret=AAAAAAAAAAAAAAAA&counter=0'),
        requireTouch: true,
      );
      expect(account.oathType, OathType.hotp);
      final renamed = await list.renameAccount(account, null, 'renamed');
      expect(renamed.name, 'renamed');
      expect((await list.calculate(renamed)).value, '654321');
      expect(
        container.read(credentialListProvider(path))!.single.code!.value,
        '654321',
      );
      await list.deleteAccount(renamed);
      expect(container.read(credentialListProvider(path)), isEmpty);
    },
  );

  test(
    'password operations publish snapshots, including a rejected unlock',
    () async {
      handler = (_) => snapshot(locked: true, hasKey: true, pairs: []);
      start();
      await container.read(oathStateProvider(path).future);
      final notifier = container.read(oathStateProvider(path).notifier);
      handler = (_) =>
          snapshot(locked: true, hasKey: true, pairs: [], result: false);
      expect(await notifier.unlock('wrong'), (false, false));
      expect(
        (await container.read(oathStateProvider(path).future)).locked,
        isTrue,
      );

      handler = (_) => snapshot(hasKey: true, result: true);
      expect(await notifier.setPassword('old', 'new'), isTrue);
      expect(calls.last.method, 'setPassword');
      expect(calls.last.arguments['current'], 'old');
      expect(
        (await container.read(oathStateProvider(path).future)).hasKey,
        isTrue,
      );

      handler = (_) => snapshot(result: true);
      expect(await notifier.unsetPassword('new'), isTrue);
      expect(
        (await container.read(oathStateProvider(path).future)).hasKey,
        isFalse,
      );
      await notifier.forgetPassword();
      expect(calls.last.method, 'forgetPassword');
      handler = (_) => snapshot(pairs: []);
      await notifier.reset();
      expect(calls.last.method, 'reset');
      expect(container.read(credentialListProvider(path)), isEmpty);
    },
  );

  test('refresh retains manually calculated HOTP and touch codes', () async {
    final hotp = credential(id: '01', name: 'hotp', type: 16);
    final touch = credential(id: '02', name: 'touch', touch: true);
    handler = (_) => snapshot(
      pairs: [
        {'credential': hotp, 'code': null},
        {'credential': touch, 'code': null},
      ],
    );
    start();
    await container.read(oathStateProvider(path).future);
    final list = container.read(credentialListProvider(path).notifier);
    handler = (_) => snapshot(
      pairs: [
        {
          'credential': hotp,
          'code': {...code('111111'), 'valid_to': 0},
        },
        {'credential': touch, 'code': null},
      ],
      result: {...code('111111'), 'valid_to': 0},
    );
    await list.calculate(OathCredential.fromJson(hotp));
    handler = (_) => snapshot(
      pairs: [
        {'credential': hotp, 'code': null},
        {'credential': touch, 'code': code('222222')},
      ],
      result: code('222222'),
    );
    await list.calculate(OathCredential.fromJson(touch));
    final pairs = container.read(credentialListProvider(path))!;
    expect(pairs.map((pair) => pair.code!.value), ['111111', '222222']);
    expect(pairs.first.code!.validTo, 0);
  });

  test(
    'malformed responses expose an error without retrying the NFC scan',
    () async {
      handler = (_) => '{"state": {}}';
      start();
      await expectLater(
        container.read(oathStateProvider(path).future),
        throwsA(isA<OathStateReadException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(calls.map((call) => call.method), ['get']);
    },
  );

  testWidgets('USB refresh stops outside Accounts and in the background', (
    tester,
  ) async {
    container
        .read(currentDeviceProvider.notifier)
        .setCurrentDevice(
          DeviceNode.usbYubiKey(path, 'YubiKey', UsbPid.yk4OtpFidoCcid, null),
        );
    handler = (_) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return snapshot(
        pairs: [
          {
            'credential': credential(),
            'code': {
              'value': '123456',
              'valid_from': now,
              'valid_to': now + (calls.length == 1 ? 1 : 60),
            },
          },
        ],
      );
    };
    start();
    await tester.pump();
    await container.read(oathStateProvider(path).future);
    await tester.pump(const Duration(seconds: 2));
    expect(calls.map((call) => call.method), ['get', 'get']);

    final sections = container.read(currentSectionProvider.notifier);
    sections.setCurrentSection(Section.home);
    await tester.pump(const Duration(seconds: 61));
    expect(calls, hasLength(2));
    sections.setCurrentSection(Section.accounts);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 61));
    expect(calls, hasLength(2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 61));
    expect(calls, hasLength(3));
    sections.setCurrentSection(Section.home);
  });

  test(
    'a cancelled initial scan exposes an error without another NFC prompt',
    () async {
      handler = (_) => throw PlatformException(code: 'CancellationException');
      start();
      await expectLater(
        container.read(oathStateProvider(path).future),
        throwsA(
          isA<OathStateReadException>().having(
            (error) => error.cause,
            'cause',
            isA<CancellationException>(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(calls.map((call) => call.method), ['get']);
    },
  );
}
