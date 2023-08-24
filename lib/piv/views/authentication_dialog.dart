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
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;

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
    return ResponsiveDialog(
      title: Text(l10n.l_unlock_piv_management),
      actions: [
        TextButton(
          key: keys.unlockButton,
          onPressed: _keyController.text.length == keyLen
              ? () async {
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
            TextField(
              key: keys.managementKeyField,
              autofocus: true,
              autofillHints: const [AutofillHints.password],
              controller: _keyController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('[a-f0-9]', caseSensitive: false))
              ],
              readOnly: _defaultKeyUsed,
              maxLength: !_defaultKeyUsed ? keyLen : null,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_management_key,
                prefixIcon: const Icon(Icons.key_outlined),
                errorText: _keyIsWrong ? l10n.l_wrong_key : null,
                errorMaxLines: 3,
                helperText: _defaultKeyUsed ? l10n.l_default_key_used : null,
                suffixIcon: hasMetadata
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
                              _keyController.text = defaultManagementKey;
                            } else {
                              _keyController.clear();
                            }
                          });
                        },
                      ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _keyIsWrong = false;
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
