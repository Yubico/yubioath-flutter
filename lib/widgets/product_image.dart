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

import 'package:flutter/material.dart';

import '../management/models.dart';

const _imagesForName = {
  'YubiKey 4': 'yk4series',
  'YubiKey Edge': 'ykedge',
  'YubiKey Plus': 'ykplus',
  'YubiKey 5A': 'yk4',
  'FIDO U2F Security Key': 'sky1',
  'Security Key by Yubico': 'sky2',
  'Security Key NFC': 'sky3',
  'Security Key C NFC': 'skycnfc',
  'YubiKey NEO': 'neo',
  'YubiKey Standard': 'standard',
};

const _imagesForFormFactor = {
  FormFactor.usbAKeychain: 'yk4',
  FormFactor.usbANano: 'yk5nano',
  FormFactor.usbCKeychain: 'yk5c',
  FormFactor.usbCNano: 'yk5cnano',
  FormFactor.usbCLightning: 'yk5ci',
  FormFactor.usbABio: 'ykbioa',
  FormFactor.usbCBio: 'ykbioc',
};

const _imagesForFormFactorNfc = {
  FormFactor.usbAKeychain: 'yk5nfc',
  FormFactor.usbCKeychain: 'yk5cnfc',
};

class ProductImage extends StatelessWidget {
  final String name;
  final FormFactor formFactor;
  final bool isNfc;

  const ProductImage(
      {super.key,
      required this.name,
      required this.formFactor,
      required this.isNfc});

  @override
  Widget build(BuildContext context) {
    var image = _imagesForName[name];
    image ??= isNfc
        ? _imagesForFormFactorNfc[formFactor]
        : _imagesForFormFactor[formFactor];
    image ??= Theme.of(context).brightness == Brightness.dark
        ? 'generic_dark'
        : 'generic';

    return Image.asset(
      'assets/product-images/$image.png',
      // Medium provides the best results when scaling down
      filterQuality: FilterQuality.medium,
    );
  }
}
