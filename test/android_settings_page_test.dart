import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/keys.dart' as keys;
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/android/views/android_settings_page.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/core/state.dart';

import '../integration_test/android/constants.dart';

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
    var widget = find.byKey(keys.nfcTapSetting).hitTestable();
    expect(widget, findsOneWidget);
    await tap(widget);
    await pumpAndSettle();
  }

  Future<void> selectLaunchOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(keys.launchTapAction));
    await pumpAndSettle();
  }

  Future<void> selectCopyOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(keys.copyTapAction));
    await pumpAndSettle();
  }

  Future<void> selectBothOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(keys.bothTapAction));
    await pumpAndSettle();
  }

  ListTile keyboardLayoutListTile() =>
      find.byKey(keys.nfcKeyboardLayoutSetting).evaluate().single.widget
          as ListTile;

  Future<void> openKeyboardLayoutOptionSelection() async {
    var widget = find.byKey(keys.nfcKeyboardLayoutSetting).hitTestable();
    expect(widget, findsOneWidget);
    await tap(widget);
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutUSOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(keys.keyboardLayoutOption('US')));
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutDEOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(keys.keyboardLayoutOption('DE')));
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutDECHOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(keys.keyboardLayoutOption('DE-CH')));
    await pumpAndSettle();
  }

  Future<void> tapBypassTouch() async {
    await tap(find.byKey(keys.nfcBypassTouchSetting));
    await pumpAndSettle();
  }

  ListTile themeModeListTile() =>
      find.byKey(keys.themeModeSetting).evaluate().single.widget as ListTile;

  Future<void> openAppThemeOptionSelection() async {
    var widget = find.byKey(keys.themeModeSetting).hitTestable();
    expect(widget, findsOneWidget);
    await tap(widget);
    await pumpAndSettle();
  }

  Future<void> selectSystemTheme() async {
    await openAppThemeOptionSelection();
    await tap(find.byKey(keys.themeModeSystem));
    await pumpAndSettle();
  }

  Future<void> selectLightTheme() async {
    await openAppThemeOptionSelection();
    await tap(find.byKey(keys.themeModeLight));
    await pumpAndSettle();
  }

  Future<void> selectDarkTheme() async {
    await openAppThemeOptionSelection();
    await tap(find.byKey(keys.themeModeDark));
    await pumpAndSettle();
  }
}

Widget androidWidget({
  required SharedPreferences sharedPrefs,
  required Widget child,
  int sdkVersion = 33,
}) =>
    ProviderScope(overrides: [
      prefProvider.overrideWithValue(sharedPrefs),
      androidSdkVersionProvider.overrideWithValue(sdkVersion),
      supportedThemesProvider
          .overrideWithProvider(androidSupportedThemesProvider)
    ], child: child);

void main() {
  var widget = createMaterialApp(child: const AndroidSettingsPage());

  testWidgets('NFC Tap options', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {prefNfcOpenApp: true, prefNfcCopyOtp: false});

    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(androidWidget(
      sharedPrefs: sharedPrefs,
      child: widget,
    ));

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

    // launch - changes to value
    await tester.selectLaunchOption();
    expect(sharedPrefs.getBool(prefNfcOpenApp), equals(true));
    expect(sharedPrefs.getBool(prefNfcCopyOtp), equals(false));
  });

  testWidgets('Static password keyboard layout', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {prefNfcOpenApp: true, prefNfcCopyOtp: false, prefClipKbdLayout: 'US'});

    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(androidWidget(
      sharedPrefs: sharedPrefs,
      child: widget,
    ));

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
    SharedPreferences.setMockInitialValues({prefNfcBypassTouch: false});
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(androidWidget(
      sharedPrefs: sharedPrefs,
      child: widget,
    ));

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

      await tester.pumpWidget(androidWidget(
        sharedPrefs: sharedPrefs,
        child: widget,
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

      await tester.pumpWidget(androidWidget(
        sharedPrefs: sharedPrefs,
        child: widget,
        // Android 9 (API Level 28)
        sdkVersion: 28,
      ));

      // we expect System theme default
      expect((tester.themeModeListTile().subtitle as Text).data,
          equals('Light theme'));
    });

    testWidgets('Theme preferences update', (WidgetTester tester) async {
      // no value for theme
      SharedPreferences.setMockInitialValues({});
      SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(androidWidget(
        sharedPrefs: sharedPrefs,
        child: widget,
      ));

      await tester.selectSystemTheme();
      expect(sharedPrefs.getString(prefTheme), equals('system'));

      await tester.selectLightTheme();
      expect(sharedPrefs.getString(prefTheme), equals('light'));

      await tester.selectDarkTheme();
      expect(sharedPrefs.getString(prefTheme), equals('dark'));
    });
  });
}
