import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

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
  late TextEditingController _issuerController;
  late TextEditingController _nameController;
  _RenameAccountDialogState();

  @override
  void initState() {
    super.initState();
    _issuerController =
        TextEditingController(text: widget.credential.issuer ?? '');
    _nameController = TextEditingController(text: widget.credential.name);
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

    int remaining = 64;
    if (credential.oathType == OathType.totp && credential.period != 30) {
      remaining -= '${credential.period}/'.length;
    }
    if (_issuerController.text.isNotEmpty) {
      remaining -= 1;
    }
    final issuerRemaining = remaining - _nameController.text.length;
    final nameRemaining = remaining - _issuerController.text.length;
    final isValid = _nameController.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text('Rename $label?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'This will change how the account is displayed in the list.'),
          TextField(
            controller: _issuerController,
            enabled: issuerRemaining > 0,
            maxLength: issuerRemaining > 0 ? issuerRemaining : null,
            decoration: const InputDecoration(
              labelText: 'Issuer',
              helperText: '',
            ),
            onChanged: (value) {
              setState(() {}); // Update maxLength
            },
          ),
          TextField(
            controller: _nameController,
            enabled: nameRemaining > 0,
            maxLength: nameRemaining > 0 ? nameRemaining : null,
            decoration: InputDecoration(
              labelText: 'Account name *',
              helperText: '',
              errorText: isValid ? null : 'Your account must have a name',
            ),
            onChanged: (value) {
              setState(() {}); // Update maxLength, isValid
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
                  final issuer = _issuerController.text.trim();
                  final name = _nameController.text.trim();
                  await ref
                      .read(credentialListProvider(widget.device.path).notifier)
                      .renameAccount(
                          credential, issuer.isNotEmpty ? issuer : null, name);
                  Navigator.of(context).pop();
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
