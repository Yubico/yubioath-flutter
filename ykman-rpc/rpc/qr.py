import mss
import zxingcpp
import base64
import io
from PIL import Image


def scan_qr(image_data = None):
    if (image_data):
        msg = base64.b64decode(image_data)
        buf = io.BytesIO(msg)
        img = Image.open(buf)
    else:
        with mss.mss() as sct:
            monitor = sct.monitors[0]  # 0 is the special "all monitors" value.
            sct_img = sct.grab(monitor)  # mss format
        img = Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")
    result = zxingcpp.read_barcode(img)
    if result.valid:
        return result.text
    raise ValueError("Unable to read QR code")
