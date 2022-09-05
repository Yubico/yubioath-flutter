import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../cancellation_exception.dart';
import '../../desktop/models.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/file_drop_target.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../models.dart';
import '../state.dart';
import 'utils.dart';

final _log = Logger('oath.view.add_account_page');

final _secretFormatterPattern =
    RegExp('[abcdefghijklmnopqrstuvwxyz234567 ]', caseSensitive: false);

enum _QrScanState { none, scanning, success, failed }

class OathAddAccountPage extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OathState state;
  final List<OathCredential>? credentials;
  final bool openQrScanner;
  const OathAddAccountPage(
    this.devicePath,
    this.state, {
    super.key,
    required this.openQrScanner,
    required this.credentials,
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
  bool _touch = false;
  OathType _oathType = defaultOathType;
  HashAlgorithm _hashAlgorithm = defaultHashAlgorithm;
  int _digits = defaultDigits;
  bool _validateSecretLength = false;
  _QrScanState _qrState = _QrScanState.none;
  bool _isObscure = true;
  List<int> _periodValues = [20, 30, 45, 60];
  List<int> _digitsValues = [6, 8];

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
      showMessage(
        context,
        '${AppLocalizations.of(context)!.oath_failed_reading_qr}: $errorMessage',
        duration: const Duration(seconds: 4),
      );
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

  @override
  void initState() {
    super.initState();

    final qrScanner = ref.read(qrScannerProvider);
    if (qrScanner != null && widget.openQrScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scanQrCode(qrScanner);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final isUnique = widget.credentials
            ?.where((element) =>
                element.name == _accountController.text.trim() &&
                (element.issuer ?? '') == _issuerController.text.trim())
            .isEmpty ??
        false;

    final isValid = _accountController.text.trim().isNotEmpty &&
        secret.isNotEmpty &&
        isUnique &&
        issuerRemaining >= -1 &&
        nameRemaining >= 0 &&
        period > 0;

    final qrScanner = ref.watch(qrScannerProvider);

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

        try {
          await ref
              .read(credentialListProvider(widget.devicePath).notifier)
              .addAccount(cred.toUri(), requireTouch: _touch);
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
              key: const Key('save_btn')),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('issuer'),
              controller: _issuerController,
              autofocus: !widget.openQrScanner,
              enabled: issuerRemaining > 0,
              maxLength: max(issuerRemaining, 1),
              inputFormatters: [limitBytesLength(issuerRemaining)],
              buildCounter: buildByteCounterFor(_issuerController.text.trim()),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: AppLocalizations.of(context)!.oath_issuer_optional,
                helperText: '', // Prevents dialog resizing when enabled = false
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
              key: const Key('name'),
              controller: _accountController,
              maxLength: max(nameRemaining, 1),
              buildCounter: buildByteCounterFor(_accountController.text.trim()),
              inputFormatters: [limitBytesLength(nameRemaining)],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
                labelText: AppLocalizations.of(context)!.oath_account_name,
                helperText: '', // Prevents dialog resizing when enabled = false
                errorText: isUnique
                    ? null
                    : 'This name already exists for the Issuer', // TODO
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
              key: const Key('secret'),
              controller: _secretController,
              obscureText: _isObscure,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(_secretFormatterPattern)
              ],
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
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
                  labelText: AppLocalizations.of(context)!.oath_secret_key,
                  errorText: _validateSecretLength && !secretLengthValid
                      ? AppLocalizations.of(context)!.oath_invalid_length
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
            if (qrScanner != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ActionChip(
                    avatar: _qrState != _QrScanState.scanning
                        ? (_qrState == _QrScanState.success
                            ? const Icon(Icons.qr_code)
                            : const Icon(Icons.qr_code_scanner_outlined))
                        : const CircularProgressIndicator(strokeWidth: 2.0),
                    label: _qrState == _QrScanState.success
                        ? Text(AppLocalizations.of(context)!.oath_scanned_qr)
                        : Text(AppLocalizations.of(context)!.oath_scan_qr),
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
                if (widget.state.version.isAtLeast(4, 2))
                  FilterChip(
                    label:
                        Text(AppLocalizations.of(context)!.oath_require_touch),
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
                  items: HashAlgorithm.values,
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
                    value:
                        int.tryParse(_periodController.text) ?? defaultPeriod,
                    selected:
                        int.tryParse(_periodController.text) != defaultPeriod,
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
    );
  }
}
