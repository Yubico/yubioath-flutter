/*
 * Copyright (C) 2022-2024 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../desktop/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'utils.dart';

final _log = Logger('oath.view.rename_account_dialog');

class RenameAccountDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final String? issuer;
  final String name;
  final OathType oathType;
  final int period;
  final List<(String? issuer, String name)> existing;
  final Future<dynamic> Function(String? issuer, String name) rename;

  const RenameAccountDialog({
    required this.devicePath,
    required this.issuer,
    required this.name,
    required this.oathType,
    this.period = defaultPeriod,
    this.existing = const [],
    required this.rename,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RenameAccountDialogState();

  factory RenameAccountDialog.forOathCredential(
      WidgetRef ref,
      DevicePath devicePath,
      OathCredential credential,
      List<(String? issuer, String name)> existing) {
    return RenameAccountDialog(
      devicePath: devicePath,
      issuer: credential.issuer,
      name: credential.name,
      oathType: credential.oathType,
      period: credential.period,
      existing: existing,
      rename: (issuer, name) async {
        final withContext = ref.read(withContextProvider);
        try {
          // Rename credentials
          final renamed = await ref
              .read(credentialListProvider(devicePath).notifier)
              .renameAccount(credential, issuer, name);

          // Update favorite
          ref
              .read(favoritesProvider.notifier)
              .renameCredential(credential.id, renamed.id);

          await withContext((context) async => showMessage(
              context, AppLocalizations.of(context)!.s_account_renamed));
          return renamed;
        } on CancellationException catch (_) {
          return CancellationException();
        } catch (e) {
          _log.error('Failed to rename account', e);
          final String errorMessage;
          // TODO: Make this cleaner than importing desktop specific RpcError.
          if (e is RpcError) {
            errorMessage = e.message;
          } else {
            errorMessage = e.toString();
          }
          await withContext((context) async => showMessage(
                context,
                AppLocalizations.of(context)!
                    .l_rename_account_failed(errorMessage),
                duration: const Duration(seconds: 4),
              ));
          return null;
        }
      },
    );
  }
}

class _RenameAccountDialogState extends ConsumerState<RenameAccountDialog> {
  late String _issuer;
  late String _name;

  final _issuerFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _issuer = widget.issuer?.trim() ?? '';
    _name = widget.name.trim();
  }

  @override
  void dispose() {
    _issuerFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    _issuerFocus.unfocus();
    _nameFocus.unfocus();
    final nav = Navigator.of(context);
    final renamed =
        await widget.rename(_issuer.isNotEmpty ? _issuer : null, _name);
    if (renamed is! CancellationException) {
      nav.pop(renamed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (issuerRemaining, nameRemaining) = getRemainingKeySpace(
      oathType: widget.oathType,
      period: widget.period,
      issuer: _issuer,
      name: _name,
    );

    // are the name/issuer values different from original
    final didChange = (widget.issuer ?? '') != _issuer || widget.name != _name;

    // is this credentials name/issuer pair different from all other, or initial value?
    final isUnique = !widget.existing.contains((_issuer, _name)) || !didChange;

    // is this credential name/issuer of valid format
    final nameNotEmpty = _name.isNotEmpty;

    // can we rename with the new values
    final isValid = isUnique && nameNotEmpty;

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
            Text(l10n.q_rename_target(widget.issuer != null
                ? '${widget.issuer} (${widget.name})'
                : widget.name)),
            Text(l10n.p_rename_will_change_account_displayed),
            AppTextFormField(
              initialValue: _issuer,
              enabled: issuerRemaining > 0,
              maxLength: issuerRemaining > 0 ? issuerRemaining : null,
              buildCounter: buildByteCounterFor(_issuer),
              inputFormatters: [limitBytesLength(issuerRemaining)],
              key: keys.issuerField,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_issuer_optional,
                helperText: '', // Prevents dialog resizing when disabled
                prefixIcon: const Icon(Symbols.business),
              ),
              textInputAction: TextInputAction.next,
              focusNode: _issuerFocus,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _issuer = value.trim();
                });
              },
            ).init(),
            AppTextFormField(
              initialValue: _name,
              maxLength: nameRemaining,
              inputFormatters: [limitBytesLength(nameRemaining)],
              buildCounter: buildByteCounterFor(_name),
              key: keys.nameField,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_account_name,
                helperText: '', // Prevents dialog resizing when disabled
                errorText: !nameNotEmpty
                    ? l10n.l_account_name_required
                    : !isUnique
                        ? l10n.l_name_already_exists
                        : null,
                prefixIcon: const Icon(Symbols.people_alt),
              ),
              textInputAction: TextInputAction.done,
              focusNode: _nameFocus,
              onChanged: (value) {
                setState(() {
                  _name = value.trim();
                });
              },
              onFieldSubmitted: (_) {
                if (didChange && isValid) {
                  _submit();
                }
              },
            ).init(),
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
