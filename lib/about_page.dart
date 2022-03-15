import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'app/views/responsive_dialog.dart';
import 'core/state.dart';
import 'desktop/state.dart';

final _log = Logger('about');

class AboutPage extends ConsumerWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveDialog(
      title: const Text('About Yubico Authenticator'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: Store the version number elsewhere
          const Text('Yubico Authenticator version: 6.0.0-alpha.1'),
          if (isDesktop)
            Text('ykman version: ${ref.watch(rpcStateProvider).version}'),
          Text('Dart version: ${Platform.version}'),
          const SizedBox(height: 8.0),
          const Divider(),
          if (isDesktop)
            TextButton(
              onPressed: () async {
                _log.info('Running diagnostics...');
                final response =
                    await ref.read(rpcProvider).command('diagnose', []);
                _log.info('Response', response['diagnostics']);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Diagnostics done. See log for results...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Run diagnostics...'),
            ),
        ],
      ),
    );
  }
}
