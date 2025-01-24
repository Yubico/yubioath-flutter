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
import 'package:intl/intl.dart';

import '../../app/state.dart';
import '../../widgets/info_table.dart';
import '../keys.dart' as keys;
import '../models.dart';

class CertInfoTable extends ConsumerWidget {
  final CertInfo? certInfo;
  final SlotMetadata? metadata;
  final bool alwaysIncludePrivate;
  final bool supportsBio;

  const CertInfoTable(this.certInfo, this.metadata,
      {super.key, this.alwaysIncludePrivate = false, this.supportsBio = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat =
        DateFormat.yMMMEd(ref.watch(currentLocaleProvider).locale.toString());

    final certInfo = this.certInfo;
    final metadata = this.metadata;
    return InfoTable({
      if (metadata != null)
        l10n.s_private_key: (
          metadata.keyType.getDisplayName(l10n),
          keys.slotMetadataKeyType
        ),
      if (metadata != null &&
          metadata.pinPolicy != PinPolicy.never &&
          supportsBio)
        l10n.s_biometrics: (
          [PinPolicy.matchAlways, PinPolicy.matchOnce]
                  .contains(metadata.pinPolicy)
              ? l10n.s_enabled
              : l10n.s_disabled,
          keys.slotMetadataBiometrics
        ),
      if (metadata == null && alwaysIncludePrivate)
        l10n.s_private_key: (l10n.s_none, keys.slotMetadataKeyType),
      if (certInfo != null) ...{
        l10n.s_public_key: (
          certInfo.keyType?.getDisplayName(l10n) ?? l10n.s_unknown_type,
          keys.certInfoKeyType
        ),
        l10n.s_subject: (certInfo.subject, keys.certInfoSubject),
        l10n.s_issuer: (certInfo.issuer, keys.certInfoIssuer),
        l10n.s_serial: (certInfo.serial, keys.certInfoSerial),
        l10n.s_certificate_fingerprint: (
          certInfo.fingerprint,
          keys.certInfoFingerprint
        ),
        l10n.s_valid_from: (
          dateFormat.format(DateTime.parse(certInfo.notValidBefore)),
          keys.certInfoValidFrom
        ),
        l10n.s_valid_to: (
          dateFormat.format(DateTime.parse(certInfo.notValidAfter)),
          keys.certInfoValidTo
        ),
      },
    });
  }
}
