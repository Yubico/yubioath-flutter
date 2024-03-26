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

import '../../app/message.dart';
import '../../app/state.dart';
import '../../widgets/tooltip_if_truncated.dart';
import '../keys.dart' as keys;
import '../models.dart';

class _InfoTable extends ConsumerWidget {
  final Map<String, (String, Key)> values;

  const _InfoTable(this.values);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    // This is what ListTile uses for subtitle
    final subtitleStyle = textTheme.bodyMedium!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final clipboard = ref.watch(clipboardProvider);
    final withContext = ref.watch(withContextProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: values.keys
              .map((title) => Text(
                    title,
                    textAlign: TextAlign.right,
                  ))
              .toList(),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: values.entries.map((e) {
              final title = e.key;
              final (value, key) = e.value;
              return GestureDetector(
                onDoubleTap: () async {
                  await clipboard.setText(value);
                  if (!clipboard.platformGivesFeedback()) {
                    await withContext((context) async {
                      showMessage(
                          context, l10n.p_target_copied_clipboard(title));
                    });
                  }
                },
                child: TooltipIfTruncated(
                  key: key,
                  text: value,
                  style: subtitleStyle,
                  tooltip: value.replaceAllMapped(
                      RegExp(r',([A-Z]+)='), (match) => '\n${match[1]}='),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class CertInfoTable extends ConsumerWidget {
  final CertInfo? certInfo;
  final SlotMetadata? metadata;
  final bool alwaysIncludePrivate;

  const CertInfoTable(this.certInfo, this.metadata,
      {super.key, this.alwaysIncludePrivate = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat =
        DateFormat.yMMMEd(ref.watch(currentLocaleProvider).toString());

    final certInfo = this.certInfo;
    final metadata = this.metadata;
    return _InfoTable({
      if (metadata != null)
        l10n.s_private_key: (
          metadata.keyType.getDisplayName(l10n),
          keys.slotMetadataKeyType
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
