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

import '../../widgets/delayed_visibility.dart';
import '../../widgets/file_drop_target.dart';
import '../message.dart';
import '../shortcuts.dart';
import 'fs_dialog.dart';
import 'keys.dart';
import 'navigation.dart';

// We use global keys here to maintain the NavigatorContent between AppPages.
final _navKey = GlobalKey();
final _navExpandedKey = GlobalKey();

class AppPage extends StatelessWidget {
  final String? title;
  final Widget Function(BuildContext context, bool expanded) builder;
  final Widget Function(BuildContext context)? detailViewBuilder;
  final List<Widget> actions;
  final Widget Function(BuildContext context)? keyActionsBuilder;
  final bool keyActionsBadge;
  final bool centered;
  final bool delayedContent;
  final Widget Function(BuildContext context)? actionButtonBuilder;
  final Widget? fileDropOverlay;
  final Function(File file)? onFileDropped;
  const AppPage({
    super.key,
    this.title,
    required this.builder,
    this.actions = const [],
    this.centered = false,
    this.keyActionsBuilder,
    this.detailViewBuilder,
    this.actionButtonBuilder,
    this.fileDropOverlay,
    this.onFileDropped,
    this.delayedContent = false,
    this.keyActionsBadge = false,
  }) : assert(!(onFileDropped != null && fileDropOverlay == null),
            'Declaring onFileDropped requires declaring a fileDropOverlay');

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width < 400) {
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
            return Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLogo(context),
                          NavigationContent(
                            key: _navExpandedKey,
                            shouldPop: false,
                            extended: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildScaffold(context, false, false, true),
                  ),
                ],
              ),
            );
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

  List<Widget> _buildTitle(BuildContext context) {
    return title != null
        ? [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(title!,
                    style: Theme.of(context).textTheme.displaySmall!.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
              ),
            ),
            const SizedBox(
              height: 24,
            )
          ]
        : [];
  }

  Widget _buildMainContent(BuildContext context, bool expanded) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildTitle(context),
        builder(context, expanded),
        if (actions.isNotEmpty)
          Align(
            alignment: centered ? Alignment.center : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: actions,
              ),
            ),
          ),
      ],
    );
    return SingleChildScrollView(
      primary: false,
      child: SafeArea(
        child: delayedContent
            ? DelayedVisibility(
                key: GlobalKey(), // Ensure we reset the delay on rebuild
                delay: const Duration(milliseconds: 400),
                child: content,
              )
            : content,
      ),
    );
  }

  Scaffold _buildScaffold(
      BuildContext context, bool hasDrawer, bool hasRail, bool hasManage) {
    var body = _buildMainContent(context, hasManage);
    if (centered) {
      body = Center(child: body);
    }
    if (onFileDropped != null) {
      body = FileDropTarget(
        onFileDropped: onFileDropped!,
        overlay: fileDropOverlay!,
        child: body,
      );
    }
    if (hasRail || hasManage) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasRail)
            SizedBox(
              width: 72,
              child: SingleChildScrollView(
                child: NavigationContent(
                  key: _navKey,
                  shouldPop: false,
                  extended: false,
                ),
              ),
            ),
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
              (detailViewBuilder != null || keyActionsBuilder != null))
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      if (detailViewBuilder != null)
                        detailViewBuilder!(context),
                      if (keyActionsBuilder != null)
                        keyActionsBuilder!(context),
                    ],
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
        scrolledUnderElevation: 0.0,
        leadingWidth: hasRail ? 84 : null,
        leading: hasRail
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: DrawerButton(),
                  )),
                  SizedBox(width: 12),
                ],
              )
            : null,
        actions: [
          if (actionButtonBuilder == null &&
              (keyActionsBuilder != null && !hasManage))
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
                        child: keyActionsBuilder!(context),
                      ),
                    ),
                  );
                },
                icon: keyActionsBadge
                    ? const Badge(
                        child: Icon(Icons.more_vert_outlined),
                      )
                    : const Icon(Icons.more_vert_outlined),
                iconSize: 24,
                tooltip: AppLocalizations.of(context)!.s_configure_yk,
                padding: const EdgeInsets.all(12),
              ),
            ),
          if (actionButtonBuilder != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: actionButtonBuilder!.call(context),
            ),
        ],
      ),
      drawer: hasDrawer ? _buildDrawer(context) : null,
      body: body,
    );
  }
}
