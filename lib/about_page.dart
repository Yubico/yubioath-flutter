import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app/logging.dart';
import 'app/message.dart';
import 'app/state.dart';
import 'core/state.dart';
import 'desktop/state.dart';
import 'version.dart';
import 'widgets/responsive_dialog.dart';
import 'widgets/choice_filter_chip.dart';

final _log = Logger('about');

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveDialog(
      title: const Text('About'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/graphics/app-icon.png', scale: 1 / 0.75),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Text(
              Platform.isAndroid
                  ? 'Yubico Authenticator Preview'
                  : 'Yubico Authenticator',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Text(version),
          const Text(''),
          const Text('Copyright © 2022 Yubico'),
          const Text('All rights reserved'),
          const Text(''),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: Text(
                  AppLocalizations.of(context)!.general_terms_of_use,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                        'https://www.yubico.com/support/terms-conditions/yubico-license-agreement/'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              TextButton(
                child: Text(
                  AppLocalizations.of(context)!.general_privacy_policy,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                        'https://www.yubico.com/support/terms-conditions/privacy-notice/'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
          TextButton(
            child: Text(
              AppLocalizations.of(context)!.general_open_src_licenses,
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (BuildContext context) => const LicensePage(
                  applicationVersion: version,
                ),
                settings: const RouteSettings(name: 'licenses'),
              ));
            },
          ),
          const Padding(
            padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              AppLocalizations.of(context)!.general_help_and_feedback,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: Text(
                  AppLocalizations.of(context)!.general_send_feedback,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse('https://forms.gle/nYPVWcFnqoprZX1S9'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              TextButton(
                child: Text(
                  AppLocalizations.of(context)!.general_i_need_help,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse('https://support.yubico.com/support/home'),
                    mode: LaunchMode.externalApplication,
                  );
                },
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
              'Troubleshooting',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const LoggingPanel(),
          if (isDesktop) ...[
            const SizedBox(height: 12.0),
            ActionChip(
              avatar: const Icon(Icons.bug_report_outlined),
              label: const Text('Run diagnostics'),
              onPressed: () async {
                _log.info('Running diagnostics...');
                final response =
                    await ref.read(rpcProvider).command('diagnose', []);
                final data = response['diagnostics'] as List;
                data.insert(0, {
                  'app_version': version,
                  'dart': Platform.version,
                });
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
    final logLevel = ref.watch(logLevelProvider);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4.0,
      runSpacing: 8.0,
      children: [
        ChoiceFilterChip<Level>(
          avatar: Icon(
            Icons.insights,
            color: Theme.of(context).colorScheme.primary,
          ),
          value: logLevel,
          items: Levels.LEVELS,
          selected: logLevel != Level.INFO,
          labelBuilder: (value) => Text(
              'Log level: ${value.name[0]}${value.name.substring(1).toLowerCase()}'),
          itemBuilder: (value) =>
              Text('${value.name[0]}${value.name.substring(1).toLowerCase()}'),
          onChanged: (level) {
            ref.read(logLevelProvider.notifier).setLogLevel(level);
            _log.debug('Log level set to $level');
            showMessage(context, 'Log level set to $level');
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.copy),
          label: const Text('Copy log'),
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
