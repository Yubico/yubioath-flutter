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
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/keys.dart';
import '../../app/views/message_page.dart';
import '../../app/views/message_page_not_initialized.dart';
import '../../core/state.dart';
import '../../exception/no_data_exception.dart';
import '../../management/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/flex_box.dart';
import '../../widgets/list_title.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'actions.dart';
import 'credential_dialog.dart';
import 'credential_info_view.dart';
import 'key_actions.dart';
import 'pin_dialog.dart';
import 'pin_entry_form.dart';

class PasskeysScreen extends ConsumerWidget {
  final YubiKeyData deviceData;

  const PasskeysScreen(this.deviceData, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(fidoStateProvider(deviceData.node.path)).when(
        loading: () => AppPage(
              title: l10n.s_passkeys,
              capabilities: const [Capability.fido2],
              centered: true,
              delayedContent: true,
              builder: (context, _) => const CircularProgressIndicator(),
            ),
        error: (error, _) {
          if (error is NoDataException) {
            return MessagePageNotInitialized(
              title: l10n.s_passkeys,
              capabilities: const [Capability.fido2],
            );
          }
          final enabled = deviceData
                  .info.config.enabledCapabilities[deviceData.node.transport] ??
              0;

          if (Capability.fido2.value & enabled == 0) {
            return MessagePage(
              title: l10n.s_passkeys,
              capabilities: const [Capability.fido2],
              header: l10n.s_fido_disabled,
              message: l10n.l_webauthn_req_fido2,
            );
          }

          return AppFailurePage(
            cause: error,
          );
        },
        data: (fidoState) {
          return fidoState.unlocked
              ? _FidoUnlockedPage(deviceData.node, fidoState)
              : _FidoLockedPage(deviceData.node, fidoState);
        });
  }
}

class _FidoLockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const _FidoLockedPage(this.node, this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);
    final isBio = state.bioEnroll != null;
    final alwaysUv = state.alwaysUv;

    if (!state.hasPin) {
      return MessagePage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        actionsBuilder: (context, expanded) {
          return [
            if (isBio)
              ActionChip(
                label: Text(l10n.s_setup_fingerprints),
                onPressed: () async {
                  ref
                      .read(currentSectionProvider.notifier)
                      .setCurrentSection(Section.fingerprints);
                },
                avatar: const Icon(Symbols.fingerprint),
              ),
            if (!isBio && alwaysUv && !expanded)
              ActionChip(
                label: Text(l10n.s_set_pin),
                onPressed: () async {
                  await showBlurDialog(
                      context: context,
                      builder: (context) => FidoPinDialog(node.path, state));
                },
                avatar: const Icon(Symbols.pin),
              )
          ];
        },
        header: state.credMgmt
            ? l10n.l_no_discoverable_accounts
            : l10n.l_ready_to_use,
        message: isBio
            ? l10n.p_setup_fingerprints_desc
            : alwaysUv
                ? l10n.l_pin_change_required_desc
                : l10n.l_register_sk_on_websites,
        footnote: isBio ? null : l10n.p_non_passkeys_note,
        keyActionsBuilder: hasActions ? _buildActions : null,
        keyActionsBadge: passkeysShowActionsNotifier(state),
      );
    }

    if (!state.credMgmt && !isBio) {
      return MessagePage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        header: l10n.l_ready_to_use,
        message: l10n.l_register_sk_on_websites,
        footnote: l10n.p_non_passkeys_note,
        keyActionsBuilder: hasActions ? _buildActions : null,
        keyActionsBadge: passkeysShowActionsNotifier(state),
      );
    }

    if (state.forcePinChange) {
      return MessagePage(
        actionsBuilder: (context, expanded) => [
          if (!expanded)
            ActionChip(
              label: Text(l10n.s_change_pin),
              onPressed: () async {
                await showBlurDialog(
                    context: context,
                    builder: (context) => FidoPinDialog(node.path, state));
              },
              avatar: const Icon(Symbols.pin),
            )
        ],
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        header: l10n.s_pin_change_required,
        message: l10n.l_pin_change_required_desc,
        keyActionsBuilder: hasActions ? _buildActions : null,
        keyActionsBadge: passkeysShowActionsNotifier(state),
      );
    }

    return AppPage(
      title: l10n.s_passkeys,
      capabilities: const [Capability.fido2],
      keyActionsBuilder: hasActions ? _buildActions : null,
      builder: (context, _) => Column(
        children: [
          PinEntryForm(state, node),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) =>
      passkeysBuildActions(context, node, state);
}

class _FidoUnlockedPage extends ConsumerStatefulWidget {
  final DeviceNode node;
  final FidoState state;

  _FidoUnlockedPage(this.node, this.state) : super(key: ObjectKey(node.path));

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FidoUnlockedPageState();
}

class _FidoUnlockedPageState extends ConsumerState<_FidoUnlockedPage> {
  late FocusNode searchFocus;
  late TextEditingController searchController;
  FidoCredential? _selected;
  bool _canRequestFocus = true;

  @override
  void initState() {
    super.initState();
    searchFocus = FocusNode();
    searchController =
        TextEditingController(text: ref.read(passkeysSearchProvider));
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
    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);
    final noFingerprints = widget.state.bioEnroll == false;

    if (!widget.state.credMgmt) {
      // TODO: Special handling for credMgmt not supported
      return MessagePage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        header: l10n.l_no_discoverable_accounts,
        message: l10n.l_register_sk_on_websites,
        footnote: l10n.p_non_passkeys_note,
        keyActionsBuilder: hasActions
            ? (context) =>
                passkeysBuildActions(context, widget.node, widget.state)
            : null,
        keyActionsBadge: passkeysShowActionsNotifier(widget.state),
      );
    }

    final data = ref.watch(credentialProvider(widget.node.path)).asData;
    if (data == null) {
      return _buildLoadingPage(context);
    }
    final credentials = data.value;
    final filteredCredentials =
        ref.watch(filteredFidoCredentialsProvider(credentials.toList()));

    final remainingCreds = widget.state.remainingCreds;
    final maxCreds =
        remainingCreds != null ? remainingCreds + credentials.length : 25;

    if (credentials.isEmpty) {
      return MessagePage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        actionsBuilder: noFingerprints
            ? (context, expanded) {
                return [
                  ActionChip(
                    label: Text(l10n.s_setup_fingerprints),
                    onPressed: () async {
                      ref
                          .read(currentSectionProvider.notifier)
                          .setCurrentSection(Section.fingerprints);
                    },
                    avatar: const Icon(Symbols.fingerprint),
                  )
                ];
              }
            : null,
        header: l10n.l_no_discoverable_accounts,
        message: noFingerprints
            ? l10n.p_setup_fingerprints_desc
            : l10n.l_register_sk_on_websites,
        keyActionsBuilder: hasActions
            ? (context) =>
                passkeysBuildActions(context, widget.node, widget.state)
            : null,
        keyActionsBadge: passkeysShowActionsNotifier(widget.state),
        footnote: l10n.p_non_passkeys_note,
      );
    }

    final credential = _selected;
    final searchText = searchController.text;
    return FidoActions(
      devicePath: widget.node.path,
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
        OpenIntent<FidoCredential>:
            CallbackAction<OpenIntent<FidoCredential>>(onInvoke: (intent) {
          return showBlurDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => CredentialDialog(intent.target),
          );
        }),
        if (hasFeature(features.credentialsDelete))
          DeleteIntent<FidoCredential>:
              CallbackAction<DeleteIntent<FidoCredential>>(
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
        title: l10n.s_passkeys,
        alternativeTitle:
            searchText != '' ? l10n.l_results_for(searchText) : null,
        capabilities: const [Capability.fido2],
        footnote:
            '${l10n.p_passkeys_used(credentials.length, maxCreds)} ${l10n.p_non_passkeys_note}',
        headerSliver: Focus(
          canRequestFocus: false,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              node.focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              searchController.clear();
              ref.read(passkeysSearchProvider.notifier).setFilter('');
              node.unfocus();
              setState(() {});
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: LayoutBuilder(builder: (context, constraints) {
            final textTheme = Theme.of(context).textTheme;
            final width = constraints.maxWidth;
            final showLayoutOptions = width > 600;
            return Consumer(
              builder: (context, ref, child) {
                final layout = ref.watch(passkeysLayoutProvider);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
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
                      hintText: l10n.s_search_passkeys,
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
                                  .read(passkeysSearchProvider.notifier)
                                  .setFilter('');
                              setState(() {});
                            },
                          ),
                        if (searchController.text.isEmpty &&
                            !searchFocus.hasFocus &&
                            showLayoutOptions) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                // need this to maintain consistent distance
                                // between icons
                                padding: const EdgeInsets.only(left: 17.0),
                                child: Container(
                                  color:
                                      Theme.of(context).colorScheme.background,
                                  width: 1,
                                  height: 45,
                                ),
                              ),
                            ],
                          ),
                          ...FlexLayout.values.map(
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
                                      .read(passkeysLayoutProvider.notifier)
                                      .setLayout(e);
                                },
                                icon: Icon(
                                  e.icon,
                                  color: e == layout
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    onChanged: (value) {
                      ref
                          .read(passkeysSearchProvider.notifier)
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
        detailViewBuilder: credential != null
            ? (context) => Column(
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
                          child: CredentialInfoTable(credential),
                        ),
                      ),
                    ),
                    ActionListSection.fromMenuActions(
                      context,
                      l10n.s_actions,
                      actions: buildCredentialActions(credential, l10n),
                    ),
                  ],
                )
            : null,
        keyActionsBuilder: hasActions
            ? (context) =>
                passkeysBuildActions(context, widget.node, widget.state)
            : null,
        keyActionsBadge: passkeysShowActionsNotifier(widget.state),
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
              if (expanded) ...{
                OpenIntent<FidoCredential>:
                    CallbackAction<OpenIntent<FidoCredential>>(
                        onInvoke: (intent) {
                  setState(() {
                    _selected = intent.target;
                  });
                  return null;
                }),
              }
            },
            child: Consumer(
              builder: (context, ref, child) {
                final layout = ref.watch(passkeysLayoutProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (filteredCredentials.isEmpty)
                      Center(
                        child: Text(l10n.s_no_passkeys),
                      ),
                    FlexBox<FidoCredential>(
                      items: filteredCredentials,
                      itemBuilder: (cred) => _CredentialListItem(
                        cred,
                        expanded: expanded,
                        selected: _selected == cred,
                      ),
                      layout: layout,
                      getItemsPerRow: _getItemsPerRow,
                    )
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  int _getItemsPerRow(double width) {
    int itemsPerRow = 1;
    if (width <= 600) {
      // single column
      itemsPerRow = 1;
    } else if (width <= 900) {
      // 2 column
      itemsPerRow = 2;
    } else if (width < 1300) {
      // 3 column
      itemsPerRow = 3;
    } else if (width < 1500) {
      // 4 column
      itemsPerRow = 4;
    } else if (width < 1700) {
      // 5 column
      itemsPerRow = 5;
    } else if (width < 1900) {
      // 6 column
      itemsPerRow = 6;
    } else if (width < 2100) {
      // 7 column
      itemsPerRow = 7;
    } else {
      // 8 column
      itemsPerRow = 8;
    }
    return itemsPerRow;
  }

  Widget _buildLoadingPage(BuildContext context) => AppPage(
        title: AppLocalizations.of(context)!.s_passkeys,
        capabilities: const [Capability.fido2],
        centered: true,
        delayedContent: true,
        builder: (context, _) => const CircularProgressIndicator(),
      );
}

class _CredentialListItem extends StatelessWidget {
  final FidoCredential credential;
  final bool selected;
  final bool expanded;

  const _CredentialListItem(this.credential,
      {required this.expanded, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppListItem(
      credential,
      selected: selected,
      leading: CircleAvatar(
        foregroundColor: colorScheme.onSecondary,
        backgroundColor: colorScheme.secondary,
        child: const Icon(Symbols.passkey),
      ),
      title: credential.rpId,
      subtitle: credential.userName,
      trailing: expanded
          ? null
          : OutlinedButton(
              onPressed: Actions.handler(context, OpenIntent(credential)),
              child: const Icon(Symbols.more_horiz),
            ),
      tapIntent: isDesktop && !expanded ? null : OpenIntent(credential),
      doubleTapIntent: isDesktop && !expanded ? OpenIntent(credential) : null,
      buildPopupActions: (context) =>
          buildCredentialActions(credential, AppLocalizations.of(context)!),
    );
  }
}
