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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'overwrite_confirm_dialog.dart';
import 'utils.dart';

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
  bool _invalidSubject = true;
  GenerateType _generateType = defaultGenerateType;
  KeyType _keyType = defaultKeyType;
  late DateTime _validFrom;
  late DateTime _validTo;
  late DateTime _validToDefault;
  late DateTime _validToMax;
  bool _generating = false;

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
    final textTheme = Theme.of(context).textTheme;
    // This is what ListTile uses for subtitle
    final subtitleStyle = textTheme.bodyMedium!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    final isFips =
        ref.watch(currentDeviceDataProvider).valueOrNull?.info.isFips ?? false;

    final canSave = !_generating &&
        (!_invalidSubject || _generateType == GenerateType.publicKey);

    return ResponsiveDialog(
      allowCancel: !_generating,
      title: Text(l10n.s_generate_key),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: canSave
              ? () async {
                  if (!await confirmOverwrite(
                    context,
                    widget.pivSlot,
                    writeKey: true,
                    writeCert: _generateType == GenerateType.certificate,
                  )) {
                    return;
                  }

                  setState(() {
                    _generating = true;
                  });

                  final pivNotifier =
                      ref.read(pivSlotsProvider(widget.devicePath).notifier);

                  if (!(_generateType == GenerateType.publicKey ||
                      await pivNotifier.validateRfc4514(_subject))) {
                    setState(() {
                      _generating = false;
                      _invalidSubject = true;
                    });
                    return;
                  }

                  final result = await pivNotifier.generate(
                    widget.pivSlot.slot,
                    _keyType,
                    parameters: switch (_generateType) {
                      GenerateType.publicKey =>
                        PivGenerateParameters.publicKey(),
                      GenerateType.certificate =>
                        PivGenerateParameters.certificate(
                            subject: _subject,
                            validFrom: _validFrom,
                            validTo: _validTo),
                      GenerateType.csr =>
                        PivGenerateParameters.csr(subject: _subject),
                    },
                  );

                  await ref.read(withContextProvider)(
                    (context) async {
                      Navigator.of(context).pop(result);
                      showMessage(
                        context,
                        l10n.s_private_key_generated,
                      );
                    },
                  );
                }
              : null,
          child: Text(l10n.s_save),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                l10n.p_generate_desc(widget.pivSlot.slot.getDisplayName(l10n))),
            Text(
              l10n.s_subject,
              style: textTheme.bodyLarge,
            ),
            Text(l10n.p_subject_desc),
            AppTextField(
              autofocus: true,
              key: keys.subjectField,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_subject,
                errorText: _subject.isNotEmpty && _invalidSubject
                    ? l10n.l_rfc4514_invalid
                    : null,
              ),
              textInputAction: TextInputAction.next,
              enabled: !_generating && _generateType != GenerateType.publicKey,
              onChanged: (value) {
                setState(() {
                  _invalidSubject = value.isEmpty;
                  _subject = value;
                });
              },
            ).init(),
            Text(
              l10n.rfc4514_examples,
              style: subtitleStyle,
            ),
            Text(
              l10n.s_options,
              style: textTheme.bodyLarge,
            ),
            Text(l10n.p_cert_options_desc),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4.0,
                runSpacing: 8.0,
                children: [
                  ChoiceFilterChip<KeyType>(
                    items:
                        getSupportedKeyTypes(widget.pivState.version, isFips),
                    value: _keyType,
                    selected: _keyType != defaultKeyType,
                    itemBuilder: (value) => Text(value.getDisplayName(l10n)),
                    onChanged: _generating
                        ? null
                        : (value) {
                            setState(() {
                              _keyType = value;
                              if (value == KeyType.x25519) {
                                _generateType = GenerateType.publicKey;
                              }
                            });
                          },
                  ),
                  ChoiceFilterChip<GenerateType>(
                    items: GenerateType.values,
                    value: _generateType,
                    selected: _generateType != defaultGenerateType,
                    itemBuilder: (value) => Text(value.getDisplayName(l10n)),
                    onChanged: _generating || _keyType == KeyType.x25519
                        ? null
                        : (value) {
                            setState(() {
                              _generateType = value;
                            });
                          },
                  ),
                  if (_generateType == GenerateType.certificate)
                    FilterChip(
                      label: Text(dateFormatter.format(_validTo)),
                      onSelected: _generating
                          ? null
                          : (value) async {
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Visibility(
                visible: _generating,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: const LinearProgressIndicator(),
              ),
            ),
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
