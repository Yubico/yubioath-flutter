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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../app/views/fs_dialog.dart';
import '../models.dart';
import '../state.dart';
import 'actions.dart';

class SlotDialog extends ConsumerWidget {
  final SlotId slot;
  const SlotDialog(this.slot, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Solve this in a cleaner way
    final node = ref.watch(currentDeviceDataProvider).valueOrNull?.node;
    if (node == null) {
      // The rest of this method assumes there is a device, and will throw an exception if not.
      // This will never be shown, as the dialog will be immediately closed
      return const SizedBox();
    }

    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final otpState = ref.watch(otpStateProvider(node.path)).valueOrNull;
    final otpSlot =
        otpState!.slots.firstWhereOrNull((element) => element.slot == slot);

    if (otpSlot == null) {
      return const FsDialog(child: CircularProgressIndicator());
    }

    return registerOtpActions(node.path, otpSlot,
        ref: ref,
        builder: (context) => FocusScope(
              autofocus: true,
              child: FsDialog(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 48, bottom: 16),
                      child: Column(
                        children: [
                          Text(
                            otpSlot.slot.getDisplayName(l10n),
                            style: textTheme.headlineSmall,
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Icon(
                            Icons.touch_app,
                            size: 100.0,
                          ),
                          const SizedBox(height: 8),
                          Text(otpSlot.isConfigured
                              ? l10n.l_otp_slot_configured
                              : l10n.l_otp_slot_empty)
                        ],
                      ),
                    ),
                    ActionListSection.fromMenuActions(
                      context,
                      l10n.s_setup,
                      actions: buildSlotActions(otpSlot.isConfigured, l10n),
                    )
                  ],
                ),
              ),
            ));
  }
}
