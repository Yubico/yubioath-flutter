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

  MethodChannelNotifier(this._channel);

  @override
  void build() {}

  /// Calls [name] on the native side. The native side reports failures in the
  /// shared error format, so they are thrown as [AppException].
  Future<dynamic> invoke(
    String name, [
    Map<String, dynamic> args = const {},
  ]) async {
    try {
      final result = await _channel.invokeMethod(name, args);
      await ref.read(nfcOverlay.notifier).waitForHide();
      return result;
    } on PlatformException catch (e) {
      // Let the NFC overlay finish its failure animation before the caller
      // reacts, the same way a successful call waits for it.
      await ref.read(nfcOverlay.notifier).waitForHide();
      throw e.toAppException();
    }
  }
}
