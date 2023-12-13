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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'configure_chalresp_dialog.dart';
import 'configure_hotp_dialog.dart';
import 'configure_static_dialog.dart';
import 'configure_yubiotp_dialog.dart';
import 'delete_slot_dialog.dart';

class ConfigureIntent extends Intent {
  const ConfigureIntent({required this.configurationType});

  final SlotConfigurationType configurationType;
}

Widget registerOtpActions(
  DevicePath devicePath,
  OtpSlot otpSlot, {
  required WidgetRef ref,
  required Widget Function(BuildContext context) builder,
  Map<Type, Action<Intent>> actions = const {},
}) {
  final hasFeature = ref.watch(featureProvider);
  return Actions(
    actions: {
      if (hasFeature(features.slotsConfigure))
        ConfigureIntent:
            CallbackAction<ConfigureIntent>(onInvoke: (intent) async {
          final withContext = ref.read(withContextProvider);
          final configurationType = intent.configurationType;

          switch (configurationType) {
            case SlotConfigurationType.chalresp:
              await withContext((context) async {
                await showBlurDialog(
                    context: context,
                    builder: (context) =>
                        ConfigureChalrespDialog(devicePath, otpSlot));
              });
            case SlotConfigurationType.hotp:
              await withContext((context) async {
                await showBlurDialog(
                    context: context,
                    builder: (context) =>
                        ConfigureHotpDialog(devicePath, otpSlot));
              });
            case SlotConfigurationType.static:
              final keyboardLayouts = await ref
                  .read(otpStateProvider(devicePath).notifier)
                  .getKeyboardLayouts();
              await withContext((context) async {
                await showBlurDialog(
                    context: context,
                    builder: (context) => ConfigureStaticDialog(
                        devicePath, otpSlot, keyboardLayouts));
              });
            case SlotConfigurationType.yubiotp:
              await withContext((context) async {
                await showBlurDialog(
                    context: context,
                    builder: (context) =>
                        ConfigureYubiOtpDialog(devicePath, otpSlot));
              });
            default:
              break;
          }

          return null;
        }),
      if (hasFeature(features.slotsDelete))
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          final withContext = ref.read(withContextProvider);

          final bool? deleted = await withContext((context) async =>
              await showBlurDialog(
                  context: context,
                  builder: (context) =>
                      DeleteSlotDialog(devicePath, otpSlot)) ??
              false);
          return deleted;
        }),
      ...actions,
    },
    child: Builder(builder: builder),
  );
}

List<ActionItem> buildSlotActions(bool isConfigured, AppLocalizations l10n) {
  return [
    ActionItem(
        key: keys.configureYubiOtp,
        feature: features.slotsConfigure,
        icon: const Icon(Icons.shuffle_outlined),
        title: l10n.s_yubiotp,
        subtitle: l10n.l_yubiotp_desc,
        intent: const ConfigureIntent(
            configurationType: SlotConfigurationType.yubiotp)),
    ActionItem(
        key: keys.configureChalResp,
        feature: features.slotsConfigure,
        icon: const Icon(Icons.key_outlined),
        title: l10n.s_challenge_response,
        subtitle: l10n.l_challenge_response_desc,
        intent: const ConfigureIntent(
            configurationType: SlotConfigurationType.chalresp)),
    ActionItem(
        key: keys.configureStatic,
        feature: features.slotsConfigure,
        icon: const Icon(Icons.password_outlined),
        title: l10n.s_static_password,
        subtitle: l10n.l_static_password_desc,
        intent: const ConfigureIntent(
            configurationType: SlotConfigurationType.static)),
    ActionItem(
        key: keys.configureHotp,
        feature: features.slotsConfigure,
        icon: const Icon(Icons.tag_outlined),
        title: l10n.s_hotp,
        subtitle: l10n.l_hotp_desc,
        intent: const ConfigureIntent(
            configurationType: SlotConfigurationType.hotp)),
    ActionItem(
      key: keys.deleteAction,
      feature: features.slotsDelete,
      actionStyle: ActionStyle.error,
      icon: const Icon(Icons.delete_outline),
      title: l10n.s_delete_slot,
      subtitle: l10n.l_delete_slot_desc,
      intent: isConfigured ? const DeleteIntent() : null,
    )
  ];
}
