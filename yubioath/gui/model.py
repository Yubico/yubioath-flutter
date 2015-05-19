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

from yubioath.core.controller import Controller
from collections import namedtuple


class CredentialType:
    AUTO, HOTP, TOUCH, INVALID = range(4)


Code = namedtuple('Code', 'code expiry')


class Credential(object):

    def __init__(self, name, cred_type):
        self.name = name
        self.cred_type = cred_type


class AutoCredential(Credential):

    def __init__(self, name, code):
        super(AutoCredential, self).__init__(name, CredentialType.AUTO)
        self._code = code

    def calculate(self):
        return self._code

    def set_code(self, code):
        self._code = code


class TouchCredential(Credential):

    def __init__(self, name, slot, digits):
        super(TouchCredential, self).__init__(name, CredentialType.TOUCH)
        self._slot = slot
        self._digits = digits

    def calculate(self):
        pass  # TODO


class HotpCredential(Credential):

    def __init__(self, name):
        super(HotpCredential, self).__init__(name, CredentialType.HOTP)

    def calculate(self):
        pass  # TODO


def wrap_credential((cred, code)):
    if code == 'INVALID':
        return Credential(cred.name, CredentialType.INVALID)
    if code == 'TIMEOUT':
        return TouchCredential(cred.name, cred._slot, cred._digits)
    if code is None:
        return HotpCredential(cred.name)
    else:
        return AutoCredential(cred.name, code)


class GuiController(Controller):

    def __init__(self, reader_name, slot1=0, slot2=0):
        super(GuiController, self).__init__()
        self._reader_name = reader_name
        self._slot1 = slot1
        self._slot2 = slot2
        self._reader = None
        self._creds = None

    def read_slot_otp_touch(self, cred, timestamp):
        return (cred, 'TIMEOUT')

    @property
    def otp_enabled(self):
        return bool(self._slot1 or self._slot2)

    def calculate_all(self, ccid_dev, timestamp):
        read = self.read_creds(ccid_dev, self._slot1, self._slot2, timestamp)

        creds = map(wrap_credential, read)

        print "creds", creds
        return creds
