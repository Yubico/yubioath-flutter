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

from ..core.ccid import open_scard
from ..core.standard import TYPE_HOTP, TYPE_TOTP
from ..core.utils import parse_uri
from .keystore import get_keystore
from .controller import CliController
from time import time
from base64 import b32decode
import argparse
import sys


def intersects(a, b):
    return bool(set(a) & set(b))


def subcmd_names(parser):
    for a in parser._subparsers._actions:
        if isinstance(a, argparse._SubParsersAction):
            for name in a._name_parser_map.keys():
                yield name


class YubiOathCli(object):

    def __init__(self):
        self._parser = self._init_parser()

    def _init_parser(self):
        parser = argparse.ArgumentParser(
            description="Read OATH one time passwords from a YubiKey.",
            add_help=True
        )

        global_opts = argparse.ArgumentParser(add_help=False)
        global_opts.add_argument('-S', '--save-password', help='save the access key '
                            'for later use.', action='store_true')
        global_opts.add_argument('-r', '--reader', help='name to match smartcard '
                            'reader against (case insensitive)',
                            default='YubiKey')

        subparsers = parser.add_subparsers(dest='command', help='subcommands')

        self._init_show(subparsers.add_parser('show', parents=[global_opts],
                                              help='read one or more codes'))
        self._init_put(subparsers.add_parser('put', parents=[global_opts],
                                             help='store a new credential'))
        self._init_delete(subparsers.add_parser('delete', parents=[global_opts],
                                                help='delete a new credential'))
        self._init_password(subparsers.add_parser(
            'password', parents=[global_opts], help='set/unset the password'))
        return parser

    def _init_show(self, parser):
        parser.add_argument('query', help='credential name to match against '
                            '(case insensitive)', nargs='?')
        parser.add_argument('-s1', '--slot1', help='number of digits to '
                            'output for slot 1', type=int, default=0)
        parser.add_argument('-s2', '--slot2', help='number of digits to '
                            'output for slot 2', type=int, default=0)
        parser.add_argument('-t', '--timestamp', help='user provided timestamp',
                            type=int, default=int(time()) + 5)

    def _init_put(self, parser):
        parser.add_argument('key', help='base32 encoded key, or otpauth:// URI')
        parser.add_argument('-D', '--destination', help='Where to store the '
                            'credential', type=int, choices=[0, 1, 2],
                            default=0)
        parser.add_argument('-N', '--name', help='credential name')
        parser.add_argument('-A', '--oath-type', help='OATH algorithm',
                            choices=['totp', 'hotp'], default='totp')
        parser.add_argument('-T', '--touch', help='require touch',
                            action='store_true')

    def _init_delete(self, parser):
        parser.add_argument('name', help='name of the credential to delete')

    def _init_password(self, parser):
        parser.add_argument('-P', '--new-password', help='the password to set')

    def parse_args(self):
        # Default to "show" sub command.
        subcmds = list(subcmd_names(self._parser))
        if not intersects(sys.argv[1:], subcmds + ['-h', '--help']):
            sys.argv.insert(1, 'show')

        return self._parser.parse_args()

    def run(self):
        args = self.parse_args()

        self._dev = open_scard(args.reader)
        self._controller = CliController(get_keystore(), args.save_password)

        return getattr(self, args.command)(args) or 0

    def show(self, args):
        creds = self._controller.read_creds(self._dev, args.slot1, args.slot2,
                                            args.timestamp)

        if creds is None:
            sys.stderr.write('No YubiKey found!\n')
            return 1

        if args.query:
            query = args.query.lower()
            creds = filter(lambda (c, _): query in c.name.lower(), creds)
            if len(creds) == 1 and creds[0][0].oath_type == TYPE_HOTP:
                cred = creds[0][0]
                creds = [(cred, cred.calculate(args.timestamp))]

        print_creds(creds)

    def put(self, args):
        if args.key.startswith('otpauth://'):
            parsed = parse_uri(args.key)
            args.key = parsed['secret']
            args.name = args.name or parsed.get('name')
            args.oath_type = parsed.get('type')

        unpadded = args.key.upper()
        args.key = b32decode(unpadded + '=' * (-len(unpadded) % 8))

        if args.destination == 0:
            if self._dev is None:
                sys.stderr.write('No YubiKey found!\n')
                return 1
            if not args.name:
                if sys.stdin.isatty():
                    sys.stderr.write('Enter a name for the credential: ')
                    args.name = sys.stdin.readline().strip()
                if not args.name:
                    sys.stderr.write('Missing required argument: --name\n')
                    return 1
            oath_type = TYPE_TOTP if args.oath_type == 'totp' else TYPE_HOTP
            self._controller.add_cred(self._dev, args.name, args.key, oath_type)
        else:
            self._controller.add_cred_legacy(args.destination, args.key,
                                             args.touch)

    def delete(self, args):
        if self._dev is None:
            sys.stderr.write('No YubiKey found!\n')
            return 1
        self._controller.delete_cred(self._dev, args.name)
        sys.stderr.write('Credential deleted!\n')

    def password(self, args):
        if self._dev is None:
            sys.stderr.write('No YubiKey found!\n')
            return 1
        self._controller.set_password(self._dev, args.new_password,
                                      args.save_password)
        if args.new_password:
            sys.stderr.write('New password set!\n')
        else:
            sys.stderr.write('Password cleared!\n')


def print_creds(results):
    if not results:
        sys.stderr.write('No credentials found\n')
        return

    longest = max(map(lambda r: len(r[0].name), results))
    format_str = '{:<%d}  {:>10}' % longest
    for (cred, code) in results:
        if code is None:
            code = '[HOTP credential]'
        print format_str.format(cred, code)


def main():
    app = YubiOathCli()
    sys.exit(app.run())
