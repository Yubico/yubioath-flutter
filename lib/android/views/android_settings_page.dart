import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/app_methods.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/core/state.dart';

import '../../app/state.dart';
import '../../widgets/list_title.dart';
import '../../widgets/responsive_dialog.dart';

final _log = Logger('android_settings_page');
final _hideAppThumbnailProvider = StateProvider<bool>((ref) => true);

const String _prefNfcOpenApp = 'prefNfcOpenApp';
const String _prefNfcBypassTouch = 'prefNfcBypassTouch';
const String _prefNfcCopyOtp = 'prefNfcCopyOtp';
const String _prefClipKbdLayout = 'prefClipKbdLayout';

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

  static _TapAction load(SharedPreferences prefs) {
    final launchApp = prefs.getBool(_prefNfcOpenApp) ?? true;
    final copyOtp = prefs.getBool(_prefNfcCopyOtp) ?? false;
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
    prefs.setBool(_prefNfcOpenApp, this != copy);
    prefs.setBool(_prefNfcCopyOtp, this != launch);
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
        prefs.getString(_prefClipKbdLayout) ?? _defaultClipKbdLayout;
    final nfcBypassTouch = prefs.getBool(_prefNfcBypassTouch) ?? false;
    final themeMode = ref.watch(themeModeProvider);
    final hideAppThumbnail = ref.watch(_hideAppThumbnailProvider);

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
              onTap: () async {
                final newTapAction = await _selectTapAction(context, tapAction);
                newTapAction.save(prefs);
                setState(() {});
              },
            ),
            ListTile(
              title: const Text('Keyboard Layout (for static password)'),
              subtitle: Text(clipKbdLayout),
              enabled: tapAction != _TapAction.launch,
              onTap: () async {
                var newValue = await _selectKbdLayout(context, clipKbdLayout);
                if (newValue != clipKbdLayout) {
                  await prefs.setString(_prefClipKbdLayout, newValue);
                  setState(() {});
                }
              },
            ),
            SwitchListTile(
                title: const Text('Bypass touch requirement'),
                subtitle: nfcBypassTouch
                    ? const Text(
                        'Accounts that require touch are automatically shown over NFC.')
                    : const Text(
                        'Accounts that require touch need an additional tap over NFC.'),
                value: nfcBypassTouch,
                onChanged: (value) {
                  prefs.setBool(_prefNfcBypassTouch, value);
                  setState(() {});
                }),
            const ListTitle('Appearance'),
            ListTile(
              title: const Text('App theme'),
              subtitle: Text(themeMode.displayName),
              onTap: () async {
                final newMode = await _selectAppearance(context, themeMode);
                ref.read(themeModeProvider.notifier).setThemeMode(newMode);
              },
            ),
            const ListTitle('Security'),
            SwitchListTile(
                title: const Text('Hide app thumbnail'),
                value: hideAppThumbnail,
                onChanged: (value) async {
                  try {
                    bool hideAppThumbnail = await ref
                        .read(appMethodsProvider)
                        .invokeMethod('hideAppThumbnail', value);
                    ref.read(_hideAppThumbnailProvider.notifier).state =
                        hideAppThumbnail;
                  } catch (e) {
                    _log.error('Failed to call hideAppThumbnail', e);
                  }
                }),
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
                        value: e,
                        groupValue: tapAction,
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
                        groupValue: currentKbdLayout,
                        onChanged: (mode) {
                          Navigator.pop(context, e);
                        }),
                  )
                  .toList(),
            );
          }) ??
      _defaultClipKbdLayout;

  Future<ThemeMode> _selectAppearance(
          BuildContext context, ThemeMode themeMode) async =>
      await showDialog<ThemeMode>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose app theme'),
              children: ThemeMode.values
                  .map((e) => RadioListTile(
                        title: Text(e.displayName),
                        value: e,
                        groupValue: themeMode,
                        onChanged: (mode) {
                          Navigator.pop(context, e);
                        },
                      ))
                  .toList(),
            );
          }) ??
      ThemeMode.system;
}
