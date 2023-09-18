#  Copyright (C) 2022 Yubico.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

import mss
import zxingcpp
import base64
import io
import os
import sys
import subprocess  # nosec
import tempfile
from mss.exception import ScreenShotError
from PIL import Image


def _capture_screen():
    try:
        with mss.mss() as sct:
            monitor = sct.monitors[0]  # 0 is the special "all monitors" value.
            sct_img = sct.grab(monitor)  # mss format
        return Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")
    except ScreenShotError:
        # One common error is that mss doesn't work with Wayland
        if sys.platform.startswith("linux"):
            # Try calling screenshot tools, with original library path
            env = dict(os.environ)
            lp = env.get("LD_LIBRARY_PATH_ORIG")
            if lp is not None:
                env["LD_LIBRARY_PATH"] = lp
            else:
                env.pop("LD_LIBRARY_PATH", None)
            fd, fname = tempfile.mkstemp(suffix=".png")

            try:
                # Try using gnome-screenshot
                rc = subprocess.call(  # nosec
                    ["gnome-screenshot", "-f", fname], env=env
                )
                if rc == 0:
                    return Image.open(fname)
            except FileNotFoundError:
                # Try using spectacle (KDE)
                try:
                    rc = subprocess.call(  # nosec
                        ["spectacle", "-b", "-n", "-o", fname], env=env
                    )
                    if rc == 0:
                        return Image.open(fname)
                except FileNotFoundError:
                    pass  # Fall through to ValueError
            finally:
                os.unlink(fname)
    raise ValueError("Unable to capture screenshot")


def scan_qr(image_data=None):
    if image_data:
        msg = base64.b64decode(image_data)
        buf = io.BytesIO(msg)
        img = Image.open(buf)
    else:
        img = _capture_screen()

    result = zxingcpp.read_barcode(img)
    if result and result.valid:
        return result.text
    return None
