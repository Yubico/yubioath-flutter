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
import io
import os
import subprocess  # nosec
import sys
import tempfile

import mss
import zxingcpp
from mss.exception import ScreenShotError
from PIL import Image, UnidentifiedImageError

from .base import RpcException


def _capture_with_mss():
    with mss.mss() as sct:
        monitor = sct.monitors[0]  # 0 is the special "all monitors" value.
        sct_img = sct.grab(monitor)  # mss format
    return Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")


def _capture_with_tools():
    # Call screenshot tools, with original library path
    env = dict(os.environ)
    lp = env.get("LD_LIBRARY_PATH_ORIG")
    if lp is not None:
        env["LD_LIBRARY_PATH"] = lp
    else:
        env.pop("LD_LIBRARY_PATH", None)
    fd, fname = tempfile.mkstemp(suffix=".png")
    os.close(fd)

    # Try each tool in turn until one produces a usable image.
    tools = [
        ["gnome-screenshot", "-f", fname],  # GNOME
        ["spectacle", "-b", "-n", "-o", fname],  # KDE
        ["grim", fname],  # wlroots (Sway, Hyprland, ...)
    ]
    try:
        for cmd in tools:
            try:
                rc = subprocess.call(cmd, env=env)  # noqa: S603
                if rc != 0 or os.path.getsize(fname) == 0:
                    continue
                with Image.open(fname) as img:
                    img.load()
                    return img.copy()
            except (OSError, UnidentifiedImageError):
                continue
    finally:
        os.unlink(fname)
    return None


def _is_wayland():
    return (
        os.environ.get("XDG_SESSION_TYPE", "").lower() == "wayland"
        or "WAYLAND_DISPLAY" in os.environ
    )


def _capture_screen():
    linux = sys.platform.startswith("linux")
    # Under Wayland, mss may "succeed" via XWayland but only capture a blank
    # screen, so prefer the native tools there.
    if linux and _is_wayland():
        img = _capture_with_tools()
        if img is not None:
            return img
    try:
        return _capture_with_mss()
    except ScreenShotError:
        if linux and not _is_wayland():
            img = _capture_with_tools()
            if img is not None:
                return img
    raise ValueError("Unable to capture screenshot")


class InvalidImageException(RpcException):
    def __init__(self):
        super().__init__(
            "invalid-image",
            "The provided file is not a valid image",
        )


def scan_qr(image_data=None):
    if image_data:
        try:
            msg = base64.b64decode(image_data)
            buf = io.BytesIO(msg)
            img = Image.open(buf)
        except UnidentifiedImageError:
            raise InvalidImageException()
    else:
        img = _capture_screen()

    result = zxingcpp.read_barcode(img)
    if result and result.valid:
        return result.text
    return None
