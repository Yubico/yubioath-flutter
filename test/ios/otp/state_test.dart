/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/ios/otp/state.dart';
import 'package:yubico_authenticator/otp/models.dart';
import 'package:yubico_authenticator/otp/state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.yubico.authenticator/otp');
  final path = DevicePath([]);
  final calls = <MethodCall>[];
  late ProviderContainer container;
  late FutureOr<String?> Function(MethodCall) handler;

  String snapshot({
    bool slot1 = true,
    bool slot2 = false,
    int serial = 123456,
  }) => jsonEncode({
    'state': {
      'slot1_configured': slot1,
      'slot2_configured': slot2,
      'device_serial': serial,
    },
    'result': null,
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
        otpStateProvider.overrideWith2(IosOtpStateNotifier.new),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'one state snapshot initializes both slots without repeated scans',
    () async {
      final state = await container.read(otpStateProvider(path).future);
      expect(state.slot1Configured, isTrue);
      expect(state.slot2Configured, isFalse);
      expect(calls.map((call) => call.method), ['get']);
    },
  );

  test(
    'mutations pass the selected serial and publish returned snapshots',
    () async {
      handler = (call) => switch (call.method) {
        'get' => snapshot(),
        'configureSlot' => snapshot(slot1: false, slot2: true),
        _ => fail('Unexpected method ${call.method}'),
      };
      await container.read(otpStateProvider(path).future);
      final notifier = container.read(otpStateProvider(path).notifier);
      final config = SlotConfiguration.hotp(
        key: 'JBSWY3DPEHPK3PXP',
        options: SlotConfigurationOptions(digits8: true),
      );
      await notifier.configureSlot(
        SlotId.two,
        configuration: config,
        accessCode: '010203040506',
      );

      final call = calls.last;
      expect(call.method, 'configureSlot');
      expect(call.arguments, {
        'slot': 'two',
        'configuration': config.toJson(),
        'accessCode': '010203040506',
        'expectedSerial': 123456,
      });
      final state = container.read(otpStateProvider(path)).requireValue;
      expect(state.slot1Configured, isFalse);
      expect(state.slot2Configured, isTrue);
      expect(calls.map((call) => call.method), ['get', 'configureSlot']);
    },
  );

  test(
    'delete and swap use the same serial binding and do not reload state',
    () async {
      await container.read(otpStateProvider(path).future);
      final notifier = container.read(otpStateProvider(path).notifier);
      await notifier.deleteSlot(SlotId.one, accessCode: '010203040506');
      await notifier.swapSlots();

      expect(calls.map((call) => call.method), [
        'get',
        'deleteSlot',
        'swapSlots',
      ]);
      expect(calls[1].arguments, {
        'slot': 'one',
        'accessCode': '010203040506',
        'expectedSerial': 123456,
      });
      expect(calls[2].arguments, {'expectedSerial': 123456});
    },
  );

  test(
    'all slot configuration variants preserve Android JSON options',
    () async {
      handler = (call) => switch (call.method) {
        'get' || 'configureSlot' => snapshot(),
        _ => fail('Unexpected method ${call.method}'),
      };
      await container.read(otpStateProvider(path).future);
      final notifier = container.read(otpStateProvider(path).notifier);
      final configurations = [
        SlotConfiguration.chalresp(
          key: '00112233445566778899',
          options: SlotConfigurationOptions(requireTouch: true),
        ),
        SlotConfiguration.static(
          password: 'Pa55word',
          keyboardLayout: 'US',
          options: SlotConfigurationOptions(appendCr: false),
        ),
        SlotConfiguration.yubiotp(
          publicId: 'cccccc',
          privateId: '010203040506',
          key: '00112233445566778899aabbccddeeff',
          options: SlotConfigurationOptions(appendCr: true),
        ),
      ];
      for (final config in configurations) {
        await notifier.configureSlot(SlotId.one, configuration: config);
        expect(calls.last.arguments['configuration'], config.toJson());
      }
      expect(configurations.map((config) => config.toJson()['type']), [
        'hmac_sha1',
        'static_password',
        'yubiotp',
      ]);
    },
  );

  test('mutations are blocked when the key identity cannot be bound', () async {
    handler = (_) => jsonEncode({
      'state': {
        'slot1_configured': true,
        'slot2_configured': false,
        'device_serial': null,
      },
      'result': null,
    });
    await container.read(otpStateProvider(path).future);
    final notifier = container.read(otpStateProvider(path).notifier);
    await expectLater(
      notifier.deleteSlot(SlotId.one),
      throwsA(isA<OtpOperationException>()),
    );
    expect(calls.map((call) => call.method), ['get']);
  });

  test(
    'local utilities use the method channel and never request a YubiKey',
    () async {
      handler = (call) => switch (call.method) {
        'get' => snapshot(),
        'getKeyboardLayouts' => jsonEncode({
          'MODHEX': ['b', 'c'],
          'US': ['a', 'b'],
        }),
        'generateStaticPassword' => jsonEncode({'password': 'AB12'}),
        'modhexEncodeSerial' => jsonEncode({'encoded': 'cccc'}),
        'formatYubiOtpCsv' => jsonEncode({
          'csv': '123,public,private,key,,time,',
        }),
        _ => fail('Unexpected method ${call.method}'),
      };
      await container.read(otpStateProvider(path).future);
      calls.clear();
      final notifier = container.read(otpStateProvider(path).notifier);
      expect(await notifier.getKeyboardLayouts(), {
        'MODHEX': ['b', 'c'],
        'US': ['a', 'b'],
      });
      expect(await notifier.generateStaticPassword(4, 'US'), 'AB12');
      expect(await notifier.modhexEncodeSerial(123), 'cccc');
      expect(
        await notifier.formatYubiOtpCsv(123, 'public', 'private', 'key'),
        '123,public,private,key,,time,',
      );
      expect(calls.map((call) => call.method), [
        'getKeyboardLayouts',
        'generateStaticPassword',
        'modhexEncodeSerial',
        'formatYubiOtpCsv',
      ]);
      expect(calls[1].arguments, {'length': 4, 'layout': 'US'});
      expect(calls[3].arguments, {
        'serial': 123,
        'publicId': 'public',
        'privateId': 'private',
        'key': 'key',
      });
    },
  );

  test(
    'failed initial scan exposes a non-retrying state-read exception',
    () async {
      handler = (_) => throw PlatformException(
        code: 'CancellationException',
        message: 'User cancelled NFC',
      );
      await expectLater(
        container.read(otpStateProvider(path).future),
        throwsA(isA<OtpStateReadException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(calls.map((call) => call.method), ['get']);
    },
  );
}
