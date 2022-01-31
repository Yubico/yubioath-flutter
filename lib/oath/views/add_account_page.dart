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

class AddAccountForm extends StatefulWidget {
  final Function(CredentialData, bool) onSubmit;
  const AddAccountForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<AddAccountForm> {
  String _issuer = '';
  String _account = '';
  String _secret = '';
  bool _touch = false;
  bool _advanced = false;
  OathType _oathType = defaultOathType;
  HashAlgorithm _hashAlgorithm = defaultHashAlgorithm;
  int _period = defaultPeriod;
  int _digits = defaultDigits;

  @override
  Widget build(BuildContext context) {
    final remaining = getRemainingKeySpace(
      oathType: _oathType,
      period: _period,
      issuer: _issuer,
      name: _account,
    );
    final issuerRemaining = remaining.first;
    final nameRemaining = remaining.second;

    final secretValid = _secret.length * 5 % 8 < 5;
    final isValid =
        _account.isNotEmpty && _secret.isNotEmpty && secretValid && _period > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                enabled: issuerRemaining > 0,
                maxLength: max(issuerRemaining, 1),
                decoration: const InputDecoration(
                  labelText: 'Issuer (optional)',
                  helperText:
                      '', // Prevents dialog resizing when enabled = false
                ),
                onChanged: (value) {
                  setState(() {
                    _issuer = value.trim();
                  });
                },
              ),
              TextField(
                maxLength: nameRemaining,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  helperText:
                      '', // Prevents dialog resizing when enabled = false
                ),
                onChanged: (value) {
                  setState(() {
                    _account = value.trim();
                  });
                },
              ),
              TextField(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(_secretFormatterPattern)
                ],
                decoration: InputDecoration(
                    labelText: 'Secret key',
                    errorText: secretValid ? null : 'Invalid value'),
                onChanged: (value) {
                  setState(() {
                    _secret = value.replaceAll(' ', '');
                  });
                },
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
                        onChanged: (type) {
                          setState(() {
                            _oathType = type ?? OathType.totp;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 8.0,
                    ),
                    Expanded(
                      child: DropdownButtonFormField<HashAlgorithm>(
                        decoration:
                            const InputDecoration(label: Text('Algorithm')),
                        value: _hashAlgorithm,
                        items: HashAlgorithm.values
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (type) {
                          setState(() {
                            _hashAlgorithm = type ?? HashAlgorithm.sha1;
                          });
                        },
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
                          initialValue: _period > 0 ? _period.toString() : '',
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            label: const Text('Period'),
                            errorText: _period > 0
                                ? null
                                : 'Must be a positive number',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _period = int.tryParse(value) ?? -1;
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
                        decoration:
                            const InputDecoration(label: Text('Digits')),
                        value: _digits,
                        items: [6, 7, 8]
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _digits = value ?? defaultDigits;
                          });
                        },
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
                    widget.onSubmit(
                      CredentialData(
                        issuer: _issuer.isEmpty ? null : _issuer,
                        name: _account,
                        secret: _secret,
                        oathType: _oathType,
                        hashAlgorithm: _hashAlgorithm,
                        digits: _digits,
                        period: _period,
                      ),
                      _touch,
                    );
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
