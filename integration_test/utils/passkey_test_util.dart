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

import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';

import 'test_util.dart';

const fido2DanceLongWaitMs = 15000;

extension Fido2Functions on WidgetTester {
  Future<void> fido2DanceWait() async {
    await pump(const Duration(milliseconds: fido2DanceLongWaitMs));
  }

  /// Open the PIV Configuration
  Future<void> configurePasskey() async {
    // 1. open PIV view
    await tap(find.byKey(fidoPasskeysAppDrawer).hitTestable());
    await shortWait();
    await tap(find.byKey(actionsIconButtonKey).hitTestable());
    await shortWait();
  }

  /// Factory reset FIDO application
  Future<void> resetFido2() async {
    final targetKey = approvedKeys[0]; // only reset approved keys!

    /// 1. make sure we are using approved key
    await switchToKey(targetKey);
    await shortWait();

    /// 2. open the home view
    await tap(find.byKey(homeDrawer).hitTestable());
    await shortWait();

    /// 3. open menu
    await tap(find.byKey(actionsIconButtonKey).hitTestable());
    await shortWait();
    await tap(find.byKey(yubikeyFactoryResetMenuButton));
    await shortWait();

    /// 4. then toggle 'Piv' in the 'Factory reset' reset_dialog.dart
    await tap(find.byKey(factoryResetPickResetFido2));
    await longWait();

    /// 5. Click reset TextButton: done
    await tap(find.byKey(factoryResetReset));
    await fido2DanceWait();

    /// 6. Click the close button
    await tap(find.text('Close').hitTestable());
    await shortWait();
  }

  // /// Factory reset Fido2 application
  // Future<void> resetFido2() async {
  //   final targetKey = approvedKeys[0]; // only reset approved keys!
  //
  //   /// 1. make sure we are using approved key
  //   await switchToKey(targetKey);
  //   await shortWait();
  //
  //   /// 2. open the key menu
  //   await tapPopupMenu(targetKey);
  //   await shortWait();
  //   await tap(find.byKey(yubikeyFactoryResetMenuButton).hitTestable());
  //   await longWait();
  //
  //   /// 3. then toggle 'Fido2' in the 'Factory reset' reset_dialog.dart
  //   await tap(find.byKey(factoryResetPickResetFido2));
  //   await longWait();
  //
  //   /// 4. Click reset TextButton: done
  //   await tap(find.byKey(factoryResetReset));
  //   await fido2DanceWait();
  //
  //   /// 5. Click the 'Close' button
  //   await tap(find.text('Close').hitTestable());
  //   await shortWait();
  //
  //   /// TODO 6. Verify Resetedness
  // }
}
