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

from setuptools import Command
from distutils.errors import DistutilsSetupError
from setuptools.command.sdist import sdist
import os


class qt_sdist(sdist):
    def run(self):
        self.run_command('qt_resources')

        sdist.run(self)


class qt_resources(Command):
    description = "convert file resources into code"
    user_options = []
    boolean_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        self.cwd = os.getcwd()
        self.source = os.path.join(self.cwd, 'qt_resources')
        self.target = os.path.join(self.cwd, 'yubioath', 'gui',
                                   'qt_resources.py')

    def _create_qrc(self):
        qrc = os.path.join(self.source, 'qt_resources.qrc')
        with open(qrc, 'w') as f:
            f.write('<RCC>\n<qresource>\n')
            for fname in os.listdir(self.source):
                f.write('<file>%s</file>\n' % fname)
            f.write('</qresource>\n</RCC>\n')
        return qrc

    def run(self):
        if os.getcwd() != self.cwd:
            raise DistutilsSetupError("Must be in package root!")

        qrc = self._create_qrc()
        self.execute(os.system,
                     ('pyside-rcc "%s" -o "%s"' % (qrc, self.target),))
        os.unlink(qrc)

        self.announce("QT resources compiled into %s" % self.target)
