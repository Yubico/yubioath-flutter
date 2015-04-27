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

import os
import sys
import time
import argparse
import yubioath.gui.qt_resources
from PySide import QtGui, QtCore
from yubioath import __version__ as version
from yubioath.gui import messages as m
from yubioath.gui.view.main import MainWindow
from yubioath.gui.worker import Worker

if getattr(sys, 'frozen', False):
    # we are running in a PyInstaller bundle
    basedir = sys._MEIPASS
else:
    # we are running in a normal Python environment
    basedir = os.path.dirname(__file__)

# Font fixes for OSX
if sys.platform == 'darwin':
    from platform import mac_ver
    mac_version = tuple(mac_ver()[0].split('.'))
    if (10, 9) <= mac_version < (10, 10):  # Mavericks
        QtGui.QFont.insertSubstitution('.Lucida Grande UI', 'Lucida Grande')
    if (10, 10) <= mac_version:  # Yosemite
        QtGui.QFont.insertSubstitution('.Helvetica Neue DeskInterface',
                                       'Helvetica Neue')


class YubiOathApplication(QtGui.QApplication):

    def __init__(self, argv):
        super(YubiOathApplication, self).__init__(argv)

        self._set_basedir()

        m._translate(self)

        QtCore.QCoreApplication.setOrganizationName(m.organization)
        QtCore.QCoreApplication.setOrganizationDomain(m.domain)
        QtCore.QCoreApplication.setApplicationName(m.app_name)

        self.window = self._create_window()
        self.worker = Worker(self.window)

        QtCore.QTimer.singleShot(0, self.start)

    def start(self):
        args = self._parse_args()

        if args.tray:
            pass

        self.window.show()
        self.window.raise_()

    def _parse_args(self):
        parser = argparse.ArgumentParser(description='Yubico Authenticator',
                                         add_help=True)
        parser.add_argument('-t', '--tray', action='store_true')
        return parser.parse_args()

    def _set_basedir(self):
        if getattr(sys, 'frozen', False):
            # we are running in a PyInstaller bundle
            self.basedir = sys._MEIPASS
        else:
            # we are running in a normal Python environment
            self.basedir = os.path.dirname(__file__)

    def _create_window(self):
        window = MainWindow()
        window.setWindowTitle(m.win_title_1 % version)
        window.setWindowIcon(QtGui.QIcon(':/yubioath.png'))
        return window


def main():
    app = YubiOathApplication(sys.argv)
    status = app.exec_()
    app.worker.thread().quit()
    app.deleteLater()
    time.sleep(0.01)  # Without this the process sometimes stalls.
    sys.exit(status)
