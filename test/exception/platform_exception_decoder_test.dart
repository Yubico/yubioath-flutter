/*
 * Copyright (C) 2023 Yubico.
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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/exception/apdu_exception.dart';
import 'package:yubico_authenticator/exception/cancellation_exception.dart';
import 'package:yubico_authenticator/exception/platform_exception_decoder.dart';

PlatformException mockApdu(String message) =>
    PlatformException(code: 'ApduException', message: message);

void main() {
  test('Recognize cancellation exception', () {
    final pe = PlatformException(
        code: 'CancellationException',
        message: null,
        details: null,
        stacktrace: null);

    expect(pe.decode(), isA<CancellationException>());
  });

  test('Recognize apdu exception', () {
    var pe = mockApdu(
        'com.yubico.yubikit.core.smartcard.ApduException: APDU error: 0x6f00');

    expect(
        pe.decode(),
        const TypeMatcher<ApduException>()
            .having((ae) => ae.sw, 'SW', 28416)
            .having((ae) => ae.message, 'message', 'SW: 0x6f00'));

    pe = mockApdu(
        'com.yubico.yubikit.core.smartcard.ApduException: APDU error: 0xIJKLMNO');

    expect(pe.decode(), isNot(const TypeMatcher<ApduException>()));

    pe = mockApdu(
        'com.yubico.yubikit.core.smartcard.ApduException: APDU error: 6f00');

    expect(pe.decode(), isNot(const TypeMatcher<ApduException>()));

    pe = mockApdu(
        'com.yubico.yubikit.core.smartcard.ApduException: APDU error:');

    expect(pe.decode(), isNot(const TypeMatcher<ApduException>()));

    pe = mockApdu('');

    expect(pe.decode(), isNot(const TypeMatcher<ApduException>()));
  });

  test('Rethrow', () {
    var pe = PlatformException(
        code: 'some code',
        message: 'some message',
        details: 'some details',
        stacktrace: 'and stacktrace');

    expect(
        pe.decode(),
        const TypeMatcher<PlatformException>()
            .having((pe) => pe.code, 'code', 'some code')
            .having((pe) => pe.message, 'message', 'some message')
            .having((pe) => pe.details, 'details', 'some details')
            .having((pe) => pe.stacktrace, 'stacktrace', 'and stacktrace'));
  });
}
