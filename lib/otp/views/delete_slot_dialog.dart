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
import '../../app/state.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';

class DeleteSlotDialog extends ConsumerWidget {
  final DevicePath devicePath;
  final OtpSlot otpSlot;
  const DeleteSlotDialog(this.devicePath, this.otpSlot, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ResponsiveDialog(
      title: Text(l10n.s_delete_slot),
      actions: [
        TextButton(
          key: keys.deleteButton,
          onPressed: () async {
            try {
              await ref
                  .read(otpStateProvider(devicePath).notifier)
                  .deleteSlot(otpSlot.slot);
              await ref.read(withContextProvider)((context) async {
                Navigator.of(context).pop(true);
                showMessage(context, l10n.l_slot_deleted);
              });
            } catch (e) {
              await ref.read(withContextProvider)((context) async {
                Navigator.of(context).pop(true);
                showMessage(
                  context,
                  l10n.p_otp_slot_configuration_error(
                      otpSlot.slot.getDisplayName(l10n)),
                  duration: const Duration(seconds: 4),
                );
              });
            }
          },
          child: Text(l10n.s_delete),
        )
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n
                .p_warning_delete_slot_configuration(otpSlot.slot.numberId)),
          ]
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: e,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
