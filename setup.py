# Copyright (c) 2013-2014 Yubico AB
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


from release import release
from setuptools import setup
import re

VERSION_PATTERN = re.compile(r"(?m)^__version__\s*=\s*['\"](.+)['\"]$")


def get_version():
    """Return the current version as defined by yubicoauthenticator/__init__.py."""

    with open('yubicoauthenticator/__init__.py', 'r') as f:
        match = VERSION_PATTERN.search(f.read())
        return match.group(1)

setup(
    name='yubioath-desktop',
    version=get_version(),
    author='Tommaso Galassi De Orchi',
    author_email='tom@yubico.com',
    maintainer='Yubico Open Source Maintainers',
    maintainer_email='ossmaint@yubico.com',
    url='https://github.com/Yubico/yubioath-desktop',
    license='BSD 2 clause',
	description='Crossplatform tool for generating TOTP & HOTP codes with a Yubikey NEO',
    packages=['yubicoauthenticator'],
    include_package_data=True,
	#scripts=['scripts/yubicoauthenticator'],
    setup_requires=['nose>=1.0'],
    install_requires=['PySide', 'pbkdf2', 'pyscard'],
    test_suite='nose.collector',
    tests_require=[''],
    cmdclass={'release': release},
    classifiers=[
        'License :: OSI Approved :: BSD License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Development Status :: 4 - Beta',
        'Environment :: X11 Applications :: Qt',
        'Intended Audience :: End Users/Desktop',
        'Topic :: Security :: Cryptography',
        'Topic :: Utilities'
    ]
)
