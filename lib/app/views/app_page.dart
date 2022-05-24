import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_button.dart';
import 'main_drawer.dart';

class AppPage extends ConsumerWidget {
  final Key _scaffoldKey = GlobalKey();
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final bool centered;
  AppPage({
    super.key,
    this.title,
    required this.child,
    this.actions = const [],
    this.centered = false,
  });

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
                    width: 280,
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
          child: Builder(builder: (context) {
            return Column(
              children: [
                child,
                if (actions.isNotEmpty)
                  Align(
                    alignment:
                        centered ? Alignment.center : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: actions,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      );

  Scaffold _buildScaffold(BuildContext context, WidgetRef ref, bool hasDrawer) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 8,
        title: title,
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: const [DeviceButton()],
      ),
      drawer: hasDrawer ? const MainPageDrawer() : null,
      body: centered ? Center(child: _buildScrollView()) : _buildScrollView(),
    );
  }
}
