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
import '../models.dart';

class CertInfoTable extends ConsumerWidget {
  final CertInfo certInfo;

  const CertInfoTable(this.certInfo, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    // This is what ListTile uses for subtitle
    final subtitleStyle = textTheme.bodyMedium!.copyWith(
      color: textTheme.bodySmall!.color,
    );
    final dateFormat =
        DateFormat.yMMMEd(ref.watch(currentLocaleProvider).toString());
    final clipboard = ref.watch(clipboardProvider);
    final withContext = ref.watch(withContextProvider);

    Widget header(String title) => Text(
          title,
          textAlign: TextAlign.right,
        );

    Widget body(String title, String value) => GestureDetector(
          onDoubleTap: () async {
            await clipboard.setText(value);
            if (!clipboard.platformGivesFeedback()) {
              await withContext((context) async {
                showMessage(context, l10n.p_target_copied_clipboard(title));
              });
            }
          },
          child: TooltipIfTruncated(
            text: value,
            style: subtitleStyle,
            tooltip: value.replaceAllMapped(
                RegExp(r',([A-Z]+)='), (match) => '\n${match[1]}='),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            header(l10n.s_subject),
            header(l10n.s_issuer),
            header(l10n.s_serial),
            header(l10n.s_certificate_fingerprint),
            header(l10n.s_valid_from),
            header(l10n.s_valid_to),
          ],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              body(l10n.s_subject, certInfo.subject),
              body(l10n.s_issuer, certInfo.issuer),
              body(l10n.s_serial, certInfo.serial),
              body(l10n.s_certificate_fingerprint, certInfo.fingerprint),
              body(l10n.s_valid_from,
                  dateFormat.format(DateTime.parse(certInfo.notValidBefore))),
              body(l10n.s_valid_to,
                  dateFormat.format(DateTime.parse(certInfo.notValidAfter))),
            ],
          ),
        ),
      ],
    );
  }
}
