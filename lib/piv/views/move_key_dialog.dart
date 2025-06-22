/*
 * Copyright (C) 2023-2025 Yubico.
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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/choice_filter_chip.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'overwrite_confirm_dialog.dart';

class MoveKeyDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final PivState pivState;
  final PivSlot pivSlot;
  const MoveKeyDialog(
    this.devicePath,
    this.pivState,
    this.pivSlot, {
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MoveKeyDialogState();
}

class _MoveKeyDialogState extends ConsumerState<MoveKeyDialog> {
  SlotId? _destination;
  late bool _includeCertificate;

  @override
  void initState() {
    super.initState();
    _includeCertificate = widget.pivSlot.certInfo != null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ResponsiveDialog(
      title: Text(l10n.l_move_key),
      actions: [
        TextButton(
          key: keys.moveButton,
          onPressed:
              _destination != null
                  ? () async {
                    try {
                      final pivSlots =
                          ref.read(pivSlotsProvider(widget.devicePath)).asData;
                      if (pivSlots != null) {
                        final destination = pivSlots.value.firstWhere(
                          (element) => element.slot == _destination,
                        );

                        if (!await confirmOverwrite(
                          context,
                          destination,
                          writeKey: true,
                          writeCert: _includeCertificate,
                        )) {
                          return;
                        }

                        await ref
                            .read(pivSlotsProvider(widget.devicePath).notifier)
                            .moveKey(
                              widget.pivSlot.slot,
                              destination.slot,
                              destination.metadata != null,
                              _includeCertificate,
                            );

                        await ref.read(withContextProvider)((context) async {
                          String message;
                          if (_includeCertificate) {
                            message = l10n.l_key_and_certificate_moved;
                          } else {
                            message = l10n.l_key_moved;
                          }

                          Navigator.of(context).pop(true);
                          showMessage(context, message);
                        });
                      }
                    } on CancellationException catch (_) {
                      // ignored
                    }
                  }
                  : null,
          child: Text(l10n.s_move),
        ),
      ],
      builder:
          (context, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  [
                        Text(
                          _destination == null
                              ? l10n.q_move_key_confirm(
                                widget.pivSlot.slot.getDisplayName(l10n),
                              )
                              : widget.pivSlot.certInfo != null &&
                                  _includeCertificate
                              ? l10n.q_move_key_and_certificate_to_slot_confirm(
                                widget.pivSlot.slot.getDisplayName(l10n),
                                _destination!.getDisplayName(l10n),
                              )
                              : l10n.q_move_key_to_slot_confirm(
                                widget.pivSlot.slot.getDisplayName(l10n),
                                _destination!.getDisplayName(l10n),
                              ),
                        ),
                        Wrap(
                          spacing: 4.0,
                          runSpacing: 8.0,
                          children: [
                            ChoiceFilterChip<SlotId?>(
                              menuConstraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              value: _destination,
                              items:
                                  SlotId.values
                                      .where(
                                        (element) =>
                                            element != widget.pivSlot.slot,
                                      )
                                      .toList(),
                              labelBuilder:
                                  (value) => Text(
                                    _destination == null
                                        ? l10n.l_select_destination_slot
                                        : _destination!.getDisplayName(l10n),
                                  ),
                              itemBuilder:
                                  (value) => Text(value!.getDisplayName(l10n)),
                              onChanged: (value) {
                                setState(() {
                                  _destination = value;
                                });
                              },
                            ),
                            if (widget.pivSlot.certInfo != null)
                              FilterChip(
                                key: keys.includeCertificateChip,
                                label: Text(l10n.l_include_certificate),
                                selected: _includeCertificate,
                                onSelected: (value) {
                                  setState(() {
                                    _includeCertificate = value;
                                  });
                                },
                              ),
                          ],
                        ),
                      ]
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: e,
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }
}
