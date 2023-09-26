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

import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../keys.dart' as keys;

List<ActionItem> buildFingerprintActions(AppLocalizations l10n) {
  return [
    ActionItem(
      key: keys.editFingerintAction,
      icon: const Icon(Icons.edit),
      title: l10n.s_rename_fp,
      subtitle: l10n.l_rename_fp_desc,
      intent: const EditIntent(),
    ),
    ActionItem(
      key: keys.deleteFingerprintAction,
      actionStyle: ActionStyle.error,
      icon: const Icon(Icons.delete),
      title: l10n.s_delete_fingerprint,
      subtitle: l10n.l_delete_fingerprint_desc,
      intent: const DeleteIntent(),
    ),
  ];
}

List<ActionItem> buildCredentialActions(AppLocalizations l10n) {
  return [
    ActionItem(
      key: keys.deleteCredentialAction,
      actionStyle: ActionStyle.error,
      icon: const Icon(Icons.delete),
      title: l10n.s_delete_passkey,
      subtitle: l10n.l_delete_account_desc,
      intent: const DeleteIntent(),
    ),
  ];
}
