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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/file_drop_overlay.dart';
import '../../widgets/list_title.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'account_dialog.dart';
import 'account_helper.dart';
import 'account_list.dart';
import 'actions.dart';
import 'key_actions.dart';
import 'unlock_form.dart';
import 'utils.dart';

class OathScreen extends ConsumerWidget {
  final DevicePath devicePath;

  const OathScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(oathStateProvider(devicePath)).when(
          loading: () => const MessagePage(
            graphic: CircularProgressIndicator(),
            delayedContent: true,
          ),
          error: (error, _) => AppFailurePage(
            cause: error,
          ),
          data: (oathState) => oathState.locked
              ? _LockedView(devicePath, oathState)
              : _UnlockedView(devicePath, oathState),
        );
  }
}

class _LockedView extends ConsumerWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _LockedView(this.devicePath, this.oathState);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActions = ref.watch(featureProvider)(features.actions);
    return AppPage(
      title: AppLocalizations.of(context)!.s_accounts,
      keyActionsBuilder: hasActions
          ? (context) => oathBuildActions(context, devicePath, oathState, ref)
          : null,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: UnlockForm(
          devicePath,
          keystore: oathState.keystore,
        ),
      ),
    );
  }
}

class _UnlockedView extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _UnlockedView(this.devicePath, this.oathState);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UnlockedViewState();
}

class _UnlockedViewState extends ConsumerState<_UnlockedView> {
  late FocusNode searchFocus;
  late TextEditingController searchController;
  OathCredential? _selected;

  @override
  void initState() {
    super.initState();
    searchFocus = FocusNode();
    searchController = TextEditingController(text: ref.read(searchProvider));
    searchFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    searchFocus.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // ONLY rebuild if the number of credentials changes.
    final numCreds = ref.watch(credentialListProvider(widget.devicePath)
        .select((value) => value?.length));
    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);

    Future<void> onFileDropped(File file) async {
      final qrScanner = ref.read(qrScannerProvider);
      if (qrScanner != null) {
        final fileData = await file.readAsBytes();
        final b64Image = base64Encode(fileData);
        final qrData = await qrScanner.scanQr(b64Image);
        final withContext = ref.read(withContextProvider);
        await withContext(
          (context) async {
            if (qrData != null) {
              final credentials = ref.read(credentialsProvider);
              await handleUri(context, credentials, qrData, widget.devicePath,
                  widget.oathState, l10n);
            } else {
              showMessage(context, l10n.l_qr_not_found);
            }
          },
        );
      }
    }

    if (numCreds == 0) {
      return MessagePage(
        key: keys.noAccountsView,
        graphic: Icon(Icons.people,
            size: 96, color: Theme.of(context).colorScheme.primary),
        header: l10n.s_no_accounts,
        keyActionsBuilder: hasActions
            ? (context) => oathBuildActions(
                context, widget.devicePath, widget.oathState, ref,
                used: 0)
            : null,
        onFileDropped: onFileDropped,
        fileDropOverlay: FileDropOverlay(
          title: l10n.s_add_account,
          subtitle: l10n.l_drop_qr_description,
        ),
      );
    }

    return OathActions(
      devicePath: widget.devicePath,
      actions: (context) => {
        SearchIntent: CallbackAction<SearchIntent>(onInvoke: (_) {
          searchController.selection = TextSelection(
              baseOffset: 0, extentOffset: searchController.text.length);
          searchFocus.requestFocus();
          return null;
        }),
        EscapeIntent: CallbackAction<EscapeIntent>(onInvoke: (intent) {
          if (_selected != null) {
            setState(() {
              _selected = null;
            });
          } else {
            Actions.invoke(context, intent);
          }
          return false;
        }),
        OpenIntent<OathCredential>: CallbackAction<OpenIntent<OathCredential>>(
            onInvoke: (intent) async {
          await showBlurDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => AccountDialog(intent.target),
          );
          return null;
        }),
        if (hasFeature(features.accountsRename))
          EditIntent<OathCredential>:
              CallbackAction<EditIntent<OathCredential>>(
                  onInvoke: (intent) async {
            final renamed =
                await (Actions.invoke(context, intent) as Future<dynamic>?);
            if (renamed is OathCredential && _selected == intent.target) {
              setState(() {
                _selected = renamed;
              });
            }
            return renamed;
          }),
        if (hasFeature(features.accountsDelete))
          DeleteIntent<OathCredential>:
              CallbackAction<DeleteIntent<OathCredential>>(
                  onInvoke: (intent) async {
            final deleted =
                await (Actions.invoke(context, intent) as Future<dynamic>?);
            if (deleted == true && _selected == intent.target) {
              setState(() {
                _selected = null;
              });
            }
            return deleted;
          }),
      },
      builder: (context) => AppPage(
        title: l10n.s_accounts,
        keyActionsBuilder: hasActions
            ? (context) => oathBuildActions(
                  context,
                  widget.devicePath,
                  widget.oathState,
                  ref,
                  used: numCreds ?? 0,
                )
            : null,
        onFileDropped: onFileDropped,
        fileDropOverlay: FileDropOverlay(
          title: l10n.s_add_account,
          subtitle: l10n.l_drop_qr_description,
        ),
        centered: numCreds == null,
        delayedContent: numCreds == null,
        detailViewBuilder: _selected != null
            ? (context) {
                final helper = AccountHelper(context, ref, _selected!);
                final subtitle = helper.subtitle;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTitle(l10n.s_details),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconTheme(
                                    data: IconTheme.of(context)
                                        .copyWith(size: 24),
                                    child: helper.buildCodeIcon(),
                                  ),
                                  const SizedBox(width: 8.0),
                                  DefaultTextStyle.merge(
                                    style: const TextStyle(fontSize: 28),
                                    child: helper.buildCodeLabel(),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              helper.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                              softWrap: true,
                              textAlign: TextAlign.center,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                softWrap: true,
                                textAlign: TextAlign.center,
                                // This is what ListTile uses for subtitle
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .color,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ActionListSection.fromMenuActions(
                      context,
                      AppLocalizations.of(context)!.s_actions,
                      actions: helper.buildActions(),
                    ),
                  ],
                );
              }
            : null,
        builder: (context, expanded) {
          // De-select if window is resized to be non-expanded.
          if (!expanded) {
            Timer.run(() {
              setState(() {
                _selected = null;
              });
            });
          }
          return numCreds != null
              ? Actions(
                  actions: {
                    if (expanded)
                      OpenIntent<OathCredential>:
                          CallbackAction<OpenIntent<OathCredential>>(
                              onInvoke: (OpenIntent<OathCredential> intent) {
                        setState(() {
                          _selected = intent.target;
                        });
                        return null;
                      }),
                  },
                  child: Column(
                    children: [
                      Focus(
                        canRequestFocus: false,
                        onKeyEvent: (node, event) {
                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowDown) {
                            node.focusInDirection(TraversalDirection.down);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(builder: (context) {
                          final textTheme = Theme.of(context).textTheme;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: AppTextFormField(
                              key: keys.searchAccountsField,
                              controller: searchController,
                              focusNode: searchFocus,
                              // Use the default style, but with a smaller font size:
                              style: textTheme.titleMedium?.copyWith(
                                  fontSize: textTheme.titleSmall?.fontSize),
                              decoration: AppInputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide(
                                    width: 0,
                                    style: searchFocus.hasFocus
                                        ? BorderStyle.solid
                                        : BorderStyle.none,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                fillColor: Theme.of(context).hoverColor,
                                filled: true,
                                hintText: l10n.s_search_accounts,
                                isDense: true,
                                prefixIcon: const Padding(
                                  padding:
                                      EdgeInsetsDirectional.only(start: 8.0),
                                  child: Icon(Icons.search_outlined),
                                ),
                                suffixIcon: searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        iconSize: 16,
                                        onPressed: () {
                                          searchController.clear();
                                          ref
                                              .read(searchProvider.notifier)
                                              .setFilter('');
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                ref
                                    .read(searchProvider.notifier)
                                    .setFilter(value);
                                setState(() {});
                              },
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (value) {
                                Focus.of(context)
                                    .focusInDirection(TraversalDirection.down);
                              },
                            ),
                          );
                        }),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          return AccountList(
                            ref.watch(credentialListProvider(
                                    widget.devicePath)) ??
                                [],
                            expanded: expanded,
                            selected: _selected,
                          );
                        },
                      )
                    ],
                  ),
                )
              : const CircularProgressIndicator();
        },
      ),
    );
  }
}
