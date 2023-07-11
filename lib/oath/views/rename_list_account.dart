/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../desktop/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../models.dart';
import '../keys.dart' as keys;
import 'utils.dart';

final _log = Logger('oath.view.rename_account_dialog');

class RenameList extends ConsumerStatefulWidget {
  final DeviceNode device;
  final CredentialData credential;
  final List<CredentialData>? credentialsFromUri;
  final List<OathCredential>? credentials;

  const RenameList(
      this.device, this.credential, this.credentialsFromUri, this.credentials,
      {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RenameListState();
}

class _RenameListState extends ConsumerState<RenameList> {
  late String _issuer;
  late String _account;

  @override
  void initState() {
    super.initState();
    _issuer = widget.credential.issuer?.trim() ?? '';
    _account = widget.credential.name.trim();
  }

  void _submit() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Rename credentials
      final credential = CredentialData(
        issuer: _issuer,
        name: _account,
        oathType: widget.credential.oathType,
        secret: widget.credential.secret,
        hashAlgorithm: widget.credential.hashAlgorithm,
        digits: widget.credential.digits,
        counter: widget.credential.counter,
      );

      if (!mounted) return;
      Navigator.of(context).pop(credential);
      showMessage(context, l10n.s_account_renamed);
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
        l10n.l_account_add_failed(errorMessage),
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final credential = widget.credential;

    final remaining = getRemainingKeySpace(
      oathType: credential.oathType,
      period: credential.period,
      issuer: _issuer,
      name: _account,
    );
    final issuerRemaining = remaining.first;
    final nameRemaining = remaining.second;

    // is this credentials name/issuer pair different from all other?
    final isUniqueFromUri = widget.credentialsFromUri
            ?.where((element) =>
                element != credential &&
                element.name == _account &&
                (element.issuer ?? '') == _issuer)
            .isEmpty ??
        false;

    final isUniqueFromDevice = widget.credentials
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
    final isValid = isUniqueFromUri && isUniqueFromDevice && isValidFormat;

    return ResponsiveDialog(
      title: Text(l10n.s_rename_account),
      actions: [
        TextButton(
          onPressed: didChange && isValid ? _submit : null,
          key: keys.saveButton,
          child: Text(l10n.s_save),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.q_rename_target(credential.name)),
            Text(l10n.p_rename_will_change_account_displayed),
            TextFormField(
              initialValue: _issuer,
              enabled: issuerRemaining > 0,
              maxLength: issuerRemaining > 0 ? issuerRemaining : null,
              buildCounter: buildByteCounterFor(_issuer),
              inputFormatters: [limitBytesLength(issuerRemaining)],
              key: keys.issuerField,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_issuer_optional,
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
              key: keys.nameField,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_account_name,
                helperText: '', // Prevents dialog resizing when disabled
                errorText: !isValidFormat
                    ? l10n.l_account_name_required
                    : (!isUniqueFromUri || !isUniqueFromDevice)
                        ? l10n.l_name_already_exists
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
