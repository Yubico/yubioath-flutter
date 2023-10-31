/*
 * Copyright (C) 2022-2023 Yubico.
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

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../android/oath/state.dart';
import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../exception/apdu_exception.dart';
import '../../exception/cancellation_exception.dart';
import '../../core/state.dart';
import '../../desktop/models.dart';
import '../../management/models.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/file_drop_target.dart';
import '../../widgets/focus_utils.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'unlock_form.dart';
import 'utils.dart';

final _log = Logger('oath.view.add_account_page');

final _secretFormatterPattern =
    RegExp('[abcdefghijklmnopqrstuvwxyz234567 ]', caseSensitive: false);

class OathAddAccountPage extends ConsumerStatefulWidget {
  final DevicePath? devicePath;
  final OathState? state;
  final List<OathCredential>? credentials;
  final CredentialData? credentialData;
  const OathAddAccountPage(
    this.devicePath,
    this.state, {
    super.key,
    required this.credentials,
    this.credentialData,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OathAddAccountPageState();
}

class _OathAddAccountPageState extends ConsumerState<OathAddAccountPage> {
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();
  final _periodController = TextEditingController(text: '$defaultPeriod');
  UserInteractionController? _promptController;
  Uri? _otpauthUri;
  bool _touch = false;
  OathType _oathType = defaultOathType;
  HashAlgorithm _hashAlgorithm = defaultHashAlgorithm;
  int _digits = defaultDigits;
  int _counter = defaultCounter;
  bool _validateSecretLength = false;
  bool _dataLoaded = false;
  bool _isObscure = true;
  List<int> _periodValues = [20, 30, 45, 60];
  List<int> _digitsValues = [6, 8];
  List<OathCredential>? _credentials;

  @override
  void dispose() {
    _issuerController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final cred = widget.credentialData;
    if (cred != null) {
      _loadCredentialData(cred);
    }
  }

  _loadCredentialData(CredentialData data) {
    setState(() {
      _issuerController.text = data.issuer?.trim() ?? '';
      _accountController.text = data.name.trim();
      _secretController.text = data.secret;
      _oathType = data.oathType;
      _hashAlgorithm = data.hashAlgorithm;
      _periodValues = [data.period];
      _periodController.text = '${data.period}';
      _digitsValues = [data.digits];
      _digits = data.digits;
      _counter = data.counter;
      _isObscure = true;
      _dataLoaded = true;
    });
  }

  Future<void> _doAddCredential(
      {DevicePath? devicePath, required Uri credUri}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      FocusUtils.unfocus(context);

      if (devicePath == null) {
        assert(isAndroid, 'devicePath is only optional for Android');
        await ref
            .read(addCredentialToAnyProvider)
            .call(credUri, requireTouch: _touch);
      } else {
        await ref
            .read(credentialListProvider(devicePath).notifier)
            .addAccount(credUri, requireTouch: _touch);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, l10n.s_account_added);
    } on CancellationException catch (_) {
      // ignored
    } catch (e) {
      _log.error('Failed to add account', e);
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else if (e is ApduException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      showMessage(
        context,
        l10n.l_account_add_failed(errorMessage),
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deviceNode = ref.watch(currentDeviceProvider);
    if (widget.devicePath != null && widget.devicePath != deviceNode?.path) {
      // If the dialog was started for a specific device and it was
      // changed/removed, close the dialog.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    final OathState? oathState;
    if (widget.state == null && deviceNode != null) {
      oathState = ref
          .watch(oathStateProvider(deviceNode.path))
          .maybeWhen(data: (data) => data, orElse: () => null);
      _credentials = ref
          .watch(credentialListProvider(deviceNode.path))
          ?.map((e) => e.credential)
          .toList();
    } else {
      oathState = widget.state;
      _credentials = widget.credentials;
    }

    final otpauthUri = _otpauthUri;
    _promptController?.updateContent(title: l10n.l_insert_yk);
    if (otpauthUri != null && deviceNode != null) {
      final deviceData = ref.watch(currentDeviceDataProvider);
      deviceData.when(data: (data) {
        if (Capability.oath.value ^
                (data.info.config.enabledCapabilities[deviceNode.transport] ??
                    0) !=
            0) {
          if (oathState == null) {
            _promptController?.updateContent(title: l10n.s_please_wait);
          } else if (oathState.locked) {
            _promptController?.close();
          } else {
            _otpauthUri = null;
            _promptController?.close();
            Timer.run(() => _doAddCredential(
                  devicePath: deviceNode.path,
                  credUri: otpauthUri,
                ));
          }
        } else {
          _promptController?.updateContent(title: l10n.s_unsupported_yk);
        }
      }, error: (error, _) {
        _promptController?.updateContent(title: l10n.s_unsupported_yk);
      }, loading: () {
        _promptController?.updateContent(title: l10n.s_please_wait);
      });
    }

    final period = int.tryParse(_periodController.text) ?? -1;
    final issuerText = _issuerController.text.trim();
    final nameText = _accountController.text.trim();
    final (issuerRemaining, nameRemaining) = getRemainingKeySpace(
      oathType: _oathType,
      period: period,
      issuer: issuerText,
      name: nameText,
    );

    final issuerMaxLength = max(issuerRemaining, 1);
    final nameMaxLength = max(nameRemaining, 1);

    final secret = _secretController.text.replaceAll(' ', '');
    final secretLengthValid = secret.length * 5 % 8 < 5;

    // is this credentials name/issuer pair different from all other?
    final isUnique = _credentials
            ?.where((element) =>
                element.name == nameText &&
                (element.issuer ?? '') == issuerText)
            .isEmpty ??
        true;
    final issuerNoColon = !_issuerController.text.contains(':');

    final isLocked = oathState?.locked ?? false;

    final isValid = !isLocked &&
        nameText.isNotEmpty &&
        secret.isNotEmpty &&
        isUnique &&
        issuerNoColon &&
        issuerRemaining >= -1 &&
        nameRemaining >= 0 &&
        period > 0;

    final hashAlgorithms = HashAlgorithm.values
        .where((alg) =>
            alg != HashAlgorithm.sha512 ||
            (oathState?.version.isAtLeast(4, 3, 1) ?? true))
        .toList();
    if (!hashAlgorithms.contains(_hashAlgorithm)) {
      _hashAlgorithm = HashAlgorithm.sha1;
    }

    if (!(oathState?.version.isAtLeast(4, 2) ?? true)) {
      // Touch not supported
      _touch = false;
    }

    void submit() async {
      if (secretLengthValid) {
        final cred = CredentialData(
          issuer: issuerText.isEmpty ? null : issuerText,
          name: nameText,
          secret: secret,
          oathType: _oathType,
          hashAlgorithm: _hashAlgorithm,
          digits: _digits,
          period: period,
          counter: _counter,
        );

        final devicePath = deviceNode?.path;
        if (devicePath != null) {
          await _doAddCredential(devicePath: devicePath, credUri: cred.toUri());
        } else if (isAndroid) {
          // Send the credential to Android to be added to the next YubiKey
          await _doAddCredential(devicePath: null, credUri: cred.toUri());
        } else {
          // Desktop. No YubiKey, prompt and store the cred.
          _otpauthUri = cred.toUri();
          _promptController = promptUserInteraction(
            context,
            title: l10n.l_insert_yk,
            description: l10n.s_add_account,
            icon: const Icon(Icons.usb),
            onCancel: () {
              _otpauthUri = null;
            },
          );
        }
      } else {
        setState(() {
          _validateSecretLength = true;
        });
      }
    }

    return ResponsiveDialog(
      title: Text(l10n.s_add_account),
      actions: [
        TextButton(
          onPressed: isValid ? submit : null,
          child: Text(l10n.s_save, key: keys.saveButton),
        ),
      ],
      child: FileDropTarget(
        onFileDropped: (fileData) async {
          final qrScanner = ref.read(qrScannerProvider);
          if (qrScanner != null) {
            final b64Image = base64Encode(fileData);
            final otpauth = await qrScanner.scanQr(b64Image);
            if (otpauth == null) {
              if (!mounted) return;
              showMessage(context, l10n.l_qr_not_found);
            } else {
              try {
                final data = CredentialData.fromOtpauth(Uri.parse(otpauth));
                _loadCredentialData(data);
              } catch (e) {
                final String errorMessage;
                // TODO: Make this cleaner than importing desktop specific RpcError.
                if (e is RpcError) {
                  errorMessage = e.message;
                } else {
                  errorMessage = e.toString();
                }
                if (!mounted) return;
                showMessage(context, errorMessage);
              }
            }
          }
        },
        child: isLocked
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child:
                    UnlockForm(deviceNode!.path, keystore: oathState!.keystore),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: keys.issuerField,
                      controller: _issuerController,
                      autofocus: widget.credentialData == null,
                      enabled: issuerRemaining > 0,
                      maxLength: issuerMaxLength,
                      inputFormatters: [
                        limitBytesLength(issuerRemaining),
                      ],
                      buildCounter: buildByteCounterFor(issuerText),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_issuer_optional,
                        helperText:
                            '', // Prevents dialog resizing when disabled
                        prefixIcon: const Icon(Icons.business_outlined),
                        errorText: (byteLength(issuerText) > issuerMaxLength)
                            ? '' // needs empty string to render as error
                            : issuerNoColon
                                ? null
                                : l10n.l_invalid_character_issuer,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        setState(() {
                          // Update maxlengths
                        });
                      },
                      onSubmitted: (_) {
                        if (isValid) submit();
                      },
                    ),
                    TextField(
                      key: keys.nameField,
                      controller: _accountController,
                      maxLength: nameMaxLength,
                      buildCounter: buildByteCounterFor(nameText),
                      inputFormatters: [limitBytesLength(nameRemaining)],
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                        labelText: l10n.s_account_name,
                        helperText:
                            '', // Prevents dialog resizing when disabled
                        errorText: (byteLength(nameText) > nameMaxLength)
                            ? '' // needs empty string to render as error
                            : isUnique
                                ? null
                                : l10n.l_name_already_exists,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        setState(() {
                          // Update maxlengths
                        });
                      },
                      onSubmitted: (_) {
                        if (isValid) submit();
                      },
                    ),
                    TextField(
                      key: keys.secretField,
                      controller: _secretController,
                      obscureText: _isObscure,
                      // avoid using autofill hints on Android otherwise Autofill service
                      // would hint to use saved passwords for this field
                      autofillHints:
                          isAndroid ? [] : const [AutofillHints.password],
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            _secretFormatterPattern)
                      ],
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: IconTheme.of(context).color,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.key_outlined),
                          labelText: l10n.s_secret_key,
                          errorText: _validateSecretLength && !secretLengthValid
                              ? l10n.s_invalid_length
                              : null),
                      readOnly: _dataLoaded,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        setState(() {
                          _validateSecretLength = false;
                        });
                      },
                      onSubmitted: (_) {
                        if (isValid) submit();
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4.0,
                      runSpacing: 8.0,
                      children: [
                        if (oathState?.version.isAtLeast(4, 2) ?? true)
                          FilterChip(
                            key: keys.requireTouchFilterChip,
                            label: Text(l10n.s_require_touch),
                            selected: _touch,
                            onSelected: (value) {
                              setState(() {
                                _touch = value;
                              });
                            },
                          ),
                        ChoiceFilterChip<OathType>(
                          key: keys.oathTypeFilterChip,
                          items: OathType.values,
                          value: _oathType,
                          selected: _oathType != defaultOathType,
                          itemBuilder: (value) => Text(
                              value.getDisplayName(l10n),
                              key: value == OathType.totp
                                  ? keys.oathTypeTotpFilterValue
                                  : keys.oathTypeHotpFilterValue),
                          onChanged: !_dataLoaded
                              ? (value) {
                                  setState(() {
                                    _oathType = value;
                                  });
                                }
                              : null,
                        ),
                        ChoiceFilterChip<HashAlgorithm>(
                          key: keys.hashAlgorithmFilterChip,
                          items: hashAlgorithms,
                          value: _hashAlgorithm,
                          selected: _hashAlgorithm != defaultHashAlgorithm,
                          itemBuilder: (value) => Text(value.displayName,
                              key: value == HashAlgorithm.sha1
                                  ? keys.hashAlgorithmSha1FilterValue
                                  : value == HashAlgorithm.sha256
                                      ? keys.hashAlgorithmSha256FilterValue
                                      : keys.hashAlgorithmSha512FilterValue),
                          onChanged: !_dataLoaded
                              ? (value) {
                                  setState(() {
                                    _hashAlgorithm = value;
                                  });
                                }
                              : null,
                        ),
                        if (_oathType == OathType.totp)
                          ChoiceFilterChip<int>(
                            items: _periodValues,
                            value: int.tryParse(_periodController.text) ??
                                defaultPeriod,
                            selected: int.tryParse(_periodController.text) !=
                                defaultPeriod,
                            itemBuilder: ((value) =>
                                Text(l10n.s_num_sec(value))),
                            onChanged: !_dataLoaded
                                ? (period) {
                                    setState(() {
                                      _periodController.text = '$period';
                                    });
                                  }
                                : null,
                          ),
                        ChoiceFilterChip<int>(
                          items: _digitsValues,
                          value: _digits,
                          selected: _digits != defaultDigits,
                          itemBuilder: (value) =>
                              Text(l10n.s_num_digits(value)),
                          onChanged: !_dataLoaded
                              ? (digits) {
                                  setState(() {
                                    _digits = digits;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ]
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: e,
                          ))
                      .toList(),
                ),
              ),
      ),
    );
  }
}
