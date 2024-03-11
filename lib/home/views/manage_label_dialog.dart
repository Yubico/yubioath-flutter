/*
 * Copyright (C) 2024 Yubico.
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

import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/focus_utils.dart';
import '../../widgets/responsive_dialog.dart';

class ManageLabelDialog extends ConsumerStatefulWidget {
  final KeyCustomization initialCustomization;

  const ManageLabelDialog({super.key, required this.initialCustomization});

  @override
  ConsumerState<ManageLabelDialog> createState() => _ManageLabelDialogState();
}

class _ManageLabelDialogState extends ConsumerState<ManageLabelDialog> {
  String? _label;

  @override
  void initState() {
    super.initState();
    _label = widget.initialCustomization.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initialLabel = widget.initialCustomization.name;
    final didChange = initialLabel != _label;
    return ResponsiveDialog(
      title:
          Text(initialLabel != null ? l10n.s_change_label : l10n.s_set_label),
      actions: [
        TextButton(
          onPressed: didChange ? _submit : null,
          child: Text(l10n.s_save),
        )
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (initialLabel != null) Text(l10n.q_rename_target(initialLabel)),
            Text(initialLabel == null
                ? l10n.p_set_will_add_custom_name
                : l10n.p_rename_will_change_custom_name),
            AppTextFormField(
              autofocus: true,
              initialValue: _label,
              maxLength: 20,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_label,
                helperText: '',
                prefixIcon: const Icon(Symbols.key),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  final trimmed = value.trim();
                  _label = trimmed.isEmpty ? null : trimmed;
                });
              },
              onFieldSubmitted: (_) {
                _submit();
              },
            )
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

  void _submit() async {
    final manager = ref.read(keyCustomizationManagerProvider.notifier);
    await manager.set(
        serial: widget.initialCustomization.serial,
        name: _label,
        color: widget.initialCustomization.color);

    await ref.read(withContextProvider)((context) async {
      FocusUtils.unfocus(context);
      Navigator.of(context).pop();
    });
  }
}
