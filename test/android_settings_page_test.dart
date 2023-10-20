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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/keys.dart' as android_keys;
import 'package:yubico_authenticator/android/models.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;
import 'package:yubico_authenticator/app/views/settings_page.dart';
import 'package:yubico_authenticator/core/state.dart';

Widget createMaterialApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en', ''),
    ],
    home: child,
  );
}

extension _WidgetTesterHelper on WidgetTester {
  Future<void> openNfcTapOptionSelection() async {
    var widget = find.byKey(android_keys.nfcTapSetting).hitTestable();
    expect(widget, findsOneWidget);
    await tap(widget);
    await pumpAndSettle();
  }

  Future<void> selectDoNothingOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(android_keys.nfcTapOption(NfcTapAction.noAction)));
    await pumpAndSettle();
  }

  Future<void> selectLaunchOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(android_keys.nfcTapOption(NfcTapAction.launch)));
    await pumpAndSettle();
  }

  Future<void> selectCopyOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(android_keys.nfcTapOption(NfcTapAction.copy)));
    await pumpAndSettle();
  }

  Future<void> selectBothOption() async {
    await openNfcTapOptionSelection();
    await tap(
        find.byKey(android_keys.nfcTapOption(NfcTapAction.launchAndCopy)));
    await pumpAndSettle();
  }

  ListTile keyboardLayoutListTile() =>
      find.byKey(android_keys.nfcKeyboardLayoutSetting).evaluate().single.widget
          as ListTile;

  Future<void> openKeyboardLayoutOptionSelection() async {
    var widget =
        find.byKey(android_keys.nfcKeyboardLayoutSetting).hitTestable();
    expect(widget, findsOneWidget);
    await tap(widget);
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutUSOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(android_keys.keyboardLayoutOption('US')));
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutDEOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(android_keys.keyboardLayoutOption('DE')));
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutDECHOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(android_keys.keyboardLayoutOption('DE-CH')));
    await pumpAndSettle();
  }

  Future<void> tapBypassTouch() async {
    await tap(find.byKey(android_keys.nfcBypassTouchSetting));
    await pumpAndSettle();
  }

  Future<void> tapOpenAppOnUsb() async {
    await ensureVisible(find.byKey(android_keys.usbOpenApp));
    await tap(find.byKey(android_keys.usbOpenApp));
    await pumpAndSettle();
  }

  Future<void> tapSilenceNfcSounds() async {
    await tap(find.byKey(android_keys.nfcSilenceSoundsSettings));
    await pumpAndSettle();
  }

  ListTile themeModeListTile() =>
      find.byKey(app_keys.themeModeSetting).evaluate().single.widget
          as ListTile;

  Future<void> openAppThemeOptionSelection() async {
    await ensureVisible(find.byKey(app_keys.themeModeSetting));
    var widget = find.byKey(app_keys.themeModeSetting).hitTestable();
    expect(widget, findsOneWidget);
    await tap(widget);
    await pumpAndSettle();
  }

  Future<void> selectSystemTheme() async {
    await openAppThemeOptionSelection();
    await tap(find.byKey(app_keys.themeModeOption(ThemeMode.system)));
    await pumpAndSettle();
  }

  Future<void> selectLightTheme() async {
    await openAppThemeOptionSelection();
    await tap(find.byKey(app_keys.themeModeOption(ThemeMode.light)));
    await pumpAndSettle();
  }

  Future<void> selectDarkTheme() async {
    await openAppThemeOptionSelection();
    await tap(find.byKey(app_keys.themeModeOption(ThemeMode.dark)));
    await pumpAndSettle();
  }
}

Future<Widget> androidWidget({
  SharedPreferences? sharedPrefs,
  int sdkVersion = 33,
  bool hasNfcSupport = true,
  Widget? child,
}) async =>
    ProviderScope(overrides: [
      prefProvider.overrideWithValue(
          sharedPrefs ?? await SharedPreferences.getInstance()),
      androidSdkVersionProvider.overrideWithValue(sdkVersion),
      supportedThemesProvider
          .overrideWith((ref) => ref.watch(androidSupportedThemesProvider)),
      androidNfcSupportProvider.overrideWithValue(hasNfcSupport)
    ], child: child ?? createMaterialApp(child: const SettingsPage()));

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  testWidgets('NFC Tap options', (WidgetTester tester) async {
    const prefNfcOpenApp = 'prefNfcOpenApp';
    const prefNfcCopyOtp = 'prefNfcCopyOtp';
    SharedPreferences.setMockInitialValues(
        {prefNfcOpenApp: true, prefNfcCopyOtp: false});

    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(await androidWidget(sharedPrefs: sharedPrefs));

    // launch - preserves original value
    await tester.selectLaunchOption();
    expect(sharedPrefs.getBool(prefNfcOpenApp), equals(true));
    expect(sharedPrefs.getBool(prefNfcCopyOtp), equals(false));

    // copy
    await tester.selectCopyOption();
    expect(sharedPrefs.getBool(prefNfcOpenApp), equals(false));
    expect(sharedPrefs.getBool(prefNfcCopyOtp), equals(true));

    // both
    await tester.selectBothOption();
    expect(sharedPrefs.getBool(prefNfcOpenApp), equals(true));
    expect(sharedPrefs.getBool(prefNfcCopyOtp), equals(true));

    // do nothing
    await tester.selectDoNothingOption();
    expect(sharedPrefs.getBool(prefNfcOpenApp), equals(false));
    expect(sharedPrefs.getBool(prefNfcCopyOtp), equals(false));

    // launch - changes to value
    await tester.selectLaunchOption();
    expect(sharedPrefs.getBool(prefNfcOpenApp), equals(true));
    expect(sharedPrefs.getBool(prefNfcCopyOtp), equals(false));
  });

  testWidgets('Static password keyboard layout', (WidgetTester tester) async {
    const prefNfcOpenApp = 'prefNfcOpenApp';
    const prefNfcCopyOtp = 'prefNfcCopyOtp';
    const prefClipKbdLayout = 'prefClipKbdLayout';
    SharedPreferences.setMockInitialValues(
        {prefNfcOpenApp: true, prefNfcCopyOtp: false, prefClipKbdLayout: 'US'});

    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(await androidWidget(sharedPrefs: sharedPrefs));

    // option is disabled for "do nothing"
    await tester.selectDoNothingOption();
    expect(tester.keyboardLayoutListTile().enabled, equals(false));

    // option is disabled for "open"
    expect(tester.keyboardLayoutListTile().enabled, equals(false));

    // option is enabled for "copy" and "launch"
    await tester.selectCopyOption();
    expect(tester.keyboardLayoutListTile().enabled, equals(true));

    await tester.selectBothOption();
    expect(tester.keyboardLayoutListTile().enabled, equals(true));

    // US - preserves the original value value
    await tester.selectKeyboardLayoutUSOption();
    expect(sharedPrefs.getString(prefClipKbdLayout), equals('US'));

    // DE
    await tester.selectKeyboardLayoutDEOption();
    expect(sharedPrefs.getString(prefClipKbdLayout), equals('DE'));

    // DE-CH
    await tester.selectKeyboardLayoutDECHOption();
    expect(sharedPrefs.getString(prefClipKbdLayout), equals('DE-CH'));

    // US
    await tester.selectKeyboardLayoutUSOption();
    expect(sharedPrefs.getString(prefClipKbdLayout), equals('US'));
  });

  testWidgets('Bypass touch req', (WidgetTester tester) async {
    const prefNfcBypassTouch = 'prefNfcBypassTouch';
    SharedPreferences.setMockInitialValues({prefNfcBypassTouch: false});
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(await androidWidget(sharedPrefs: sharedPrefs));

    // change to true
    await tester.tapBypassTouch();
    expect(sharedPrefs.getBool(prefNfcBypassTouch), equals(true));

    // change to false
    await tester.tapBypassTouch();
    expect(sharedPrefs.getBool(prefNfcBypassTouch), equals(false));
  });

  group('Theme settings', () {
    testWidgets('Theme default on Android 10+', (WidgetTester tester) async {
      // no value for theme
      SharedPreferences.setMockInitialValues({});
      SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(await androidWidget(
        sharedPrefs: sharedPrefs,
        // Android 10 (API Level 29)
        sdkVersion: 29,
      ));

      // we expect System theme default
      expect((tester.themeModeListTile().subtitle as Text).data,
          equals('System default'));
    });

    testWidgets('Theme default on Android <10', (WidgetTester tester) async {
      // no value for theme
      SharedPreferences.setMockInitialValues({});
      SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(await androidWidget(
        sharedPrefs: sharedPrefs,
        // Android 9 (API Level 28)
        sdkVersion: 28,
      ));

      // we expect System theme default
      expect((tester.themeModeListTile().subtitle as Text).data,
          equals('Light mode'));
    });

    testWidgets('Theme preferences update', (WidgetTester tester) async {
      // no value for theme
      SharedPreferences.setMockInitialValues({});
      SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
      const prefTheme = 'APP_STATE_THEME';

      await tester.pumpWidget(await androidWidget(sharedPrefs: sharedPrefs));

      await tester.selectSystemTheme();
      expect(sharedPrefs.getString(prefTheme), equals('system'));

      await tester.selectLightTheme();
      expect(sharedPrefs.getString(prefTheme), equals('light'));

      await tester.selectDarkTheme();
      expect(sharedPrefs.getString(prefTheme), equals('dark'));
    });
  });

  testWidgets('Open app on USB', (WidgetTester tester) async {
    const prefUsbOpenApp = 'prefUsbOpenApp';
    SharedPreferences.setMockInitialValues({prefUsbOpenApp: false});
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(await androidWidget(sharedPrefs: sharedPrefs));

    // change to true
    await tester.tapOpenAppOnUsb();
    expect(sharedPrefs.getBool(prefUsbOpenApp), equals(true));

    // change to false
    await tester.tapOpenAppOnUsb();
    expect(sharedPrefs.getBool(prefUsbOpenApp), equals(false));
  });

  testWidgets('Silence NFC sound', (WidgetTester tester) async {
    const prefNfcSilenceSounds = 'prefNfcSilenceSounds';
    SharedPreferences.setMockInitialValues({prefNfcSilenceSounds: false});
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(await androidWidget(sharedPrefs: sharedPrefs));

    // change to true
    await tester.tapSilenceNfcSounds();
    expect(sharedPrefs.getBool(prefNfcSilenceSounds), equals(true));

    // change to false
    await tester.tapSilenceNfcSounds();
    expect(sharedPrefs.getBool(prefNfcSilenceSounds), equals(false));
  });

  testWidgets('NFC options visible on device with NFC support',
      (WidgetTester tester) async {
    await tester.pumpWidget(await androidWidget(hasNfcSupport: true));

    expect(find.byKey(android_keys.nfcTapSetting), findsOneWidget);
    expect(find.byKey(android_keys.nfcKeyboardLayoutSetting), findsOneWidget);
    expect(find.byKey(android_keys.nfcSilenceSoundsSettings), findsOneWidget);
    expect(find.byKey(android_keys.nfcBypassTouchSetting), findsOneWidget);
  });

  testWidgets('NFC options hidden on device without NFC support',
      (WidgetTester tester) async {
    await tester.pumpWidget(await androidWidget(hasNfcSupport: false));

    expect(find.byKey(android_keys.nfcTapSetting), findsNothing);
    expect(find.byKey(android_keys.nfcKeyboardLayoutSetting), findsNothing);
    expect(find.byKey(android_keys.nfcSilenceSoundsSettings), findsNothing);
    expect(find.byKey(android_keys.nfcBypassTouchSetting), findsNothing);
  });

  testWidgets('USB options visible on device with NFC support',
      (WidgetTester tester) async {
    await tester.pumpWidget(await androidWidget(hasNfcSupport: true));

    expect(find.byKey(android_keys.usbOpenApp), findsOneWidget);
  });

  testWidgets('USB options visible on device without NFC support',
      (WidgetTester tester) async {
    await tester.pumpWidget(await androidWidget(hasNfcSupport: false));

    expect(find.byKey(android_keys.usbOpenApp), findsOneWidget);
  });

  debugDefaultTargetPlatformOverride = null;
}
