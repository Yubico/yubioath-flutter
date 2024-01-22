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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../android/qr_scanner/qr_scanner_provider.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../core/state.dart';
import '../features.dart' as features;
import '../icon_provider/icon_pack_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import 'add_account_dialog.dart';
import 'manage_password_dialog.dart';

Widget oathBuildActions(
  BuildContext context,
  DevicePath devicePath,
  OathState oathState,
  WidgetRef ref, {
  int? used,
}) {
  final l10n = AppLocalizations.of(context)!;
  final capacity = oathState.version.isAtLeast(4) ? 32 : null;

  return Column(
    children: [
      ActionListSection(l10n.s_setup, children: [
        ActionListItem(
            feature: features.actionsAdd,
            key: keys.addAccountAction,
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
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    if (isAndroid) {
                      final withContext = ref.read(withContextProvider);
                      final qrScanner = ref.read(qrScannerProvider);
                      if (qrScanner != null) {
                        final qrData = await qrScanner.scanQr();
                        await AndroidQrScanner.handleScannedData(
                            qrData, withContext, qrScanner, l10n);
                      } else {
                        // no QR scanner - enter data manually
                        await AndroidQrScanner.showAccountManualEntryDialog(
                            withContext, l10n);
                      }
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
            feature: features.actionsIcons,
            title: l10n.s_custom_icons,
            subtitle: l10n.l_set_icons_for_accounts,
            icon: const Icon(Icons.image_outlined),
            onTap: (context) async {
              Navigator.of(context).popUntil((route) => route.isFirst);
              await ref.read(withContextProvider)((context) => showBlurDialog(
                    context: context,
                    routeSettings:
                        const RouteSettings(name: 'oath_icon_pack_dialog'),
                    builder: (context) => const IconPackDialog(),
                  ));
            }),
        ActionListItem(
            key: keys.setOrManagePasswordAction,
            feature: features.actionsPassword,
            title:
                oathState.hasKey ? l10n.s_manage_password : l10n.s_set_password,
            subtitle: l10n.l_optional_password_protection,
            icon: const Icon(Icons.password_outlined),
            onTap: (context) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              showBlurDialog(
                context: context,
                builder: (context) =>
                    ManagePasswordDialog(devicePath, oathState),
              );
            }),
      ]),
    ],
  );
}
