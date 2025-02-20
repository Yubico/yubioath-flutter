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
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';

class UnlockForm extends ConsumerStatefulWidget {
  final DevicePath _devicePath;
  final KeystoreState keystore;
  const UnlockForm(this._devicePath, {required this.keystore, super.key});

  @override
  ConsumerState<UnlockForm> createState() => _UnlockFormState();
}

class _UnlockFormState extends ConsumerState<UnlockForm> {
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _remember = false;
  bool _passwordIsWrong = false;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _passwordFocus.requestFocus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      _passwordIsWrong = false;
    });
    try {
      final (success, remembered) = await ref
          .read(oathStateProvider(widget._devicePath).notifier)
          .unlock(_passwordController.text, remember: _remember);
      if (!mounted) return;
      if (!success) {
        _passwordController.selection = TextSelection(
            baseOffset: 0, extentOffset: _passwordController.text.length);
        _passwordFocus.requestFocus();
        setState(() {
          _passwordIsWrong = true;
        });
      } else if (_remember && !remembered) {
        showMessage(context, AppLocalizations.of(context).l_remember_pw_failed);
      }
    } on CancellationException catch (_) {
      // ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keystoreFailed = widget.keystore == KeystoreState.failed;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.l_enter_oath_pw,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                child: AppTextField(
                  key: keys.passwordField,
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  autofocus: true,
                  obscureText: _isObscure,
                  autofillHints: const [AutofillHints.password],
                  decoration: AppInputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.s_password,
                    errorText: _passwordIsWrong ? l10n.s_wrong_password : null,
                    helperText: '', // Prevents resizing when errorText shown
                    icon: const Icon(Symbols.password),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure
                          ? Symbols.visibility
                          : Symbols.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      tooltip: _isObscure
                          ? l10n.s_show_password
                          : l10n.s_hide_password,
                    ),
                  ),
                  onChanged: (_) => setState(() {
                    _passwordIsWrong = false;
                  }), // Update state on change
                  onSubmitted: (_) => _submit(),
                ).init(),
              ),
              const SizedBox(height: 3.0),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4.0,
                      runSpacing: 8.0,
                      children: [
                        keystoreFailed
                            ? Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4.0,
                                runSpacing: 8.0,
                                children: [
                                  Icon(Symbols.warning_amber,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary),
                                  Text(l10n.l_keystore_unavailable)
                                ],
                              )
                            : FilterChip(
                                label: Text(l10n.s_remember_password),
                                selected: _remember,
                                onSelected: (value) {
                                  setState(() {
                                    _remember = value;
                                  });
                                },
                              ),
                        FilledButton.icon(
                          key: keys.unlockButton,
                          label: Text(l10n.s_unlock),
                          icon: const Icon(Symbols.lock_open),
                          onPressed: _passwordController.text.isNotEmpty &&
                                  !_passwordIsWrong
                              ? _submit
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
