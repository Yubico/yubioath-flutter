import mss
import zxingcpp
from PIL import Image


def scan_qr():
    with mss.mss() as sct:
        monitor = sct.monitors[0]  # 0 is the special "all monitors" value.
        sct_img = sct.grab(monitor)  # mss format
    img = Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")

    result = zxingcpp.read_barcode(img)
    if result.valid:
        return result.text
    raise ValueError("Unable to read QR code")
