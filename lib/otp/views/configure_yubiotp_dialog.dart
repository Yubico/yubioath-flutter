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

import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
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

final _log = Logger('otp.view.configure_yubiotp_dialog');

enum OutputActions {
  selectFile,
  noOutput;

  const OutputActions();

  String getDisplayName(AppLocalizations l10n) => switch (this) {
        OutputActions.selectFile => l10n.l_select_file,
        OutputActions.noOutput => l10n.l_no_export_file,
      };
}

final uploadOtpUri = Uri.parse('https://upload.yubico.com');

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
  final _secretFocus = FocusNode();
  final _publicIdController = TextEditingController();
  final _publicIdFocus = FocusNode();
  final _privateIdController = TextEditingController();
  final _privateIdFocus = FocusNode();
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
    _secretFocus.dispose();
    _publicIdFocus.dispose();
    _privateIdFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final info = ref.watch(currentDeviceDataProvider).valueOrNull?.info;

    final secret = _secretController.text;
    final secretLengthValid = secret.length == secretLength;
    final secretFormatValid = Format.hex.isValid(secret);

    final privateId = _privateIdController.text;
    final privateIdLengthValid = privateId.length == privateIdLength;
    final privateIdFormatValid = Format.hex.isValid(privateId);

    final publicId = _publicIdController.text;
    final publicIdLengthValid = publicId.length == publicIdLength;
    final publicIdFormatValid = Format.modhex.isValid(publicId);

    final lengthsValid =
        secretLengthValid && privateIdLengthValid && publicIdLengthValid;

    final outputFile = ref.read(yubiOtpOutputProvider);

    _createUploadText(context, l10n);

    void submit() async {
      if (!secretFormatValid || !publicIdFormatValid || !privateIdFormatValid) {
        setState(() {
          _validateSecretFormat = !secretFormatValid;
          _validatePublicIdFormat = !publicIdFormatValid;
          _validatePrivateIdFormat = !privateIdFormatValid;
        });
        return;
      }

      if (!await confirmOverwrite(context, widget.otpSlot)) {
        return;
      }

      final otpNotifier = ref.read(
        otpStateProvider(widget.devicePath).notifier,
      );
      final configuration = SlotConfiguration.yubiotp(
        publicId: publicId,
        privateId: privateId,
        key: secret,
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

      if (configurationSucceeded) {
        if (outputFile != null) {
          final csv = await otpNotifier.formatYubiOtpCsv(
            info!.serial!,
            publicId,
            privateId,
            secret,
          );

          await outputFile.writeAsString(
            '$csv${Platform.lineTerminator}',
            mode: FileMode.append,
          );
        }
      }
      await ref.read(withContextProvider)((context) async {
        Navigator.of(context).pop();
        if (configurationSucceeded) {
          showMessage(
            context,
            outputFile != null
                ? l10n.l_slot_credential_configured_and_exported(
                    l10n.s_capability_otp,
                    outputFile.uri.pathSegments.last,
                  )
                : l10n.l_slot_credential_configured(l10n.s_capability_otp),
          );
        }
      });
    }

    Future<bool> selectFile() async {
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.l_export_configuration_file,
        allowedExtensions: ['csv'],
        fileName: 'yubico-otp-$publicId.csv',
        type: FileType.custom,
        lockParentWindow: true,
      );

      if (filePath == null) {
        return false;
      }

      // Windows only: Append csv extension if missing
      if (Platform.isWindows && !filePath.toLowerCase().endsWith('.csv')) {
        filePath += '.csv';
      }

      ref.read(yubiOtpOutputProvider.notifier).setOutput(File(filePath));
      return true;
    }

    return ResponsiveDialog(
      title: Text(l10n.s_capability_otp),
      actions: [
        TextButton(
          key: keys.saveButton,
          onPressed: lengthsValid ? submit : null,
          child: Text(l10n.s_save),
        ),
      ],
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              key: keys.publicIdField,
              autofocus: true,
              controller: _publicIdController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              focusNode: _publicIdFocus,
              maxLength: publicIdLength,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_public_id,
                errorText: _validatePublicIdFormat && !publicIdFormatValid
                    ? l10n.l_invalid_format_allowed_chars(
                        Format.modhex.allowedCharacters,
                      )
                    : null,
                icon: const Icon(Symbols.public),
                suffixIcon: IconButton(
                  key: keys.useSerial,
                  tooltip: l10n.s_use_serial,
                  icon: const Icon(Symbols.auto_awesome),
                  onPressed: (info?.serial != null)
                      ? () async {
                          final publicId = await ref
                              .read(
                                otpStateProvider(
                                  widget.devicePath,
                                ).notifier,
                              )
                              .modhexEncodeSerial(info!.serial!);
                          setState(() {
                            _publicIdController.text = publicId;
                          });
                        }
                      : null,
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _validatePublicIdFormat = false;
                });
              },
              onSubmitted: (_) {
                if (publicIdLengthValid) {
                  _privateIdFocus.requestFocus();
                } else {
                  _publicIdFocus.requestFocus();
                }
              },
            ).init(),
            AppTextField(
              key: keys.privateIdField,
              controller: _privateIdController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: privateIdLength,
              focusNode: _privateIdFocus,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_private_id,
                errorText: _validatePrivateIdFormat && !privateIdFormatValid
                    ? l10n.l_invalid_format_allowed_chars(
                        Format.hex.allowedCharacters,
                      )
                    : null,
                icon: const Icon(Symbols.key),
                suffixIcon: IconButton(
                  key: keys.generatePrivateId,
                  tooltip: l10n.s_generate_random,
                  icon: const Icon(Symbols.refresh),
                  onPressed: () {
                    final random = Random.secure();
                    final key = List.generate(
                      6,
                      (_) =>
                          random.nextInt(256).toRadixString(16).padLeft(2, '0'),
                    ).join();
                    setState(() {
                      _privateIdController.text = key;
                    });
                  },
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _validatePrivateIdFormat = false;
                });
              },
              onSubmitted: (_) {
                if (privateIdLengthValid) {
                  _secretFocus.requestFocus();
                } else {
                  _privateIdFocus.requestFocus();
                }
              },
            ).init(),
            AppTextField(
              key: keys.secretField,
              controller: _secretController,
              autofillHints: isAndroid ? [] : const [AutofillHints.password],
              maxLength: secretLength,
              focusNode: _secretFocus,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_secret_key,
                errorText: _validateSecretFormat && !secretFormatValid
                    ? l10n.l_invalid_format_allowed_chars(
                        Format.hex.allowedCharacters,
                      )
                    : null,
                icon: const Icon(Symbols.key),
                suffixIcon: IconButton(
                  key: keys.generateSecretKey,
                  tooltip: l10n.s_generate_random,
                  icon: const Icon(Symbols.refresh),
                  onPressed: () {
                    final random = Random.secure();
                    final key = List.generate(
                      16,
                      (_) =>
                          random.nextInt(256).toRadixString(16).padLeft(2, '0'),
                    ).join();
                    setState(() {
                      _secretController.text = key;
                    });
                  },
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _validateSecretFormat = false;
                });
              },
              onSubmitted: (_) {
                if (lengthsValid) {
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                  ),
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
                      ChoiceFilterChip<OutputActions>(
                        tooltip: outputFile?.path ?? l10n.s_no_export,
                        selected: outputFile != null,
                        avatar: outputFile != null
                            ? Icon(
                                Symbols.check,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                              )
                            : null,
                        value: _action,
                        items: OutputActions.values,
                        itemBuilder: (value) =>
                            Text(value.getDisplayName(l10n)),
                        labelBuilder: (_) {
                          String? fileName = outputFile?.uri.pathSegments.last;
                          return Container(
                            constraints: const BoxConstraints(
                              maxWidth: 140,
                            ),
                            child: Text(
                              fileName != null
                                  ? '${l10n.s_export} $fileName'
                                  : _action.getDisplayName(l10n),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                        onChanged: (value) async {
                          if (value == OutputActions.noOutput) {
                            ref
                                .read(
                                  yubiOtpOutputProvider.notifier,
                                )
                                .setOutput(null);
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
                  ),
                ),
              ],
            ),
            _createUploadText(context, l10n),
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

  RichText _createUploadText(BuildContext context, AppLocalizations l10n) {
    final uploadText = l10n.l_exported_can_be_uploaded_at(uploadOtpUri.host);
    final host = uploadOtpUri.host;
    final parts = uploadText.split(RegExp('(?=$host)|(?<=$host)'));

    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        children: [
          ...parts.map(
            (e) => e == uploadOtpUri.host
                ? _createUploadOtpLink(context)
                : TextSpan(text: e),
          ),
        ],
      ),
    );
  }

  TextSpan _createUploadOtpLink(BuildContext context) {
    final theme = Theme.of(context);
    return TextSpan(
      text: uploadOtpUri.host,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          await launchUrl(
            uploadOtpUri,
            mode: LaunchMode.externalApplication,
          );
        },
    );
  }
}
