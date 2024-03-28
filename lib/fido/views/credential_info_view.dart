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

import '../../widgets/info_table.dart';
import '../keys.dart' as keys;
import '../models.dart';

class CredentialInfoTable extends ConsumerWidget {
  final FidoCredential credential;

  const CredentialInfoTable(this.credential, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final credential = this.credential;
    return InfoTable({
      l10n.s_rp_id: (credential.rpId, keys.credentialInfoRpId),
      l10n.s_display_name: (
        credential.userName,
        keys.credentialInfoDisplayName
      ),
      l10n.s_user_name: (credential.userName, keys.credentialInfoUserName),
      l10n.s_user_id: (credential.userId, keys.credentialInfoUserId),
      l10n.s_credential_id: (
        credential.credentialId,
        keys.credentialInfoCredentialId
      ),
    });
  }
}
