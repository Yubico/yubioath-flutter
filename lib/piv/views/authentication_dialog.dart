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
import 'package:yubico_authenticator/core/models.dart';

import '../../app/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';

class AuthenticationDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final PivState pivState;
  const AuthenticationDialog(this.devicePath, this.pivState, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AuthenticationDialogState();
}

class _AuthenticationDialogState extends ConsumerState<AuthenticationDialog> {
  bool _defaultKeyUsed = false;
  bool _keyIsWrong = false;
  bool _keyFormatInvalid = false;
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasMetadata = widget.pivState.metadata != null;
    final keyLen = (widget.pivState.metadata?.managementKeyMetadata.keyType ??
                ManagementKeyType.tdes)
            .keyLength *
        2;
    final keyFormatInvalid = !Format.hex.isValid(_keyController.text);
    return ResponsiveDialog(
      title: Text(l10n.l_unlock_piv_management),
      actions: [
        TextButton(
          key: keys.unlockButton,
          onPressed: _keyController.text.length == keyLen
              ? () async {
                  if (keyFormatInvalid) {
                    setState(() {
                      _keyFormatInvalid = true;
                    });
                    return;
                  }
                  final navigator = Navigator.of(context);
                  try {
                    final status = await ref
                        .read(pivStateProvider(widget.devicePath).notifier)
                        .authenticate(_keyController.text);
                    if (status) {
                      navigator.pop(true);
                    } else {
                      setState(() {
                        _keyIsWrong = true;
                      });
                    }
                  } on CancellationException catch (_) {
                    navigator.pop(false);
                  } catch (_) {
                    // TODO: More error cases
                    setState(() {
                      _keyIsWrong = true;
                    });
                  }
                }
              : null,
          child: Text(l10n.s_unlock),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.p_unlock_piv_management_desc),
            AppTextField(
              key: keys.managementKeyField,
              autofocus: true,
              autofillHints: const [AutofillHints.password],
              controller: _keyController,
              readOnly: _defaultKeyUsed,
              maxLength: !_defaultKeyUsed ? keyLen : null,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_management_key,
                helperText: _defaultKeyUsed ? l10n.l_default_key_used : null,
                errorText: _keyIsWrong
                    ? l10n.l_wrong_key
                    : _keyFormatInvalid
                        ? l10n.l_invalid_format_allowed_chars(
                            Format.hex.allowedCharacters)
                        : null,
                errorMaxLines: 3,
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: hasMetadata && (!_keyIsWrong && !_keyFormatInvalid)
                    ? null
                    : hasMetadata && (_keyIsWrong || _keyFormatInvalid)
                        ? const Icon(Icons.error)
                        : Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(_defaultKeyUsed
                                    ? Icons.auto_awesome
                                    : Icons.auto_awesome_outlined),
                                tooltip: l10n.s_use_default,
                                onPressed: () {
                                  setState(() {
                                    _keyFormatInvalid = false;
                                    _defaultKeyUsed = !_defaultKeyUsed;
                                    if (_defaultKeyUsed) {
                                      _keyController.text =
                                          defaultManagementKey;
                                    } else {
                                      _keyController.clear();
                                    }
                                  });
                                },
                              ),
                              if (_keyIsWrong || _keyFormatInvalid) ...[
                                const Icon(Icons.error_outlined),
                                const SizedBox(
                                  width: 8.0,
                                )
                              ]
                            ],
                          ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _keyIsWrong = false;
                  _keyFormatInvalid = false;
                });
              },
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
