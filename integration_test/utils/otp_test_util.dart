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

import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/otp/keys.dart';
import 'package:yubico_authenticator/otp/models.dart';

import 'test_util.dart';

extension OtpFunctions on WidgetTester {
  /// Opens the menu of specific OTP Slot, either by tapping the button or
  /// by tapping the list item
  Future<void> openSlotMenu(SlotId slotId) async {
    final menuButtonFinder = find.byKey(getOpenMenuButtonKey(slotId));
    if (menuButtonFinder.evaluate().isNotEmpty) {
      await tap(menuButtonFinder);
    } else {
      await tap(find.byKey(getAppListItemKey(slotId)));
    }
    await longWait();
  }

  /// tap the Swap Slots button - either first open the action menu,
  /// or try to find the button on visible screen
  Future<void> tapSwapSlotsButton() async {
    final actionButtonFinder = find.byKey(actionsIconButtonKey);
    if (actionButtonFinder.evaluate().isNotEmpty) {
      await tap(actionButtonFinder);
      await shortWait();
    }

    await tap(find.byKey(swapSlots).hitTestable());
    await longWait();
  }
}
