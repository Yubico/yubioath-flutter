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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/biometrics/state.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../../app/message.dart';
import '../../app/state.dart';
import 'views/biometrics_info_dialog.dart';

final _log = Logger('app.methods');

const biometricsMethodsChannel = MethodChannel('biometrics.methods');

Future<void> callSetUseBiometrics(bool enabled) async {
  await biometricsMethodsChannel.invokeMethod('setUseBiometrics', enabled);
}

void refreshBiometricProtectionAvailability(ref) {
  // get current preference value
  ref.read(useBiometricProtection.notifier).refresh();

  getHasBiometricsSupport().then((value) {
    ref.read(isBiometricProtectionAvailable.notifier).setEnabled(value);

    if (!value) {
      // disable use of biometrics if not supported in the system
      ref.read(useBiometricProtection.notifier).setUseBiometrics(value);
      // update preference value
      ref.read(useBiometricProtection.notifier).refresh();
    }
  });
}

Future<bool> getHasBiometricsSupport() async {
  return await biometricsMethodsChannel.invokeMethod('hasBiometricsSupport');
}

void setupBiometricsMethodsChannel(WidgetRef ref) {
  biometricsMethodsChannel.setMethodCallHandler((call) async {
    final args = jsonDecode(call.arguments);
    var dialogVariantArg = args['variant'];
    BiometricsDialogVariant variant = dialogVariantArg == 1
        ? BiometricsDialogVariant.invalidated
        : BiometricsDialogVariant.disabled;
    switch (call.method) {
      case 'showBiometricsDialog':
        {
          _log.debug('showBiometricsDialog');
          await ref.read(withContextProvider)((context) => showBlurDialog(
                context: context,
                routeSettings: const RouteSettings(
                    name: 'oath_biometric_authentication_info_dialog'),
                builder: (context) => BiometricsInfoDialog(variant),
              ));
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
