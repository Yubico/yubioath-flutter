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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/state.dart';
import 'biometrics_methods.dart';

final useBiometricProtection =
    StateNotifierProvider<UseBiometricProtectionNotifier, bool>(
        (ref) => UseBiometricProtectionNotifier(ref.watch(prefProvider)));

class UseBiometricProtectionNotifier extends StateNotifier<bool> {
  static const _prefUseBiometrics = 'prefUseBiometrics';
  final SharedPreferences _prefs;

  UseBiometricProtectionNotifier(this._prefs)
      : super(_prefs.getBool(_prefUseBiometrics) ?? false);

  void refresh() {
    state = _prefs.getBool(_prefUseBiometrics) ?? false;
  }

  Future<void> setUseBiometrics(bool value) async {
    if (state != value) {
      state = value;
      await _prefs.setBool(_prefUseBiometrics, value);
      await callSetUseBiometrics(state);
    }
  }
}

final isBiometricProtectionAvailable =
    StateNotifierProvider<BiometricProtectionNotifier, bool>(
        (ref) => BiometricProtectionNotifier());

class BiometricProtectionNotifier extends StateNotifier<bool> {
  BiometricProtectionNotifier() : super(false);

  void setEnabled(bool value) {
    state = value;
  }
}
