# Copyright (c) 2014 Yubico AB
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Additional permission under GNU GPL version 3 section 7
#
# If you modify this program, or any covered work, by linking or
# combining it with the OpenSSL project's OpenSSL library (or a
# modified version of that library), containing parts covered by the
# terms of the OpenSSL or SSLeay licenses, We grant you additional
# permission to convey the resulting work. Corresponding Source for a
# non-source form of such a combination shall include the source code
# for the parts of OpenSSL used as well as that of the covered work.

from smartcard.System import readers
from yubioath.core.utils import (der_read, der_pack, hmac_sha1, derive_key,
                                 get_random_bytes)

YKOATH_AID = 'a000000527210101'.decode('hex')

INS_SET_CODE = 0x03
INS_VALIDATE = 0xa3

TAG_NAME = 0x71
TAG_KEY = 0x73
TAG_CHALLENGE = 0x74
TAG_RESPONSE = 0x75
TAG_VERSION = 0x79

TYPE_MASK = 0xf0
TYPE_HOTP = 0x10
TYPE_TOTP = 0x20

ALG_MASK = 0x0f
ALG_SHA1 = 0x01
ALG_SHA256 = 0x02


class CardError(Exception):

    def __init__(self, status, message=''):
        super(CardError, self).__init__('Card Error (%04x): %s' %
                                        (status, message))


class DeviceLockedError(Exception):

    def __init__(self):
        super(DeviceLockedError, self).__init__('Device is locked!')


class ScardDevice(object):

    """
    Pyscard based backend.
    """

    def __init__(self, reader):
        self.reader = reader

    def send_apdu(self, cl, ins, p1, p2, data):
        header = [cl, ins, p1, p2, len(data)]
        print "SEND:", (''.join(map(chr, header)) + data).encode('hex')
        resp, sw1, sw2 = self.reader.transmit(header + map(ord, data))
        print "RECV:", (''.join(map(chr, resp))).encode('hex')
        return ''.join(map(chr, resp)), sw1 << 8 | sw2

    def __del__(self):
        self.reader.disconnect()


def ensure_unlocked(ykoath):
    if ykoath.locked:
        raise DeviceLockedError()


class YubiOath(object):

    """
    Device interface to a OATH-enabled YubiKey.
    """

    def __init__(self, device):
        self._device = device

        self._select()

    def _send(self, ins, data, p1=0, p2=0, expected=0x9000):
        resp, status = self._device.send_apdu(0, ins, p1, p2, data)
        if expected != status:
            raise CardError(status)
        return resp

    def _select(self):
        resp = self._send(0xa4, YKOATH_AID, p1=0x04)
        self._version, resp = der_read(resp, TAG_VERSION)
        self._id, resp = der_read(resp, TAG_NAME)
        if len(resp) != 0:
            self._challenge, resp = der_read(resp, TAG_CHALLENGE)
        else:
            self._challenge = None

    @property
    def id(self):
        return self._id

    @property
    def version(self):
        return tuple(map(ord, self._version))

    @property
    def locked(self):
        return self._challenge is not None

    def calculate_key(self, passphrase):
        return derive_key(self.id, passphrase)

    def unlock(self, key):
        if not self.locked:
            return

        response = hmac_sha1(key, self._challenge)
        challenge = get_random_bytes(8)
        verification = hmac_sha1(key, challenge)

        data = der_pack(TAG_RESPONSE, response, TAG_CHALLENGE, challenge)
        resp = self._send(INS_VALIDATE, data)
        resp = der_read(resp, TAG_RESPONSE)[0]
        if resp != verification:
            raise ValueError('Response did not match verification!')
        self._challenge = None

    def set_key(self, key=''):
        ensure_unlocked(self)
        if key:
            keydata = chr(TYPE_TOTP | ALG_SHA1) + key
            challenge = get_random_bytes(8)
            response = hmac_sha1(key, challenge)
            data = der_pack(TAG_KEY, keydata, TAG_CHALLENGE, challenge,
                            TAG_RESPONSE, response)
        else:
            data = der_pack(TAG_KEY, '')
        self._send(INS_SET_CODE, data)


def open_scard(name='YubiKey'):
    name = name.lower()
    for reader in readers():
        if name in reader.name.lower():
            conn = reader.createConnection()
            conn.connect()
            return YubiOath(ScardDevice(conn))
