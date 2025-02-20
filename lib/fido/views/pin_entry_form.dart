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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../keys.dart';
import '../models.dart';
import '../state.dart';

class PinEntryForm extends ConsumerStatefulWidget {
  final FidoState _state;
  final DeviceNode _deviceNode;

  const PinEntryForm(this._state, this._deviceNode, {super.key});

  @override
  ConsumerState<PinEntryForm> createState() => _PinEntryFormState();
}

class _PinEntryFormState extends ConsumerState<PinEntryForm> {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  bool _blocked = false;
  int? _retries;
  bool _pinIsWrong = false;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _pinFocus.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    _pinFocus.unfocus();

    setState(() {
      _pinIsWrong = false;
      _isObscure = true;
    });
    try {
      final result = await ref
          .read(fidoStateProvider(widget._deviceNode.path).notifier)
          .unlock(_pinController.text);
      result.whenOrNull(failed: (reason) {
        reason.maybeWhen(
          invalidPin: (retries, authBlocked) {
            _pinController.selection = TextSelection(
                baseOffset: 0, extentOffset: _pinController.text.length);
            _pinFocus.requestFocus();
            setState(() {
              _pinIsWrong = true;
              _retries = retries;
              _blocked = authBlocked;
            });
          },
          orElse: () {},
        );
      });
    } on CancellationException catch (_) {
      // ignored
    }
  }

  String? _getErrorText() {
    final l10n = AppLocalizations.of(context);
    if (widget._state.pinBlocked || _retries == 0) {
      return l10n.l_pin_blocked_reset;
    }
    if (_blocked) {
      return l10n.l_pin_soft_locked;
    }
    if (_retries != null) {
      return l10n.l_wrong_pin_attempts_remaining(_retries!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final noFingerprints = widget._state.bioEnroll == false;
    final authBlocked = widget._state.pinBlocked;
    final pinRetries = widget._state.pinRetries;
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.l_enter_fido2_pin),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
            child: AppTextField(
              key: pinEntry,
              autofocus: true,
              obscureText: _isObscure,
              autofillHints: const [AutofillHints.password],
              controller: _pinController,
              focusNode: _pinFocus,
              enabled: !authBlocked && !_blocked && (_retries ?? 1) > 0,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_pin,
                helperText: pinRetries != null && pinRetries <= 3
                    ? l10n.l_attempts_remaining(pinRetries)
                    : '', // Prevents dialog resizing
                errorText: _pinIsWrong || authBlocked ? _getErrorText() : null,
                errorMaxLines: 3,
                icon: const Icon(Symbols.pin),
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
              onChanged: (value) {
                setState(() {
                  _pinIsWrong = false;
                });
              }, // Update state on change
              onSubmitted: (_) => _submit(),
            ).init(),
          ),
          ListTile(
            leading: noFingerprints
                ? Icon(Symbols.warning_amber,
                    color: Theme.of(context).colorScheme.tertiary)
                : null,
            title: noFingerprints
                ? Text(
                    l10n.l_no_fps_added,
                    overflow: TextOverflow.fade,
                  )
                : null,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            minLeadingWidth: 0,
            trailing: FilledButton.icon(
              key: unlockFido2WithPin,
              icon: const Icon(Symbols.lock_open),
              label: Text(l10n.s_unlock),
              onPressed: !_pinIsWrong &&
                      _pinController.text.length >=
                          widget._state.minPinLength &&
                      !_blocked
                  ? _submit
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
