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

import 'dart:async';
import 'dart:io';
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
      transitionBuilder: (ctx, anim1, anim2, child) {
        var sigma = 20 * anim1.value;
        // Flutter 3.3 has an issue with rendering this on Android.
        // Workaround: Don't animate the un-blur.
        if (Platform.isAndroid && anim1.status == AnimationStatus.reverse) {
          sigma = 0;
        }
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
      routeSettings: routeSettings,
    );
