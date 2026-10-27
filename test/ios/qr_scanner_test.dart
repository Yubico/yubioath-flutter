/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/exception/cancellation_exception.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';
import 'package:yubico_authenticator/ios/qr_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  String? response;
  PlatformException? failure;

  setUp(() {
    calls.clear();
    response = null;
    failure = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(IosQrScanner.channel, (call) async {
          calls.add(call);
          if (failure != null) throw failure!;
          return response;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(IosQrScanner.channel, null);
  });

  testWidgets('camera scan passes localized controls and returns QR text', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scanner = IosQrScanner(
      <T>(Future<T> Function(BuildContext) action) => action(context),
    );
    response = 'otpauth://totp/Example?secret=JBSWY3DPEHPK3PXP';
    expect(await scanner.scanQr(), response);
    expect(calls.single.method, 'scan');
    expect(
      (calls.single.arguments as Map)['permission'],
      AppLocalizations.of(context).p_need_camera_permission,
    );
    response = null;
    await expectLater(scanner.scanQr(), throwsA(isA<CancellationException>()));
    failure = PlatformException(code: 'camera_error', message: 'Camera failed');
    await expectLater(scanner.scanQr(), throwsA(isA<PlatformException>()));
  });

  test(
    'image scan sends bytes without requesting a camera or UI context',
    () async {
      final scanner = IosQrScanner(
        <T>(Future<T> Function(BuildContext) action) =>
            throw StateError('Image decoding must not open camera UI'),
      );
      response = 'otpauth-migration://offline?data=example';
      expect(await scanner.scanQr(base64Encode([1, 2, 3])), response);
      expect(calls.single.method, 'scanImage');
      expect(calls.single.arguments, Uint8List.fromList([1, 2, 3]));
      response = null;
      expect(await scanner.scanQr(base64Encode([1])), isNull);
      failure = PlatformException(
        code: 'invalid_image',
        message: 'Invalid image',
      );
      await expectLater(
        scanner.scanQr(base64Encode([1])),
        throwsA(isA<PlatformException>()),
      );
    },
  );
}
