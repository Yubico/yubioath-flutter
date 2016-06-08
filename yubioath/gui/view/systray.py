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

from PySide import QtGui
from .. import messages as m
import sys


class Systray(QtGui.QSystemTrayIcon):

    def __init__(self, parent):
        super(Systray, self).__init__(parent)

        self._reason = QtGui.QSystemTrayIcon.ActivationReason.Trigger

        # Require double-click on OSX since single click opens menu.
        if sys.platform == 'darwin':
            self._reason = QtGui.QSystemTrayIcon.ActivationReason.DoubleClick

        self.activated.connect(self._activated)
        self._build_menu()

    def _build_menu(self):
        menu = QtGui.QMenu()

        show_action = QtGui.QAction(m.action_show, menu)
        show_action.triggered.connect(self._show)
        menu.addAction(show_action)

        quit_action = QtGui.QAction(m.action_quit, menu)
        quit_action.triggered.connect(self.quit)
        menu.addAction(quit_action)

        self.setContextMenu(menu)

    def _activated(self, reason):
        if reason == self._reason:
            self._show()

    def _show(self):
        self.parent().window.show()
        self.parent().window.activateWindow()
        self.parent().window.raise_()

    def quit(self):
        self.hide()
        self.parent().window.close()
