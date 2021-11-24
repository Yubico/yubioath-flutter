import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/core/state.dart';

final log = Logger('about');

class AboutPage extends ConsumerWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rpcState = ref.watch(rpcStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Yubico Authenticator'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ykman version: ${rpcState.version}'),
            Text('Dart version: ${Platform.version}'),
            const SizedBox(height: 8.0),
            Text('Log level: ${ref.watch(logLevelProvider)}'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(logLevelProvider.notifier).setLevel(Level.INFO);
                    log.info('Log level changed to INFO');
                  },
                  child: const Text('INFO'),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(logLevelProvider.notifier).setLevel(Level.CONFIG);
                    log.config('Log level changed to CONFIG');
                  },
                  child: const Text('DEBUG'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
