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

from .base import RpcNode, action
from yubikit.core import require_version, NotSupportedError, TRANSPORT
from yubikit.core.smartcard import SmartCardConnection
from yubikit.core.otp import OtpConnection
from yubikit.core.fido import FidoConnection
from yubikit.management import ManagementSession, DeviceConfig, Mode, CAPABILITY
from ykman.device import list_all_devices
from dataclasses import asdict
from time import sleep
import logging

logger = logging.getLogger(__name__)


class ManagementNode(RpcNode):
    def __init__(self, connection):
        super().__init__()
        self._connection_type = type(connection)
        self.session = ManagementSession(connection)

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

        # Prefer to use the "same" connection type as before
        if self._connection_type.usb_interface in ifaces:
            connection_types = [self._connection_type]
        else:
            connection_types = [
                t
                for t in [SmartCardConnection, OtpConnection, FidoConnection]
                if ifaces.supports_connection(t)
            ]

        self.session.close()
        logger.debug("Waiting for device to re-appear...")
        for _ in range(10):
            sleep(0.2)  # Always sleep initially
            for dev, info in list_all_devices(connection_types):
                if info.serial == serial:
                    return
            logger.debug("Not found, sleep...")
        else:
            logger.warning("Timed out waiting for device")

    @action
    def configure(self, params, event, signal):
        reboot = params.pop("reboot", False)
        cur_lock_code = bytes.fromhex(params.pop("cur_lock_code", "")) or None
        new_lock_code = bytes.fromhex(params.pop("new_lock_code", "")) or None
        config = DeviceConfig(
            params.pop("enabled_capabilities", {}),
            params.pop("auto_eject_timeout", None),
            params.pop("challenge_response_timeout", None),
            params.pop("device_flags", None),
        )
        serial = self.session.read_device_info().serial
        self.session.write_device_config(config, reboot, cur_lock_code, new_lock_code)
        if reboot:
            enabled = config.enabled_capabilities.get(TRANSPORT.USB)
            self._await_reboot(serial, enabled)
        return dict()

    @action
    def set_mode(self, params, event, signal):
        self.session.set_mode(
            Mode(params["interfaces"]),
            params.pop("challenge_response_timeout", 0),
            params.pop("auto_eject_timeout"),
        )
        return dict()
