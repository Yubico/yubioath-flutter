import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/oath/models.dart';

import '../../app/state.dart';
import '../../app/models.dart';
import '../state.dart';

class OathAddAccountPage extends ConsumerStatefulWidget {
  const OathAddAccountPage({required this.device, Key? key}) : super(key: key);
  final DeviceNode device;
  @override
  OathAddAccountPageState createState() => OathAddAccountPageState();
}

class OathAddAccountPageState extends ConsumerState<OathAddAccountPage> {
  String _issuer = '';
  String _account = '';
  String _secret = '';
  bool _touch = false;

  @override
  Widget build(BuildContext context) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      //TODO: This can probably be checked better to make sure it's the main page.
      Navigator.of(context).popUntil((route) => route.isFirst);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add account'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Issuer',
              ),
              onChanged: (value) {
                setState(() {
                  _issuer = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Account name *',
              ),
              onChanged: (value) {
                setState(() {
                  _account = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Secret key *',
              ),
              onChanged: (value) {
                setState(() {
                  _secret = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CheckboxListTile(
              title: const Text('Require touch'),
              checkColor: Colors.white,
              value: _touch,
              onChanged: (value) {
                setState(() {
                  _touch = value ?? false;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                final cred = CredentialData(
                    issuer: _issuer.isEmpty ? null : _issuer,
                    name: _account,
                    secret: _secret);
                ref
                    .read(credentialListProvider(widget.device.path).notifier)
                    .addAccount(cred.toUri(), requireTouch: _touch);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account added'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
