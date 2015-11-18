# PYTHON_ARGCOMPLETE_OK

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

from .. import __version__
from ..core.ccid import open_scard
from ..core.standard import TYPE_HOTP, TYPE_TOTP
from ..core.utils import parse_uri
from .keystore import get_keystore
from .controller import CliController
from time import time
from base64 import b32decode
from getpass import getpass
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
        global_opts = argparse.ArgumentParser(add_help=False)
        global_opts.add_argument('-R', '--remember', help='remember any '
                                 'entered access key for later use',
                                 action='store_true')
        global_opts.add_argument('-r', '--reader', help='name to match '
                                 'smartcard reader against (case insensitive)',
                                 default='YubiKey')

        parser = argparse.ArgumentParser(
            description="Read OATH one time passwords from a YubiKey.",
            parents=[global_opts],
            add_help=True
        )
        parser.add_argument('-v', '--version', action='version',
                            version='%(prog)s ' + __version__)

        subparsers = parser.add_subparsers(dest='command', help='subcommands')

        self._init_show(subparsers.add_parser('show', parents=[global_opts],
                                              help='read one or more codes'))
        self._init_put(subparsers.add_parser('put', parents=[global_opts],
                                             help='store a new credential'))
        self._init_delete(subparsers.add_parser('delete', parents=[global_opts],
                                                help='delete a new credential'))
        self._init_password(subparsers.add_parser(
            'password', parents=[global_opts], help='set/unset the password'))
        self._init_reset(subparsers.add_parser('reset', parents=[global_opts],
                                               help='wipe all non slot-based '
                                               'OATH credentials'))

        return parser

    def parse_args(self):
        # Default to "show" sub command.
        subcmds = list(subcmd_names(self._parser))
        if not intersects(sys.argv[1:],
                          subcmds + ['-h', '--help', '-v', '--version']):
            sys.argv.insert(1, 'show')

        try:
            import argcomplete
            argcomplete.autocomplete(self._parser)
        except ImportError:
            pass  # No argcomplete, no problem!

        return self._parser.parse_args()

    def run(self):
        args = self.parse_args()

        self._dev = open_scard(args.reader)
        self._controller = CliController(get_keystore(), args.remember)

        return getattr(self, args.command)(args) or 0

    def _init_show(self, parser):
        parser.add_argument('query', help='credential name to match against '
                            '(case insensitive)', nargs='?')
        parser.add_argument('-s1', '--slot1', help='number of digits to '
                            'output for slot 1', type=int, default=0)
        parser.add_argument('-s2', '--slot2', help='number of digits to '
                            'output for slot 2', type=int, default=0)
        parser.add_argument('-t', '--timestamp', help='user provided timestamp',
                            type=int, default=int(time()) + 5)

    def show(self, args):
        creds = self._controller.read_creds(self._dev, args.slot1, args.slot2,
                                            args.timestamp)

        if creds is None:
            sys.stderr.write('No YubiKey found!\n')
            return 1

        if args.query:
            # Filter based on query. If exact match, show only that result.
            matched = []
            for cred, code in creds:
                if cred.name == args.query:
                    matched = [(cred, code)]
                    break
                if args.query.lower() in cred.name.lower():
                    matched.append((cred, code))

            # Only calculate Touch/HOTP codes if the credential is singled out.
            if len(matched) == 1:
                (cred, code) = matched[0]
                if not code:
                    if cred.touch:
                        self._controller._prompt_touch()
                    creds = [(cred, cred.calculate(args.timestamp))]
                else:
                    creds = [(cred, code)]
            else:
                creds = matched

        print_creds(creds)

    def _init_put(self, parser):
        parser.add_argument('key', help='base32 encoded key, or otpauth:// URI')
        parser.add_argument('-S', '--destination', help='Where to store the '
                            'credential', type=int, choices=[0, 1, 2],
                            default=0)
        parser.add_argument('-N', '--name', help='credential name')
        parser.add_argument('-A', '--oath-type', help='OATH algorithm',
                            choices=['totp', 'hotp'], default='totp')
        parser.add_argument('-D', '--digits', help='number of digits',
                            type=int, choices=[6, 8])
        parser.add_argument('-I', '--imf', help='initial moving factor',
                            type=int, default=0)
        parser.add_argument('-T', '--touch', help='require touch',
                            action='store_true')

    def put(self, args):
        if args.key.startswith('otpauth://'):
            parsed = parse_uri(args.key)
            args.key = parsed['secret']
            args.name = args.name or parsed.get('name')
            args.oath_type = parsed.get('type')
            args.digits = args.digits or int(parsed.get('digits', '6'))
            args.imf = args.imf or int(parsed.get('counter', '0'))

        args.digits = args.digits or 6
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
            self._controller.add_cred(self._dev, args.name, args.key, oath_type,
                                      digits=args.digits, imf=args.imf,
                                      require_touch=args.touch)
        else:
            self._controller.add_cred_legacy(args.destination, args.key,
                                             args.touch)

    def _init_delete(self, parser):
        parser.add_argument('name', help='name of the credential to delete')

    def delete(self, args):
        if self._dev is None:
            sys.stderr.write('No YubiKey found!\n')
            return 1
        self._controller.delete_cred(self._dev, args.name)
        sys.stderr.write('Credential deleted!\n')

    def _init_password(self, parser):
        actions = parser.add_mutually_exclusive_group(required=True)
        actions.add_argument('-S', '--set', help='sets a new password',
                             action='store_true')
        actions.add_argument('-U', '--unset', help='unsets the password',
                             action='store_true')
        actions.add_argument('-F', '--forget', help='forgets all stored keys',
                             action='store_true')
        parser.add_argument('-P', '--password', help='new password to set')

    def password(self, args):
        if args.forget:
            self._controller.keystore.clear()
            sys.stderr.write('Saved access keys deleted!\n')
        else:
            if self._dev is None:
                sys.stderr.write('No YubiKey found!\n')
                return 1

            if args.set:
                if not args.password:
                    pw = getpass('New password: ')
                    pw2 = getpass('Re-type password: ')
                    if pw == pw2:
                        args.password = pw
                    else:
                        sys.stderr.write('Passwords did not match!\n')
                        return 1
                self._controller.set_password(self._dev, args.password,
                                              args.remember)
                sys.stderr.write('New password set!\n')
            elif args.unset:
                self._controller.set_password(self._dev, '')
                sys.stderr.write('Password cleared!\n')

    def _init_reset(self, parser):
        parser.add_argument('-f', '--force', help='do not ask before resetting',
                            action='store_true')

    def reset(self, args):
        if self._dev is None:
            sys.stderr.write('No YubiKey found!\n')
            return 1

        if not args.force:
            sys.stderr.write('WARNING!!! You are about to completely wipe all '
                             'non slot-based OATH credentials from the device!'
                             '\n')
            confirm = ''
            while confirm != 'yes':
                sys.stderr.write('Proceed? [yes/no]: ')
                confirm = sys.stdin.readline().strip()
                if confirm == 'no':
                    sys.stderr.write('Aborted...\n')
                    return 1
                elif confirm != 'yes':
                    sys.stderr.write('Please type out "yes" or "no".\n')

        self._controller.reset_device(self._dev)
        sys.stderr.write('Your YubiKey has been reset.\n')


def print_creds(results):
    if not results:
        sys.stderr.write('No credentials found\n')
        return

    longest = max(map(lambda r: len(r[0].name), results))
    format_str = '{:<%d}  {:>10}' % longest
    for (cred, code) in results:
        if code is None:
            if cred.oath_type == TYPE_HOTP:
                code = '[HOTP credential]'
            elif cred.touch:
                code = '[Touch credential]'
        print format_str.format(cred, code)


def main():
    app = YubiOathCli()
    try:
        sys.exit(app.run())
    except KeyboardInterrupt:
        sys.stderr.write('\nInterrupted, exiting.\n')
        sys.exit(130)


if __name__ == '__main__':
    main()
