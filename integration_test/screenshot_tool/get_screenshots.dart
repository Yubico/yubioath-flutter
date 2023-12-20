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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:integration_test/integration_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/desktop/init.dart';
import 'package:yubico_authenticator/fido/keys.dart';

var controller = ScreenshotController();

int screenshotNum = 0;

List<String> script = [];

String currentLocale = 'EN';
String screenshotOutputDir =
    Platform.environment['_YA_SCREENSHOT_OUTPUT'] ?? '.';

extension TakeScreenshot on WidgetTester {
  Future<void> tapAndTake(
    Key tap,
    String description, {
    int delayMs = 0,
  }) async {
    await tapKey(tap, Duration(milliseconds: delayMs));
    await takeScreenshot(description);
  }

  Future<void> tapKey(Key key, [Duration delay = Duration.zero]) async {
    await tap(find.byKey(key).hitTestable());
    if (delay != Duration.zero) {
      await pump(delay);
    }
    await pumpAndSettle();
  }

  Future<void> closeDialog() async {
    await tapAt(const Offset(0, 0));
    await pumpAndSettle();
  }

  Future<void> takeScreenshot(String description) async {
    await pump(const Duration(milliseconds: 100));

    var prefix = screenshotNum.toString().padLeft(5, '0');
    var screenshotDescription = '${testDescription}_${prefix}_$description'
        .replaceAll(' ', '_')
        .replaceAll('`', '');

    script.add('$screenshotNum: $testDescription $description');
    var fileName = '${currentLocale}_$screenshotDescription.png';

    await controller.captureAndSave(
      screenshotOutputDir,
      fileName: fileName,
      delay: const Duration(milliseconds: 30),
    );

    screenshotNum++;
  }
}

class ScreenshotWrappedApp extends StatelessWidget {
  final Widget child;

  const ScreenshotWrappedApp(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return Screenshot(controller: controller, child: child);
  }
}

@isTest
void startScreenshotSession(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Map startUpParams = const {},
  dynamic tags,
}) {
  testWidgets(description, skip: skip, (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenshotWrappedApp(await initialize([])),
      duration: const Duration(milliseconds: 1000),
    );
    await callback(tester);
  }, tags: tags);
}

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  screenshotNum = 0;

  tearDown(() async {
    await File(
      '$screenshotOutputDir/${currentLocale}_script.txt',
    ).writeAsString(script.join('\n'));
  });

  startScreenshotSession('Initialization', (t) async {
    await t.takeScreenshot('Startup screen');
    await t.pumpAndSettle();
  });

  startScreenshotSession('About', (t) async {
    await t.tapAndTake(homeDrawer, 'Home view');
    await t.tapAndTake(helpDrawerIcon, 'Help Dialog');
    await t.tapAndTake(logChip, 'Click `Copy log` feedback', delayMs: 2000);
    await t.tapAndTake(
      diagnosticsChip,
      'Click `Diagnostics` feedback',
      delayMs: 2000,
    );
    await t.tapAndTake(logLevelsChip, 'Click `Log levels`', delayMs: 500);
    await t.closeDialog();
  });

  startScreenshotSession('Settings', (t) async {
    await t.tapAndTake(settingDrawerIcon, 'Setting Dialog');
    await t.tapAndTake(themeModeSetting, 'Available themes');
    await t.closeDialog();
  });

  startScreenshotSession('WebAuthn', (t) async {
    await t.tapAndTake(fidoPasskeysAppDrawer, 'FIDO view');
    await t.tapAndTake(managePinAction, 'Manage PIN dialog');
    await t.enterText(find.byKey(newPin), '1234567');
    await t.pumpAndSettle();
    // the following actions are just examples, it is not possible to tap buttons
    // when the pin's don't match
    // write something in the other fields to enable the save button
    await t.enterText(find.byKey(confirmPin), '11111111');
    await t.pumpAndSettle();
    await t.tapAndTake(saveButton, 'Wrong PIN');
    await t.enterText(find.byKey(newPin), '111');
    await t.pumpAndSettle();
    await t.enterText(find.byKey(confirmPin), '111');
    await t.pumpAndSettle();
    await t.tapAndTake(saveButton, 'Short new PIN');

    // cancel the dialog
    await t.tapKey(cancelButton);
    await t.closeDialog();
  });
}
