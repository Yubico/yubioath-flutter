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

from ..core.standard import (YubiOathCcid, TYPE_TOTP, TYPE_HOTP,
                             Credential as StdCredential)
from ..core.legacy_otp import LegacyCredential
from ..core.controller import Controller
from ..core.exc import CardError, DeviceLockedError
from .ccid import CardStatus
from yubioath.yubicommon.qt.utils import is_minimized
from .view.get_password import GetPasswordDialog
from .keystore import get_keystore
from . import messages as m
from yubioath.core.utils import ccid_supported_but_disabled
from yubioath.yubicommon.qt import get_active_window, MutexLocker
from PySide import QtCore, QtGui
from time import time
from collections import namedtuple

import sys
if sys.platform == 'win32':  # Windows has issues with the high level API.
    from .ccid_poll import observe_reader
else:
    from .ccid import observe_reader


Code = namedtuple('Code', 'code timestamp ttl')
UNINITIALIZED = Code('', 0, 0)

TIME_PERIOD = 30
INF = float('inf')


class CredEntry(QtCore.QObject):
    changed = QtCore.Signal()

    def __init__(self, cred, controller):
        super(CredEntry, self).__init__()
        self.cred = cred
        self._controller = controller
        self._code = Code('', 0, 0)

    @property
    def code(self):
        return self._code

    @code.setter
    def code(self, value):
        self._code = value
        self.changed.emit()

    @property
    def manual(self):
        return self.cred.touch or self.cred.oath_type == TYPE_HOTP

    def calculate(self):
        dialog = QtGui.QMessageBox(get_active_window())
        dialog.setWindowTitle(m.touch_title)
        dialog.setStandardButtons(QtGui.QMessageBox.NoButton)
        dialog.setIcon(QtGui.QMessageBox.Information)
        dialog.setText(m.touch_desc)
        timer = None

        def cb(code):
            if timer:
                timer.stop()
            dialog.accept()
            if isinstance(code, Exception):
                QtGui.QMessageBox.warning(get_active_window(), m.error,
                                          code.message)
            else:
                self.code = code
        self._controller._app.worker.post_bg((self._controller._calculate_cred,
                                              self.cred), cb)
        if self.cred.touch:
            dialog.exec_()
        elif self.cred.oath_type == TYPE_HOTP:
            # HOTP might require touch, we don't know. Assume yes after 500ms.
            timer = QtCore.QTimer(self)
            timer.setSingleShot(True)
            timer.timeout.connect(dialog.exec_)
            timer.start(500)

    def delete(self):
        if self.cred.name in ['YubiKey slot 1', 'YubiKey slot 2']:
            self._controller.delete_cred_legacy(int(self.cred.name[-1]))
        else:
            self._controller.delete_cred(self.cred.name)


Capabilities = namedtuple('Capabilities', 'ccid otp version')


def names(creds):
    return set(c.cred.name for c in creds)


class Timer(QtCore.QObject):
    time_changed = QtCore.Signal(int)

    def __init__(self, interval):
        super(Timer, self).__init__()
        self._interval = interval

        now = time()
        rem = now % interval
        self._time = int(now - rem)
        QtCore.QTimer.singleShot((self._interval - rem) * 1000, self._tick)

    def _tick(self):
        self._time += self._interval
        self.time_changed.emit(self._time)
        next_time = self._time + self._interval
        QtCore.QTimer.singleShot((next_time - time()) * 1000, self._tick)

    @property
    def time(self):
        return self._time


class GuiController(QtCore.QObject, Controller):
    refreshed = QtCore.Signal()
    ccid_disabled = QtCore.Signal()

    def __init__(self, app, settings):
        super(GuiController, self).__init__()
        self._app = app
        self._settings = settings
        self._needs_read = False
        self._reader = None
        self._creds = None
        self._lock = QtCore.QMutex()
        self._keystore = get_keystore()
        self._current_device_has_ccid_disabled = False
        self.timer = Timer(TIME_PERIOD)

        self.watcher = observe_reader(self.reader_name, self._on_reader)

        self.startTimer(3000)
        self.timer.time_changed.connect(self.refresh_codes)

    def settings_changed(self):
        self.watcher.reader_name = self.reader_name
        self.refresh_codes()

    @property
    def reader_name(self):
        return self._settings.get('reader', 'Yubikey')

    @property
    def slot1(self):
        return self._settings.get('slot1', 0)

    @property
    def slot2(self):
        return self._settings.get('slot2', 0)

    @property
    def mute_ccid_disabled_warning(self):
        return self._settings.get('mute_ccid_disabled_warning', 0)

    @mute_ccid_disabled_warning.setter
    def mute_ccid_disabled_warning(self, value):
        self._settings['mute_ccid_disabled_warning'] = value

    def unlock(self, dev):
        if dev.locked:
            key = self._keystore.get(dev.id)
            if not key:
                self._app.worker.post_fg((self._init_dev, dev))
                return False
            dev.unlock(key)
        return True

    def grab_lock(self, lock=None, try_lock=False):
        return lock or MutexLocker(self._lock, False).lock(try_lock)

    @property
    def otp_enabled(self):
        return self.otp_supported and bool(self.slot1 or self.slot2)

    @property
    def credentials(self):
        return self._creds

    def has_expiring(self, timestamp):
        for c in self._creds or []:
            if c.code.timestamp >= timestamp and c.code.ttl < INF:
                return True
        return False

    def get_capabilities(self):
        assert self.grab_lock()
        ccid_dev = self.watcher.open()
        if ccid_dev:
            dev = YubiOathCcid(ccid_dev)
            return Capabilities(True, None, dev.version)
        legacy = self.open_otp()
        if legacy:
            return Capabilities(None, legacy.slot_status(), (0, 0, 0))
        return Capabilities(None, None, (0, 0, 0))
    
    def get_entry_names(self):
        return names(self._creds)

    def _on_reader(self, watcher, reader, lock=None):
        if reader:
            if self._reader is None:
                self._reader = reader
                self._creds = []
                if is_minimized(self._app.window):
                    self._needs_read = True
                else:
                    ccid_dev = watcher.open()
                    if ccid_dev:
                        dev = YubiOathCcid(ccid_dev)
                        self._app.worker.post_fg((self._init_dev, dev))
                    else:
                        self._needs_read = True
            elif self._needs_read:
                self.refresh_codes(self.timer.time)
        else:
            self._reader = None
            self._creds = None
            self.refreshed.emit()

    def _init_dev(self, dev):
        lock = self.grab_lock()
        while dev.locked:
            if self._keystore.get(dev.id) is None:
                dialog = GetPasswordDialog(get_active_window())
                if dialog.exec_():
                    self._keystore.put(dev.id,
                                       dev.calculate_key(dialog.password),
                                       dialog.remember)
                else:
                    return
            try:
                dev.unlock(self._keystore.get(dev.id))
            except CardError:
                self._keystore.delete(dev.id)
        self.refresh_codes(self.timer.time, lock)

    def _await(self):
        self._creds = None

    def wrap_credential(self, tup):
        (cred, code) = tup
        entry = CredEntry(cred, self)
        if code and code not in ['INVALID', 'TIMEOUT']:
            entry.code = Code(code, self.timer.time, TIME_PERIOD)

        return entry

    def _set_creds(self, creds):
        if creds:
            creds = [self.wrap_credential(c) for c in creds]
            if self._creds and names(creds) == names(self._creds):
                entry_map = dict((c.cred.name, c) for c in creds)
                for entry in self._creds:
                    cred = entry.cred
                    code = entry_map[cred.name].code
                    if code.code:
                        entry.code = code
                    elif cred.oath_type != entry_map[cred.name].cred.oath_type:
                        break
                else:
                    return
            elif self._reader and self._needs_read and self._creds:
                return
        self._creds = creds
        self.refreshed.emit()

    def _calculate_cred(self, cred):
        assert self.grab_lock()
        now = time()
        timestamp = self.timer.time
        if timestamp + TIME_PERIOD - now < 10:
            timestamp += TIME_PERIOD
        ttl = TIME_PERIOD
        if cred.oath_type == TYPE_HOTP:
            ttl = INF

        if cred.name in ['YubiKey slot 1', 'YubiKey slot 2']:
            legacy = self.open_otp()
            if not legacy:
                raise ValueError('YubiKey removed!')

            try:
                cred._legacy = legacy
                cred, code = super(GuiController, self).read_slot_otp(
                    cred, timestamp, True)
            finally:
                cred._legacy = None  # Release the handle.
            return Code(code, timestamp, TIME_PERIOD)

        ccid_dev = self.watcher.open()
        if not ccid_dev:
            if self.watcher.status != CardStatus.Present:
                self._set_creds(None)
            return
        dev = YubiOathCcid(ccid_dev)
        if self.unlock(dev):
            return Code(dev.calculate(cred.name, cred.oath_type, timestamp),
                        timestamp, ttl)

    def read_slot_otp(self, cred, timestamp=None, use_touch=False):
        return super(GuiController, self).read_slot_otp(cred, timestamp, False)

    def refresh_codes(self, timestamp=None, lock=None):
        if not self._reader and self.watcher.reader:
            return self._on_reader(self.watcher, self.watcher.reader, lock)
        elif is_minimized(self._app.window):
            self._needs_read = True
            return
        lock = self.grab_lock(lock, True)
        if not lock:
            return
        device = self.watcher.open()
        self._needs_read = bool(self._reader and device is None)
        timestamp = timestamp or self.timer.time
        try:
            creds = self.read_creds(device, self.slot1, self.slot2, timestamp,
                                    False)
        except DeviceLockedError:
            creds = []
        self._set_creds(creds)

    def timerEvent(self, event):
        if not is_minimized(self._app.window):
            timestamp = self.timer.time
            if self._reader and self._needs_read:
                self._app.worker.post_bg(self.refresh_codes)
            elif self._reader is None:
                if self.otp_enabled:
                    def refresh_otp():
                        lock = self.grab_lock(try_lock=True)
                        if lock:
                            read = self.read_creds(None, self.slot1, self.slot2,
                                                   timestamp, False)
                            self._set_creds(read)
                    self._app.worker.post_bg(refresh_otp)
                else:
                    if ccid_supported_but_disabled():
                        if not self._current_device_has_ccid_disabled:
                            self.ccid_disabled.emit()
                        self._current_device_has_ccid_disabled = True
                        event.accept()
                        return
            self._current_device_has_ccid_disabled = False
        event.accept()

    def add_cred(self, *args, **kwargs):
        lock = self.grab_lock()
        ccid_dev = self.watcher.open()
        if ccid_dev:
            dev = YubiOathCcid(ccid_dev)
            if self.unlock(dev):
                super(GuiController, self).add_cred(dev, *args, **kwargs)
                self._creds = None
                self.refresh_codes(lock=lock)

    def add_cred_legacy(self, *args, **kwargs):
        lock = self.grab_lock()
        super(GuiController, self).add_cred_legacy(*args, **kwargs)
        self._creds = None
        self.refresh_codes(lock=lock)

    def delete_cred(self, name):
        lock = self.grab_lock()
        ccid_dev = self.watcher.open()
        if ccid_dev:
            dev = YubiOathCcid(ccid_dev)
            if self.unlock(dev):
                super(GuiController, self).delete_cred(dev, name)
                self._creds = None
                self.refresh_codes(lock=lock)

    def delete_cred_legacy(self, *args, **kwargs):
        lock = self.grab_lock()
        super(GuiController, self).delete_cred_legacy(*args, **kwargs)
        self._creds = None
        self.refresh_codes(lock=lock)

    def set_password(self, password, remember=False):
        assert self.grab_lock()
        ccid_dev = self.watcher.open()
        if ccid_dev:
            dev = YubiOathCcid(ccid_dev)
            if self.unlock(dev):
                key = super(GuiController, self).set_password(dev, password)
                self._keystore.put(dev.id, key, remember)

    def forget_passwords(self):
        self._keystore.forget()
