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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:logging/logging.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;
import 'overwrite_confirm_dialog.dart';

final _log = Logger('otp.view.configure_Chalresp_dialog');

class ConfigureChalrespDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OtpSlot otpSlot;
  const ConfigureChalrespDialog(this.devicePath, this.otpSlot, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ConfigureChalrespDialogState();
}

class _ConfigureChalrespDialogState
    extends ConsumerState<ConfigureChalrespDialog> {
  final _keyController = TextEditingController();
  bool _invalidKeyLength = false;
  bool _configuring = false;
  bool _requireTouch = false;
  final int maxLength = 40;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final secret = _keyController.text.replaceAll(' ', '');

    return ResponsiveDialog(
      allowCancel: !_configuring,
      title: Text(l10n.s_challenge_response),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: _configuring || _invalidKeyLength
              ? null
              : () async {
                  if (!(secret.isNotEmpty && secret.length <= maxLength)) {
                    setState(() {
                      _configuring = false;
                      _invalidKeyLength = true;
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
                        configuration: SlotConfiguration.chalresp(
                            key: secret,
                            options: SlotConfigurationOptions(
                                requireTouch: _requireTouch)));
                    await ref.read(withContextProvider)((context) async {
                      Navigator.of(context).pop();
                      showMessage(context,
                          l10n.l_slot_configuration_programmed(l10n.s_hotp));
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
              controller: _keyController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: maxLength,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: l10n.s_generate_secret_key,
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      final random = Random.secure();
                      final key = List.generate(
                          20,
                          (_) => random
                              .nextInt(256)
                              .toRadixString(16)
                              .padLeft(2, '0')).join();
                      setState(() {
                        _keyController.text = key;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key_outlined),
                  labelText: l10n.s_secret_key,
                  errorText: _invalidKeyLength ? l10n.s_invalid_length : null),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    RegExp('[a-f0-9]', caseSensitive: false))
              ],
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _invalidKeyLength = false;
                });
              },
            ),
            FilterChip(
              label: Text(l10n.s_require_touch),
              selected: _requireTouch,
              onSelected: (value) {
                setState(() {
                  _requireTouch = value;
                });
              },
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
