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

import '../../app/models.dart';
import '../../core/models.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;

class GenerateKeyDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final PivState pivState;
  final PivSlot pivSlot;
  const GenerateKeyDialog(this.devicePath, this.pivState, this.pivSlot,
      {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GenerateKeyDialogState();
}

class _GenerateKeyDialogState extends ConsumerState<GenerateKeyDialog> {
  String _subject = '';
  GenerateType _generateType = defaultGenerateType;
  KeyType _keyType = defaultKeyType;
  late DateTime _validFrom;
  late DateTime _validTo;
  late DateTime _validToDefault;
  late DateTime _validToMax;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _validFrom = DateTime.utc(now.year, now.month, now.day);
    _validToDefault = DateTime.utc(now.year + 1, now.month, now.day);
    _validTo = _validToDefault;
    _validToMax = DateTime.utc(now.year + 10, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    return ResponsiveDialog(
      title: Text(l10n.s_generate_key),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: () async {
            final result = await ref
                .read(pivSlotsProvider(widget.devicePath).notifier)
                .generate(
                  widget.pivSlot.slot,
                  _keyType,
                  parameters: switch (_generateType) {
                    GenerateType.certificate =>
                      PivGenerateParameters.certificate(
                          subject: _subject,
                          validFrom: _validFrom,
                          validTo: _validTo),
                    GenerateType.csr =>
                      PivGenerateParameters.csr(subject: _subject),
                  },
                );

            navigator.pop(result);
          },
          child: Text(l10n.s_save),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              autofocus: true,
              key: keys.subjectField,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_subject,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _subject = value.contains('=') ? value : 'CN=$value';
                });
              },
            ),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4.0,
                runSpacing: 8.0,
                children: [
                  ChoiceFilterChip<GenerateType>(
                    items: GenerateType.values,
                    value: _generateType,
                    selected: _generateType != defaultGenerateType,
                    itemBuilder: (value) => Text(value.getDisplayName(l10n)),
                    onChanged: (value) {
                      setState(() {
                        _generateType = value;
                      });
                    },
                  ),
                  ChoiceFilterChip<KeyType>(
                    items: KeyType.values,
                    value: _keyType,
                    selected: _keyType != defaultKeyType,
                    itemBuilder: (value) => Text(value.getDisplayName(l10n)),
                    onChanged: (value) {
                      setState(() {
                        _keyType = value;
                      });
                    },
                  ),
                  if (_generateType == GenerateType.certificate)
                    FilterChip(
                      label: Text(dateFormatter.format(_validTo)),
                      onSelected: (value) async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _validTo,
                          firstDate: _validFrom,
                          lastDate: _validToMax,
                        );
                        if (selected != null) {
                          setState(() {
                            _validTo = selected;
                          });
                        }
                      },
                    ),
                ]),
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
