/*
 * Copyright (C) 2022-2025 Yubico.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';

enum ManageTarget { pin, puk, unblock }

class ManagePinPukDialog extends ConsumerStatefulWidget {
  final DevicePath path;
  final PivState pivState;
  final ManageTarget target;
  const ManagePinPukDialog(
    this.path,
    this.pivState, {
    super.key,
    this.target = ManageTarget.pin,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagePinPukDialogState();
}

class _ManagePinPukDialogState extends ConsumerState<ManagePinPukDialog> {
  final _currentPinController = TextEditingController();
  final _currentPinFocus = FocusNode();
  final _newPinController = TextEditingController();
  final _newPinFocus = FocusNode();
  final _confirmPinFocus = FocusNode();
  String _confirmPin = '';
  bool _pinIsBlocked = false;
  bool _currentIsWrong = false;
  bool _newIsWrong = false;
  String? _newPinError;
  int _attemptsRemaining = -1;
  bool _isObscureCurrent = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  late final bool _defaultPinUsed;
  late final bool _defaultPukUsed;

  @override
  void initState() {
    super.initState();

    _defaultPinUsed =
        widget.pivState.metadata?.pinMetadata.defaultValue ?? false;
    _defaultPukUsed =
        widget.pivState.metadata?.pukMetadata.defaultValue ?? false;
    if (widget.target == ManageTarget.pin && _defaultPinUsed) {
      _currentPinController.text = defaultPin;
    }
    if (widget.target != ManageTarget.pin && _defaultPukUsed) {
      _currentPinController.text = defaultPuk;
    }
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _currentPinFocus.dispose();
    _newPinController.dispose();
    _newPinFocus.dispose();
    _confirmPinFocus.dispose();
    super.dispose();
  }

  _submit() async {
    final notifier = ref.read(pivStateProvider(widget.path).notifier);
    final l10n = AppLocalizations.of(context);

    final result = await switch (widget.target) {
      ManageTarget.pin => notifier.changePin(
        _currentPinController.text,
        _newPinController.text,
      ),
      ManageTarget.puk => notifier.changePuk(
        _currentPinController.text,
        _newPinController.text,
      ),
      ManageTarget.unblock => notifier.unblockPin(
        _currentPinController.text,
        _newPinController.text,
      ),
    };

    switch (result) {
      case PinSuccess():
        {
          if (!mounted) return;
          Navigator.of(context).pop();
          showMessage(context, switch (widget.target) {
            ManageTarget.puk => l10n.s_puk_set,
            _ => l10n.s_pin_set,
          });
        }
      case PinFailure(:final reason):
        {
          switch (reason) {
            case PivInvalidPin(:final attemptsRemaining):
              {
                _currentPinController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _currentPinController.text.length,
                );
                _currentPinFocus.requestFocus();
                setState(() {
                  _attemptsRemaining = attemptsRemaining;
                  _currentIsWrong = true;
                  if (_attemptsRemaining == 0) {
                    _pinIsBlocked = true;
                  }
                });
              }
            case PivWeakPin():
              {
                _newPinController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _newPinController.text.length,
                );
                _newPinFocus.requestFocus();
                setState(() {
                  _newPinError = l10n.p_pin_puk_complexity_failure(
                    widget.target == ManageTarget.puk ? l10n.s_puk : l10n.s_pin,
                  );
                  _newIsWrong = true;
                });
              }
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentPin = _currentPinController.text;
    final currentPinLen = byteLength(currentPin);
    final newPin = _newPinController.text;
    final newPinLen = byteLength(newPin);
    final isValid =
        !_currentIsWrong &&
        newPin.isNotEmpty &&
        newPin == _confirmPin &&
        currentPin.isNotEmpty;

    final titleText = switch (widget.target) {
      ManageTarget.pin => l10n.s_change_pin,
      ManageTarget.puk => l10n.s_change_puk,
      ManageTarget.unblock => l10n.s_unblock_pin,
    };

    final showDefaultPinUsed =
        widget.target == ManageTarget.pin && _defaultPinUsed;
    final showDefaultPukUsed =
        widget.target != ManageTarget.pin && _defaultPukUsed;

    final deviceData = ref.read(currentDeviceDataProvider).valueOrNull;
    final hasPinComplexity = deviceData?.info.pinComplexity ?? false;
    final isBio = [
      FormFactor.usbABio,
      FormFactor.usbCBio,
    ].contains(deviceData?.info.formFactor);

    final isFipsCapable =
        deviceData?.info.getFipsStatus(Capability.piv).$1 ?? false;

    // Old YubiKeys allowed a 4 digit PIN
    final currentMinPinLen =
        isFipsCapable
            ? 8
            : widget.pivState.version.isAtLeast(4, 3, 1)
            ? 6
            : 4;
    final newMinPinLen = currentMinPinLen > 4 ? currentMinPinLen : 6;

    return ResponsiveDialog(
      title: Text(titleText),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          key: keys.saveButton,
          child: Text(l10n.s_save),
        ),
      ],
      builder:
          (context, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  [
                        AppTextField(
                          autofocus:
                              !(showDefaultPinUsed || showDefaultPukUsed),
                          obscureText: _isObscureCurrent,
                          maxLength: 8,
                          inputFormatters: [limitBytesLength(8)],
                          buildCounter: buildByteCounterFor(currentPin),
                          autofillHints: const [AutofillHints.password],
                          key: keys.pinPukField,
                          readOnly: showDefaultPinUsed || showDefaultPukUsed,
                          controller: _currentPinController,
                          focusNode: _currentPinFocus,
                          enabled: !_pinIsBlocked,
                          decoration: AppInputDecoration(
                            border: const OutlineInputBorder(),
                            helperText:
                                showDefaultPinUsed
                                    ? l10n.l_default_pin_used
                                    : showDefaultPukUsed
                                    ? l10n.l_default_puk_used
                                    : null,
                            labelText:
                                widget.target == ManageTarget.pin
                                    ? l10n.s_current_pin
                                    : l10n.s_current_puk,
                            errorText:
                                _pinIsBlocked
                                    ? (widget.target == ManageTarget.pin &&
                                            !isBio
                                        ? l10n.l_piv_pin_blocked
                                        : l10n.l_piv_pin_puk_blocked)
                                    : (_currentIsWrong
                                        ? (widget.target == ManageTarget.pin
                                            ? l10n
                                                .l_wrong_pin_attempts_remaining(
                                                  _attemptsRemaining,
                                                )
                                            : l10n
                                                .l_wrong_puk_attempts_remaining(
                                                  _attemptsRemaining,
                                                ))
                                        : null),
                            errorMaxLines: 3,
                            icon: const Icon(Symbols.pin),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscureCurrent
                                    ? Symbols.visibility
                                    : Symbols.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscureCurrent = !_isObscureCurrent;
                                });
                              },
                              tooltip:
                                  widget.target == ManageTarget.pin
                                      ? (_isObscureCurrent
                                          ? l10n.s_show_pin
                                          : l10n.s_hide_pin)
                                      : (_isObscureCurrent
                                          ? l10n.s_show_puk
                                          : l10n.s_hide_puk),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: (value) {
                            setState(() {
                              _currentIsWrong = false;
                            });
                          },
                          onSubmitted: (_) {
                            if (currentPinLen >= currentMinPinLen ||
                                (isFipsCapable && showDefaultPinUsed)) {
                              _newPinFocus.requestFocus();
                            } else {
                              _currentPinFocus.requestFocus();
                            }
                          },
                        ).init(),
                        // Used to add more spacing
                        const SizedBox(height: 0),
                        AppTextField(
                          key: keys.newPinPukField,
                          autofocus: showDefaultPinUsed || showDefaultPukUsed,
                          obscureText: _isObscureNew,
                          controller: _newPinController,
                          focusNode: _newPinFocus,
                          maxLength: 8,
                          inputFormatters: [limitBytesLength(8)],
                          buildCounter: buildByteCounterFor(newPin),
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: AppInputDecoration(
                            border: const OutlineInputBorder(),
                            helperText:
                                hasPinComplexity
                                    ? l10n
                                        .p_new_piv_pin_puk_complexity_active_requirements(
                                          widget.target == ManageTarget.puk
                                              ? l10n.s_puk
                                              : l10n.s_pin,
                                          newMinPinLen,
                                          '123456',
                                        )
                                    : l10n.p_new_piv_pin_puk_requirements(
                                      widget.target == ManageTarget.puk
                                          ? l10n.s_puk
                                          : l10n.s_pin,
                                      newMinPinLen,
                                    ),
                            helperMaxLines: 5,
                            labelText:
                                widget.target == ManageTarget.puk
                                    ? l10n.s_new_puk
                                    : l10n.s_new_pin,
                            errorText: _newIsWrong ? _newPinError : null,
                            icon: const Icon(Symbols.pin),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscureNew
                                    ? Symbols.visibility
                                    : Symbols.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscureNew = !_isObscureNew;
                                });
                              },
                              tooltip:
                                  widget.target == ManageTarget.pin
                                      ? (_isObscureNew
                                          ? l10n.s_show_pin
                                          : l10n.s_hide_pin)
                                      : (_isObscureNew
                                          ? l10n.s_show_puk
                                          : l10n.s_hide_puk),
                            ),
                            enabled:
                                currentPinLen >= currentMinPinLen ||
                                (isFipsCapable && showDefaultPinUsed),
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: (value) {
                            setState(() {
                              _newIsWrong = false;
                            });
                          },
                          onSubmitted: (_) {
                            if (newPinLen >= newMinPinLen) {
                              _confirmPinFocus.requestFocus();
                            } else {
                              _newPinFocus.requestFocus();
                            }
                          },
                        ).init(),
                        AppTextField(
                          key: keys.confirmPinPukField,
                          obscureText: _isObscureConfirm,
                          maxLength: 8,
                          inputFormatters: [limitBytesLength(8)],
                          buildCounter: buildByteCounterFor(_confirmPin),
                          focusNode: _confirmPinFocus,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: AppInputDecoration(
                            border: const OutlineInputBorder(),
                            labelText:
                                widget.target == ManageTarget.puk
                                    ? l10n.s_confirm_puk
                                    : l10n.s_confirm_pin,
                            icon: const Icon(Symbols.pin),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscureConfirm
                                    ? Symbols.visibility
                                    : Symbols.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscureConfirm = !_isObscureConfirm;
                                });
                              },
                              tooltip:
                                  widget.target == ManageTarget.pin
                                      ? (_isObscureConfirm
                                          ? l10n.s_show_pin
                                          : l10n.s_hide_pin)
                                      : (_isObscureConfirm
                                          ? l10n.s_show_puk
                                          : l10n.s_hide_puk),
                            ),
                            enabled: newPinLen >= newMinPinLen,
                            errorText:
                                newPinLen == _confirmPin.length &&
                                        newPin != _confirmPin
                                    ? (widget.target == ManageTarget.pin ||
                                            widget.target ==
                                                ManageTarget.unblock
                                        ? l10n.l_pin_mismatch
                                        : l10n.l_puk_mismatch)
                                    : null,
                            helperText:
                                '', // Prevents resizing when errorText shown
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
                            } else {
                              _confirmPinFocus.requestFocus();
                            }
                          },
                        ).init(),
                      ]
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: e,
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }
}
