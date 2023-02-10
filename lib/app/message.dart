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
                      enabled: a.intent != null,
                      onTap: a.intent == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              Actions.invoke(context, a.intent!);
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
