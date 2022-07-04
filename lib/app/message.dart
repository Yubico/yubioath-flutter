import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'state.dart';

ScaffoldFeatureController showMessage(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 1),
}) {
  final width = MediaQuery.of(context).size.width;
  final narrow = width < 540;
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: duration,
    behavior: narrow ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
    width: narrow ? null : 400,
  ));
}

Future<void> showBottomMenu(
    BuildContext context, List<MenuAction> actions) async {
  MediaQuery? mediaQuery = context.findAncestorWidgetOfExactType<MediaQuery>();
  var width = mediaQuery?.data.size.width ?? 0;
  await showModalBottomSheet(
      context: context,
      constraints: width > 540 ? const BoxConstraints(maxWidth: 380) : null,
      builder: (context) => SafeArea(child: _BottomMenu(actions)));
}

class _BottomMenu extends ConsumerWidget {
  final List<MenuAction> actions;
  const _BottomMenu(this.actions);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .map((a) => ListTile(
                leading: a.icon,
                title: Text(a.text),
                enabled: a.action != null,
                onTap: a.action == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        a.action?.call(context);
                      },
              ))
          .toList(),
    );
  }
}

Future<T?> showBlurDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  RouteSettings? routeSettings,
}) =>
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black12,
      pageBuilder: (ctx, anim1, anim2) => builder(ctx),
      transitionDuration: const Duration(milliseconds: 150),
      transitionBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      ),
      routeSettings: routeSettings,
    );
