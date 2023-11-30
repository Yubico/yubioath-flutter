/*
 * Copyright (C) 2022-2023 Yubico.
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

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import 'state.dart';

const appMethodsChannel = MethodChannel('app.methods');

Future<bool> getHasCamera() async {
  return await appMethodsChannel.invokeMethod('hasCamera');
}

Future<bool> getHasNfc() async {
  return await appMethodsChannel.invokeMethod('hasNfc');
}

Future<bool> isNfcEnabled() async {
  return await appMethodsChannel.invokeMethod('isNfcEnabled');
}

/// The next onPause/onResume lifecycle event will not stop and start
/// USB/NFC discovery which will preserve the current YubiKey connection.
///
/// This function should be called before showing system dialogs, such as
/// native file picker or permission request dialogs.
/// The state automatically resets during onResume call.
Future<void> preserveConnectedDeviceWhenPaused() async {
  await appMethodsChannel.invokeMethod('preserveConnectionOnPause');
}

Future<void> openNfcSettings() async {
  await appMethodsChannel.invokeMethod('openNfcSettings');
}

Future<int> getAndroidSdkVersion() async {
  return await appMethodsChannel.invokeMethod('getAndroidSdkVersion');
}

Future<void> setPrimaryClip(String toClipboard, bool isSensitive) async {
  await appMethodsChannel.invokeMethod('setPrimaryClip',
      {'toClipboard': toClipboard, 'isSensitive': isSensitive});
}

void setupAppMethodsChannel(WidgetRef ref) {
  appMethodsChannel.setMethodCallHandler((call) async {
    final args = jsonDecode(call.arguments);
    switch (call.method) {
      case 'nfcAdapterStateChanged':
        {
          var nfcEnabled = args['nfcEnabled'];
          ref.read(androidNfcStateProvider.notifier).setNfcEnabled(nfcEnabled);
          break;
        }
      case 'getString':
        {
          var arbKey = args['arbKey'] as String;

          var l10n = ref.read(l10nProvider);
          return switch (arbKey) {
            's_ndef_set_otp' => l10n.s_ndef_set_otp,
            's_ndef_set_password' => l10n.s_ndef_set_password,
            's_ndef_parse_failure' => l10n.s_ndef_parse_failure,
            's_ndef_set_clip_failure' => l10n.s_ndef_set_clip_failure,
            _ => arbKey
          };
        }
      default:
        throw PlatformException(
          code: 'NotImplemented',
          message: 'Method ${call.method} is not implemented',
        );
    }
  });
}
