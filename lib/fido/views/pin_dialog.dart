/*
 * Copyright (C) 2022-2024 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../desktop/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../management/models.dart';
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
  final _currentPinController = TextEditingController();
  final _currentPinFocus = FocusNode();
  final _newPinController = TextEditingController();
  final _newPinFocus = FocusNode();
  String _confirmPin = '';
  String? _currentPinError;
  String? _newPinError;
  bool _currentIsWrong = false;
  bool _newIsWrong = false;
  bool _isObscureCurrent = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _isBlocked = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _currentPinFocus.dispose();
    _newPinController.dispose();
    _newPinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPin = widget.state.hasPin;
    final minPinLength = widget.state.minPinLength;
    final currentMinPinLen = !hasPin
        ? 0
        // N.B. current PIN may be shorter than minimum if set before the minimum was increased
        : (widget.state.forcePinChange ? 4 : widget.state.minPinLength);
    final currentPinLenOk =
        _currentPinController.text.length >= currentMinPinLen;
    final newPinLenOk = _newPinController.text.length >= minPinLength;
    final isValid =
        currentPinLenOk && newPinLenOk && _newPinController.text == _confirmPin;

    final deviceData = ref.read(currentDeviceDataProvider).valueOrNull;

    final hasPinComplexity = deviceData?.info.pinComplexity ?? false;
    final pinRetries = ref.watch(fidoStateProvider(widget.devicePath)
        .select((s) => s.whenOrNull(data: (state) => state.pinRetries)));

    final isBio = widget.state.bioEnroll != null;
    final enabled = deviceData
            ?.info.config.enabledCapabilities[deviceData.node.transport] ??
        0;
    final maxPinLength =
        isBio && (enabled & Capability.piv.value) != 0 ? 8 : null;

    return ResponsiveDialog(
      title: Text(hasPin ? l10n.s_change_pin : l10n.s_set_pin),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          key: saveButton,
          child: Text(l10n.s_save),
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
                controller: _currentPinController,
                focusNode: _currentPinFocus,
                maxLength: maxPinLength,
                autofocus: true,
                obscureText: _isObscureCurrent,
                autofillHints: const [AutofillHints.password],
                decoration: AppInputDecoration(
                  enabled: !_isBlocked,
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_current_pin,
                  helperText: pinRetries != null && pinRetries <= 3
                      ? l10n.l_attempts_remaining(pinRetries)
                      : '', // Prevents dialog resizing
                  errorText: _currentIsWrong ? _currentPinError : null,
                  errorMaxLines: 3,
                  prefixIcon: const Icon(Symbols.pin),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscureCurrent
                        ? Symbols.visibility
                        : Symbols.visibility_off),
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
                  });
                },
              ).init(),
            ],
            Text(hasPinComplexity
                ? l10n.p_enter_new_fido2_pin_complexity_active(
                    minPinLength, 2, '123456')
                : maxPinLength != null
                    ? l10n.p_enter_new_fido2_pin_max_length(
                        minPinLength, maxPinLength)
                    : l10n.p_enter_new_fido2_pin(minPinLength)),
            // TODO: Set max characters based on UTF-8 bytes
            AppTextFormField(
              key: newPin,
              controller: _newPinController,
              focusNode: _newPinFocus,
              maxLength: maxPinLength,
              autofocus: !hasPin,
              obscureText: _isObscureNew,
              autofillHints: const [AutofillHints.password],
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_new_pin,
                enabled: !_isBlocked && currentPinLenOk,
                errorText: _newIsWrong ? _newPinError : null,
                errorMaxLines: 3,
                prefixIcon: const Icon(Symbols.pin),
                suffixIcon: IconButton(
                  icon: Icon(_isObscureNew
                      ? Symbols.visibility
                      : Symbols.visibility_off),
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
                });
              },
            ).init(),
            AppTextFormField(
              key: confirmPin,
              initialValue: _confirmPin,
              maxLength: maxPinLength,
              obscureText: _isObscureConfirm,
              autofillHints: const [AutofillHints.password],
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_confirm_pin,
                prefixIcon: const Icon(Symbols.pin),
                suffixIcon: IconButton(
                  icon: Icon(_isObscureConfirm
                      ? Symbols.visibility
                      : Symbols.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isObscureConfirm = !_isObscureConfirm;
                    });
                  },
                  tooltip:
                      _isObscureConfirm ? l10n.s_show_pin : l10n.s_hide_pin,
                ),
                enabled: !_isBlocked && currentPinLenOk && newPinLenOk,
                errorText:
                    _newPinController.text.length == _confirmPin.length &&
                            _newPinController.text != _confirmPin
                        ? l10n.l_pin_mismatch
                        : null,
                helperText: '', // Prevents resizing when errorText shown
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
            ).init(),
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
    final oldPin = _currentPinController.text.isNotEmpty
        ? _currentPinController.text
        : null;
    final newPin = _newPinController.text;
    try {
      final result = await ref
          .read(fidoStateProvider(widget.devicePath).notifier)
          .setPin(newPin, oldPin: oldPin);
      result.whenOrNull(
        success: () {
          Navigator.of(context).pop(true);
          showMessage(context, l10n.s_pin_set);
        },
        failed: (reason) {
          reason.when(
            invalidPin: (retries, authBlocked) {
              _currentPinController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _currentPinController.text.length);
              _currentPinFocus.requestFocus();
              setState(() {
                if (authBlocked || retries == 0) {
                  _currentPinError = retries == 0
                      ? l10n.l_pin_blocked_reset
                      : l10n.l_pin_soft_locked;
                  _currentIsWrong = true;
                  _isBlocked = true;
                } else {
                  _currentPinError =
                      l10n.l_wrong_pin_attempts_remaining(retries);
                  _currentIsWrong = true;
                }
              });
            },
            weakPin: () {
              _newPinController.selection = TextSelection(
                  baseOffset: 0, extentOffset: _newPinController.text.length);
              _newPinFocus.requestFocus();
              setState(() {
                _newPinError = l10n.p_pin_puk_complexity_failure(l10n.s_pin);
                _newIsWrong = true;
              });
            },
          );
        },
      );
    } on CancellationException catch (_) {
      // ignored
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
