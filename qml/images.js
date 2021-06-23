
var _images_for_name = {
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

var _images_for_form_factor = {
    1: 'yk4',
    2: 'yk5nano',
    3: 'yk5c',
    4: 'yk5cnano',
    5: 'yk5ci',
    6: 'ykbioa',
    7: 'ykbioc',
};

var _images_for_form_factor_nfc = {
    1: 'yk5nfc',
    3: 'yk5cnfc',
};

function getYubiKeyImageName(yubiKey) {
    var image = _images_for_name[yubiKey.name];
    if(image === undefined) {
        if(yubiKey.nfcAppSupported.length > 0) {
            image = _images_for_form_factor_nfc[yubiKey.formFactor]
        }
        if(image === undefined) {
            image = _images_for_form_factor[yubiKey.formFactor]
        }
    }
    return image || 'yk5series';
}
