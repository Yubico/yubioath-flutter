import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'message_page.dart';
import 'device_error_screen.dart';
import '../models.dart';
import '../state.dart';
import '../../fido/views/fido_screen.dart';
import '../../oath/views/oath_screen.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Function(BuildContext)?>(
      contextConsumer,
      (previous, next) {
        next?.call(context);
      },
    );
    // If the current device changes, we need to pop any open dialogs.
    ref.listen<AsyncValue<YubiKeyData>>(currentDeviceDataProvider, (_, __) {
      Navigator.of(context).popUntil((route) {
        return route.isFirst ||
            [
              'device_picker',
              'settings',
              'about',
              'licenses',
            ].contains(route.settings.name);
      });
    });

    final deviceNode = ref.watch(currentDeviceProvider);
    if (deviceNode == null) {
      return MessagePage(message: Platform.isAndroid ? 'Insert or tap your YubiKey' : 'Insert your YubiKey');
    } else {
      return ref.watch(currentDeviceDataProvider).when(
            data: (data) {
              final app = ref.watch(currentAppProvider);
              if (app.getAvailability(data) == Availability.unsupported) {
                return MessagePage(
                  header: 'Application not supported',
                  message: 'The used YubiKey does not support \'${app.name}\' application',
                );
              } else if (app.getAvailability(data) != Availability.enabled) {
                return MessagePage(
                  header: 'Application disabled',
                  message: 'Enable the \'${app.name}\' application on your YubiKey to access',
                );
              }

              switch (app) {
                case Application.oath:
                  return OathScreen(data.node.path);
                case Application.fido:
                  return FidoScreen(data);
                default:
                  return const MessagePage(
                    header: 'Not supported',
                    message: 'This application is not supported',
                  );
              }
            },
            loading: () => DeviceErrorScreen(deviceNode),
            error: (error, _) => DeviceErrorScreen(deviceNode, error: error),
          );
    }
  }
}
