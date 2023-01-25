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

import '../../widgets/delayed_visibility.dart';
import '../message.dart';
import 'device_button.dart';
import 'keys.dart';
import 'main_drawer.dart';

class AppPage extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final Widget Function(BuildContext context)? keyActionsBuilder;
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
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 540) {
            // Single column layout
            return _buildScaffold(context, true);
          } else {
            // Two-column layout
            return Scaffold(
              body: Row(
                children: [
                  const SizedBox(
                    width: 280,
                    child: ListTileTheme(
                        style: ListTileStyle.drawer,
                        child: MainPageDrawer(shouldPop: false)),
                  ),
                  Expanded(
                    child: _buildScaffold(context, false),
                  ),
                ],
              ),
            );
          }
        },
      );

  Widget _buildScrollView() {
    final content = Column(
      children: [
        child,
        if (actions.isNotEmpty)
          Align(
            alignment: centered ? Alignment.center : Alignment.centerLeft,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 18.0),
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

  Scaffold _buildScaffold(BuildContext context, bool hasDrawer) {
    return Scaffold(
      key: scaffoldGlobalKey,
      appBar: AppBar(
        title: title,
        titleSpacing: hasDrawer ? 2 : 8,
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          if (actionButtonBuilder == null && keyActionsBuilder != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                key: actionsIconButtonKey,
                onPressed: () {
                  showBlurDialog(context: context, builder: keyActionsBuilder!);
                },
                icon: const Icon(Icons.tune),
                iconSize: 24,
                tooltip:
                    AppLocalizations.of(context)!.general_configure_yubikey,
                padding: const EdgeInsets.all(12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: actionButtonBuilder?.call(context) ?? const DeviceButton(),
          ),
        ],
      ),
      drawer: hasDrawer ? const MainPageDrawer() : null,
      body: centered ? Center(child: _buildScrollView()) : _buildScrollView(),
    );
  }
}
