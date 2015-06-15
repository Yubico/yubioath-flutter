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

from smartcard import System
from smartcard.Exceptions import SmartcardException


class ScardDevice(object):

    """
    Pyscard based backend.
    """

    def __init__(self, connection):
        self._conn = connection

    def send_apdu(self, cl, ins, p1, p2, data):
        header = [cl, ins, p1, p2, len(data)]
        # print "SEND:", (''.join(map(chr, header)) + data).encode('hex')
        resp, sw1, sw2 = self._conn.transmit(header + map(ord, data))
        # print "RECV:", (''.join(map(chr, resp))).encode('hex')
        return ''.join(map(chr, resp)), sw1 << 8 | sw2

    def close(self):
        self._conn.disconnect()

    def __del__(self):
        self.close()


def open_scard(name='Yubikey'):
    name = name.lower()
    for reader in System.readers():
        if name in reader.name.lower():
            conn = reader.createConnection()
            try:
                conn.connect()
                return ScardDevice(conn)
            except SmartcardException:
                pass
