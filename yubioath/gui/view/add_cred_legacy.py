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
from .add_cred import B32Validator
from .. import messages as m
from ..qrparse import parse_qr_codes
from ..qrdecode import decode_qr_data
from ...core.utils import parse_uri
from PySide import QtGui
from base64 import b32decode


class AddCredDialog(qt.Dialog):

    def __init__(self, worker, otp_slots=(0, 0), url=None, parent=None):
        super(AddCredDialog, self).__init__(parent)

        self.setWindowTitle(m.add_cred)
        self._worker = worker
        self._slot_status = otp_slots
        self._build_ui()

    def _build_ui(self):
        layout = QtGui.QFormLayout(self)

        self._qr_btn = QtGui.QPushButton(QtGui.QIcon(':/qr.png'), m.qr_scan)
        self._qr_btn.clicked.connect(self._scan_qr)
        layout.addRow(self._qr_btn)

        self._cred_key = QtGui.QLineEdit()
        self._cred_key.setValidator(B32Validator())
        layout.addRow(m.cred_key, self._cred_key)

        layout.addRow(QtGui.QLabel(m.slot))
        self._slot = QtGui.QButtonGroup(self)
        slot1_status = m.in_use if self._slot_status[0] else m.free
        self._slot_1 = QtGui.QRadioButton(m.slot_2 % (1, slot1_status))
        self._slot_1.setProperty('value', 1)
        self._slot.addButton(self._slot_1)
        layout.addRow(self._slot_1)
        slot2_status = m.in_use if self._slot_status[1] else m.free
        self._slot_2 = QtGui.QRadioButton(m.slot_2 % (2, slot2_status))
        self._slot_2.setProperty('value', 2)
        self._slot.addButton(self._slot_2)
        layout.addRow(self._slot_2)

        self._touch = QtGui.QCheckBox(m.require_touch)
        layout.addRow(self._touch)

        self._n_digits = QtGui.QComboBox()
        self._n_digits.addItems(['6', '8'])
        layout.addRow(m.n_digits, self._n_digits)

        btns = QtGui.QDialogButtonBox(QtGui.QDialogButtonBox.Ok |
                                      QtGui.QDialogButtonBox.Cancel)
        btns.accepted.connect(self._save)
        btns.rejected.connect(self.reject)
        layout.addRow(btns)

    def _save(self):
        if not self._cred_key.hasAcceptableInput():
            QtGui.QMessageBox.warning(self, m.invalid_key, m.invalid_key_desc)
            self._cred_key.selectAll()
        elif not self._slot.checkedButton():
            QtGui.QMessageBox.warning(self, m.no_slot, m.no_slot_desc)
        elif self._slot_status[self.slot - 1] \
            and QtGui.QMessageBox.Ok != QtGui.QMessageBox.warning(
                self, m.overwrite_slot, m.overwrite_slot_desc_1 % self.slot,
                QtGui.QMessageBox.Ok | QtGui.QMessageBox.Cancel):
            return
        else:
            self.accept()

    def _do_scan_qr(self, qimage):
        for qr in parse_qr_codes(qimage):
            try:
                data = decode_qr_data(qr)
                if data.startswith('otpauth://'):
                    return parse_uri(data)
            except:
                pass
        return None

    def _scan_qr(self):
        winId = QtGui.QApplication.desktop().winId()
        qimage = QtGui.QPixmap.grabWindow(winId).toImage()
        self._worker.post(m.qr_scanning, (self._do_scan_qr, qimage),
                          self._handle_qr)

    def _handle_qr(self, parsed):
        if parsed:
            if parsed['type'] != 'totp':
                QtGui.QMessageBox.warning(self, m.qr_not_supported,
                                          m.qr_not_supported_desc)
            else:
                self._cred_key.setText(parsed['secret'])
                n_digits = parsed.get('digits', '6')
                self._n_digits.setCurrentIndex(0 if n_digits == '6' else 1)
        else:
            QtGui.QMessageBox.warning(self, m.qr_not_found, m.qr_not_found_desc)


    @property
    def key(self):
        unpadded = self._cred_key.text().upper()
        return b32decode(unpadded + '=' * (-len(unpadded) % 8))

    @property
    def slot(self):
        return self._slot.checkedButton().property('value')

    @property
    def touch(self):
        return self._touch.isChecked()

    @property
    def n_digits(self):
        return int(self._n_digits.currentText())
