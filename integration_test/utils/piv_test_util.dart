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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/piv/keys.dart';

import 'test_util.dart';

extension PIVFunctions on WidgetTester {
  static const ett = 'firstpin';
  static const tva = 'lockpinn';

  /// Open the PIV Configuration
  Future<void> configurePiv() async {
    await tap(find.byKey(pivAppDrawer).hitTestable());
    await shortWait();
    await tap(find.byKey(actionsIconButtonKey).hitTestable());
    await shortWait();
  }

  Future<void> pinView() async {
    await tap(find.byKey(pivAppDrawer).hitTestable());
    await shortWait();
    await tap(find.byKey(actionsIconButtonKey).hitTestable());
    await shortWait();
    await tap(find.byKey(managePinAction));
    await shortWait();
  }

  Future<void> pukView() async {
    await tap(find.byKey(pivAppDrawer).hitTestable());
    await shortWait();
    await tap(find.byKey(actionsIconButtonKey).hitTestable());
    await shortWait();
    await tap(find.byKey(managePukAction));
    await shortWait();
  }

  Future<void> managementKeyView() async {
    await tap(find.byKey(pivAppDrawer).hitTestable());
    await shortWait();
    await tap(find.byKey(actionsIconButtonKey).hitTestable());
    await shortWait();
    await tap(find.byKey(manageManagementKeyAction));
    await shortWait();
  }

  Future<void> pivFirst() async {
    // when in pin or puk view, remove factorypin/puk
    await enterText(find.byKey(newPinPukField), ett);
    await shortWait();
    await enterText(find.byKey(confirmPinPukField), ett);
    await shortWait();
    await tap(find.byKey(saveButton).hitTestable());
    await shortWait();
  }

  Future<void> pivLock() async {
    // when in pin or puk view this will lock it
    for (var i = 0; i < 3; i += 1) {
      await enterText(find.byKey(pinPukField), tva);
      await shortWait();
      await enterText(find.byKey(newPinPukField), tva);
      await shortWait();
      await enterText(find.byKey(confirmPinPukField), tva);
      await shortWait();
      await tap(find.byKey(saveButton).hitTestable());
      await shortWait();
    }
    await sendKeyEvent(LogicalKeyboardKey.escape);
    await shortWait();
  }

  /// Factory reset Piv application
  Future<void> resetPiv() async {
    final targetKey = approvedKeys[0]; // only reset approved keys!

    /// 1. make sure we are using approved key
    await switchToKey(targetKey);
    await shortWait();

    /// 2. open the key menu
    await tapPopupMenu(targetKey);
    await shortWait();
    await tap(find.byKey(yubikeyFactoryResetMenuButton).hitTestable());
    await longWait();

    /// 3. then toggle 'Piv' in the 'Factory reset' reset_dialog.dart
    await tap(find.byKey(factoryResetPickResetPiv));
    await longWait();

    /// 4. Click reset TextButton: done
    await tap(find.byKey(factoryResetReset));
    await shortWait();

    // 5. Verify Resetedness
    // /// TODO: this expect algorithm is flaky
    // expect(find.byWidgetPredicate((widget) {
    //   if (widget is AppListItem) {
    //     final AppListItem textWidget = widget;
    //     if ((textWidget.key == appListItem9a ||
    //             textWidget.key == appListItem9c ||
    //             textWidget.key == appListItem9d ||
    //             textWidget.key == appListItem9e) &&
    //         textWidget.subtitle == 'No certificate loaded') {
    //       return true;
    //     }
    //   }
    //   return false;
    // }), findsNWidgets(4));
  }
}
