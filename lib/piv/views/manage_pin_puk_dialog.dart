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
import '../../widgets/visibility_toggle_button.dart';
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
  String? _currentPinError;
  bool _confirmIsWrong = false;
  String? _confirmPinError;

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

  Future<void> _submit() async {
    _currentPinFocus.unfocus();
    _newPinFocus.unfocus();
    _confirmPinFocus.unfocus();

    final l10n = AppLocalizations.of(context);
    final currentPin = _currentPinController.text;
    final newPin = _newPinController.text;

    final deviceData = ref.read(currentDeviceDataProvider).value;
    final isFipsCapable =
        deviceData?.info.getFipsStatus(Capability.piv).$1 ?? false;
    final currentMinPinLen = isFipsCapable
        ? 8
        : widget.pivState.version.isAtLeast(4, 3, 1)
        ? 6
        : 4;
    final newMinPinLen = currentMinPinLen > 4 ? currentMinPinLen : 6;

    bool hasError = false;
    String? currentErr;
    String? newPinErr;
    bool newIsWrong = false;
    String? confirmErr;
    bool confirmIsWrong = false;

    if (currentPin.isEmpty) {
      currentErr = l10n.l_field_required;
      hasError = true;
    }

    if (newPin.isEmpty) {
      newPinErr = l10n.l_field_required;
      newIsWrong = true;
      hasError = true;
    } else if (byteLength(newPin) < newMinPinLen) {
      newPinErr = l10n.s_invalid_length;
      newIsWrong = true;
      hasError = true;
    }

    if (_confirmPin.isEmpty) {
      confirmErr = l10n.l_field_required;
      confirmIsWrong = true;
      hasError = true;
    } else if (newPin != _confirmPin) {
      confirmErr =
          widget.target == ManageTarget.pin ||
              widget.target == ManageTarget.unblock
          ? l10n.l_pin_mismatch
          : l10n.l_puk_mismatch;
      confirmIsWrong = true;
      hasError = true;
    }

    if (hasError) {
      setState(() {
        if (currentErr != null) {
          _currentIsWrong = true;
          _currentPinError = currentErr;
        }
        _newIsWrong = newIsWrong;
        _newPinError = newPinErr;
        _confirmIsWrong = confirmIsWrong;
        _confirmPinError = confirmErr;
      });
      return;
    }

    final notifier = ref.read(pivStateProvider(widget.path).notifier);

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
                  _currentPinError = widget.target == ManageTarget.pin
                      ? l10n.l_wrong_pin_attempts_remaining(attemptsRemaining)
                      : l10n.l_wrong_puk_attempts_remaining(attemptsRemaining);
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

    final titleText = switch (widget.target) {
      ManageTarget.pin => l10n.s_change_pin,
      ManageTarget.puk => l10n.s_change_puk,
      ManageTarget.unblock => l10n.s_unblock_pin,
    };

    final showDefaultPinUsed =
        widget.target == ManageTarget.pin && _defaultPinUsed;
    final showDefaultPukUsed =
        widget.target != ManageTarget.pin && _defaultPukUsed;

    final deviceData = ref.read(currentDeviceDataProvider).value;
    final hasPinComplexity = deviceData?.info.pinComplexity ?? false;
    final isBio = [
      FormFactor.usbABio,
      FormFactor.usbCBio,
    ].contains(deviceData?.info.formFactor);

    final isFipsCapable =
        deviceData?.info.getFipsStatus(Capability.piv).$1 ?? false;

    // Old YubiKeys allowed a 4 digit PIN
    final currentMinPinLen = isFipsCapable
        ? 8
        : widget.pivState.version.isAtLeast(4, 3, 1)
        ? 6
        : 4;
    final newMinPinLen = currentMinPinLen > 4 ? currentMinPinLen : 6;

    return ResponsiveDialog(
      title: Text(titleText),
      actions: [
        TextButton(
          onPressed: _submit,
          key: keys.saveButton,
          child: Text(l10n.s_save),
        ),
      ],
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: .start,
          children:
              [
                    AppTextField(
                      autofocus: !(showDefaultPinUsed || showDefaultPukUsed),
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
                        helperText: showDefaultPinUsed
                            ? l10n.l_default_pin_used
                            : showDefaultPukUsed
                            ? l10n.l_default_puk_used
                            : null,
                        labelText: widget.target == ManageTarget.pin
                            ? l10n.s_current_pin
                            : l10n.s_current_puk,
                        isRequired: true,
                        errorText: _pinIsBlocked
                            ? (widget.target == ManageTarget.pin && !isBio
                                  ? l10n.l_piv_pin_blocked
                                  : l10n.l_piv_pin_puk_blocked)
                            : _currentIsWrong
                            ? _currentPinError
                            : null,
                        errorMaxLines: 3,
                        icon: const Icon(Symbols.pin),
                        suffixIcon: VisibilityToggleButton(
                          isObscured: _isObscureCurrent,
                          onToggle: () {
                            setState(() {
                              _isObscureCurrent = !_isObscureCurrent;
                            });
                          },
                          showLabel: widget.target == ManageTarget.pin
                              ? l10n.s_show_pin
                              : l10n.s_show_puk,
                          hideLabel: widget.target == ManageTarget.pin
                              ? l10n.s_hide_pin
                              : l10n.s_hide_puk,
                        ),
                      ),
                      textInputAction: .next,
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
                        helperText: hasPinComplexity
                            ? l10n.p_new_piv_pin_puk_complexity_active_requirements(
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
                        labelText: widget.target == ManageTarget.puk
                            ? l10n.s_new_puk
                            : l10n.s_new_pin,
                        isRequired: true,
                        errorText: _newIsWrong ? _newPinError : null,
                        icon: const Icon(Symbols.pin),
                        suffixIcon: VisibilityToggleButton(
                          isObscured: _isObscureNew,
                          onToggle: () {
                            setState(() {
                              _isObscureNew = !_isObscureNew;
                            });
                          },
                          showLabel: widget.target == ManageTarget.pin
                              ? l10n.s_show_pin
                              : l10n.s_show_puk,
                          hideLabel: widget.target == ManageTarget.pin
                              ? l10n.s_hide_pin
                              : l10n.s_hide_puk,
                        ),
                        enabled: true,
                      ),
                      textInputAction: .next,
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
                        labelText: widget.target == ManageTarget.puk
                            ? l10n.s_confirm_puk
                            : l10n.s_confirm_pin,
                        isRequired: true,
                        icon: const Icon(Symbols.pin),
                        suffixIcon: VisibilityToggleButton(
                          isObscured: _isObscureConfirm,
                          onToggle: () {
                            setState(() {
                              _isObscureConfirm = !_isObscureConfirm;
                            });
                          },
                          showLabel: widget.target == ManageTarget.pin
                              ? l10n.s_show_pin
                              : l10n.s_show_puk,
                          hideLabel: widget.target == ManageTarget.pin
                              ? l10n.s_hide_pin
                              : l10n.s_hide_puk,
                        ),
                        enabled: true,
                        errorText: _confirmIsWrong ? _confirmPinError : null,
                        helperText:
                            '', // Prevents resizing when errorText shown
                      ),
                      textInputAction: .done,
                      onChanged: (value) {
                        setState(() {
                          _confirmIsWrong = false;
                          _confirmPin = value;
                        });
                      },
                      onSubmitted: (_) {
                        _submit();
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
