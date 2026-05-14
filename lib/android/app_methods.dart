/*
 * Copyright (C) 2022-2025 Yubico.
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

import '../app/models.dart';
import '../theme.dart';
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

/// System-level association status of the my.yubico.com domain with this app.
///
/// On Android 16 (API 36+), NFC taps on a YubiKey route through ACTION_VIEW
/// for https://my.yubico.com instead of NDEF_DISCOVERED. Unless the domain is
/// auto-verified via Digital Asset Links or the user enabled "Open by default"
/// for the app, ACTION_VIEW falls back to a browser.
enum DomainVerificationStatus {
  /// Pre-Android 12, or API not available.
  unsupported,

  /// Domain is auto-verified — no user action required.
  verified,

  /// User has opted the app in — no user action required.
  selected,

  /// No association — the user should be prompted to enable it.
  none;

  bool get isAssociated => this == verified || this == selected;
}

Future<DomainVerificationStatus> getDomainVerificationStatus() async {
  final value = await appMethodsChannel.invokeMethod<String>(
    'getDomainVerificationStatus',
  );
  return switch (value) {
    'verified' => DomainVerificationStatus.verified,
    'selected' => DomainVerificationStatus.selected,
    'none' => DomainVerificationStatus.none,
    _ => DomainVerificationStatus.unsupported,
  };
}

Future<bool> openDomainVerificationSettings() async {
  final result = await appMethodsChannel.invokeMethod<bool>(
    'openDomainVerificationSettings',
  );
  return result ?? false;
}

Future<int> getAndroidSdkVersion() async {
  return await appMethodsChannel.invokeMethod('getAndroidSdkVersion');
}

Future<bool> getAndroidIsArc() async {
  return await appMethodsChannel.invokeMethod('isArc');
}

Future<Color> getPrimaryColor() async {
  final value = await appMethodsChannel.invokeMethod('getPrimaryColor');
  return value != null ? Color(value) : defaultPrimaryColor;
}

Future<void> setPrimaryClip(String toClipboard, bool isSensitive) async {
  await appMethodsChannel.invokeMethod('setPrimaryClip', {
    'toClipboard': toClipboard,
    'isSensitive': isSensitive,
  });
}

void setupAppMethodsChannel(WidgetRef ref) {
  appMethodsChannel.setMethodCallHandler((call) async {
    final args = jsonDecode(call.arguments);
    switch (call.method) {
      case 'nfcAdapterStateChanged':
        {
          var enabled = args['enabled'];
          ref.read(androidNfcAdapterState.notifier).enable(enabled);
          break;
        }
      case 'nfcStateChanged':
        {
          var nfcState = args['state'];
          ref.read(androidNfcState.notifier).set(nfcState);
          break;
        }
      case 'appContextChanged':
        {
          var appContext = args['appContext'];
          var section = switch (appContext) {
            0 => Section.home,
            1 => Section.accounts,
            3 => Section.fingerprints,
            4 => Section.passkeys,
            7 => Section.settings,
            _ => Section.home,
          };

          // use Android specific notifier to set the current section
          // don't notify, as we just received the section
          ref
              .read(androidCurrentSectionNotifierProvider)
              .setCurrentSection(section, notify: false);
          break;
        }
      default:
        throw PlatformException(
          code: 'NotImplemented',
          message: 'Method ${call.method} is not implemented',
        );
    }
  });
}
