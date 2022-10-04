/*
 * Copyright (C) 2022 Yubico.
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
import 'dart:io';
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
import '../../cancellation_exception.dart';
import '../../core/state.dart';
import '../../desktop/models.dart';
import '../../management/models.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/file_drop_target.dart';
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

enum _QrScanState { none, scanning, success, failed }

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
  bool _validateSecretLength = false;
  _QrScanState _qrState = _QrScanState.none;
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

  _scanQrCode(QrScanner qrScanner) async {
    try {
      setState(() {
        // If we have a previous scan result stored, clear it
        if (_qrState == _QrScanState.success) {
          _issuerController.text = '';
          _accountController.text = '';
          _secretController.text = '';
          _oathType = defaultOathType;
          _hashAlgorithm = defaultHashAlgorithm;
          _periodController.text = '$defaultPeriod';
          _digits = defaultDigits;
        }
        _qrState = _QrScanState.scanning;
      });
      final otpauth = await qrScanner.scanQr();
      if (otpauth == null) {
        if (!mounted) return;
        showMessage(context, AppLocalizations.of(context)!.oath_no_qr_code);
        setState(() {
          _qrState = _QrScanState.failed;
        });
      } else {
        final data = CredentialData.fromUri(Uri.parse(otpauth));
        _loadCredentialData(data);
      }
    } catch (e) {
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }

      if (e is! CancellationException) {
        showMessage(
          context,
          '${AppLocalizations.of(context)!.oath_failed_reading_qr}: $errorMessage',
          duration: const Duration(seconds: 4),
        );
      }
      setState(() {
        _qrState = _QrScanState.failed;
      });
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
      _isObscure = true;
      _qrState = _QrScanState.success;
    });
  }

  Future<void> _doAddCredential(
      {DevicePath? devicePath, required Uri credUri}) async {
    try {
      if (devicePath == null) {
        assert(Platform.isAndroid, 'devicePath is only optional for Android');
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
      showMessage(
          context, AppLocalizations.of(context)!.oath_success_add_account);
    } on CancellationException catch (_) {
      // ignored
    } catch (e) {
      _log.error('Failed to add account', e);
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      showMessage(
        context,
        '${AppLocalizations.of(context)!.oath_fail_add_account}: $errorMessage',
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
    _promptController?.updateContent(title: 'Insert YubiKey');
    if (otpauthUri != null && deviceNode != null) {
      final deviceData = ref.watch(currentDeviceDataProvider);
      deviceData.when(data: (data) {
        if (Capability.oath.value ^
                (data.info.config.enabledCapabilities[deviceNode.transport] ??
                    0) !=
            0) {
          if (oathState == null) {
            _promptController?.updateContent(title: 'Please wait...');
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
          _promptController?.updateContent(title: 'Unsupported YubiKey');
        }
      }, error: (error, _) {
        _promptController?.updateContent(title: 'Unsupported YubiKey');
      }, loading: () {
        _promptController?.updateContent(title: 'Please wait...');
      });
    }

    final period = int.tryParse(_periodController.text) ?? -1;
    final remaining = getRemainingKeySpace(
      oathType: _oathType,
      period: period,
      issuer: _issuerController.text.trim(),
      name: _accountController.text.trim(),
    );
    final issuerRemaining = remaining.first;
    final nameRemaining = remaining.second;

    final secret = _secretController.text.replaceAll(' ', '');
    final secretLengthValid = secret.length * 5 % 8 < 5;

    // is this credentials name/issuer pair different from all other?
    final isUnique = _credentials
            ?.where((element) =>
                element.name == _accountController.text.trim() &&
                (element.issuer ?? '') == _issuerController.text.trim())
            .isEmpty ??
        true;

    final isLocked = oathState?.locked ?? false;

    final isValid = !isLocked &&
        _accountController.text.trim().isNotEmpty &&
        secret.isNotEmpty &&
        isUnique &&
        issuerRemaining >= -1 &&
        nameRemaining >= 0 &&
        period > 0;

    final qrScanner = ref.watch(qrScannerProvider);

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
        final issuer = _issuerController.text.trim();

        final cred = CredentialData(
          issuer: issuer.isEmpty ? null : issuer,
          name: _accountController.text.trim(),
          secret: secret,
          oathType: _oathType,
          hashAlgorithm: _hashAlgorithm,
          digits: _digits,
          period: period,
        );

        final devicePath = deviceNode?.path;
        if (devicePath != null) {
          await _doAddCredential(devicePath: devicePath, credUri: cred.toUri());
        } else if (Platform.isAndroid) {
          // Send the credential to Android to be added to the next YubiKey
          await _doAddCredential(devicePath: null, credUri: cred.toUri());
        } else {
          // Desktop. No YubiKey, prompt and store the cred.
          _otpauthUri = cred.toUri();
          _promptController = promptUserInteraction(
            context,
            title: 'Insert YubiKey',
            description: 'Add account',
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
      title: Text(AppLocalizations.of(context)!.oath_add_account),
      actions: [
        TextButton(
          onPressed: isValid ? submit : null,
          child: Text(AppLocalizations.of(context)!.oath_save,
              key: keys.saveButton),
        ),
      ],
      child: FileDropTarget(
        onFileDropped: (fileData) async {
          if (qrScanner != null) {
            final b64Image = base64Encode(fileData);
            final otpauth = await qrScanner.scanQr(b64Image);
            if (otpauth == null) {
              if (!mounted) return;
              showMessage(
                  context, AppLocalizations.of(context)!.oath_no_qr_code);
            } else {
              final data = CredentialData.fromUri(Uri.parse(otpauth));
              _loadCredentialData(data);
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
                      maxLength: max(issuerRemaining, 1),
                      inputFormatters: [limitBytesLength(issuerRemaining)],
                      buildCounter:
                          buildByteCounterFor(_issuerController.text.trim()),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText:
                            AppLocalizations.of(context)!.oath_issuer_optional,
                        helperText:
                            '', // Prevents dialog resizing when disabled
                        prefixIcon: const Icon(Icons.business_outlined),
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
                      maxLength: max(nameRemaining, 1),
                      buildCounter:
                          buildByteCounterFor(_accountController.text.trim()),
                      inputFormatters: [limitBytesLength(nameRemaining)],
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                        labelText:
                            AppLocalizations.of(context)!.oath_account_name,
                        helperText:
                            '', // Prevents dialog resizing when disabled
                        errorText: isUnique
                            ? null
                            : AppLocalizations.of(context)!.oath_duplicate_name,
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
                          labelText:
                              AppLocalizations.of(context)!.oath_secret_key,
                          errorText: _validateSecretLength && !secretLengthValid
                              ? AppLocalizations.of(context)!
                                  .oath_invalid_length
                              : null),
                      readOnly: _qrState == _QrScanState.success,
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
                    if (isDesktop && qrScanner != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ActionChip(
                            avatar: _qrState != _QrScanState.scanning
                                ? (_qrState == _QrScanState.success
                                    ? const Icon(Icons.qr_code)
                                    : const Icon(
                                        Icons.qr_code_scanner_outlined))
                                : const CircularProgressIndicator(
                                    strokeWidth: 2.0),
                            label: _qrState == _QrScanState.success
                                ? Text(AppLocalizations.of(context)!
                                    .oath_scanned_qr)
                                : Text(
                                    AppLocalizations.of(context)!.oath_scan_qr),
                            onPressed: () {
                              _scanQrCode(qrScanner);
                            }),
                      ),
                    const Divider(),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4.0,
                      runSpacing: 8.0,
                      children: [
                        if (oathState?.version.isAtLeast(4, 2) ?? true)
                          FilterChip(
                            label: Text(AppLocalizations.of(context)!
                                .oath_require_touch),
                            selected: _touch,
                            onSelected: (value) {
                              setState(() {
                                _touch = value;
                              });
                            },
                          ),
                        ChoiceFilterChip<OathType>(
                          items: OathType.values,
                          value: _oathType,
                          selected: _oathType != defaultOathType,
                          itemBuilder: (value) => Text(value.displayName),
                          onChanged: _qrState != _QrScanState.success
                              ? (value) {
                                  setState(() {
                                    _oathType = value;
                                  });
                                }
                              : null,
                        ),
                        ChoiceFilterChip<HashAlgorithm>(
                          items: hashAlgorithms,
                          value: _hashAlgorithm,
                          selected: _hashAlgorithm != defaultHashAlgorithm,
                          itemBuilder: (value) => Text(value.displayName),
                          onChanged: _qrState != _QrScanState.success
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
                            itemBuilder: ((value) => Text(
                                '$value ${AppLocalizations.of(context)!.oath_sec}')),
                            onChanged: _qrState != _QrScanState.success
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
                          itemBuilder: (value) => Text(
                              '$value ${AppLocalizations.of(context)!.oath_digits}'),
                          onChanged: _qrState != _QrScanState.success
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
