import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

import 'app/state.dart';
import 'widgets/responsive_dialog.dart';

final _log = Logger('settings');

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveDialog(
      title: const Text('Settings'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<ThemeMode>(
            decoration: const InputDecoration(labelText: 'Theme'),
            value: ref.watch(themeModeProvider),
            items: [ThemeMode.system, ThemeMode.dark, ThemeMode.light]
                .map((e) => DropdownMenuItem(
                      value: e,
                      child:
                          Text(e.name[0].toUpperCase() + e.name.substring(1)),
                    ))
                .toList(),
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
