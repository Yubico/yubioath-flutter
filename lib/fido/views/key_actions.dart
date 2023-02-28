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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../widgets/list_title.dart';
import '../models.dart';
import 'add_fingerprint_dialog.dart';
import 'pin_dialog.dart';
import 'reset_dialog.dart';

Widget fidoBuildActions(
    BuildContext context, DeviceNode node, FidoState state, int fingerprints) {
  final theme = Theme.of(context).colorScheme;
  return SimpleDialog(
    children: [
      if (state.bioEnroll != null) ...[
        ListTitle(AppLocalizations.of(context)!.w_setup,
            textStyle: Theme.of(context).textTheme.bodyLarge),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.fingerprint_outlined)),
          title: Text(AppLocalizations.of(context)!.l_add_fingerprint),
          subtitle: state.unlocked
              ? Text(AppLocalizations.of(context)!
                  .l_fingerprints_used(fingerprints))
              : Text(state.hasPin
                  ? AppLocalizations.of(context)!.l_unlock_pin_first
                  : AppLocalizations.of(context)!.l_set_pin_first),
          enabled: state.unlocked && fingerprints < 5,
          onTap: state.unlocked && fingerprints < 5
              ? () {
                  Navigator.of(context).pop();
                  showBlurDialog(
                    context: context,
                    builder: (context) => AddFingerprintDialog(node.path),
                  );
                }
              : null,
        ),
      ],
      ListTitle(AppLocalizations.of(context)!.w_manage,
          textStyle: Theme.of(context).textTheme.bodyLarge),
      ListTile(
          leading: const CircleAvatar(child: Icon(Icons.pin_outlined)),
          title: Text(state.hasPin
              ? AppLocalizations.of(context)!.l_change_pin
              : AppLocalizations.of(context)!.l_set_pin),
          subtitle: Text(state.hasPin
              ? AppLocalizations.of(context)!.l_fido_pin_protection
              : AppLocalizations.of(context)!.l_fido_pin_protection_optional),
          onTap: () {
            Navigator.of(context).pop();
            showBlurDialog(
              context: context,
              builder: (context) => FidoPinDialog(node.path, state),
            );
          }),
      ListTile(
        leading: CircleAvatar(
          foregroundColor: theme.onError,
          backgroundColor: theme.error,
          child: const Icon(Icons.delete_outline),
        ),
        title: Text(AppLocalizations.of(context)!.l_reset_fido),
        subtitle: Text(AppLocalizations.of(context)!.l_factory_reset_this_app),
        onTap: () {
          Navigator.of(context).pop();
          showBlurDialog(
            context: context,
            builder: (context) => ResetDialog(node),
          );
        },
      ),
    ],
  );
}
