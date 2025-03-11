/*
 * Copyright (C) 2023-2025 Yubico.
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
import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'access_code_dialog.dart';
import 'overwrite_confirm_dialog.dart';

final _log = Logger('otp.view.configure_static_dialog');

class ConfigureStaticDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OtpSlot otpSlot;
  final Map<String, List<String>> keyboardLayouts;

  const ConfigureStaticDialog(
    this.devicePath,
    this.otpSlot,
    this.keyboardLayouts, {
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ConfigureStaticDialogState();
}

class _ConfigureStaticDialogState extends ConsumerState<ConfigureStaticDialog> {
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final passwordMaxLength = 38;
  bool _validatePassword = false;
  bool _appendEnter = true;
  String _keyboardLayout = '';
  String _defaultKeyboardLayout = '';

  @override
  void initState() {
    super.initState();
    final modhexLayout = widget.keyboardLayouts.keys.toList()[0];
    _keyboardLayout = modhexLayout;
    _defaultKeyboardLayout = modhexLayout;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  RegExp generateFormatterPattern(String layout) {
    final allowedCharacters = widget.keyboardLayouts[layout] ?? [];

    final pattern = allowedCharacters
        .map((char) => RegExp.escape(char))
        .join('');

    return RegExp('^[$pattern]+\$', caseSensitive: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final password = _passwordController.text;
    final passwordLengthValid =
        password.isNotEmpty && password.length <= passwordMaxLength;
    final passwordFormatValid = generateFormatterPattern(
      _keyboardLayout,
    ).hasMatch(password);

    void submit() async {
      if (!passwordLengthValid || !passwordFormatValid) {
        setState(() {
          _validatePassword = true;
        });
        return;
      }

      if (!await confirmOverwrite(context, widget.otpSlot)) {
        return;
      }

      final otpNotifier = ref.read(
        otpStateProvider(widget.devicePath).notifier,
      );
      final configuration = SlotConfiguration.static(
        password: password,
        keyboardLayout: _keyboardLayout,
        options: SlotConfigurationOptions(appendCr: _appendEnter),
      );

      bool configurationSucceeded = false;
      try {
        await otpNotifier.configureSlot(
          widget.otpSlot.slot,
          configuration: configuration,
        );
        configurationSucceeded = true;
      } catch (e) {
        _log.error('Failed to program credential', e);
        // Access code required
        await ref.read(withContextProvider)((context) async {
          final result = await showBlurDialog(
            context: context,
            builder:
                (context) => AccessCodeDialog(
                  devicePath: widget.devicePath,
                  otpSlot: widget.otpSlot,
                  action: (accessCode) async {
                    await otpNotifier.configureSlot(
                      widget.otpSlot.slot,
                      configuration: configuration,
                      accessCode: accessCode,
                    );
                  },
                ),
          );
          configurationSucceeded = result ?? false;
        });
      }

      await ref.read(withContextProvider)((context) async {
        Navigator.of(context).pop();
        if (configurationSucceeded) {
          showMessage(
            context,
            l10n.l_slot_credential_configured(l10n.s_static_password),
          );
        }
      });
    }

    return ResponsiveDialog(
      title: Text(l10n.s_static_password),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: !_validatePassword ? submit : null,
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
                          key: keys.secretField,
                          autofocus: true,
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          autofillHints:
                              isAndroid ? [] : const [AutofillHints.password],
                          maxLength: passwordMaxLength,
                          decoration: AppInputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: l10n.s_password,
                            errorText:
                                _validatePassword && !passwordLengthValid
                                    ? l10n.s_invalid_length
                                    : _validatePassword && !passwordFormatValid
                                    ? l10n.l_invalid_keyboard_character
                                    : null,
                            icon: const Icon(Symbols.key),
                            suffixIcon: IconButton(
                              key: keys.generateSecretKey,
                              tooltip: l10n.s_generate_random,
                              icon: const Icon(Symbols.refresh),
                              onPressed: () async {
                                final password = await ref
                                    .read(
                                      otpStateProvider(
                                        widget.devicePath,
                                      ).notifier,
                                    )
                                    .generateStaticPassword(
                                      passwordMaxLength,
                                      _keyboardLayout,
                                    );
                                setState(() {
                                  _validatePassword = false;
                                  _passwordController.text = password;
                                });
                              },
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: (value) {
                            setState(() {
                              _validatePassword = false;
                            });
                          },
                          onSubmitted: (_) {
                            if (!_validatePassword) {
                              submit();
                            } else {
                              _passwordFocus.requestFocus();
                            }
                          },
                        ).init(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Icon(
                                Symbols.tune,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Flexible(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.start,
                                spacing: 4.0,
                                runSpacing: 8.0,
                                children: [
                                  FilterChip(
                                    label: Text(l10n.s_append_enter),
                                    tooltip: l10n.l_append_enter_desc,
                                    selected: _appendEnter,
                                    onSelected: (value) {
                                      setState(() {
                                        _appendEnter = value;
                                      });
                                    },
                                  ),
                                  ChoiceFilterChip(
                                    items: widget.keyboardLayouts.keys.toList(),
                                    value: _keyboardLayout,
                                    selected:
                                        _keyboardLayout !=
                                        _defaultKeyboardLayout,
                                    labelBuilder:
                                        (value) =>
                                            Text(l10n.l_keyboard_layout(value)),
                                    itemBuilder: (value) => Text(value),
                                    onChanged: (layout) {
                                      setState(() {
                                        _keyboardLayout = layout;
                                        _validatePassword = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
