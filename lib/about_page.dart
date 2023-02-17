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

import 'package:file_picker/file_picker.dart';
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
import 'oath/state.dart';
import 'version.dart';
import 'widgets/choice_filter_chip.dart';
import 'widgets/responsive_dialog.dart';

final _log = Logger('about');

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.general_about),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/graphics/app-icon.png', scale: 1 / 0.75),
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Text(
                'Yubico Authenticator',
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
                    AppLocalizations.of(context)!.general_terms_of_use,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                  ),
                  onPressed: () {
                    launchTermsUrl();
                  },
                ),
                TextButton(
                  child: Text(
                    AppLocalizations.of(context)!.general_privacy_policy,
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
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                  ),
                  onPressed: () {
                    launchFeedbackUrl();
                  },
                ),
                TextButton(
                  child: Text(
                    AppLocalizations.of(context)!.general_i_need_help,
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
                AppLocalizations.of(context)!.general_troubleshooting,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const LoggingPanel(),

            // Diagnostics (desktop only)
            if (isDesktop) ...[
              const SizedBox(height: 12.0),
              ActionChip(
                avatar: const Icon(Icons.bug_report_outlined),
                label:
                    Text(AppLocalizations.of(context)!.general_run_diagnostics),
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
                  });
                  final text = const JsonEncoder.withIndent('  ').convert(data);
                  await ref.read(clipboardProvider).setText(text);
                  await ref.read(withContextProvider)(
                    (context) async {
                      showMessage(
                          context,
                          AppLocalizations.of(context)!
                              .general_diagnostics_copied);
                    },
                  );
                },
              ),
            ],

            // Enable screenshots (Android only)
            if (isAndroid) ...[
              const SizedBox(height: 12.0),
              FilterChip(
                label: Text(
                    AppLocalizations.of(context)!.general_allow_screenshots),
                selected: ref.watch(androidAllowScreenshotsProvider),
                onSelected: (value) async {
                  ref
                      .read(androidAllowScreenshotsProvider.notifier)
                      .setAllowScreenshots(value);
                },
              ),
            ],

            ... [
              const SizedBox(height: 12.0,),
              FilterChip(
                label: const Text('Import icon pack'),
                onSelected: (value) async {
                  final result = await FilePicker.platform.pickFiles(
                      allowedExtensions: ['zip'],
                      type: FileType.custom,
                      allowMultiple: false,
                      lockParentWindow: true,
                      dialogTitle: 'Choose icon pack');
                  if (result != null && result.files.isNotEmpty) {
                    final importStatus = await ref
                        .read(issuerIconProvider)
                        .importPack(result.paths.first!);

                    await ref.read(withContextProvider)(
                      (context) async {
                        if (importStatus) {
                          showMessage(context, 'Icon pack imported');
                        } else {
                          showMessage(context, 'Error importing icon pack');
                        }
                      },
                    );
                  }
                },
              ),
            ]
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
              '${AppLocalizations.of(context)!.general_log_level}: ${value.name[0]}${value.name.substring(1).toLowerCase()}'),
          itemBuilder: (value) =>
              Text('${value.name[0]}${value.name.substring(1).toLowerCase()}'),
          onChanged: (level) {
            ref.read(logLevelProvider.notifier).setLogLevel(level);
            _log.debug('Log level set to $level');
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.copy),
          label: Text(AppLocalizations.of(context)!.general_copy_log),
          onPressed: () async {
            _log.info('Copying log to clipboard ($version)...');
            final logs = await ref.read(logLevelProvider.notifier).getLogs();
            var clipboard = ref.read(clipboardProvider);
            await clipboard.setText(logs.join('\n'));
            if (!clipboard.platformGivesFeedback()) {
              await ref.read(withContextProvider)(
                (context) async {
                  showMessage(context,
                      AppLocalizations.of(context)!.general_log_copied);
                },
              );
            }
          },
        ),
      ],
    );
  }
}
