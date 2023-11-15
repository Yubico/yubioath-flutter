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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_cache.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_file_loader.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_pack.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_pack_manager.dart';
import 'package:yubico_authenticator/widgets/delayed_visibility.dart';

class AccountIcon extends ConsumerWidget {
  final String? issuer;
  final Widget defaultWidget;

  static const double _width = 40;
  static const double _height = 40;

  const AccountIcon({
    super.key,
    required this.issuer,
    required this.defaultWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconPack = ref.watch(iconPackManagerProvider);
    return iconPack.when(
        data: (IconPack? iconPack) {
          final issuerImageFile = iconPack?.getFileForIssuer(issuer);
          if (issuerImageFile == null) {
            return defaultWidget;
          }

          return switch (extension(issuerImageFile.path)) {
            '.svg' =>
              _DecodedSvg(issuerImageFile, defaultWidget, _width, _height),
            '.jpg' || '.png' => _DecodedRasterImage(
                issuerImageFile, defaultWidget, _width, _height),
            _ => defaultWidget
          };
        },
        error: (_, __) => defaultWidget,
        loading: () => defaultWidget);
  }
}

class _AccountIconClipper extends CustomClipper<Rect> {
  final double _width;
  final double _height;

  _AccountIconClipper(this._width, this._height);

  @override
  Rect getClip(Size size) {
    return Rect.fromCenter(
        center: Offset(_width / 2, _height / 2),
        // make the rect smaller to hide artifacts
        width: _width - 1,
        height: _height - 1);
  }

  @override
  bool shouldReclip(oldClipper) {
    return true;
  }
}

class _DecodedSvg extends ConsumerWidget {
  final File _file;
  final double _width;
  final double _height;
  final Widget _defaultWidget;

  const _DecodedSvg(this._file, this._defaultWidget, this._width, this._height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconCache = ref.watch(iconCacheProvider);
    return VectorGraphic(
        width: _width,
        height: _height,
        fit: BoxFit.fill,
        loader: IconFileLoader(iconCache, _file),
        placeholderBuilder: (BuildContext _) {
          return DelayedVisibility(
            delay: const Duration(milliseconds: 10),
            child: Stack(alignment: Alignment.center, children: [
              Opacity(
                opacity: 0.5,
                child: _defaultWidget,
              ),
              const CircularProgressIndicator(),
            ]),
          );
        });
  }
}

class _DecodedRasterImage extends ConsumerWidget {
  final File _file;
  final double _width;
  final double _height;
  final Widget _defaultWidget;

  const _DecodedRasterImage(
      this._file, this._defaultWidget, this._width, this._height);

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClipOval(
        // This clipper makes the oval small enough to hide artifacts
        // on the oval border for images not supporting transparency.
        clipper: _AccountIconClipper(_width, _height),
        child: Image.file(
          _file,
          filterQuality: FilterQuality.medium,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          width: _width,
          height: _height,
          errorBuilder: (_, __, ___) => _defaultWidget,
        ),
      );
}
