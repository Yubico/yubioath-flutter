/*
 * Copyright (C) 2024-2026 Yubico.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../exception/app_exception.dart';
import '../../method_channel_errors.dart';
import 'nfc_overlay.dart';

class MethodChannelNotifier extends Notifier<void> {
  final MethodChannel _channel;

  /// When true, the native side reports errors in the shared error format and
  /// [invoke] throws [AppException] instead of [PlatformException].
  ///
  /// Apps opt in as they are moved to platform-agnostic errors; once all have,
  /// this becomes the only behavior.
  final bool throwAppExceptions;

  MethodChannelNotifier(this._channel, {this.throwAppExceptions = false});

  @override
  void build() {}

  Future<dynamic> invoke(
    String name, [
    Map<String, dynamic> args = const {},
  ]) async {
    try {
      final result = await _channel.invokeMethod(name, args);
      await ref.read(nfcOverlay.notifier).waitForHide();
      return result;
    } on PlatformException catch (e) {
      if (!throwAppExceptions) rethrow;
      throw e.toAppException();
    }
  }
}
