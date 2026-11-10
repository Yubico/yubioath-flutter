/*
 * Copyright (C) 2022-2026 Yubico.
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

/// Whether this app handles `https://my.yubico.com` links.
///
/// From Android 16, every NFC tap action depends on it. Builds signed with
/// Yubico's release key are verified automatically through Digital Asset
/// Links; any other build has to be allowed by hand under "Open by default".
///
/// Mirrors `DomainVerificationHelper.Status` in Kotlin.
enum DomainVerificationStatus {
  /// Not applicable: Android older than 16, or the state could not be read.
  unsupported,

  /// Verified through Digital Asset Links.
  verified,

  /// Allowed by the user under "Open by default".
  selected,

  /// Not handled: NFC tap actions do nothing until the user allows it.
  none,
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

/// Opens the app's "Open by default" settings page. Returns false if no
/// settings screen could be started.
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

/// Maps an `appContextChanged` payload to the [Section] it selects.
///
/// [appContext] is an `OperationContext` value from `MainViewModel.kt`, which
/// numbers its entries to match the declaration order of [Section]. The two
/// enums are a wire contract and must be changed together — inserting a
/// [Section] in the middle shifts every later index and silently reroutes those
/// contexts here. `OperationContextTest.kt` pins the Kotlin values;
/// `app_methods_test.dart` mirrors the ones that reach Dart and asserts that the
/// two enums still line up.
///
/// Contexts that Android never reports as a section — `FidoU2f` (2), `OpenPgp`,
/// `HsmAuth` and `Management`, none of which are in `supportedSectionsProvider`
/// — fall back to [Section.home], as does any unknown value.
Section sectionFromAppContext(int appContext) => switch (appContext) {
  0 => Section.home,
  1 => Section.accounts,
  3 => Section.fingerprints,
  4 => Section.passkeys,
  5 => Section.certificates,
  6 => Section.slots,
  7 => Section.settings,
  _ => Section.home,
};

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
          var section = sectionFromAppContext(appContext);

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
