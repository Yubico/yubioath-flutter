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

from ..core.controller import Controller
from ..core.standard import YubiOathCcid
from ..core.exc import CardError
from getpass import getpass
import sys


class CliController(Controller):

    def __init__(self, keystore, save=False):
        self.keystore = keystore
        self._save = save

    def _prompt_touch(self):
        sys.stderr.write('Touch your YubiKey...\n')

    def unlock(self, device):
        key = self.keystore.get(device.id)
        if key:
            try:
                device.unlock(key)
            except CardError:
                sys.stderr.write('Incorrect password from file.\n')
                self.keystore.delete(device.id)

        while device.locked:
            pw = getpass('Password: ')
            key = device.calculate_key(pw)
            try:
                device.unlock(key)
                if self._save:
                    self.keystore.put(device.id, key)
                    sys.stderr.write('Password saved to %s\n' %
                                     self.keystore.fname)
            except CardError:
                sys.stderr.write('Incorrect password!\n')

    def set_password(self, ccid_dev, password, remember=False):
        dev = YubiOathCcid(ccid_dev)
        key = super(CliController, self).set_password(dev, password)
        if remember:
            self.keystore.put(dev.id, key)
            sys.stderr.write('Password saved to %s\n' % self.keystore.fname)
        else:
            self.keystore.delete(dev.id)

    def add_cred(self, ccid_dev, *args, **kwargs):
        dev = YubiOathCcid(ccid_dev)
        super(CliController, self).add_cred(dev, *args, **kwargs)

    def delete_cred(self, ccid_dev, name):
        dev = YubiOathCcid(ccid_dev)
        super(CliController, self).delete_cred(dev, name)

    def reset_device(self, ccid_dev):
        dev = YubiOathCcid(ccid_dev)
        self.keystore.delete(dev.id)
        super(CliController, self).reset_device(dev)
