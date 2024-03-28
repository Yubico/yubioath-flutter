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

import '../app/message.dart';
import '../app/state.dart';
import 'tooltip_if_truncated.dart';

class InfoTable extends ConsumerWidget {
  final Map<String, (String, Key)> values;

  const InfoTable(this.values, {super.key});

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
