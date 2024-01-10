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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/action_list.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'actions.dart';
import 'key_actions.dart';
import 'slot_dialog.dart';

final _selectedSlot = StateProvider<OtpSlot?>(
  (ref) => null,
);

class OtpScreen extends ConsumerWidget {
  final DevicePath devicePath;

  const OtpScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    return ref.watch(otpStateProvider(devicePath)).when(
        loading: () => MessagePage(
              title: Text(l10n.s_slots),
              graphic: const CircularProgressIndicator(),
              delayedContent: true,
            ),
        error: (error, _) =>
            AppFailurePage(title: Text(l10n.s_slots), cause: error),
        data: (otpState) {
          final selected = ref.watch(_selectedSlot);
          return Actions(
            actions: {
              EscapeIntent: CallbackAction<EscapeIntent>(onInvoke: (intent) {
                if (selected != null) {
                  ref.read(_selectedSlot.notifier).state = null;
                } else {
                  Actions.invoke(context, intent);
                }
                return false;
              }),
            },
            child: AppPage(
              title: Text(l10n.s_slots),
              keyActionsBuilder: selected != null
                  ? (context) => registerOtpActions(
                        devicePath,
                        selected,
                        ref: ref,
                        builder: (context) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTitle(l10n.s_details),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                // TODO: Reuse from fingerprint_dialog
                                child: Column(
                                  children: [
                                    Text(
                                      selected.slot.getDisplayName(l10n),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Icon(
                                      Icons.touch_app,
                                      size: 100.0,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(selected.isConfigured
                                        ? l10n.l_otp_slot_configured
                                        : l10n.l_otp_slot_empty)
                                  ],
                                ),
                              ),
                            ),
                            ActionListSection.fromMenuActions(
                              context,
                              l10n.s_setup,
                              actions:
                                  buildSlotActions(selected.isConfigured, l10n),
                            )
                          ],
                        ),
                      )
                  : (hasFeature(features.actions)
                      ? (context) =>
                          otpBuildActions(context, devicePath, otpState, ref)
                      : null),
              builder: (context, expanded) {
                // De-select if window is resized to be non-expanded.
                if (!expanded) {
                  Timer.run(() {
                    ref.read(_selectedSlot.notifier).state = null;
                  });
                }
                return Column(children: [
                  ListTitle(l10n.s_slots),
                  ...otpState.slots.map((e) => registerOtpActions(devicePath, e,
                      ref: ref,
                      actions: {
                        OpenIntent:
                            CallbackAction<OpenIntent>(onInvoke: (_) async {
                          if (expanded) {
                            ref.read(_selectedSlot.notifier).state = e;
                          } else {
                            await showBlurDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (context) => SlotDialog(e.slot),
                            );
                          }
                          return null;
                        }),
                      },
                      builder: (context) => _SlotListItem(e, expanded)))
                ]);
              },
            ),
          );
        });
  }
}

class _SlotListItem extends ConsumerWidget {
  final OtpSlot otpSlot;
  final bool expanded;

  const _SlotListItem(this.otpSlot, this.expanded);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = otpSlot.slot;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isConfigured = otpSlot.isConfigured;
    final hasFeature = ref.watch(featureProvider);
    final selected = ref.watch(_selectedSlot) == otpSlot;

    return AppListItem(
      selected: selected,
      leading: CircleAvatar(
          foregroundColor: colorScheme.onSecondary,
          backgroundColor: colorScheme.secondary,
          child: Text(slot.numberId.toString())),
      title: slot.getDisplayName(l10n),
      subtitle:
          isConfigured ? l10n.l_otp_slot_configured : l10n.l_otp_slot_empty,
      trailing: expanded
          ? null
          : OutlinedButton(
              onPressed: Actions.handler(context, const OpenIntent()),
              child: const Icon(Icons.more_horiz),
            ),
      openOnSingleTap: expanded,
      buildPopupActions: hasFeature(features.slots)
          ? (context) => buildSlotActions(isConfigured, l10n)
          : null,
    );
  }
}
