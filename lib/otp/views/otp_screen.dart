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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../models.dart';
import '../state.dart';
import '../features.dart' as features;
import 'actions.dart';
import 'key_actions.dart';
import 'slot_dialog.dart';

class OtpScreen extends ConsumerWidget {
  final DevicePath devicePath;

  const OtpScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    return ref.watch(otpStateProvider(devicePath)).when(
        loading: () => MessagePage(
              title: Text(l10n.s_otp),
              graphic: const CircularProgressIndicator(),
              delayedContent: true,
            ),
        error: (error, _) =>
            AppFailurePage(title: Text(l10n.s_otp), cause: error),
        data: (otpState) {
          return AppPage(
            title: Text(l10n.s_otp),
            keyActionsBuilder: hasFeature(features.actions)
                ? (context) =>
                    otpBuildActions(context, devicePath, otpState, ref)
                : null,
            child: Column(children: [
              ListTitle(l10n.s_otp_slots),
              ...otpState.slots.map((e) => registerOtpActions(devicePath, e,
                  ref: ref,
                  actions: {
                    OpenIntent: CallbackAction<OpenIntent>(onInvoke: (_) async {
                      await showBlurDialog(
                        context: context,
                        barrierColor: Colors.transparent,
                        builder: (context) => SlotDialog(e.slot),
                      );
                      return null;
                    }),
                  },
                  builder: (context) => _SlotListItem(e)))
            ]),
          );
        });
  }
}

class _SlotListItem extends ConsumerWidget {
  final OtpSlot otpSlot;
  const _SlotListItem(this.otpSlot);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = otpSlot.slot;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isConfigured = otpSlot.isConfigured;
    final hasFeature = ref.watch(featureProvider);

    return Semantics(
        label: slot.getDisplayName(l10n),
        child: AppListItem(
          leading: CircleAvatar(
              foregroundColor: colorScheme.onSecondary,
              backgroundColor: colorScheme.secondary,
              child: Text(slot.numberId.toString())),
          title: slot.getDisplayName(l10n),
          subtitle:
              isConfigured ? l10n.l_otp_slot_configured : l10n.l_otp_slot_empty,
          trailing: OutlinedButton(
            onPressed: Actions.handler(context, const OpenIntent()),
            child: const Icon(Icons.more_horiz),
          ),
          buildPopupActions: hasFeature(features.slots)
              ? (context) => buildSlotActions(isConfigured, l10n)
              : null,
        ));
  }
}
