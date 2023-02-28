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

import '../../app/message.dart';
import '../../desktop/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';

class RenameFingerprintDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final Fingerprint fingerprint;
  const RenameFingerprintDialog(this.devicePath, this.fingerprint, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RenameAccountDialogState();
}

class _RenameAccountDialogState extends ConsumerState<RenameFingerprintDialog> {
  late String _label;
  _RenameAccountDialogState();

  @override
  void initState() {
    super.initState();
    _label = widget.fingerprint.name ?? '';
  }

  _submit() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final renamed = await ref
          .read(fingerprintProvider(widget.devicePath).notifier)
          .renameFingerprint(widget.fingerprint, _label);
      if (!mounted) return;
      Navigator.of(context).pop(renamed);
      showMessage(context, l10n.l_fingerprint_renamed);
    } catch (e) {
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      showMessage(
        context,
        '${l10n.l_rename_fp_failed}: $errorMessage',
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ResponsiveDialog(
      title: Text(l10n.l_rename_fp),
      actions: [
        TextButton(
          onPressed: _label.isNotEmpty ? _submit : null,
          child: Text(l10n.w_save),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.q_rename_target(widget.fingerprint.label)),
            Text(l10n.p_will_change_label_fp),
            TextFormField(
              initialValue: _label,
              maxLength: 15,
              inputFormatters: [limitBytesLength(15)],
              buildCounter: buildByteCounterFor(_label),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.w_label,
                prefixIcon: const Icon(Icons.fingerprint_outlined),
              ),
              onChanged: (value) {
                setState(() {
                  _label = value.trim();
                });
              },
              onFieldSubmitted: (_) {
                if (_label.isNotEmpty) {
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
