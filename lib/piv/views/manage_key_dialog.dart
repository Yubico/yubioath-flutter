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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../theme.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/visibility_icon.dart';
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
  late bool _usesStoredKey;
  late bool _storeKey;
  bool _currentIsWrong = false;
  bool _currentInvalidFormat = false;
  bool _newInvalidFormat = false;
  int _attemptsRemaining = -1;
  ManagementKeyType _keyType = ManagementKeyType.tdes;
  final _currentController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();

    _hasMetadata = widget.pivState.metadata != null;
    _defaultKeyUsed =
        widget.pivState.metadata?.managementKeyMetadata.defaultValue ?? false;
    _usesStoredKey = widget.pivState.protectedKey;
    if (!_usesStoredKey && _defaultKeyUsed) {
      _currentController.text = defaultManagementKey;
    }
    _storeKey = _usesStoredKey;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  _submit() async {
    final currentInvalidFormat = Format.hex.isValid(_currentController.text);
    final newInvalidFormat = Format.hex.isValid(_keyController.text);
    if (!currentInvalidFormat || !newInvalidFormat) {
      setState(() {
        _currentInvalidFormat = !currentInvalidFormat;
        _newInvalidFormat = !newInvalidFormat;
      });
      return;
    }

    final notifier = ref.read(pivStateProvider(widget.path).notifier);
    if (_usesStoredKey) {
      final status = (await notifier.verifyPin(_currentController.text)).when(
        success: () => true,
        failure: (attemptsRemaining) {
          setState(() {
            _attemptsRemaining = attemptsRemaining;
            _currentIsWrong = true;
          });
          return false;
        },
      );
      if (!status) {
        return;
      }
    } else {
      if (!await notifier.authenticate(_currentController.text)) {
        setState(() {
          _currentIsWrong = true;
        });
        return;
      }
    }

    if (_storeKey && !_usesStoredKey) {
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
    final currentType =
        widget.pivState.metadata?.managementKeyMetadata.keyType ??
            ManagementKeyType.tdes;
    final hexLength = _keyType.keyLength * 2;
    final protected = widget.pivState.protectedKey;
    final currentKeyOrPin = _currentController.text;
    final currentLenOk = protected
        ? currentKeyOrPin.length >= 4
        : currentKeyOrPin.length == currentType.keyLength * 2;
    final newLenOk = _keyController.text.length == hexLength;

    return ResponsiveDialog(
      title: Text(l10n.l_change_management_key),
      actions: [
        TextButton(
          onPressed: currentLenOk && newLenOk ? _submit : null,
          key: keys.saveButton,
          child: Text(l10n.s_save),
        )
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.p_change_management_key_desc),
            if (protected)
              AppTextField(
                autofocus: true,
                obscureText: _isObscure,
                autofillHints: const [AutofillHints.password],
                key: keys.pinPukField,
                maxLength: 8,
                controller: _currentController,
                decoration: AppInputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_pin,
                  errorText: _currentIsWrong
                      ? l10n.l_wrong_pin_attempts_remaining(_attemptsRemaining)
                      : _currentInvalidFormat
                          ? l10n.l_invalid_format_allowed_chars(
                              Format.hex.allowedCharacters)
                          : null,
                  errorMaxLines: 3,
                  prefixIcon: const Icon(Icons.pin_outlined),
                  suffixIcon: IconButton(
                      icon: VisibilityIcon(_isObscure),
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
              ),
            if (!protected)
              AppTextFormField(
                key: keys.managementKeyField,
                autofocus: !_defaultKeyUsed,
                autofillHints: const [AutofillHints.password],
                controller: _currentController,
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
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: _hasMetadata
                      ? null
                      : IconButton(
                          icon: Icon(_defaultKeyUsed
                              ? Icons.auto_awesome
                              : Icons.auto_awesome_outlined),
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
              ),
            AppTextField(
              key: keys.newPinPukField,
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
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  key: keys.managementKeyRefresh,
                  icon: const Icon(Icons.refresh),
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
            ),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4.0,
                runSpacing: 8.0,
                children: [
                  if (widget.pivState.metadata != null)
                    ChoiceFilterChip<ManagementKeyType>(
                      items: ManagementKeyType.values,
                      value: _keyType,
                      selected: _keyType != defaultManagementKeyType,
                      itemBuilder: (value) => Text(value.getDisplayName(l10n)),
                      onChanged: (value) {
                        setState(() {
                          _keyType = value;
                        });
                      },
                    ),
                  FilterChip(
                    key: keys.pinLockManagementKeyChip,
                    backgroundColor: surfaceVariantOf(context),
                    label: Text(l10n.s_protect_key),
                    selected: _storeKey,
                    onSelected: (value) {
                      setState(() {
                        _storeKey = value;
                      });
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
