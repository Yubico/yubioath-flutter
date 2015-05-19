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
from yubioath.core.controller import Controller
from yubioath.cli.keystore import get_keystore
from yubioath.cli.unlocker import CliUnlocker
from PySide import QtCore
from smartcard import System
from smartcard.ReaderMonitoring import ReaderObserver, ReaderMonitor
from time import time
import weakref


class CcidObserver(ReaderObserver):

    def __init__(self, controller):
        self._controller = weakref.ref(controller)
        self._monitor = ReaderMonitor()
        self._monitor.addObserver(self)

    def update(self, observable, (added, removed)):
        c = self._controller()
        if c:
            c._update(added, removed)

    def delete(self):
        self._monitor.deleteObservers()


class GuiController(QtCore.QObject, Controller):
    refreshed = QtCore.Signal()

    def __init__(self, reader_name, slot1=0, slot2=0):
        super(GuiController, self).__init__()
        self._reader_name = reader_name
        self._slot1 = slot1
        self._slot2 = slot2
        self._reader = None
        self._creds = None
        self._expires = 0

        self._update(System.readers(), [])
        self._observer = CcidObserver(self)

        self.startTimer(2000)

    def _prompt_touch(self):
        print "Show touch dialog..."  # TODO

    def _end_prompt_touch(self):
        print "Close touch dialog."  # TODO

    @property
    def otp_enabled(self):
        return bool(self._slot1 or self._slot2)

    @property
    def credentials(self):
        return self._creds

    @property
    def expires(self):
        return self._expires

    def __del__(self):
        self._observer.delete()

    def _update(self, added, removed):
        if self._reader in removed:  # Device removed
            self._reader = None
            self._creds = None
            self._expires = 0
            self.refreshed.emit()

        if self._reader is None:
            for reader in added:
                if self._reader_name in reader.name:
                    self._reader = reader
                    self._creds = []
                    self.refresh()
                    return

    def _await(self):
        print "Awaiting device..."
        self._creds = None

    def _set_creds(self, creds, timestamp):
        self._creds = creds
        self._expires = timestamp + 30
        QtCore.QTimer.singleShot((self._expires-time()) * 1000, self.refresh)
        self.refreshed.emit()

    def refresh(self):
        if self._creds is not None:
            print "Refresh codes..."
            device = open_scard(self._reader)

            timestamp = int(time() + 5)
            self._set_creds(self.read_creds(device, self._slot1, self._slot2,
                                            timestamp), timestamp)

    def timerEvent(self, event):
        if self._creds is None and self.otp_enabled:
            print "Refresh codes legacy..."
            timestamp = int(time() + 5)
            self._set_creds(self.read_creds(None, self._slot1, self._slot2,
                                            timestamp), timestamp)
        event.accept()
