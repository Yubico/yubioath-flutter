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

import base64
import os
import sys
import subprocess
import tempfile
import mss
from mss.exception import ScreenShotError
from mss.tools import to_png


def capture_screen():
    try:
        with mss.mss() as sct:
            monitor = sct.monitors[0]  # 0 is the special "all monitors" value.
            sct_img = sct.grab(monitor)  # mss format
        png = to_png(sct_img.rgb, sct_img.size)
        return base64.b64encode(png).decode()
    except ScreenShotError:
        # One common error is that mss doesn't work with Wayland
        if sys.platform.startswith("linux"):
            # Try gnome-screenshot fallback
            fd, fname = tempfile.mkstemp(suffix=".png")
            try:
                rc = subprocess.call(["gnome-screenshot", "-f", fname])  # nosec
                if rc == 0:
                    with open(fname, "rb") as f:
                        return f.read()
            except FileNotFoundError:
                pass  # Fall through to ValueError
            finally:
                os.unlink(fname)
    raise ValueError("Unable to capture screenshot")
