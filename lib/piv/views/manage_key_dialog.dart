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
  late bool _defaultKeyUsed;
  late bool _usesStoredKey;
  late bool _storeKey;
  String _currentKeyOrPin = '';
  bool _currentIsWrong = false;
  int _attemptsRemaining = -1;
  String _newKey = '';
  ManagementKeyType _keyType = ManagementKeyType.tdes;

  @override
  void initState() {
    super.initState();

    _defaultKeyUsed =
        widget.pivState.metadata?.managementKeyMetadata.defaultValue ?? false;
    _usesStoredKey = widget.pivState.protectedKey;
    if (!_usesStoredKey && _defaultKeyUsed) {
      _currentKeyOrPin = defaultManagementKey;
    }
    _storeKey = _usesStoredKey;
  }

  _submit() async {
    final notifier = ref.read(pivStateProvider(widget.path).notifier);
    if (_usesStoredKey) {
      final status = (await notifier.verifyPin(_currentKeyOrPin)).when(
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
      if (!await notifier.authenticate(_currentKeyOrPin)) {
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

    await notifier.setManagementKey(_newKey,
        managementKeyType: _keyType, storeKey: _storeKey);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    showMessage(context, l10n.l_management_key_changed);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentType = widget.pivState.metadata?.managementKeyMetadata.keyType;
    final hexLength = _keyType.keyLength * 2;

    return ResponsiveDialog(
      title: Text(l10n.l_change_management_key),
      actions: [
        TextButton(
          onPressed: _submit,
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
            if (widget.pivState.protectedKey)
              TextField(
                autofocus: true,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                key: keys.managementKeyField,
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
                    _currentKeyOrPin = value;
                  });
                },
              ),
            if (!widget.pivState.protectedKey)
              TextFormField(
                key: keys.pinPukField,
                autofocus: !_defaultKeyUsed,
                autofillHints: const [AutofillHints.password],
                initialValue: _defaultKeyUsed ? defaultManagementKey : null,
                readOnly: _defaultKeyUsed,
                maxLength: !_defaultKeyUsed && currentType != null
                    ? currentType.keyLength * 2
                    : null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_current_management_key,
                  prefixIcon: const Icon(Icons.password_outlined),
                  errorText: _currentIsWrong ? l10n.l_wrong_key : null,
                  errorMaxLines: 3,
                  helperText: _defaultKeyUsed ? l10n.l_default_key_used : null,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  setState(() {
                    _currentIsWrong = false;
                    _currentKeyOrPin = value;
                  });
                },
              ),
            TextField(
              key: keys.newPinPukField,
              autofocus: _defaultKeyUsed,
              autofillHints: const [AutofillHints.newPassword],
              maxLength: hexLength,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    RegExp('[a-f0-9]', caseSensitive: false))
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_new_management_key,
                prefixIcon: const Icon(Icons.password_outlined),
                enabled: _currentKeyOrPin.isNotEmpty,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _newKey = value;
                });
              },
              onSubmitted: (_) {
                if (_newKey.length == hexLength) {
                  _submit();
                }
              },
            ),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4.0,
                runSpacing: 8.0,
                children: [
                  if (currentType != null)
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
