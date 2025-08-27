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

import ctypes
import logging
import os
import sys
from dataclasses import asdict
from hashlib import sha256
from typing import Mapping

from cryptography.hazmat.primitives.asymmetric.ec import EllipticCurvePublicKey
from fido2.ctap import CtapError
from smartcard.CardMonitoring import CardMonitor, CardObserver
from smartcard.Exceptions import NoCardException, SmartcardException
from smartcard.pcsc.PCSCExceptions import EstablishContextException
from ykman import __version__ as ykman_version
from ykman.device import list_all_devices, scan_devices
from ykman.diagnostics import get_diagnostics
from ykman.logging import set_log_level
from ykman.pcsc import YK_READER_NAME, list_devices
from yubikit.core import PID, TRANSPORT, NotSupportedError, _override_version
from yubikit.core.fido import FidoConnection, SmartCardCtapDevice
from yubikit.core.otp import OtpConnection
from yubikit.core.smartcard import (
    SW,
    ApduError,
    ApplicationNotAvailableError,
    SmartCardConnection,
    SmartCardProtocol,
)
from yubikit.core.smartcard.scp import Scp11KeyParams
from yubikit.logging import LOG_LEVEL
from yubikit.management import CAPABILITY, RELEASE_TYPE
from yubikit.securitydomain import SecurityDomainSession
from yubikit.support import get_name, read_info

from .base import (
    ChildResetException,
    NoSuchNodeException,
    RpcException,
    RpcNode,
    action,
    child,
)
from .fido import Ctap2Node
from .management import ManagementNode
from .oath import OathNode
from .piv import PivNode
from .qr import scan_qr
from .yubiotp import YubiOtpNode

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
    def diagnose(self):
        return dict(diagnostics=get_diagnostics())

    @action(closes_child=False)
    def logging(self, level: str):
        lvl = LOG_LEVEL[level.upper()]
        set_log_level(lvl)
        logger.info(f"Log level set to: {lvl.name}")
        return dict()

    @action(closes_child=False)
    def qr(self, image: str | None = None):
        return dict(result=scan_qr(image))


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
        self.scan()

    @action(closes_child=False)
    def scan(self):
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
        return ReaderDeviceNode(self._reader_mapping[name])


class _ScanDevices:
    def __init__(self):
        self._state: tuple[Mapping[PID, int], int] = ({}, 0)
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
                response = super().__call__(*args, **kwargs)
                if "device_closed" in response.flags:
                    self._list_state = 0
                    self._device_mapping = {}
                    response.flags.remove("device_closed")
                return response
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
    def scan(self):
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
                self._device_mapping[dev_id] = dev
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
            return UsbDeviceNode(self._device_mapping[name])
        except KeyError:
            raise NoSuchNodeException(name)


class AbstractDeviceNode(RpcNode):
    def __init__(self, device):
        super().__init__()
        self._device = device
        self._info = None
        self._data = self._refresh_data()

    def __call__(self, *args, **kwargs):
        try:
            response = super().__call__(*args, **kwargs)

            # The command resulted in the device closing
            if "device_closed" in response.flags:
                self.close()
                return response

            # The command resulted in device_info modification
            if "device_info" in response.flags:
                old_info = self._info
                # Refresh data
                self._data = self._refresh_data()
                if old_info == self._info:
                    # No change to DeviceInfo, further propagation not needed.
                    response.flags.remove("device_info")

            return response

        except (SmartcardException, OSError):
            logger.exception("Device error", exc_info=True)

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
        if self._data:
            return self._data
        raise ChildResetException("Unable to read device data")

    def _refresh_data(self): ...

    def _read_data(self, conn):
        pid = self._device.pid
        self._info = read_info(conn, pid)
        if self._info.version_qualifier.type != RELEASE_TYPE.FINAL:
            _override_version(self._info.version_qualifier.version)
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
        # Re-use existing connection if possible
        if self._child and not self._child.closed:
            # Make sure to close any open session
            self._child._close_child()
            try:
                return self._read_data(self._child._connection)
            except Exception:
                logger.warning(
                    f"Unable to use {self._child._connection}", exc_info=True
                )

        # No child, open new connection
        for conn_type in (SmartCardConnection, OtpConnection, FidoConnection):
            if self._supports_connection(conn_type):
                try:
                    with self._device.open_connection(conn_type) as conn:
                        return self._read_data(conn)
                except Exception:
                    logger.warning(f"Unable to connect via {conn_type}", exc_info=True)
        # Failed to refresh, close
        self.close()
        return None

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
        except Exception as e:  # TODO: Replace with ConnectionError once added
            if "Wrong" in str(e):
                logger.warning("Error opening connection", exc_info=True)
                raise ConnectionException(self._device.fingerprint, "fido", e)
            raise


class _ReaderObserver(CardObserver):
    def __init__(self, device):
        self.device = device
        self.needs_refresh = True

    def update(self, observable, actions):
        added, removed = actions

        for card in added + removed:
            if card.reader == self.device.reader.name:
                self.needs_refresh = True
                break


RESTRICTED_NDEF = bytes.fromhex("001fd1011b5504") + b"yubico.com/getting-started"


class ReaderDeviceNode(AbstractDeviceNode):
    def __init__(self, device):
        self._observer = _ReaderObserver(device)
        self._monitor = CardMonitor()
        self._monitor.addObserver(self._observer)
        super().__init__(device)

    def close(self):
        self._monitor.deleteObserver(self._observer)
        super().close()

    def get_data(self):
        if self._observer.needs_refresh:
            self._data = self._refresh_data()
        return super().get_data()

    def _read_data(self, conn):
        return dict(super()._read_data(conn), present=True)

    def _refresh_data(self):
        try:
            self._close_child()
            with self._device.open_connection(SmartCardConnection) as conn:
                try:
                    data = self._read_data(conn)
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
    def get(self):
        return super().get()

    @child
    def ccid(self):
        try:
            connection = self._device.open_connection(SmartCardConnection)
            if not self._info:
                self._read_data(connection)
            return ScpConnectionNode(self._device, connection, self._info)
        except (ValueError, SmartcardException, EstablishContextException) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException(self._device.fingerprint, "ccid", e)

    @child
    def fido(self):
        try:
            if not self._info:
                with self._device.open_connection(SmartCardConnection) as connection:
                    self._read_data(connection)
            connection = self._device.open_connection(FidoConnection)
            return ConnectionNode(
                self._device, connection, self._info, self._device.reader.name
            )
        except (ValueError, SmartcardException, EstablishContextException) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException(self._device.fingerprint, "fido", e)


class ConnectionNode(RpcNode):
    def __init__(self, device, connection, info, reader_name=None):
        super().__init__()
        self._device = device
        self._transport = device.transport
        self._connection = connection
        self._info = info
        self._reader_name = reader_name

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
        except CtapError as e:
            if e.code == CtapError.ERR.CHANNEL_BUSY:
                raise ChildResetException(str(e))
            raise
        except Exception as e:  # TODO: Replace with ConnectionError once added
            words = str(e).split()
            try:
                word = words[words.index("Wrong") + 1]
                if word in ("nonce", "channel", "sequence"):
                    raise ChildResetException(str(e))
            except ValueError:
                pass
            raise

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
        return dict(version=self._info.version, serial=self._info.serial)

    def _init_child_node(self, child_cls, capability=CAPABILITY(0), **kwargs):
        return child_cls(self._connection, **kwargs)

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
        return self._init_child_node(
            PivNode, CAPABILITY.PIV, capabilities=self.capabilities
        )

    @child(
        condition=lambda self: CAPABILITY.FIDO2 in self.capabilities
        and (
            isinstance(self._connection, FidoConnection)
            or (  # SmartCardConnection can be used over USB if enabled
                isinstance(self._connection, SmartCardConnection)
                and self._info.config.enabled_capabilities[self._transport] & 0x1000
            )
        )
    )
    def ctap2(self):
        if isinstance(self._connection, SmartCardConnection):
            return Ctap2Node(
                SmartCardCtapDevice(self._connection),
                device=self._device,
                reader_name=self._reader_name,
            )
        return self._init_child_node(
            Ctap2Node, device=self._device, reader_name=self._reader_name
        )

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
                            assert isinstance(pub_key, EllipticCurvePublicKey)  # noqa: S101
                            self.scp_params = Scp11KeyParams(ref, pub_key)
                            break
        except NotSupportedError:
            pass

    def _init_child_node(self, child_cls, capability=CAPABILITY(0), **kwargs):
        if capability in self.fips_capable:
            return child_cls(self._connection, self.scp_params, **kwargs)
        return child_cls(self._connection, **kwargs)
