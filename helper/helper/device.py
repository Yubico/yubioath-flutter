# Copyright (c) 2021 Yubico AB
# All rights reserved.
#
#   Redistribution and use in source and binary forms, with or
#   without modification, are permitted provided that the following
#   conditions are met:
#
#    1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


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
from .qr import scan_qr
from ykman import __version__ as ykman_version
from ykman.base import PID
from ykman.device import scan_devices, list_all_devices
from ykman.diagnostics import get_diagnostics
from ykman.logging import set_log_level
from yubikit.core import TRANSPORT
from yubikit.core.smartcard import SmartCardConnection, ApduError, SW
from yubikit.core.otp import OtpConnection
from yubikit.core.fido import FidoConnection
from yubikit.support import get_name, read_info
from yubikit.management import CAPABILITY
from yubikit.logging import LOG_LEVEL

from ykman.pcsc import list_devices, YK_READER_NAME
from smartcard.Exceptions import SmartcardException, NoCardException
from smartcard.pcsc.PCSCExceptions import EstablishContextException
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
    def __init__(self, connection, exc_type):
        super().__init__(
            "connection-error",
            f"Error connecting to {connection} interface",
            dict(connection=connection, exc_type=type(exc_type).__name__),
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

    def __call__(self, *args, **kwargs):
        with self._get_state:
            return super().__call__(*args, **kwargs)

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

    def __call__(self, *args, **kwargs):
        try:
            return super().__call__(*args, **kwargs)
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
    def __init__(self, device, info):
        super().__init__(device, info)

    def _supports_connection(self, conn_type):
        return self._device.supports_connection(conn_type)

    def _create_connection(self, conn_type):
        connection = self._device.open_connection(conn_type)
        return ConnectionNode(self._device, connection, self._info)

    def get_data(self):
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
            raise ConnectionException("ccid", e)

    @child(condition=lambda self: self._supports_connection(OtpConnection))
    def otp(self):
        try:
            return self._create_connection(OtpConnection)
        except (ValueError, OSError) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException("otp", e)

    @child(condition=lambda self: self._supports_connection(FidoConnection))
    def fido(self):
        try:
            return self._create_connection(FidoConnection)
        except (ValueError, OSError) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException("fido", e)


class ReaderDeviceNode(AbstractDeviceNode):
    def get_data(self):
        try:
            with self._device.open_connection(SmartCardConnection) as conn:
                return dict(self._read_data(conn), present=True)
        except NoCardException:
            return dict(present=False)

    @child
    def ccid(self):
        try:
            connection = self._device.open_connection(SmartCardConnection)
            info = read_info(connection)
            return ConnectionNode(self._device, connection, info)
        except (ValueError, SmartcardException, EstablishContextException) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException("ccid", e)

    @child
    def fido(self):
        try:
            with self._device.open_connection(SmartCardConnection) as conn:
                info = read_info(conn)
            connection = self._device.open_connection(FidoConnection)
            return ConnectionNode(self._device, connection, info)
        except (ValueError, SmartcardException, EstablishContextException) as e:
            logger.warning("Error opening connection", exc_info=True)
            raise ConnectionException("fido", e)


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

    @child(
        condition=lambda self: self._transport == TRANSPORT.USB
        or isinstance(self._connection, SmartCardConnection)
    )
    def management(self):
        return ManagementNode(self._connection)

    @child(
        condition=lambda self: isinstance(self._connection, SmartCardConnection)
        and CAPABILITY.OATH in self.capabilities
    )
    def oath(self):
        return OathNode(self._connection)

    @child(
        condition=lambda self: isinstance(self._connection, FidoConnection)
        and CAPABILITY.FIDO2 in self.capabilities
    )
    def ctap2(self):
        return Ctap2Node(self._connection)

    @child(
        condition=lambda self: CAPABILITY.OTP in self.capabilities
        and (
            isinstance(self._connection, OtpConnection)
            or (  # SmartCardConnection can be used over NFC, or on 5.3 and later.
                isinstance(self._connection, SmartCardConnection)
                and (
                    self._transport == TRANSPORT.NFC or self._info.version >= (5, 3, 0)
                )
            )
        )
    )
    def yubiotp(self):
        return YubiOtpNode(self._connection)
