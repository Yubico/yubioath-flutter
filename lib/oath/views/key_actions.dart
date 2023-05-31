/*
 * Copyright (C) 2023 Yubico.
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_pack_dialog.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../core/state.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/list_title.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;
import 'add_account_page.dart';
import 'manage_password_dialog.dart';
import 'reset_dialog.dart';

Widget oathBuildActions(
  BuildContext context,
  DevicePath devicePath,
  OathState oathState,
  WidgetRef ref, {
  int? used,
}) {
  final l10n = AppLocalizations.of(context)!;
  final capacity = oathState.version.isAtLeast(4) ? 32 : null;
  final theme =
      ButtonTheme.of(context).colorScheme ?? Theme.of(context).colorScheme;
  return FsDialog(
    child: Column(
      children: [
        ListTitle(l10n.s_setup,
            textStyle: Theme.of(context).textTheme.bodyLarge),
        ListTile(
          title: Text(l10n.s_add_account),
          key: keys.addAccountAction,
          leading: CircleAvatar(
            backgroundColor: theme.primary,
            foregroundColor: theme.onPrimary,
            child: const Icon(Icons.person_add_alt_1_outlined),
          ),
          subtitle: Text(used == null
              ? l10n.l_unlock_first
              : (capacity != null ? l10n.l_accounts_used(used, capacity) : '')),
          enabled: used != null && (capacity == null || capacity > used),
          onTap: used != null && (capacity == null || capacity > used)
              ? () async {
                  final credentials = ref.read(credentialsProvider);
                  final withContext = ref.read(withContextProvider);
                  Navigator.of(context).pop();
                  CredentialData? otpauth;
                  if (isAndroid) {
                    final scanner = ref.read(qrScannerProvider);
                    if (scanner != null) {
                      try {
                        final url = await scanner.scanQr();
                        if (url != null) {
                          otpauth = CredentialData.fromUri(Uri.parse(url));
                        }
                      } on CancellationException catch (_) {
                        // ignored - user cancelled
                        return;
                      }
                    }
                  }
                  await withContext((context) async {
                    await showBlurDialog(
                      context: context,
                      builder: (context) => OathAddAccountPage(
                        devicePath,
                        oathState,
                        credentials: credentials,
                        credentialData: otpauth,
                      ),
                    );
                  });
                }
              : null,
        ),
        ListTitle(l10n.s_manage,
            textStyle: Theme.of(context).textTheme.bodyLarge),
        ListTile(
            key: keys.customIconsAction,
            title: Text(l10n.s_custom_icons),
            subtitle: Text(l10n.l_set_icons_for_accounts),
            leading: CircleAvatar(
              backgroundColor: theme.secondary,
              foregroundColor: theme.onSecondary,
              child: const Icon(Icons.image_outlined),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(withContextProvider)((context) => showBlurDialog(
                    context: context,
                    routeSettings:
                        const RouteSettings(name: 'oath_icon_pack_dialog'),
                    builder: (context) => const IconPackDialog(),
                  ));
            }),
        ListTile(
            key: keys.setOrManagePasswordAction,
            title: Text(oathState.hasKey
                ? l10n.s_manage_password
                : l10n.s_set_password),
            subtitle: Text(l10n.l_optional_password_protection),
            leading: CircleAvatar(
                backgroundColor: theme.secondary,
                foregroundColor: theme.onSecondary,
                child: const Icon(Icons.password_outlined)),
            onTap: () {
              Navigator.of(context).pop();
              showBlurDialog(
                context: context,
                builder: (context) =>
                    ManagePasswordDialog(devicePath, oathState),
              );
            }),
        ListTile(
            key: keys.resetAction,
            title: Text(l10n.s_reset_oath),
            subtitle: Text(l10n.l_factory_reset_this_app),
            leading: CircleAvatar(
              foregroundColor: theme.onError,
              backgroundColor: theme.error,
              child: const Icon(Icons.delete_outline),
            ),
            onTap: () {
              Navigator.of(context).pop();
              showBlurDialog(
                context: context,
                builder: (context) => ResetDialog(devicePath),
              );
            }),
      ],
    ),
  );
}
