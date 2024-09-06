/*
 * Copyright (C) 2024 Yubico.
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

import 'tap_request_dialog.dart';

class MethodChannelNotifier extends Notifier<void> {
  final MethodChannel _channel;

  MethodChannelNotifier(this._channel);

  @override
  void build() {}

  Future<dynamic> invoke(String name,
      [Map<String, dynamic> params = const {}]) async {
    final result = await _channel.invokeMethod(name, params['callArgs']);
    await ref.read(androidDialogProvider.notifier).waitForDialogClosed();
    return result;
  }
}
