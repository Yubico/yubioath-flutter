/*
 * Copyright (C) 2022 Yubico.
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/views/app_list_item.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;
import 'package:yubico_authenticator/oath/keys.dart' as keys;
import 'package:yubico_authenticator/oath/views/account_list.dart';
import 'package:yubico_authenticator/oath/views/account_view.dart';
import 'package:yubico_authenticator/piv/keys.dart';

import 'android/util.dart';
import '../utils/test_util.dart';

class Account {
  final String? issuer;
  final String name;
  final String secret;

  const Account({
    this.issuer,
    this.name = '',
    this.secret = 'abcdefghabcdefgh',
  });

  @override
  String toString() => '$issuer/$name';
}

extension PIVFunctions on WidgetTester {
  /// Resets the PIV application of a key
  Future<void> resetPiv() async {
    // 1. open PIV view
    var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
    await tap(pivDrawerButton);
    await pump(const Duration(milliseconds: 500));
    // 1.3. Reset PIV
    // 1. Click Configure JubiKey
    await tap(find.byKey(actionsIconButtonKey).hitTestable());
    await pump(const Duration(milliseconds: 500));
    // 2. Click Reset PIV
    await tap(find.byKey(resetAction).hitTestable());
    await pump(const Duration(milliseconds: 500));
    // 3. Click Reset
    await tap(find.byKey(resetButton).hitTestable());
    await pump(const Duration(milliseconds: 500));
    // 4. Verify Resetedness
    expect(find.byWidgetPredicate((widget) {
      if (widget is AppListItem) {
        final AppListItem textWidget = widget;
        if ((textWidget.key == appListItem9a ||
                textWidget.key == appListItem9c ||
                textWidget.key == appListItem9d ||
                textWidget.key == appListItem9e) &&
            textWidget.subtitle == 'No certificate loaded') {
          return true;
        }
      }
      return false;
    }), findsNWidgets(4));
  }
}
