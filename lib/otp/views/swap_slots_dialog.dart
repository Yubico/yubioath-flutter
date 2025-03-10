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
import '../../app/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/basic_dialog.dart';
import '../keys.dart';
import '../state.dart';

class SwapSlotsDialog extends ConsumerWidget {
  final DevicePath devicePath;
  const SwapSlotsDialog(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return BasicDialog(
      icon: Icon(Symbols.swap_vert),
      title: Text(l10n.q_swap_slots),
      actions: [
        TextButton(
          key: swapButton,
          onPressed: () async {
            try {
              await ref.read(otpStateProvider(devicePath).notifier).swapSlots();
              await ref.read(withContextProvider)((context) async {
                Navigator.of(context).pop();
                showMessage(context, l10n.l_slots_swapped);
              });
            } catch (e) {
              await ref.read(withContextProvider)((context) async {
                Navigator.of(context).pop();
                showMessage(context, l10n.p_otp_swap_error);
              });
            }
          },
          child: Text(l10n.s_swap),
        ),
      ],
      content: Text(
        l10n.p_swap_slots_desc,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
