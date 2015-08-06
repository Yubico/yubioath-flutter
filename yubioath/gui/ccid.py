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

from ..core.ccid import ScardDevice
from smartcard import System
from smartcard.ReaderMonitoring import ReaderMonitor, ReaderObserver
from smartcard.CardMonitoring import CardMonitor, CardObserver
from smartcard.Exceptions import SmartcardException
from smartcard.pcsc.PCSCExceptions import EstablishContextException
from PySide import QtCore
import weakref


class _CcidReaderObserver(ReaderObserver):

    def __init__(self, controller):
        self._controller = weakref.ref(controller)
        self._monitor = ReaderMonitor()
        self._monitor.addObserver(self)

    def update(self, observable, tup):
        (added, removed) = tup
        c = self._controller()
        if c:
            c._update(added, removed)

    def delete(self):
        self._monitor.deleteObservers()


class _CcidCardObserver(CardObserver):

    def __init__(self, controller):
        self._controller = weakref.ref(controller)
        self._monitor = CardMonitor()
        self._monitor.addObserver(self)

    def update(self, observable, tup):
        (added, removed) = tup
        c = self._controller()
        if c:
            c._update([card.reader for card in added],
                      [r.reader for r in removed])

    def delete(self):
        self._monitor.deleteObservers()


class CardStatus:
    NoCard, InUse, Present = range(3)


class CardWatcher(QtCore.QObject):
    status_changed = QtCore.Signal(int)

    def __init__(self, reader_name, callback, parent=None):
        super(CardWatcher, self).__init__(parent)

        self._status = CardStatus.NoCard
        self.reader_name = reader_name
        self._callback = callback or (lambda _: _)
        self._reader = None
        self._reader_observer = _CcidReaderObserver(self)
        self._card_observer = _CcidCardObserver(self)
        try:
            self._update(System.readers(), [])
        except EstablishContextException:
            pass  # No PC/SC context!

    def _update(self, added, removed):
        if self._reader in removed:  # Device removed
            self.reader = None
            self._set_status(CardStatus.NoCard)

        if self._reader is None:
            for reader in added:
                if self.reader_name in reader.name:
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
            conn = self._reader.createConnection()
            try:
                conn.connect()
                self._set_status(CardStatus.Present)
                return ScardDevice(conn)
            except SmartcardException:
                self._set_status(CardStatus.InUse)

    def __del__(self):
        self._reader_observer.delete()
        self._card_observer.delete()


def observe_reader(reader_name='Yubikey', callback=None):
    return CardWatcher(reader_name, callback)
