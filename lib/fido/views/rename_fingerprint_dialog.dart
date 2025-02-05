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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../desktop/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../models.dart';
import '../state.dart';

class RenameFingerprintDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final Fingerprint fingerprint;
  const RenameFingerprintDialog(this.devicePath, this.fingerprint, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RenameAccountDialogState();
}

class _RenameAccountDialogState extends ConsumerState<RenameFingerprintDialog> {
  late TextEditingController _labelController;
  late FocusNode _labelFocus;
  _RenameAccountDialogState();

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.fingerprint.name);
    _labelFocus = FocusNode();
  }

  @override
  void dispose() {
    _labelFocus.dispose();
    _labelController.dispose();
    super.dispose();
  }

  _submit() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final renamed = await ref
          .read(fingerprintProvider(widget.devicePath).notifier)
          .renameFingerprint(widget.fingerprint, _labelController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(renamed);
      showMessage(context, l10n.s_fingerprint_renamed);
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
        l10n.l_rename_fp_failed(errorMessage),
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _labelController.text.trim();
    return ResponsiveDialog(
      title: Text(l10n.s_rename_fp),
      actions: [
        TextButton(
          onPressed: label.isNotEmpty ? _submit : null,
          child: Text(l10n.s_save),
        ),
      ],
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              autofocus: true,
              controller: _labelController,
              focusNode: _labelFocus,
              maxLength: 15,
              inputFormatters: [limitBytesLength(15)],
              buildCounter: buildByteCounterFor(label),
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_name,
                icon: const Icon(Symbols.fingerprint),
              ),
              onChanged: (_) {
                setState(() {});
              },
              onSubmitted: (_) {
                if (label.isNotEmpty) {
                  _submit();
                } else {
                  _labelFocus.requestFocus();
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
