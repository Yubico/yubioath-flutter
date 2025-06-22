import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/version.dart';

import 'utils.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  appGroup('Home', (params) {
    testKeyless('Settings', params, ($) async {
      await $.navigate(Section.home);

      // Open settings dialog
      await $.viewAction(settingDrawerIcon);

      // Change theme
      await $(themeModeSetting).tap();
      await $(themeModeOption(ThemeMode.dark)).tap();
      expect($($.l10n.s_dark_mode), findsOneWidget);

      await $(themeModeSetting).tap();
      await $(themeModeOption(ThemeMode.light)).tap();
      expect($($.l10n.s_light_mode), findsOneWidget);

      await $(themeModeSetting).tap();
      await $(themeModeOption(ThemeMode.system)).tap();
      expect($($.l10n.s_system_default), findsOneWidget);

      // Change language
      final currentLocale = $.read(currentLocaleProvider);
      await $(languageSetting).tap();
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<Locale> && widget.value != currentLocale,
        ),
      ).tap();
      expect($.read(currentLocaleProvider), isNot(currentLocale));

      // Change back to the original locale
      await $(languageSetting).tap();
      await $(
        find.byWidgetPredicate(
          (widget) =>
              widget is RadioListTile<Locale> && widget.value == currentLocale,
        ),
      ).tap();
      expect($.read(currentLocaleProvider), equals(currentLocale));

      // Close the dialog
      await $(closeButton).tap();
    });

    testKeyless('About', params, ($) async {
      await $.navigate(Section.home);

      // Open help dialog
      await $.viewAction(helpDrawerIcon);

      // Make sure version is visible
      expect($(version), findsOneWidget);

      // Test logging overlay warnings (not localized)
      expect($(RegExp('WARNING:')), findsNothing);

      // Enable debug logging
      await $(logLevelChip).tap();
      await $('Debug').tap();
      expect($(RegExp('WARNING:')), findsOneWidget);

      // Enable traffic logging
      await $(logLevelChip).tap();
      await $('Traffic').tap();
      expect($(RegExp('WARNING:.*logged')), findsOneWidget);

      if (isAndroid) {
        // Enable screenshots, and make sure both warnings are shown
        await $(screenshotChip).tap();
        expect($(RegExp('WARNING:.*logged.*screen')), findsOneWidget);
        await $(screenshotChip).tap();
        expect($(RegExp('WARNING:.*screen')), findsNothing);
        expect($(RegExp('WARNING:.*logged')), findsOneWidget);
      }

      // Re-enable info logging
      await $(logLevelChip).tap();
      await $('Info').tap();
      expect($(RegExp('WARNING:')), findsNothing);

      // Close the dialog
      await $(closeButton).tap();
    });
  });
}
