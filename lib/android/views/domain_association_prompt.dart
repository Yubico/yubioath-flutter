/*
 * Copyright (C) 2026 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../version.dart' as app_version;
import '../../widgets/basic_dialog.dart';
import '../app_methods.dart';

/// SharedPreferences key tracking the build number for which the user has
/// already seen the my.yubico.com association prompt at startup. The prompt
/// is re-shown after install/update if the domain still isn't associated.
const _kPromptedBuildKey = 'androidDomainPromptedBuild';

Future<void> _showDialog(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return BasicDialog(
        icon: const Icon(Symbols.link),
        title: Text(l10n.s_link_my_yubico),
        content: Text(l10n.p_link_my_yubico_desc),
        onCancel: () {},
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.s_open_settings),
          ),
        ],
      );
    },
  );
  if (accepted == true) {
    await openDomainVerificationSettings();
  }
}

/// Shows an explanation dialog and offers to deep-link the user to the
/// system "Open by default" settings if my.yubico.com is not associated
/// with this app. No-op when the domain is already associated, when the
/// API is unavailable, or when the widget is no longer mounted.
Future<void> promptDomainAssociation(BuildContext context) async {
  final status = await getDomainVerificationStatus();
  if (status != DomainVerificationStatus.none) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  await _showDialog(context);
}

/// Like [promptDomainAssociation] but only shows the dialog once per app
/// build. Used at startup so the user is reminded after install/update
/// without being nagged on every launch.
Future<void> maybePromptDomainAssociationOnStartup(
  BuildContext context,
  SharedPreferences prefs,
) async {
  if (prefs.getInt(_kPromptedBuildKey) == app_version.build) {
    return;
  }
  final status = await getDomainVerificationStatus();
  if (status == DomainVerificationStatus.unsupported) {
    // No deep-linkable settings page on this OS version.
    return;
  }
  // Record the prompt attempt regardless of outcome so we don't keep
  // showing it on every launch when the user dismisses it.
  await prefs.setInt(_kPromptedBuildKey, app_version.build);
  if (status != DomainVerificationStatus.none) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  await _showDialog(context);
}
