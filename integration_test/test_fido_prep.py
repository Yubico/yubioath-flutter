import unittest
from types import SimpleNamespace
from unittest.mock import Mock, patch

from yubikit.core import TRANSPORT
from yubikit.core.fido import FidoConnection

import fido_prep


class FidoConnectionTests(unittest.TestCase):
    def test_usb_uses_native_fido_connection(self):
        device = Mock(transport=TRANSPORT.USB)

        connection = fido_prep._open_ctap_device(device)

        self.assertIs(connection, device.open_connection.return_value)
        device.open_connection.assert_called_once_with(FidoConnection)

    def test_nfc_uses_selected_reader(self):
        device = SimpleNamespace(transport=TRANSPORT.NFC, reader_name="Test reader")
        connection = Mock()
        with patch(
            "fido2.pcsc.CtapPcscDevice.list_devices", return_value=iter([connection])
        ) as discover:
            self.assertIs(fido_prep._open_ctap_device(device), connection)
        discover.assert_called_once_with("Test reader")

    def test_unavailable_nfc_connection_reports_reader_and_windows_permissions(self):
        device = SimpleNamespace(transport=TRANSPORT.NFC, reader_name="Test reader")
        with patch("fido2.pcsc.CtapPcscDevice.list_devices", return_value=iter([])):
            with self.assertRaisesRegex(ValueError, "reader Test reader.*administrator"):
                fido_prep._open_ctap_device(device)


if __name__ == "__main__":
    unittest.main()
