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

from .base import RpcResponse, RpcNode, action
from yubikit.core import (
    require_version,
    NotSupportedError,
    TRANSPORT,
    USB_INTERFACE,
    Connection,
)
from yubikit.core.smartcard import SmartCardConnection
from yubikit.core.otp import OtpConnection
from yubikit.core.fido import FidoConnection
from yubikit.management import (
    ManagementSession,
    DeviceConfig,
    Mode,
    CAPABILITY,
    DEVICE_FLAG,
)
from ykman.device import list_all_devices
from dataclasses import asdict
from time import sleep
from typing import Type
import logging

logger = logging.getLogger(__name__)


class ManagementNode(RpcNode):
    def __init__(self, connection, scp_params=None):
        super().__init__()
        self._connection_type: Type[Connection] = type(connection)
        self.session = ManagementSession(connection, scp_params)

    def get_data(self):
        try:
            return asdict(self.session.read_device_info())
        except NotSupportedError:
            return {}

    def list_actions(self):
        actions = super().list_actions()
        try:
            require_version(self.session.version, (5, 0, 0))
            actions.remove("set_mode")
        except NotSupportedError:
            actions.remove("configure")
        return actions

    def _await_reboot(self, serial, usb_enabled):
        ifaces = CAPABILITY(usb_enabled or 0).usb_interfaces

        types: list[Type[Connection]] = [
            SmartCardConnection,
            OtpConnection,
            # mypy doesn't support ABC.register()
            FidoConnection,  # type: ignore
        ]
        connection_types = [t for t in types if t.usb_interface in ifaces]
        # Prefer to use the "same" connection type as before
        if self._connection_type in connection_types:
            connection_types.remove(self._connection_type)
            connection_types.insert(0, self._connection_type)

        self.session.close()
        logger.debug(f"Waiting for device to re-appear over {connection_types}...")
        for _ in range(10):
            sleep(0.2)  # Always sleep initially
            for dev, info in list_all_devices(connection_types):
                if info.serial == serial:
                    return
            logger.debug("Not found, sleep...")
        else:
            logger.warning("Timed out waiting for device")

    @action
    def configure(
        self,
        reboot: bool = False,
        cur_lock_code: str = "",
        new_lock_code: str = "",
        enabled_capabilities: dict = {},
        auto_eject_timeout: int | None = None,
        challenge_response_timeout: int | None = None,
        device_flags: int | None = None,
    ):
        cur_code = bytes.fromhex(cur_lock_code) or None
        new_code = bytes.fromhex(new_lock_code) or None
        config = DeviceConfig(
            enabled_capabilities,
            auto_eject_timeout,
            challenge_response_timeout,
            DEVICE_FLAG(device_flags) if device_flags else None,
        )
        serial = self.session.read_device_info().serial
        self.session.write_device_config(config, reboot, cur_code, new_code)
        flags = ["device_info"]
        if reboot:
            enabled = config.enabled_capabilities.get(TRANSPORT.USB)
            flags.append("device_closed")
            self._await_reboot(serial, enabled)
        return RpcResponse(dict(), flags)

    @action
    def set_mode(
        self,
        interfaces: int,
        challenge_response_timeout: int = 0,
        auto_eject_timeout: int | None = None,
    ):
        self.session.set_mode(
            Mode(USB_INTERFACE(interfaces)),
            challenge_response_timeout,
            auto_eject_timeout,
        )
        return dict()

    @action(
        condition=lambda self: issubclass(self._connection_type, SmartCardConnection)
    )
    def device_reset(self):
        self.session.device_reset()
        return RpcResponse(dict(), ["device_info"])
