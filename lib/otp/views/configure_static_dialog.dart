/*
 * Copyright (C) 2023-2026 Yubico.
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
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'access_code_dialog.dart';
import 'overwrite_confirm_dialog.dart';

final _log = Logger('otp.view.configure_static_dialog');

class ConfigureStaticDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OtpSlot otpSlot;
  final Map<String, KeyboardLayout> keyboardLayouts;

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
  String? _passwordError;
  bool _appendEnter = true;
  String _keyboardLayout = '';
  String _variant = '';

  @override
  void initState() {
    super.initState();
    _keyboardLayout = widget.keyboardLayouts.keys.toList()[0];
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  RegExp generateFormatterPattern(String layout) {
    final allowedCharacters =
        widget.keyboardLayouts[layout]?.charactersFor(_variant) ?? [];

    final pattern = allowedCharacters
        .map((char) => RegExp.escape(char))
        .join('');

    return RegExp('^[$pattern]+\$', caseSensitive: false);
  }

  /// The helper selector string for the current layout + variant, e.g. `de` or
  /// `de:dvorak`.
  String get _layoutSelector =>
      widget.keyboardLayouts[_keyboardLayout]?.selector(_variant) ??
      _keyboardLayout;

  Future<String?> _selectLayout(BuildContext context) => showBlurDialog<String>(
    context: context,
    builder: (context) => _LayoutPickerDialog(
      layouts: widget.keyboardLayouts.values.toList(),
      selected: _keyboardLayout,
    ),
  );

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
      _passwordFocus.unfocus();

      if (password.isEmpty) {
        _passwordFocus.requestFocus();
        setState(() {
          _passwordError = l10n.l_field_required;
        });
        return;
      }
      if (!passwordLengthValid) {
        _passwordFocus.requestFocus();
        setState(() {
          _passwordError = l10n.s_invalid_length;
        });
        return;
      }
      if (!passwordFormatValid) {
        _passwordFocus.requestFocus();
        setState(() {
          _passwordError = l10n.l_invalid_keyboard_character;
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
        keyboardLayout: _layoutSelector,
        options: SlotConfigurationOptions(appendCr: _appendEnter),
      );

      bool configurationSucceeded = false;
      try {
        await otpNotifier.configureSlot(
          widget.otpSlot.slot,
          configuration: configuration,
        );
        configurationSucceeded = true;
      } on CancellationException {
        // The user dismissed the NFC overlay, this is not an access code failure.
        return;
      } catch (e) {
        _log.error('Failed to program credential', e);
        // Access code required
        await ref.read(withContextProvider)((context) async {
          final result = await showBlurDialog(
            context: context,
            builder: (context) => AccessCodeDialog(
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
          onPressed: submit,
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
                      key: keys.secretField,
                      autofocus: true,
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      autofillHints: isAndroid
                          ? []
                          : const [AutofillHints.password],
                      maxLength: passwordMaxLength,
                      buildCounter: buildByteCounterFor(
                        _passwordController.text,
                      ),
                      inputFormatters: [limitBytesLength(passwordMaxLength)],
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_password,
                        isRequired: true,
                        errorText: _passwordError,
                        icon: const Icon(Symbols.key),
                        suffixIcon: IconButton(
                          key: keys.generateSecretKey,
                          tooltip: l10n.s_generate_random,
                          icon: const Icon(Symbols.refresh),
                          onPressed: () async {
                            final password = await ref
                                .read(
                                  otpStateProvider(widget.devicePath).notifier,
                                )
                                .generateStaticPassword(
                                  passwordMaxLength,
                                  _layoutSelector,
                                );
                            setState(() {
                              _passwordController.text = password;
                              _passwordError = null;
                            });
                          },
                        ),
                      ),
                      textInputAction: .done,
                      onChanged: (value) {
                        setState(() {
                          _passwordError = null;
                        });
                      },
                      onSubmitted: (_) {
                        submit();
                      },
                    ).init(),
                    Row(
                      crossAxisAlignment: .start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Icon(
                            Symbols.tune,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Flexible(
                          child: Wrap(
                            crossAxisAlignment: .start,
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
                              ActionChip(
                                avatar: const Icon(Symbols.keyboard),
                                label: Text(
                                  widget
                                          .keyboardLayouts[_keyboardLayout]
                                          ?.description ??
                                      _keyboardLayout,
                                ),
                                tooltip: l10n.s_keyboard_layout,
                                onPressed: () async {
                                  final selected = await _selectLayout(context);
                                  if (selected != null) {
                                    setState(() {
                                      _keyboardLayout = selected;
                                      // Reset the variant when the layout
                                      // changes; the previous variant may not
                                      // exist in the new layout.
                                      _variant = '';
                                      _passwordError = null;
                                    });
                                  }
                                },
                              ),
                              if (widget
                                      .keyboardLayouts[_keyboardLayout]
                                      ?.variants
                                      .isNotEmpty ??
                                  false)
                                ChoiceFilterChip<String>(
                                  avatar: const Icon(Symbols.tune),
                                  items: [
                                    '',
                                    ...widget
                                        .keyboardLayouts[_keyboardLayout]!
                                        .variants
                                        .keys,
                                  ],
                                  value: _variant,
                                  tooltip: l10n.s_keyboard_variant,
                                  selected: _variant.isNotEmpty,
                                  labelBuilder: (value) => Text(
                                    value.isEmpty
                                        ? l10n.s_keyboard_variant_default
                                        : value,
                                  ),
                                  itemBuilder: (value) => Text(
                                    value.isEmpty
                                        ? l10n.s_keyboard_variant_default
                                        : value,
                                  ),
                                  onChanged: (variant) {
                                    setState(() {
                                      _variant = variant;
                                      _passwordError = null;
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

/// A searchable picker dialog for selecting a keyboard layout by its
/// human-readable description. Used instead of a long, flat popup menu.
class _LayoutPickerDialog extends StatefulWidget {
  final List<KeyboardLayout> layouts;
  final String selected;

  const _LayoutPickerDialog({required this.layouts, required this.selected});

  @override
  State<_LayoutPickerDialog> createState() => _LayoutPickerDialogState();
}

class _LayoutPickerDialogState extends State<_LayoutPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _query.trim().toLowerCase();
    final filtered = widget.layouts
        .where(
          (layout) =>
              query.isEmpty ||
              layout.description.toLowerCase().contains(query) ||
              layout.name.toLowerCase().contains(query),
        )
        .toList();

    return AlertDialog(
      title: Text(l10n.s_keyboard_layout),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
      content: SizedBox(
        width: 320,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                autofocus: true,
                decoration: AppInputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_search,
                  prefixIcon: const Icon(Symbols.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final layout = filtered[index];
                  final selected = layout.name == widget.selected;
                  return ListTile(
                    dense: true,
                    selected: selected,
                    title: Text(layout.description),
                    trailing: selected ? const Icon(Symbols.check) : null,
                    onTap: () => Navigator.of(context).pop(layout.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.s_cancel),
        ),
      ],
    );
  }
}
