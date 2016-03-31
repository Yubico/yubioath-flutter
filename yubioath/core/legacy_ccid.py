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

from .exc import CardError, InvalidSlotError, NeedsTouchError
from .utils import (format_code, parse_full, time_challenge)

YKLEGACY_AID = b'\xa0\x00\x00\x05\x27\x20\x01'

INS_CHALRESP = 0x01

SLOTS = [
    -1,
    0x30,
    0x38
]


class LegacyOathCcid(object):

    """
    CCID interface to a legacy OATH-enabled YubiKey.
    """

    def __init__(self, device):
        self._device = device

        self._select()

    def _send(self, ins, data='', p1=0, p2=0, expected=0x9000):
        resp, status = self._device.send_apdu(0, ins, p1, p2, data)
        if expected != status:
            raise CardError(status)
        return resp

    def _select(self):
        self._send(0xa4, YKLEGACY_AID, p1=0x04)

    def calculate(self, slot, digits=6, timestamp=None, mayblock=0):
        data = time_challenge(timestamp)
        try:
            resp = self._send(INS_CHALRESP, data, p1=SLOTS[slot])
        except CardError as e:
            if e.status == 0x6985:
                raise NeedsTouchError()
            raise
        if not resp:
            raise InvalidSlotError()
        return format_code(parse_full(resp), digits)
