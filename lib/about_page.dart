/*
 * Copyright (C) 2022-2025 Yubico.
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_url_launcher.dart';
import 'app/views/keys.dart';
import 'generated/l10n/app_localizations.dart';
import 'version.dart';
import 'widgets/responsive_dialog.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ResponsiveDialog(
      title: Text(l10n.s_about),
      builder:
          (context, _) => Padding(
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
                        key: tosButton,
                        l10n.s_terms_of_use,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () {
                        launchTermsUrl();
                      },
                    ),
                    TextButton(
                      child: Text(
                        key: privacyButton,
                        l10n.s_privacy_policy,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () {
                        launchPrivacyUrl();
                      },
                    ),
                  ],
                ),
                TextButton(
                  child: Text(
                    key: licensesButton,
                    l10n.s_open_src_licenses,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (BuildContext context) =>
                                const LicensePage(applicationVersion: version),
                        settings: const RouteSettings(name: 'licenses'),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                  child: Divider(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    key: helpButton,
                    l10n.s_help_and_feedback,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: launchDocumentationUrl,
                      child: Text(
                        key: userGuideButton,
                        l10n.s_user_guide,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: launchHelpUrl,
                      child: Text(
                        l10n.s_i_need_help,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}
