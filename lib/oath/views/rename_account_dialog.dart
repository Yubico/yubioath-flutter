import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../cancellation_exception.dart';
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
  final List<OathCredential>? credentials;

  const RenameAccountDialog(this.device, this.credential, this.credentials,
      {super.key});

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

    // is this credentials name/issuer pair different from all other?
    final isUnique = widget.credentials
            ?.where((element) =>
                element != credential &&
                element.name == _account &&
                (element.issuer ?? '') == _issuer)
            .isEmpty ??
        false;

    // is this credential name/issuer of valid format
    final isValidFormat = _account.isNotEmpty;

    // are the name/issuer values different from original
    final didChange = (widget.credential.issuer != null
            ? _issuer != widget.credential.issuer
            : _issuer != '') ||
        _account != widget.credential.name;

    // can we rename with the new values
    final isValid = isUnique && isValidFormat;

    return ResponsiveDialog(
      title: const Text('Rename account'),
      actions: [
        TextButton(
          onPressed: didChange && isValid
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
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Issuer (optional)',
              helperText: '',
              // Prevents dialog resizing when enabled = false
              errorText: isUnique ? null : ' ', // make the decoration red
              prefixIcon: const Icon(Icons.business_outlined),
            ),
            textInputAction: TextInputAction.next,
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
              helperText: '',
              // Prevents dialog resizing when enabled = false
              errorText: !isValidFormat
                  ? 'Your account must have a name'
                  : isUnique
                      ? null
                      : 'Same account already exists on the YubiKey',
              prefixIcon: const Icon(Icons.people_alt_outlined),
            ),
            textInputAction: TextInputAction.done,
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
