/*
 * Copyright (C) 2022-2023 Yubico.
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../management/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/info_popup_button.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'pin_dialog.dart';

class ManageKeyDialog extends ConsumerStatefulWidget {
  final DevicePath path;
  final PivState pivState;
  const ManageKeyDialog(this.path, this.pivState, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManageKeyDialogState();
}

class _ManageKeyDialogState extends ConsumerState<ManageKeyDialog> {
  late bool _hasMetadata;
  late bool _defaultKeyUsed;
  late bool _defaultPinUsed;
  late bool _usesStoredKey;
  late bool _storeKey;
  bool _currentIsWrong = false;
  bool _currentInvalidFormat = false;
  bool _newInvalidFormat = false;
  int _attemptsRemaining = -1;
  late ManagementKeyType _keyType;
  final _currentController = TextEditingController();
  final _currentFocus = FocusNode();
  final _keyController = TextEditingController();
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();

    _hasMetadata = widget.pivState.metadata != null;
    _keyType = widget.pivState.metadata?.managementKeyMetadata.keyType ??
        defaultManagementKeyType;
    _defaultKeyUsed =
        widget.pivState.metadata?.managementKeyMetadata.defaultValue ?? false;
    _defaultPinUsed =
        widget.pivState.metadata?.pinMetadata.defaultValue ?? false;
    _usesStoredKey = widget.pivState.protectedKey;
    if (!_usesStoredKey && _defaultKeyUsed) {
      _currentController.text = defaultManagementKey;
    } else if (_usesStoredKey && _defaultPinUsed) {
      _currentController.text = defaultPin;
    }
    _storeKey = _usesStoredKey;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _currentController.dispose();
    _currentFocus.dispose();
    super.dispose();
  }

  _submit() async {
    final currentValidFormat =
        _usesStoredKey || Format.hex.isValid(_currentController.text);
    final newValidFormat = Format.hex.isValid(_keyController.text);
    if (!currentValidFormat || !newValidFormat) {
      setState(() {
        _currentInvalidFormat = !currentValidFormat;
        _newInvalidFormat = !newValidFormat;
      });
      return;
    }

    final notifier = ref.read(pivStateProvider(widget.path).notifier);
    if (_usesStoredKey) {
      final status = (await notifier.verifyPin(_currentController.text)).when(
        success: () => true,
        failure: (reason) {
          reason.maybeWhen(
            invalidPin: (attemptsRemaining) {
              _currentController.selection = TextSelection(
                  baseOffset: 0, extentOffset: _currentController.text.length);
              _currentFocus.requestFocus();
              setState(() {
                _attemptsRemaining = attemptsRemaining;
                _currentIsWrong = true;
              });
            },
            orElse: () {},
          );
          return false;
        },
      );
      if (!status) {
        return;
      }
    } else {
      if (!await notifier.authenticate(_currentController.text)) {
        _currentController.selection = TextSelection(
            baseOffset: 0, extentOffset: _currentController.text.length);
        _currentFocus.requestFocus();
        setState(() {
          _currentIsWrong = true;
        });
        return;
      }
    }

    if (_storeKey && !_usesStoredKey) {
      if (_defaultPinUsed) {
        await notifier.verifyPin(defaultPin);
      } else {
        final withContext = ref.read(withContextProvider);
        final verified = await withContext((context) async =>
                await showBlurDialog(
                    context: context,
                    builder: (context) => PinDialog(widget.path))) ??
            false;

        if (!verified) {
          return;
        }
      }
    }

    await notifier.setManagementKey(_keyController.text,
        managementKeyType: _keyType, storeKey: _storeKey);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    showMessage(context, l10n.l_management_key_changed);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentType =
        widget.pivState.metadata?.managementKeyMetadata.keyType ??
            defaultManagementKeyType;
    final hexLength = _keyType.keyLength * 2;
    final currentKeyOrPin = _currentController.text;
    final currentLenOk = _usesStoredKey
        ? currentKeyOrPin.length >= 4
        : currentKeyOrPin.length == currentType.keyLength * 2;
    final newLenOk = _keyController.text.length == hexLength;
    final (fipsCapable, fipsApproved) = ref
            .watch(currentDeviceDataProvider)
            .valueOrNull
            ?.info
            .getFipsStatus(Capability.piv) ??
        (false, false);
    final fipsUnready = fipsCapable && !fipsApproved;
    final managementKeyTypes = ManagementKeyType.values.toList();
    if (fipsCapable) {
      managementKeyTypes.remove(ManagementKeyType.tdes);
    }

    return ResponsiveDialog(
      title: Text(l10n.l_change_management_key),
      actions: [
        TextButton(
          onPressed:
              !_currentIsWrong && currentLenOk && newLenOk ? _submit : null,
          key: keys.saveButton,
          child: Text(l10n.s_save),
        )
      ],
      builder: (_, fullScreen) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_usesStoredKey)
              AppTextField(
                autofocus: true,
                obscureText: _isObscure,
                autofillHints: const [AutofillHints.password],
                key: keys.pinPukField,
                maxLength: 8,
                inputFormatters: [limitBytesLength(8)],
                buildCounter: buildByteCounterFor(_currentController.text),
                controller: _currentController,
                focusNode: _currentFocus,
                readOnly: _defaultPinUsed,
                decoration: AppInputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_pin,
                  helperText: _defaultPinUsed ? l10n.l_default_pin_used : null,
                  errorText: _currentIsWrong
                      ? l10n.l_wrong_pin_attempts_remaining(_attemptsRemaining)
                      : null,
                  errorMaxLines: 3,
                  icon: const Icon(Symbols.pin),
                  suffixIcon: IconButton(
                      icon: Icon(_isObscure
                          ? Symbols.visibility
                          : Symbols.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      tooltip: _isObscure ? l10n.s_show_pin : l10n.s_hide_pin),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  setState(() {
                    _currentIsWrong = false;
                    _currentInvalidFormat = false;
                  });
                },
              ).init(),
            if (!_usesStoredKey)
              AppTextField(
                key: keys.managementKeyField,
                autofocus: !_defaultKeyUsed,
                autofillHints: const [AutofillHints.password],
                controller: _currentController,
                focusNode: _currentFocus,
                readOnly: _defaultKeyUsed,
                maxLength: !_defaultKeyUsed ? currentType.keyLength * 2 : null,
                decoration: AppInputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_current_management_key,
                  helperText: _defaultKeyUsed ? l10n.l_default_key_used : null,
                  errorText: _currentIsWrong
                      ? l10n.l_wrong_key
                      : _currentInvalidFormat
                          ? l10n.l_invalid_format_allowed_chars(
                              Format.hex.allowedCharacters)
                          : null,
                  errorMaxLines: 3,
                  icon: const Icon(Symbols.key),
                  suffixIcon: _hasMetadata
                      ? null
                      : IconButton(
                          icon: Icon(Symbols.auto_awesome,
                              fill: _defaultKeyUsed ? 1.0 : 0.0),
                          tooltip: l10n.s_use_default,
                          onPressed: () {
                            setState(() {
                              _defaultKeyUsed = !_defaultKeyUsed;
                              if (_defaultKeyUsed) {
                                _currentController.text = defaultManagementKey;
                              } else {
                                _currentController.clear();
                              }
                            });
                          },
                        ),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  setState(() {
                    _currentIsWrong = false;
                  });
                },
              ).init(),
            AppTextField(
              key: keys.newManagementKeyField,
              autofocus: _defaultKeyUsed,
              autofillHints: const [AutofillHints.newPassword],
              maxLength: hexLength,
              controller: _keyController,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_new_management_key,
                errorText: _newInvalidFormat
                    ? l10n.l_invalid_format_allowed_chars(
                        Format.hex.allowedCharacters)
                    : null,
                enabled: currentLenOk,
                icon: const Icon(Symbols.key),
                suffixIcon: IconButton(
                  key: keys.managementKeyRefresh,
                  icon: const Icon(Symbols.refresh),
                  tooltip: l10n.s_generate_random,
                  onPressed: currentLenOk
                      ? () {
                          final random = Random.secure();
                          final key = List.generate(
                              _keyType.keyLength,
                              (_) => random
                                  .nextInt(256)
                                  .toRadixString(16)
                                  .padLeft(2, '0')).join();
                          setState(() {
                            _keyController.text = key;
                            _newInvalidFormat = false;
                          });
                        }
                      : null,
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                setState(() {
                  // Update length
                });
              },
              onSubmitted: (_) {
                if (currentLenOk && newLenOk) {
                  _submit();
                }
              },
            ).init(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                      runSpacing: 8.0,
                      children: [
                        if (widget.pivState.metadata != null)
                          ChoiceFilterChip<ManagementKeyType>(
                            tooltip: l10n.s_management_key_algorithm,
                            items: managementKeyTypes,
                            value: _keyType,
                            selected: _keyType != currentType,
                            itemBuilder: (value) =>
                                Text(value.getDisplayName(l10n)),
                            onChanged: (value) {
                              setState(() {
                                _keyType = value;
                              });
                            },
                          ),
                        if (!fipsUnready)
                          FilterChip(
                            key: keys.pinLockManagementKeyChip,
                            label: Text(l10n.s_protect_key),
                            selected: _storeKey,
                            onSelected: (value) {
                              setState(() {
                                _storeKey = value;
                              });
                            },
                          ),
                        InfoPopupButton(
                          size: 30,
                          iconSize: 20,
                          displayDialog: fullScreen,
                          infoText: RichText(
                            text: TextSpan(
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(
                                  text: l10n.s_management_key_algorithm,
                                  style: textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: '\n'),
                                TextSpan(
                                  text: l10n.p_management_key_algorithm_desc,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                ),
              ],
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
