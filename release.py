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

from distutils import log
from distutils.errors import DistutilsSetupError
from setuptools import Command
import os
import re
from datetime import date


class release(Command):
    description = "create and release a new version"
    user_options = [
        ('keyid', None, "GPG key to sign with"),
        ('skip-tests', None, "skip running the tests"),
        ('pypi', None, "publish to pypi"),
    ]
    boolean_options = ['skip-tests', 'pypi']

    def initialize_options(self):
        self.keyid = None
        self.skip_tests = 0
        self.pypi = 0

    def finalize_options(self):
        self.cwd = os.getcwd()
        self.fullname = self.distribution.get_fullname()
        self.name = self.distribution.get_name()
        self.version = self.distribution.get_version()

    def _verify_version(self):
        with open('NEWS', 'r') as news_file:
            line = news_file.readline()
        now = date.today().strftime('%Y-%m-%d')
        if not re.search(r'Version %s \(released %s\)' % (self.version, now),
                         line):
            raise DistutilsSetupError("Incorrect date/version in NEWS!")

    def _verify_tag(self):
        if os.system('git tag | grep -q "^%s\$"' % self.fullname) == 0:
            raise DistutilsSetupError(
                "Tag '%s' already exists!" % self.fullname)

    def _sign(self):
        if os.path.isfile('dist/%s.tar.gz.asc' % self.fullname):
            # Signature exists from upload, re-use it:
            sign_opts = ['--output dist/%s.tar.gz.sig' % self.fullname,
                         '--dearmor dist/%s.tar.gz.asc' % self.fullname]
        else:
            # No signature, create it:
            sign_opts = ['--detach-sign', 'dist/%s.tar.gz' % self.fullname]
            if self.keyid:
                sign_opts.insert(1, '--default-key ' + self.keyid)
        self.execute(os.system, ('gpg ' + (' '.join(sign_opts)),))

        if os.system('gpg --verify dist/%s.tar.gz.sig' % self.fullname) != 0:
            raise DistutilsSetupError("Error verifying signature!")

    def _tag(self):
        tag_opts = ['-s', '-m ' + self.fullname, self.fullname]
        if self.keyid:
            tag_opts[0] = '-u ' + self.keyid
        self.execute(os.system, ('git tag ' + (' '.join(tag_opts)),))

    def _do_call_publish(self, cmd):
        self._published = os.system(cmd) == 0

    def _publish(self):
        web_repo = os.getenv('YUBICO_GITHUB_REPO')
        if web_repo and os.path.isdir(web_repo):
            artifacts = [
                'dist/%s.tar.gz' % self.fullname,
                'dist/%s.tar.gz.sig' % self.fullname
            ]
            cmd = '%s/publish %s %s %s' % (
                web_repo, self.name, self.version, ' '.join(artifacts))

            self.execute(self._do_call_publish, (cmd,))
            if self._published:
                self.announce("Release published! Don't forget to:", log.INFO)
                self.announce("")
                self.announce("    (cd %s && git push)" % web_repo, log.INFO)
                self.announce("")
            else:
                self.warn("There was a problem publishing the release!")
        else:
            self.warn("YUBICO_GITHUB_REPO not set or invalid!")
            self.warn("This release will not be published!")

    def run(self):
        if os.getcwd() != self.cwd:
            raise DistutilsSetupError("Must be in package root!")

        self._verify_version()
        self._verify_tag()

        self.execute(os.system, ('git2cl > ChangeLog',))

        if not self.skip_tests:
            self.run_command('check')
            # Nosetests calls sys.exit(status)
            try:
                self.run_command('nosetests')
            except SystemExit as e:
                if e.code != 0:
                    raise DistutilsSetupError("There were test failures!")

        self.run_command('sdist')

        if self.pypi:
            cmd_obj = self.distribution.get_command_obj('upload')
            cmd_obj.sign = True
            if self.keyid:
                cmd_obj.identity = self.keyid
            self.run_command('upload')

        self._sign()
        self._tag()

        self._publish()

        self.announce("Release complete! Don't forget to:", log.INFO)
        self.announce("")
        self.announce("    git push && git push --tags", log.INFO)
        self.announce("")
