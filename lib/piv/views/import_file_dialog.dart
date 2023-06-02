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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;

class ImportFileDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final PivState pivState;
  final PivSlot pivSlot;
  final File file;
  const ImportFileDialog(
      this.devicePath, this.pivState, this.pivSlot, this.file,
      {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ImportFileDialogState();
}

class _ImportFileDialogState extends ConsumerState<ImportFileDialog> {
  late String _data;
  PivExamineResult? _state;
  String _password = '';
  bool _passwordIsWrong = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final bytes = await widget.file.readAsBytes();
    _data = bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    _examine();
  }

  void _examine() async {
    setState(() {
      _state = null;
    });
    final result = await ref
        .read(pivSlotsProvider(widget.devicePath).notifier)
        .examine(_data, password: _password.isNotEmpty ? _password : null);
    setState(() {
      _state = result;
      _passwordIsWrong = result.maybeWhen(
        invalidPassword: () => _password.isNotEmpty,
        orElse: () => true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = _state;
    if (state == null) {
      return ResponsiveDialog(
        title: Text("Import file"),
        actions: [
          TextButton(
            key: keys.unlockButton,
            onPressed: null,
            child: Text(l10n.s_unlock),
          ),
        ],
        child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0),
            child: Center(
              child: CircularProgressIndicator(),
            )),
      );
    }

    return state.when(
      invalidPassword: () => ResponsiveDialog(
        title: Text("Import file"),
        actions: [
          TextButton(
            key: keys.unlockButton,
            onPressed: () => _examine(),
            child: Text(l10n.s_unlock),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                autofocus: true,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                key: keys.managementKeyField,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.password_outlined),
                    errorText: _passwordIsWrong ? l10n.s_wrong_password : null,
                    errorMaxLines: 3),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  setState(() {
                    _passwordIsWrong = false;
                    _password = value;
                  });
                },
                onSubmitted: (_) => _examine(),
              ),
            ]
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: e,
                    ))
                .toList(),
          ),
        ),
      ),
      result: (_, privateKey, certificates) => ResponsiveDialog(
        title: Text("Import file"),
        actions: [
          TextButton(
            key: keys.unlockButton,
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                await ref
                    .read(pivSlotsProvider(widget.devicePath).notifier)
                    .import(widget.pivSlot.slot, _data,
                        password: _password.isNotEmpty ? _password : null);
                navigator.pop(true);
              } catch (_) {
                // TODO: More error cases
                setState(() {
                  _passwordIsWrong = true;
                });
              }
            },
            child: Text(l10n.s_save),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Import the following into slot ${widget.pivSlot.slot.getDisplayName(l10n)}?"),
              if (privateKey) Text("- Private key"),
              if (certificates > 0) Text("- Certificate"),
            ]
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: e,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
