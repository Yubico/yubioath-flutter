/*
 * Copyright (C) 2022 Yubico.
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
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;
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
  int _attemptsRemaining = -1;
  ManagementKeyType _keyType = ManagementKeyType.tdes;
  final _currentController = TextEditingController();
  final _keyController = TextEditingController();

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
              TextField(
                autofocus: true,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                key: keys.pinPukField,
                maxLength: 8,
                controller: _currentController,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.s_pin,
                    prefixIcon: const Icon(Icons.pin_outlined),
                    errorText: _currentIsWrong
                        ? l10n
                            .l_wrong_pin_attempts_remaining(_attemptsRemaining)
                        : null,
                    errorMaxLines: 3),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  setState(() {
                    _currentIsWrong = false;
                  });
                },
              ),
            if (!protected)
              TextFormField(
                key: keys.managementKeyField,
                autofocus: !_defaultKeyUsed,
                autofillHints: const [AutofillHints.password],
                controller: _currentController,
                readOnly: _defaultKeyUsed,
                maxLength: !_defaultKeyUsed ? currentType.keyLength * 2 : null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_current_management_key,
                  prefixIcon: const Icon(Icons.key_outlined),
                  errorText: _currentIsWrong ? l10n.l_wrong_key : null,
                  errorMaxLines: 3,
                  helperText: _defaultKeyUsed ? l10n.l_default_key_used : null,
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
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                      RegExp('[a-f0-9]', caseSensitive: false))
                ],
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  setState(() {
                    _currentIsWrong = false;
                  });
                },
              ),
            TextField(
              key: keys.newPinPukField,
              autofocus: _defaultKeyUsed,
              autofillHints: const [AutofillHints.newPassword],
              maxLength: hexLength,
              controller: _keyController,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    RegExp('[a-f0-9]', caseSensitive: false))
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_new_management_key,
                prefixIcon: const Icon(Icons.key_outlined),
                enabled: currentLenOk,
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
                          });
                        }
                      : null,
                ),
              ),
              textInputAction: TextInputAction.next,
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
