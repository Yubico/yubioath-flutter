/*
 * Copyright (C) 2023 Yubico.
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
import '../../exception/cancellation_exception.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../keys.dart' as keys;
import '../state.dart';

class PinDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  const PinDialog(this.devicePath, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<PinDialog> {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  bool _pinIsWrong = false;
  int _attemptsRemaining = -1;
  bool _isObscure = true;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    try {
      final status = await ref
          .read(pivStateProvider(widget.devicePath).notifier)
          .verifyPin(_pinController.text);
      status.when(
        success: () {
          navigator.pop(true);
        },
        failure: (reason) {
          reason.maybeWhen(
            invalidPin: (attemptsRemaining) {
              _pinController.selection = TextSelection(
                  baseOffset: 0, extentOffset: _pinController.text.length);
              _pinFocus.requestFocus();
              setState(() {
                _attemptsRemaining = attemptsRemaining;
                _pinIsWrong = true;
              });
            },
            orElse: () {},
          );
        },
      );
    } on CancellationException catch (_) {
      navigator.pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final version = ref.watch(pivStateProvider(widget.devicePath)).valueOrNull;
    final minPinLen = version?.version.isAtLeast(4, 3, 1) == true ? 6 : 4;
    final currentPinLen = byteLength(_pinController.text);
    return ResponsiveDialog(
      title: Text(l10n.s_pin_required),
      actions: [
        TextButton(
          key: keys.unlockButton,
          onPressed: currentPinLen >= minPinLen ? _submit : null,
          child: Text(l10n.s_unlock),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.p_pin_required_desc),
            AppTextField(
              autofocus: true,
              obscureText: _isObscure,
              maxLength: 8,
              inputFormatters: [limitBytesLength(8)],
              buildCounter: buildByteCounterFor(_pinController.text),
              autofillHints: const [AutofillHints.password],
              key: keys.managementKeyField,
              controller: _pinController,
              focusNode: _pinFocus,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_pin,
                errorText: _pinIsWrong
                    ? l10n.l_wrong_pin_attempts_remaining(_attemptsRemaining)
                    : null,
                errorMaxLines: 3,
                prefixIcon: const Icon(Symbols.pin),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isObscure ? Symbols.visibility : Symbols.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                  tooltip: _isObscure ? l10n.s_show_pin : l10n.s_hide_pin,
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _pinIsWrong = false;
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
        ),
      ),
    );
  }
}
