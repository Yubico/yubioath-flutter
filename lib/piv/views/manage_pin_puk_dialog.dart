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
import 'package:yubico_authenticator/piv/models.dart';

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

//TODO: Use switch expressions in Dart 3
class _ManagePinPukDialogState extends ConsumerState<ManagePinPukDialog> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _currentIsWrong = false;
  int _attemptsRemaining = -1;

  _submit() async {
    final notifier = ref.read(pivStateProvider(widget.path).notifier);
    final PinVerificationStatus result;
    switch (widget.target) {
      case ManageTarget.pin:
        result = await notifier.changePin(_currentPin, _newPin);
        break;
      case ManageTarget.puk:
        result = await notifier.changePuk(_currentPin, _newPin);
        break;
      case ManageTarget.unblock:
        result = await notifier.unblockPin(_currentPin, _newPin);
        break;
    }

    result.when(success: () {
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, AppLocalizations.of(context)!.s_password_set);
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

    final String titleText;
    switch (widget.target) {
      case ManageTarget.pin:
        titleText = "Change PIN";
        break;
      case ManageTarget.puk:
        titleText = l10n.s_manage_password;
        break;
      case ManageTarget.unblock:
        titleText = "Unblock PIN";
        break;
    }

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
            Text(l10n.p_enter_current_password_or_reset),
            TextField(
              autofocus: true,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              key: keys.pinPukField,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: widget.target == ManageTarget.pin
                      ? 'Current PIN'
                      : 'Current PUK',
                  prefixIcon: const Icon(Icons.password_outlined),
                  errorText: _currentIsWrong
                      ? l10n.l_wrong_pin_attempts_remaining(_attemptsRemaining)
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
            Text(
                "Enter your new ${widget.target == ManageTarget.puk ? 'PUK' : 'PIN'}. Must be 6-8 characters."),
            TextField(
              key: keys.newPinPukField,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: widget.target == ManageTarget.puk
                    ? "New PUK"
                    : l10n.s_new_pin,
                prefixIcon: const Icon(Icons.password_outlined),
                enabled: _currentPin.isNotEmpty,
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
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_confirm_pin,
                prefixIcon: const Icon(Icons.password_outlined),
                enabled: _currentPin.isNotEmpty && _newPin.isNotEmpty,
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
