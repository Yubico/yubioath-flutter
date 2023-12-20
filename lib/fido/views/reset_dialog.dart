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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../core/models.dart';
import '../../desktop/models.dart';
import '../../fido/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../state.dart';

final _log = Logger('fido.views.reset_dialog');

class ResetDialog extends ConsumerStatefulWidget {
  final DeviceNode node;
  const ResetDialog(this.node, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ResetDialogState();
}

class _ResetDialogState extends ConsumerState<ResetDialog> {
  StreamSubscription<InteractionEvent>? _subscription;
  InteractionEvent? _interaction;
  int _currentStep = -1;
  final _totalSteps = 3;

  String _getMessage() {
    final l10n = AppLocalizations.of(context)!;
    final nfc = widget.node.transport == Transport.nfc;
    if (_currentStep == 3) {
      return l10n.l_fido_app_reset;
    }
    return switch (_interaction) {
      InteractionEvent.remove =>
        nfc ? l10n.l_remove_yk_from_reader : l10n.l_unplug_yk,
      InteractionEvent.insert =>
        nfc ? l10n.l_replace_yk_on_reader : l10n.l_reinsert_yk,
      InteractionEvent.touch => l10n.l_touch_button_now,
      null => ''
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double progress = _currentStep == -1 ? 0.0 : _currentStep / (_totalSteps);
    return ResponsiveDialog(
      title: Text(l10n.s_factory_reset),
      onCancel: _currentStep < 3
          ? () {
              _subscription?.cancel();
            }
          : null,
      actions: _currentStep < 3
          ? [
              TextButton(
                onPressed: _subscription == null
                    ? () async {
                        _subscription = ref
                            .read(fidoStateProvider(widget.node.path).notifier)
                            .reset()
                            .listen((event) {
                          setState(() {
                            _currentStep++;
                            _interaction = event;
                          });
                        }, onDone: () {
                          setState(() {
                            _currentStep++;
                          });
                          _subscription = null;
                        }, onError: (e) {
                          _log.error('Error performing FIDO reset', e);
                          Navigator.of(context).pop();
                          final String errorMessage;
                          // TODO: Make this cleaner than importing desktop specific RpcError.
                          if (e is RpcError) {
                            if (e.status == 'connection-error') {
                              errorMessage = l10n.l_failed_connecting_to_fido;
                            } else if (e.status == 'key-mismatch') {
                              errorMessage = l10n.l_wrong_inserted_yk_error;
                            } else if (e.status == 'user-action-timeout') {
                              errorMessage = l10n.l_user_action_timeout_error;
                            } else {
                              errorMessage = e.message;
                            }
                          } else {
                            errorMessage = e.toString();
                          }
                          showMessage(
                            context,
                            l10n.l_reset_failed(errorMessage),
                            duration: const Duration(seconds: 4),
                          );
                        });
                      }
                    : null,
                child: Text(l10n.s_reset),
              ),
            ]
          : [],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.p_warning_deletes_accounts,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              l10n.p_warning_disable_accounts,
            ),
            if (_currentStep > -1) ...[
              Text('${l10n.s_status}: ${_getMessage()}'),
              LinearProgressIndicator(value: progress)
            ],
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
