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

import 'dart:convert';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/state.dart';
import '../logging.dart';
import 'models.dart';

final keyCustomizationManagerProvider =
    StateNotifierProvider<KeyCustomizationNotifier, Map<int, KeyCustomization>>(
        (ref) => KeyCustomizationNotifier(ref.watch(prefProvider)));

final _log = Logger('key_customization_manager');

class KeyCustomizationNotifier
    extends StateNotifier<Map<int, KeyCustomization>> {
  static const _prefKeyCustomizations = 'KEY_CUSTOMIZATIONS';
  final SharedPreferences _prefs;

  KeyCustomizationNotifier(this._prefs)
      : super(_readCustomizations(_prefs.getString(_prefKeyCustomizations)));

  static Map<int, KeyCustomization> _readCustomizations(String? pref) {
    if (pref == null) {
      return {};
    }

    try {
      final retval = <int, KeyCustomization>{};
      for (var element in json.decode(pref)) {
        final keyCustomization = KeyCustomization.fromJson(element);
        retval[keyCustomization.serial] = keyCustomization;
      }
      return retval;
    } catch (e) {
      _log.error('Failure reading customizations: $e');
      return {};
    }
  }

  KeyCustomization? get(int serial) {
    _log.debug('Getting key customization for $serial');
    return state[serial];
  }

  Future<void> set({required int serial, String? name, Color? color}) async {
    _log.debug('Setting key customization for $serial: $name, $color');
    if (name == null && color == null) {
      // remove this customization
      state = {...state..remove(serial)};
    } else {
      state = {
        ...state
          ..[serial] =
              KeyCustomization(serial: serial, name: name, color: color)
      };
    }
    await _prefs.setString(
        _prefKeyCustomizations, json.encode(state.values.toList()));
  }
}
