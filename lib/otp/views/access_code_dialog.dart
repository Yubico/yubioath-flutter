/*
 * Copyright (C) 2024-2025 Yubico.
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

import '../../app/models.dart';
import '../../core/models.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';

class AccessCodeDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OtpSlot otpSlot;
  final Future<void> Function(String accessCode) action;

  const AccessCodeDialog(
      {super.key,
      required this.devicePath,
      required this.otpSlot,
      required this.action});

  @override
  ConsumerState<AccessCodeDialog> createState() => _AccessCodeDialogState();
}

class _AccessCodeDialogState extends ConsumerState<AccessCodeDialog> {
  final _accessCodeController = TextEditingController();
  final _accessCodeFocus = FocusNode();
  bool _accessCodeIsWrong = false;
  String _accessCodeError = '';
  bool _isObscure = true;
  final accessCodeLength = 12;

  @override
  void dispose() {
    _accessCodeController.dispose();
    _accessCodeFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!Format.hex.isValid(_accessCodeController.text)) {
      _accessCodeController.selection = TextSelection(
          baseOffset: 0, extentOffset: _accessCodeController.text.length);
      _accessCodeFocus.requestFocus();
      setState(() {
        _accessCodeError =
            l10n.l_invalid_format_allowed_chars(Format.hex.allowedCharacters);
        _accessCodeIsWrong = true;
      });
      return;
    }
    try {
      final navigator = Navigator.of(context);
      await widget.action(_accessCodeController.text);
      navigator.pop(true);
    } catch (e) {
      _accessCodeController.selection = TextSelection(
          baseOffset: 0, extentOffset: _accessCodeController.text.length);
      _accessCodeFocus.requestFocus();
      setState(() {
        _accessCodeIsWrong = true;
        _accessCodeError = l10n.l_wrong_access_code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accessCode = _accessCodeController.text.replaceAll(' ', '');
    final accessCodeLengthValid =
        accessCode.isNotEmpty && accessCode.length == accessCodeLength;
    return ResponsiveDialog(
      title: Text(l10n.s_access_code),
      actions: [
        TextButton(
          onPressed: accessCodeLengthValid ? _submit : null,
          child: Text(l10n.s_unlock),
        )
      ],
      builder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.p_enter_access_code(
                  widget.otpSlot.slot.numberId.toString())),
              AppTextField(
                autofocus: true,
                obscureText: _isObscure,
                maxLength: accessCodeLength,
                autofillHints: const [AutofillHints.password],
                controller: _accessCodeController,
                focusNode: _accessCodeFocus,
                decoration: AppInputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_access_code,
                  errorText: _accessCodeIsWrong ? _accessCodeError : null,
                  errorMaxLines: 3,
                  icon: const Icon(Symbols.pin),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure
                        ? Symbols.visibility
                        : Symbols.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                    tooltip: _isObscure
                        ? l10n.s_show_access_code
                        : l10n.s_hide_access_code,
                  ),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  setState(() {
                    _accessCodeIsWrong = false;
                  });
                },
                onSubmitted: (_) => _submit(),
              ).init(),
            ]
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: e,
                    ))
                .toList(),
          )),
    );
  }
}
