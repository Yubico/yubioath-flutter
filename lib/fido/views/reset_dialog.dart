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
import 'package:yubico_authenticator/app/logging.dart';

import '../../app/message.dart';
import '../../core/models.dart';
import '../../desktop/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../state.dart';
import '../../fido/models.dart';
import '../../app/models.dart';

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

  String _getMessage() {
    final l10n = AppLocalizations.of(context)!;
    final nfc = widget.node.transport == Transport.nfc;
    return switch (_interaction) {
      InteractionEvent.remove =>
        nfc ? l10n.l_remove_yk_from_reader : l10n.l_unplug_yk,
      InteractionEvent.insert =>
        nfc ? l10n.l_replace_yk_on_reader : l10n.l_reinsert_yk,
      InteractionEvent.touch => l10n.l_touch_button_now,
      null => l10n.l_press_reset_to_begin
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ResponsiveDialog(
      title: Text(l10n.s_factory_reset),
      onCancel: () {
        _subscription?.cancel();
      },
      actions: [
        TextButton(
          onPressed: _subscription == null
              ? () async {
                  _subscription = ref
                      .read(fidoStateProvider(widget.node.path).notifier)
                      .reset()
                      .listen((event) {
                    setState(() {
                      _interaction = event;
                    });
                  }, onDone: () {
                    _subscription = null;
                    Navigator.of(context).pop();
                    showMessage(context, l10n.l_fido_app_reset);
                  }, onError: (e) {
                    _log.error('Error performing FIDO reset', e);
                    Navigator.of(context).pop();
                    final String errorMessage;
                    // TODO: Make this cleaner than importing desktop specific RpcError.
                    if (e is RpcError) {
                      errorMessage = e.message;
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
      ],
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
            Center(
              child: Text(_getMessage(),
                  style: Theme.of(context).textTheme.titleLarge),
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
