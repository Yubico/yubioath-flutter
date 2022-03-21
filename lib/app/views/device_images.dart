import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../management/models.dart';

const _imagesForName = {
  'YubiKey 4': 'yk4series',
  'YubiKey Edge': 'ykedge',
  'YubiKey Plus': 'ykplus',
  'YubiKey 5A': 'yk4',
  'FIDO U2F Security Key': 'sky1',
  'Security Key by Yubico': 'sky2',
  'Security Key NFC': 'sky3',
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

Image getProductImage(DeviceInfo info, String name) {
  var image = _imagesForName[name];
  image ??= info.supportedCapabilities.containsKey(Transport.nfc)
      ? _imagesForFormFactorNfc[info.formFactor]
      : _imagesForFormFactor[info.formFactor];
  image ??= 'yk5series';

  return Image.asset('assets/product-images/$image.png');
}
