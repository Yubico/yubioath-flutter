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

from yubioath.yubicommon import qt
from .. import messages as m
from PySide import QtGui


class GetPasswordDialog(qt.Dialog):

    def __init__(self, parent=None):
        super(GetPasswordDialog, self).__init__(parent)
        self.setWindowTitle(m.pass_required)

        layout = QtGui.QFormLayout(self)
        self._pwd_field = QtGui.QLineEdit()
        self._pwd_field.setEchoMode(QtGui.QLineEdit.Password)
        layout.addRow(m.password, self._pwd_field)

        self._remember = QtGui.QCheckBox(m.remember)
        layout.addRow(self._remember)

        btns = QtGui.QDialogButtonBox(QtGui.QDialogButtonBox.Ok |
                                      QtGui.QDialogButtonBox.Cancel)
        btns.accepted.connect(self.accept)
        btns.rejected.connect(self.reject)
        layout.addWidget(btns)

    @property
    def password(self):
        return self._pwd_field.text()

    @property
    def remember(self):
        return self._remember.isChecked()
