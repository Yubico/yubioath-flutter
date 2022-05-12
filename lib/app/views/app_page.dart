import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_button.dart';
import 'main_drawer.dart';

class AppPage extends ConsumerWidget {
  final Key _scaffoldKey = GlobalKey();
  final Widget? title;
  final Widget child;
  final Widget? floatingActionButton;
  final bool centered;
  AppPage(
      {super.key,
      this.title,
      required this.child,
      this.floatingActionButton,
      this.centered = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 540) {
            // Single column layout
            return _buildScaffold(context, ref, true);
          } else {
            // Two-column layout
            return Scaffold(
              body: Row(
                children: [
                  const SizedBox(
                    width: 240,
                    child: ListTileTheme(
                        style: ListTileStyle.drawer,
                        child: MainPageDrawer(shouldPop: false)),
                  ),
                  Expanded(
                    child: _buildScaffold(context, ref, false),
                  ),
                ],
              ),
            );
          }
        },
      );

  Widget _buildScrollView() => SafeArea(
        child: SingleChildScrollView(
          // Make sure FAB doesn't block content
          padding: floatingActionButton != null
              ? const EdgeInsets.only(bottom: 72)
              : null,
          child: child,
        ),
      );

  Scaffold _buildScaffold(BuildContext context, WidgetRef ref, bool hasDrawer) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: title,
        centerTitle: true,
        actions: const [DeviceButton()],
      ),
      drawer: hasDrawer ? const MainPageDrawer() : null,
      body: centered ? Center(child: _buildScrollView()) : _buildScrollView(),
      floatingActionButton: floatingActionButton,
    );
  }
}
