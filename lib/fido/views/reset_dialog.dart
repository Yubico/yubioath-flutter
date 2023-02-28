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
    final nfc = widget.node.transport == Transport.nfc;
    switch (_interaction) {
      case InteractionEvent.remove:
        return nfc
            ? AppLocalizations.of(context)!.l_remove_yk_from_reader
            : AppLocalizations.of(context)!.l_unplug_yk;
      case InteractionEvent.insert:
        return nfc
            ? AppLocalizations.of(context)!.l_replace_yk_on_reader
            : AppLocalizations.of(context)!.l_reinsert_yk;
      case InteractionEvent.touch:
        return AppLocalizations.of(context)!.l_touch_button_now;
      case null:
        return AppLocalizations.of(context)!.l_press_reset_to_begin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.l_factory_reset),
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
                    showMessage(context,
                        AppLocalizations.of(context)!.l_fido_app_reset);
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
                      '${AppLocalizations.of(context)!.l_reset_failed}: $errorMessage',
                      duration: const Duration(seconds: 4),
                    );
                  });
                }
              : null,
          child: Text(AppLocalizations.of(context)!.w_reset),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.p_warning_deletes_accounts,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              AppLocalizations.of(context)!.p_warning_disable_accounts,
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
