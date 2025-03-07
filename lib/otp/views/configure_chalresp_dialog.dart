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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'access_code_dialog.dart';
import 'overwrite_confirm_dialog.dart';

final _log = Logger('otp.view.configure_chalresp_dialog');

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
  final _secretController = TextEditingController();
  final _secretFocus = FocusNode();
  bool _validateSecret = false;
  bool _requireTouch = false;
  final int secretMaxLength = 40;

  @override
  void dispose() {
    _secretController.dispose();
    _secretFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final secret = _secretController.text;
    final secretLengthValid = secret.isNotEmpty &&
        secret.length % 2 == 0 &&
        secret.length <= secretMaxLength;
    final secretFormatValid = Format.hex.isValid(secret);

    void submit() async {
      if (!secretLengthValid || !secretFormatValid) {
        setState(() {
          _validateSecret = true;
        });
        return;
      }

      if (!await confirmOverwrite(context, widget.otpSlot)) {
        return;
      }

      final otpNotifier =
          ref.read(otpStateProvider(widget.devicePath).notifier);
      final configuration = SlotConfiguration.chalresp(
          key: secret,
          options: SlotConfigurationOptions(requireTouch: _requireTouch));

      bool configurationSucceeded = false;
      try {
        await otpNotifier.configureSlot(widget.otpSlot.slot,
            configuration: configuration);
        configurationSucceeded = true;
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
                      await otpNotifier.configureSlot(widget.otpSlot.slot,
                          configuration: configuration, accessCode: accessCode);
                    },
                  ));
          configurationSucceeded = result ?? false;
        });
      }

      await ref.read(withContextProvider)((context) async {
        Navigator.of(context).pop();
        if (configurationSucceeded) {
          showMessage(context,
              l10n.l_slot_credential_configured(l10n.s_challenge_response));
        }
      });
    }

    return ResponsiveDialog(
      title: Text(l10n.s_challenge_response),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: !_validateSecret ? submit : null,
          child: Text(l10n.s_save),
        )
      ],
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              key: keys.secretField,
              autofocus: true,
              controller: _secretController,
              focusNode: _secretFocus,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: secretMaxLength,
              decoration: AppInputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_secret_key,
                  errorText: _validateSecret && !secretFormatValid
                      ? l10n.l_invalid_format_allowed_chars(
                          Format.hex.allowedCharacters)
                      : _validateSecret && !secretLengthValid
                          ? l10n.s_invalid_length
                          : null,
                  icon: const Icon(Symbols.key),
                  suffixIcon: IconButton(
                    key: keys.generateSecretKey,
                    icon: const Icon(Symbols.refresh),
                    onPressed: () {
                      setState(() {
                        final random = Random.secure();
                        final key = List.generate(
                            20,
                            (_) => random
                                .nextInt(256)
                                .toRadixString(16)
                                .padLeft(2, '0')).join();
                        setState(() {
                          _secretController.text = key;
                          _validateSecret = false;
                        });
                      });
                    },
                    tooltip: l10n.s_generate_random,
                  )),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _validateSecret = false;
                });
              },
              onSubmitted: (_) {
                if (!_validateSecret) {
                  submit();
                } else {
                  _secretFocus.requestFocus();
                }
              },
            ).init(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Icon(
                    Symbols.tune,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16.0),
                FilterChip(
                  label: Text(l10n.s_require_touch),
                  selected: _requireTouch,
                  onSelected: (value) {
                    setState(() {
                      _requireTouch = value;
                    });
                  },
                ),
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
