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

final _log = Logger('otp.view.configure_yubiotp_dialog');

final _modhexPattern = RegExp('[cbdefghijklnrtuv]', caseSensitive: false);

class ConfigureYubiOtpDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OtpSlot otpSlot;
  const ConfigureYubiOtpDialog(this.devicePath, this.otpSlot, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ConfigureYubiOtpDialogState();
}

class _ConfigureYubiOtpDialogState
    extends ConsumerState<ConfigureYubiOtpDialog> {
  final _keyController = TextEditingController();
  final _publicIdController = TextEditingController();
  final _privateIdController = TextEditingController();
  final maxLengthKey = 32;
  final maxLengthPublicId = 12;
  final maxLengthPrivateId = 12;
  bool _appendEnter = true;
  bool _configuring = false;

  @override
  void dispose() {
    _keyController.dispose();
    _publicIdController.dispose();
    _privateIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final info = ref.watch(currentDeviceDataProvider).valueOrNull?.info;

    final secret = _keyController.text.replaceAll(' ', '');
    final privateId = _privateIdController.text;
    String publicId = _publicIdController.text;

    return ResponsiveDialog(
      allowCancel: !_configuring,
      title: Text(l10n.s_yubiotp),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: _configuring
              ? null
              : () async {
                  if (!(secret.isNotEmpty && secret.length * 5 % 8 < 5)) {
                    setState(() {
                      _configuring = false;
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
                    if (info != null && publicId == info.serial.toString()) {
                      publicId =
                          await otpNotifier.modhexEncodeSerial(info.serial!);
                    }
                    await otpNotifier.configureSlot(widget.otpSlot.slot,
                        configuration: SlotConfiguration.yubiotp(
                            publicId: publicId,
                            privateId: privateId,
                            key: secret,
                            options: SlotConfigurationOptions(
                                appendCr: _appendEnter)));
                    await ref.read(withContextProvider)((context) async {
                      Navigator.of(context).pop();
                      showMessage(context,
                          l10n.l_slot_configuration_programmed(l10n.s_yubiotp));
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
              key: keys.publicIdField,
              autofocus: true,
              controller: _publicIdController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: maxLengthPublicId,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: l10n.s_use_serial,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    onPressed: () {
                      setState(() {
                        _publicIdController.text = info!.serial.toString();
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.public_outlined),
                  labelText: l10n.s_public_id),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(_modhexPattern)
              ],
              textInputAction: TextInputAction.next,
            ),
            TextField(
              key: keys.privateIdField,
              controller: _privateIdController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: maxLengthPrivateId,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: l10n.s_generate_private_id,
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      final random = Random.secure();
                      final key = List.generate(
                          6,
                          (_) => random
                              .nextInt(256)
                              .toRadixString(16)
                              .padLeft(2, '0')).join();
                      setState(() {
                        _privateIdController.text = key;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key_outlined),
                  labelText: l10n.s_private_id),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    RegExp('[a-f0-9]', caseSensitive: false))
              ],
              textInputAction: TextInputAction.next,
            ),
            TextField(
              key: keys.secretField,
              controller: _keyController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: maxLengthKey,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: l10n.s_generate_secret_key,
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      final random = Random.secure();
                      final key = List.generate(
                          16,
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
                  labelText: l10n.s_secret_key),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    RegExp('[a-f0-9]', caseSensitive: false))
              ],
              textInputAction: TextInputAction.next,
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
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
