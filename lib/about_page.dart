import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'app/state.dart';
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
      title: const Text('About'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/graphics/app-icon.png', scale: 1 / 0.75),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              'Yubico Authenticator',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Text('Yubico Authenticator: $version'),
          if (isDesktop) Text('ykman: ${ref.watch(rpcStateProvider).version}'),
          //Text('Dart version: ${Platform.version}'),
          const Text('Copyright © 2022 Yubico'),
          const Text('All rights reserved'),
          const Text(''),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              UrlLink(
                text: 'Terms of use',
                url:
                    'https://www.yubico.com/support/terms-conditions/yubico-license-agreement/',
              ),
              SizedBox(width: 8.0),
              UrlLink(
                text: 'Privacy policy',
                url:
                    'https://www.yubico.com/support/terms-conditions/privacy-notice/',
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Help and feedback',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              UrlLink(
                text: 'Send us feedback',
                url: 'https://example.com',
              ),
              SizedBox(width: 8.0),
              UrlLink(
                  text: 'I need help',
                  url: 'https://support.yubico.com/support/home'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Troubleshooting',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const LoggingPanel(),
          if (isDesktop) ...[
            const SizedBox(height: 12.0),
            OutlinedButton.icon(
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Run diagnostics'),
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
    return Column(
      //crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12.0),
        DropdownButtonFormField<Level>(
          decoration: const InputDecoration(
            labelText: 'Log level',
            border: OutlineInputBorder(),
          ),
          value: ref.watch(logLevelProvider),
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
        const SizedBox(height: 12.0),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copy log to clipboard'),
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

class UrlLink extends StatefulWidget {
  final String text;
  final String url;

  const UrlLink({super.key, required this.text, required this.url});

  @override
  State<StatefulWidget> createState() => _UrlLinkState();
}

class _UrlLinkState extends State<UrlLink> {
  late TapGestureRecognizer _tapRecognizer;

  @override
  void initState() {
    super.initState();
    _tapRecognizer = TapGestureRecognizer();
    _tapRecognizer.onTap = () {
      //TODO: use url_launcher
      // ignore: avoid_print
      print('TODO: Go to ${widget.url}');
    };
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
        text: TextSpan(
      text: widget.text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      recognizer: _tapRecognizer,
    ));
  }
}
