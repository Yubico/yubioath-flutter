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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state.dart';
import '../message.dart';
import '../state.dart';
import 'device_avatar.dart';
import 'device_picker_dialog.dart';
import 'device_utils.dart';
import 'keys.dart';

class _CircledDeviceAvatar extends ConsumerWidget {
  final double radius;
  const _CircledDeviceAvatar(this.radius);

  @override
  Widget build(BuildContext context, WidgetRef ref) => CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: IconTheme(
          // Force the standard icon theme
          data: IconTheme.of(context),
          child: DeviceAvatar.currentDevice(ref, radius: radius - 1),
        ),
      );
}

class DeviceButton extends ConsumerWidget {
  final double radius;
  final List<PopupMenuEntry> actions;
  const DeviceButton({super.key, this.actions = const [], this.radius = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'More actions',
      icon: _CircledDeviceAvatar(radius),
      onPressed: () {
        final withContext = ref.read(withContextProvider);

        showMenu(
          context: context,
          position: const RelativeRect.fromLTRB(100, 0, 0, 0),
          items: <PopupMenuEntry>[
            PopupMenuItem(
              padding: const EdgeInsets.only(left: 11, right: 16),
              onTap: isDesktop
                  ? () {
                      // Wait for menu to close, and use the main context to open
                      Timer.run(() {
                        withContext(
                          (context) async {
                            await showBlurDialog(
                              context: context,
                              builder: (context) => const DevicePickerDialog(),
                              routeSettings:
                                  const RouteSettings(name: 'device_picker'),
                            );
                          },
                        );
                      });
                    }
                  : null,
              child: _SlideInWidget(radius: radius),
            ),
            if (actions.isNotEmpty) const PopupMenuDivider(),
            ...actions,
          ],
        );
      },
    );
  }
}

class _SlideInWidget extends ConsumerStatefulWidget {
  final double radius;
  const _SlideInWidget({required this.radius});

  @override
  ConsumerState<_SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends ConsumerState<_SlideInWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  )..forward();
  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(0.9, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  ));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = getDeviceMessages(
      ref.watch(currentDeviceProvider),
      ref.watch(currentDeviceDataProvider),
    );
    return SlideTransition(
      position: _offsetAnimation,
      child: ListTile(
        key: deviceInfoListTile,
        dense: true,
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 0,
        horizontalTitleGap: 13,
        leading: _CircledDeviceAvatar(widget.radius),
        title: Text(messages.removeAt(0)),
        subtitle: Text(messages.first),
      ),
    );
  }
}
