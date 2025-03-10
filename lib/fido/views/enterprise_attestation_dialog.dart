/*
 * Copyright (C) 2022-2025 Yubico.
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
import '../state.dart';

class EnableEnterpriseAttestationDialog extends ConsumerWidget {
  final DevicePath devicePath;
  const EnableEnterpriseAttestationDialog(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return BasicDialog(
      icon: Icon(Symbols.local_police),
      title: Text(l10n.q_enable_ep_attestation),
      actions: [
        TextButton(
          onPressed: () async {
            await ref
                .read(fidoStateProvider(devicePath).notifier)
                .enableEnterpriseAttestation();
            await ref.read(withContextProvider)((context) async {
              Navigator.of(context).pop();
              showMessage(context, l10n.s_ep_attestation_enabled);
            });
          },
          child: Text(l10n.s_enable),
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.p_enable_ep_attestation_desc,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8.0),
          Text(l10n.p_enable_ep_attestation_disable_with_factory_reset),
        ],
      ),
    );
  }
}
