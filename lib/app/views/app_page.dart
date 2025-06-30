/*
 * Copyright (C) 2022-2025 Yubico.
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../../widgets/delayed_visibility.dart';
import '../../widgets/file_drop_target.dart';
import '../message.dart';
import '../shortcuts.dart';
import '../state.dart';
import 'fs_dialog.dart';
import 'keys.dart';
import 'navigation.dart';

final _navigationBarVisibilityProvider =
    StateNotifierProvider<_VisibilityNotifier, bool>(
      (ref) =>
          _VisibilityNotifier('NAVIGATION_VISIBILITY', ref.watch(prefProvider)),
    );

final _sideMenuBarVisibilityProvider =
    StateNotifierProvider<_VisibilityNotifier, bool>(
      (ref) => _VisibilityNotifier(
        'DETAIL_VIEW_VISIBILITY',
        ref.watch(prefProvider),
      ),
    );

class _VisibilityNotifier extends StateNotifier<bool> {
  final String _key;
  final SharedPreferences _prefs;
  _VisibilityNotifier(this._key, this._prefs)
    : super(_prefs.getBool(_key) ?? true);

  void toggleExpanded() {
    final newValue = !state;
    state = newValue;
    _prefs.setBool(_key, newValue);
  }
}

// We use global keys here to maintain the content between AppPages,
// and keep track of what has been scrolled under AppBar
final _navKey = GlobalKey();
final _navExpandedKey = GlobalKey();
final _sliverTitleGlobalKey = GlobalKey();
final _sliverTitleWrapperGlobalKey = GlobalKey();
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
  const AppPage({
    super.key,
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
    this.headerSliver,
  }) : assert(
         !(onFileDropped != null && fileDropOverlay == null),
         'Declaring onFileDropped requires declaring a fileDropOverlay',
       );

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppPageState();
}

class _AppPageState extends ConsumerState<AppPage> {
  final _VisibilityController _sliverTitleController = _VisibilityController();
  final _VisibilityController _headerSliverController = _VisibilityController();
  final _VisibilityController _navController = _VisibilityController();
  final _VisibilityController _detailsController = _VisibilityController();
  late _VisibilitiesController _scrolledUnderController;

  final ScrollController _sliverTitleScrollController = ScrollController();
  bool _isKeyActionsDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _scrolledUnderController = _VisibilitiesController([
      _sliverTitleController,
      _navController,
      _detailsController,
    ]);
  }

  @override
  void dispose() {
    _sliverTitleController.dispose();
    _headerSliverController.dispose();
    _navController.dispose();
    _detailsController.dispose();
    _scrolledUnderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        // If tap is not absorbed downstream, treat it as dead space
        // and invoke escape intent
        Actions.invoke(context, EscapeIntent());
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          if (width < 400 ||
              (isAndroid && width < 600 && width < constraints.maxHeight)) {
            return _buildScaffold(context, true, false, false, height);
          }
          if (width < 800) {
            return _buildScaffold(context, true, true, false, height);
          }
          if (width < 1000) {
            return _buildScaffold(context, true, true, true, height);
          } else {
            // Fully expanded layout, close existing drawer if open
            final scaffoldState = scaffoldGlobalKey.currentState;
            if (scaffoldState?.isDrawerOpen == true) {
              scaffoldState?.closeDrawer();
            }
            return _buildScaffold(context, false, true, true, height);
          }
        },
      ),
    );
  }

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

  Widget _buildDrawer(BuildContext context, double appHeight) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: CloseButton(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                _buildLogo(context),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: Material(
                type: MaterialType.transparency,
                child: NavigationContent(
                  key: _navExpandedKey,
                  extended: true,
                  isDrawer: true,
                  appHeight: appHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollElement(
    BuildContext context,
    ScrollController scrollController,
    _ScrollDirection direction,
    _VisibilityController controller,
    GlobalKey targetKey,
    GlobalKey? anchorKey,
  ) {
    if (direction != _ScrollDirection.idle) {
      final currentContext = targetKey.currentContext;
      if (currentContext == null) return;

      final RenderBox renderBox =
          currentContext.findRenderObject() as RenderBox;
      final RenderBox? anchorRenderBox =
          anchorKey != null
              ? anchorKey.currentContext?.findRenderObject() as RenderBox?
              : null;

      final anchorHeight =
          anchorRenderBox != null
              ? anchorRenderBox.size.height
              : Scaffold.of(context).appBarMaxHeight!;

      final targetHeight = renderBox.size.height;
      final positionOffset =
          anchorRenderBox != null
              ? Offset(0, -anchorRenderBox.localToGlobal(Offset.zero).dy)
              : Offset.zero;

      final position = renderBox.localToGlobal(positionOffset);

      if (direction == _ScrollDirection.up) {
        var offset =
            scrollController.position.pixels +
            (targetHeight - (anchorHeight - position.dy));
        if (offset > scrollController.position.maxScrollExtent) {
          offset = scrollController.position.maxScrollExtent;
        }
        Timer.run(() {
          scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.ease,
          );
        });
      } else {
        var offset =
            scrollController.position.pixels - (anchorHeight - position.dy);

        if (offset < scrollController.position.minScrollExtent) {
          offset = scrollController.position.minScrollExtent;
        }
        if (controller.visibility != _Visibility.visible) {
          Timer.run(() {
            scrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 100),
              curve: Curves.ease,
            );
          });
        }
      }
    }
  }

  Widget _buildTitle(BuildContext context) {
    return ListenableBuilder(
      listenable: _sliverTitleController,
      builder: (context, child) {
        _scrollElement(
          context,
          _sliverTitleScrollController,
          _sliverTitleController.scrollDirection,
          _sliverTitleController,
          _sliverTitleWrapperGlobalKey,
          null,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                key: _sliverTitleGlobalKey,
                widget.alternativeTitle ?? widget.title!,
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color:
                      widget.alternativeTitle != null
                          ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                          : Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.capabilities != null && widget.alternativeTitle == null)
              Wrap(
                spacing: 4.0,
                runSpacing: 8.0,
                children: [
                  ...widget.capabilities!.map((c) => CapabilityBadge(c)),
                ],
              ),
          ],
        );
      },
    );
  }

  double _getTitleHeight(BuildContext context) {
    final Size size =
        (TextPainter(
          text: TextSpan(
            text: widget.title,
            style: Theme.of(context).textTheme.displaySmall,
          ), // Same style as title
          maxLines: 1,
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: TextDirection.ltr,
        )..layout()).size;
    return size.height;
  }

  Widget? _buildAppBarTitle(
    BuildContext context,
    bool hasRail,
    bool hasManage,
    bool fullyExpanded,
  ) {
    final showExpandedNavigationBar = ref.watch(
      _navigationBarVisibilityProvider,
    );
    final showExpandedSideMenuBar = ref.watch(_sideMenuBarVisibilityProvider);

    EdgeInsets padding;
    if (fullyExpanded) {
      padding = EdgeInsets.only(
        left: showExpandedNavigationBar ? 280 : 72,
        right: showExpandedSideMenuBar ? 320 : 0.0,
      );
    } else if (!hasRail && hasManage) {
      padding = const EdgeInsets.only(right: 320);
    } else if (hasRail && hasManage) {
      padding = EdgeInsets.only(
        left: 72,
        right: showExpandedSideMenuBar ? 320 : 0.0,
      );
    } else if (hasRail && !hasManage) {
      padding = const EdgeInsets.only(left: 72);
    } else {
      padding = const EdgeInsets.all(0);
    }

    if (widget.title != null) {
      return ListenableBuilder(
        listenable: _sliverTitleController,
        builder: (context, child) {
          final visible =
              _sliverTitleController.visibility == _Visibility.scrolledUnder;
          return Padding(
            padding: padding,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: visible ? 1 : 0,
              child: Text(widget.alternativeTitle ?? widget.title!),
            ),
          );
        },
      );
    }

    return null;
  }

  Widget _buildMainContent(BuildContext context, bool expanded) {
    final showExpandedSideMenuBar = ref.watch(_sideMenuBarVisibilityProvider);
    final actions =
        widget.actionsBuilder?.call(
          context,
          expanded && showExpandedSideMenuBar,
        ) ??
        [];
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          widget.centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
      children: [
        widget.builder(context, expanded && showExpandedSideMenuBar),
        if (actions.isNotEmpty)
          Align(
            alignment:
                widget.centered ? Alignment.center : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 0,
                left: 18,
                right: 18,
              ),
              child: Wrap(spacing: 8, runSpacing: 4, children: actions),
            ),
          ),
        if (widget.footnote != null)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 16,
              top: 33,
              left: 18,
              right: 18,
            ),
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
      child:
          widget.delayedContent
              ? DelayedVisibility(
                key: GlobalKey(), // Ensure we reset the delay on rebuild
                delay: const Duration(milliseconds: 400),
                child: content,
              )
              : content,
    );

    if (widget.centered) {
      return Stack(
        children: [
          if (widget.title != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 18.0,
                    right: 18.0,
                    bottom: 24.0,
                    top: 4.0,
                  ),
                  child: _buildTitle(context),
                ),
              ),
            ),
          Positioned.fill(
            // Header height = title height + vertical padding
            top: widget.title != null ? _getTitleHeight(context) + 24 : 0,
            child: Align(
              alignment: Alignment.center,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics:
                      isAndroid
                          ? const ClampingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          )
                          : null,
                  child: safeArea,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (widget.title != null) {
      return _VisibilityListener(
        targetKey: _sliverTitleGlobalKey,
        controller: _sliverTitleController,
        subTargetKey:
            widget.headerSliver != null ? headerSliverGlobalKey : null,
        subController:
            widget.headerSliver != null ? _headerSliverController : null,
        subAnchorKey:
            widget.headerSliver != null ? _sliverTitleWrapperGlobalKey : null,
        child: CustomScrollView(
          physics:
              isAndroid
                  ? const _NoImplicitScrollPhysics(
                    parent: ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                  )
                  : const _NoImplicitScrollPhysics(),
          controller: _sliverTitleScrollController,
          key: _mainContentGlobalKey,
          slivers: [
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTitleDelegate(
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        key: _sliverTitleWrapperGlobalKey,
                        padding: const EdgeInsets.only(
                          left: 18.0,
                          right: 18.0,
                          bottom: 12.0,
                          top: 4.0,
                        ),
                        child: _buildTitle(context),
                      ),
                    ),
                    // Header height = title height + vertical padding
                    height: _getTitleHeight(context) + 16,
                  ),
                ),
                if (widget.headerSliver != null)
                  SliverToBoxAdapter(
                    child: ListenableBuilder(
                      listenable: _headerSliverController,
                      builder: (context, child) {
                        _scrollElement(
                          context,
                          _sliverTitleScrollController,
                          _headerSliverController.scrollDirection,
                          _headerSliverController,
                          headerSliverGlobalKey,
                          _sliverTitleWrapperGlobalKey,
                        );

                        return Container(
                          key: headerSliverGlobalKey,
                          child: widget.headerSliver,
                        );
                      },
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(child: safeArea),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics:
          isAndroid
              ? const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
              : null,
      primary: false,
      child: safeArea,
    );
  }

  void _handleNavigationVisibility(BuildContext context, bool canExpand) {
    if (canExpand) {
      ref.read(_navigationBarVisibilityProvider.notifier).toggleExpanded();
    } else {
      final scaffoldState = scaffoldGlobalKey.currentState;
      if (scaffoldState?.isDrawerOpen == false) {
        scaffoldState?.openDrawer();
      } else {
        scaffoldState?.closeDrawer();
      }
    }
  }

  void _handleDetailViewVisibility(BuildContext context, bool canExpand) async {
    if (canExpand &&
        (widget.keyActionsBuilder != null ||
            widget.detailViewBuilder != null)) {
      ref.read(_sideMenuBarVisibilityProvider.notifier).toggleExpanded();
    }
    if (!canExpand &&
        widget.actionButtonBuilder == null &&
        widget.keyActionsBuilder != null) {
      if (!Navigator.of(context).canPop()) {
        _isKeyActionsDialogOpen = true;
        await showBlurDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder:
              (context) => FsDialog(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: widget.keyActionsBuilder!(context),
                ),
              ),
        );
        _isKeyActionsDialogOpen = false;
      } else {
        if (_isKeyActionsDialogOpen) {
          Navigator.of(context).pop();
          _isKeyActionsDialogOpen = false;
        }
      }
    }
  }

  Widget _buildScaffold(
    BuildContext context,
    bool hasDrawer,
    bool hasRail,
    bool hasManage,
    double appHeight,
  ) {
    final l10n = AppLocalizations.of(context);
    final fullyExpanded = !hasDrawer && hasRail && hasManage;
    final showExpandedNavigationBar = ref.watch(
      _navigationBarVisibilityProvider,
    );
    final showExpandedSideMenuBar = ref.watch(_sideMenuBarVisibilityProvider);
    final hasDetailsOrKeyActions =
        widget.detailViewBuilder != null || widget.keyActionsBuilder != null;
    var body = _buildMainContent(context, hasManage);

    var navigationText =
        fullyExpanded
            ? (showExpandedNavigationBar
                ? l10n.s_collapse_navigation
                : l10n.s_expand_navigation)
            : l10n.s_show_navigation;

    if (widget.onFileDropped != null) {
      body = FileDropTarget(
        onFileDropped: widget.onFileDropped!,
        overlay: widget.fileDropOverlay!,
        child: body,
      );
    }
    if (hasRail || hasManage) {
      body = SafeArea(
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasRail && (!fullyExpanded || !showExpandedNavigationBar))
                FocusTraversalOrder(
                  order: NumericFocusOrder(1),
                  child: SizedBox(
                    width: 72,
                    child: _VisibilityListener(
                      targetKey: _navKey,
                      controller: _navController,
                      child: NavigationContent(
                        key: _navKey,
                        shouldPop: false,
                        extended: false,
                        appHeight: appHeight,
                      ),
                    ),
                  ),
                ),
              if (fullyExpanded && showExpandedNavigationBar)
                FocusTraversalOrder(
                  order: NumericFocusOrder(1),
                  child: SizedBox(
                    width: 280,
                    child: _VisibilityListener(
                      controller: _navController,
                      targetKey: _navExpandedKey,
                      child: Material(
                        type: MaterialType.transparency,
                        child: NavigationContent(
                          key: _navExpandedKey,
                          shouldPop: false,
                          extended: true,
                          appHeight: appHeight,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(2),
                  child: body,
                ),
              ),
              if (hasManage &&
                  !hasDetailsOrKeyActions &&
                  showExpandedSideMenuBar &&
                  widget.capabilities != null &&
                  widget.capabilities?.first != Capability.u2f)
                // Add a placeholder for the Manage/Details column. Exceptions are:
                // - the "Security Key" because it does not have any actions/details.
                // - pages without Capabilities
                const SizedBox(width: 336), // simulate column
              if (hasManage &&
                  hasDetailsOrKeyActions &&
                  showExpandedSideMenuBar)
                FocusTraversalOrder(
                  order: NumericFocusOrder(3),
                  child: _VisibilityListener(
                    controller: _detailsController,
                    targetKey: _detailsViewGlobalKey,
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
                ),
            ],
          ),
        ),
      );
    }
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(
          navigationVisibilityProvider,
          (prev, next) => _handleNavigationVisibility(context, fullyExpanded),
        );
        ref.listen(
          sideMenuVisibilityProvider,
          (prev, next) => _handleDetailViewVisibility(context, hasManage),
        );
        return Scaffold(
          key: scaffoldGlobalKey,
          appBar: AppBar(
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: ListenableBuilder(
                listenable: _scrolledUnderController,
                builder: (context, child) {
                  final visible = _scrolledUnderController.someIsScrolledUnder;
                  return AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      color: Theme.of(context).hoverColor,
                      height: 1.0,
                    ),
                  );
                },
              ),
            ),
            iconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            scrolledUnderElevation: 0.0,
            leadingWidth: hasRail ? 84 : null,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: _buildAppBarTitle(
              context,
              hasRail,
              hasManage,
              fullyExpanded,
            ),
            centerTitle: true,
            leading:
                hasRail
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: IconButton(
                              icon: Icon(
                                Symbols.menu,
                                semanticLabel: navigationText,
                              ),
                              tooltip: navigationText,
                              onPressed:
                                  () => _handleNavigationVisibility(
                                    context,
                                    fullyExpanded,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    )
                    : Builder(
                      builder: (context) {
                        // Need to wrap with builder to get Scaffold context
                        return IconButton(
                          key: drawerIconButtonKey,
                          tooltip: l10n.s_show_navigation,
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: Icon(
                            Symbols.menu,
                            semanticLabel: l10n.s_show_navigation,
                          ),
                        );
                      },
                    ),
            actions: [
              if (widget.actionButtonBuilder == null &&
                  (widget.keyActionsBuilder != null && !hasManage))
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: IconButton(
                    key: actionsIconButtonKey,
                    onPressed:
                        () => _handleDetailViewVisibility(context, hasManage),
                    icon:
                        widget.keyActionsBadge
                            ? Badge(
                              child: Icon(
                                Symbols.more_vert,
                                semanticLabel: l10n.s_show_menu,
                              ),
                            )
                            : Icon(
                              Symbols.more_vert,
                              semanticLabel: l10n.s_show_menu,
                            ),
                    iconSize: 24,
                    tooltip: l10n.s_show_menu,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              if (hasManage &&
                  (widget.keyActionsBuilder != null ||
                      widget.detailViewBuilder != null))
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: IconButton(
                    key: toggleDetailViewIconButtonKey,
                    onPressed:
                        () => _handleDetailViewVisibility(context, hasManage),
                    icon: Icon(
                      Symbols.dock_to_left,
                      fill: showExpandedSideMenuBar ? 1 : 0,
                      weight: 600.0,
                    ),
                    iconSize: 24,
                    tooltip: l10n.s_toggle_menu_bar,
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
          drawer: hasDrawer ? _buildDrawer(context, appHeight) : null,
          body: body,
        );
      },
    );
  }
}

class CapabilityBadge extends ConsumerWidget {
  final Capability capability;
  final bool noTooltip;

  const CapabilityBadge(this.capability, {super.key, this.noTooltip = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final text = Text(capability.getDisplayName(l10n));
    final (fipsCapable, fipsApproved) =
        ref
            .watch(currentDeviceDataProvider)
            .valueOrNull
            ?.info
            .getFipsStatus(capability) ??
        (false, false);
    final label =
        fipsCapable
            ? Row(
              children: [
                Icon(
                  Symbols.shield,
                  color: colorScheme.onSecondaryContainer,
                  size: 12,
                  fill: fipsApproved ? 1 : 0,
                ),
                const SizedBox(width: 4),
                text,
              ],
            )
            : text;
    return Badge(
      backgroundColor: colorScheme.secondaryContainer,
      textColor: colorScheme.onSecondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      largeSize: MediaQuery.of(context).textScaler.scale(20),
      label:
          fipsCapable && !noTooltip
              ? Tooltip(
                message:
                    fipsApproved ? l10n.l_fips_approved : l10n.l_fips_capable,
                child: label,
              )
              : label,
    );
  }
}

enum _Visibility { visible, topScrolledUnder, halfScrolledUnder, scrolledUnder }

enum _ScrollDirection { idle, up, down }

class _VisibilityController with ChangeNotifier {
  _Visibility _visibility = _Visibility.visible;
  _ScrollDirection _scrollDirection = _ScrollDirection.idle;

  void setVisibility(_Visibility visibility) {
    if (visibility != _visibility) {
      _visibility = visibility;
      if (_visibility != _Visibility.visible) {
        _scrollDirection = _ScrollDirection.idle;
      }
      notifyListeners();
    }
  }

  void notifyScroll(_ScrollDirection scrollDirection) {
    if (visibility != _Visibility.scrolledUnder) {
      _scrollDirection = scrollDirection;
      notifyListeners();
    }
  }

  _ScrollDirection get scrollDirection => _scrollDirection;
  _Visibility get visibility => _visibility;
}

class _VisibilitiesController with ChangeNotifier {
  final List<_VisibilityController> controllers;
  bool someIsScrolledUnder = false;
  _VisibilitiesController(this.controllers) {
    for (var element in controllers) {
      element.addListener(() {
        _setScrolledUnder();
      });
    }
  }

  void _setScrolledUnder() {
    final val = controllers.any(
      (element) => element.visibility != _Visibility.visible,
    );
    if (val != someIsScrolledUnder) {
      someIsScrolledUnder = val;
      notifyListeners();
    }
  }
}

class _VisibilityListener extends StatefulWidget {
  final _VisibilityController controller;
  final Widget child;
  final GlobalKey targetKey;
  final _VisibilityController? subController;
  final GlobalKey? subTargetKey;
  final GlobalKey? subAnchorKey;
  const _VisibilityListener({
    required this.controller,
    required this.child,
    required this.targetKey,
    this.subController,
    this.subTargetKey,
    this.subAnchorKey,
  }) : assert(
         (subController == null &&
                 subTargetKey == null &&
                 subAnchorKey == null) ||
             (subController != null &&
                 subTargetKey != null &&
                 subAnchorKey != null),
         'Declaring   requires subTargetKey and subAnchorKey, and vice versa',
       );

  @override
  State<_VisibilityListener> createState() => _VisibilityListenerState();
}

class _VisibilityListenerState extends State<_VisibilityListener> {
  bool disableScroll = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (event) {
      setState(() {
        disableScroll = true;
      });
    },
    onPointerUp: (event) {
      setState(() {
        disableScroll = false;
      });
    },
    onPointerSignal: (event) {
      if (event is PointerScrollEvent) {
        if (!disableScroll) {
          setState(() {
            disableScroll = true;
          });
          Timer(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                disableScroll = false;
              });
            }
          });
        }
      }
    },
    child: NotificationListener(
      onNotification: (notification) {
        if (notification is ScrollMetricsNotification ||
            notification is ScrollUpdateNotification) {
          _handleScrollUpdate(context);
        }

        if (notification is ScrollEndNotification &&
            widget.child is CustomScrollView) {
          // Disable auto scrolling for mouse wheel and scrollbar
          _handleScrollEnd(context);
        }
        return false;
      },
      child: widget.child,
    ),
  );

  void _handleScrollUpdate(BuildContext context) {
    widget.controller.setVisibility(
      _scrolledUnderState(context, widget.targetKey, null),
    );

    if (widget.subController != null) {
      widget.subController!.setVisibility(
        _scrolledUnderState(context, widget.subTargetKey!, widget.subAnchorKey),
      );
    }
  }

  void _handleScrollEnd(BuildContext context) {
    if (!disableScroll) {
      widget.controller.notifyScroll(
        _getScrollDirection(
          _scrolledUnderState(context, widget.targetKey, null),
        ),
      );

      if (widget.subController != null) {
        widget.subController!.notifyScroll(
          _getScrollDirection(
            _scrolledUnderState(
              context,
              widget.subTargetKey!,
              widget.subAnchorKey,
            ),
          ),
        );
      }
    }
  }

  _ScrollDirection _getScrollDirection(_Visibility visibility) {
    if (visibility == _Visibility.halfScrolledUnder) {
      return _ScrollDirection.up;
    } else if (visibility == _Visibility.topScrolledUnder) {
      return _ScrollDirection.down;
    } else {
      return _ScrollDirection.idle;
    }
  }

  _Visibility _scrolledUnderState(
    BuildContext context,
    GlobalKey targetKey,
    GlobalKey? anchorKey,
  ) {
    final currentContext = targetKey.currentContext;
    if (currentContext == null) return _Visibility.visible;

    final RenderBox renderBox = currentContext.findRenderObject() as RenderBox;
    final RenderBox? anchorRenderBox =
        anchorKey != null
            ? anchorKey.currentContext?.findRenderObject() as RenderBox?
            : null;

    final anchorHeight =
        anchorRenderBox != null
            ? anchorRenderBox.size.height
            : Scaffold.of(context).appBarMaxHeight!;

    final targetHeight = renderBox.size.height;
    final positionOffset =
        anchorRenderBox != null
            ? Offset(0, -anchorRenderBox.localToGlobal(Offset.zero).dy)
            : Offset.zero;

    final position = renderBox.localToGlobal(positionOffset);

    if (anchorHeight - position.dy > targetHeight - 10) {
      return _Visibility.scrolledUnder;
    } else if (anchorHeight - position.dy > targetHeight / 2) {
      return _Visibility.halfScrolledUnder;
    } else if (anchorHeight - position.dy > 0) {
      return _Visibility.topScrolledUnder;
    } else {
      return _Visibility.visible;
    }
  }
}

class _SliverTitleDelegate extends SliverPersistentHeaderDelegate {
  _SliverTitleDelegate({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTitleDelegate oldDelegate) => true;
}

class _NoImplicitScrollPhysics extends ScrollPhysics {
  const _NoImplicitScrollPhysics({super.parent});

  @override
  bool get allowImplicitScrolling => false;

  @override
  _NoImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _NoImplicitScrollPhysics(parent: buildParent(ancestor));
  }
}
