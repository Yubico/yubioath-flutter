/*
 * Copyright (C) 2023 Yubico.
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:yubico_authenticator/app/message.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_file_loader.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_pack_dialog.dart';
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
    final issuerWidget = issuerImageFile != null
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
    return IconButton(
      onPressed: () async {
        await showBlurDialog(
          context: context,
          builder: (context) => const IconPackDialog(),
        );
      },
      icon: issuerWidget,
      tooltip: 'Manage icons',
      padding: const EdgeInsets.all(1.0),
    );
  }
}
