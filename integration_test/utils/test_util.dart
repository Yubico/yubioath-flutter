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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yubico_authenticator/app/views/device_picker.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/management/views/keys.dart';

import 'android/util.dart' as android_test_util;
import 'desktop/util.dart' as desktop_test_util;

const shortWaitMs = 200;
const longWaitMs = 500;
const ultraLongWaitMs = 5000;

class ConnectedKey {
  final String? name;
  final String? serialNumber;
  final String? firmware;

  const ConnectedKey(this.name, this.serialNumber, this.firmware);

  @override
  String toString() {
    return 'ConnectedYubiKey{name: $name, serialNumber: $serialNumber, firmware: $firmware}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectedKey &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          serialNumber == other.serialNumber &&
          firmware == other.firmware;

  @override
  int get hashCode => name.hashCode ^ serialNumber.hashCode ^ firmware.hashCode;
}

extension ConnectedKeyExt on List<ConnectedKey> {
  String serialNumbers() => where((e) => e.serialNumber != null)
      .map((e) => e.serialNumber!)
      .toList()
      .join(',');

  String prettyList() {
    var retval = '';
    if (this.isEmpty) {
      return 'No keys.';
    }
    for (final (index, connectedKey) in indexed) {
      retval += '${index + 1}: ${connectedKey.name} / '
          'SN: ${connectedKey.serialNumber} / '
          'FW: ${connectedKey.firmware}\n';
    }
    return retval;
  }
}

extension ListTileInfoExt on ListTile {
  ConnectedKey getKeyInfo() {
    final itemName = (title as Text).data;
    String? itemSerialNumber;
    String? itemFirmware;
    var subtitle = (this.subtitle as Text?)?.data;

    if (subtitle != null) {
      RegExpMatch? match =
          RegExp(r'S/N: (\d.*) F/W: (\d\.\d\.\d)').firstMatch(subtitle);
      if (match != null) {
        itemSerialNumber = match.group(1);
        itemFirmware = match.group(2);
      } else {
        match = RegExp(r'F/W: (\d\.\d\.\d)').firstMatch(subtitle);
        if (match != null) {
          itemFirmware = match.group(1);
        }
      }
    }

    return ConnectedKey(
      itemName,
      itemSerialNumber,
      itemFirmware,
    );
  }
}

/// contains information about connected YubiKeys approved for testing
final approvedKeys = <ConnectedKey>[];
bool collectedYubiKeyInformation = false;

extension AppWidgetTester on WidgetTester {
  Future<void> shortWait() async {
    await pump(const Duration(milliseconds: shortWaitMs));
  }

  Future<void> longWait() async {
    await pump(const Duration(milliseconds: longWaitMs));
  }

  Future<void> ultraLongWait() async {
    await pump(const Duration(milliseconds: ultraLongWaitMs));
  }

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
      testLog(false,
          'Found 0 ${f.describeMatch(Plurality.zero)} in $timeOutSec seconds.');
    }

    return f;
  }

  Finder findActionIconButton() {
    return find.byKey(actionsIconButtonKey).hitTestable();
  }

  Future<void> tapActionIconButton() async {
    final actionIconButtonFinder = findActionIconButton();
    if (actionIconButtonFinder.evaluate().isNotEmpty) {
      await tap(actionIconButtonFinder);
      await pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> tapTopLeftCorner() async {
    await tapAt(const Offset(0, 0));
    await longWait();
  }

  /// Drawer helpers
  bool hasDrawer() => scaffoldGlobalKey.currentState!.hasDrawer;

  /// Open drawer if not opened
  /// return open state
  Future<bool> openDrawer() async {
    bool isOpened = isDrawerOpened();
    if (hasDrawer() && !isOpened) {
      scaffoldGlobalKey.currentState!.openDrawer();
      await pump(const Duration(milliseconds: 500));
    }
    return isOpened;
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

  /// Tap a app button in the drawer
  /// If the drawer is closed, it is opened first
  Future<void> tapAppDrawerButton(Key appKey) async {
    if (hasDrawer() && !isDrawerOpened()) {
      await openDrawer();
    }

    var appButtonFinder = find.byKey(appKey).hitTestable();
    await tap(appButtonFinder);
    await longWait();
  }

  Future<void> switchToKey(ConnectedKey key) async {
    await openDrawer();
    final drawerDevicesFinder = await getDrawerDevices();
    var itemIndex = 0;
    for (var element in drawerDevicesFinder.evaluate()) {
      final listTile = element.widget as ListTile;
      if (key == listTile.getKeyInfo()) {
        await tap(drawerDevicesFinder.at(itemIndex));
        break;
      }
      itemIndex++;
    }

    await closeDrawer();
  }

  Future<void> tapPopupMenu(ConnectedKey key) async {
    await openDrawer();
    final drawerDevicesFinder = await getDrawerDevices();
    var itemIndex = 0;
    for (var element in drawerDevicesFinder.evaluate()) {
      final listTile = element.widget as ListTile;
      if (key == listTile.getKeyInfo()) {
        // find the popup menu
        final popupMenu = find.descendant(
            of: drawerDevicesFinder.at(itemIndex),
            matching: find.byKey(yubikeyPopupMenuButton));
        expect(popupMenu, findsOne);
        await tap(popupMenu);
        break;
      }
      itemIndex++;
    }
  }

  /// Management screen
  Future<void> openManagementScreen() async {
    if (!isDrawerOpened()) {
      await openDrawer();
    }

    await tap(find.byKey(managementAppDrawer).hitTestable());
    await pump(const Duration(milliseconds: 500));

    expect(find.byKey(screenKey), findsOneWidget);
  }

  /// Retrieve a list of test approved serial numbers.
  ///
  /// There are two ways how to provide approved serial numbers:
  ///
  /// 1. Serial numbers defined in test resource file
  /// To add testing keys add comma separated serial numbers to a file
  /// `approved_serial_numbers.csv` in `integration_test/test_res/resources/`.
  /// This file is bundled only during test runs and is explicitly ignored from
  /// version control.
  ///
  /// 2. Serial numbers passed through build environment
  /// YA_TEST_APPROVED_KEY_SN should contain comma separated list of
  /// YubiKey serial numbers which are approved for tests
  /// To pass the variable to the test use:
  /// flutter --dart-define=YA_TEST_APPROVED_KEY_SN=SN1,SN2,...,SNn test t
  Future<List<String>> getApprovedSerialNumbers() async {
    const approvedKeysResource = 'approved_serial_numbers.csv';
    String approved = '';

    const envVar = String.fromEnvironment('YA_TEST_APPROVED_KEY_SN');

    try {
      approved = await rootBundle.loadString(
        'packages/test_res/resources/$approvedKeysResource',
      );
    } catch (_) {
      testLog(false, 'Failed to read $approvedKeysResource');
    }

    return (approved + (approved.isEmpty ? '' : ',') + envVar)
        .split(',')
        .map((e) => e.trim())
        .sorted()
        .toList(growable: false);
  }

  Future<void> startUp([Map<dynamic, dynamic> startUpParams = const {}]) async {
    var result = isAndroid == true
        ? await android_test_util.startUp(this, startUpParams)
        : await desktop_test_util.startUp(this, startUpParams);

    if (!collectedYubiKeyInformation) {
      final connectedKeys = await collectYubiKeyInformation();
      if (connectedKeys.isEmpty) {
        fail('No YubiKey connected');
      }

      final approvedSerialNumbers = await getApprovedSerialNumbers();

      approvedKeys.addAll(connectedKeys
          .where(
              (element) => approvedSerialNumbers.contains(element.serialNumber))
          .toList(growable: false));

      testLog(false, 'Approved keys:');
      testLog(false, approvedKeys.prettyList());

      if (approvedKeys.isEmpty) {
        final connectedSerials = connectedKeys.serialNumbers();
        fail('None of the connected YubiKeys ($connectedSerials) '
            'is approved for integration tests.\nUse --dart-define='
            'YA_TEST_APPROVED_KEY_SN=$connectedSerials test '
            'parameter to approve it.');
      }
    }

    return result;
  }

  void testLog(bool quiet, String message) {
    if (!quiet) {
      printToConsole(message);
    }
  }

  /// get key information
  Future<Finder> getDrawerDevices() async {
    var devicePickerContent =
        await waitForFinder(find.byType(DevicePickerContent));

    var deviceRows = find.descendant(
        of: devicePickerContent, matching: find.byType(ListTile));

    return deviceRows;
  }

  Future<List<ConnectedKey>> collectYubiKeyInformation() async {
    final connectedKeys = <ConnectedKey>[];

    await openDrawer();

    final drawerDevicesFinder = await getDrawerDevices();
    for (var element in drawerDevicesFinder.evaluate()) {
      final listTile = element.widget as ListTile;
      connectedKeys.add(listTile.getKeyInfo());
    }

    // close the opened menu
    await closeDrawer();

    testLog(false, 'Connected YubiKeys:');
    testLog(false, connectedKeys.prettyList());

    collectedYubiKeyInformation = true;

    return connectedKeys;
  }

  bool isTextButtonEnabled(Key buttonKey) {
    var finder = find.byKey(buttonKey).hitTestable();
    expect(finder.evaluate().isNotEmpty, true);
    TextButton button = finder.evaluate().single.widget as TextButton;
    return button.enabled;
  }
}

@isTest
void appTest(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Map startUpParams = const {},
  dynamic tags,
}) {
  testWidgets(description, skip: skip, (WidgetTester tester) async {
    await tester.startUp(startUpParams);
    await callback(tester);
  }, tags: tags);
}
