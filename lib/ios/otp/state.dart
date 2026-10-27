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
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/state.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../otp/models.dart';
import '../../otp/state.dart';

const _channel = MethodChannel('com.yubico.authenticator/otp');
final _log = Logger('ios.otp.state');

class OtpOperationException implements Exception {
  const OtpOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _OtpSnapshot {
  _OtpSnapshot.fromJson(Map<String, dynamic> json)
    : state = OtpState.fromJson(json['state'] as Map<String, dynamic>),
      serial = (json['state'] as Map<String, dynamic>)['device_serial'] as int?;

  final OtpState state;
  final int? serial;
}

class IosOtpStateNotifier extends OtpStateNotifier {
  IosOtpStateNotifier(super.devicePath);

  int? _deviceSerial;

  @override
  Future<OtpState> build() async {
    final selectedSerial = ref.watch(
      currentDeviceDataProvider.select((value) => value.value?.info.serial),
    );
    try {
      final snapshot = await _snapshot('get', {
        'expectedSerial': ?selectedSerial,
      });
      _deviceSerial = snapshot.serial;
      return snapshot.state;
    } catch (error, stack) {
      _log.error('Failed to read OTP slot state', error, stack);
      Error.throwWithStackTrace(OtpStateReadException(error), stack);
    }
  }

  @override
  Future<void> swapSlots() async {
    await _mutate('swapSlots');
  }

  @override
  Future<void> configureSlot(
    SlotId slot, {
    required SlotConfiguration configuration,
    String? accessCode,
  }) async {
    await _mutate('configureSlot', {
      'slot': slot.id,
      'configuration': configuration.toJson(),
      'accessCode': accessCode,
    });
  }

  @override
  Future<void> deleteSlot(SlotId slot, {String? accessCode}) async {
    await _mutate('deleteSlot', {'slot': slot.id, 'accessCode': accessCode});
  }

  @override
  Future<String> generateStaticPassword(int length, String layout) async {
    final response = await _compute('generateStaticPassword', {
      'length': length,
      'layout': layout,
    });
    return response['password'] as String;
  }

  @override
  Future<String> modhexEncodeSerial(int serial) async {
    final response = await _compute('modhexEncodeSerial', {'serial': serial});
    return response['encoded'] as String;
  }

  @override
  Future<Map<String, List<String>>> getKeyboardLayouts() async {
    final response = await _compute('getKeyboardLayouts');
    return response.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>).cast<String>().toList(growable: false),
      ),
    );
  }

  @override
  Future<String> formatYubiOtpCsv(
    int serial,
    String publicId,
    String privateId,
    String key,
  ) async {
    final response = await _compute('formatYubiOtpCsv', {
      'serial': serial,
      'publicId': publicId,
      'privateId': privateId,
      'key': key,
    });
    return response['csv'] as String;
  }

  Future<void> _mutate(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    final serial = _deviceSerial;
    if (serial == null) {
      throw const OtpOperationException(
        'This YubiKey does not expose a serial number; OTP changes are disabled to prevent writing to a different key.',
      );
    }
    final snapshot = await _snapshot(method, {
      ...arguments,
      'expectedSerial': serial,
    });
    _deviceSerial = snapshot.serial;
    state = AsyncData(snapshot.state);
  }

  Future<_OtpSnapshot> _snapshot(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    try {
      final response = await _channel.invokeMethod<String>(method, arguments);
      if (response == null) {
        throw const FormatException('Missing iOS OTP response');
      }
      return _OtpSnapshot.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } on PlatformException catch (error) {
      throw error.decode();
    }
  }

  Future<Map<String, dynamic>> _compute(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    try {
      final response = await _channel.invokeMethod<String>(method, arguments);
      if (response == null) {
        throw const FormatException('Missing iOS OTP utility response');
      }
      return jsonDecode(response) as Map<String, dynamic>;
    } on PlatformException catch (error) {
      throw error.decode();
    }
  }
}
