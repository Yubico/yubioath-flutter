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

INDENT = 16


class SettingsDialog(qt.Dialog):

    def __init__(self, parent, settings):
        super(SettingsDialog, self).__init__(parent)
        self.settings = settings

        self.setWindowTitle(m.settings)
        self.accepted.connect(self._save)
        self._build_ui()
        self._reset()

    def _build_ui(self):
        layout = QtGui.QFormLayout(self)
        layout.addRow(self.section(m.ykstd_slots))

        # YubiKey slot 1
        self._slot1_enabled = QtGui.QCheckBox(m.enable_slot_1 % 1)
        self._slot1_enabled.setToolTip(m.tt_slot_enabled_1 % 1)
        layout.addRow(self._slot1_enabled)
        self._slot1_digits = QtGui.QComboBox()
        self._slot1_digits.addItems(['6', '8'])
        self._slot1_enabled.stateChanged.connect(self._slot1_digits.setEnabled)
        self._slot1_digits.setEnabled(False)
        self._slot1_digits.setToolTip(m.tt_num_digits)
        layout.addRow(m.n_digits, self._slot1_digits)
        layout.labelForField(self._slot1_digits).setIndent(INDENT)

        # YubiKey slot 2
        self._slot2_enabled = QtGui.QCheckBox(m.enable_slot_1 % 2)
        self._slot2_enabled.setToolTip(m.tt_slot_enabled_1 % 2)
        layout.addRow(self._slot2_enabled)
        self._slot2_digits = QtGui.QComboBox()
        self._slot2_digits.addItems(['6', '8'])
        self._slot2_enabled.stateChanged.connect(self._slot2_digits.setEnabled)
        self._slot2_digits.setEnabled(False)
        self._slot2_digits.setToolTip(m.tt_num_digits)
        layout.addRow(m.n_digits, self._slot2_digits)
        layout.labelForField(self._slot2_digits).setIndent(INDENT)

        layout.addRow(self.section(m.advanced))

        # Systray
        self._systray = QtGui.QCheckBox(m.enable_systray)
        self._systray.setToolTip(m.tt_systray)
        layout.addRow(self._systray)

        # Kill scdaemon
        self._kill_scdaemon = QtGui.QCheckBox(m.kill_scdaemon)
        self._kill_scdaemon.setToolTip(m.tt_kill_scdaemon)
        layout.addRow(self._kill_scdaemon)

        # Reader name
        self._reader_name = QtGui.QLineEdit()
        self._reader_name.setToolTip(m.tt_reader_name)
        layout.addRow(m.reader_name, self._reader_name)

        btns = QtGui.QDialogButtonBox(QtGui.QDialogButtonBox.Ok |
                                      QtGui.QDialogButtonBox.Cancel)
        btns.accepted.connect(self.accept)
        btns.rejected.connect(self.reject)
        layout.addRow(btns)

    def _reset(self):
        slot1 = self.settings.get('slot1', 0)
        self._slot1_digits.setCurrentIndex(1 if slot1 == 8 else 0)
        self._slot1_enabled.setChecked(bool(slot1))

        slot2 = self.settings.get('slot2', 0)
        self._slot2_digits.setCurrentIndex(1 if slot2 == 8 else 0)
        self._slot2_enabled.setChecked(bool(slot2))

        self._systray.setChecked(self.settings.get('systray', False))
        self._kill_scdaemon.setChecked(
            self.settings.get('kill_scdaemon', False))

        self._reader_name.setText(self.settings.get('reader', 'Yubikey'))

    @property
    def slot1(self):
        return self._slot1_enabled.isChecked() \
            and int(self._slot1_digits.currentText())

    @property
    def slot2(self):
        return self._slot2_enabled.isChecked() \
            and int(self._slot2_digits.currentText())

    @property
    def systray(self):
        return self._systray.isChecked()

    @property
    def kill_scdaemon(self):
        return self._kill_scdaemon.isChecked()

    @property
    def reader_name(self):
        return self._reader_name.text()

    def _save(self):
        self.settings['slot1'] = self.slot1
        self.settings['slot2'] = self.slot2
        self.settings['systray'] = self.systray
        self.settings['kill_scdaemon'] = self.kill_scdaemon
        self.settings['reader'] = self.reader_name
