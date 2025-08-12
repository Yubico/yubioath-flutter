library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/init.dart' as android;
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/device_picker.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/app/views/navigation.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/desktop/init.dart' as desktop;
import 'package:yubico_authenticator/desktop/window_manager_helper/window_manager_helper.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';
import 'package:yubico_authenticator/management/models.dart';

const _expectedSerials = String.fromEnvironment('TEST_SERIALS');
final expectedSerials = _expectedSerials
    .split(',')
    .map(int.parse)
    .toList(growable: false);
const windowSizeName = String.fromEnvironment('WINDOW_SIZE');
const nfcReader = String.fromEnvironment('READER');
const _deviceInfoJson = String.fromEnvironment('INFO');
final _deviceInfo = _deviceInfoJson.isEmpty
    ? null
    : DeviceInfo.fromJson(jsonDecode(_deviceInfoJson));

enum WindowSize {
  narrow(Size(378, 840)),
  medium(Size(512, 840)),
  wide(Size(1024, 840));

  final Size size;
  const WindowSize(this.size);

  static WindowSize get standard => windowSizeName.isNotEmpty
      ? WindowSize.values.byName(windowSizeName)
      : WindowSize.wide;
}

class TestParameters {
  final WindowSize windowSize;

  TestParameters({WindowSize? windowSize})
    : windowSize = windowSize ?? WindowSize.standard;
}

Widget? _app;
Future<Widget> getApp() async {
  if (_app == null) {
    isRunningTest = true; // Enable test mode

    if (isAndroid) {
      _app = await android.initialize(level: Levels.INFO);
    } else if (isDesktop) {
      _app = await desktop.initialize([]);
    } else {
      throw UnimplementedError('Platform not supported');
    }
  }
  return _app!;
}

typedef TestCondition = bool Function(DeviceInfo info);
typedef AppTest = Future<void> Function(PatrolTester $);

@isTest
void testApp(
  String name,
  TestParameters params,
  AppTest test, {
  bool skip = false,
  dynamic tags,
}) {
  if (skip) {
    patrolWidgetTest(name, (_) async {}, tags: tags, skip: true);
    return;
  }
  if (isDesktop) {
    patrolWidgetTest(name, (widgetTester) async {
      final window = WindowManagerHelper.withPreferences(
        await SharedPreferences.getInstance(),
      );
      await widgetTester.pumpWidget(await getApp());

      // Set window size
      final size = params.windowSize.size;
      final rect = Rect.fromLTWH(10, 10, size.width, size.height);
      if (await window.getBounds() != rect) {
        await Future.delayed(const Duration(milliseconds: 200));
        await window.setBounds(rect);
      }

      await widgetTester.pumpAndSettle();
      await test(widgetTester);
    }, tags: tags);
  } else if (isAndroid) {
    patrolWidgetTest(name, (widgetTester) async {
      await widgetTester.pumpWidget(await getApp());
      await test(widgetTester);
      // Allow some time for the app to settle after the test
      await Future.delayed(const Duration(milliseconds: 200));
    }, tags: tags);
  } else {
    fail('Unsupported platform');
  }
}

typedef AppKeyTest = Future<void> Function(PatrolTester $, YubiKeyData data);

@isTest
Future<void> testKey(
  String name,
  TestParameters params,
  AppKeyTest test, {
  TestCondition? condition,
  bool skip = false,
  dynamic tags,
}) async {
  if ([false, null, 0].contains(skip) &&
      condition != null &&
      _deviceInfo != null) {
    skip = !condition(_deviceInfo!);
  }
  testApp(
    name,
    params,
    ($) async {
      final device = await $.waitForYubiKey(
        reader: isDesktop && nfcReader.isNotEmpty ? nfcReader : null,
      );
      await test($, device);
    },
    skip: skip || expectedSerials.isEmpty,
    tags: tags,
  );
}

@isTest
void testKeyless(
  String name,
  TestParameters params,
  AppTest test, {
  bool skip = false,
  dynamic tags,
}) => testApp(
  name,
  params,
  ($) async {
    // Make sure the app has settled, and there are no keys connected
    await Future.delayed(const Duration(seconds: 1));
    if ($.read(currentDeviceDataProvider).hasValue) {
      await $.fatalError('YubiKey(s) connected, expected none');
    }
    await test($);
  },
  skip: skip,
  tags: tags,
);

@isTestGroup
void appGroup(
  Object description,
  void Function(TestParameters params) body, {
  TestCondition? condition,
  dynamic skip,
  int? retry,
}) {
  if ([false, null, 0].contains(skip) &&
      condition != null &&
      _deviceInfo != null) {
    skip = !condition(_deviceInfo!);
  }
  if (!isDesktop || windowSizeName.isNotEmpty) {
    group(description, () => body(TestParameters()), skip: skip, retry: retry);
  } else {
    for (var windowSize in WindowSize.values) {
      group(
        '$description [${windowSize.name}]',
        () => body(TestParameters(windowSize: windowSize)),
        skip: skip,
        retry: retry,
      );
    }
  }
}

extension DeviceInfoUtils on DeviceInfo {
  (bool capable, bool approved) get fipsStatus {
    return getFipsStatus(Capability.piv);
  }

  bool hasCapability(Capability capability) {
    final transport = nfcReader.isNotEmpty ? Transport.nfc : Transport.usb;
    return (supportedCapabilities[transport] ?? 0) & capability.value != 0;
  }
}

extension PatrolFinderUtils on PatrolFinder {
  T widget<T extends Widget>() => tester.tester.widget<T>(this);
  T element<T extends Element>() => tester.tester.element<T>(this);
}

extension PatrolTesterUtils on PatrolTester {
  PatrolTester get $ => this;

  ProviderContainer get _ref =>
      ProviderScope.containerOf($(MaterialApp).element());

  T read<T>(ProviderListenable<T> provider) => _ref.read(provider);

  AppLocalizations get l10n => AppLocalizations.of($(Scaffold).first.element());

  Future<Never> fatalError(String message) async {
    tester.printToConsole('\n❌ $message\n');
    await Future.delayed(const Duration(milliseconds: 100));
    exit(1);
  }

  Future<void> condition(
    FutureOr<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 30),
    String reason = 'Condition not met within timeout',
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      if (await condition()) {
        await pumpAndSettle();
        return;
      }
      await pumpAndSettle();
    }
    fail(reason);
  }

  Future<YubiKeyData> waitForYubiKey({String? reader}) async {
    if (!read(currentDeviceDataProvider).hasValue) {
      if (isDesktop) {
        final drawerButton = $(drawerIconButtonKey);
        if (drawerButton.exists) {
          // Open drawer
          await drawerButton.tap();
          await pumpAndSettle();
        }

        if (reader != null) {
          // Select the NFC reader
          await $(DeviceRow).which<DeviceRow>((widget) {
            return widget.node?.name.toLowerCase().contains(
                  reader.toLowerCase(),
                ) ==
                true;
          }).tap();
        } else {
          // Make sure USB is selected
          await $(DeviceRow).first.tap();
        }
      }

      // Wait for the current device data to be set
      await condition(() async => read(currentDeviceDataProvider).hasValue);
    }

    // We have a YubiKey, wait for the UI to be ready and verify the serial
    await pumpAndSettle();
    final device = read(currentDeviceDataProvider).value!;
    if (!expectedSerials.contains(device.info.serial ?? 0)) {
      await fatalError(
        'Wrong YubiKey connected: ${device.info.serial}, expected: $expectedSerials',
      );
    }
    // Make sure no other YubiKeys are connected via USB
    if (read(attachedDevicesProvider)
        .whereType<UsbYubiKeyNode>()
        .where((node) => node != device.node)
        .isNotEmpty) {
      await fatalError('Additional YubiKeys connected');
    }

    return device;
  }

  Future<void> navigate(Section target) async {
    final targetButton = $(target.key);
    if (!targetButton.exists) {
      // Open drawer
      await $(drawerIconButtonKey).tap();
    }

    // TODO: Need to take care of sections that are hidden in the more button
    await targetButton.tap();

    // Android may need some extra time to settle after navigation
    if (isAndroid) {
      await pumpAndSettle();
    }
  }

  Future<void> viewAction(Key key) async {
    final targetButton = $(key);
    // Open actions menu, if needed
    if (!targetButton.exists) {
      await $(actionsIconButtonKey).tap();
    }
    await targetButton.scrollTo().tap();
  }

  Future<void> selectOrOpenItem(PatrolFinder owner) async {
    // Select or open the list item
    final actionButton = owner.$(appListItemActionKey);
    final target = actionButton.exists ? actionButton : owner;
    await target.scrollTo().tap();
  }

  Future<void> itemAction(PatrolFinder owner, Key action) async {
    await selectOrOpenItem(owner);

    // Trigger the action
    await $(action).scrollTo().tap();
  }
}
