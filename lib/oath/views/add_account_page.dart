import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/oath/models.dart';

import '../../app/state.dart';
import '../../app/models.dart';
import '../state.dart';
import 'utils.dart';

final _secretFormatterPattern =
    RegExp('[abcdefghijklmnopqrstuvwxyz234567 ]', caseSensitive: false);

enum _QrScanState { none, scanning, success, failed }

class AddAccountForm extends ConsumerStatefulWidget {
  final Function(CredentialData, bool) onSubmit;
  const AddAccountForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends ConsumerState<AddAccountForm> {
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();
  final _periodController = TextEditingController(text: '$defaultPeriod');
  bool _touch = false;
  bool _advanced = false;
  OathType _oathType = defaultOathType;
  HashAlgorithm _hashAlgorithm = defaultHashAlgorithm;
  int _digits = defaultDigits;
  bool _validateSecretLength = false;
  _QrScanState _qrState = _QrScanState.none;

  _scanQrCode(QrScanner qrScanner) async {
    try {
      setState(() {
        _qrState = _QrScanState.scanning;
      });
      final otpauth = await qrScanner.scanQr();
      final data = CredentialData.fromUri(Uri.parse(otpauth));
      setState(() {
        _issuerController.text = data.issuer ?? '';
        _accountController.text = data.name;
        _secretController.text = data.secret;
        _oathType = data.oathType;
        _hashAlgorithm = data.hashAlgorithm;
        _periodController.text = '${data.period}';
        _digits = data.digits;
        _qrState = _QrScanState.success;
      });
    } catch (e) {
      setState(() {
        _qrState = _QrScanState.failed;
      });
    }
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
  Widget build(BuildContext context) {
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
    final isValid =
        _accountController.text.isNotEmpty && secret.isNotEmpty && period > 0;

    final qrScanner = ref.watch(qrScannerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _issuerController,
                autofocus: true,
                enabled: issuerRemaining > 0,
                maxLength: max(issuerRemaining, 1),
                decoration: const InputDecoration(
                  labelText: 'Issuer (optional)',
                  helperText:
                      '', // Prevents dialog resizing when enabled = false
                ),
                onChanged: (value) {
                  setState(() {
                    // Update maxlengths
                  });
                },
              ),
              TextField(
                controller: _accountController,
                maxLength: nameRemaining,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  helperText:
                      '', // Prevents dialog resizing when enabled = false
                ),
                onChanged: (value) {
                  setState(() {
                    // Update maxlengths
                  });
                },
              ),
              TextField(
                controller: _secretController,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(_secretFormatterPattern)
                ],
                decoration: InputDecoration(
                    labelText: 'Secret key',
                    errorText: _validateSecretLength && !secretLengthValid
                        ? 'Invalid length'
                        : null),
                enabled: _qrState != _QrScanState.success,
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
            ],
          ),
        ),
        CheckboxListTile(
          title: const Text('Require touch'),
          controlAffinity: ListTileControlAffinity.leading,
          value: _touch,
          onChanged: (value) {
            setState(() {
              _touch = value ?? false;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Show advanced settings'),
          controlAffinity: ListTileControlAffinity.leading,
          value: _advanced,
          onChanged: (value) {
            setState(() {
              _advanced = value ?? false;
            });
          },
        ),
        if (_advanced)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<OathType>(
                        decoration: const InputDecoration(labelText: 'Type'),
                        value: _oathType,
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
                    const SizedBox(
                      width: 8.0,
                    ),
                    Expanded(
                      child: DropdownButtonFormField<HashAlgorithm>(
                        decoration:
                            const InputDecoration(labelText: 'Algorithm'),
                        value: _hashAlgorithm,
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
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_oathType == OathType.totp)
                      Expanded(
                        child: TextFormField(
                          controller: _periodController,
                          enabled: _qrState != _QrScanState.success,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            contentPadding:
                                // Manual alignment to match digits-dropdown.
                                const EdgeInsets.fromLTRB(0, 12, 0, 15),
                            labelText: 'Period',
                            errorText:
                                period > 0 ? null : 'Must be a positive number',
                          ),
                          onChanged: (value) {
                            setState(() {
                              // Update maxlengths
                            });
                          },
                        ),
                      ),
                    if (_oathType == OathType.totp)
                      const SizedBox(
                        width: 8.0,
                      ),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Digits'),
                        value: _digits,
                        items: [6, 7, 8]
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.toString()),
                                ))
                            .toList(),
                        onChanged: _qrState != _QrScanState.success
                            ? (value) {
                                setState(() {
                                  _digits = value ?? defaultDigits;
                                });
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: isValid
                ? () {
                    if (secretLengthValid) {
                      final issuer = _issuerController.text;
                      widget.onSubmit(
                        CredentialData(
                          issuer: issuer.isEmpty ? null : issuer,
                          name: _accountController.text,
                          secret: secret,
                          oathType: _oathType,
                          hashAlgorithm: _hashAlgorithm,
                          digits: _digits,
                          period: period,
                        ),
                        _touch,
                      );
                    } else {
                      setState(() {
                        _validateSecretLength = true;
                      });
                    }
                  }
                : null,
            child: const Text('Add account'),
          ),
        ),
      ],
    );
  }
}

class OathAddAccountPage extends ConsumerWidget {
  const OathAddAccountPage({required this.device, Key? key}) : super(key: key);
  final DeviceNode device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      //TODO: This can probably be checked better to make sure it's the main page.
      Navigator.of(context).popUntil((route) => route.isFirst);
    });

    return Scaffold(
        appBar: AppBar(
          title: const Text('Add account'),
        ),
        body: ListView(
          children: [
            AddAccountForm(
              onSubmit: (cred, requireTouch) {
                ref
                    .read(credentialListProvider(device.path).notifier)
                    .addAccount(cred.toUri(), requireTouch: requireTouch);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account added'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            )
          ],
        ));
  }
}
