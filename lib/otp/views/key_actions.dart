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
import '../../app/views/action_list.dart';
import '../../app/views/fs_dialog.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import 'swap_slots_dialog.dart';

Widget otpBuildActions(BuildContext context, DevicePath devicePath,
    OtpState otpState, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;

  return FsDialog(
    child: Column(
      children: [
        ActionListSection(l10n.s_manage, children: [
          ActionListItem(
            key: keys.swapSlots,
            feature: features.actionsSwap,
            title: l10n.s_swap_slots,
            subtitle: l10n.l_swap_slots_desc,
            icon: const Icon(Icons.swap_vert_outlined),
            onTap: (otpState.slot1Configured || otpState.slot2Configured)
                ? (context) {
                    Navigator.of(context).pop();
                    showBlurDialog(
                        context: context,
                        builder: (context) => SwapSlotsDialog(devicePath));
                  }
                : null,
          )
        ])
      ],
    ),
  );
}
