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

from .base import (
    RpcNode,
    child,
    action,
    RpcException,
    NoSuchNodeException,
    ChildResetException,
)
from .oath import OathNode
from .fido import Ctap2Node
from .yubiotp import YubiOtpNode
from .management import ManagementNode
from .piv import PivNode
from .qr import scan_qr
from ykman import __version__ as ykman_version
from ykman.base import PID
from ykman.device import scan_devices, list_all_devices
from ykman.diagnostics import get_diagnostics
from ykman.logging import set_log_level
from yubikit.core import TRANSPORT, NotSupportedError
from yubikit.core.smartcard import (
    SmartCardConnection,
    ApduError,
    SW,
    SmartCardProtocol,
    ApplicationNotAvailableError,
)
from yubikit.core.smartcard.scp import Scp11KeyParams
from yubikit.core.otp import OtpConnection
from yubikit.core.fido import FidoConnection
from yubikit.support import get_name, read_info
from yubikit.management import CAPABILITY
from yubikit.securitydomain import SecurityDomainSession
from yubikit.logging import LOG_LEVEL

from ykman.pcsc import list_devices, YK_READER_NAME
from smartcard.Exceptions import SmartcardException, NoCardException
from smartcard.pcsc.PCSCExceptions import EstablishContextException
from smartcard.CardMonitoring import CardObserver, CardMonitor
from cryptography.hazmat.primitives.asymmetric.ec import EllipticCurvePublicKey
from hashlib import sha256
from dataclasses import asdict
from typing import Mapping, Tuple

import os
import sys
import ctypes
import logging

logger = logging.getLogger(__name__)


def _is_admin():
    if sys.platform == "win32":
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    return os.getuid() == 0


class ConnectionException(RpcException):
    def __init__(self, device, connection, exc_type):
        super().__init__(
            "connection-error",
            f"Error connecting to {connection} interface",
            dict(
                device=device,
                connection=connection,
                exc_type=type(exc_type).__name__,
            ),
        )


class RootNode(RpcNode):
    def __init__(self):
        super().__init__()
        self._devices = DevicesNode()
        self._readers = ReadersNode()

    def __call__(self, *args):
        result = super().__call__(*args)
        if result is None:
            result = {}
        return result

    def get_child(self, name):
        self._child = self.create_child(name)
        self._child_name = name
        return self._child

    def get_data(self):
        return dict(version=ykman_version, is_admin=_is_admin())

    @child
    def usb(self):
        return self._devices

    @child
    def nfc(self):
        return self._readers

    @action
    def diagnose(self, *ignored):
        return dict(diagnostics=get_diagnostics())

    @action(closes_child=False)
    def logging(self, params, event, signal):
        level = LOG_LEVEL[params["level"].upper()]
        set_log_level(level)
        logger.info(f"Log level set to: {level.name}")
        return dict()

    @action(closes_child=False)
    def qr(self, params, event, signal):
        return dict(result=scan_qr(params.get("image")))


def _id_from_fingerprint(fp):
    if isinstance(fp, str):
        fp = fp.encode()
    return sha256(fp).hexdigest()[:16]


class ReadersNode(RpcNode):
    def __init__(self):
        super().__init__()
        self._state = set()
        self._readers = {}
        self._reader_mapping = {}

    @action(closes_child=False)
    def scan(self, *ignored):
        return self.list_children()

    def list_children(self):
        try:
            devices = [
                d
                for d in list_devices("")
                if YK_READER_NAME not in d.reader.name.lower()
            ]
        except EstablishContextException:
            logger.warning("Unable to list readers", exc_info=True)
            return {}

        state = {d.reader.name for d in devices}
        if self._state != state:
            self._readers = {}
            self._reader_mapping = {}
            for device in devices:
                dev_id = _id_from_fingerprint(device.fingerprint)
                self._reader_mapping[dev_id] = device
                self._readers[dev_id] = dict(name=device.reader.name)
            self._state = state
        return self._readers

    def create_child(self, name):
        return ReaderDeviceNode(self._reader_mapping[name], None)


class _ScanDevices:
    def __init__(self):
        self._state: Tuple[Mapping[PID, int], int] = ({}, 0)
        self._caching = False

    def __call__(self):
        if not self._caching or not self._state[1]:
            self._state = scan_devices()
        return self._state

    def __enter__(self):
        self._caching = True
        self._state = ({}, 0)

    def __exit__(self, exc_type, exc, exc_tb):
        self._caching = False


class DevicesNode(RpcNode):
    def __init__(self):
        super().__init__()
        self._get_state = _ScanDevices()
        self._list_state = 0
        self._devices = {}
        self._device_mapping = {}
        self._failing_connection = {}
        self._retries = 0

    def __call__(self, *args, **kwargs):
        with self._get_state:
            try:
                return super().__call__(*args, **kwargs)
            except ConnectionException as e:
                if self._failing_connection == e.body:
                    self._retries += 1
                else:
                    self._failing_connection = e.body
                    self._retries = 0
                if self._retries > 2:
                    raise
                logger.debug("Connection failed, attempt to recover", exc_info=True)
                raise ChildResetException(f"{e}")

    def close(self):
        self._list_state = 0
        self._device_mapping = {}
        super().close()

    @action(closes_child=False)
    def scan(self, *ignored):
        return self.get_data()

    def get_data(self):
        state = self._get_state()
        return dict(state=state[1], pids=state[0])

    def list_children(self):
        state = self._get_state()
        if state[1] != self._list_state:
            logger.debug(f"State changed (was={self._list_state}, now={state[1]})")
            self._devices = {}
            self._device_mapping = {}
            for dev, info in list_all_devices():
                if info.serial:
                    dev_id = str(info.serial)
                else:
                    dev_id = _id_from_fingerprint(dev.fingerprint)
                self._device_mapping[dev_id] = (dev, info)
                name = get_name(info, dev.pid.yubikey_type if dev.pid else None)
                self._devices[dev_id] = dict(pid=dev.pid, name=name, serial=info.serial)

            if sum(state[0].values()) == len(self._devices):
                self._list_state = state[1]
                logger.debug("State updated: {state[1]}")
            else:
                logger.warning("Not all devices identified")
                self._list_state = 0

        return self._devices

    def create_child(self, name):
        if name not in self._device_mapping and self._list_state == 0:
            self.list_children()
        try:
            return UsbDeviceNode(*self._device_mapping[name])
        except KeyError:
            raise NoSuchNodeException(name)


class AbstractDeviceNode(RpcNode):
    def __init__(self, device, info):
        super().__init__()
        self._device = device
        self._info = info
        self._data = None

    def __call__(self, *args, **kwargs):
        try:
            response = super().__call__(*args, **kwargs)
            if "device_info" in response.flags:
                # Clear DeviceInfo cache
                self._info = None
                self._data = None
                # Make sure any child node is re-opened after this,
                # as enabled applications may have changed
                super().close()

            return response

        except (SmartcardException, OSError):
            logger.exception("Device error")

            self._child = None
            name = self._child_name
            self._child_name = None
            raise NoSuchNodeException(name)

    def create_child(self, name):
        try:
            return super().create_child(name)
        except (SmartcardException, OSError):
            logger.exception(f"Unable to create child {name}")
            raise NoSuchNodeException(name)

    def get_data(self):
        if not self._data:
            self._data = self._refresh_data()
        return self._data

    def _refresh_data(self):
        ...

    def _read_data(self, conn):
        pid = self._device.pid
        self._info = read_info(conn, pid)
        name = get_name(self._info, pid.yubikey_type if pid else None)
        return dict(
            pid=pid,
            name=name,
            transport=self._device.transport,
            info=asdict(self._info),
        )


class UsbDeviceNode(AbstractDeviceNode):
    def _supports_connection(self, conn_type):
        return self._device.pid.supports_connection(conn_type)

    def _create_connection(self, conn_type):
        connection = self._device.open_connection(conn_type)
        return ConnectionNode(self._device, connection, self._info)

    def _refresh_data(self):
        for conn_type in (SmartCardConnection, OtpConnection, FidoConnection):
            if self._supports_connection(conn_type):
                try:
                    with self._device.open_connection(conn_type) as conn:
                        return self._read_data(conn)
                except Exception:
                    logger.warning(f"Unable to connect via {conn_type}", exc_info=True)
        raise ValueError("No supported connections")

    @child(condition=lambda self: self._supports_connection(SmartCardConnection))
    def ccid(self):
        try:
            return self._create_connection(SmartCardConnection)
        except (ValueError, SmartcardException, EstablishContextException) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException(self._device.fingerprint, "ccid", e)

    @child(condition=lambda self: self._supports_connection(OtpConnection))
    def otp(self):
        try:
            return self._create_connection(OtpConnection)
        except (ValueError, OSError) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException(self._device.fingerprint, "otp", e)

    @child(condition=lambda self: self._supports_connection(FidoConnection))
    def fido(self):
        try:
            return self._create_connection(FidoConnection)
        except (ValueError, OSError) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException(self._device.fingerprint, "fido", e)


class _ReaderObserver(CardObserver):
    def __init__(self, device):
        self.device = device
        self.card = None
        self.needs_refresh = True

    def update(self, observable, actions):
        added, removed = actions
        for card in added:
            if card.reader == self.device.reader.name:
                if card != self.card:
                    self.card = card
                break
        else:
            self.card = None
        self.needs_refresh = True
        logger.debug(f"NFC card: {self.card}")


RESTRICTED_NDEF = bytes.fromhex("001fd1011b5504") + b"yubico.com/getting-started"


class ReaderDeviceNode(AbstractDeviceNode):
    def __init__(self, device, info):
        super().__init__(device, info)
        self._observer = _ReaderObserver(device)
        self._monitor = CardMonitor()
        self._monitor.addObserver(self._observer)

    def close(self):
        self._monitor.deleteObserver(self._observer)
        super().close()

    def get_data(self):
        if self._observer.needs_refresh:
            self._data = None
        return super().get_data()

    def _refresh_data(self):
        card = self._observer.card
        if card is None:
            return dict(present=False, status="no-card")
        try:
            with self._device.open_connection(SmartCardConnection) as conn:
                try:
                    data = dict(self._read_data(conn), present=True)
                except ValueError:
                    # Unknown device, maybe NFC restricted
                    try:
                        p = SmartCardProtocol(conn)
                        p.select(bytes.fromhex("D2760000850101"))
                        p.send_apdu(0, 0xA4, 0x00, 0x0C, bytes.fromhex("E104"))
                        ndef = p.send_apdu(0, 0xB0, 0, 0)
                    except (ApduError, ApplicationNotAvailableError):
                        ndef = None

                    if ndef == RESTRICTED_NDEF:
                        data = dict(present=False, status="restricted-nfc")
                    else:
                        data = dict(present=False, status="unknown-device")

            self._observer.needs_refresh = False
            return data
        except NoCardException:
            return dict(present=False, status="no-card")

    @action(closes_child=False)
    def get(self, params, event, signal):
        return super().get(params, event, signal)

    @child
    def ccid(self):
        try:
            connection = self._device.open_connection(SmartCardConnection)
            info = read_info(connection)
            return ScpConnectionNode(self._device, connection, info)
        except (ValueError, SmartcardException, EstablishContextException) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException(self._device.fingerprint, "ccid", e)

    @child
    def fido(self):
        try:
            with self._device.open_connection(SmartCardConnection) as conn:
                info = read_info(conn)
            connection = self._device.open_connection(FidoConnection)
            return ConnectionNode(self._device, connection, info)
        except (ValueError, SmartcardException, EstablishContextException) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException(self._device.fingerprint, "fido", e)


class ConnectionNode(RpcNode):
    def __init__(self, device, connection, info):
        super().__init__()
        self._device = device
        self._transport = device.transport
        self._connection = connection
        self._info = info or read_info(self._connection, device.pid)

    def __call__(self, *args, **kwargs):
        try:
            return super().__call__(*args, **kwargs)
        except (SmartcardException, OSError) as e:
            logger.exception("Connection error")
            raise ChildResetException(f"{e}")
        except ApduError as e:
            if e.sw == SW.INVALID_INSTRUCTION:
                raise ChildResetException(f"SW: {e.sw}")
            raise e

    @property
    def capabilities(self):
        return self._info.config.enabled_capabilities[self._transport]

    def close(self):
        super().close()
        try:
            self._connection.close()
        except Exception:
            logger.warning("Error closing connection", exc_info=True)

    def get_data(self):
        if (
            isinstance(self._connection, SmartCardConnection)
            or self._transport == TRANSPORT.USB
        ):
            self._info = read_info(self._connection, self._device.pid)
        return dict(version=self._info.version, serial=self._info.serial)

    def _init_child_node(self, child_cls, capability=CAPABILITY(0)):
        return child_cls(self._connection)

    @child(
        condition=lambda self: self._transport == TRANSPORT.USB
        or isinstance(self._connection, SmartCardConnection)
    )
    def management(self):
        return self._init_child_node(ManagementNode)

    @child(
        condition=lambda self: isinstance(self._connection, SmartCardConnection)
        and CAPABILITY.OATH in self.capabilities
    )
    def oath(self):
        return self._init_child_node(OathNode, CAPABILITY.OATH)

    @child(
        condition=lambda self: isinstance(self._connection, SmartCardConnection)
        and CAPABILITY.PIV in self.capabilities
    )
    def piv(self):
        return self._init_child_node(PivNode, CAPABILITY.PIV)

    @child(
        condition=lambda self: isinstance(self._connection, FidoConnection)
        and CAPABILITY.FIDO2 in self.capabilities
    )
    def ctap2(self):
        return self._init_child_node(Ctap2Node)

    @child(
        condition=lambda self: CAPABILITY.OTP in self.capabilities
        and (
            isinstance(self._connection, OtpConnection)
            or (  # SmartCardConnection can be used over NFC, or on 5.3 and later.
                isinstance(self._connection, SmartCardConnection)
                and (
                    self._transport == TRANSPORT.NFC
                    or self._info.version >= (5, 3, 0)
                    or self._info.version[0] == 3
                )
            )
        )
    )
    def yubiotp(self):
        return self._init_child_node(YubiOtpNode)


class ScpConnectionNode(ConnectionNode):
    def __init__(self, device, connection, info):
        super().__init__(device, connection, info)

        self.fips_capable = info.fips_capable
        self.scp_params = None
        try:
            if self.fips_capable != 0:
                scp = SecurityDomainSession(connection)

                for ref in scp.get_key_information().keys():
                    if ref.kid == 0x13:
                        chain = scp.get_certificate_bundle(ref)
                        if chain:
                            pub_key = chain[-1].public_key()
                            assert isinstance(pub_key, EllipticCurvePublicKey)  # nosec
                            self.scp_params = Scp11KeyParams(ref, pub_key)
                            break
        except NotSupportedError:
            pass

    def _init_child_node(self, child_cls, capability=CAPABILITY(0)):
        if capability in self.fips_capable:
            return child_cls(self._connection, self.scp_params)
        return child_cls(self._connection)
