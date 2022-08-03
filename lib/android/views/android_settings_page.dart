import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/core/state.dart';

import '../../app/logging.dart';
import '../../app/state.dart';
import '../../widgets/list_title.dart';
import '../../widgets/responsive_dialog.dart';

final _log = Logger('android_settings');

class AndroidSettingsPage extends ConsumerStatefulWidget {
  const AndroidSettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AndroidSettingsPageState();
}

class _AndroidSettingsPageState extends ConsumerState<AndroidSettingsPage> {
  static const String prefNfcOpenApp = 'prefNfcOpenApp';
  static const String prefNfcCopyOtp = 'prefNfcCopyOtp';

  bool nfcOpenApp = false;
  bool nfcCopyOtp = false;

  @override
  void initState() {
    super.initState();
    nfcOpenApp = ref.read(prefProvider).getBool(prefNfcOpenApp) ?? false;
    nfcCopyOtp = ref.read(prefProvider).getBool(prefNfcCopyOtp) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return ResponsiveDialog(
      title: const Text('Settings'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTitle('NFC tap options'),
          SwitchListTile(
              title: const Text('Open authenticator'),
              value: nfcOpenApp,
              onChanged: (value) {
                ref.read(prefProvider).setBool(prefNfcOpenApp, value);
                setState(() {
                  nfcOpenApp = value;
                });
              }),
          SwitchListTile(
              title: const Text('Copy OTP to clipboard'),
              value: nfcCopyOtp,
              onChanged: (value) {
                ref.read(prefProvider).setBool(prefNfcCopyOtp, value);
                setState(() {
                  nfcCopyOtp = value;
                });
              }),
          const ListTitle('Appearance'),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (mode) {
              ref.read(themeModeProvider.notifier).setThemeMode(mode!);
              _log.debug('Set theme mode to $mode');
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light mode'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (mode) {
              ref.read(themeModeProvider.notifier).setThemeMode(mode!);
              _log.debug('Set theme mode to $mode');
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark mode'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (mode) {
              ref.read(themeModeProvider.notifier).setThemeMode(mode!);
              _log.debug('Set theme mode to $mode');
            },
          ),
        ],
      ),
    );
  }
}
