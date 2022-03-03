import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import 'utils.dart';

class RenameAccountDialog extends ConsumerStatefulWidget {
  final DeviceNode device;
  final OathCredential credential;
  const RenameAccountDialog(this.device, this.credential, {Key? key})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RenameAccountDialogState();
}

class _RenameAccountDialogState extends ConsumerState<RenameAccountDialog> {
  late String _issuer;
  late String _account;
  _RenameAccountDialogState();

  @override
  void initState() {
    super.initState();
    _issuer = widget.credential.issuer ?? '';
    _account = widget.credential.name;
  }

  @override
  Widget build(BuildContext context) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    final credential = widget.credential;

    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;

    final remaining = getRemainingKeySpace(
      oathType: credential.oathType,
      period: credential.period,
      issuer: _issuer,
      name: _account,
    );
    final issuerRemaining = remaining.first;
    final nameRemaining = remaining.second;
    final isValid = _account.isNotEmpty;

    return AlertDialog(
      title: Text('Rename $label?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'This will change how the account is displayed in the list.'),
          TextFormField(
            initialValue: _issuer,
            enabled: issuerRemaining > 0,
            maxLength: issuerRemaining > 0 ? issuerRemaining : null,
            decoration: const InputDecoration(
              labelText: 'Issuer (optional)',
              helperText: '', // Prevents dialog resizing when enabled = false
            ),
            onChanged: (value) {
              setState(() {
                _issuer = value.trim();
              });
            },
          ),
          TextFormField(
            initialValue: _account,
            maxLength: nameRemaining,
            decoration: InputDecoration(
              labelText: 'Account name',
              helperText: '', // Prevents dialog resizing when enabled = false
              errorText: isValid ? null : 'Your account must have a name',
            ),
            onChanged: (value) {
              setState(() {
                _account = value.trim();
              });
            },
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isValid
              ? () async {
                  final renamed = await ref
                      .read(credentialListProvider(widget.device.path).notifier)
                      .renameAccount(credential,
                          _issuer.isNotEmpty ? _issuer : null, _account);
                  Navigator.of(context).pop(renamed);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account renamed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          child: const Text('Rename account'),
        ),
      ],
    );
  }
}
