/*
 * Copyright (C) 2023,2024 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../management/models.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import 'utils.dart';

bool oathShowActionNotifier(DeviceInfo? info) {
  if (info == null) {
    return false;
  }

  final (fipsCapable, fipsApproved) = info.getFipsStatus(Capability.oath);
  return fipsCapable && !fipsApproved;
}

Widget oathBuildActions(
  BuildContext context,
  DevicePath devicePath,
  OathState oathState,
  WidgetRef ref, {
  int? used,
}) {
  final l10n = AppLocalizations.of(context)!;
  final capacity = oathState.capacity;
  final (fipsCapable, fipsApproved) = ref
          .watch(currentDeviceDataProvider)
          .valueOrNull
          ?.info
          .getFipsStatus(Capability.oath) ??
      (false, false);

  final String? subtitle;
  final bool enabled;
  if (used == null) {
    subtitle = l10n.l_unlock_first;
    enabled = false;
  } else if (fipsCapable & !fipsApproved) {
    subtitle = l10n.l_set_password_first;
    enabled = false;
  } else if (capacity != null) {
    subtitle = l10n.l_accounts_used(used, capacity);
    enabled = capacity > used;
  } else {
    subtitle = null;
    enabled = true;
  }

  final colors = Theme.of(context).buttonTheme.colorScheme ??
      Theme.of(context).colorScheme;
  final alertIcon = Icon(Symbols.warning_amber, color: colors.tertiary);

  return Column(
    children: [
      ActionListSection(l10n.s_setup, children: [
        ActionListItem(
            feature: features.actionsAdd,
            key: keys.addAccountAction,
            title: l10n.s_add_account,
            subtitle: subtitle,
            actionStyle: ActionStyle.primary,
            icon: const Icon(Symbols.person_add_alt),
            onTap: enabled
                ? (context) async {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    await addOathAccount(context, ref, devicePath, oathState);
                  }
                : null),
      ]),
      ActionListSection(l10n.s_manage, children: [
        ActionListItem(
            key: keys.setOrManagePasswordAction,
            feature: features.actionsPassword,
            title:
                oathState.hasKey ? l10n.s_manage_password : l10n.s_set_password,
            subtitle: l10n.l_password_protection,
            icon: const Icon(Symbols.password),
            trailing: fipsCapable && !fipsApproved ? alertIcon : null,
            onTap: (context) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              managePassword(context, ref, devicePath, oathState);
            }),
      ]),
    ],
  );
}
