"""USB power and touch control for a YubiKey on the Pico test fixture."""

import time
from urllib.request import urlopen


class PicoController:
    def __init__(self, base_url: str, port: int):
        self.base_url = base_url.rstrip("/")
        self.port = port

    def _get(self, action: str) -> None:
        url = f"{self.base_url}/usb{self.port}/{action}"
        with urlopen(url, timeout=5) as response:
            if response.status != 200:
                raise RuntimeError(f"Pico controller returned {response.status}: {url}")
            response.read()

    def touch(self) -> None:
        self.release()
        time.sleep(0.2)
        self._get("touch/on")

    def release(self) -> None:
        self._get("touch/off")

    def remove(self) -> None:
        self.release()
        self._get("power/off")

    def restore(self) -> None:
        try:
            self.release()
        finally:
            self._get("power/on")
