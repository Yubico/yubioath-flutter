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
from ...core.standard import TYPE_TOTP, TYPE_HOTP
from .. import messages as m
from PySide import QtGui, QtCore
from base64 import b32decode
import re

NAME_VALIDATOR = QtGui.QRegExpValidator(QtCore.QRegExp(r'.{3,}'))


class B32Validator(QtGui.QValidator):

    def __init__(self, parent=None):
        super(B32Validator, self).__init__(parent)
        self.partial = re.compile(r'^[a-z2-7]+$', re.IGNORECASE)

    def fixup(self, value):
        unpadded = value.upper()
        return unpadded + '=' * (-len(unpadded) % 8)

    def validate(self, value, pos):
        try:
            b32decode(self.fixup(value))
            return QtGui.QValidator.Acceptable
        except:
            if self.partial.match(value):
                return QtGui.QValidator.Intermediate
        return QtGui.QValidator.Invalid


class AddCredDialog(qt.Dialog):

    def __init__(self, parent):
        super(AddCredDialog, self).__init__(parent)

        self.setWindowTitle(m.add_cred)
        self._build_ui()

    def _build_ui(self):
        layout = QtGui.QFormLayout(self)

        self._cred_name = QtGui.QLineEdit()
        self._cred_name.setValidator(NAME_VALIDATOR)
        layout.addRow(m.cred_name, self._cred_name)

        self._cred_key = QtGui.QLineEdit()
        self._cred_key.setValidator(B32Validator())
        layout.addRow(m.cred_key, self._cred_key)

        layout.addRow(QtGui.QLabel(m.cred_type))
        self._cred_type = QtGui.QButtonGroup(self)
        self._cred_totp = QtGui.QRadioButton(m.cred_totp)
        self._cred_totp.setProperty('value', TYPE_TOTP)
        self._cred_type.addButton(self._cred_totp)
        layout.addRow(self._cred_totp)
        self._cred_hotp = QtGui.QRadioButton(m.cred_hotp)
        self._cred_hotp.setProperty('value', TYPE_HOTP)
        self._cred_type.addButton(self._cred_hotp)
        layout.addRow(self._cred_hotp)
        self._cred_totp.setChecked(True)

        self._n_digits = QtGui.QComboBox()
        self._n_digits.addItems(['6', '8'])
        layout.addRow(m.n_digits, self._n_digits)

        btns = QtGui.QDialogButtonBox(QtGui.QDialogButtonBox.Ok |
                                      QtGui.QDialogButtonBox.Cancel)
        btns.accepted.connect(self._save)
        btns.rejected.connect(self.reject)
        layout.addRow(btns)

    def _save(self):
        if not self._cred_name.hasAcceptableInput():
            QtGui.QMessageBox.warning(self, m.invalid_name, m.invalid_name_desc)
            self._cred_name.selectAll()
        elif not self._cred_key.hasAcceptableInput():
            QtGui.QMessageBox.warning(self, m.invalid_key, m.invalid_key_desc)
            self._cred_key.selectAll()
        else:
            self.accept()

    @property
    def name(self):
        return self._cred_name.text()

    @property
    def key(self):
        unpadded = self._cred_key.text().upper()
        return b32decode(unpadded + '=' * (-len(unpadded) % 8))

    @property
    def oath_type(self):
        return self._cred_type.checkedButton().property('value')

    @property
    def n_digits(self):
        return int(self._n_digits.currentText())
