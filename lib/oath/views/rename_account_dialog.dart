import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../desktop/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../models.dart';
import '../state.dart';
import 'utils.dart';

final _log = Logger('oath.view.rename_account_dialog');

class RenameAccountDialog extends ConsumerStatefulWidget {
  final DeviceNode device;
  final OathCredential credential;
  const RenameAccountDialog(this.device, this.credential, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RenameAccountDialogState();
}

class _RenameAccountDialogState extends ConsumerState<RenameAccountDialog> {
  late String _issuer;
  late String _account;

  @override
  void initState() {
    super.initState();
    _issuer = widget.credential.issuer ?? '';
    _account = widget.credential.name;
  }

  @override
  Widget build(BuildContext context) {
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

    return ResponsiveDialog(
      title: const Text('Rename account'),
      actions: [
        TextButton(
          onPressed: isValid
              ? () async {
                  try {
                    final renamed = await ref
                        .read(
                            credentialListProvider(widget.device.path).notifier)
                        .renameAccount(credential,
                            _issuer.isNotEmpty ? _issuer : null, _account);
                    if (!mounted) return;
                    Navigator.of(context).pop(renamed);
                    showMessage(context, 'Account renamed');
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
                      'Failed adding account: $errorMessage',
                      duration: const Duration(seconds: 4),
                    );
                  }
                }
              : null,
          child: const Text('Save'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rename $label?'),
          const Text(
              'This will change how the account is displayed in the list.'),
          TextFormField(
            initialValue: _issuer,
            enabled: issuerRemaining > 0,
            maxLength: issuerRemaining > 0 ? issuerRemaining : null,
            buildCounter: buildByteCounterFor(_issuer),
            inputFormatters: [limitBytesLength(issuerRemaining)],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Issuer (optional)',
              helperText: '', // Prevents dialog resizing when enabled = false
              prefixIcon: Icon(Icons.business_outlined),
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
            inputFormatters: [limitBytesLength(nameRemaining)],
            buildCounter: buildByteCounterFor(_account),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Account name',
              helperText: '', // Prevents dialog resizing when enabled = false
              errorText: isValid ? null : 'Your account must have a name',
              prefixIcon: const Icon(Icons.people_alt_outlined),
            ),
            onChanged: (value) {
              setState(() {
                _account = value.trim();
              });
            },
          ),
        ]
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: e,
                ))
            .toList(),
      ),
    );
  }
}
