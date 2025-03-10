/*
 * Copyright (C) 2023-2025 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'configure_chalresp_dialog.dart';
import 'configure_hotp_dialog.dart';
import 'configure_static_dialog.dart';
import 'configure_yubiotp_dialog.dart';
import 'delete_slot_dialog.dart';

class ConfigureChalRespIntent extends Intent {
  final OtpSlot slot;

  const ConfigureChalRespIntent(this.slot);
}

class ConfigureHotpIntent extends Intent {
  final OtpSlot slot;

  const ConfigureHotpIntent(this.slot);
}

class ConfigureStaticIntent extends Intent {
  final OtpSlot slot;

  const ConfigureStaticIntent(this.slot);
}

class ConfigureYubiOtpIntent extends Intent {
  final OtpSlot slot;

  const ConfigureYubiOtpIntent(this.slot);
}

class OtpActions extends ConsumerWidget {
  final DevicePath devicePath;
  final Map<Type, Action<Intent>> Function(BuildContext context)? actions;
  final Widget Function(BuildContext context) builder;

  const OtpActions({
    super.key,
    required this.devicePath,
    this.actions,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withContext = ref.read(withContextProvider);
    final hasFeature = ref.read(featureProvider);

    return Actions(
      actions: {
        if (hasFeature(features.slotsConfigureChalResp))
          ConfigureChalRespIntent: CallbackAction<ConfigureChalRespIntent>(
            onInvoke: (intent) async {
              await withContext((context) async {
                await showBlurDialog(
                  context: context,
                  builder:
                      (context) =>
                          ConfigureChalrespDialog(devicePath, intent.slot),
                );
              });
              return null;
            },
          ),
        if (hasFeature(features.slotsConfigureHotp))
          ConfigureHotpIntent: CallbackAction<ConfigureHotpIntent>(
            onInvoke: (intent) async {
              await withContext((context) async {
                await showBlurDialog(
                  context: context,
                  builder:
                      (context) => ConfigureHotpDialog(devicePath, intent.slot),
                );
              });
              return null;
            },
          ),
        if (hasFeature(features.slotsConfigureStatic))
          ConfigureStaticIntent: CallbackAction<ConfigureStaticIntent>(
            onInvoke: (intent) async {
              final keyboardLayouts =
                  await ref
                      .read(otpStateProvider(devicePath).notifier)
                      .getKeyboardLayouts();
              await withContext((context) async {
                await showBlurDialog(
                  context: context,
                  builder:
                      (context) => ConfigureStaticDialog(
                        devicePath,
                        intent.slot,
                        keyboardLayouts,
                      ),
                );
              });
              return null;
            },
          ),
        if (hasFeature(features.slotsConfigureYubiOtp))
          ConfigureYubiOtpIntent: CallbackAction<ConfigureYubiOtpIntent>(
            onInvoke: (intent) async {
              await withContext((context) async {
                await showBlurDialog(
                  context: context,
                  builder:
                      (context) =>
                          ConfigureYubiOtpDialog(devicePath, intent.slot),
                );
              });
              return null;
            },
          ),
        if (hasFeature(features.slotsDelete))
          DeleteIntent<OtpSlot>: CallbackAction<DeleteIntent<OtpSlot>>(
            onInvoke: (intent) async {
              final slot = intent.target;
              if (!slot.isConfigured) {
                return false;
              }

              final bool? deleted = await withContext(
                (context) async =>
                    await showDialog(
                      context: context,
                      builder: (context) => DeleteSlotDialog(devicePath, slot),
                    ) ??
                    false,
              );
              return deleted;
            },
          ),
      },
      child: Builder(
        // Builder to ensure new scope for actions, they can invoke parent actions
        builder: (context) {
          final child = Builder(builder: builder);
          return actions != null
              ? Actions(actions: actions!(context), child: child)
              : child;
        },
      ),
    );
  }
}

List<ActionItem> buildSlotActions(OtpSlot slot, AppLocalizations l10n) {
  return [
    ActionItem(
      key: keys.configureYubiOtp,
      feature: features.slotsConfigureYubiOtp,
      icon: const Icon(Symbols.shuffle),
      title: l10n.s_capability_otp,
      subtitle: l10n.l_yubiotp_desc,
      intent: ConfigureYubiOtpIntent(slot),
    ),
    ActionItem(
      key: keys.configureChalResp,
      feature: features.slotsConfigureChalResp,
      icon: const Icon(Symbols.key),
      title: l10n.s_challenge_response,
      subtitle: l10n.l_challenge_response_desc,
      intent: ConfigureChalRespIntent(slot),
    ),
    ActionItem(
      key: keys.configureStatic,
      feature: features.slotsConfigureStatic,
      icon: const Icon(Symbols.password),
      title: l10n.s_static_password,
      subtitle: l10n.l_static_password_desc,
      intent: ConfigureStaticIntent(slot),
    ),
    ActionItem(
      key: keys.configureHotp,
      feature: features.slotsConfigureHotp,
      icon: const Icon(Symbols.tag),
      title: l10n.s_hotp,
      subtitle: l10n.l_hotp_desc,
      intent: ConfigureHotpIntent(slot),
    ),
    ActionItem(
      key: keys.deleteAction,
      feature: features.slotsDelete,
      actionStyle: ActionStyle.error,
      icon: const Icon(Symbols.delete),
      title: l10n.s_delete_slot,
      subtitle: l10n.l_delete_slot_desc,
      intent: slot.isConfigured ? DeleteIntent(slot) : null,
    ),
  ];
}
