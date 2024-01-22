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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'key_actions.dart';
import 'pin_dialog.dart';

class FidoLockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoLockedPage(this.node, this.state, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);

    if (!state.hasPin) {
      if (state.bioEnroll != null) {
        return MessagePage(
          actions: [
            ActionChip(
              label: Text(l10n.s_set_pin),
              onPressed: () async {
                await showBlurDialog(
                    context: context,
                    builder: (context) => FidoPinDialog(node.path, state));
              },
              avatar: const Icon(Icons.pin_outlined),
            )
          ],
          title: l10n.s_webauthn,
          header: '${l10n.s_fingerprints_get_started} (1/2)',
          message: l10n.p_set_fingerprints_desc,
          keyActionsBuilder: hasActions ? _buildActions : null,
          keyActionsBadge: fidoShowActionsNotifier(state),
        );
      } else {
        return MessagePage(
          title: l10n.s_webauthn,
          header: state.credMgmt
              ? l10n.l_no_discoverable_accounts
              : l10n.l_ready_to_use,
          message: l10n.p_optionally_set_a_pin,
          keyActionsBuilder: hasActions ? _buildActions : null,
          keyActionsBadge: fidoShowActionsNotifier(state),
        );
      }
    }

    if (!state.credMgmt && state.bioEnroll == null) {
      return MessagePage(
        title: l10n.s_webauthn,
        header: l10n.l_ready_to_use,
        message: l10n.l_register_sk_on_websites,
        keyActionsBuilder: hasActions ? _buildActions : null,
        keyActionsBadge: fidoShowActionsNotifier(state),
      );
    }

    if (state.forcePinChange) {
      return MessagePage(
        title: l10n.s_webauthn,
        header: l10n.s_pin_change_required,
        message: l10n.l_pin_change_required_desc,
        keyActionsBuilder: hasActions ? _buildActions : null,
        keyActionsBadge: fidoShowActionsNotifier(state),
      );
    }

    return AppPage(
      title: l10n.s_webauthn,
      keyActionsBuilder: hasActions ? _buildActions : null,
      builder: (context, _) => Column(
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
    final l10n = AppLocalizations.of(context)!;
    if (_retries == 0) {
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
    final l10n = AppLocalizations.of(context)!;
    final noFingerprints = widget._state.bioEnroll == false;
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.l_enter_fido2_pin),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: AppTextField(
              autofocus: true,
              obscureText: _isObscure,
              autofillHints: const [AutofillHints.password],
              controller: _pinController,
              decoration: AppInputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_pin,
                helperText: '', // Prevents dialog resizing
                errorText: _pinIsWrong ? _getErrorText() : null,
                errorMaxLines: 3,
                prefixIcon: const Icon(Icons.pin_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off),
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
            ),
          ),
          ListTile(
            leading:
                noFingerprints ? const Icon(Icons.warning_amber_rounded) : null,
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
              icon: const Icon(Icons.lock_open),
              label: Text(l10n.s_unlock),
              onPressed:
                  _pinController.text.isNotEmpty && !_blocked ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}
