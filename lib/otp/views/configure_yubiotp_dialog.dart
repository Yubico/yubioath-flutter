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

import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'overwrite_confirm_dialog.dart';

final _log = Logger('otp.view.configure_yubiotp_dialog');

enum OutputActions {
  selectFile,
  noOutput;

  const OutputActions();

  String getDisplayName(AppLocalizations l10n) => switch (this) {
        OutputActions.selectFile => 'Select file',
        OutputActions.noOutput => 'No export file'
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
  OutputActions _action = OutputActions.noOutput;
  bool _appendEnter = true;
  bool _validateSecretFormat = false;
  bool _validatePublicIdFormat = false;
  bool _validatePrivateIdFormat = false;
  final secretLength = 32;
  final publicIdLength = 12;
  final privateIdLength = 12;

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

    final secret = _secretController.text;
    final secretLengthValid = secret.length == secretLength;
    final secretFormatValid = Format.hex.isValid(secret);

    final privateId = _privateIdController.text;
    final privateIdLengthValid = privateId.length == privateIdLength;
    final privatedIdFormatValid = Format.hex.isValid(privateId);

    final publicId = _publicIdController.text;
    final publicIdLengthValid = publicId.length == publicIdLength;
    final publicIdFormatValid = Format.modhex.isValid(publicId);

    final lengthsValid =
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
          onPressed: lengthsValid
              ? () async {
                  if (!secretFormatValid ||
                      !publicIdFormatValid ||
                      !privatedIdFormatValid) {
                    setState(() {
                      _validateSecretFormat = !secretFormatValid;
                      _validatePublicIdFormat = !publicIdFormatValid;
                      _validatePrivateIdFormat = !privatedIdFormatValid;
                    });
                    return;
                  }

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
                              ? l10n.l_slot_credential_configured_and_exported(
                                  l10n.s_yubiotp,
                                  outputFile.uri.pathSegments.last)
                              : l10n.l_slot_credential_configured(
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
                border: const OutlineInputBorder(),
                labelText: l10n.s_public_id,
                errorText: _validatePublicIdFormat && !publicIdFormatValid
                    ? l10n.l_invalid_format_allowed_chars(
                        Format.modhex.allowedCharacters)
                    : null,
                prefixIcon: const Icon(Icons.public_outlined),
                suffixIcon: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
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
                    if (_validatePublicIdFormat) ...[
                      const Icon(Icons.error_outlined),
                      const SizedBox(
                        width: 8.0,
                      )
                    ]
                  ],
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _validatePublicIdFormat = false;
                });
              },
            ),
            TextField(
              key: keys.privateIdField,
              controller: _privateIdController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: privateIdLength,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_private_id,
                errorText: _validatePrivateIdFormat && !privatedIdFormatValid
                    ? l10n.l_invalid_format_allowed_chars(
                        Format.hex.allowedCharacters)
                    : null,
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: l10n.s_generate_random,
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
                    if (_validatePrivateIdFormat) ...[
                      const Icon(Icons.error_outlined),
                      const SizedBox(
                        width: 8.0,
                      )
                    ]
                  ],
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _validatePrivateIdFormat = false;
                });
              },
            ),
            TextField(
              key: keys.secretField,
              controller: _secretController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: secretLength,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_secret_key,
                errorText: _validateSecretFormat && !secretFormatValid
                    ? l10n.l_invalid_format_allowed_chars(
                        Format.hex.allowedCharacters)
                    : null,
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: l10n.s_generate_random,
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
                    if (_validateSecretFormat) ...[
                      const Icon(Icons.error_outlined),
                      const SizedBox(
                        width: 8.0,
                      )
                    ]
                  ],
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _validateSecretFormat = false;
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
                        fileName != null
                            ? 'Export $fileName'
                            : _action.getDisplayName(l10n),
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
