/*
 * Copyright (C) 2023-2025 Yubico.
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

class DeleteCertificateDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final PivState pivState;
  final PivSlot pivSlot;
  const DeleteCertificateDialog(this.devicePath, this.pivState, this.pivSlot,
      {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DeleteCertificateDialogState();
}

class _DeleteCertificateDialogState
    extends ConsumerState<DeleteCertificateDialog> {
  late bool _deleteCertificate;
  late bool _deleteKey;

  @override
  void initState() {
    super.initState();
    _deleteCertificate = widget.pivSlot.certInfo != null;
    _deleteKey = widget.pivSlot.metadata != null &&
        widget.pivState.version.isAtLeast(5, 7);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canDeleteCertificate = widget.pivSlot.certInfo != null;
    final canDeleteKey = widget.pivSlot.metadata != null &&
        widget.pivState.version.isAtLeast(5, 7);

    return BasicDialog(
      icon: Icon(Symbols.delete),
      title: Text(canDeleteKey && canDeleteCertificate
          ? l10n.q_delete_certificate_or_key
          : canDeleteCertificate
              ? l10n.q_delete_certificate
              : l10n.q_delete_key),
      actions: [
        TextButton(
          key: keys.deleteButton,
          onPressed: _deleteKey || _deleteCertificate
              ? () async {
                  try {
                    await ref
                        .read(pivSlotsProvider(widget.devicePath).notifier)
                        .delete(widget.pivSlot.slot, _deleteCertificate,
                            _deleteKey);

                    await ref.read(withContextProvider)(
                      (context) async {
                        String message;
                        if (_deleteCertificate && _deleteKey) {
                          message = l10n.l_certificate_and_key_deleted;
                        } else if (_deleteCertificate) {
                          message = l10n.l_certificate_deleted;
                        } else {
                          message = l10n.l_key_deleted;
                        }

                        Navigator.of(context).pop(true);
                        showMessage(context, message);
                      },
                    );
                  } on CancellationException catch (_) {
                    // ignored
                  }
                }
              : null,
          child: Text(l10n.s_delete),
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_deleteCertificate || _deleteKey) ...[
            Text(
              _deleteCertificate && _deleteKey
                  ? l10n.p_warning_delete_certificate_and_key
                  : _deleteCertificate
                      ? l10n.p_warning_delete_certificate
                      : l10n.p_warning_delete_key,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8.0),
            Text(_deleteCertificate && _deleteKey
                ? l10n.p_delete_certificate_and_key_desc(
                    widget.pivSlot.slot.getDisplayName(l10n))
                : _deleteCertificate
                    ? l10n.p_delete_certificate_desc(
                        widget.pivSlot.slot.getDisplayName(l10n))
                    : l10n.p_delete_key_desc(
                        widget.pivSlot.slot.getDisplayName(l10n)))
          ],
          if (!_deleteCertificate && !_deleteKey) ...[
            const SizedBox(height: 8.0),
            Text(l10n.p_select_what_to_delete),
          ],
          if (canDeleteKey && canDeleteCertificate) ...[
            const SizedBox(height: 16.0),
            Wrap(
              spacing: 4.0,
              runSpacing: 8.0,
              children: [
                if (canDeleteCertificate)
                  FilterChip(
                    label: Text(l10n.s_certificate),
                    selected: _deleteCertificate,
                    onSelected: (value) {
                      setState(() {
                        _deleteCertificate = value;
                      });
                    },
                  ),
                if (canDeleteKey)
                  FilterChip(
                      label: Text(l10n.s_private_key),
                      selected: _deleteKey,
                      onSelected: (value) {
                        setState(() {
                          _deleteKey = value;
                        });
                      })
              ],
            ),
          ]
        ],
      ),
    );
  }
}
