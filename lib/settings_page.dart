import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'app/logging.dart';
import 'app/state.dart';
import 'widgets/list_title.dart';
import 'widgets/responsive_dialog.dart';

final _log = Logger('settings');

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return ResponsiveDialog(
      title: const Text('Settings'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
