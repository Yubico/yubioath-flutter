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

import os
import json
from binascii import b2a_hex, a2b_hex

CONFIG_HOME = os.path.join(os.path.expanduser('~'), '.yubioath')
KEY_FILE = os.path.join(CONFIG_HOME, 'keys.json')


def get_keystore():
    return Keystore(KEY_FILE)


def _to_hex(val):
    return b2a_hex(val).decode('ascii')


class Keystore(object):

    def __init__(self, fname):
        self.fname = fname
        self._data = {}
        if os.path.isfile(fname):
            with open(fname) as f:
                try:
                    data = json.load(f)
                    if isinstance(data, dict):
                        self._data = data
                except ValueError:
                    pass

    def get(self, id):
        key = _to_hex(id)
        if key in self._data:
            return a2b_hex(self._data[key])
        return None

    def put(self, id, key):
        if not key:
            self.delete(id)
        else:
            self._data[_to_hex(id)] = _to_hex(key)
            self._save()

    def delete(self, id):
        key = _to_hex(id)
        if key in self._data:
            del self._data[key]
            self._save()

    def _save(self):
        directory = os.path.dirname(self.fname)
        if not os.path.isdir(directory):
            os.makedirs(directory)
        with open(self.fname, 'w') as f:
            json.dump(self._data, f)

    def clear(self):
        if os.path.isfile(self.fname):
            os.remove(self.fname)
