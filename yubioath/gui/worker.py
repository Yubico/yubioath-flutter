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

from PySide import QtGui, QtCore
from functools import partial
from yubioath.gui import messages as m
from yubioath.gui.view.utils import get_active_window
import traceback


class _Event(QtCore.QEvent):
    EVENT_TYPE = QtCore.QEvent.Type(QtCore.QEvent.registerEventType())

    def __init__(self, callback):
        super(_Event, self).__init__(_Event.EVENT_TYPE)
        self._callback = callback

    def callback(self):
        self._callback()
        del self._callback


class QtWorker(QtCore.QObject):
    _work_signal = QtCore.Signal(tuple)
    _work_done_0 = QtCore.Signal()

    def __init__(self, window):
        super(QtWorker, self).__init__()

        self.window = window

        self.busy = QtGui.QProgressDialog('', None, 0, 0, window)
        self.busy.setWindowTitle(m.wait)
        self.busy.setWindowModality(QtCore.Qt.WindowModal)
        self.busy.setMinimumDuration(0)
        self.busy.setWindowFlags(self.busy.windowFlags()
                                 ^ QtCore.Qt.WindowContextHelpButtonHint)
        self.busy.setAutoClose(True)

        self.work_thread = QtCore.QThread()
        self.moveToThread(self.work_thread)
        self.work_thread.start()

        self._work_signal.connect(self.work)
        self._work_done_0.connect(self.busy.reset)

    def post(self, title, fn, callback=None, return_errors=False):
        self.busy.setLabelText(title)
        self.busy.adjustPosition(get_active_window())
        self.busy.show()
        self.post_bg(fn, callback, return_errors)

    def post_bg(self, fn, callback=None, return_errors=False):
        if isinstance(fn, tuple):
            fn = partial(fn[0], *fn[1:])
        self._work_signal.emit((fn, callback, return_errors))

    @QtCore.Slot(tuple)
    def work(self, job):
        QtCore.QThread.msleep(10)  # Needed to yield
        (fn, callback, return_errors) = job
        try:
            result = fn()
        except Exception as e:
            traceback.print_exc()
            result = e
            if not return_errors:
                def callback(e): raise e
        if callback:
            event = _Event(partial(callback, result))
            QtGui.QApplication.postEvent(self.window, event)
        self._work_done_0.emit()

Worker = QtWorker
