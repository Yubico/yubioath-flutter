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
from .. import messages as m
from time import time


class TimeleftBar(QtGui.QProgressBar):
    expired = QtCore.Signal()

    def __init__(self):
        super(TimeleftBar, self).__init__()

        self.setInvertedAppearance(True)
        self.setRange(0, 30000)
        self.setValue(0)
        self.setTextVisible(False)

        self._timer = 0
        self._timeleft = 0

    def set_timeleft(self, millis):
        self._timeleft = max(0, millis)
        self.setValue(min(millis, self.maximum()))
        if self._timer == 0 and millis > 0:
            self._timer = self.startTimer(250)
        elif self._timer != 0 and millis <= 0:
            self.killTimer(self._timer)
            self._timer = 0

    def timerEvent(self, event):
        self.set_timeleft(max(0, self._timeleft - 250))
        if self._timeleft == 0:
            self.expired.emit()


class CodesList(QtGui.QWidget):

    def __init__(self, credentials=[]):
        super(CodesList, self).__init__()

        layout = QtGui.QVBoxLayout(self)

        for (cred, code) in credentials:
            layout.addWidget(QtGui.QLabel(str(cred)))


class CodesWidget(QtGui.QWidget):

    def __init__(self, controller):
        super(CodesWidget, self).__init__()

        self._controller = controller
        controller.refreshed.connect(self.refresh)

        self._build_ui()
        self.refresh()

    def _build_ui(self):
        layout = QtGui.QVBoxLayout(self)
        self._timeleft = TimeleftBar()
        layout.addWidget(self._timeleft)

        self._scroll_area = QtGui.QScrollArea()
        self._scroll_area.setWidget(CodesList())
        layout.addWidget(self._scroll_area)

    def refresh(self):
        self._scroll_area.takeWidget()
        creds = self._controller.credentials
        if creds is not None:
            self._scroll_area.setWidget(CodesList(creds or []))
            self._timeleft.set_timeleft(
                1000 * (self._controller.expires - time()))
