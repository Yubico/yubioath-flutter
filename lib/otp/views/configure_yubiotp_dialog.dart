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
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

final _log = Logger('otp.view.configure_yubiotp_dialog');

final _modhexPattern = RegExp('[cbdefghijklnrtuv]', caseSensitive: false);

enum OutputActions {
  selectFile,
  noOutput;

  const OutputActions();

  String getDisplayName(AppLocalizations l10n) => switch (this) {
        OutputActions.selectFile => 'Select file',
        OutputActions.noOutput => 'No output'
      };
}

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
  final _secretController = TextEditingController();
  final _publicIdController = TextEditingController();
  final _privateIdController = TextEditingController();
  final secretLength = 32;
  final publicIdLength = 12;
  final privateIdLength = 12;
  OutputActions _action = OutputActions.selectFile;
  bool _appendEnter = true;

  @override
  void dispose() {
    _secretController.dispose();
    _publicIdController.dispose();
    _privateIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final info = ref.watch(currentDeviceDataProvider).valueOrNull?.info;

    final secret = _secretController.text.replaceAll(' ', '');
    final secretLengthValid = secret.length == secretLength;

    final privateId = _privateIdController.text;
    final privateIdLengthValid = privateId.length == privateIdLength;

    final publicId = _publicIdController.text;
    final publicIdLengthValid = publicId.length == publicIdLength;

    final isValid =
        secretLengthValid && privateIdLengthValid && publicIdLengthValid;

    final outputFile = ref.read(yubiOtpOutputProvider);

    Future<bool> selectFile() async {
      final filePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Export configuration to file',
          allowedExtensions: ['csv'],
          type: FileType.custom,
          lockParentWindow: true);

      if (filePath == null) {
        return false;
      }

      ref.read(yubiOtpOutputProvider.notifier).setOutput(File(filePath));
      return true;
    }

    return ResponsiveDialog(
      title: Text(l10n.s_yubiotp),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: isValid
              ? () async {
                  if (!await confirmOverwrite(context, widget.otpSlot)) {
                    return;
                  }

                  final otpNotifier =
                      ref.read(otpStateProvider(widget.devicePath).notifier);
                  try {
                    await otpNotifier.configureSlot(widget.otpSlot.slot,
                        configuration: SlotConfiguration.yubiotp(
                            publicId: publicId,
                            privateId: privateId,
                            key: secret,
                            options: SlotConfigurationOptions(
                                appendCr: _appendEnter)));
                    if (outputFile != null) {
                      final csv = await otpNotifier.formatYubiOtpCsv(
                          info!.serial!, publicId, privateId, secret);

                      await outputFile.writeAsString(
                          '$csv${Platform.lineTerminator}',
                          mode: FileMode.append);
                    }
                    await ref.read(withContextProvider)((context) async {
                      Navigator.of(context).pop();
                      showMessage(
                          context,
                          outputFile != null
                              ? l10n
                                  .l_slot_configuration_programmed_and_exported(
                                      l10n.s_yubiotp,
                                      outputFile.uri.pathSegments.last)
                              : l10n.l_slot_configuration_programmed(
                                  l10n.s_yubiotp));
                    });
                  } catch (e) {
                    _log.error('Failed to program credential', e);
                    await ref.read(withContextProvider)((context) async {
                      final String errorMessage;
                      if (e is PathNotFoundException) {
                        errorMessage = '${e.message} ${e.path.toString()}';
                      } else {
                        errorMessage = l10n.p_otp_slot_configuration_error(
                            widget.otpSlot.slot.getDisplayName(l10n));
                      }
                      showMessage(
                        context,
                        errorMessage,
                        duration: const Duration(seconds: 4),
                      );
                    });
                  }
                }
              : null,
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
              maxLength: publicIdLength,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: l10n.s_use_serial,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    onPressed: (info?.serial != null)
                        ? () async {
                            final publicId = await ref
                                .read(otpStateProvider(widget.devicePath)
                                    .notifier)
                                .modhexEncodeSerial(info!.serial!);
                            setState(() {
                              _publicIdController.text = publicId;
                            });
                          }
                        : null,
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.public_outlined),
                  labelText: l10n.s_public_id),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(_modhexPattern)
              ],
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  // Update lengths
                });
              },
            ),
            TextField(
              key: keys.privateIdField,
              controller: _privateIdController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: privateIdLength,
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
              onChanged: (value) {
                setState(() {
                  // Update lengths
                });
              },
            ),
            TextField(
              key: keys.secretField,
              controller: _secretController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: secretLength,
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
                        _secretController.text = key;
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
              onChanged: (value) {
                setState(() {
                  // Update lengths
                });
              },
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
                ),
                ChoiceFilterChip<OutputActions>(
                  tooltip: outputFile?.path ?? 'No export',
                  selected: outputFile != null,
                  avatar: outputFile != null
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.secondary)
                      : null,
                  value: _action,
                  items: OutputActions.values,
                  itemBuilder: (value) => Text(value.getDisplayName(l10n)),
                  labelBuilder: (_) {
                    String? fileName = outputFile?.uri.pathSegments.last;
                    return Container(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        'Output ${fileName ?? 'No output'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                  onChanged: (value) async {
                    if (value == OutputActions.noOutput) {
                      ref.read(yubiOtpOutputProvider.notifier).setOutput(null);
                      setState(() {
                        _action = value;
                      });
                    } else if (value == OutputActions.selectFile) {
                      if (await selectFile()) {
                        setState(() {
                          _action = value;
                        });
                      }
                    }
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
