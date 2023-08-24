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
import '../state.dart';
import '../keys.dart' as keys;

enum ManageTarget { pin, puk, unblock }

class ManagePinPukDialog extends ConsumerStatefulWidget {
  final DevicePath path;
  final ManageTarget target;
  const ManagePinPukDialog(this.path,
      {super.key, this.target = ManageTarget.pin});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagePinPukDialogState();
}

class _ManagePinPukDialogState extends ConsumerState<ManagePinPukDialog> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _currentIsWrong = false;
  int _attemptsRemaining = -1;

  _submit() async {
    final notifier = ref.read(pivStateProvider(widget.path).notifier);
    final result = await switch (widget.target) {
      ManageTarget.pin => notifier.changePin(_currentPin, _newPin),
      ManageTarget.puk => notifier.changePuk(_currentPin, _newPin),
      ManageTarget.unblock => notifier.unblockPin(_currentPin, _newPin),
    };

    result.when(success: () {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop();
      showMessage(
          context,
          switch (widget.target) {
            ManageTarget.puk => l10n.s_puk_set,
            _ => l10n.s_pin_set,
          });
    }, failure: (attemptsRemaining) {
      setState(() {
        _attemptsRemaining = attemptsRemaining;
        _currentIsWrong = true;
        _currentPin = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isValid =
        _newPin.isNotEmpty && _newPin == _confirmPin && _currentPin.isNotEmpty;

    final titleText = switch (widget.target) {
      ManageTarget.pin => l10n.s_change_pin,
      ManageTarget.puk => l10n.s_change_puk,
      ManageTarget.unblock => l10n.s_unblock_pin,
    };

    return ResponsiveDialog(
      title: Text(titleText),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          key: keys.saveButton,
          child: Text(l10n.s_save),
        )
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //TODO fix string
            Text(widget.target == ManageTarget.pin
                ? l10n.p_enter_current_pin_or_reset
                : l10n.p_enter_current_puk_or_reset),
            TextField(
              autofocus: true,
              obscureText: true,
              maxLength: 8,
              autofillHints: const [AutofillHints.password],
              key: keys.pinPukField,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: widget.target == ManageTarget.pin
                      ? l10n.s_current_pin
                      : l10n.s_current_puk,
                  prefixIcon: const Icon(Icons.password_outlined),
                  errorText: _currentIsWrong
                      ? (widget.target == ManageTarget.pin
                          ? l10n.l_wrong_pin_attempts_remaining(
                              _attemptsRemaining)
                          : l10n.l_wrong_puk_attempts_remaining(
                              _attemptsRemaining))
                      : null,
                  errorMaxLines: 3),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _currentIsWrong = false;
                  _currentPin = value;
                });
              },
            ),
            Text(l10n.p_enter_new_piv_pin_puk(
                widget.target == ManageTarget.puk ? l10n.s_puk : l10n.s_pin)),
            TextField(
              key: keys.newPinPukField,
              obscureText: true,
              maxLength: 8,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: widget.target == ManageTarget.puk
                    ? l10n.s_new_puk
                    : l10n.s_new_pin,
                prefixIcon: const Icon(Icons.password_outlined),
                // Old YubiKeys allowed a 4 digit PIN
                enabled: _currentPin.length >= 4,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _newPin = value;
                });
              },
              onSubmitted: (_) {
                if (isValid) {
                  _submit();
                }
              },
            ),
            TextField(
              key: keys.confirmPinPukField,
              obscureText: true,
              maxLength: 8,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: widget.target == ManageTarget.puk
                    ? l10n.s_confirm_puk
                    : l10n.s_confirm_pin,
                prefixIcon: const Icon(Icons.password_outlined),
                enabled: _currentPin.length >= 4 && _newPin.length >= 6,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  _confirmPin = value;
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
