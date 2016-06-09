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

from __future__ import print_function, division

from .exc import CardError, DeviceLockedError, NoSpaceError
from .utils import (der_read, der_pack, hmac_sha1, derive_key, get_random_bytes,
                    time_challenge, parse_truncated, format_code)
from yubioath.yubicommon.compat import int2byte, byte2int
import hashlib
import struct
import os

YKOATH_AID = b'\xa0\x00\x00\x05\x27\x21\x01\x01'
YKOATH_NO_SPACE = 0x6a84

INS_PUT = 0x01
INS_DELETE = 0x02
INS_SET_CODE = 0x03
INS_RESET = 0x04
INS_LIST = 0xa1
INS_CALCULATE = 0xa2
INS_VALIDATE = 0xa3
INS_CALC_ALL = 0xa4
INS_SEND_REMAINING = 0xa5

RESP_MORE_DATA = 0x61

TAG_NAME = 0x71
TAG_NAME_LIST = 0x72
TAG_KEY = 0x73
TAG_CHALLENGE = 0x74
TAG_RESPONSE = 0x75
TAG_T_RESPONSE = 0x76
TAG_NO_RESPONSE = 0x77
TAG_PROPERTY = 0x78
TAG_VERSION = 0x79
TAG_IMF = 0x7a
TAG_ALGO = 0x7b
TAG_TOUCH_RESPONSE = 0x7c

TYPE_MASK = 0xf0
TYPE_HOTP = 0x10
TYPE_TOTP = 0x20

ALG_MASK = 0x0f
ALG_SHA1 = 0x01
ALG_SHA256 = 0x02

PROP_ALWAYS_INC = 0x01
PROP_REQUIRE_TOUCH = 0x02

SCHEME_STANDARD = 0x00
SCHEME_STEAM = 0x01

STEAM_CHAR_TABLE = "23456789BCDFGHJKMNPQRTVWXY"


def format_code_steam(int_data, digits):
    chars = []
    for i in range(5):
        chars.append(STEAM_CHAR_TABLE[int_data % len(STEAM_CHAR_TABLE)])
        int_data //= len(STEAM_CHAR_TABLE)
    return ''.join(chars)


def ensure_unlocked(ykoath):
    if ykoath.locked:
        raise DeviceLockedError()


def format_truncated(t_resp, scheme=SCHEME_STANDARD):
    digits, data = byte2int(t_resp[0]), t_resp[1:]
    int_data = parse_truncated(data)
    if scheme == SCHEME_STANDARD:
        return format_code(int_data, digits)
    elif scheme == SCHEME_STEAM:
        return format_code_steam(int_data, digits)


def hmac_shorten_key(key, algo):
    if algo == ALG_SHA1:
        h = hashlib.sha1()
    elif algo == ALG_SHA256:
        h = hashlib.sha256()
    else:
        raise ValueError('Unsupported algorithm!')

    if len(key) > h.block_size:
        key = h.update(key).digest()

    return key


class Credential(object):
    """
    Reference to a credential.
    """

    def __init__(self, ykoath, oath_type, name, touch=False):
        self._ykoath = ykoath
        self.oath_type = oath_type
        self.name = name
        self.touch = touch

    def calculate(self, timestamp=None):
        return self._ykoath.calculate(self.name, self.oath_type, timestamp)

    def delete(self):
        self._ykoath.delete(self.name)

    def __repr__(self):
        return self.name


class _426Device(object):
    """
    The 4.2.0-4.2.6 firmwares have a known issue with credentials that require
    touch: If this action is performed within 2 seconds of a command resulting
    in a long response (over 54 bytes), the command will hang. A workaround is
    to send an invalid command (resulting in a short reply) prior to the
    "calculate" command.
    """

    def __init__(self, delegate):
        self._delegate = delegate
        self._long_resp = False

    def __getattr__(self, name):
        return getattr(self._delegate, name)

    def send_apdu(self, cl, ins, p1, p2, data):
        if ins == INS_CALCULATE and self._long_resp:
            self._delegate.send_apdu(0, 0, 0, 0, '')
            self._long_resp = False
        resp, status = self._delegate.send_apdu(cl, ins, p1, p2, data)
        self._long_resp = len(resp) > 52  # 52 bytes resp, 2 bytes status...
        return resp, status


class YubiOathCcid(object):

    """
    Device interface to a OATH-enabled YubiKey.
    """

    def __init__(self, device):
        self._device = device

        self._select()

        if (4, 2, 0) <= self.version <= (4, 2, 6):
            self._device = _426Device(device)

    def _send(self, ins, data='', p1=0, p2=0, expected=0x9000):
        resp, status = self._device.send_apdu(0, ins, p1, p2, data)
        while (status >> 8) == RESP_MORE_DATA:
            more, status = self._device.send_apdu(
                0, INS_SEND_REMAINING, 0, 0, '')
            resp += more

        if status == YKOATH_NO_SPACE:
            raise NoSpaceError()

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
        return tuple(byte2int(d) for d in self._version)

    @property
    def locked(self):
        return self._challenge is not None

    def delete(self, name):
        data = der_pack(TAG_NAME, name.encode('utf8'))
        self._send(INS_DELETE, data)

    def calculate(self, name, oath_type, timestamp=None):
        challenge = time_challenge(timestamp) if oath_type == TYPE_TOTP else ''
        data = der_pack(TAG_NAME, name.encode('utf8'), TAG_CHALLENGE, challenge)
        resp = self._send(INS_CALCULATE, data)
        # Manual dynamic truncation required for Steam entries
        resp = der_read(resp, TAG_RESPONSE)[0]
        digits, resp = resp[0:1], resp[1:]
        offset = byte2int(resp[-1]) & 0xF
        resp = resp[offset:offset + 4]
        scheme = SCHEME_STEAM if name.startswith('Steam:') else SCHEME_STANDARD
        return format_truncated(digits + resp, scheme)

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

    def set_key(self, key=None):
        ensure_unlocked(self)
        if key:
            keydata = int2byte(TYPE_TOTP | ALG_SHA1) + key
            challenge = get_random_bytes(8)
            response = hmac_sha1(key, challenge)
            data = der_pack(TAG_KEY, keydata, TAG_CHALLENGE, challenge,
                            TAG_RESPONSE, response)
        else:
            data = der_pack(TAG_KEY, b'')
        self._send(INS_SET_CODE, data)

    def reset(self):
        self._send(INS_RESET, p1=0xde, p2=0xad)
        self._challenge = None

    def list(self):
        ensure_unlocked(self)
        resp = self._send(INS_LIST)
        items = []
        while resp:
            data, resp = der_read(resp, TAG_NAME_LIST)
            items.append(Credential(
                self,
                TYPE_MASK & byte2int(data[0]),
                data[1:],
                None
            ))
        return items

    def calculate_all(self, timestamp=None):
        ensure_unlocked(self)
        data = der_pack(TAG_CHALLENGE, time_challenge(timestamp))
        resp = self._send(INS_CALC_ALL, data, p2=1)
        results = []
        while resp:
            name, resp = der_read(resp, TAG_NAME)
            name = name.decode('utf8')
            tag, value, resp = der_read(resp)
            if name.startswith('_hidden:') and 'YKOATH_SHOW_HIDDEN' not in os.environ:
                pass  # Ignore hidden credentials.
            elif tag == TAG_T_RESPONSE:
                # Steam credentials need to be recalculated
                # to skip full truncation done by Yubikey 4.
                code = self.calculate(name, TYPE_TOTP) \
                        if name.startswith('Steam:') \
                        else format_truncated(value, SCHEME_STANDARD)
                results.append((
                    Credential(self, TYPE_TOTP, name, False),
                    code
                ))
            elif tag == TAG_TOUCH_RESPONSE:
                results.append((
                    Credential(self, TYPE_TOTP, name, True),
                    None
                ))
            elif tag == TAG_NO_RESPONSE:
                results.append((Credential(self, TYPE_HOTP, name), None))
            else:
                print("Unsupported tag: %02x" % tag)
        results.sort(key=lambda a: a[0].name.lower())
        return results

    def put(self, name, key, oath_type=TYPE_TOTP, algo=ALG_SHA1, digits=6,
            imf=0, always_increasing=False, require_touch=False):
        ensure_unlocked(self)
        key = hmac_shorten_key(key, algo)
        keydata = int2byte(oath_type | algo) + int2byte(digits) + key
        data = der_pack(TAG_NAME, name.encode('utf8'), TAG_KEY, keydata)
        properties = 0
        if always_increasing:
            properties |= PROP_ALWAYS_INC
        if require_touch:
            if self.version < (4, 2, 6):
                raise Exception("Touch-required not supported on this key")
            properties |= PROP_REQUIRE_TOUCH
        if properties:
            data += int2byte(TAG_PROPERTY) + int2byte(properties)
        if imf > 0:
            data += der_pack(TAG_IMF, struct.pack('>I', imf))
        self._send(INS_PUT, data)
        return Credential(self, oath_type, name)
