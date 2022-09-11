import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/views/android_settings_page.dart';
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
    var widget = find.byKey(settingsOnNfcTapOptionKey).hitTestable();
    expect(widget, findsOneWidget);
    await tap(widget);
    await pumpAndSettle();
  }

  Future<void> selectLaunchOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(settingsOnNfcTapLaunch));
    await pumpAndSettle();
  }

  Future<void> selectCopyOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(settingsOnNfcTapCopy));
    await pumpAndSettle();
  }

  Future<void> selectBothOption() async {
    await openNfcTapOptionSelection();
    await tap(find.byKey(settingsOnNfcTapBoth));
    await pumpAndSettle();
  }

  ListTile keyboardLayoutListTile() =>
      find.byKey(settingsKeyboardLayoutOptionKey).evaluate().single.widget
          as ListTile;

  Future<void> openKeyboardLayoutOptionSelection() async {
    var widget = find.byKey(settingsKeyboardLayoutOptionKey).hitTestable();
    expect(widget, findsOneWidget);
    await tap(widget);
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutUSOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(settingsKeyboardLayoutUS));
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutDEOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(settingsKeyboardLayoutDE));
    await pumpAndSettle();
  }

  Future<void> selectKeyboardLayoutDECHOption() async {
    await openKeyboardLayoutOptionSelection();
    await tap(find.byKey(settingsKeyboardLayoutDECH));
    await pumpAndSettle();
  }

  Future<void> tapBypassTouch() async {
    await tap(find.byKey(settingsBypassTouchKey));
    await pumpAndSettle();
  }

}

void main() {

  var widget = createMaterialApp(child: const AndroidSettingsPage());

  testWidgets('NFC Tap options', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {prefNfcOpenApp: true, prefNfcCopyOtp: false});

    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
        overrides: [prefProvider.overrideWithValue(sharedPrefs)],
        child: widget));

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

    await tester.pumpWidget(ProviderScope(
        overrides: [prefProvider.overrideWithValue(sharedPrefs)],
        child: widget));

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

    await tester.pumpWidget(ProviderScope(
        overrides: [prefProvider.overrideWithValue(sharedPrefs)],
        child: widget));

    // change to true
    await tester.tapBypassTouch();
    expect(sharedPrefs.getBool(prefNfcBypassTouch), equals(true));

    // change to false
    await tester.tapBypassTouch();
    expect(sharedPrefs.getBool(prefNfcBypassTouch), equals(false));
  });
}
