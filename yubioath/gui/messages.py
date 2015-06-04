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

"""
Strings for Yubico Authenticator.

Note: String names must not start with underscore (_).

"""

organization = "Yubico"
domain = "yubico.com"
app_name = "Yubico Authenticator"
win_title_1 = "Yubico Authenticator (%s)"
about_1 = "About: %s"
copyright = "Copyright &copy; Yubico"
libraries = "Library versions"
version_1 = "Version: %s"
wait = "Please wait..."
menu_file = "&File"
menu_help = "&Help"
action_about = "&About"
action_add = "&Add..."
action_password = "Set/Change &password"
action_settings = "&Settings"
action_delete = "&Delete"
settings = "Settings"
general = "General"
no_key = "Insert a YubiKey..."
ykstd_slots = "YubiKey standard slots"
enable_slot_1 = "Read from slot %d"
n_digits = "Number of digits"
enable_systray = "Show in system tray"
reader_name = "Card reader name"
add_cred = "New credential"
cred_name = "Credential name"
cred_key = "Secret key"
cred_type = "Credential type"
cred_totp = "Time based (TOTP)"
cred_hotp = "Counter based (HOTP)"
touch_title = "Touch required"
touch_desc = "Touch your YubiKey now"


def _translate(qt):
    values = globals()
    for key, value in values.items():
        if isinstance(value, basestring) and not key.startswith('_'):
            values[key] = qt.tr(value)
