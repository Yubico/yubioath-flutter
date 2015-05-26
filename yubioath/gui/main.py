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

import sys
import argparse
from PySide import QtGui, QtCore
from yubioath import __version__ as version
from yubioath.yubicommon import qt
from ..cli.keystore import get_keystore
try:
    from ..core.legacy_otp import ykpers_version
except ImportError:
    ykpers_version = 'None'
from . import messages as m
from .controller import GuiController
from .view.codes import CodesWidget


ABOUT_TEXT = """
<h2>%s</h2>
%s<br>
%s
<h4>%s</h4>
%%s
<br><br>
""" % (m.app_name, m.copyright, m.version_1, m.libraries)


class MainWidget(QtGui.QStackedWidget):

    def __init__(self, controller):
        super(MainWidget, self).__init__()

        self._controller = controller

        self._build_ui()
        controller.refreshed.connect(self._refresh)

    def showEvent(self, event):
        event.accept()

    def _build_ui(self):
        self.codes_widget = CodesWidget(self._controller)
        self.no_key_widget = QtGui.QLabel(m.no_key)
        self.addWidget(self.codes_widget)
        self.addWidget(self.no_key_widget)

    def _refresh(self):
        if self._controller.credentials is None:
            self.setCurrentIndex(1)
        else:
            self.setCurrentIndex(0)


class YubiOathApplication(qt.Application):

    def __init__(self):
        super(YubiOathApplication, self).__init__(m)

        QtCore.QCoreApplication.setOrganizationName(m.organization)
        QtCore.QCoreApplication.setOrganizationDomain(m.domain)
        QtCore.QCoreApplication.setApplicationName(m.app_name)

        self._widget = None
        self._settings = {}  # TODO get_store('window')

        reader = self._settings.get('reader', 'Yubikey')
        self._controller = GuiController(self, reader)
        self._init_window()

    def _init_window(self):
        self.window.setWindowTitle(m.win_title_1 % version)
        self.window.setWindowIcon(QtGui.QIcon(':/yubioath.png'))
        self.window.resize(self._settings.get('size', QtCore.QSize(320, 340)))

        self._build_menu_bar()

        args = self._parse_args()

        if args.tray:
            pass

        self.window.shown.connect(self._on_shown)
        self.window.closed.connect(self._on_closed)

        self.window.show()
        self.window.raise_()

    def _parse_args(self):
        parser = argparse.ArgumentParser(description='Yubico Authenticator',
                                         add_help=True)
        parser.add_argument('-t', '--tray', action='store_true')
        return parser.parse_args()

    def _build_menu_bar(self):
        file_menu = self.window.menuBar().addMenu(m.menu_file)
        add_action = QtGui.QAction(m.action_add, file_menu)
        add_action.triggered.connect(self._add_credential)
        file_menu.addAction(add_action)
        password_action = QtGui.QAction(m.action_password, file_menu)
        password_action.triggered.connect(self._change_password)
        file_menu.addAction(password_action)
        settings_action = QtGui.QAction(m.action_settings, file_menu)
        settings_action.triggered.connect(self._show_settings)
        file_menu.addAction(settings_action)

        help_menu = self.window.menuBar().addMenu(m.menu_help)
        about_action = QtGui.QAction(m.action_about, help_menu)
        about_action.triggered.connect(self._about)
        help_menu.addAction(about_action)

    def _on_shown(self):
        if not self._widget:
            self._widget = MainWidget(self._controller)
            self.window.setCentralWidget(self._widget)

    def _on_closed(self):
        self._settings['size'] = self.window.size()

    def _libversions(self):
        return 'ykpers: %s' % ykpers_version

    def _about(self):
        QtGui.QMessageBox.about(self.window, m.about_1 % m.app_name,
                                ABOUT_TEXT % (version, self._libversions()))

    def _add_credential(self):
        print "TODO"

    def _change_password(self):
        print "TODO"

    def _show_settings(self):
        print "TODO"


def main():
    app = YubiOathApplication()
    sys.exit(app.exec_())
