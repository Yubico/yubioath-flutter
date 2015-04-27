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
from PySide import QtCore
from yubioath import __version__ as version
# from yubioath.core.ykpers import libversion as ykpers_version
ykpers_version = 'None'
from yubioath.gui import messages as m


ABOUT_TEXT = """
<h2>%s</h2>
%s<br>
%s
<h4>%s</h4>
%%s
<br><br>
""" % (m.app_name, m.copyright, m.version_1, m.libraries)


class MainWidget(QtGui.QWidget):

    def __init__(self):
        super(MainWidget, self).__init__()

        self._build_ui()

    def showEvent(self, event):
        event.accept()

    def _build_ui(self):
        layout = QtGui.QVBoxLayout(self)
        layout.addWidget(QtGui.QLabel(m.no_key))


class MainWindow(QtGui.QMainWindow):

    def __init__(self):
        super(MainWindow, self).__init__()

        self._widget = None
        self._settings = {}  # TODO get_store('window')

        self.layout().setSizeConstraint(QtGui.QLayout.SetFixedSize)

        pos = self._settings.get('pos')
        if pos:
            self.move(pos)

        self._build_menu_bar()

    def _build_menu_bar(self):
        file_menu = self.menuBar().addMenu(m.menu_file)
        add_action = QtGui.QAction(m.action_add, file_menu)
        add_action.triggered.connect(self._add_credential)
        file_menu.addAction(add_action)
        password_action = QtGui.QAction(m.action_password, file_menu)
        password_action.triggered.connect(self._change_password)
        file_menu.addAction(password_action)
        settings_action = QtGui.QAction(m.action_settings, file_menu)
        settings_action.triggered.connect(self._show_settings)
        file_menu.addAction(settings_action)

        help_menu = self.menuBar().addMenu(m.menu_help)
        about_action = QtGui.QAction(m.action_about, help_menu)
        about_action.triggered.connect(self._about)
        help_menu.addAction(about_action)

    def showEvent(self, event):
        if not self._widget:
            self._widget = MainWidget()
            self.setCentralWidget(self._widget)
        event.accept()

    def closeEvent(self, event):
        self._settings['pos'] = self.pos()
        event.accept()

    def customEvent(self, event):
        event.callback()
        event.accept()

    def _libversions(self):
        return 'ykpers: %s' % ykpers_version

    def _about(self):
        QtGui.QMessageBox.about(self, m.about_1 % m.app_name, ABOUT_TEXT %
                                (version, self._libversions()))

    def _add_credential(self):
        print "TODO"

    def _change_password(self):
        print "TODO"

    def _show_settings(self):
        print "TODO"
