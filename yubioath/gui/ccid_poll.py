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

from .ccid import CardStatus
from smartcard.Exceptions import SmartcardException
from smartcard.scard import *
from PySide import QtCore
import smartcard.util
import threading
import time


class LLScardDevice(object):

    """
    Low level pyscard based backend (Windows chokes on the high level one
    whenever you remove the key and re-insert it).
    """

    def __init__(self, context, card, protocol):
        self._context = context
        self._card = card
        self._protocol = protocol

    def send_apdu(self, cl, ins, p1, p2, data):
        apdu = [cl, ins, p1, p2, len(data)] + map(ord, data)
        hresult, response = SCardTransmit(self._card, self._protocol, apdu)
        if hresult != SCARD_S_SUCCESS:
            raise Exception('Failed to transmit: ' +
                            SCardGetErrorMessage(hresult))
        status = response[-2] << 8 | response[-1]
        return ''.join(map(chr, response[:-2])), status

    def __del__(self):
        self.close()

    def close(self):
        SCardDisconnect(self._card, SCARD_UNPOWER_CARD)
        SCardReleaseContext(self._context)


class PollerThread(threading.Thread):

    def __init__(self, watcher):
        super(PollerThread, self).__init__()
        self._watcher = watcher
        self.daemon = True
        self.running = True

    def run(self):
        old_readers = []
        while self.running:
            readers = self._list()
            added = [r for r in readers if r not in old_readers]
            removed = [r for r in old_readers if r not in readers]
            self._watcher._update(added, removed)
            old_readers = readers
            time.sleep(2)

    def _list(self):
        try:
            hresult, hcontext = SCardEstablishContext(SCARD_SCOPE_USER)
            if hresult != SCARD_S_SUCCESS:
                raise Exception('Failed to establish context : ' +
                                SCardGetErrorMessage(hresult))

            try:
                hresult, readers = SCardListReaders(hcontext, [])
                if hresult != SCARD_S_SUCCESS:
                    raise Exception('Failed to list readers: ' +
                                    SCardGetErrorMessage(hresult))
                return readers
            finally:
                hresult = SCardReleaseContext(hcontext)
                if hresult != SCARD_S_SUCCESS:
                    raise Exception('Failed to release context: ' +
                                    SCardGetErrorMessage(hresult))
        except:
            return []


class CardWatcher(QtCore.QObject):
    status_changed = QtCore.Signal(int)

    def __init__(self, reader_name, callback, parent=None):
        super(CardWatcher, self).__init__(parent)

        self._status = CardStatus.NoCard
        self.reader_name = reader_name
        self._callback = callback or (lambda _: _)
        self._reader = None
        self._thread = PollerThread(self)
        self._thread.start()

    def _update(self, added, removed):
        if self._reader in removed:  # Device removed
            self.reader = None
            self._set_status(CardStatus.NoCard)

        if self._reader is None:
            for reader in added:
                if self.reader_name in reader:
                    self.reader = reader
                    self._set_status(CardStatus.Present)
                    return

    @property
    def status(self):
        return self._status

    def _set_status(self, value):
        if self._status != value:
            self._status = value
            self.status_changed.emit(value)

    @property
    def reader(self):
        return self._reader

    @reader.setter
    def reader(self, value):
        self._reader = value
        self._callback(self, value)

    def open(self):
        if self._reader:
            try:
                hresult, hcontext = SCardEstablishContext(SCARD_SCOPE_USER)
                if hresult != SCARD_S_SUCCESS:
                    raise Exception('Failed to establish context : ' +
                                    SCardGetErrorMessage(hresult))

                hresult, hcard, dwActiveProtocol = SCardConnect(
                    hcontext, self._reader,
                    SCARD_SHARE_SHARED, SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1)
                if hresult != SCARD_S_SUCCESS:
                    raise Exception('Unable to connect: ' +
                                    SCardGetErrorMessage(hresult))
                return LLScardDevice(hcontext, hcard, dwActiveProtocol)
            except Exception:
                self._set_status(CardStatus.InUse)

    def __del__(self):
        self._thread.running = False
        self._thread.join()


def observe_reader(reader_name='Yubikey', callback=None):
    return CardWatcher(reader_name, callback)
