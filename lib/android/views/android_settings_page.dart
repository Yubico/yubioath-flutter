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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/state.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../preferences.dart';

// TODO: Get these from Android
const List<String> _keyboardLayouts = ['US', 'DE', 'DE-CH'];
const String _defaultClipKbdLayout = 'US';

enum _TapAction {
  launch,
  copy,
  both;

  String get description {
    switch (this) {
      case _TapAction.launch:
        return 'Launch Yubico Authenticator';
      case _TapAction.copy:
        return 'Copy OTP to clipboard';
      case _TapAction.both:
        return 'Launch app and copy OTP';
    }
  }

  Key get key {
    switch (this) {
      case _TapAction.launch:
        return keys.launchTapAction;
      case _TapAction.copy:
        return keys.copyTapAction;
      case _TapAction.both:
        return keys.bothTapAction;
    }
  }

  static _TapAction load(SharedPreferences prefs) {
    final launchApp = prefs.getBool(prefNfcOpenApp) ?? true;
    final copyOtp = prefs.getBool(prefNfcCopyOtp) ?? false;
    if (launchApp && copyOtp) {
      return both;
    }
    if (copyOtp) {
      return copy;
    }
    // This is the default value if both are false.
    return launch;
  }

  void save(SharedPreferences prefs) {
    prefs.setBool(prefNfcOpenApp, this != copy);
    prefs.setBool(prefNfcCopyOtp, this != launch);
  }
}

extension on ThemeMode {
  String get displayName {
    switch (this) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
    }
  }
}

class AndroidSettingsPage extends ConsumerStatefulWidget {
  const AndroidSettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AndroidSettingsPageState();
}

class _AndroidSettingsPageState extends ConsumerState<AndroidSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefProvider);

    final tapAction = _TapAction.load(prefs);
    final clipKbdLayout =
        prefs.getString(prefClipKbdLayout) ?? _defaultClipKbdLayout;
    final nfcBypassTouch = prefs.getBool(prefNfcBypassTouch) ?? false;
    final nfcSilenceSounds = prefs.getBool(prefNfcSilenceSounds) ?? false;
    final usbOpenApp = prefs.getBool(prefUsbOpenApp) ?? false;
    final themeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);

    return ResponsiveDialog(
      title: const Text('Settings'),
      child: Theme(
        // Make the headers use the primary color to pop a bit.
        // Once M3 is implemented this will probably not be needed.
        data: theme.copyWith(
          textTheme: theme.textTheme.copyWith(
              labelLarge: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTitle('NFC options'),
            ListTile(
              title: const Text('On YubiKey NFC tap'),
              subtitle: Text(tapAction.description),
              key: keys.nfcTapSetting,
              onTap: () async {
                final newTapAction = await _selectTapAction(context, tapAction);
                setState(() {
                  newTapAction.save(prefs);
                });
              },
            ),
            ListTile(
              title: const Text('Keyboard Layout (for static password)'),
              subtitle: Text(clipKbdLayout),
              key: keys.nfcKeyboardLayoutSetting,
              enabled: tapAction != _TapAction.launch,
              onTap: () async {
                var newValue = await _selectKbdLayout(context, clipKbdLayout);
                if (newValue != clipKbdLayout) {
                  setState(() {
                    prefs.setString(prefClipKbdLayout, newValue);
                  });
                }
              },
            ),
            SwitchListTile(
                title: const Text('Bypass touch requirement'),
                subtitle: nfcBypassTouch
                    ? const Text(
                        'Accounts that require touch are automatically shown over NFC')
                    : const Text(
                        'Accounts that require touch need an additional tap over NFC'),
                value: nfcBypassTouch,
                key: keys.nfcBypassTouchSetting,
                onChanged: (value) {
                  setState(() {
                    prefs.setBool(prefNfcBypassTouch, value);
                  });
                }),
            SwitchListTile(
                title: const Text('Silence NFC sounds'),
                subtitle: nfcSilenceSounds
                    ? const Text('No sounds will be played on NFC tap')
                    : const Text('Sound will play on NFC tap'),
                value: nfcSilenceSounds,
                key: keys.nfcSilenceSoundsSettings,
                onChanged: (value) {
                  setState(() {
                    prefs.setBool(prefNfcSilenceSounds, value);
                  });
                }),
            const ListTitle('USB options'),
            SwitchListTile(
                title: const Text('Launch when YubiKey is connected'),
                subtitle: usbOpenApp
                    ? const Text(
                        'This prevents other apps from using the YubiKey over USB')
                    : const Text('Other apps can use the YubiKey over USB'),
                value: usbOpenApp,
                key: keys.usbOpenApp,
                onChanged: (value) {
                  setState(() {
                    prefs.setBool(prefUsbOpenApp, value);
                  });
                }),
            const ListTitle('Appearance'),
            ListTile(
              title: const Text('App theme'),
              subtitle: Text(themeMode.displayName),
              key: keys.themeModeSetting,
              onTap: () async {
                final newMode = await _selectAppearance(
                    ref.read(supportedThemesProvider), context, themeMode);
                ref.read(themeModeProvider.notifier).setThemeMode(newMode);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<_TapAction> _selectTapAction(
          BuildContext context, _TapAction tapAction) async =>
      await showDialog<_TapAction>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('On YubiKey NFC tap'),
              children: _TapAction.values
                  .map(
                    (e) => RadioListTile<_TapAction>(
                        title: Text(e.description),
                        key: e.key,
                        value: e,
                        groupValue: tapAction,
                        toggleable: true,
                        onChanged: (mode) {
                          Navigator.pop(context, e);
                        }),
                  )
                  .toList(),
            );
          }) ??
      _TapAction.launch;

  Future<String> _selectKbdLayout(
          BuildContext context, String currentKbdLayout) async =>
      await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose keyboard layout'),
              children: _keyboardLayouts
                  .map(
                    (e) => RadioListTile<String>(
                        title: Text(e),
                        value: e,
                        key: keys.keyboardLayoutOption(e),
                        toggleable: true,
                        groupValue: currentKbdLayout,
                        onChanged: (mode) {
                          Navigator.pop(context, e);
                        }),
                  )
                  .toList(),
            );
          }) ??
      _defaultClipKbdLayout;

  Future<ThemeMode> _selectAppearance(List<ThemeMode> supportedThemes,
          BuildContext context, ThemeMode themeMode) async =>
      await showDialog<ThemeMode>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose app theme'),
              children: supportedThemes
                  .map((e) => RadioListTile(
                        title: Text(e.displayName),
                        value: e,
                        key: Key('android.keys.theme_mode_${e.name}'),
                        groupValue: themeMode,
                        toggleable: true,
                        onChanged: (mode) {
                          Navigator.pop(context, e);
                        },
                      ))
                  .toList(),
            );
          }) ??
      themeMode;
}
