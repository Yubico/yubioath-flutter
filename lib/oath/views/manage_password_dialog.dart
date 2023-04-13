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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;

class ManagePasswordDialog extends ConsumerStatefulWidget {
  final DevicePath path;
  final OathState state;
  const ManagePasswordDialog(this.path, this.state, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagePasswordDialogState();
}

class _ManagePasswordDialogState extends ConsumerState<ManagePasswordDialog> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _currentIsWrong = false;

  _submit() async {
    final result = await ref
        .read(oathStateProvider(widget.path).notifier)
        .setPassword(_currentPassword, _newPassword);
    if (result) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, AppLocalizations.of(context)!.s_password_set);
    } else {
      setState(() {
        _currentIsWrong = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isValid = _newPassword.isNotEmpty &&
        _newPassword == _confirmPassword &&
        (!widget.state.hasKey || _currentPassword.isNotEmpty);

    return ResponsiveDialog(
      title: Text(l10n.s_manage_password),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          key: keys.savePasswordButton,
          child: Text(l10n.s_save),
        )
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.state.hasKey) ...[
              Text(l10n.p_enter_current_password_or_reset),
              TextField(
                autofocus: true,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                key: keys.currentPasswordField,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.s_current_password,
                    prefixIcon: const Icon(Icons.password_outlined),
                    errorText: _currentIsWrong ? l10n.s_wrong_password : null,
                    errorMaxLines: 3),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  setState(() {
                    _currentIsWrong = false;
                    _currentPassword = value;
                  });
                },
              ),
              Wrap(
                spacing: 4.0,
                runSpacing: 8.0,
                children: [
                  OutlinedButton(
                    key: keys.removePasswordButton,
                    onPressed: _currentPassword.isNotEmpty
                        ? () async {
                            final result = await ref
                                .read(oathStateProvider(widget.path).notifier)
                                .unsetPassword(_currentPassword);
                            if (result) {
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              showMessage(context, l10n.s_password_removed);
                            } else {
                              setState(() {
                                _currentIsWrong = true;
                              });
                            }
                          }
                        : null,
                    child: Text(l10n.s_remove_password),
                  ),
                  if (widget.state.remembered)
                    OutlinedButton(
                      child: Text(l10n.s_clear_saved_password),
                      onPressed: () async {
                        await ref
                            .read(oathStateProvider(widget.path).notifier)
                            .forgetPassword();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        showMessage(context, l10n.s_password_forgotten);
                      },
                    ),
                ],
              ),
            ],
            Text(l10n.p_enter_new_password),
            TextField(
              key: keys.newPasswordField,
              autofocus: !widget.state.hasKey,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_new_password,
                prefixIcon: const Icon(Icons.password_outlined),
                enabled: !widget.state.hasKey || _currentPassword.isNotEmpty,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _newPassword = value;
                });
              },
              onSubmitted: (_) {
                if (isValid) {
                  _submit();
                }
              },
            ),
            TextField(
              key: keys.confirmPasswordField,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_confirm_password,
                prefixIcon: const Icon(Icons.password_outlined),
                enabled:
                    (!widget.state.hasKey || _currentPassword.isNotEmpty) &&
                        _newPassword.isNotEmpty,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  _confirmPassword = value;
                });
              },
              onSubmitted: (_) {
                if (isValid) {
                  _submit();
                }
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
