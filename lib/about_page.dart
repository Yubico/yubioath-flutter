import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/state.dart';

import 'version.dart';
import 'app/logging.dart';
import 'app/message.dart';
import 'core/state.dart';
import 'desktop/state.dart';
import 'widgets/responsive_dialog.dart';

final _log = Logger('about');

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveDialog(
      title: const Text('Yubico Authenticator'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yubico Authenticator: $version'),
          if (isDesktop)
            Text('ykman version: ${ref.watch(rpcStateProvider).version}'),
          Text('Dart version: ${Platform.version}'),
          const SizedBox(height: 8.0),
          const Divider(),
          const LoggingPanel(),
          if (isDesktop) ...[
            const Divider(),
            OutlinedButton(
              onPressed: () async {
                _log.info('Running diagnostics...');
                final response =
                    await ref.read(rpcProvider).command('diagnose', []);
                final data = response['diagnostics'] as List;
                data.insert(0, {'app_version': version});
                final text = const JsonEncoder.withIndent('  ').convert(data);
                await Clipboard.setData(ClipboardData(text: text));
                await ref.read(withContextProvider)(
                  (context) async {
                    showMessage(context, 'Diagnostic data copied to clipboard');
                  },
                );
              },
              child: const Text('Run diagnostics...'),
            ),
          ]
        ],
      ),
    );
  }
}

class LoggingPanel extends ConsumerWidget {
  const LoggingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Text('Log level:'),
        const SizedBox(width: 8.0),
        DropdownButton<Level>(
          value: ref.watch(logLevelProvider),
          isDense: true,
          items: Levels.LEVELS
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name.toUpperCase()),
                  ))
              .toList(),
          onChanged: (level) {
            ref.read(logLevelProvider.notifier).setLogLevel(level!);
            _log.debug('Log level set to $level');
            showMessage(context, 'Log level set to $level');
          },
        ),
        const SizedBox(width: 8.0),
        OutlinedButton(
          child: const Text('Copy log'),
          onPressed: () async {
            _log.info('Copying log to clipboard ($version)...');
            final logs = await ref.read(logLevelProvider.notifier).getLogs();
            await Clipboard.setData(ClipboardData(text: logs.join('\n')));
            await ref.read(withContextProvider)(
              (context) async {
                showMessage(context, 'Log copied to clipboard');
              },
            );
          },
        ),
      ],
    );
  }
}
