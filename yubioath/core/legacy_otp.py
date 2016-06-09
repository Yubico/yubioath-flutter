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

from __future__ import print_function

from .utils import time_challenge, parse_full, format_code
from .standard import TYPE_TOTP
from .exc import InvalidSlotError, NeedsTouchError
from yubioath.yubicommon.ctypes import CLibrary
from hashlib import sha1
from ctypes import (Structure, POINTER, c_int, c_uint8, c_uint, c_char_p,
                    c_bool, sizeof, create_string_buffer, cast, addressof)
import weakref


SLOTS = [
    -1,
    0x30,
    0x38
]

YK_KEY = type('YK_KEY', (Structure,), {})

# Programming
SLOT_CONFIG = 1
SLOT_CONFIG2 = 3
CONFIG1_VALID = 1
CONFIG2_VALID = 2

YKP_CONFIG = type('YKP_CONFIG', (Structure,), {})
YK_CONFIG = type('YK_CONFIG', (Structure,), {})
YK_STATUS = type('YK_STATUS', (Structure,), {})


class YkPers(CLibrary):
    _yk_errno_location = [], POINTER(c_int)
    yk_init = [], bool
    yk_release = [], bool
    ykpers_check_version = [c_char_p], c_char_p

    yk_open_first_key = [], POINTER(YK_KEY)
    yk_close_key = [POINTER(YK_KEY)], bool

    yk_challenge_response = [POINTER(YK_KEY), c_uint8, c_int, c_uint, c_char_p,
                             c_uint, c_char_p], bool

    ykds_alloc = [], POINTER(YK_STATUS)
    ykds_free = [POINTER(YK_STATUS)], None
    ykds_touch_level = [POINTER(YK_STATUS)], c_int
    yk_get_status = [POINTER(YK_KEY), POINTER(YK_STATUS)], c_int

    ykp_alloc = [], POINTER(YKP_CONFIG)
    ykp_free_config = [POINTER(YKP_CONFIG)], bool

    ykp_configure_version = [POINTER(YKP_CONFIG), POINTER(YK_STATUS)], None

    ykp_HMAC_key_from_raw = [POINTER(YKP_CONFIG), c_char_p], bool
    ykp_set_tktflag_CHAL_RESP = [POINTER(YKP_CONFIG), c_bool], bool
    ykp_set_cfgflag_CHAL_HMAC = [POINTER(YKP_CONFIG), c_bool], bool
    ykp_set_cfgflag_HMAC_LT64 = [POINTER(YKP_CONFIG), c_bool], bool
    ykp_set_extflag_SERIAL_API_VISIBLE = [POINTER(YKP_CONFIG), c_bool], bool
    ykp_set_extflag_ALLOW_UPDATE = [POINTER(YKP_CONFIG), c_bool], bool
    ykp_set_cfgflag_CHAL_BTN_TRIG = [POINTER(YKP_CONFIG), c_bool], bool

    ykp_core_config = [POINTER(YKP_CONFIG)], POINTER(YK_CONFIG)
    yk_write_command = [POINTER(YK_KEY), POINTER(YK_CONFIG), c_uint8, c_char_p
                        ], bool

    def yk_get_errno(self):
        return self._yk_errno_location().contents.value


ykpers = YkPers('ykpers-1', '1')


YK_ETIMEOUT = 0x04
YK_EWOULDBLOCK = 0x0b

if not ykpers.yk_init():
    raise Exception("Unable to initialize ykpers")

ykpers_version = ykpers.ykpers_check_version(None).decode('ascii')


class LegacyOathOtp(object):

    """
    OTP interface to a legacy OATH-enabled YubiKey.
    """

    def __init__(self, device):
        self._device = device

    def slot_status(self):
        st = ykpers.ykds_alloc()
        ykpers.yk_get_status(self._device, st)
        tl = ykpers.ykds_touch_level(st)
        ykpers.ykds_free(st)

        return (
            bool(tl & CONFIG1_VALID == CONFIG1_VALID),
            bool(tl & CONFIG2_VALID == CONFIG2_VALID)
        )

    def calculate(self, slot, digits=6, timestamp=None, mayblock=0):
        challenge = time_challenge(timestamp)
        resp = create_string_buffer(64)
        status = ykpers.yk_challenge_response(
            self._device, SLOTS[slot], mayblock, len(challenge), challenge,
            sizeof(resp), resp)
        if not status:
            errno = ykpers.yk_get_errno()
            if errno == YK_EWOULDBLOCK:
                raise NeedsTouchError()
            raise InvalidSlotError()
        return format_code(parse_full(resp.raw[:20]), digits)

    def put(self, slot, key, require_touch=False):
        if len(key) > 64:  # Keys longer than 64 bytes are hashed, as per HMAC.
            key = sha1(key).digest()
        if len(key) > 20:
            raise ValueError('YubiKey slots cannot handle keys over 20 bytes')
        slot = SLOT_CONFIG if slot == 1 else SLOT_CONFIG2
        key += b'\x00' * (20 - len(key))  # Keys must be padded to 20 bytes.

        st = ykpers.ykds_alloc()
        ykpers.yk_get_status(self._device, st)
        cfg = ykpers.ykp_alloc()
        ykpers.ykp_configure_version(cfg, st)
        ykpers.ykds_free(st)
        ykpers.ykp_set_tktflag_CHAL_RESP(cfg, True)
        ykpers.ykp_set_cfgflag_CHAL_HMAC(cfg, True)
        ykpers.ykp_set_cfgflag_HMAC_LT64(cfg, True)
        ykpers.ykp_set_extflag_SERIAL_API_VISIBLE(cfg, True)
        ykpers.ykp_set_extflag_ALLOW_UPDATE(cfg, True)
        if require_touch:
            ykpers.ykp_set_cfgflag_CHAL_BTN_TRIG(cfg, True)

        if ykpers.ykp_HMAC_key_from_raw(cfg, key):
            raise ValueError("Error setting the key")

        ycfg = ykpers.ykp_core_config(cfg)
        try:
            if not ykpers.yk_write_command(self._device, ycfg, slot, None):
                raise ValueError("Error writing configuration to key")
        finally:
            ykpers.ykp_free_config(cfg)

    def delete(self, slot):
        slot = SLOT_CONFIG if slot == 1 else SLOT_CONFIG2
        if not ykpers.yk_write_command(self._device, None, slot, None):
            raise ValueError("Error writing configuration to key")


class LegacyCredential(object):

    def __init__(self, legacy, slot, digits=6):
        self.name = 'YubiKey slot %d' % slot
        self.oath_type = TYPE_TOTP
        self.touch = None  # Touch is unknown
        self._legacy = legacy
        self._slot = slot
        self._digits = digits

    def calculate(self, timestamp=None):
        try:
            return self._legacy.calculate(self._slot, self._digits, timestamp,
                                          1 if self.touch else 0)
        except NeedsTouchError:
            self.touch = True
            raise
        else:
            if self.touch is None:
                self.touch = False

    def delete(self):
        self._legacy.delete(self._slot)

    def __repr__(self):
        return self.name


# Keep track of YK_KEY references.
_refs = []


def open_otp():
    key = ykpers.yk_open_first_key()
    if key:
        key_p = cast(addressof(key.contents), POINTER(YK_KEY))

        def cb(ref):
            _refs.remove(ref)
            ykpers.yk_close_key(key_p)
        _refs.append(weakref.ref(key, cb))
        return key
    return None
