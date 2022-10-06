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
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/oath/views/oath_screen.dart';

import 'test_util.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Reset Key', skip: 'Not reviewed', () {
    testWidgets('Reset OATH', (WidgetTester tester) async {
      /// this test works if there is an oath credential on the key
      /// else it will fail on tap 'Authenticator' widget
      await tester.startUp({});
      await tester.pump(const Duration(milliseconds: 500));

      /// QUESTION: I want to click the DrawerItem named 'WebAuthn' | 'Authenticator'
      ///       await tester.tap(find.byType(DrawerItem.titleText == 'WebAuthn'));
      /// which can be found in main_drawer.dart, how do I make sure I call the right
      /// thing here?
      await tester.tap(find.text('Authenticator'));

      /// get to correct widget
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(FloatingActionButton));

      /// click the Setup Button
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset OATH'));

      /// click reset oath
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset'));

      /// confirm
      await tester.pump(const Duration(milliseconds: 300));

      /// I don't know why the expects fail?
      /// The following should report 'No accounts' in Authenticator widget.
      /// Maybe through find.bySemanticsLabel or byTooltip?

/*      expect(find.byType(OathScreen), findsNothing,
          reason: 'OATH successfully reset.');*/

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Reset FIDO', skip: true, (WidgetTester tester) async {
      /// this test works if there is an oath credential on the key
      /// else it will fail on tap 'Authenticator' widget
      await tester.startUp({});
      await tester.pump(const Duration(milliseconds: 500));

      /// QUESTION: I want to click the DrawerItem named 'WebAuthn' | 'Authenticator'
      ///       await tester.tap(find.byType(DrawerItem.titleText == 'WebAuthn'));
      /// which can be found in main_drawer.dart, how do I make sure I call the right
      /// thing here?
      await tester.tap(find.text('WebAuthn'));

      /// get to correct widget
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(FloatingActionButton));

      /// click the Setup Button
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset FIDO'));

      /// click reset oath
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset'));

      /// confirm
      await tester.pump(const Duration(milliseconds: 300));

      /// I don't know why the expects fail?
      /// The following should report 'No discoverable accounts' in fido widget.
      /// Maybe through find.bySemanticsLabel or byTooltip?
      ///
      /// For this reset you require the yubikey-dance, giving user 30s for this
      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(milliseconds: 30000));

      /// The following should report the success, if there are no accounts.
      expect(find.byType(OathScreen), findsNothing, reason: 'FIDO successfully reset.');

      await tester.pump(const Duration(seconds: 3));
    });
  });
}
