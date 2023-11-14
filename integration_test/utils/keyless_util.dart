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
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/management/views/keys.dart';

import 'android/util.dart' as android_test_util;
import 'desktop/util.dart' as desktop_test_util;

/// information about YubiKey as seen by the app
String? yubiKeyName;
String? yubiKeyFirmware;
String? yubiKeySerialNumber;
bool collectedYubiKeyInformation = false;

/// TODO: clean up this monster of appTestKeyLess
extension AppWidgetTester on WidgetTester {
  /// waits up to [timeOutSec] seconds evaluating whether [Finder] f is
  /// visible
  Future<Finder> waitForFinder(Finder f, [int timeOutSec = 20]) async {
    int delayMs = 500;
    int elapsedTime = 0;

    var evaluated = f.evaluate();
    while (evaluated.isEmpty && elapsedTime < timeOutSec * 1000) {
      await pump(Duration(milliseconds: delayMs));
      elapsedTime += delayMs;
      evaluated = f.evaluate();
    }

    if (evaluated.isEmpty) {
      testLog(false, 'Failed to find ${f.description} in $timeOutSec seconds.');
    }

    return f;
  }

  Finder findActionIconButton() {
    return find.byKey(actionsIconButtonKey).hitTestable();
  }

  Future<void> tapActionIconButton() async {
    await tap(findActionIconButton());
    await pump(const Duration(milliseconds: 500));
  }

  Future<void> tapTopLeftCorner() async {
    await tapAt(const Offset(0, 0));
    await pump(const Duration(milliseconds: 500));
  }

  /// Drawer helpers
  bool hasDrawer() => scaffoldGlobalKey.currentState!.hasDrawer;

  /// Open drawer
  Future<void> openDrawer() async {
    if (hasDrawer()) {
      scaffoldGlobalKey.currentState!.openDrawer();
      await pump(const Duration(milliseconds: 500));
    }
  }

  /// Close drawer
  Future<void> closeDrawer() async {
    if (hasDrawer()) {
      scaffoldGlobalKey.currentState!.closeDrawer();
      await pump(const Duration(milliseconds: 500));
    }
  }

  /// Is drawer opened?
  /// If there is no drawer say it is open (all items are available)
  bool isDrawerOpened() =>
      hasDrawer() == false || scaffoldGlobalKey.currentState!.isDrawerOpen;

  /// Management screen
  Future<void> openManagementScreen() async {
    if (!isDrawerOpened()) {
      await openDrawer();
    }

    await tap(find.byKey(managementAppDrawer).hitTestable());
    await pump(const Duration(milliseconds: 500));

    expect(find.byKey(screenKey), findsOneWidget);
  }

  Future<void> startUp([Map<dynamic, dynamic> startUpParams = const {}]) async {
    var result = isAndroid == true
        ? await android_test_util.startUp(this, startUpParams)
        : await desktop_test_util.startUp(this, startUpParams);
    return result;
  }

  void testLog(bool quiet, String message) {
    if (!quiet) {
      printToConsole(message);
    }
  }
}

@isTest
void appTestKeyless(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Map startUpParams = const {},
}) {
  testWidgets(description, (WidgetTester tester) async {
    await tester.startUp(startUpParams);
    await callback(tester);
  });
}
