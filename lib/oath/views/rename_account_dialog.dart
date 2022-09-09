import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    _issuer = widget.credential.issuer?.trim() ?? '';
    _account = widget.credential.name.trim();
  }

  void _submit() async {
    try {
      // Rename credentials
      final renamed = await ref
          .read(credentialListProvider(widget.device.path).notifier)
          .renameAccount(
              widget.credential, _issuer.isNotEmpty ? _issuer : null, _account);

      // Update favorite
      ref
          .read(favoritesProvider.notifier)
          .renameCredential(widget.credential.id, renamed.id);

      if (!mounted) return;
      Navigator.of(context).pop(renamed);
      showMessage(context, AppLocalizations.of(context)!.oath_account_renamed);
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
    final didChange = (widget.credential.issuer ?? '') != _issuer ||
        widget.credential.name != _account;

    // can we rename with the new values
    final isValid = isUnique && isValidFormat;

    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.oath_rename_account),
      actions: [
        TextButton(
          onPressed: didChange && isValid ? _submit : null,
          child: Text(AppLocalizations.of(context)!.oath_save),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.oath_rename(label)),
            Text(AppLocalizations.of(context)!
                .oath_warning_will_change_account_displayed),
            TextFormField(
              initialValue: _issuer,
              enabled: issuerRemaining > 0,
              maxLength: issuerRemaining > 0 ? issuerRemaining : null,
              buildCounter: buildByteCounterFor(_issuer),
              inputFormatters: [limitBytesLength(issuerRemaining)],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: AppLocalizations.of(context)!.oath_issuer_optional,
                helperText: '', // Prevents dialog resizing when disabled
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
                labelText: AppLocalizations.of(context)!.oath_account_name,
                helperText: '', // Prevents dialog resizing when disabled
                errorText: !isValidFormat
                    ? AppLocalizations.of(context)!.oath_account_must_have_name
                    : !isUnique
                        ? AppLocalizations.of(context)!.oath_name_exists
                        : null,
                prefixIcon: const Icon(Icons.people_alt_outlined),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  _account = value.trim();
                });
              },
              onFieldSubmitted: (_) {
                if (didChange && isValid) {
                  _submit();
                }
              },
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
