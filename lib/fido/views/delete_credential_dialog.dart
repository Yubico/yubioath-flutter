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

// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/basic_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';

class DeleteCredentialDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final FidoCredential credential;

  const DeleteCredentialDialog(this.devicePath, this.credential, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DeleteCredentialDialogState();
}

class _DeleteCredentialDialogState
    extends ConsumerState<DeleteCredentialDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BasicDialog(
      icon: _isDeleting
          ? Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            )
          : Icon(Symbols.delete),
      title: Text(l10n.q_delete_passkey),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.p_warning_delete_passkey,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8.0),
          Text(l10n.p_warning_delete_passkey_desc),
        ],
      ),
      allowCancel: !_isDeleting,
      actions: [
        TextButton(
          key: keys.deleteButton,
          onPressed: !_isDeleting
              ? () async {
                  try {
                    setState(() {
                      _isDeleting = true;
                    });
                    await ref
                        .read(credentialProvider(widget.devicePath).notifier)
                        .deleteCredential(widget.credential);
                    await ref.read(withContextProvider)((context) async {
                      Navigator.of(context).pop(true);
                      showMessage(context, l10n.s_passkey_deleted);
                    });
                  } on CancellationException catch (_) {
                    // ignored
                    setState(() {
                      _isDeleting = false;
                    });
                  } catch (_) {
                    // Need to reset isDeleting for any unexpected errors
                    setState(() {
                      _isDeleting = false;
                    });
                    rethrow;
                  }
                }
              : null,
          child: Text(l10n.s_delete),
        ),
      ],
    );
  }
}
