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


from .standard import YubiOathCcid
from .legacy_ccid import LegacyOathCcid
from .exc import CardError, InvalidSlotError, NeedsTouchError
import time
import sys
try:
    from .legacy_otp import open_otp, LegacyOathOtp, LegacyCredential
except ImportError:
    sys.stderr.write('libykpers not found!\n')
    open_otp = None


class Controller(object):

    @property
    def otp_supported(self):
        return bool(open_otp)

    def open_otp(self):
        otp_dev = open_otp()
        if otp_dev:
            return LegacyOathOtp(otp_dev)

    def _prompt_touch(self):
        pass

    def _end_prompt_touch(self):
        pass

    def unlock(self, std):
        raise ValueError('Password required')

    def read_slot_ccid(self, std, slot, digits, timestamp=None):
        cred = LegacyCredential(std, slot, digits)
        try:
            return (cred, cred.calculate(timestamp))
        except InvalidSlotError:
            return (cred, 'INVALID')

    def read_slot_otp(self, cred, timestamp=None, use_touch=False):
        if cred.touch:
            if not use_touch:
                raise NeedsTouchError()
            self._prompt_touch()

        try:
            return (cred, cred.calculate(timestamp))
        except InvalidSlotError:
            return (cred, 'INVALID')
        except NeedsTouchError:
            if use_touch:
                try:
                    time.sleep(0.1)  # Give the key a little time...
                    self._prompt_touch()
                    start = time.time()
                    return (cred, cred.calculate(timestamp))
                except InvalidSlotError:
                    error = 'INVALID' if time.time() - start < 1 else 'TIMEOUT'
                    return (cred, error)
            return (cred, None)
        finally:
            if cred.touch:
                self._end_prompt_touch()

    def read_creds(self, ccid_dev, slot1, slot2, timestamp, mayblock=True):
        results = []
        key_found = False
        do_legacy = mayblock and bool(slot1 or slot2)
        legacy_creds = [None, None]

        if ccid_dev:
            try:
                std = YubiOathCcid(ccid_dev)
                key_found = True
                if std.locked:
                    self.unlock(std)
                results.extend(std.calculate_all(timestamp))
            except CardError:
                pass  # No applet?

            if do_legacy:
                try:
                    legacy = LegacyOathCcid(ccid_dev)
                    for (slot, digits) in [(0, slot1), (1, slot2)]:
                        if digits:
                            try:
                                legacy_creds[slot] = self.read_slot_ccid(
                                    legacy, slot+1, digits, timestamp)
                            except NeedsTouchError:
                                pass  # Handled over OTP instead
                except CardError:
                    pass  # No applet?

        if self.otp_supported and ((slot1 and not legacy_creds[0])
                                   or (slot2 and not legacy_creds[1])):
            if ccid_dev:
                ccid_dev.close()
            legacy = self.open_otp()
            if legacy:
                key_found = True
                if not legacy_creds[0] and slot1:
                    legacy_creds[0] = self.read_slot_otp(
                        LegacyCredential(legacy, 1, slot1), timestamp, True)
                if not legacy_creds[1] and slot2:
                    legacy_creds[1] = self.read_slot_otp(
                        LegacyCredential(legacy, 2, slot2), timestamp, True)
                del legacy._device

        if not key_found:
            return None

        # Add legacy slots first.
        if legacy_creds[1]:
            results.insert(0, legacy_creds[1])
        if legacy_creds[0]:
            results.insert(0, legacy_creds[0])

        return results

    def set_password(self, dev, password):
        if dev.locked:
            self.unlock(dev)
        key = dev.calculate_key(password)
        dev.set_key(key)
        return key

    def add_cred(self, dev, *args, **kwargs):
        if dev.locked:
            self.unlock(dev)
        dev.put(*args, **kwargs)

    def add_cred_legacy(self, *args, **kwargs):
        legacy = self.open_otp()
        if not legacy:
            raise Exception('No YubiKey found!')
        legacy.put(*args, **kwargs)

    def delete_cred(self, dev, name):
        if dev.locked:
            self.unlock(dev)
        dev.delete(name)

    def delete_cred_legacy(self, slot):
        legacy = self.open_otp()
        if not legacy:
            raise Exception('No YubiKey found!')
        legacy.delete(slot)

    def reset_device(self, dev):
        dev.reset()
