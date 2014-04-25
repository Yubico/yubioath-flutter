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

import re
import sys
import struct

# smartcard module
from smartcard.System import readers
from smartcard.Exceptions import (CardConnectionException,
    NoCardException, SmartcardException)


READER_PATTERN = re.compile('.*Yubikey NEO.*', re.I)


def require_user(orig):
    def new_func(neo, *args, **kwargs):
        if not neo.user_unlocked:
            raise PINModeLockedException(False)
        return orig(neo, *args, **kwargs)
    return new_func


def require_admin(orig):
    def new_func(neo, *args, **kwargs):
        if not neo.admin_unlocked:
            raise PINModeLockedException(True)
        return orig(neo, *args, **kwargs)
    return new_func


def require_key(orig):
    def new_func(neo, *args, **kwargs):
        if not neo.key_loaded:
            raise NoKeyLoadedException()
        return orig(neo, *args, **kwargs)
    return new_func


def hex2cmd(data):
    return map(ord, data.decode('hex'))


def pack_path(path):
    return ''.join([struct.pack('>I', index) for index in
                    [int(i[:-1]) | 0x80000000 if i.endswith("'") else int(i)
                     for i in path.split('/')]])


def open_key(name=None):
    """
    Opens a smartcard reader matching the given name and connects to the
    ykneo-bitcoin applet through it.

    Returns a reference to the YkneoBitcoin object.
    """
    r = re.compile(name) if name else READER_PATTERN
    for reader in readers():
        if r.match(reader.name):
            try:
                conn = reader.createConnection()
                conn.connect()
                return YkneoYubiOath(conn)
            except:
                continue
    raise Exception('No smartcard reader found matching: %s' % r.pattern)




#
# same as open keys but will try to look for the Yubico Authenticator applet on all readers (slower then open_key)
#
def open_key_multiple_readers(name=None):
    """
    Opens a smartcard reader matching the given name and connects to the
    ykneo-oath applet through it.

    Returns a reference to the YkneoYubiOath object.
    """
    for reader in readers():
        print "list of readers"
        print readers
        try:
            conn = reader.createConnection()
            conn.connect()

            data, status = _cmd2(conn, 0, 0xa4, 0x04, 0x00, 'a0000005272101'.decode('hex'))

            
            if (status) != 0x9000:
                print "unable to select the applet on reader %s" % reader
            else:
                print "using reader"
                print reader
                return YkneoYubiOath(conn)
        except Exception, e:
            print "WARNING: %s" % e
            print "i am in the except of multiple readers"


    raise Exception('No smartcard reader found with YubiOath applet')



def _cmd2(conn, cl, ins, p1, p2, data=''):

    command = '%02x%02x%02x%02x%02x%s' % (cl, ins, p1, p2, len(data),
                                          data.encode('hex'))
    try:
        data, sw1, sw2 = conn.transmit(hex2cmd(command))
    except Exception, e:
        print "FATAL: %s" % e
        sys.exit(1)

    return data, sw1 << 8 | sw2



class YkneoYubiOath(object):

    """
    Interface to the ykneo-bitcoin applet running on a YubiKey NEO.

    Example:
    neo = new YkneoBitcoin(...)
    master_key = ...
    neo.import_extended_key_pair(master_key, False)
    # neo now holds the master key pair m.

    # This returns the uncompressed public key from sub key m/0/7:
    neo.get_public_key(0, 7)

    # This returns the signature of hash signed by m/1/4711':
    neo.sign(1, 4711 | 0x80000000, hash)
    """

    def __init__(self, reader):
        self.reader = reader
        #is the neo protected?
        self.password_protected = False
        #store the password
        self.password = None
        self._user_unlocked = False
        self._admin_unlocked = False

        data, status = self._cmd(0, 0xa4, 0x04, 0x00,
                                 'a0000005272101'.decode('hex'))
        if (status) != 0x9000:
            raise Exception('Unable to select the applet')

        self._version = tuple(data[2:5])
        #print self._version
        
        self._key_loaded = data[3] == 1

        #initialize the ID
        self.install_id = data[7:15]
        #initialize the CHALLENGE
        self.challenge = data[17:] 

        #set password status
        self.set_password_status(data)
        #check version validity
        self.check_version_length(data)



    #initialize the NEO password status
    def set_password_status(self, data):
        
        for x in data:
            if x == 116:
                self.password_protected = True
                break
        else:
            #there is a password set
            self.password_protected = False

    #return the NEO password status
    def is_protected(self):
        return self.password_protected


    #check if the version is 3 bytes else something is wrong
    def check_version_length(self, data):
        if not data[1] == 3: 
            raise Exception('Wrong applet version length')



    #@property
    def user_unlocked(self):
        return self._user_unlocked

    #@property
    def admin_unlocked(self):
        return self._admin_unlocked

    #@property
    def version(self):
        return "%d.%d.%d" % self._version

    #@property
    def key_loaded(self):
        return self._key_loaded




    def _cmd(self, cl, ins, p1, p2, data=''):
        command = '%02x%02x%02x%02x%02x%s' % (cl, ins, p1, p2, len(data),
                                              data.encode('hex'))
        
        # print "DEBUG INSIDE COMMAND:"
        # print "len(data)"
        # print len(data)
        # print "DATA:"
        # print data
        
        # print "command decode hex"
        # print command.decode('hex')
        # #print ord(command[0])
        # #print hex(command[0])
        # test = []
        # for x in command:
        #     test.append(ord(x))
        
        # print "ARRAY VALORY"
        # print "ord di X"
        # print test

        data, sw1, sw2 = self.reader.transmit(hex2cmd(command))

        return data, sw1 << 8 | sw2


    def _cmd_ok(self, *args, **kwargs):

        data, status = self._cmd(*args, **kwargs)
        #get high bits
        low = status & 0xFF;
        high = status >> 8;

        if status != 0x9000:
            if high != 0x61:
                raise Exception('APDU error: 0x%04x' % status)
            else:
                while status != 0x9000:
                    part, status = self._cmd(0x00, 0xa5, 0x00, 0x00)
                    data = data + part

        return ''.join(map(chr, data))






















"""
    def unlock_user(self, pin):
        _, status = self._cmd(0, 0x21, 0, 0, pin)
        if status == 0x9000:
            self._user_unlocked = True
        elif status & 0xfff0 == 0x63c0:
            self._user_unlocked = False
            raise IncorrectPINException(False, status & 0xf)
        else:
            raise Exception('APDU error: 0x%04x' % status)

    def unlock_admin(self, pin):
        _, status = self._cmd(0, 0x21, 0, 1, pin)
        if status == 0x9000:
            self._admin_unlocked = True
        elif status & 0xfff0 == 0x63c0:
            self._admin_unlocked = False
            raise IncorrectPINException(True, status & 0xf)
        else:
            raise Exception('APDU error: 0x%04x' % status)


    def _send_set_pin(self, old_pin, new_pin, admin):
        data = chr(len(old_pin)) + old_pin + chr(len(new_pin)) + new_pin
        _, status = self._cmd(0, 0x22, 0, 1 if admin else 0, data)
        return status


    def set_admin_pin(self, old_pin, new_pin):
        status = self._send_set_pin(old_pin, new_pin, True)
        if status == 0x9000:
            self._admin_unlocked = True
        elif status & 0xfff0 == 0x63c0:
            self._admin_unlocked = False
            raise IncorrectPINException(True, status & 0xf)
        else:
            raise Exception('APDU error: 0x%04x' % status)

    def set_user_pin(self, old_pin, new_pin):
        status = self._send_set_pin(old_pin, new_pin, False)
        if status == 0x9000:
            self._user_unlocked = True
        elif status & 0xfff0 == 0x63c0:
            self._user_unlocked = False
            raise IncorrectPINException(False, status & 0xf)
        else:
            raise Exception('APDU error: 0x%04x' % status)

    @require_admin
    def _send_set_retry_count(self, attempts, admin):
        if not 0 < attempts < 16:
            raise ValueError('Attempts must be 1-15, was: %d', attempts)

        self._cmd_ok(0, 0x15, 0, 1 if admin else 0, chr(attempts))

    def set_user_retry_count(self, attempts):
        self._send_set_retry_count(attempts, False)

    def set_admin_retry_count(self, attempts):
        self._send_set_retry_count(attempts, True)

    @require_admin
    def reset_user_pin(self, pin):
        self._cmd_ok(0, 0x14, 0, 0, pin)

    @require_admin
    def generate_master_key_pair(self, allow_export, return_private,
                                 testnet=False):
        p2 = 0
        if allow_export:
            p2 |= 0x01
        if return_private:
            p2 |= 0x02
        if testnet:
            p2 |= 0x04
        resp = self._cmd_ok(0, 0x11, 0, p2)
        self._key_loaded = True
        return resp

    @require_admin
    def import_extended_key_pair(self, serialized_key, allow_export):
        self._cmd_ok(0, 0x12, 0, 1 if allow_export else 0, serialized_key)
        self._key_loaded = True

    @require_admin
    def export_extended_public_key(self):
        return self._cmd_ok(0, 0x13, 0, 0)

    @require_user
    @require_key
    def get_public_key(self, path):
        return self._cmd_ok(0, 0x01, 0, 0, pack_path(path))

    @require_user
    @require_key
    def sign(self, path, digest):
        if len(digest) != 32:
            raise ValueError('Digest must be 32 bytes')
        return self._cmd_ok(0, 0x02, 0, 0, pack_path(path) + digest)

    @require_user
    @require_key
    def get_header(self):
        return self._cmd_ok(0, 0x03, 0, 0)
"""
