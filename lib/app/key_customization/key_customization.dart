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

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging.dart';
import 'models.dart';

final _log = Logger('key_customization_manager');
const _prefKeyCustomizations = 'KEY_CUSTOMIZATIONS';

class KeyCustomizationManager {
  final SharedPreferences _prefs;
  final Map<String, KeyCustomization> _customizations;

  KeyCustomizationManager(this._prefs)
      : _customizations =
            readCustomizations(_prefs.getString(_prefKeyCustomizations));

  static Map<String, KeyCustomization> readCustomizations(String? pref) {
    if (pref == null) {
      return {};
    }

    try {
      final retval = <String, KeyCustomization>{};
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

  KeyCustomization? get(String? serial) {
    _log.debug('Getting key customization for $serial');
    return _customizations[serial];
  }

  void set({required String serial, String? name, Color? color}) {
    _log.debug('Setting key customization for $serial: $name, $color');
    if (name == null && color == null) {
      // remove this customization
      _customizations.removeWhere((key, value) => key == serial);
    } else {
      _customizations[serial] =
          KeyCustomization(serial: serial, name: name, color: color);
    }
  }

  Future<void> write() async {
    await _prefs.setString(
        _prefKeyCustomizations, json.encode(_customizations.values.toList()));
  }
}
