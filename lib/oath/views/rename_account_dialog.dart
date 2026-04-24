/*
 * Copyright (C) 2022-2025 Yubico.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../desktop/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
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
    List<(String? issuer, String name)> existing,
  ) {
    return RenameAccountDialog(
      devicePath: devicePath,
      issuer: credential.issuer,
      name: credential.name,
      oathType: credential.oathType,
      period: credential.period,
      existing: existing,
      rename: (issuer, name) async {
        final renamed = await ref
            .read(credentialListProvider(devicePath).notifier)
            .renameAccount(credential, issuer, name);
        // Update favorite
        ref
            .read(favoritesProvider.notifier)
            .renameCredential(credential.id, renamed.id);
        return renamed;
      },
    );
  }
}

class _RenameAccountDialogState extends ConsumerState<RenameAccountDialog> {
  late TextEditingController _issuerController;
  late TextEditingController _nameController;

  final _issuerFocus = FocusNode();
  final _nameFocus = FocusNode();
  String? _issuerError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _issuerController = TextEditingController(text: widget.issuer?.trim());
    _nameController = TextEditingController(text: widget.name.trim());
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _nameController.dispose();
    _issuerFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    _issuerFocus.unfocus();
    _nameFocus.unfocus();
    final issuer = _issuerController.text.trim();
    final name = _nameController.text.trim();

    final didChange = (widget.issuer ?? '') != issuer || widget.name != name;
    final isUnique = !widget.existing.contains((issuer, name)) || !didChange;
    final nameNotEmpty = name.isNotEmpty;
    final issuerNoColon = !_issuerController.text.contains(':');

    final nav = Navigator.of(context);
    final withContext = ref.read(withContextProvider);

    bool hasError = false;
    String? issuerErr;
    String? nameErr;

    if (!issuerNoColon) {
      issuerErr = AppLocalizations.of(context).l_invalid_character_issuer;
      hasError = true;
    }

    if (!nameNotEmpty) {
      nameErr = AppLocalizations.of(context).l_field_required;
      hasError = true;
    } else if (!isUnique) {
      nameErr = AppLocalizations.of(context).l_name_already_exists;
      hasError = true;
    }

    if (!didChange) {
      nav.pop();
      return;
    }

    if (hasError) {
      setState(() {
        _issuerError = issuerErr;
        _nameError = nameErr;
      });
      return;
    }

    try {
      // Rename credentials
      final renamed = await widget.rename(
        issuer.isNotEmpty ? issuer : null,
        name,
      );

      await withContext(
        (context) async => showMessage(
          context,
          AppLocalizations.of(context).s_account_renamed,
        ),
      );

      nav.pop(renamed);
    } on CancellationException catch (_) {
      // ignored
    } catch (e) {
      _log.error('Failed to rename account', e);
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      await withContext(
        (context) async => showMessage(
          context,
          AppLocalizations.of(context).l_rename_account_failed(errorMessage),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issuer = _issuerController.text.trim();
    final name = _nameController.text.trim();

    final (issuerRemaining, nameRemaining) = getRemainingKeySpace(
      oathType: widget.oathType,
      period: widget.period,
      issuer: issuer,
      name: name,
    );

    return ResponsiveDialog(
      title: Text(l10n.s_rename_account),
      actions: [
        TextButton(
          onPressed: _submit,
          key: keys.saveButton,
          child: Text(l10n.s_save),
        ),
      ],
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: .start,
          children:
              [
                    Text(l10n.p_rename_will_change_account_displayed),
                    AppTextField(
                      controller: _issuerController,
                      enabled: issuerRemaining > 0,
                      maxLength: issuerRemaining > 0 ? issuerRemaining : null,
                      buildCounter: buildByteCounterFor(issuer),
                      inputFormatters: [limitBytesLength(issuerRemaining)],
                      key: keys.issuerField,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_issuer,
                        helperText:
                            '', // Prevents dialog resizing when disabled
                        errorText: _issuerError,
                        icon: const Icon(Symbols.business),
                      ),
                      textInputAction: .next,
                      focusNode: _issuerFocus,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {
                          _issuerError = null;
                        });
                      },
                    ).init(),
                    AppTextField(
                      controller: _nameController,
                      maxLength: nameRemaining,
                      inputFormatters: [limitBytesLength(nameRemaining)],
                      buildCounter: buildByteCounterFor(name),
                      key: keys.nameField,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_account_name,
                        isRequired: true,
                        helperText:
                            '', // Prevents dialog resizing when disabled
                        errorText: _nameError,
                        icon: const Icon(Symbols.people_alt),
                      ),
                      textInputAction: .done,
                      focusNode: _nameFocus,
                      onChanged: (value) {
                        setState(() {
                          _nameError = null;
                        });
                      },
                      onSubmitted: (_) {
                        _submit();
                      },
                    ).init(),
                  ]
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: e,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
