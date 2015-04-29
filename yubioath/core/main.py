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

from yubioath.core.ccid import open_scard
from yubioath.core.standard import YubiOathCcid, TYPE_TOTP
from yubioath.core.legacy_ccid import LegacyOathCcid
from yubioath.core.legacy_otp import open_otp, LegacyOathOtp
from yubioath.core.exc import CardError, InvalidSlotError
"""
Ideas:

Read from CCID yubioath first, then legacy CCID or OTP, when enabled.
Configure: which slot(s), digits.

{
    SLOT1: None/6/8
    SLOT2: None/6/8
}
"""


class LegacyCredential(object):

    def __init__(self, legacy, slot, digits=6):
        self.name = 'YubiKey slot %d' % slot
        self.oath_type = TYPE_TOTP
        self._legacy = legacy
        self._slot = slot
        self._digits = digits

    def calculate(self, timestamp=None):
        return self._legacy.calculate(self._slot, self._digits, timestamp)

    def delete(self):
        raise NotImplementedError()

    def __repr__(self):
        return self.name


def calculate_legacy(legacy, slot1=0, slot2=0, timestamp=None):
    results = []
    if slot1:
        cred = LegacyCredential(legacy, 1, slot1)
        try:
            results.append((cred, cred.calculate()))
        except InvalidSlotError:
            results.append((cred, 'INVALID'))
    if slot2:
        cred = LegacyCredential(legacy, 2, slot2)
        try:
            results.append((cred, cred.calculate()))
        except InvalidSlotError:
            results.append((cred, 'INVALID'))
    return results


def calculate_all(key=None, slot1=0, slot2=0, timestamp=None):
    results = []
    do_legacy = bool(slot1 or slot2)

    ccid_dev = open_scard()
    if ccid_dev:
        try:
            std = YubiOathCcid(ccid_dev)
            std.unlock(key)
            results.extend(std.calculate_all(timestamp))
        except CardError:
            pass  # No applet?

        if do_legacy:
            try:
                legacy = LegacyOathCcid(ccid_dev)
                do_legacy = False
                results = calculate_legacy(legacy, slot1, slot2, timestamp) +\
                    results
            except CardError:
                pass  # No applet?
        del ccid_dev

    if do_legacy:
        otp_dev = open_otp()
        if otp_dev:
            legacy = LegacyOathOtp(otp_dev)
            results = calculate_legacy(legacy, slot1, slot2, timestamp) +\
                results
            del otp_dev

    return results
