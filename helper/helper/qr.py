import mss
import zxingcpp
import base64
import io
import os
import sys
import subprocess
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
            # Try gnome-screenshot fallback
            fd, fname = tempfile.mkstemp(suffix=".png")
            try:
                rc = subprocess.call(["gnome-screenshot", "-f", fname])  # nosec
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
    if result.valid:
        return result.text
    return None
