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
import 'package:yubico_authenticator/oath/views/add_account_dialog.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../app/views/action_list.dart';
import '../../core/state.dart';
import '../models.dart';
import '../keys.dart' as keys;
import '../state.dart';
import 'add_account_page.dart';
import 'manage_password_dialog.dart';
import 'reset_dialog.dart';
import 'utils.dart';

Widget oathBuildActions(
  BuildContext context,
  DevicePath devicePath,
  OathState oathState,
  WidgetRef ref, {
  int? used,
}) {
  final l10n = AppLocalizations.of(context)!;
  final capacity = oathState.version.isAtLeast(4) ? 32 : null;

  return FsDialog(
    child: Column(
      children: [
        ActionListSection(l10n.s_setup, children: [
          ActionListItem(
              title: l10n.s_add_account,
              subtitle: used == null
                  ? l10n.l_unlock_first
                  : (capacity != null
                      ? l10n.l_accounts_used(used, capacity)
                      : ''),
              actionStyle: ActionStyle.primary,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onTap: used != null && (capacity == null || capacity > used)
                  ? (context) async {
                      final credentials = ref.read(credentialsProvider);
                      final withContext = ref.read(withContextProvider);
                      Navigator.of(context).pop();
                      if (isAndroid) {
                        final qrScanner = ref.read(qrScannerProvider);
                        if (qrScanner != null) {
                          final qrData = await qrScanner.scanQr();
                          if (qrData != null) {
                            await withContext((context) => handleUri(
                                  context,
                                  credentials,
                                  qrData,
                                  devicePath,
                                  oathState,
                                  l10n,
                                ));
                            return;
                          }
                        }
                        await withContext((context) => showBlurDialog(
                              context: context,
                              routeSettings:
                                  const RouteSettings(name: 'oath_add_account'),
                              builder: (context) {
                                return OathAddAccountPage(
                                  devicePath,
                                  oathState,
                                  credentials: credentials,
                                  credentialData: null,
                                );
                              },
                            ));
                      } else {
                        await showBlurDialog(
                          context: context,
                          builder: (context) =>
                              AddAccountDialog(devicePath, oathState),
                        );
                      }
                    }
                  : null),
        ]),
        ActionListSection(l10n.s_manage, children: [
          ActionListItem(
              key: keys.customIconsAction,
              title: l10n.s_custom_icons,
              subtitle: l10n.l_set_icons_for_accounts,
              icon: const Icon(Icons.image_outlined),
              onTap: (context) async {
                Navigator.of(context).pop();
                await ref.read(withContextProvider)((context) => showBlurDialog(
                      context: context,
                      routeSettings:
                          const RouteSettings(name: 'oath_icon_pack_dialog'),
                      builder: (context) => const IconPackDialog(),
                    ));
              }),
          ActionListItem(
              key: keys.setOrManagePasswordAction,
              title: oathState.hasKey
                  ? l10n.s_manage_password
                  : l10n.s_set_password,
              subtitle: l10n.l_optional_password_protection,
              icon: const Icon(Icons.password_outlined),
              onTap: (context) {
                Navigator.of(context).pop();
                showBlurDialog(
                  context: context,
                  builder: (context) =>
                      ManagePasswordDialog(devicePath, oathState),
                );
              }),
          ActionListItem(
              key: keys.resetAction,
              icon: const Icon(Icons.delete_outline),
              actionStyle: ActionStyle.error,
              title: l10n.s_reset_oath,
              subtitle: l10n.l_factory_reset_this_app,
              onTap: (context) {
                Navigator.of(context).pop();
                showBlurDialog(
                  context: context,
                  builder: (context) => ResetDialog(devicePath),
                );
              }),
        ]),
      ],
    ),
  );
}
