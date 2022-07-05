import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/toast.dart';
import 'models.dart';

void Function() showMessage(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) =>
    showToast(context, message, duration: duration);

Future<void> showBottomMenu(
    BuildContext context, List<MenuAction> actions) async {
  await showBlurDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Options'),
          contentPadding: const EdgeInsets.only(bottom: 24, top: 4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: actions
                .map((a) => ListTile(
                      leading: a.icon,
                      title: Text(a.text),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      enabled: a.action != null,
                      onTap: a.action == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              a.action?.call(context);
                            },
                    ))
                .toList(),
          ),
        );
      });
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
        filter: ImageFilter.blur(
            sigmaX: 20 * anim1.value, sigmaY: 20 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      ),
      routeSettings: routeSettings,
    );
