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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'cert_info_view.dart';
import 'overwrite_confirm_dialog.dart';
import 'utils.dart';

class ImportFileDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final PivState pivState;
  final PivSlot pivSlot;
  final File file;
  final bool showMatch;

  ImportFileDialog(
    this.devicePath,
    this.pivState,
    this.pivSlot,
    this.file, {
    super.key,
  }) : showMatch = pivSlot.slot != SlotId.cardAuth && pivState.supportsBio;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ImportFileDialogState();
}

class _ImportFileDialogState extends ConsumerState<ImportFileDialog> {
  late String _data;
  late bool _allowMatch;
  PivExamineResult? _state;
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _passwordIsWrong = false;
  bool _importing = false;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();

    _allowMatch = widget.showMatch;
    _init();
  }

  @override
  void dispose() {
    _passwordFocus.dispose();
    _passwordController.dispose();
    super.dispose();
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
    final password = _passwordController.text;
    final result = await ref
        .read(pivSlotsProvider(widget.devicePath).notifier)
        .examine(
          widget.pivSlot.slot,
          _data,
          password: password.isNotEmpty ? password : null,
        );

    final passwordIsWrong = switch (result) {
      PivExamineResultInvalidPassword() => password.isNotEmpty,
      PivExamineResultResult() => true,
    };
    if (passwordIsWrong) {
      _passwordController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _passwordController.text.length,
      );
      _passwordFocus.requestFocus();
    }
    setState(() {
      _state = result;
      _passwordIsWrong = passwordIsWrong;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // This is what ListTile uses for subtitle
    final subtitleStyle = textTheme.bodyMedium!.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    // This is what TextInput errors look like
    final errorStyle = textTheme.labelLarge!.copyWith(color: colorScheme.error);
    final state = _state;
    if (state == null) {
      return ResponsiveDialog(
        title: Text(l10n.l_import_file),
        actions: [
          TextButton(
            key: keys.unlockButton,
            onPressed: null,
            child: Text(l10n.s_unlock),
          ),
        ],
        builder: (context, _) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final password = _passwordController.text;

    switch (state) {
      case PivExamineResultInvalidPassword():
        return ResponsiveDialog(
          title: Text(l10n.l_import_file),
          actions: [
            TextButton(
              key: keys.unlockButton,
              onPressed: password.isNotEmpty ? _examine : null,
              child: Text(l10n.s_unlock),
            ),
          ],
          builder: (context, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  [
                        Text(l10n.p_password_protected_file),
                        AppTextField(
                          autofocus: true,
                          focusNode: _passwordFocus,
                          controller: _passwordController,
                          obscureText: _isObscure,
                          autofillHints: const [AutofillHints.password],
                          key: keys.managementKeyField,
                          decoration: AppInputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: l10n.s_password,
                            errorText: _passwordIsWrong
                                ? l10n.s_wrong_password
                                : null,
                            errorMaxLines: 3,
                            icon: const Icon(Symbols.password),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure
                                    ? Symbols.visibility
                                    : Symbols.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                              tooltip: _isObscure
                                  ? l10n.s_show_password
                                  : l10n.s_hide_password,
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: (value) {
                            setState(() {
                              _passwordIsWrong = false;
                            });
                          },
                          onSubmitted: (_) {
                            if (password.isNotEmpty && !_passwordIsWrong) {
                              _examine();
                            } else {
                              _passwordFocus.requestFocus();
                            }
                          },
                        ).init(),
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

      case PivExamineResultResult(
        :final keyType,
        :final certInfo,
        :final publicKeyMatch,
      ):
        {
          final isFips =
              ref.watch(currentDeviceDataProvider).valueOrNull?.info.isFips ??
              false;
          final unsupportedKey =
              keyType != null &&
              !getSupportedKeyTypes(
                widget.pivState.version,
                isFips,
              ).contains(keyType);

          return ResponsiveDialog(
            title: Text(l10n.l_import_file),
            actions: [
              TextButton(
                key: keys.unlockButton,
                onPressed:
                    (keyType == null && certInfo == null) ||
                        _importing ||
                        unsupportedKey
                    ? null
                    : () async {
                        final withContext = ref.read(withContextProvider);

                        if (!await confirmOverwrite(
                          context,
                          widget.pivSlot,
                          writeKey: keyType != null,
                          writeCert: certInfo != null,
                        )) {
                          return;
                        }

                        setState(() {
                          _importing = true;
                        });

                        void Function()? close;
                        try {
                          close = await withContext<void Function()>(
                            (context) async => !Platform.isAndroid
                                ? showMessage(
                                    context,
                                    l10n.l_importing_file,
                                    duration: const Duration(seconds: 30),
                                  )
                                : () {},
                          );
                          await ref
                              .read(
                                pivSlotsProvider(widget.devicePath).notifier,
                              )
                              .import(
                                widget.pivSlot.slot,
                                _data,
                                password: password.isNotEmpty ? password : null,
                                pinPolicy: getPinPolicy(
                                  widget.pivSlot.slot,
                                  _allowMatch,
                                ),
                              );
                          await withContext((context) async {
                            Navigator.of(context).pop(true);
                            showMessage(context, l10n.s_file_imported);
                          });
                        } catch (err) {
                          // TODO: More error cases
                          setState(() {
                            _passwordIsWrong = true;
                            _importing = false;
                          });
                        } finally {
                          close?.call();
                        }
                      },
                child: Text(l10n.s_import),
              ),
            ],
            builder: (context, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    [
                          Text(
                            l10n.p_import_items_desc(
                              widget.pivSlot.slot.getDisplayName(l10n),
                            ),
                          ),
                          if (keyType == null && certInfo == null) ...[
                            Row(
                              children: [
                                Icon(Symbols.error, color: colorScheme.error),
                                const SizedBox(width: 8),
                                Text(l10n.l_import_nothing, style: errorStyle),
                              ],
                            ),
                          ],
                          if (keyType != null) ...[
                            Row(
                              children: [
                                const Icon(Symbols.key),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.s_private_key,
                                  style: textTheme.bodyLarge,
                                  softWrap: true,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.s_algorithm),
                                const SizedBox(width: 8),
                                Text(
                                  keyType.name.toUpperCase(),
                                  style: subtitleStyle,
                                ),
                              ],
                            ),
                            if (unsupportedKey)
                              Row(
                                children: [
                                  Icon(Symbols.error, color: colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.l_unsupported_key_type,
                                    style: errorStyle,
                                  ),
                                ],
                              ),
                          ],
                          if (certInfo != null) ...[
                            Row(
                              children: [
                                const Icon(Symbols.id_card),
                                const SizedBox(width: 8.0),
                                Text(
                                  l10n.s_certificate,
                                  style: textTheme.bodyLarge,
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            if (publicKeyMatch == false)
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Symbols.warning_amber,
                                      fill: 1,
                                      size: 16,
                                      color: colorScheme.onTertiary,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.l_warning_public_key_mismatch,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onTertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              height:
                                  140, // Needed for layout, adapt if text sizes changes
                              child: CertInfoTable(certInfo, null),
                            ),
                          ],
                          if (keyType != null &&
                              !unsupportedKey &&
                              widget.showMatch) ...[
                            Row(
                              children: [
                                const Icon(Symbols.tune),
                                const SizedBox(width: 8.0),
                                Text(
                                  l10n.s_options,
                                  style: textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            Text(l10n.p_key_options_bio_desc),
                            FilterChip(
                              tooltip: l10n.s_pin_policy,
                              label: Text(l10n.s_allow_fingerprint),
                              selected: _allowMatch,
                              onSelected: _importing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _allowMatch = value;
                                      });
                                    },
                            ),
                          ],
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
  }
}
