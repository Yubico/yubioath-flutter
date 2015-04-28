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

from ctypes import (Structure, POINTER, c_int, c_uint8, c_uint, c_char_p,
                    sizeof, create_string_buffer)
from yubioath.core.libloader import load_library

_lib = load_library('ykpers-1', '1')


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

yk_init = define('yk_init', [], c_int)
yk_release = define('yk_release', [], c_int)

yk_open_first_key = define('yk_open_first_key', [], POINTER(YK_KEY))
yk_close_key = define('yk_close_key', [POINTER(YK_KEY)], c_int)

yk_challenge_response = define('yk_challenge_response',
                               [POINTER(YK_KEY), c_uint8, c_int, c_uint,
                                c_char_p, c_uint, c_char_p],
                               c_int)

if not yk_init():
    raise Exception("Unable to initialize ykpers")


def read_challenge(challenge, slot=1, mayblock=0):
    dev = yk_open_first_key()
    resp = create_string_buffer(64)
    rc = yk_challenge_response(dev, SLOTS[slot], mayblock, len(challenge),
                               challenge, sizeof(resp), resp)
    yk_close_key(dev)
    if rc != 1:
        raise Exception(rc)
    return resp.raw[:20]
