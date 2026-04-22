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
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/visibility_toggle_button.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';

class ManagePasswordDialog extends ConsumerStatefulWidget {
  final DevicePath path;
  final OathState state;

  const ManagePasswordDialog(this.path, this.state, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagePasswordDialogState();
}

class _ManagePasswordDialogState extends ConsumerState<ManagePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _currentPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  String _newPassword = '';
  String _confirmPassword = '';
  bool _currentIsWrong = false;
  String? _currentPasswordError;
  bool _isObscureCurrent = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _removeFocus() {
    _currentPasswordFocus.unfocus();
    _newPasswordFocus.unfocus();
    _confirmPasswordFocus.unfocus();
  }

  Future<void> _submit() async {
    _removeFocus();

    final l10n = AppLocalizations.of(context);
    bool hasError = false;
    String? currentErr;
    String? newErr;
    String? confirmErr;

    if (widget.state.hasKey && _currentPasswordController.text.isEmpty) {
      currentErr = l10n.l_field_required;
      hasError = true;
    }

    if (_newPassword.isEmpty) {
      newErr = l10n.l_field_required;
      hasError = true;
    }

    if (_confirmPassword.isEmpty) {
      confirmErr = l10n.l_field_required;
      hasError = true;
    } else if (_newPassword != _confirmPassword) {
      confirmErr = l10n.l_password_mismatch;
      hasError = true;
    }

    if (hasError) {
      setState(() {
        if (currentErr != null) {
          _currentIsWrong = true;
          _currentPasswordError = currentErr;
        }
        _newPasswordError = newErr;
        _confirmPasswordError = confirmErr;
      });
      return;
    }

    try {
      final result = await ref
          .read(oathStateProvider(widget.path).notifier)
          .setPassword(_currentPasswordController.text, _newPassword);
      if (result) {
        if (mounted) {
          await ref.read(withContextProvider)((context) async {
            Navigator.of(context).pop();
            showMessage(context, AppLocalizations.of(context).s_password_set);
          });
        }
      } else {
        _currentPasswordController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _currentPasswordController.text.length,
        );
        _currentPasswordFocus.requestFocus();
        setState(() {
          _currentIsWrong = true;
          _currentPasswordError = AppLocalizations.of(context).p_wrong_password;
        });
      }
    } on CancellationException catch (_) {
      // ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    final fipsCapable = ref
        .watch(currentDeviceDataProvider)
        .maybeWhen(
          data: (data) => data.info.getFipsStatus(Capability.oath).$1,
          orElse: () => false,
        );
    final l10n = AppLocalizations.of(context);

    return ResponsiveDialog(
      title: Text(
        widget.state.hasKey ? l10n.s_manage_password : l10n.s_set_password,
      ),
      actions: [
        TextButton(
          onPressed: _submit,
          key: keys.savePasswordButton,
          child: Text(l10n.s_save),
        ),
      ],
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: .start,
          children:
              [
                    if (widget.state.hasKey) ...[
                      AppTextField(
                        autofocus: true,
                        obscureText: _isObscureCurrent,
                        autofillHints: const [AutofillHints.password],
                        key: keys.currentPasswordField,
                        controller: _currentPasswordController,
                        focusNode: _currentPasswordFocus,
                        decoration: AppInputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: l10n.s_current_password,
                          isRequired: true,
                          errorText: _currentIsWrong
                              ? _currentPasswordError
                              : null,
                          errorMaxLines: 3,
                          icon: const Icon(Symbols.password),
                          suffixIcon: VisibilityToggleButton(
                            isObscured: _isObscureCurrent,
                            onToggle: () {
                              setState(() {
                                _isObscureCurrent = !_isObscureCurrent;
                              });
                            },
                          ),
                        ),
                        textInputAction: .next,
                        onChanged: (value) {
                          setState(() {
                            _currentIsWrong = false;
                          });
                        },
                        onSubmitted: (_) {
                          if (_currentPasswordController.text.isNotEmpty) {
                            _newPasswordFocus.requestFocus();
                          } else {
                            _currentPasswordFocus.requestFocus();
                          }
                        },
                      ).init(),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Wrap(
                          spacing: 4.0,
                          runSpacing: 8.0,
                          children: [
                            if (!fipsCapable)
                              OutlinedButton(
                                key: keys.removePasswordButton,
                                onPressed: () async {
                                  if (_currentPasswordController.text.isEmpty) {
                                    setState(() {
                                      _currentIsWrong = true;
                                      _currentPasswordError =
                                          l10n.l_field_required;
                                    });
                                    return;
                                  }
                                  _removeFocus();

                                  final result = await ref
                                      .read(
                                        oathStateProvider(widget.path).notifier,
                                      )
                                      .unsetPassword(
                                        _currentPasswordController.text,
                                      );
                                  if (result) {
                                    if (mounted) {
                                      await ref.read(withContextProvider)((
                                        context,
                                      ) async {
                                        Navigator.of(context).pop();
                                        showMessage(
                                          context,
                                          l10n.s_password_removed,
                                        );
                                      });
                                    }
                                  } else {
                                    _currentPasswordController
                                        .selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _currentPasswordController
                                          .text
                                          .length,
                                    );
                                    _currentPasswordFocus.requestFocus();
                                    setState(() {
                                      _currentIsWrong = true;
                                      _currentPasswordError =
                                          l10n.p_wrong_password;
                                    });
                                  }
                                },
                                child: Text(l10n.s_remove_password),
                              ),
                            if (widget.state.remembered)
                              OutlinedButton(
                                child: Text(l10n.s_clear_saved_password),
                                onPressed: () async {
                                  await ref
                                      .read(
                                        oathStateProvider(widget.path).notifier,
                                      )
                                      .forgetPassword();
                                  if (mounted) {
                                    await ref.read(withContextProvider)((
                                      context,
                                    ) async {
                                      Navigator.of(context).pop();
                                      showMessage(
                                        context,
                                        l10n.s_password_forgotten,
                                      );
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),
                    ],
                    AppTextField(
                      key: keys.newPasswordField,
                      autofocus: !widget.state.hasKey,
                      obscureText: _isObscureNew,
                      autofillHints: const [AutofillHints.newPassword],
                      focusNode: _newPasswordFocus,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_new_password,
                        isRequired: true,
                        helperText: l10n.p_new_password_requirements,
                        helperMaxLines: 3,
                        errorText: _newPasswordError,
                        icon: const Icon(Symbols.password),
                        suffixIcon: VisibilityToggleButton(
                          isObscured: _isObscureNew,
                          onToggle: () {
                            setState(() {
                              _isObscureNew = !_isObscureNew;
                            });
                          },
                        ),
                      ),
                      textInputAction: .next,
                      onChanged: (value) {
                        setState(() {
                          _newPasswordError = null;
                          _newPassword = value;
                        });
                      },
                      onSubmitted: (_) {
                        if (_newPassword.isNotEmpty) {
                          _confirmPasswordFocus.requestFocus();
                        } else if (_newPassword.isEmpty) {
                          _newPasswordFocus.requestFocus();
                        }
                      },
                    ).init(),
                    AppTextField(
                      key: keys.confirmPasswordField,
                      obscureText: _isObscureConfirm,
                      focusNode: _confirmPasswordFocus,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_confirm_password,
                        isRequired: true,
                        icon: const Icon(Symbols.password),
                        suffixIcon: VisibilityToggleButton(
                          isObscured: _isObscureConfirm,
                          onToggle: () {
                            setState(() {
                              _isObscureConfirm = !_isObscureConfirm;
                            });
                          },
                        ),
                        errorText: _confirmPasswordError,
                        helperText:
                            '', // Prevents resizing when errorText shown
                      ),
                      textInputAction: .done,
                      onChanged: (value) {
                        setState(() {
                          _confirmPasswordError = null;
                          _confirmPassword = value;
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
