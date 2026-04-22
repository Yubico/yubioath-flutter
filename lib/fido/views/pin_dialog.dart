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
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../desktop/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../../widgets/visibility_toggle_button.dart';
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
  final _confirmPinController = TextEditingController();
  final _confirmPinFocus = FocusNode();
  String? _currentPinError;
  String? _newPinError;
  String? _confirmPinError;
  bool _currentIsWrong = false;
  bool _newIsWrong = false;
  bool _confirmIsWrong = false;
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
    _confirmPinController.dispose();
    _confirmPinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPin = widget.state.hasPin;
    final minPinLength = widget.state.minPinLength;
    final deviceData = ref.read(currentDeviceDataProvider).value;

    final hasPinComplexity = deviceData?.info.pinComplexity ?? false;
    final pinRetries = ref.watch(
      fidoStateProvider(
        widget.devicePath,
      ).select((s) => s.whenOrNull(data: (state) => state.pinRetries)),
    );

    final isBio = widget.state.bioEnroll != null;
    final enabled =
        deviceData?.info.config.enabledCapabilities[deviceData
            .node
            .transport] ??
        0;
    final maxPinLength = isBio && (enabled & Capability.piv.value) != 0
        ? 8
        : 63;

    return ResponsiveDialog(
      title: Text(hasPin ? l10n.s_change_pin : l10n.s_set_pin),
      actions: [
        TextButton(
          onPressed: _submit,
          key: saveButton,
          child: Text(l10n.s_save),
        ),
      ],
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: .start,
          children:
              [
                    if (hasPin) ...[
                      AppTextField(
                        key: currentPin,
                        controller: _currentPinController,
                        focusNode: _currentPinFocus,
                        maxLength: maxPinLength,
                        inputFormatters: [limitBytesLength(maxPinLength)],
                        buildCounter: buildByteCounterFor(
                          _currentPinController.text,
                        ),
                        autofocus: true,
                        obscureText: _isObscureCurrent,
                        autofillHints: const [AutofillHints.password],
                        decoration: AppInputDecoration(
                          enabled: !_isBlocked,
                          border: const OutlineInputBorder(),
                          labelText: l10n.s_current_pin,
                          isRequired: true,
                          helperText: pinRetries != null && pinRetries <= 3
                              ? l10n.l_attempts_remaining(pinRetries)
                              : '',
                          // Prevents dialog resizing
                          errorText: _currentIsWrong ? _currentPinError : null,
                          errorMaxLines: 3,
                          icon: const Icon(Symbols.pin),
                          suffixIcon: VisibilityToggleButton(
                            isObscured: _isObscureCurrent,
                            onToggle: () {
                              setState(() {
                                _isObscureCurrent = !_isObscureCurrent;
                              });
                            },
                            showLabel: l10n.s_show_pin,
                            hideLabel: l10n.s_hide_pin,
                          ),
                        ),
                        textInputAction: .next,
                        onChanged: (value) {
                          setState(() {
                            _currentIsWrong = false;
                          });
                        },
                        onSubmitted: (_) {
                          if (_currentPinController.text.length <
                              minPinLength) {
                            _currentPinFocus.requestFocus();
                          } else {
                            _newPinFocus.requestFocus();
                          }
                        },
                      ).init(),
                      // Used to add more spacing
                      const SizedBox(height: 0),
                    ],
                    AppTextField(
                      key: newPin,
                      controller: _newPinController,
                      focusNode: _newPinFocus,
                      maxLength: maxPinLength,
                      inputFormatters: [limitBytesLength(maxPinLength)],
                      buildCounter: buildByteCounterFor(_newPinController.text),
                      autofocus: !hasPin,
                      obscureText: _isObscureNew,
                      autofillHints: const [AutofillHints.password],
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_new_pin,
                        isRequired: true,
                        enabled: !_isBlocked,
                        helperText: hasPinComplexity
                            ? l10n.p_new_fido2_pin_complexity_active_requirements(
                                minPinLength,
                                maxPinLength,
                                2,
                                '123456',
                              )
                            : l10n.p_new_fido2_pin_requirements(
                                minPinLength,
                                maxPinLength,
                              ),
                        helperMaxLines: 7,
                        errorText: _newIsWrong ? _newPinError : null,
                        errorMaxLines: 3,
                        icon: const Icon(Symbols.pin),
                        suffixIcon: VisibilityToggleButton(
                          isObscured: _isObscureNew,
                          onToggle: () {
                            setState(() {
                              _isObscureNew = !_isObscureNew;
                            });
                          },
                          showLabel: l10n.s_show_pin,
                          hideLabel: l10n.s_hide_pin,
                        ),
                      ),
                      textInputAction: .next,
                      onChanged: (value) {
                        setState(() {
                          _newIsWrong = false;
                        });
                      },
                      onSubmitted: (_) {
                        if (_newPinController.text.length < minPinLength) {
                          _newPinFocus.requestFocus();
                        } else {
                          _confirmPinFocus.requestFocus();
                        }
                      },
                    ).init(),
                    AppTextField(
                      key: confirmPin,
                      controller: _confirmPinController,
                      focusNode: _confirmPinFocus,
                      maxLength: maxPinLength,
                      inputFormatters: [limitBytesLength(maxPinLength)],
                      buildCounter: buildByteCounterFor(
                        _confirmPinController.text,
                      ),
                      obscureText: _isObscureConfirm,
                      autofillHints: const [AutofillHints.password],
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_confirm_pin,
                        isRequired: true,
                        icon: const Icon(Symbols.pin),
                        suffixIcon: VisibilityToggleButton(
                          isObscured: _isObscureConfirm,
                          onToggle: () {
                            setState(() {
                              _isObscureConfirm = !_isObscureConfirm;
                            });
                          },
                          showLabel: l10n.s_show_pin,
                          hideLabel: l10n.s_hide_pin,
                        ),
                        enabled: !_isBlocked,
                        errorText: _confirmIsWrong ? _confirmPinError : null,
                        helperText:
                            '', // Prevents resizing when errorText shown
                      ),
                      textInputAction: .done,
                      onChanged: (value) {
                        setState(() {
                          _confirmIsWrong = false;
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

  void _submit() async {
    _currentPinFocus.unfocus();
    _newPinFocus.unfocus();
    _confirmPinFocus.unfocus();

    final l10n = AppLocalizations.of(context);
    final hasPin = widget.state.hasPin;
    final minPinLength = widget.state.minPinLength;

    bool valid = true;

    if (hasPin && _currentPinController.text.isEmpty) {
      _currentPinError = l10n.l_field_required;
      _currentIsWrong = true;
      valid = false;
    }

    if (_newPinController.text.isEmpty) {
      _newPinError = l10n.l_field_required;
      _newIsWrong = true;
      valid = false;
    } else if (_newPinController.text.length < minPinLength) {
      _newPinError = l10n.s_invalid_length;
      _newIsWrong = true;
      valid = false;
    }

    if (_confirmPinController.text.isEmpty) {
      _confirmPinError = l10n.l_field_required;
      _confirmIsWrong = true;
      valid = false;
    } else if (_newPinController.text != _confirmPinController.text &&
        _confirmPinController.text.isNotEmpty) {
      _confirmPinError = l10n.l_pin_mismatch;
      _confirmIsWrong = true;
      valid = false;
    }

    if (!valid || _currentIsWrong) {
      setState(() {});
      return;
    }
    final oldPin = _currentPinController.text.isNotEmpty
        ? _currentPinController.text
        : null;
    final newPin = _newPinController.text;
    try {
      final result = await ref
          .read(fidoStateProvider(widget.devicePath).notifier)
          .setPin(newPin, oldPin: oldPin);
      switch (result) {
        case PinResultSuccess():
          {
            await ref.read(withContextProvider)((context) async {
              Navigator.of(context).pop(true);
              showMessage(context, l10n.s_pin_set);
            });
          }
        case PinResultFailure(:final reason):
          {
            switch (reason) {
              case FidoInvalidPin(:final retries, :final authBlocked):
                {
                  _currentPinController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _currentPinController.text.length,
                  );
                  _currentPinFocus.requestFocus();
                  setState(() {
                    if (authBlocked || retries == 0) {
                      _currentPinError = retries == 0
                          ? l10n.l_pin_blocked_reset
                          : l10n.l_pin_soft_locked;
                      _currentIsWrong = true;
                      _isBlocked = true;
                    } else {
                      _currentPinError = l10n.l_wrong_pin_attempts_remaining(
                        retries,
                      );
                      _currentIsWrong = true;
                    }
                  });
                }
              case FidoWeakPin():
                {
                  _newPinController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _newPinController.text.length,
                  );
                  _newPinFocus.requestFocus();
                  setState(() {
                    _newPinError = l10n.p_pin_puk_complexity_failure(
                      l10n.s_pin,
                    );
                    _newIsWrong = true;
                  });
                }
            }
          }
      }
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
      await ref.read(withContextProvider)((context) async {
        showMessage(
          context,
          l10n.l_set_pin_failed(errorMessage),
          duration: const Duration(seconds: 4),
        );
      });
    }
  }
}
