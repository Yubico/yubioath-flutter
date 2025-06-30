import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:yubico_authenticator/android/models.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/app_list_item.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/app/views/settings_page.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/version.dart';

import 'utils.dart';

Future<void> _selectNfcActionAndKeyboardLayout(
  PatrolTester $,
  NfcTapAction action,
  String currentKeyboardLayout,
) async {
  // Select NFC action
  await $(
    find.byWidgetPredicate(
      (widget) =>
          widget is RadioListTile<NfcTapAction> && widget.value == action,
    ),
  ).tap();

  expect($.read(androidNfcTapActionProvider), action);

  // Ensure keyboard layout is enabled
  await $(nfcKeyboardLayoutSetting).tap();

  await $(
    find.byWidgetPredicate(
      (widget) =>
          widget is RadioListTile<String> &&
          widget.value != currentKeyboardLayout,
    ),
  ).tap();
  expect($.read(androidNfcKbdLayoutProvider), isNot(currentKeyboardLayout));

  // Change back to original layout
  await $(nfcKeyboardLayoutSetting).tap();
  await $(
    find.byWidgetPredicate(
      (widget) =>
          widget is RadioListTile<String> &&
          widget.value == currentKeyboardLayout,
    ),
  ).tap();
  expect($.read(androidNfcKbdLayoutProvider), currentKeyboardLayout);
}

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  appGroup('Settings', (params) {
    testKeyless('General settings sections', params, ($) async {
      await $.navigate(Section.settings);

      settingsSetion(SettingsSection section) => $(
        $(AppListItem<SettingsSection>).which(
          (widget) => (widget as AppListItem<SettingsSection>).item == section,
        ),
      );

      // Change language
      final currentLocale = $.read(currentLocaleProvider);
      await $.selectOrOpenItem(settingsSetion(SettingsSection.language));
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<Locale> && widget.value != currentLocale,
        ),
      ).tap();
      expect($.read(currentLocaleProvider), isNot(currentLocale));

      // Change back to the original locale
      await $.selectOrOpenItem(settingsSetion(SettingsSection.language));
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<Locale> && widget.value == currentLocale,
        ),
      ).tap();
      expect($.read(currentLocaleProvider), equals(currentLocale));

      // Change theme
      await $.selectOrOpenItem(settingsSetion(SettingsSection.theme));
      await $(themeModeOption(ThemeMode.dark)).tap();
      expect($($.l10n.s_dark_mode), findsAtLeast(1));

      await $.selectOrOpenItem(settingsSetion(SettingsSection.theme));
      await $(themeModeOption(ThemeMode.light)).tap();
      expect($($.l10n.s_light_mode), findsAtLeast(1));

      await $.selectOrOpenItem(settingsSetion(SettingsSection.theme));
      await $(themeModeOption(ThemeMode.system)).tap();
      expect($($.l10n.s_system_default), findsAtLeast(1));

      // Enable debug logging
      await $.selectOrOpenItem(settingsSetion(SettingsSection.logs));
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<Level> && widget.value == Levels.DEBUG,
        ),
      ).tap();
      expect($(RegExp('WARNING:')), findsOneWidget);

      // Enable traffic logging
      await $.selectOrOpenItem(settingsSetion(SettingsSection.logs));
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<Level> && widget.value == Levels.TRAFFIC,
        ),
      ).tap();
      expect($(RegExp('WARNING:.*logged')), findsOneWidget);

      // Re-enable info logging
      await $.selectOrOpenItem(settingsSetion(SettingsSection.logs));
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<Level> && widget.value == Levels.INFO,
        ),
      ).tap();
      expect($(RegExp('WARNING:')), findsNothing);

      // Test help & about
      await $.selectOrOpenItem(settingsSetion(SettingsSection.help));
      // Make sure version is visible
      expect($(version), findsOneWidget);
    });

    testKeyless('Android settings sections', params, ($) async {
      await $.navigate(Section.settings);

      settingsSetion(SettingsSection section) => $(
        $(AppListItem<SettingsSection>).which(
          (widget) => (widget as AppListItem<SettingsSection>).item == section,
        ),
      );

      // Change on NFC tap action
      final tapAction = $.read(androidNfcTapActionProvider);

      await $.selectOrOpenItem(settingsSetion(SettingsSection.nfcAndUsb));

      // Test no action
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<NfcTapAction> &&
              widget.value == NfcTapAction.noAction,
        ),
      ).tap();
      expect($.read(androidNfcTapActionProvider), NfcTapAction.noAction);

      // Test OTP actions and keyboard layout
      final currentKeyboardLayout = $.read(androidNfcKbdLayoutProvider);

      // Test copy OTP to clipboard
      await _selectNfcActionAndKeyboardLayout(
        $,
        NfcTapAction.copy,
        currentKeyboardLayout,
      );

      // Test launch and copy OTP
      await _selectNfcActionAndKeyboardLayout(
        $,
        NfcTapAction.launchAndCopy,
        currentKeyboardLayout,
      );

      // Change back to the original action
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<NfcTapAction> &&
              widget.value == tapAction,
        ),
      ).tap();
      expect($.read(androidNfcTapActionProvider), tapAction);

      // Change bypass touch requirement
      final nfcBypassTouch = $.read(androidNfcBypassTouchProvider);
      await $(nfcBypassTouchSetting).tap();
      expect($.read(androidNfcBypassTouchProvider), !nfcBypassTouch);

      // Change back to default touch requirement
      await $(nfcBypassTouchSetting).tap();
      expect($.read(androidNfcBypassTouchProvider), nfcBypassTouch);

      // Change silence NFC sounds
      final nfcSilenceSounds = $.read(androidNfcSilenceSoundsProvider);
      await $(nfcSilenceSoundsSettings).tap();
      expect($.read(androidNfcSilenceSoundsProvider), !nfcSilenceSounds);

      // Change back to default silence NFC sounds
      await $(nfcSilenceSoundsSettings).tap();
      expect($.read(androidNfcSilenceSoundsProvider), nfcSilenceSounds);

      // Change on USB insert
      final usbOpenApp = $.read(androidUsbLaunchAppProvider);
      await $(usbOpenAppSetting).tap();
      expect($.read(androidUsbLaunchAppProvider), !usbOpenApp);

      // Change back to default on USB insert
      await $(usbOpenAppSetting).tap();
      expect($.read(androidUsbLaunchAppProvider), usbOpenApp);
    }, skip: !isAndroid);
  });
}
