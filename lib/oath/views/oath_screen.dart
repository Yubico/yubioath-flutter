/*
 * Copyright (C) 2022-2024 Yubico.
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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_page.dart';
import '../../app/views/keys.dart';
import '../../app/views/message_page.dart';
import '../../app/views/message_page_not_initialized.dart';
import '../../core/state.dart';
import '../../exception/no_data_exception.dart';
import '../../management/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/file_drop_overlay.dart';
import '../../widgets/list_title.dart';
import '../../widgets/tooltip_if_truncated.dart';
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

extension on OathLayout {
  IconData get _icon => switch (this) {
        OathLayout.list => Symbols.list,
        OathLayout.grid => Symbols.grid_view,
        OathLayout.mixed => Symbols.vertical_split
      };
  String getDisplayName(AppLocalizations l10n) => switch (this) {
        OathLayout.list => l10n.s_list_layout,
        OathLayout.grid => l10n.s_grid_layout,
        OathLayout.mixed => l10n.s_mixed_layout
      };
}

class OathScreen extends ConsumerWidget {
  final DevicePath devicePath;

  const OathScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(oathStateProvider(devicePath)).when(
        loading: () => MessagePage(
              title: AppLocalizations.of(context)!.s_accounts,
              capabilities: const [Capability.oath],
              centered: true,
              graphic: const CircularProgressIndicator(),
              delayedContent: true,
            ),
        error: (error, _) => error is NoDataException
            ? MessagePageNotInitialized(
                title: l10n.s_accounts,
                capabilities: const [Capability.oath],
              )
            : AppFailurePage(
                cause: error,
              ),
        data: (oathState) => oathState.locked
            ? _LockedView(devicePath, oathState)
            : _UnlockedView(devicePath, oathState));
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
      capabilities: const [Capability.oath],
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
  bool _canRequestFocus = true;

  @override
  void initState() {
    super.initState();
    searchFocus = FocusNode();
    searchController =
        TextEditingController(text: ref.read(accountsSearchProvider));
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
    final searchText = searchController.text;

    Future<void> onFileDropped(File file) async {
      final qrScanner = ref.read(qrScannerProvider);
      if (qrScanner != null) {
        final withContext = ref.read(withContextProvider);
        final qrData =
            await handleQrFile(file, context, withContext, qrScanner);
        if (qrData != null) {
          await withContext((context) async {
            final credentials = ref.read(credentialsProvider);
            await handleUri(context, credentials, qrData, widget.devicePath,
                widget.oathState, l10n);
          });
        }
      }
    }

    if (numCreds == 0) {
      return MessagePage(
        actionsBuilder: (context, expanded) => [
          if (!expanded)
            ActionChip(
              label: Text(l10n.s_add_account),
              onPressed: () async {
                await addOathAccount(
                  context,
                  ref,
                  widget.devicePath,
                  widget.oathState,
                );
              },
              avatar: const Icon(Symbols.person_add_alt),
            )
        ],
        title: l10n.s_accounts,
        capabilities: const [Capability.oath],
        key: keys.noAccountsView,
        header: l10n.l_authenticator_get_started,
        message: l10n.l_no_accounts_desc,
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

    if (numCreds == null) {
      return AppPage(
        title: AppLocalizations.of(context)!.s_accounts,
        capabilities: const [Capability.oath],
        centered: true,
        delayedContent: true,
        builder: (context, _) => const CircularProgressIndicator(),
      );
    }

    return OathActions(
      devicePath: widget.devicePath,
      actions: (context) => {
        SearchIntent: CallbackAction<SearchIntent>(onInvoke: (_) {
          searchController.selection = TextSelection(
              baseOffset: 0, extentOffset: searchController.text.length);
          searchFocus.unfocus();
          Timer.run(() => searchFocus.requestFocus());
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
        alternativeTitle:
            searchText != '' ? l10n.l_results_for(searchText) : null,
        capabilities: const [Capability.oath],
        keyActionsBuilder: hasActions
            ? (context) => oathBuildActions(
                  context,
                  widget.devicePath,
                  widget.oathState,
                  ref,
                  used: numCreds,
                )
            : null,
        onFileDropped: onFileDropped,
        fileDropOverlay: FileDropOverlay(
          title: l10n.s_add_account,
          subtitle: l10n.l_drop_qr_description,
        ),
        detailViewBuilder: _selected != null
            ? (context) {
                final helper = AccountHelper(context, ref, _selected!);
                final subtitle = helper.subtitle;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTitle(l10n.s_details),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Card(
                        elevation: 0.0,
                        color: Theme.of(context).hoverColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 16),
                          child: Column(
                            children: [
                              Row(
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
                              const SizedBox(height: 16),
                              TooltipIfTruncated(
                                text: helper.title,
                                style: TextStyle(
                                    fontSize: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.fontSize),
                              ),
                              if (subtitle != null)
                                TooltipIfTruncated(
                                  text: subtitle,
                                  // This is what ListTile uses for subtitle
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
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
        headerSliver: Focus(
          canRequestFocus: false,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              node.focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              searchController.clear();
              ref.read(accountsSearchProvider.notifier).setFilter('');
              node.unfocus();
              setState(() {});
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final textTheme = Theme.of(context).textTheme;
            return Consumer(
              builder: (context, ref, child) {
                final credentials = ref.watch(filteredCredentialsProvider(
                    ref.watch(credentialListProvider(widget.devicePath)) ??
                        []));
                final favorites = ref.watch(favoritesProvider);
                final pinnedCreds = credentials
                    .where((entry) => favorites.contains(entry.credential.id));

                final availableLayouts = pinnedCreds.isEmpty ||
                        pinnedCreds.length == credentials.length
                    ? OathLayout.values
                        .where((element) => element != OathLayout.mixed)
                    : OathLayout.values;
                final oathLayout = ref.watch(oathLayoutProvider);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 8.0),
                  child: AppTextFormField(
                    key: searchField,
                    controller: searchController,
                    canRequestFocus: _canRequestFocus,
                    focusNode: searchFocus,
                    // Use the default style, but with a smaller font size:
                    style: textTheme.titleMedium
                        ?.copyWith(fontSize: textTheme.titleSmall?.fontSize),
                    decoration: AppInputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(48),
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
                        padding: EdgeInsetsDirectional.only(start: 8.0),
                        child: Icon(Icons.search_outlined),
                      ),
                      suffixIcons: [
                        if (searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            iconSize: 16,
                            onPressed: () {
                              searchController.clear();
                              ref
                                  .read(accountsSearchProvider.notifier)
                                  .setFilter('');
                              setState(() {});
                            },
                          ),
                        if (searchController.text.isEmpty) ...[
                          if (width >= 450)
                            ...availableLayouts.map(
                              (e) => MouseRegion(
                                onEnter: (event) {
                                  if (!searchFocus.hasFocus) {
                                    setState(() {
                                      _canRequestFocus = false;
                                    });
                                  }
                                },
                                onExit: (event) {
                                  setState(() {
                                    _canRequestFocus = true;
                                  });
                                },
                                child: IconButton(
                                  tooltip: e.getDisplayName(l10n),
                                  onPressed: () {
                                    ref
                                        .read(oathLayoutProvider.notifier)
                                        .setLayout(e);
                                  },
                                  icon: Icon(
                                    e._icon,
                                    color: e == oathLayout
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          if (width < 450)
                            MouseRegion(
                              onEnter: (event) {
                                if (!searchFocus.hasFocus) {
                                  setState(() {
                                    _canRequestFocus = false;
                                  });
                                }
                              },
                              onExit: (event) {
                                setState(() {
                                  _canRequestFocus = true;
                                });
                              },
                              child: PopupMenuButton(
                                constraints: const BoxConstraints.tightFor(),
                                tooltip: 'Select layout',
                                popUpAnimationStyle:
                                    AnimationStyle(duration: Duration.zero),
                                icon: Icon(
                                  oathLayout._icon,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                itemBuilder: (context) => [
                                  ...availableLayouts.map(
                                    (e) => PopupMenuItem(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Tooltip(
                                            message: e.getDisplayName(l10n),
                                            child: Icon(
                                              e._icon,
                                              color: e == oathLayout
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        ref
                                            .read(oathLayoutProvider.notifier)
                                            .setLayout(e);
                                      },
                                    ),
                                  )
                                ],
                              ),
                            )
                        ]
                      ],
                    ),

                    onChanged: (value) {
                      ref
                          .read(accountsSearchProvider.notifier)
                          .setFilter(value);
                      setState(() {});
                    },
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (value) {
                      Focus.of(context)
                          .focusInDirection(TraversalDirection.down);
                    },
                  ).init(),
                );
              },
            );
          }),
        ),
        builder: (context, expanded) {
          // De-select if window is resized to be non-expanded.
          if (!expanded && _selected != null) {
            Timer.run(() {
              setState(() {
                _selected = null;
              });
            });
          }
          return Actions(
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
                Consumer(
                  builder: (context, ref, _) {
                    return AccountList(
                      ref.watch(credentialListProvider(widget.devicePath)) ??
                          [],
                      expanded: expanded,
                      selected: _selected,
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
