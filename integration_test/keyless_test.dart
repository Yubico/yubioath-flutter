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

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';

import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Settings', () {
    appTest('Clickety settings', (WidgetTester tester) async {
      var settingDrawerButton = find.byKey(settingDrawerIcon).hitTestable();
      await tester.tap(settingDrawerButton);
      await tester.longWait();
    });
  });
  group('Help and about', () {
    var helpDrawerButton = find.byKey(helpDrawerIcon).hitTestable();

    appTest('Check Licenses view', (WidgetTester tester) async {
      await tester.tap(helpDrawerButton);
      await tester.shortWait();
      var licensesButtonText = find.byKey(licensesButton).hitTestable();
      await tester.tap(licensesButtonText);
      await tester.shortWait();

      /// TODO: do want to click all licenses and see that they show?
    });
    group('Opening of URLs', () {
      appTest('TOS link', (WidgetTester tester) async {
        await tester.tap(helpDrawerButton);
        await tester.longWait();
        await tester.tap(find.byKey(tosButton).hitTestable());
        await tester.longWait();
      });
      appTest('Privacy link', (WidgetTester tester) async {
        await tester.tap(helpDrawerButton);
        await tester.longWait();
        await tester.tap(find.byKey(privacyButton).hitTestable());
        await tester.longWait();
      });
      appTest('Feedback link', (WidgetTester tester) async {
        await tester.tap(helpDrawerButton);
        await tester.longWait();
        await tester.tap(find.byKey(feedbackButton).hitTestable());
        await tester.longWait();
      });
      appTest('Help link', (WidgetTester tester) async {
        await tester.tap(helpDrawerButton);
        await tester.longWait();
        await tester.tap(find.byKey(helpButton).hitTestable());
        await tester.longWait();
      });
    });
    group('Desktop logging', () {
      appTest('Diagnostics Button', (WidgetTester tester) async {
        await tester.tap(helpDrawerButton);
        await tester.shortWait();
      });
      appTest('Log button', (WidgetTester tester) async {
        await tester.tap(helpDrawerButton);
        await tester.shortWait();
      });
    });
  });
}
