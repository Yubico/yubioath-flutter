/*
 * Copyright (C) 2022-2023 Yubico.
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
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../models.dart';
import '../state.dart';
import 'key_actions.dart';

class FidoLockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoLockedPage(this.node, this.state, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!state.hasPin) {
      if (state.bioEnroll != null) {
        return MessagePage(
          title: Text(AppLocalizations.of(context)!.fido_webauthn),
          graphic: noFingerprints,
          header: AppLocalizations.of(context)!.fido_no_fingerprints,
          message: AppLocalizations.of(context)!.fido_set_pin_fingerprints,
          keyActionsBuilder: _buildActions,
        );
      } else {
        return MessagePage(
          title: Text(AppLocalizations.of(context)!.fido_webauthn),
          graphic: manageAccounts,
          header: state.credMgmt
              ? AppLocalizations.of(context)!.fido_no_discoverable_acc
              : AppLocalizations.of(context)!.fido_ready_to_use,
          message: AppLocalizations.of(context)!.fido_optionally_set_a_pin,
          keyActionsBuilder: _buildActions,
        );
      }
    }

    if (!state.credMgmt && state.bioEnroll == null) {
      return MessagePage(
        title: Text(AppLocalizations.of(context)!.fido_webauthn),
        graphic: manageAccounts,
        header: AppLocalizations.of(context)!.fido_ready_to_use,
        message: AppLocalizations.of(context)!.fido_register_as_a_key,
        keyActionsBuilder: _buildActions,
      );
    }

    return AppPage(
      title: Text(AppLocalizations.of(context)!.fido_webauthn),
      keyActionsBuilder: _buildActions,
      child: Column(
        children: [
          _PinEntryForm(state, node),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) =>
      fidoBuildActions(context, node, state, -1);
}

class _PinEntryForm extends ConsumerStatefulWidget {
  final FidoState _state;
  final DeviceNode _deviceNode;
  const _PinEntryForm(this._state, this._deviceNode);

  @override
  ConsumerState<_PinEntryForm> createState() => _PinEntryFormState();
}

class _PinEntryFormState extends ConsumerState<_PinEntryForm> {
  final _pinController = TextEditingController();
  bool _blocked = false;
  int? _retries;
  bool _pinIsWrong = false;
  bool _isObscure = true;

  void _submit() async {
    setState(() {
      _pinIsWrong = false;
      _isObscure = true;
    });
    final result = await ref
        .read(fidoStateProvider(widget._deviceNode.path).notifier)
        .unlock(_pinController.text);
    result.whenOrNull(failed: (retries, authBlocked) {
      setState(() {
        _pinController.clear();
        _pinIsWrong = true;
        _retries = retries;
        _blocked = authBlocked;
      });
    });
  }

  String? _getErrorText() {
    if (_retries == 0) {
      return AppLocalizations.of(context)!.fido_pin_blocked_factory_reset;
    }
    if (_blocked) {
      return AppLocalizations.of(context)!.fido_pin_temp_blocked;
    }
    if (_retries != null) {
      return AppLocalizations.of(context)!.fido_wrong_pin_attempts(_retries!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final noFingerprints = widget._state.bioEnroll == false;
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18, top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.fido_enter_fido2_pin),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: TextField(
              autofocus: true,
              obscureText: _isObscure,
              controller: _pinController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: AppLocalizations.of(context)!.fido_pin,
                helperText: '', // Prevents dialog resizing
                errorText: _pinIsWrong ? _getErrorText() : null,
                errorMaxLines: 3,
                prefixIcon: const Icon(Icons.pin_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                    color: IconTheme.of(context).color,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _pinIsWrong = false;
                });
              }, // Update state on change
              onSubmitted: (_) => _submit(),
            ),
          ),
          ListTile(
            leading:
                noFingerprints ? const Icon(Icons.warning_amber_rounded) : null,
            title: noFingerprints
                ? Text(
                    AppLocalizations.of(context)!.fido_no_fp_added,
                    overflow: TextOverflow.fade,
                  )
                : null,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            minLeadingWidth: 0,
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.lock_open),
              label: Text(AppLocalizations.of(context)!.fido_unlock),
              onPressed:
                  _pinController.text.isNotEmpty && !_blocked ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}
