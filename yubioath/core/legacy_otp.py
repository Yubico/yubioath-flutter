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

from .utils import time_challenge, parse_full, format_code
from .standard import TYPE_TOTP
from .exc import InvalidSlotError, NeedsTouchError
from yubioath.yubicommon.ctypes import load_library
from ctypes import (Structure, POINTER, c_int, c_uint8, c_uint, c_char_p,
                    sizeof, create_string_buffer, cast, addressof)
import weakref

_lib = load_library('ykpers-1', '1')
if not hasattr(_lib, 'yk_init'):
    raise ImportError('Can\'t find ykpers library')


def define(name, args, res):
    try:
        fn = getattr(_lib, name)
        fn.argtypes = args
        fn.restype = res
    except AttributeError:
        print "Undefined symbol: %s" % name

        def error(*args, **kwargs):
            raise Exception("Undefined symbol: %s" % name)
        fn = error
    return fn


SLOTS = [
    -1,
    0x30,
    0x38
]

YK_KEY = type('YK_KEY', (Structure,), {})

_yk_errno_location = define('_yk_errno_location', [], POINTER(c_int))
yk_init = define('yk_init', [], bool)
yk_release = define('yk_release', [], bool)
ykpers_check_version = define('ykpers_check_version', [c_char_p], c_char_p)

yk_open_first_key = define('yk_open_first_key', [], POINTER(YK_KEY))
yk_close_key = define('yk_close_key', [POINTER(YK_KEY)], bool)

yk_challenge_response = define('yk_challenge_response',
                               [POINTER(YK_KEY), c_uint8, c_int, c_uint,
                                c_char_p, c_uint, c_char_p], bool)

YK_ETIMEOUT = 0x04
YK_EWOULDBLOCK = 0x0b

if not yk_init():
    raise Exception("Unable to initialize ykpers")

ykpers_version = ykpers_check_version(None)


def yk_get_errno():
    return _yk_errno_location().contents.value


class YkWrapper(object):

    def __init__(self, key):
        self.key = key

    def __del__(self):
        yk_close_key(self.key)
        del self.key


class LegacyOathOtp(object):

    """
    OTP interface to a legacy OATH-enabled YubiKey.
    """

    def __init__(self, device):
        self._device = device

    def calculate(self, slot, digits=6, timestamp=None, mayblock=0):
        challenge = time_challenge(timestamp)
        resp = create_string_buffer(64)
        status = yk_challenge_response(self._device, SLOTS[slot], mayblock,
                                       len(challenge), challenge, sizeof(resp),
                                       resp)
        if not status:
            errno = yk_get_errno()
            if errno == YK_EWOULDBLOCK:
                raise NeedsTouchError()
            raise InvalidSlotError()
        return format_code(parse_full(resp.raw[:20]), digits)


class LegacyCredential(object):

    def __init__(self, legacy, slot, digits=6):
        self.name = 'YubiKey slot %d' % slot
        self.oath_type = TYPE_TOTP
        self._legacy = legacy
        self._slot = slot
        self._digits = digits

    def calculate(self, timestamp=None, mayblock=0):
        return self._legacy.calculate(self._slot, self._digits, timestamp,
                                      mayblock)

    def delete(self):
        raise NotImplementedError()

    def __repr__(self):
        return self.name


# Keep track of YK_KEY references.
_refs = []


def open_otp():
    key = yk_open_first_key()
    if key:
        key_p = cast(addressof(key.contents), POINTER(YK_KEY))

        def cb(ref):
            _refs.remove(ref)
            yk_close_key(key_p)
        _refs.append(weakref.ref(key, cb))
        return key
    return None
