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

DEFAULT_DIGITS = 6
ALLOWED_DIGITS = [6, 7, 8]

ALG_MASK = 0x0f
ALG_SHA1 = 0x01
ALG_SHA256 = 0x02

PROP_ALWAYS_INC = 0x01
PROP_REQUIRE_TOUCH = 0x02

SCHEME_STANDARD = 0x00
SCHEME_STEAM = 0x01

STEAM_CHAR_TABLE = "23456789BCDFGHJKMNPQRTVWXY"
