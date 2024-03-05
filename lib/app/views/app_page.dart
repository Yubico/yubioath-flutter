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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../core/state.dart';
import '../../management/models.dart';
import '../../widgets/delayed_visibility.dart';
import '../../widgets/file_drop_target.dart';
import '../message.dart';
import '../shortcuts.dart';
import 'fs_dialog.dart';
import 'keys.dart';
import 'navigation.dart';

final _navigationProvider = StateNotifierProvider<_NavigationProvider, bool>(
    (ref) => _NavigationProvider());

class _NavigationProvider extends StateNotifier<bool> {
  _NavigationProvider() : super(true);

  void toggleExpanded() {
    state = !state;
  }
}

class _ScrolledUnderProvider extends StateNotifier<bool> {
  _ScrolledUnderProvider() : super(false);

  void toggleScrolledUnder(bool scrolledUnder) {
    if (state != scrolledUnder) {
      state = scrolledUnder;
    }
  }
}

// We use global keys here to maintain the content between AppPages,
// and keep track of what has been scrolled under AppBar
final _navKey = GlobalKey();
final _navExpandedKey = GlobalKey();
final _sliverTitleGlobalKey = GlobalKey();
final _detailsViewGlobalKey = GlobalKey();
final _mainContentGlobalKey = GlobalKey();

class AppPage extends ConsumerStatefulWidget {
  final String? title;
  final String? alternativeTitle;
  final String? footnote;
  final Widget Function(BuildContext context, bool expanded) builder;
  final Widget Function(BuildContext context)? detailViewBuilder;
  final List<Widget> Function(BuildContext context, bool expanded)?
      actionsBuilder;
  final Widget Function(BuildContext context)? keyActionsBuilder;
  final bool keyActionsBadge;
  final bool centered;
  final bool delayedContent;
  final Widget Function(BuildContext context)? actionButtonBuilder;
  final Widget? fileDropOverlay;
  final Function(File file)? onFileDropped;
  final List<Capability>? capabilities;
  final Widget? headerSliver;
  const AppPage(
      {super.key,
      this.title,
      this.alternativeTitle,
      this.footnote,
      required this.builder,
      this.centered = false,
      this.keyActionsBuilder,
      this.detailViewBuilder,
      this.actionButtonBuilder,
      this.actionsBuilder,
      this.fileDropOverlay,
      this.capabilities,
      this.onFileDropped,
      this.delayedContent = false,
      this.keyActionsBadge = false,
      this.headerSliver})
      : assert(!(onFileDropped != null && fileDropOverlay == null),
            'Declaring onFileDropped requires declaring a fileDropOverlay');

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppPageState();
}

class _AppPageState extends ConsumerState<AppPage> {
  final _sliverTitleProvider =
      StateNotifierProvider<_ScrolledUnderProvider, bool>(
          (ref) => _ScrolledUnderProvider());
  final _navViewProvider = StateNotifierProvider<_ScrolledUnderProvider, bool>(
      (ref) => _ScrolledUnderProvider());
  final _detailsViewProvider =
      StateNotifierProvider<_ScrolledUnderProvider, bool>(
          (ref) => _ScrolledUnderProvider());

  bool _scrolledUnderAppBar(GlobalKey key) {
    final currentContext = key.currentContext;
    if (currentContext != null) {
      final RenderBox renderBox =
          currentContext.findRenderObject() as RenderBox;
      final appBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
      final position = renderBox.localToGlobal(Offset.zero);

      return appBarHeight - position.dy > 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width < 400 ||
              (isAndroid && width < 600 && width < constraints.maxHeight)) {
            return _buildScaffold(context, true, false, false);
          }
          if (width < 800) {
            return _buildScaffold(context, true, true, false);
          }
          if (width < 1000) {
            return _buildScaffold(context, true, true, true);
          } else {
            // Fully expanded layout, close existing drawer if open
            final scaffoldState = scaffoldGlobalKey.currentState;
            if (scaffoldState?.isDrawerOpen == true) {
              scaffoldState?.openEndDrawer();
            }
            return _buildScaffold(context, false, true, true);
          }
        },
      );

  Widget _buildLogo(BuildContext context) {
    final color =
        Theme.of(context).brightness == Brightness.dark ? 'white' : 'green';
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Image.asset(
        'assets/graphics/yubico-$color.png',
        alignment: Alignment.centerLeft,
        height: 28,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
        child: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: DrawerButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                _buildLogo(context),
                const SizedBox(width: 48),
              ],
            ),
            Material(
                type: MaterialType.transparency,
                child: NavigationContent(key: _navExpandedKey, extended: true)),
          ],
        ),
      ),
    ));
  }

  Widget _buildTitle(BuildContext context, bool? visible) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedOpacity(
          opacity: visible ?? true ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.alternativeTitle ?? widget.title!,
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                        color: widget.alternativeTitle != null
                            ? Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.4)
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.9),
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.capabilities != null &&
                  widget.alternativeTitle == null)
                Wrap(
                  spacing: 4.0,
                  runSpacing: 8.0,
                  children: [
                    ...widget.capabilities!.map((c) => CapabilityBadge(c))
                  ],
                )
            ],
          ),
        )
      ],
    );
  }

  Widget? _buildAppBarTitle(BuildContext context, bool hasRail, bool hasManage,
      bool fullyExpanded, bool visible) {
    final showNavigation = ref.watch(_navigationProvider);
    EdgeInsets padding;
    if (fullyExpanded) {
      padding = EdgeInsets.only(left: showNavigation ? 280 : 72, right: 320);
    } else if (!hasRail && hasManage) {
      padding = const EdgeInsets.only(right: 320);
    } else if (hasRail && hasManage) {
      padding = const EdgeInsets.only(left: 72, right: 320);
    } else if (hasRail && !hasManage) {
      padding = const EdgeInsets.only(left: 72);
    } else {
      padding = const EdgeInsets.all(0);
    }

    if (widget.title != null) {
      return Padding(
        padding: padding,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1 : 0,
          child: Text(widget.alternativeTitle ?? widget.title!),
        ),
      );
    }

    return null;
  }

  Widget _buildMainContent(BuildContext context, bool expanded) {
    final actions = widget.actionsBuilder?.call(context, expanded) ?? [];
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        widget.builder(context, expanded),
        if (actions.isNotEmpty)
          Align(
            alignment:
                widget.centered ? Alignment.center : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 0, left: 16, right: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: actions,
              ),
            ),
          ),
        if (widget.footnote != null)
          Padding(
            padding:
                const EdgeInsets.only(bottom: 16, top: 33, left: 16, right: 16),
            child: Opacity(
              opacity: 0.6,
              child: Text(
                widget.footnote!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );

    final safeArea = SafeArea(
      child: widget.delayedContent
          ? DelayedVisibility(
              key: GlobalKey(), // Ensure we reset the delay on rebuild
              delay: const Duration(milliseconds: 400),
              child: content,
            )
          : content,
    );

    if (widget.centered) {
      return Stack(children: [
        if (widget.title != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 24.0),
                child: _buildTitle(context, null),
              ),
            ),
          ),
        Positioned.fill(
          top: widget.title != null ? 68.0 : 0,
          child: Align(
            alignment: Alignment.center,
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: safeArea,
              ),
            ),
          ),
        )
      ]);
    }
    if (widget.title != null) {
      return NotificationListener<ScrollMetricsNotification>(
        onNotification: (notification) {
          final isSliverScrolledUnder = ref.read(_sliverTitleProvider);
          final scrolledUnder = _scrolledUnderAppBar(_sliverTitleGlobalKey);
          if (isSliverScrolledUnder != scrolledUnder &&
              isSliverScrolledUnder &&
              !scrolledUnder) {
            Scrollable.ensureVisible(_sliverTitleGlobalKey.currentContext!,
                duration: const Duration(milliseconds: 300));
          }
          ref
              .read(_sliverTitleProvider.notifier)
              .toggleScrolledUnder(scrolledUnder);

          return false;
        },
        child: CustomScrollView(
          key: _mainContentGlobalKey,
          slivers: [
            SliverMainAxisGroup(
              slivers: [
                SliverPinnedHeader(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.background,
                    child: Padding(
                        key: _sliverTitleGlobalKey,
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 12.0, top: 4.0),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final visible = !ref.watch(_sliverTitleProvider);
                            return _buildTitle(context, visible);
                          },
                        )),
                  ),
                ),
                if (widget.headerSliver != null)
                  SliverToBoxAdapter(
                    child: widget.headerSliver,
                  )
              ],
            ),
            SliverToBoxAdapter(child: safeArea)
          ],
        ),
      );
    }

    return SingleChildScrollView(
      primary: false,
      child: safeArea,
    );
  }

  Scaffold _buildScaffold(
      BuildContext context, bool hasDrawer, bool hasRail, bool hasManage) {
    final fullyExpanded = !hasDrawer && hasRail && hasManage;
    final showNavigation = ref.watch(_navigationProvider);
    var body = _buildMainContent(context, hasManage);

    if (widget.onFileDropped != null) {
      body = FileDropTarget(
        onFileDropped: widget.onFileDropped!,
        overlay: widget.fileDropOverlay!,
        child: body,
      );
    }
    if (hasRail || hasManage) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasRail && (!fullyExpanded || !showNavigation))
            SizedBox(
              width: 72,
              child: NotificationListener(
                onNotification: (_) {
                  ref
                      .read(_navViewProvider.notifier)
                      .toggleScrolledUnder(_scrolledUnderAppBar(_navKey));
                  return false;
                },
                child: SingleChildScrollView(
                  child: NavigationContent(
                    key: _navKey,
                    shouldPop: false,
                    extended: false,
                  ),
                ),
              ),
            ),
          if (fullyExpanded && showNavigation)
            SizedBox(
                width: 280,
                child: NotificationListener(
                  onNotification: (_) {
                    ref.read(_navViewProvider.notifier).toggleScrolledUnder(
                        _scrolledUnderAppBar(_navExpandedKey));
                    return false;
                  },
                  child: SingleChildScrollView(
                    child: NavigationContent(
                      key: _navExpandedKey,
                      shouldPop: false,
                      extended: true,
                    ),
                  ),
                )),
          const SizedBox(width: 8),
          Expanded(
              child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: () {
              Actions.invoke(context, const EscapeIntent());
            },
            child: Stack(children: [
              Container(
                color: Colors.transparent,
              ),
              body
            ]),
          )),
          if (hasManage &&
              (widget.detailViewBuilder != null ||
                  widget.keyActionsBuilder != null))
            NotificationListener(
              onNotification: (_) {
                ref.read(_detailsViewProvider.notifier).toggleScrolledUnder(
                    _scrolledUnderAppBar(_detailsViewGlobalKey));
                return false;
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 320,
                    child: Column(
                      key: _detailsViewGlobalKey,
                      children: [
                        if (widget.detailViewBuilder != null)
                          widget.detailViewBuilder!(context),
                        if (widget.keyActionsBuilder != null)
                          widget.keyActionsBuilder!(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      key: scaffoldGlobalKey,
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Consumer(
            builder: (context, ref, child) {
              final visible = ref.watch(_sliverTitleProvider) ||
                  ref.watch(_navViewProvider) ||
                  ref.watch(_detailsViewProvider);
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: visible ? 1 : 0,
                child: Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  height: 1.0,
                ),
              );
            },
          ),
        ),
        scrolledUnderElevation: 0.0,
        leadingWidth: hasRail ? 84 : null,
        backgroundColor: Theme.of(context).colorScheme.background,
        title: widget.title != null
            ? Consumer(
                builder: (context, ref, child) {
                  final visible = ref.watch(_sliverTitleProvider);
                  return _buildAppBarTitle(
                      context, hasRail, hasManage, fullyExpanded, visible)!;
                },
              )
            : null,
        leading: hasRail
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DrawerButton(
                      onPressed: fullyExpanded
                          ? () {
                              ref
                                  .read(_navigationProvider.notifier)
                                  .toggleExpanded();
                            }
                          : null,
                    ),
                  )),
                  const SizedBox(width: 12),
                ],
              )
            : null,
        actions: [
          if (widget.actionButtonBuilder == null &&
              (widget.keyActionsBuilder != null && !hasManage))
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                key: actionsIconButtonKey,
                onPressed: () {
                  showBlurDialog(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (context) => FsDialog(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: widget.keyActionsBuilder!(context),
                      ),
                    ),
                  );
                },
                icon: widget.keyActionsBadge
                    ? const Badge(
                        child: Icon(Symbols.more_vert),
                      )
                    : const Icon(Symbols.more_vert),
                iconSize: 24,
                tooltip: AppLocalizations.of(context)!.s_configure_yk,
                padding: const EdgeInsets.all(12),
              ),
            ),
          if (widget.actionButtonBuilder != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: widget.actionButtonBuilder!.call(context),
            ),
        ],
      ),
      drawer: hasDrawer ? _buildDrawer(context) : null,
      body: body,
    );
  }
}

class CapabilityBadge extends StatelessWidget {
  final Capability capability;

  const CapabilityBadge(this.capability, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Badge(
      backgroundColor: colorScheme.secondaryContainer,
      textColor: colorScheme.onSecondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      largeSize: 20,
      label: Text(
        capability.getDisplayName(l10n),
      ),
    );
  }
}
