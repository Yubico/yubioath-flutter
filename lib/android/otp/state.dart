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
import '../../exception/no_data_exception.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../otp/models.dart';
import '../../otp/state.dart';
import '../overlay/nfc/method_channel_notifier.dart' show MethodChannelNotifier;

final _log = Logger('android.otp.state');

const _methodsChannel = MethodChannel('android.otp.methods');

class AndroidOtpStateNotifier extends OtpStateNotifier {
  final _events = const EventChannel('android.otp.state');
  late StreamSubscription _sub;
  late OtpMethodChannelNotifier otp = ref.watch(_otpMethodsProvider.notifier);

  AndroidOtpStateNotifier(super.devicePath);

  @override
  FutureOr<OtpState> build() async {
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final json = jsonDecode(event);
        if (json == null) {
          state = AsyncValue.error(const NoDataException(), StackTrace.current);
        } else if (json == 'loading') {
          state = const AsyncValue.loading();
        } else {
          state = AsyncValue.data(OtpState.fromJson(json));
        }
      },
      onError: (err, stackTrace) {
        state = AsyncValue.error(err, stackTrace);
      },
    );

    ref.onDispose(_sub.cancel);

    return Completer<OtpState>().future;
  }

  // The slot state is pushed back over the event channel by OtpManager once the
  // operation completes, so none of the mutating methods invalidate themselves.

  @override
  Future<void> swapSlots() async {
    try {
      await otp.invoke('swapSlots');
    } on PlatformException catch (pe) {
      throw pe.decode();
    }
  }

  @override
  Future<void> configureSlot(
    SlotId slot, {
    required SlotConfiguration configuration,
    String? accessCode,
  }) async {
    try {
      await otp.invoke('configureSlot', {
        'slot': slot.id,
        'configuration': configuration.toJson(),
        'accessCode': accessCode,
      });
    } on PlatformException catch (pe) {
      throw pe.decode();
    }
  }

  @override
  Future<void> deleteSlot(SlotId slot, {String? accessCode}) async {
    try {
      await otp.invoke('deleteSlot', {
        'slot': slot.id,
        'accessCode': accessCode,
      });
    } on PlatformException catch (pe) {
      throw pe.decode();
    }
  }

  @override
  Future<String> generateStaticPassword(int length, String layout) async {
    final result = await _compute('generateStaticPassword', {
      'length': length,
      'layout': layout,
    });
    return result['password'];
  }

  @override
  Future<String> modhexEncodeSerial(int serial) async {
    final result = await _compute('modhexEncodeSerial', {'serial': serial});
    return result['encoded'];
  }

  @override
  Future<Map<String, KeyboardLayout>> getKeyboardLayouts() async {
    final result = await _compute('getKeyboardLayouts');
    return result.map(
      (key, value) => MapEntry(
        key,
        KeyboardLayout(
          name: key,
          description: key,
          characters: (value as List<dynamic>).cast<String>(),
          variants: const {},
        ),
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
    final result = await _compute('formatYubiOtpCsv', {
      'serial': serial,
      'publicId': publicId,
      'privateId': privateId,
      'key': key,
    });
    return result['csv'];
  }

  /// Invokes one of the methods which are computed without a YubiKey.
  ///
  /// These bypass [OtpMethodChannelNotifier] on purpose: they never talk to a key, so waiting
  /// for the NFC overlay to hide would only add latency while the user is still filling in a
  /// dialog.
  Future<Map<String, dynamic>> _compute(
    String method, [
    Map<String, dynamic> args = const {},
  ]) async {
    try {
      return jsonDecode(await _methodsChannel.invokeMethod(method, args));
    } on PlatformException catch (pe) {
      _log.error('Failed to invoke $method', pe);
      throw pe.decode();
    }
  }
}

final _otpMethodsProvider = NotifierProvider<OtpMethodChannelNotifier, void>(
  () => OtpMethodChannelNotifier(),
);

class OtpMethodChannelNotifier extends MethodChannelNotifier {
  OtpMethodChannelNotifier() : super(_methodsChannel);
}
