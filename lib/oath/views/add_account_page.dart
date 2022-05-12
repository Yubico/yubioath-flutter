import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/file_drop_target.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import 'utils.dart';

final _log = Logger('oath.view.add_account_page');

final _secretFormatterPattern =
    RegExp('[abcdefghijklmnopqrstuvwxyz234567 ]', caseSensitive: false);

enum _QrScanState { none, scanning, success, failed }

class OathAddAccountPage extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final bool openQrScanner;
  const OathAddAccountPage(this.devicePath,
      {super.key, required this.openQrScanner});

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
        _qrState = _QrScanState.scanning;
      });
      final otpauth = await qrScanner.scanQr();
      final data = CredentialData.fromUri(Uri.parse(otpauth));
      _loadCredentialData(data);
    } catch (e) {
      setState(() {
        _qrState = _QrScanState.failed;
      });
    }
  }

  _loadCredentialData(CredentialData data) {
    setState(() {
      _issuerController.text = data.issuer ?? '';
      _accountController.text = data.name;
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

  List<Widget> _buildQrStatus() {
    switch (_qrState) {
      case _QrScanState.success:
        return const [
          Icon(Icons.check_circle_outline_outlined),
          Text('QR code scanned!'),
        ];
      case _QrScanState.scanning:
        return const [
          SizedBox.square(dimension: 16.0, child: CircularProgressIndicator()),
        ];
      case _QrScanState.failed:
        return const [
          Icon(Icons.warning_amber_rounded),
          Text('No QR code found'),
        ];
      default:
        return [];
    }
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
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      //TODO: This can probably be checked better to make sure it's the main page.
      Navigator.of(context).popUntil((route) => route.isFirst);
    });

    final period = int.tryParse(_periodController.text) ?? -1;
    final remaining = getRemainingKeySpace(
      oathType: _oathType,
      period: period,
      issuer: _issuerController.text,
      name: _accountController.text,
    );
    final issuerRemaining = remaining.first;
    final nameRemaining = remaining.second;

    final secret = _secretController.text.replaceAll(' ', '');
    final secretLengthValid = secret.length * 5 % 8 < 5;
    final isValid = _accountController.text.isNotEmpty &&
        secret.isNotEmpty &&
        issuerRemaining >= -1 &&
        nameRemaining >= 0 &&
        period > 0;

    final qrScanner = ref.watch(qrScannerProvider);

    return ResponsiveDialog(
      title: const Text('Add account'),
      actions: [
        TextButton(
          onPressed: isValid
              ? () async {
                  if (secretLengthValid) {
                    final issuer = _issuerController.text;

                    final cred = CredentialData(
                      issuer: issuer.isEmpty ? null : issuer,
                      name: _accountController.text,
                      secret: secret,
                      oathType: _oathType,
                      hashAlgorithm: _hashAlgorithm,
                      digits: _digits,
                      period: period,
                    );

                    try {
                      await ref
                          .read(credentialListProvider(widget.devicePath)
                              .notifier)
                          .addAccount(cred.toUri(), requireTouch: _touch);
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      showMessage(context, 'Account added');
                    } catch (e) {
                      _log.error('Failed to add account', e);
                      showMessage(context, 'Failed adding account');
                    }
                  } else {
                    setState(() {
                      _validateSecretLength = true;
                    });
                  }
                }
              : null,
          child: const Text('Save', key: Key('save_btn')),
        ),
      ],
      child: FileDropTarget(
        onFileDropped: (fileData) async {
          if (qrScanner != null) {
            final b64Image = base64Encode(fileData);
            final otpauth = await qrScanner.scanQr(b64Image);
            final data = CredentialData.fromUri(Uri.parse(otpauth));
            _loadCredentialData(data);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account details',
              style: Theme.of(context).textTheme.headline6,
            ),
            TextField(
              key: const Key('issuer'),
              controller: _issuerController,
              autofocus: true,
              enabled: issuerRemaining > 0,
              maxLength: max(issuerRemaining, 1),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Issuer (optional)',
                helperText: '', // Prevents dialog resizing when enabled = false
              ),
              onChanged: (value) {
                setState(() {
                  // Update maxlengths
                });
              },
            ),
            TextField(
              key: const Key('name'),
              controller: _accountController,
              maxLength: max(nameRemaining, 1),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Account name',
                helperText: '', // Prevents dialog resizing when enabled = false
              ),
              onChanged: (value) {
                setState(() {
                  // Update maxlengths
                });
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
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  labelText: 'Secret key',
                  errorText: _validateSecretLength && !secretLengthValid
                      ? 'Invalid length'
                      : null),
              readOnly: _qrState == _QrScanState.success,
              onChanged: (value) {
                setState(() {
                  _validateSecretLength = false;
                });
              },
            ),
            if (qrScanner != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        _scanQrCode(qrScanner);
                      },
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Scan QR code'),
                    ),
                    const SizedBox(width: 8.0),
                    ..._buildQrStatus(),
                  ],
                ),
              ),
            const Divider(),
            Text(
              'Options',
              style: Theme.of(context).textTheme.headline6,
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4.0,
              runSpacing: 8.0,
              children: [
                FilterChip(
                  label: const Text('Require touch'),
                  selected: _touch,
                  onSelected: (value) {
                    setState(() {
                      _touch = value;
                    });
                  },
                ),
                Chip(
                  label: DropdownButtonHideUnderline(
                    child: DropdownButton<OathType>(
                      value: _oathType,
                      isDense: true,
                      underline: null,
                      items: OathType.values
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: _qrState != _QrScanState.success
                          ? (type) {
                              setState(() {
                                _oathType = type ?? OathType.totp;
                              });
                            }
                          : null,
                    ),
                  ),
                ),
                Chip(
                  label: DropdownButtonHideUnderline(
                    child: DropdownButton<HashAlgorithm>(
                      value: _hashAlgorithm,
                      isDense: true,
                      underline: null,
                      items: HashAlgorithm.values
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: _qrState != _QrScanState.success
                          ? (type) {
                              setState(() {
                                _hashAlgorithm = type ?? HashAlgorithm.sha1;
                              });
                            }
                          : null,
                    ),
                  ),
                ),
                if (_oathType == OathType.totp)
                  Chip(
                    label: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: int.tryParse(_periodController.text) ??
                            defaultPeriod,
                        isDense: true,
                        underline: null,
                        items: _periodValues
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('$e sec'),
                                ))
                            .toList(),
                        onChanged: _qrState != _QrScanState.success
                            ? (period) {
                                setState(() {
                                  _periodController.text =
                                      '${period ?? defaultPeriod}';
                                });
                              }
                            : null,
                      ),
                    ),
                  ),
                Chip(
                  label: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _digits,
                      isDense: true,
                      underline: null,
                      items: _digitsValues
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('$e digits'),
                              ))
                          .toList(),
                      onChanged: _qrState != _QrScanState.success
                          ? (digits) {
                              setState(() {
                                _digits = digits ?? defaultDigits;
                              });
                            }
                          : null,
                    ),
                  ),
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
