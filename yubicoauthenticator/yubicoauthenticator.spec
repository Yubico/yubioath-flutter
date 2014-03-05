# -*- coding: utf-8 -*-
#
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


import os
import sys
import re
import distutils.core
import errno
from glob import glob
from getpass import getpass

######################
#					 #
# USER CONFIGURATION #
#					 #
######################

NAME = "Yubico Authenticator"
PROJECT_PATH = "C:\\Users\\v\\Documents\\Git\\yubioath-desktop\\yubicoauthenticator"
ICON = "yubico.ico"

### END OF USER CONFIGURATION ###



WIN = sys.platform in ['win32', 'cygwin']
OSX = sys.platform in ['darwin']

#if WIN:
#	ICON = os.path.join('graphics\\graphics', 'yubico.ico')

# Read version string
with open('__init__.py', 'r') as f:
    match = re.search(r"(?m)^__version__\s*=\s*['\"](.+)['\"]$", f.read())
    ver_str = match.group(1)

if WIN:
	a = Analysis(['.\\ui_systray.py'],
             pathex=[PROJECT_PATH],
             hiddenimports=[],
             hookspath=None,
             runtime_hooks=None)
			 
if OSX:
	a = Analysis(['ui_systray.py'],
             pathex=['.'],
             hiddenimports=[],
             hookspath=None,
             runtime_hooks=None)

			 
pyz = PYZ(a.pure)
exe = EXE(pyz,
          a.scripts,
          exclude_binaries=True,
          name='Yubico Authenticator.exe',
          debug=False,
          strip=None,
          upx=True,
          console=False,
		  append_pkg=not OSX,
		  icon=ICON )
		  
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=None,
               upx=True,
               name=NAME)
			   
# Read version information on Windows.
VERSION = None
if WIN:
    VERSION = 'build/file_version_info.txt'

    ver_tup = tuple(map(int, ver_str.split('.')))
    while len(ver_tup) < 4:
        ver_tup += (0,)
    assert len(ver_tup) == 4

    # Write version info.
    with open(VERSION, 'w') as f:
        f.write("""
VSVersionInfo(
  ffi=FixedFileInfo(
    # filevers and prodvers should be always a tuple with four
    # items: (1, 2, 3, 4)
    # Set not needed items to zero 0.
    filevers=%(ver_tup)r,
    prodvers=%(ver_tup)r,
    # Contains a bitmask that specifies the valid bits 'flags'r
    mask=0x0,
    # Contains a bitmask that specifies the Boolean attributes
    # of the file.
    flags=0x0,
    # The operating system for which this file was designed.
    # 0x4 - NT and there is no need to change it.
    OS=0x4,
    # The general type of file.
    # 0x1 - the file is an application.
    fileType=0x1,
    # The function of the file.
    # 0x0 - the function is not defined for this fileType
    subtype=0x0,
    # Creation date and time stamp.
    date=(0, 0)
  ),
  kids=[
    StringFileInfo(
      [
      StringTable(
        u'040904E4',
        [StringStruct(u'FileDescription', u'Yubico Authenticator'),
        StringStruct(u'FileVersion', u'%(ver_str)s'),
        StringStruct(u'InternalName', u'yubicoauthenticator'),
        StringStruct(u'LegalCopyright', u'Copyright © 2013 Yubico'),
        StringStruct(u'OriginalFilename', u'%(exe_name)s'),
        StringStruct(u'ProductName', u'Yubico Authenticator'),
        StringStruct(u'ProductVersion', u'%(ver_str)s')])
      ]),
    VarFileInfo([VarStruct(u'Translation', [1033, 1252])])
  ]
)""" % {
            'ver_tup': ver_tup,
            'ver_str': ver_str,
            'exe_name': '%s.exe' % NAME
        })
	

	
	
# Create .app for OSX
if OSX:
    app = BUNDLE(coll,
                 name="%s.app" % NAME,
                 icon=ICON)

    from shutil import copy2 as copy
    copy('resources/qt.conf', 'dist/%s.app/Contents/Resources/' % NAME)
	
	
	
	
# fix graphics folder
import shutil
shutil.copy2('yubioath-48.png', 'dist/Yubico Authenticator/yubioath-48.png')
shutil.copy2('yubico.ico', 'dist/Yubico Authenticator/yubico.ico')
shutil.copy2('yubico.png', 'dist/Yubico Authenticator/yubico.png')
shutil.copy2('yubico-logo81.png', 'dist/Yubico Authenticator/yubico-logo81.png')

if OSX:
	shutil.copy2('yubioath-48.png', 'dist/Yubico Authenticator.app/Contents/MacOS/yubioath-48.png')
	shutil.copy2('yubico.ico', 'dist/Yubico Authenticator.app/Contents/MacOS/yubico.ico')
	shutil.copy2('yubico.png', 'dist/Yubico Authenticator.app/Contents/MacOS/yubico.png')
	shutil.copy2('yubico-logo81.png', 'dist/Yubico Authenticator.app/Contents/MacOS/yubico-logo81.png')
	shutil.copy2('yubioath-48.icns', 'dist/Yubico Authenticator.app/Contents/MacOS/yubioath-48.png')
	shutil.copy2('yubioath-48.icns', 'dist/Yubico Authenticator.app/Contents/Resources/yubioath-48.png')


#######################
#                     #
# SIGN THE EXECUTABLE #
#                     #
#######################

pfx_pass = "yubico"
	
if WIN:
  import subprocess
  subprocess.call(['C:/Program Files (x86)/NSIS/makensis.exe', '-DYUBICOAUTHENTICATOR_VERSION='+ver_str, 'resources\yubicoauthenticator.nsi'])
  installer = ("dist\Yubico Authenticator\yubico-authenticator-%s.exe" % ver_str)
  subprocess.call(['C:/Program Files (x86)/Microsoft SDKs/Windows/v7.1A/Bin/signtool.exe', 'sign', '/f', 'certificate.pfx', '/p', pfx_pass, '/t', 'http://timestamp.verisign.com/scripts/timstamp.dll', installer])
  print "Installer created: %s" % installer
