/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'android/state.dart';
import 'app/app_url_launcher.dart';
import 'app/logging.dart';
import 'app/message.dart';
import 'app/state.dart';
import 'core/state.dart';
import 'desktop/state.dart';
import 'version.dart';
import 'widgets/choice_filter_chip.dart';
import 'widgets/responsive_dialog.dart';

final _log = Logger('about');

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ResponsiveDialog(
      title: Text(l10n.w_about),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/graphics/app-icon.png', scale: 1 / 0.75),
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Text(
                l10n.app_name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Text(version),
            const Text(''),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  child: Text(
                    l10n.l_terms_of_use,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                  ),
                  onPressed: () {
                    launchTermsUrl();
                  },
                ),
                TextButton(
                  child: Text(
                    l10n.l_privacy_policy,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                  ),
                  onPressed: () {
                    launchPrivacyUrl();
                  },
                ),
              ],
            ),
            TextButton(
              child: Text(
                l10n.l_open_src_licenses,
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
                l10n.l_help_and_feedback,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  child: Text(
                    l10n.l_send_feedback,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                  ),
                  onPressed: () {
                    launchFeedbackUrl();
                  },
                ),
                TextButton(
                  child: Text(
                    l10n.l_i_need_help,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                  ),
                  onPressed: () {
                    launchHelpUrl();
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
                l10n.w_troubleshooting,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const LoggingPanel(),

            // Diagnostics (desktop only)
            if (isDesktop) ...[
              const SizedBox(height: 12.0),
              ActionChip(
                avatar: const Icon(Icons.bug_report_outlined),
                label: Text(l10n.l_run_diagnostics),
                onPressed: () async {
                  _log.info('Running diagnostics...');
                  final response = await ref
                      .read(rpcProvider)
                      .requireValue
                      .command('diagnose', []);
                  final data = response['diagnostics'] as List;
                  data.insert(0, {
                    'app_version': version,
                    'dart': Platform.version,
                    'os': Platform.operatingSystem,
                    'os_version': Platform.operatingSystemVersion,
                  });
                  final text = const JsonEncoder.withIndent('  ').convert(data);
                  await ref.read(clipboardProvider).setText(text);
                  await ref.read(withContextProvider)(
                    (context) async {
                      showMessage(context, l10n.l_diagnostics_copied);
                    },
                  );
                },
              ),
            ],

            // Enable screenshots (Android only)
            if (isAndroid) ...[
              const SizedBox(height: 12.0),
              FilterChip(
                label: Text(l10n.l_allow_screenshots),
                selected: ref.watch(androidAllowScreenshotsProvider),
                onSelected: (value) async {
                  ref
                      .read(androidAllowScreenshotsProvider.notifier)
                      .setAllowScreenshots(value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoggingPanel extends ConsumerWidget {
  const LoggingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
          labelBuilder: (value) => Text(l10n.l_log_level(
              value.name[0] + value.name.substring(1).toLowerCase())),
          itemBuilder: (value) =>
              Text('${value.name[0]}${value.name.substring(1).toLowerCase()}'),
          onChanged: (level) {
            ref.read(logLevelProvider.notifier).setLogLevel(level);
            _log.debug('Log level set to $level');
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.copy),
          label: Text(l10n.l_copy_log),
          onPressed: () async {
            _log.info('Copying log to clipboard ($version)...');
            final logs = await ref.read(logLevelProvider.notifier).getLogs();
            var clipboard = ref.read(clipboardProvider);
            await clipboard.setText(logs.join('\n'));
            if (!clipboard.platformGivesFeedback()) {
              await ref.read(withContextProvider)(
                (context) async {
                  showMessage(context, l10n.l_log_copied);
                },
              );
            }
          },
        ),
      ],
    );
  }
}
