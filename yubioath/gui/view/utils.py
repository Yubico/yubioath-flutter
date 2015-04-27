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

TOP_SECTION = '<b>%s</b>'
SECTION = '<br><b>%s</b>'
IMPORTANT = '<strong>%s</strong>'


class Dialog(QtGui.QDialog):

    def __init__(self, *args, **kwargs):
        super(Dialog, self).__init__(*args, **kwargs)
        self.setWindowFlags(self.windowFlags()
                            ^ QtCore.Qt.WindowContextHelpButtonHint)
        self._headers = Headers()

    @property
    def headers(self):
        return self._headers

    def section(self, title):
        return self._headers.section(title)


class Headers(object):

    def __init__(self):
        self._first = True

    def section(self, title):
        if self._first:
            self._first = False
            section = TOP_SECTION % title
        else:
            section = SECTION % title
        return QtGui.QLabel(section)


def get_text(*args, **kwargs):
    flags = (
        QtCore.Qt.WindowTitleHint |
        QtCore.Qt.WindowSystemMenuHint
    )
    kwargs['flags'] = flags
    return QtGui.QInputDialog.getText(*args, **kwargs)


def get_active_window():
    active_win = QtGui.QApplication.activeWindow()
    if active_win is not None:
        return active_win

    wins = filter(lambda w: isinstance(w, Dialog) and w.isVisible(),
                  QtGui.QApplication.topLevelWidgets())

    if not wins:
        return QtCore.QCoreApplication.instance().window

    return wins[0]  # TODO: If more than one candidates remain, find best one.
