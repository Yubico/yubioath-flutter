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
  bool _isObscureCurrent = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

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
    final isValid =
        !_currentIsWrong &&
        _newPassword.isNotEmpty &&
        _newPassword == _confirmPassword &&
        (!widget.state.hasKey || _currentPasswordController.text.isNotEmpty);

    final newPasswordEnabled =
        !widget.state.hasKey || _currentPasswordController.text.isNotEmpty;

    final confirmPasswordEnabled =
        (!widget.state.hasKey || _currentPasswordController.text.isNotEmpty) &&
        _newPassword.isNotEmpty;

    return ResponsiveDialog(
      title: Text(
        widget.state.hasKey ? l10n.s_manage_password : l10n.s_set_password,
      ),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          key: keys.savePasswordButton,
          child: Text(l10n.s_save),
        ),
      ],
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          errorText: _currentIsWrong
                              ? l10n.p_wrong_password
                              : null,
                          errorMaxLines: 3,
                          icon: const Icon(Symbols.password),
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
                            tooltip: _isObscureCurrent
                                ? l10n.s_show_password
                                : l10n.s_hide_password,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
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
                                onPressed:
                                    _currentPasswordController
                                            .text
                                            .isNotEmpty &&
                                        !_currentIsWrong
                                    ? () async {
                                        _removeFocus();

                                        final result = await ref
                                            .read(
                                              oathStateProvider(
                                                widget.path,
                                              ).notifier,
                                            )
                                            .unsetPassword(
                                              _currentPasswordController.text,
                                            );
                                        if (result) {
                                          if (mounted) {
                                            await ref.read(withContextProvider)(
                                              (context) async {
                                                Navigator.of(context).pop();
                                                showMessage(
                                                  context,
                                                  l10n.s_password_removed,
                                                );
                                              },
                                            );
                                          }
                                        } else {
                                          _currentPasswordController.selection =
                                              TextSelection(
                                                baseOffset: 0,
                                                extentOffset:
                                                    _currentPasswordController
                                                        .text
                                                        .length,
                                              );
                                          _currentPasswordFocus.requestFocus();
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
                        helperText: l10n.p_new_password_requirements,
                        helperMaxLines: 3,
                        icon: const Icon(Symbols.password),
                        suffixIcon: ExcludeFocusTraversal(
                          excluding: !newPasswordEnabled,
                          child: IconButton(
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
                            tooltip: _isObscureNew
                                ? l10n.s_show_password
                                : l10n.s_hide_password,
                          ),
                        ),
                        enabled: newPasswordEnabled,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        setState(() {
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
                        icon: const Icon(Symbols.password),
                        suffixIcon: ExcludeFocusTraversal(
                          excluding: !confirmPasswordEnabled,
                          child: IconButton(
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
                            tooltip: _isObscureConfirm
                                ? l10n.s_show_password
                                : l10n.s_hide_password,
                          ),
                        ),
                        enabled: confirmPasswordEnabled,
                        errorText:
                            _newPassword.length == _confirmPassword.length &&
                                _newPassword != _confirmPassword
                            ? l10n.l_password_mismatch
                            : null,
                        helperText:
                            '', // Prevents resizing when errorText shown
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
                        } else {
                          _confirmPasswordFocus.requestFocus();
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
