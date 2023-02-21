import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_file_loader.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_pack_manager.dart';
import 'package:yubico_authenticator/widgets/delayed_visibility.dart';

class AccountIcon extends ConsumerWidget {
  final String? issuer;
  final Widget defaultWidget;

  const AccountIcon({
    super.key,
    required this.issuer,
    required this.defaultWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconPack = ref.watch(iconPackManager).getIconPack();
    if (iconPack == null || issuer == null) {
      return defaultWidget;
    }

    final matching = iconPack.icons
        .where((element) => element.issuer.any((element) => element == issuer));
    final issuerImageFile = matching.isNotEmpty
        ? File('${iconPack.directory.path}${matching.first.filename}')
        : null;
    return issuerImageFile != null && issuerImageFile.existsSync()
        ? VectorGraphic(
            width: 40,
            height: 40,
            fit: BoxFit.fill,
            loader: IconFileLoader(ref, issuerImageFile),
            placeholderBuilder: (BuildContext _) {
              return DelayedVisibility(
                delay: const Duration(milliseconds: 10),
                child: Stack(alignment: Alignment.center, children: [
                  Opacity(
                    opacity: 0.5,
                    child: defaultWidget,
                  ),
                  const CircularProgressIndicator(),
                ]),
              );
            })
        : defaultWidget;
  }
}
