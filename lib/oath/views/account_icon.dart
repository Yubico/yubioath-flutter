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
    final issuerImageFile = ref.watch(iconPackManager).getFileForIssuer(issuer);
    return issuerImageFile != null
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
