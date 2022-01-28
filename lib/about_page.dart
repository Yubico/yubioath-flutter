import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'core/state.dart';
import 'desktop/state.dart';

final log = Logger('about');

class AboutPage extends ConsumerWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Yubico Authenticator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                Text('ykman version: ${ref.watch(rpcStateProvider).version}'),
              Text('Dart version: ${Platform.version}'),
              const SizedBox(height: 8.0),
              Text('Log level: ${ref.watch(logLevelProvider)}'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [Level.INFO, Level.CONFIG, Level.FINE]
                    .map((level) => TextButton(
                          onPressed: () {
                            ref.read(logLevelProvider.notifier).state = level;
                            log.info(
                                'Log level changed to ${level.name.toUpperCase()}');
                          },
                          child: Text(level.name.toUpperCase()),
                        ))
                    .toList(),
              ),
              const Divider(),
              if (isDesktop)
                TextButton(
                  onPressed: () async {
                    log.info('Running diagnostics...');
                    final response =
                        await ref.read(rpcProvider).command('diagnose', []);
                    log.info('Response', response['diagnostics']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Diagnostics done. See log for results...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Run diagnostics...'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
