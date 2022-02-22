import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/state.dart';

import 'core/state.dart';

final _log = Logger('settings');

class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                          child: Text(
                              e.name[0].toUpperCase() + e.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (mode) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode!);
                },
              ),
              DropdownButtonFormField<Level>(
                decoration: const InputDecoration(labelText: 'Logging'),
                value: ref.watch(logLevelProvider),
                items: [Level.INFO, Level.CONFIG, Level.FINE]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (level) {
                  ref.read(logLevelProvider.notifier).setLogLevel(level!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
