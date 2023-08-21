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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:yubico_authenticator/core/state.dart';

import '../../widgets/delayed_visibility.dart';
import '../message.dart';
import 'keys.dart';
import 'navigation.dart';

// We use global keys here to maintain the NavigatorContent between AppPages.
final _navKey = GlobalKey();
final _navExpandedKey = GlobalKey();

class AppPage extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final Widget Function(BuildContext context)? keyActionsBuilder;
  final bool keyActionsBadge;
  final bool centered;
  final bool delayedContent;
  final Widget Function(BuildContext context)? actionButtonBuilder;
  const AppPage({
    super.key,
    this.title,
    required this.child,
    this.actions = const [],
    this.centered = false,
    this.keyActionsBuilder,
    this.actionButtonBuilder,
    this.delayedContent = false,
    this.keyActionsBadge = false,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final bool singleColumn;
          final bool hasRail;
          if (isAndroid) {
            final isPortrait = constraints.maxWidth < constraints.maxHeight;
            singleColumn = isPortrait || constraints.maxWidth < 600;
            hasRail = constraints.maxWidth > 600;
          } else {
            singleColumn = constraints.maxWidth < 600;
            hasRail = constraints.maxWidth > 400;
          }

          if (singleColumn) {
            // Single column layout, maybe with rail
            return _buildScaffold(context, true, hasRail);
          } else {
            // Fully expanded layout
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
                    child: _buildScaffold(context, false, false),
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
            NavigationContent(key: _navExpandedKey, extended: true),
          ],
        ),
      ),
    ));
  }

  Widget _buildMainContent() {
    final content = Column(
      children: [
        child,
        if (actions.isNotEmpty)
          Align(
            alignment: centered ? Alignment.center : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Wrap(
                spacing: 4,
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
        child: Center(
          child: SizedBox(
            width: 700,
            child: delayedContent
                ? DelayedVisibility(
                    key: GlobalKey(), // Ensure we reset the delay on rebuild
                    delay: const Duration(milliseconds: 400),
                    child: content,
                  )
                : content,
          ),
        ),
      ),
    );
  }

  Scaffold _buildScaffold(BuildContext context, bool hasDrawer, bool hasRail) {
    var body =
        centered ? Center(child: _buildMainContent()) : _buildMainContent();
    if (hasRail) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      key: scaffoldGlobalKey,
      appBar: AppBar(
        title: title,
        titleSpacing: hasDrawer ? 2 : 8,
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
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
          if (actionButtonBuilder == null && keyActionsBuilder != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                key: actionsIconButtonKey,
                onPressed: () {
                  showBlurDialog(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: keyActionsBuilder!,
                  );
                },
                icon: keyActionsBadge
                    ? const Badge(
                        child: Icon(Icons.tune),
                      )
                    : const Icon(Icons.tune),
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
