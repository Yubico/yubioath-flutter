/*
 * Copyright (C) 2023 Yubico.
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
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/widgets/choice_filter_chip.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;
import 'overwrite_confirm_dialog.dart';

final _log = Logger('otp.view.configure_Chalresp_dialog');

class ConfigureStaticDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OtpSlot otpSlot;
  final Map<String, List<String>> keyboardLayouts;
  const ConfigureStaticDialog(
      this.devicePath, this.otpSlot, this.keyboardLayouts,
      {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ConfigureStaticDialogState();
}

class _ConfigureStaticDialogState extends ConsumerState<ConfigureStaticDialog> {
  final _passwordController = TextEditingController();
  bool _invalidPasswordLength = false;
  bool _configuring = false;
  bool _appendEnter = true;
  String _keyboardLayout = '';
  final maxLength = 38;

  @override
  void initState() {
    super.initState();
    _keyboardLayout = widget.keyboardLayouts.keys.toList()[0];
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  RegExp generateFormatterPattern(String layout) {
    final allowedCharacters = widget.keyboardLayouts[layout] ?? [];

    final pattern =
        allowedCharacters.map((char) => RegExp.escape(char)).join('');

    return RegExp('[$pattern]', caseSensitive: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final secret = _passwordController.text.replaceAll(' ', '');

    return ResponsiveDialog(
      allowCancel: !_configuring,
      title: Text(l10n.s_static_password),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: _configuring || _invalidPasswordLength
              ? null
              : () async {
                  if (!(secret.isNotEmpty && secret.length <= maxLength)) {
                    setState(() {
                      _configuring = false;
                      _invalidPasswordLength = true;
                    });
                    return;
                  }

                  if (!await confirmOverwrite(context, widget.otpSlot)) {
                    return;
                  }

                  setState(() {
                    _configuring = true;
                  });

                  final otpNotifier =
                      ref.read(otpStateProvider(widget.devicePath).notifier);
                  try {
                    await otpNotifier.configureSlot(widget.otpSlot.slot,
                        configuration: SlotConfiguration.static(
                            password: secret,
                            keyboardLayout: _keyboardLayout,
                            options: SlotConfigurationOptions(
                                appendCr: _appendEnter)));
                    await ref.read(withContextProvider)((context) async {
                      Navigator.of(context).pop();
                      showMessage(
                          context,
                          l10n.l_slot_configuration_programmed(
                              l10n.s_static_password));
                    });
                  } catch (e) {
                    _log.error('Failed to program credential', e);
                    await ref.read(withContextProvider)((context) async {
                      showMessage(
                        context,
                        l10n.p_otp_slot_configuration_error(
                            widget.otpSlot.slot.getDisplayName(l10n)),
                        duration: const Duration(seconds: 4),
                      );
                    });
                  }
                },
          child: Text(l10n.s_save),
        )
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: keys.secretField,
              autofocus: true,
              controller: _passwordController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: maxLength,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: l10n.s_generate_passowrd,
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final password = await ref
                          .read(otpStateProvider(widget.devicePath).notifier)
                          .generateStaticPassword(maxLength, _keyboardLayout);
                      setState(() {
                        _passwordController.text = password;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key_outlined),
                  labelText: l10n.s_password,
                  errorText:
                      _invalidPasswordLength ? l10n.s_invalid_length : null),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    generateFormatterPattern(_keyboardLayout))
              ],
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _invalidPasswordLength = false;
                });
              },
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4.0,
              runSpacing: 8.0,
              children: [
                ChoiceFilterChip(
                    items: widget.keyboardLayouts.keys.toList(),
                    value: _keyboardLayout,
                    itemBuilder: (value) => Text(value),
                    onChanged: (layout) {
                      setState(() {
                        _keyboardLayout = layout;
                      });
                    }),
                FilterChip(
                  label: Text(l10n.s_append_enter),
                  tooltip: l10n.l_append_enter_desc,
                  selected: _appendEnter,
                  onSelected: (value) {
                    setState(() {
                      _appendEnter = value;
                    });
                  },
                )
              ],
            )
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
}
