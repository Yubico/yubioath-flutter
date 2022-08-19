import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/core/state.dart';

import '../../app/state.dart';
import '../../widgets/list_title.dart';
import '../../widgets/responsive_dialog.dart';

class AndroidSettingsPage extends ConsumerWidget {
  const AndroidSettingsPage({super.key});

  static const String prefNfcOpenApp = 'prefNfcOpenApp';
  static const String prefNfcBypassTouch = 'prefNfcBypassTouch';
  static const String prefNfcCopyOtp = 'prefNfcCopyOtp';
  static const String prefClipKbdLayout = 'prefClipKbdLayout';

  static const String defaultClipKbdLayout = 'US';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nfcOpenApp = ref.watch(prefProvider).getBool(prefNfcOpenApp) ?? true;
    final nfcBypassTouch =
        ref.watch(prefProvider).getBool(prefNfcBypassTouch) ?? false;
    final nfcCopyOtp = ref.watch(prefProvider).getBool(prefNfcCopyOtp) ?? false;
    final clipKbdLayout =
        ref.watch(prefProvider).getString(prefClipKbdLayout) ??
            defaultClipKbdLayout;
    final themeMode = ref.watch(themeModeProvider);
    return ResponsiveDialog(
      title: const Text('Settings'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTitle('General'),
          SwitchListTile(
              title: const Text('Open authenticator on NFC tap'),
              value: nfcOpenApp,
              onChanged: (value) {
                ref.read(prefProvider).setBool(prefNfcOpenApp, value);
                ref.refresh(prefProvider);
              }),
          SwitchListTile(
              title: const Text('Bypass touch requirement for NFC'),
              value: nfcBypassTouch,
              onChanged: (value) {
                ref.read(prefProvider).setBool(prefNfcBypassTouch, value);
                ref.refresh(prefProvider);
              }),
          const ListTitle('Yubiclip'),
          SwitchListTile(
              title: const Text('Copy OTP to clipboard'),
              value: nfcCopyOtp,
              onChanged: (value) {
                ref.read(prefProvider).setBool(prefNfcCopyOtp, value);
                ref.refresh(prefProvider);
              }),
          ListTile(
            title: const Text('Static password keyboard layout'),
            subtitle: Text('Current: $clipKbdLayout'),
            onTap: () async {
              var newValue = await _selectKbdLayout(context, clipKbdLayout);
              if (newValue != clipKbdLayout) {
                await ref
                    .read(prefProvider)
                    .setString(prefClipKbdLayout, newValue);
                ref.refresh(prefProvider);
              }
            },
          ),
          const ListTitle('Appearance'),
          ListTile(
            title: const Text('App theme'),
            subtitle: Text(ref.read(themeModeProvider).name),
            onTap: () async {
              var newMode = await _selectAppearance(context, themeMode);
              ref.read(themeModeProvider.notifier).setThemeMode(newMode);
            },
          ),
        ],
      ),
    );
  }

  Future<String> _selectKbdLayout(
          BuildContext context, String currentKbdLayout) async =>
      await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose keyboard layout'),
              children: <Widget>[
                RadioListTile<String>(
                    title: const Text('US'),
                    value: 'US',
                    groupValue: currentKbdLayout,
                    onChanged: (mode) {
                      Navigator.pop(context, 'US');
                    }),
                RadioListTile<String>(
                    title: const Text('DE'),
                    value: 'DE',
                    groupValue: currentKbdLayout,
                    onChanged: (mode) {
                      Navigator.pop(context, 'DE');
                    }),
                RadioListTile<String>(
                    title: const Text('DE-CH'),
                    value: 'DE-CH',
                    groupValue: currentKbdLayout,
                    onChanged: (mode) {
                      Navigator.pop(context, 'DE-CH');
                    }),
              ],
            );
          }) ??
      defaultClipKbdLayout;

  Future<ThemeMode> _selectAppearance(
          BuildContext context, ThemeMode themeMode) async =>
      await showDialog<ThemeMode>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose app theme'),
              children: <Widget>[
                RadioListTile<ThemeMode>(
                    title: const Text('System default'),
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (mode) {
                      Navigator.pop(context, ThemeMode.system);
                    }),
                RadioListTile<ThemeMode>(
                    title: const Text('Light mode'),
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (mode) {
                      Navigator.pop(context, ThemeMode.light);
                    }),
                RadioListTile<ThemeMode>(
                    title: const Text('Dark mode'),
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (mode) {
                      Navigator.pop(context, ThemeMode.dark);
                    }),
              ],
            );
          }) ??
      ThemeMode.system;
}
