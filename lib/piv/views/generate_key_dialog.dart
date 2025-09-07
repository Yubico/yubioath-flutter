/*
 * Copyright (C) 2023-2025 Yubico.
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/info_popup_button.dart';
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
  final bool showMatch;

  GenerateKeyDialog(this.devicePath, this.pivState, this.pivSlot, {super.key})
    : showMatch = pivSlot.slot != SlotId.cardAuth && pivState.supportsBio;

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
  late bool _allowMatch;
  bool _generating = false;
  final _subjectFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _validFrom = DateTime.utc(now.year, now.month, now.day);
    _validToDefault = DateTime.utc(now.year + 1, now.month, now.day);
    _validTo = _validToDefault;
    _validToMax = DateTime.utc(now.year + 10, now.month, now.day);

    _allowMatch = widget.showMatch;
  }

  @override
  void dispose() {
    _subjectFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final isFips =
        ref.watch(currentDeviceDataProvider).valueOrNull?.info.isFips ?? false;

    final canSave =
        !_generating &&
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

                  final pivNotifier = ref.read(
                    pivSlotsProvider(widget.devicePath).notifier,
                  );

                  if (!(_generateType == GenerateType.publicKey ||
                      await pivNotifier.validateRfc4514(_subject))) {
                    setState(() {
                      _generating = false;
                      _invalidSubject = true;
                    });
                    return;
                  }

                  try {
                    final result = await pivNotifier.generate(
                      widget.pivSlot.slot,
                      _keyType,
                      pinPolicy: getPinPolicy(widget.pivSlot.slot, _allowMatch),
                      parameters: switch (_generateType) {
                        GenerateType.publicKey =>
                          PivGenerateParameters.publicKey(),
                        GenerateType.certificate =>
                          PivGenerateParameters.certificate(
                            subject: _subject,
                            validFrom: _validFrom,
                            validTo: _validTo,
                          ),
                        GenerateType.csr => PivGenerateParameters.csr(
                          subject: _subject,
                        ),
                      },
                    );

                    await ref.read(withContextProvider)((context) async {
                      Navigator.of(context).pop(result);
                      showMessage(context, l10n.s_private_key_generated);
                    });
                  } on Exception catch (e) {
                    setState(() {
                      _generating = false;
                    });
                    if (e is! CancellationException) {
                      await ref.read(withContextProvider)((context) async {
                        showExceptionMessage(context, e);
                      });
                    }
                  }
                }
              : null,
          child: Text(l10n.s_save),
        ),
      ],
      builder: (context, fullScreen) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              [
                    Text(
                      l10n.p_generate_desc(
                        widget.pivSlot.slot.getDisplayName(l10n),
                      ),
                    ),
                    AppTextField(
                      autofocus: true,
                      focusNode: _subjectFocus,
                      key: keys.subjectField,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_subject,
                        helperText:
                            '${l10n.p_subject_desc}\n\n${l10n.rfc4514_examples}',
                        helperMaxLines: 10,
                        errorText: _subject.isNotEmpty && _invalidSubject
                            ? '${l10n.l_rfc4514_invalid}\n\n${l10n.rfc4514_examples}'
                            : null,
                        icon: Icon(Symbols.subject),
                      ),
                      textInputAction: TextInputAction.next,
                      enabled:
                          !_generating &&
                          _generateType != GenerateType.publicKey,
                      onChanged: (value) {
                        setState(() {
                          _invalidSubject = value.isEmpty;
                          _subject = value;
                        });
                      },
                    ).init(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Symbols.download,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 16.0),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2.0),
                              Text(
                                l10n.s_output_format,
                                style: textTheme.bodyLarge,
                              ),
                              ...GenerateType.values.map(
                                (e) => ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0.0,
                                  ),
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    e.getDisplayName(l10n),
                                    style: textTheme.bodyMedium,
                                  ),
                                  leading: Radio<GenerateType>(
                                    value: e,
                                    groupValue: _generateType,
                                    onChanged:
                                        (_keyType == KeyType.x25519 &&
                                                e == GenerateType.publicKey) ||
                                            _keyType != KeyType.x25519
                                        ? (value) {
                                            setState(() {
                                              _generateType = e;
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: isAndroid
                              ? const EdgeInsets.fromLTRB(0, 12.0, 0.0, 4.0)
                              : const EdgeInsets.symmetric(vertical: 4.0),
                          child: Icon(
                            Symbols.tune,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Flexible(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.start,
                            spacing: 4.0,
                            runSpacing: 0.0,
                            children: [
                              ChoiceFilterChip<KeyType>(
                                tooltip: l10n.s_algorithm,
                                items: getSupportedKeyTypes(
                                  widget.pivState.version,
                                  isFips,
                                  generateType: _generateType,
                                ),
                                value: _keyType,
                                selected: _keyType != defaultKeyType,
                                itemBuilder: (value) =>
                                    Text(value.getDisplayName(l10n)),
                                onChanged: _generating
                                    ? null
                                    : (value) {
                                        _subjectFocus.unfocus();
                                        setState(() {
                                          _keyType = value;
                                          if (value == KeyType.x25519) {
                                            _generateType =
                                                GenerateType.publicKey;
                                          }
                                        });
                                      },
                              ),
                              FilterChip(
                                tooltip: l10n.s_expiration_date,
                                label: Text(dateFormatter.format(_validTo)),
                                onSelected:
                                    _generating ||
                                        (_generateType !=
                                            GenerateType.certificate)
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
                              if (widget.showMatch)
                                FilterChip(
                                  tooltip: l10n.s_pin_policy,
                                  label: Text(l10n.s_allow_fingerprint),
                                  selected: _allowMatch,
                                  onSelected: _generating
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _allowMatch = value;
                                          });
                                        },
                                ),
                              InfoPopupButton(
                                size: 30,
                                iconSize: 20,
                                displayDialog: fullScreen,
                                infoText: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: l10n.s_algorithm,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(text: '\n'),
                                      TextSpan(
                                        text: l10n.p_algorithm_desc,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      TextSpan(text: '\n' * 2),
                                      TextSpan(
                                        text: l10n.s_expiration_date,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(text: '\n'),
                                      TextSpan(
                                        text: l10n.p_expiration_date_desc,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (widget.showMatch) ...[
                                        TextSpan(text: '\n' * 2),
                                        TextSpan(
                                          text: l10n.s_pin_policy,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(text: '\n'),
                                        TextSpan(
                                          text: l10n.p_key_options_bio_desc,
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (Platform.isAndroid &&
                                  ref
                                          .watch(attachedDevicesProvider)
                                          .firstOrNull
                                          ?.transport !=
                                      Transport.usb &&
                                  [
                                    KeyType.rsa1024,
                                    KeyType.rsa2048,
                                    KeyType.rsa3072,
                                    KeyType.rsa4096,
                                  ].contains(_keyType)) ...[
                                const SizedBox(
                                  width: double.infinity,
                                ), // continue on next line,
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    0,
                                    0,
                                    0,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              0,
                                              0,
                                              4,
                                              0,
                                            ),
                                            child: Icon(
                                              Symbols.warning_amber_rounded,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          text: l10n.p_warning_usb_preferred,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Visibility(
                        visible: _generating,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: LinearProgressIndicator(
                          value: _generating ? null : 0,
                        ),
                      ),
                    ),
                  ]
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: e,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
