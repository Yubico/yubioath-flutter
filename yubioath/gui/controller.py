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

from ..core.ccid import open_scard
from ..core.standard import YubiOathCcid
from ..core.controller import Controller
from ..core.exc import CardError
from .view.get_password import GetPasswordDialog
from yubioath.yubicommon.qt import get_active_window
from PySide import QtCore
from smartcard import System
from smartcard.ReaderMonitoring import ReaderMonitor, ReaderObserver
from smartcard.CardMonitoring import CardMonitor, CardObserver
from time import time
from collections import namedtuple
import weakref


class CredentialType:
    AUTO, HOTP, TOUCH, INVALID = range(4)


Code = namedtuple('Code', 'code timestamp')
UNINITIALIZED = Code('', 0)

TIME_PERIOD = 30


class Credential(QtCore.QObject):
    changed = QtCore.Signal()

    def __init__(self, name, cred_type):
        super(Credential, self).__init__()
        self.name = name
        self.cred_type = cred_type
        self._code = UNINITIALIZED

    @property
    def code(self):
        return self._code

    @code.setter
    def code(self, value):
        self._code = value
        self.changed.emit()


class AutoCredential(Credential):

    def __init__(self, name, code):
        super(AutoCredential, self).__init__(name, CredentialType.AUTO)
        self._code = code


class TouchCredential(Credential):

    def __init__(self, controller, name, slot, digits):
        super(TouchCredential, self).__init__(name, CredentialType.TOUCH)

        self._controller = controller
        self._slot = slot
        self._digits = digits

    def calculate(self):
        def cb(code):
            self.code = code
        self._controller._app.worker.post(
            'Touch...',
            (self._controller._calculate_touch, self._slot, self._digits),
            cb)


class HotpCredential(Credential):

    def __init__(self, controller, cred, name):
        super(HotpCredential, self).__init__(name, CredentialType.HOTP)
        self._controller = controller
        self._cred = cred

    def calculate(self):
        def cb(code):
            self.code = code
        self._controller._app.worker.post_bg(
            (self._controller._calculate_hotp, self._cred),
            cb)


def names(creds):
    return set(map(lambda c: c.name, creds))


class CcidReaderObserver(ReaderObserver):

    def __init__(self, controller):
        self._controller = weakref.ref(controller)
        self._monitor = ReaderMonitor()
        self._monitor.addObserver(self)

    def update(self, observable, xxx_todo_changeme):
        (added, removed) = xxx_todo_changeme
        c = self._controller()
        if c:
            c._update(added, removed)

    def delete(self):
        self._monitor.deleteObservers()


class CcidCardObserver(CardObserver):

    def __init__(self, controller):
        self._controller = weakref.ref(controller)
        self._monitor = CardMonitor()
        self._monitor.addObserver(self)

    def update(self, observable, xxx_todo_changeme1):
        (added, removed) = xxx_todo_changeme1
        c = self._controller()
        if c:
            c._update([card.reader for card in added], [removed])

    def delete(self):
        self._monitor.deleteObservers()


class Timer(QtCore.QObject):
    time_changed = QtCore.Signal(int)

    def __init__(self):
        super(Timer, self).__init__()

        now = time()
        rem = now % TIME_PERIOD
        QtCore.QTimer.singleShot((TIME_PERIOD - rem) * 1000, self.start_timer)
        self._time = int(now - rem)

    def start_timer(self):
        self.startTimer(TIME_PERIOD * 1000)
        self.timerEvent(QtCore.QEvent(QtCore.QEvent.None))

    def timerEvent(self, event):
        self._time += TIME_PERIOD
        self.time_changed.emit(self._time)
        event.accept()

    @property
    def time(self):
        return self._time


class GuiController(QtCore.QObject, Controller):
    refreshed = QtCore.Signal()

    def __init__(self, app, reader_name, slot1=0, slot2=0):
        super(GuiController, self).__init__()
        self._app = app
        self._reader_name = reader_name
        self._slot1 = slot1
        self._slot2 = slot2
        self._keys = {}
        self._needs_read = False
        self._reader = None
        self._creds = None
        self._lock = QtCore.QMutex()
        self.timer = Timer()

        self._update(System.readers(), [])
        self._reader_observer = CcidReaderObserver(self)
        self._card_observer = CcidCardObserver(self)

        self.startTimer(2000)
        self.timer.time_changed.connect(self.refresh_codes)

    def unlock(self, dev):
        dev.unlock(self._keys[dev.id])

    def grab_lock(self, lock=None):
        return lock or QtCore.QMutexLocker(self._lock)

    def read_slot_otp_touch(self, cred, timestamp):
        return (cred, 'TIMEOUT')

    @property
    def otp_enabled(self):
        return self.otp_supported and bool(self._slot1 or self._slot2)

    @property
    def credentials(self):
        return self._creds

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
                    ccid_dev = open_scard(reader)
                    if ccid_dev:
                        dev = YubiOathCcid(ccid_dev)
                        self._app.worker.post_fg((self._init_dev, dev))
        elif self._needs_read:
            self.refresh_codes(self.timer.time)

    def _init_dev(self, dev):
        _lock = self.grab_lock()
        while dev.locked:
            if dev.id not in self._keys:
                dialog = GetPasswordDialog(get_active_window())
                if dialog.exec_():
                    self._keys[dev.id] = dev.calculate_key(dialog.password)
                else:
                    return
            try:
                dev.unlock(self._keys[dev.id])
            except CardError:
                del self._keys[dev.id]
        self.refresh_codes(self.timer.time, _lock)

    def _await(self):
        self._creds = None

    def wrap_credential(self, xxx_todo_changeme2):
        (cred, code) = xxx_todo_changeme2
        if code == 'INVALID':
            return Credential(cred.name, CredentialType.INVALID)
        if code == 'TIMEOUT':
            return TouchCredential(self, cred.name, cred._slot, cred._digits)
        if code is None:
            return HotpCredential(self, cred, cred.name)
        else:
            return AutoCredential(cred.name, Code(code, self.timer.time))

    def _set_creds(self, creds):
        if creds:
            creds = map(self.wrap_credential, creds)
            if self._creds and names(creds) == names(self._creds):
                creds = dict((c.name, c) for c in creds)
                for cred in self._creds:
                    if cred.cred_type == CredentialType.AUTO:
                        cred.code = creds[cred.name].code
                return
            elif self._reader and self._needs_read and self._creds:
                return
            else:
                self._creds = creds
        else:
            self._creds = creds
        self.refreshed.emit()

    def _calculate_touch(self, slot, digits):
        _lock = self.grab_lock()
        legacy = self.open_otp()
        if not legacy:
            raise ValueError('YubiKey removed!')

        now = time()
        timestamp = self.timer.time
        if timestamp + TIME_PERIOD - now < 10:
            timestamp += TIME_PERIOD
        cred = self.read_slot_otp(legacy, slot, digits, timestamp, True)
        cred, code = super(GuiController, self).read_slot_otp_touch(cred[0],
                                                                    timestamp)
        return Code(code, timestamp)

    def _calculate_hotp(self, cred):
        _lock = self.grab_lock()
        std = YubiOathCcid(open_scard(self._reader))
        if std.locked:
            self.unlock(std)
        return Code(std.calculate(cred.name, cred.oath_type), float('inf'))

    def refresh_codes(self, timestamp, lock=None):
        lock = self.grab_lock(lock)
        device = open_scard(self._reader)
        self._needs_read = self._reader and device is None
        creds = self.read_creds(device, self._slot1, self._slot2, timestamp)
        self._set_creds(creds)

    def timerEvent(self, event):
        # TODO Only if window active
        if self._reader is None and self._creds is None and self.otp_enabled:
            _lock = self.grab_lock()
            timestamp = self.timer.time
            read = self.read_creds(None, self._slot1, self._slot2, timestamp)
            if read is not None and self._reader is None:
                self._set_creds(read)
        event.accept()
