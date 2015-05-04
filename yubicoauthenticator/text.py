version = "0.1.2"


copyright = """


<b><center><font color="#8cc041">Yubico Authenticator</font> Version %s </center></b>

<br>
<p>Copyright (c) 2013-2014 Yubico AB</p>

<p>This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.</p>

<p>This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.</p>

<p>You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.</p>""" % version


instructions = """

This application generates TOTP & HOTP codes. 

How to use it:

Plug in your Yubikey NEO in one of the USB port available on your computer. Be sure that you have the Yubico Authenticator applet installed on the Yubikey NEO!

1) Right click on the Yubico icon (Y) in the task bar 

2) Select "Show codes"

3) Click once on the displayed values to copy text to the clipboard. Double click to copy text and minimize the window.

4) To quit the application right click on the Yubico icon (Y) in the taskbar and select Exit (or you can use ctrl + Q)

In case you are also using gpg, make sure to add "card-timeout 5" to  ~/.gnupg/scdaemon.conf
"""



no_yubikey_no_m82 = """No Yubikey NEO found. Please plugin your Yubikey NEO in one of your USB port.
Ensure that the NEO has CCID mode enabled, e.g -m86 or -m82. Download the Yubikey NEO manager from developers.yubico.com"""
