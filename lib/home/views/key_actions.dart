/*
 * Copyright (C) 2024 Yubico.
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
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/features.dart' as features;
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/action_list.dart';
import '../../app/views/reset_dialog.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../management/views/management_screen.dart';

Widget homeBuildActions(
    BuildContext context, YubiKeyData? deviceData, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final hasFeature = ref.watch(featureProvider);
  final interfacesLocked = deviceData?.info.resetBlocked != 0;
  final managementAvailability = hasFeature(features.management) &&
      switch (deviceData?.info.version) {
        Version version => (version.major > 4 || // YK5 and up
            (version.major == 4 && version.minor >= 1) || // YK4.1 and up
            version.major == 3), // NEO,
        null => false,
      };

  return Column(
    children: [
      if (deviceData != null)
        ActionListSection(
          l10n.s_device,
          children: [
            if (managementAvailability)
              ActionListItem(
                feature: features.management,
                icon: const Icon(Symbols.construction),
                actionStyle: ActionStyle.primary,
                title: deviceData.info.version.major > 4
                    ? l10n.s_toggle_applications
                    : l10n.s_toggle_interfaces,
                subtitle: interfacesLocked
                    ? 'Requires factory reset' // TODO: Replace with l10n
                    : (deviceData.info.version.major > 4
                        ? l10n.l_toggle_applications_desc
                        : l10n.l_toggle_interfaces_desc),
                onTap: interfacesLocked
                    ? null
                    : (context) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        showBlurDialog(
                          context: context,
                          builder: (context) => ManagementScreen(deviceData),
                        );
                      },
              ),
            if (getResetCapabilities(hasFeature).any((c) =>
                c.value &
                    (deviceData.info
                            .supportedCapabilities[deviceData.node.transport] ??
                        0) !=
                0))
              ActionListItem(
                icon: const Icon(Symbols.delete_forever),
                title: l10n.s_factory_reset,
                subtitle: l10n.l_factory_reset_desc,
                actionStyle: ActionStyle.primary,
                onTap: (context) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  showBlurDialog(
                    context: context,
                    builder: (context) => ResetDialog(deviceData),
                  );
                },
              )
          ],
        ),
      ActionListSection(l10n.s_application, children: [
        ActionListItem(
          icon: const Icon(Symbols.settings),
          title: l10n.s_settings,
          subtitle: l10n.l_settings_desc,
          actionStyle: ActionStyle.primary,
          onTap: (context) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Actions.maybeInvoke(context, const SettingsIntent());
          },
        ),
        ActionListItem(
          icon: const Icon(Symbols.help),
          title: l10n.s_help_and_about,
          subtitle: l10n.l_help_and_about_desc,
          actionStyle: ActionStyle.primary,
          onTap: (context) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Actions.maybeInvoke(context, const AboutIntent());
          },
        )
      ])
    ],
  );
}
