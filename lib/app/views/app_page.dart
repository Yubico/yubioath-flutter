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

import 'device_button.dart';
import 'keys.dart';
import 'main_drawer.dart';

class AppPage extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final List<PopupMenuEntry> keyActions;
  final bool centered;
  final Widget Function(List<PopupMenuEntry>)? actionButtonBuilder;
  const AppPage({
    super.key,
    this.title,
    required this.child,
    this.actions = const [],
    this.keyActions = const [],
    this.centered = false,
    this.actionButtonBuilder,
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
    return SingleChildScrollView(
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: 700,
            child: Column(
              children: [
                child,
                if (actions.isNotEmpty)
                  Align(
                    alignment:
                        centered ? Alignment.center : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 18.0),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: actions,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Scaffold _buildScaffold(BuildContext context, bool hasDrawer) {
    return Scaffold(
      key: scaffoldGlobalKey,
      appBar: AppBar(
        titleSpacing: 8,
        title: title,
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: actionButtonBuilder?.call(keyActions) ??
                DeviceButton(actions: keyActions),
          ),
        ],
      ),
      drawer: hasDrawer ? const MainPageDrawer() : null,
      body: centered ? Center(child: _buildScrollView()) : _buildScrollView(),
    );
  }
}
