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

enum BiometricsDialogVariant { disabled, invalidated }

class BiometricsInfoDialog extends ConsumerWidget {
  final BiometricsDialogVariant _variant;

  const BiometricsInfoDialog(this._variant, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.l_biometrics_dialog_title),
      titlePadding: const EdgeInsets.only(top: 24, left: 18, right: 18),
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Text(_variant == BiometricsDialogVariant.invalidated
                  ? l10n.p_biometrics_dialog_invalidated
                  : l10n.p_biometrics_dialog_disabled)
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(l10n.s_close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
