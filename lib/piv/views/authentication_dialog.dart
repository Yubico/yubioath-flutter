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
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;

class AuthenticationDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final PivState pivState;
  const AuthenticationDialog(this.devicePath, this.pivState, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AuthenticationDialogState();
}

class _AuthenticationDialogState extends ConsumerState<AuthenticationDialog> {
  String _managementKey = '';
  bool _keyIsWrong = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyLen = (widget.pivState.metadata?.managementKeyMetadata.keyType ??
                ManagementKeyType.tdes)
            .keyLength *
        2;
    return ResponsiveDialog(
      title: Text(l10n.l_unlock_piv_management),
      actions: [
        TextButton(
          key: keys.unlockButton,
          onPressed: _managementKey.length == keyLen
              ? () async {
                  final navigator = Navigator.of(context);
                  try {
                    final status = await ref
                        .read(pivStateProvider(widget.devicePath).notifier)
                        .authenticate(_managementKey);
                    if (status) {
                      navigator.pop(true);
                    } else {
                      setState(() {
                        _keyIsWrong = true;
                      });
                    }
                  } on CancellationException catch (_) {
                    navigator.pop(false);
                  } catch (_) {
                    // TODO: More error cases
                    setState(() {
                      _keyIsWrong = true;
                    });
                  }
                }
              : null,
          child: Text(l10n.s_unlock),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.p_unlock_piv_management_desc),
            TextField(
              key: keys.managementKeyField,
              autofocus: true,
              maxLength: keyLen,
              autofillHints: const [AutofillHints.password],
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('[a-f0-9]', caseSensitive: false))
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.s_management_key,
                prefixIcon: const Icon(Icons.key_outlined),
                errorText: _keyIsWrong ? l10n.l_wrong_key : null,
                errorMaxLines: 3,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _keyIsWrong = false;
                  _managementKey = value;
                });
              },
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
