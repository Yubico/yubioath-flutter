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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../desktop/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart';
import '../models.dart';
import '../state.dart';

final _log = Logger('fido.views.pin_dialog');

class FidoPinDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final FidoState state;
  const FidoPinDialog(this.devicePath, this.state, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FidoPinDialogState();
}

class _FidoPinDialogState extends ConsumerState<FidoPinDialog> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _currentPinError;
  String? _newPinError;
  bool _currentIsWrong = false;
  bool _newIsWrong = false;
  bool _isObscureCurrent = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPin = widget.state.hasPin;
    final isValid = _newPin.isNotEmpty &&
        _newPin == _confirmPin &&
        (!hasPin || _currentPin.isNotEmpty);
    final minPinLength = widget.state.minPinLength;

    return ResponsiveDialog(
      title: Text(hasPin ? l10n.s_change_pin : l10n.s_set_pin),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          child: Text(l10n.s_save),
          key: saveButton,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPin) ...[
              Text(l10n.p_enter_current_pin_or_reset_no_puk),
              AppTextFormField(
                key: currentPin,
                initialValue: _currentPin,
                autofocus: true,
                obscureText: _isObscureCurrent,
                autofillHints: const [AutofillHints.password],
                decoration: AppInputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_current_pin,
                  errorText: _currentIsWrong ? _currentPinError : null,
                  errorMaxLines: 3,
                  prefixIcon: const Icon(Icons.pin_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscureCurrent
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscureCurrent = !_isObscureCurrent;
                      });
                    },
                    tooltip:
                        _isObscureCurrent ? l10n.s_show_pin : l10n.s_hide_pin,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _currentIsWrong = false;
                    _currentPin = value;
                  });
                },
              ),
            ],
            Text(l10n.p_enter_new_fido2_pin(minPinLength)),
            // TODO: Set max characters based on UTF-8 bytes
            AppTextFormField(
              key: newPin,
              initialValue: _newPin,
              autofocus: !hasPin,
              obscureText: _isObscureNew,
              autofillHints: const [AutofillHints.password],
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_new_pin,
                enabled: !hasPin || _currentPin.isNotEmpty,
                errorText: _newIsWrong ? _newPinError : null,
                errorMaxLines: 3,
                prefixIcon: const Icon(Icons.pin_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isObscureNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isObscureNew = !_isObscureNew;
                    });
                  },
                  tooltip: _isObscureNew ? l10n.s_show_pin : l10n.s_hide_pin,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _newIsWrong = false;
                  _newPin = value;
                });
              },
            ),
            AppTextFormField(
              key: confirmPin,
              initialValue: _confirmPin,
              obscureText: _isObscureConfirm,
              autofillHints: const [AutofillHints.password],
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_confirm_pin,
                prefixIcon: const Icon(Icons.pin_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_isObscureConfirm
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isObscureConfirm = !_isObscureConfirm;
                    });
                  },
                  tooltip:
                      _isObscureConfirm ? l10n.s_show_pin : l10n.s_hide_pin,
                ),
                enabled:
                    (!hasPin || _currentPin.isNotEmpty) && _newPin.isNotEmpty,
              ),
              onChanged: (value) {
                setState(() {
                  _confirmPin = value;
                });
              },
              onFieldSubmitted: (_) {
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

  void _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final minPinLength = widget.state.minPinLength;
    final oldPin = _currentPin.isNotEmpty ? _currentPin : null;
    if (_newPin.length < minPinLength) {
      setState(() {
        _newPinError = l10n.l_new_pin_len(minPinLength);
        _newIsWrong = true;
      });
      return;
    }
    try {
      final result = await ref
          .read(fidoStateProvider(widget.devicePath).notifier)
          .setPin(_newPin, oldPin: oldPin);
      result.when(success: () {
        Navigator.of(context).pop(true);
        showMessage(context, l10n.s_pin_set);
      }, failed: (retries, authBlocked) {
        setState(() {
          if (authBlocked) {
            _currentPinError = l10n.l_pin_soft_locked;
            _currentIsWrong = true;
          } else {
            _currentPinError = l10n.l_wrong_pin_attempts_remaining(retries);
            _currentIsWrong = true;
          }
        });
      });
    } catch (e) {
      _log.error('Failed to set PIN', e);
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      await ref.read(withContextProvider)(
        (context) async {
          showMessage(
            context,
            l10n.l_set_pin_failed(errorMessage),
            duration: const Duration(seconds: 4),
          );
        },
      );
    }
  }
}
