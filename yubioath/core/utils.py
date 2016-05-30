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

from __future__ import print_function

from yubioath.yubicommon.compat import int2byte, byte2int
from Crypto.Hash import HMAC, SHA
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Random import get_random_bytes
try:
    from urlparse import urlparse, parse_qs
    from urllib import unquote
except ImportError:
    from urllib.parse import unquote, urlparse, parse_qs
import subprocess
import struct
import time
import sys
import re

__all__ = [
    'hmac_sha1',
    'derive_key',
    'der_pack',
    'der_read',
    'get_random_bytes'
]


#
# OATH related
#

def hmac_sha1(secret, message):
    return HMAC.new(secret, message, digestmod=SHA).digest()


def time_challenge(t=None):
    return struct.pack('>q', int((t or time.time())/30))


def parse_full(resp):
    offs = byte2int(resp[-1]) & 0xf
    return parse_truncated(resp[offs:offs+4])


def parse_truncated(resp):
    return struct.unpack('>I', resp)[0] & 0x7fffffff


def format_code(code, digits=6):
    return ('%%0%dd' % digits) % (code % 10 ** digits)


def parse_uri(uri):
    uri = uri.strip()  # Remove surrounding whitespace
    parsed = urlparse(uri)
    if parsed.scheme != 'otpauth':  # Not a uri, assume secret.
        return {'secret': uri}
    params = dict((k, v[0]) for k, v in parse_qs(parsed.query).items())
    params['name'] = unquote(parsed.path)[1:]  # Unquote and strip leading /
    params['type'] = parsed.hostname
    if 'issuer' in params and not params['name'].startswith(params['issuer']):
        params['name'] = params['issuer'] + ':' + params['name']
    return params


#
# General utils
#

def derive_key(salt, passphrase):
    if not passphrase:
        return None
    return PBKDF2(passphrase, salt, 16, 1000)


def der_pack(*values):
    return b''.join([int2byte(t) + int2byte(len(v)) + v for t, v in zip(
        values[0::2], values[1::2])])


def der_read(der_data, expected_t=None):
    t = byte2int(der_data[0])
    if expected_t is not None and expected_t != t:
        raise ValueError('Wrong tag. Expected: %x, got: %x' % (expected_t, t))
    l = byte2int(der_data[1])
    offs = 2
    if l > 0x80:
        n_bytes = l - 0x80
        l = b2len(der_data[offs:offs + n_bytes])
        offs = offs + n_bytes
    v = der_data[offs:offs + l]
    rest = der_data[offs + l:]
    if expected_t is None:
        return t, v, rest
    return v, rest


def b2len(bs):
    l = 0
    for b in bs:
        l *= 256
        l += byte2int(b)
    return l


def kill_scdaemon():
    try:
        # Works for Windows.
        from win32com.client import GetObject
        from win32api import OpenProcess, CloseHandle, TerminateProcess
        WMI = GetObject('winmgmts:')
        ps = WMI.InstancesOf('Win32_Process')
        for p in ps:
            if p.Properties_('Name').Value == 'scdaemon.exe':
                pid = p.Properties_('ProcessID').Value
                print("Killing", pid)
                handle = OpenProcess(1, False, pid)
                TerminateProcess(handle, -1)
                CloseHandle(handle)
    except ImportError:
        # Works for Linux and OS X.
        pids = subprocess.check_output(
            "ps ax | grep scdaemon | grep -v grep | awk '{ print $1 }'",
            shell=True).strip()
        if pids:
            for pid in pids.split():
                print("Killing", pid)
                subprocess.call(['kill', '-9', pid])


NON_CCID_YK_PIDS = set([0x0110, 0x0113, 0x0114, 0x0401, 0x0402, 0x0403])


def ccid_supported_but_disabled():
    """
    Check whether the first connected YubiKey supports CCID, but has it disabled.
    """

    if sys.platform in ['win32', 'cygwin']:
        pids = _get_pids_win()
    elif sys.platform == 'darwin':
        pids = _get_pids_osx()
    else:
        pids = _get_pids_linux()

    return bool(NON_CCID_YK_PIDS.intersection(pids))


def _get_pids_linux():
    pid_pattern = re.compile(r' 1050:([0-9a-f]{4}) ')
    pids = []
    for line in subprocess.check_output('lsusb').splitlines():
        match = pid_pattern.search(line.decode('ascii'))
        if match:
            pids.append(int(match.group(1), 16))
    return pids


def _get_pids_osx():
    pids = []
    vid_ok = False
    pid = None
    output = subprocess.check_output(['system_profiler', 'SPUSBDataType'])
    for line in output.splitlines():
        line = line.decode().strip()
        if line.endswith(':'):  # New entry
            if vid_ok and pid is not None:
                pids.append(pid)
            vid_ok = False
            pid = None
        if line.startswith('Vendor ID: '):
            vid_ok = line.endswith(' 0x1050')
        elif line.startswith('Product ID:'):
            pid = int(line.rsplit(' ', 1)[1], 16)

    return pids


def _get_pids_win():
    pid_pattern = re.compile(r'PID_([0-9A-F]{4})')
    pids = []
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    output = subprocess.check_output(['wmic', 'path',
                                      'Win32_USBControllerDevice', 'get', '*'],
                                     startupinfo=startupinfo)
    for line in output.splitlines():
        if 'VID_1050' in line:
            match = pid_pattern.search(line.decode('ascii'))
            if match:
                pids.append(int(match.group(1), 16))
    return pids
