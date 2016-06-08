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


class CardError(Exception):

    def __init__(self, status, message=''):
        super(CardError, self).__init__('Card Error (%04x): %s' %
                                        (status, message))
        self.status = status


class DeviceLockedError(Exception):

    def __init__(self):
        super(DeviceLockedError, self).__init__('Device is locked!')


class NoSpaceError(Exception):

    def __init__(self):
        super(NoSpaceError, self).__init__('No space available on device.')


class InvalidSlotError(Exception):

    def __init__(self):
        super(InvalidSlotError, self).__init__(
            'The selected slot does not contain a valid OATH credential.')


class NeedsTouchError(Exception):

    def __init__(self):
        super(NeedsTouchError, self).__init__(
            'The selected slot needs touch to be used.')
