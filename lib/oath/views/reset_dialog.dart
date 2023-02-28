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
import '../../widgets/responsive_dialog.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class ResetDialog extends ConsumerWidget {
  final DevicePath devicePath;
  const ResetDialog(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ResponsiveDialog(
      title: Text(l10n.l_factory_reset),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(oathStateProvider(devicePath).notifier).reset();
            await ref.read(withContextProvider)((context) async {
              Navigator.of(context).pop();
              showMessage(context, l10n.l_oath_application_reset);
            });
          },
          child: Text(l10n.w_reset),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          children: [
            Text(
              l10n.p_warning_factory_reset,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(l10n.p_warning_disable_credentials),
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
