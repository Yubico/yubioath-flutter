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

import '../../app/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/responsive_dialog.dart';
import '../state.dart';
import '../keys.dart' as keys;

class PinDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  const PinDialog(this.devicePath, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<PinDialog> {
  String _pin = '';
  bool _pinIsWrong = false;
  int _attemptsRemaining = -1;

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    try {
      final status = await ref
          .read(pivStateProvider(widget.devicePath).notifier)
          .verifyPin(_pin);
      status.when(
        success: () {
          navigator.pop(true);
        },
        failure: (attemptsRemaining) {
          setState(() {
            _attemptsRemaining = attemptsRemaining;
            _pinIsWrong = true;
          });
        },
      );
    } on CancellationException catch (_) {
      navigator.pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ResponsiveDialog(
      title: Text(l10n.s_pin_required),
      actions: [
        TextButton(
          key: keys.unlockButton,
          onPressed: _submit,
          child: Text(l10n.s_unlock),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.p_pin_required_desc),
            TextField(
              autofocus: true,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              key: keys.managementKeyField,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.s_pin,
                  prefixIcon: const Icon(Icons.pin_outlined),
                  errorText: _pinIsWrong
                      ? l10n.l_wrong_pin_attempts_remaining(_attemptsRemaining)
                      : null,
                  errorMaxLines: 3),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _pinIsWrong = false;
                  _pin = value;
                });
              },
              onSubmitted: (_) => _submit(),
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
