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

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/l10n_utils.dart';
import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
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
import '../yubiotp_csv.dart';
import 'access_code_dialog.dart';
import 'overwrite_confirm_dialog.dart';

final _log = Logger('otp.view.configure_yubiotp_dialog');

enum OutputActions {
  selectFile,
  createFile,
  noOutput;

  const OutputActions();

  String getDisplayName(AppLocalizations l10n) => switch (this) {
    OutputActions.selectFile => l10n.l_select_file,
    OutputActions.createFile => l10n.l_create_export_file,
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
  String? _publicIdError;
  String? _privateIdError;
  String? _secretError;
  final secretLength = 32;
  final publicIdLength = 12;
  final privateIdLength = 12;

  /// The "can be uploaded at upload.yubico.com" footer.
  ///
  /// Built here rather than in [build] because it owns a `TapGestureRecognizer`,
  /// and this dialog rebuilds on every keystroke.
  late Text _uploadText;

  /// The recognizers backing the links in [_uploadText], disposed in [dispose].
  final List<TapGestureRecognizer> _uploadLinkRecognizers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // didChangeDependencies can fire more than once (e.g. on a theme or locale
    // change); drop the previous build's recognizers before creating new ones.
    _disposeUploadLinkRecognizers();
    _uploadText = injectLinksInText(
      l10n.l_exported_can_be_uploaded_at(uploadOtpUri.host),
      {uploadOtpUri.host: uploadOtpUri},
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      linkStyle: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      recognizers: _uploadLinkRecognizers,
    );
  }

  void _disposeUploadLinkRecognizers() {
    for (final recognizer in _uploadLinkRecognizers) {
      recognizer.dispose();
    }
    _uploadLinkRecognizers.clear();
  }

  @override
  void dispose() {
    _secretController.dispose();
    _publicIdController.dispose();
    _privateIdController.dispose();
    _secretFocus.dispose();
    _publicIdFocus.dispose();
    _privateIdFocus.dispose();
    _disposeUploadLinkRecognizers();
    super.dispose();
  }

  void _removeFocus() {
    _publicIdFocus.unfocus();
    _privateIdFocus.unfocus();
    _secretFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final info = ref.watch(currentDeviceDataProvider).value?.info;

    final secret = _secretController.text;
    final secretLengthValid = secret.length == secretLength;
    final secretFormatValid = Format.hex.isValid(secret);

    final privateId = _privateIdController.text;
    final privateIdLengthValid = privateId.length == privateIdLength;
    final privateIdFormatValid = Format.hex.isValid(privateId);

    final publicId = _publicIdController.text;
    final publicIdLengthValid = publicId.length == publicIdLength;
    final publicIdFormatValid = Format.modhex.isValid(publicId);

    final outputFile = ref.read(yubiOtpOutputProvider);

    void submit() async {
      _removeFocus();

      // The first field that failed validation, refocused so the user can
      // correct it.
      FocusNode? invalidField;

      if (publicId.isEmpty) {
        _publicIdError = l10n.l_field_required;
        invalidField ??= _publicIdFocus;
      } else if (!publicIdFormatValid) {
        _publicIdError = l10n.l_invalid_format_allowed_chars(
          Format.modhex.allowedCharacters,
        );
        invalidField ??= _publicIdFocus;
      } else if (!publicIdLengthValid) {
        _publicIdError = l10n.s_invalid_length;
        invalidField ??= _publicIdFocus;
      }

      if (privateId.isEmpty) {
        _privateIdError = l10n.l_field_required;
        invalidField ??= _privateIdFocus;
      } else if (!privateIdFormatValid) {
        _privateIdError = l10n.l_invalid_format_allowed_chars(
          Format.hex.allowedCharacters,
        );
        invalidField ??= _privateIdFocus;
      } else if (!privateIdLengthValid) {
        _privateIdError = l10n.s_invalid_length;
        invalidField ??= _privateIdFocus;
      }

      if (secret.isEmpty) {
        _secretError = l10n.l_field_required;
        invalidField ??= _secretFocus;
      } else if (!secretFormatValid) {
        _secretError = l10n.l_invalid_format_allowed_chars(
          Format.hex.allowedCharacters,
        );
        invalidField ??= _secretFocus;
      } else if (!secretLengthValid) {
        _secretError = l10n.s_invalid_length;
        invalidField ??= _secretFocus;
      }

      if (invalidField != null) {
        invalidField.requestFocus();
        setState(() {});
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

      // The CSV starts with the serial, so a key that does not report one cannot be
      // exported. Guard here rather than on the export chip: over NFC the serial is
      // unknown until the tap, which is after the dialog is built.
      final serial = info?.serial;
      String? exportedFileName;
      if (configurationSucceeded &&
          (_action == OutputActions.createFile || outputFile != null) &&
          serial != null) {
        final csv = await otpNotifier.formatYubiOtpCsv(
          serial,
          publicId,
          privateId,
          secret,
        );
        if (outputFile != null) {
          await appendYubiOtpCsv(outputFile, csv);
          exportedFileName = outputFile.uri.pathSegments.last;
        } else {
          final fileName = 'yubico-otp-$publicId.csv';
          final uri = await FilePicker.saveFile(
            dialogTitle: l10n.l_export_configuration_file,
            fileName: fileName,
            bytes: Uint8List.fromList(
              utf8.encode('$csv${Platform.lineTerminator}'),
            ),
            windowsOptions: const WindowsOptions(lockParentWindow: true),
            linuxOptions: const LinuxOptions(lockParentWindow: true),
          );
          if (uri != null) {
            exportedFileName = uri.scheme == 'file'
                ? uri.pathSegments.last
                : fileName;
            if (uri.scheme == 'file') {
              ref
                  .read(yubiOtpOutputProvider.notifier)
                  .setOutput(File.fromUri(uri));
            }
          }
        }
      }
      await ref.read(withContextProvider)((context) async {
        Navigator.of(context).pop();
        if (configurationSucceeded) {
          showMessage(
            context,
            exportedFileName != null
                ? l10n.l_slot_credential_configured_and_exported(
                    l10n.s_capability_otp,
                    exportedFileName,
                  )
                : l10n.l_slot_credential_configured(l10n.s_capability_otp),
          );
        }
      });
    }

    return ResponsiveDialog(
      title: Text(l10n.s_capability_otp),
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
                      key: keys.publicIdField,
                      autofocus: true,
                      controller: _publicIdController,
                      autofillHints: isAndroid
                          ? []
                          : const [AutofillHints.password],
                      focusNode: _publicIdFocus,
                      maxLength: publicIdLength,
                      buildCounter: buildByteCounterFor(
                        _publicIdController.text,
                      ),
                      inputFormatters: [limitBytesLength(publicIdLength)],
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_public_id,
                        isRequired: true,
                        errorText: _publicIdError,
                        icon: const Icon(Symbols.public),
                        suffixIcon: IconButton(
                          key: keys.useSerial,
                          tooltip: l10n.s_use_serial,
                          icon: const Icon(Symbols.auto_awesome),
                          onPressed: (info?.serial != null)
                              ? () async {
                                  final publicId = await ref
                                      .read(
                                        otpStateProvider(widget.devicePath)
                                            .notifier,
                                      )
                                      .modhexEncodeSerial(info!.serial!);
                                  setState(() {
                                    _publicIdController.text = publicId;
                                    _publicIdError = null;
                                  });
                                }
                              : null,
                        ),
                      ),
                      textInputAction: .next,
                      onChanged: (value) {
                        setState(() {
                          _publicIdError = null;
                        });
                      },
                      onSubmitted: (_) {
                        if (publicId.isNotEmpty) {
                          _privateIdFocus.requestFocus();
                        } else {
                          _publicIdFocus.requestFocus();
                        }
                      },
                    ).init(),
                    AppTextField(
                      key: keys.privateIdField,
                      controller: _privateIdController,
                      autofillHints: isAndroid
                          ? []
                          : const [AutofillHints.password],
                      maxLength: privateIdLength,
                      buildCounter: buildByteCounterFor(
                        _privateIdController.text,
                      ),
                      inputFormatters: [limitBytesLength(privateIdLength)],
                      focusNode: _privateIdFocus,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_private_id,
                        isRequired: true,
                        errorText: _privateIdError,
                        icon: const Icon(Symbols.key),
                        suffixIcon: IconButton(
                          key: keys.generatePrivateId,
                          tooltip: l10n.s_generate_random,
                          icon: const Icon(Symbols.refresh),
                          onPressed: () {
                            final random = Random.secure();
                            final key = List.generate(
                              6,
                              (_) => random
                                  .nextInt(256)
                                  .toRadixString(16)
                                  .padLeft(2, '0'),
                            ).join();
                            setState(() {
                              _privateIdController.text = key;
                              _privateIdError = null;
                            });
                          },
                        ),
                      ),
                      textInputAction: .next,
                      onChanged: (value) {
                        setState(() {
                          _privateIdError = null;
                        });
                      },
                      onSubmitted: (_) {
                        if (privateId.isNotEmpty) {
                          _secretFocus.requestFocus();
                        } else {
                          _privateIdFocus.requestFocus();
                        }
                      },
                    ).init(),
                    AppTextField(
                      key: keys.secretField,
                      controller: _secretController,
                      autofillHints: isAndroid
                          ? []
                          : const [AutofillHints.password],
                      maxLength: secretLength,
                      buildCounter: buildByteCounterFor(_secretController.text),
                      inputFormatters: [limitBytesLength(secretLength)],
                      focusNode: _secretFocus,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_secret_key,
                        isRequired: true,
                        errorText: _secretError,
                        icon: const Icon(Symbols.key),
                        suffixIcon: IconButton(
                          key: keys.generateSecretKey,
                          tooltip: l10n.s_generate_random,
                          icon: const Icon(Symbols.refresh),
                          onPressed: () {
                            final random = Random.secure();
                            final key = List.generate(
                              16,
                              (_) => random
                                  .nextInt(256)
                                  .toRadixString(16)
                                  .padLeft(2, '0'),
                            ).join();
                            setState(() {
                              _secretController.text = key;
                              _secretError = null;
                            });
                          },
                        ),
                      ),
                      textInputAction: .done,
                      onChanged: (value) {
                        setState(() {
                          _secretError = null;
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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
                              ChoiceFilterChip<OutputActions>(
                                tooltip:
                                    outputFile?.path ??
                                    (_action == OutputActions.createFile
                                        ? l10n.l_create_export_file
                                        : l10n.s_no_export),
                                selected:
                                    outputFile != null ||
                                    _action == OutputActions.createFile,
                                avatar:
                                    outputFile != null ||
                                        _action == OutputActions.createFile
                                    ? Icon(
                                        Symbols.check,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      )
                                    : null,
                                value: _action,
                                // Android's picker returns a cached copy of an existing file.
                                // Only offer creating a document that SAF can write directly.
                                items: isAndroid
                                    ? [
                                        OutputActions.createFile,
                                        OutputActions.noOutput,
                                      ]
                                    : OutputActions.values,
                                itemBuilder: (value) =>
                                    Text(value.getDisplayName(l10n)),
                                labelBuilder: (_) {
                                  String? fileName =
                                      outputFile?.uri.pathSegments.last;
                                  return Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 140,
                                    ),
                                    child: Text(
                                      fileName != null
                                          ? '${l10n.s_export} $fileName'
                                          : _action.getDisplayName(l10n),
                                      overflow: .ellipsis,
                                    ),
                                  );
                                },
                                onChanged: (value) async {
                                  if (value == OutputActions.noOutput) {
                                    ref
                                        .read(yubiOtpOutputProvider.notifier)
                                        .setOutput(null);
                                    setState(() {
                                      _action = value;
                                    });
                                  } else if (value ==
                                      OutputActions.selectFile) {
                                    final file = await pickExistingYubiOtpCsv(
                                      l10n.l_select_file,
                                    );
                                    if (file == null) {
                                      return;
                                    }
                                    ref
                                        .read(yubiOtpOutputProvider.notifier)
                                        .setOutput(file);
                                    setState(() {
                                      _action = value;
                                    });
                                  } else if (value ==
                                      OutputActions.createFile) {
                                    ref
                                        .read(yubiOtpOutputProvider.notifier)
                                        .setOutput(null);
                                    setState(() {
                                      _action = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _uploadText,
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
