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

from .base import RpcNode, action, child

from yubikit.core import NotSupportedError, CommandError
from yubikit.core.otp import modhex_encode, modhex_decode
from yubikit.yubiotp import (
    YubiOtpSession,
    SLOT,
    UpdateConfiguration,
    HmacSha1SlotConfiguration,
    HotpSlotConfiguration,
    StaticPasswordSlotConfiguration,
    YubiOtpSlotConfiguration,
    StaticTicketSlotConfiguration,
)
from ykman.otp import generate_static_pw, format_csv
from yubikit.oath import parse_b32_key
from ykman.scancodes import KEYBOARD_LAYOUT, encode

from typing import Dict
import struct

_FAIL_MSG = (
    "Failed to write to the YubiKey. Make sure the device does not "
    "have restricted access"
)


class YubiOtpNode(RpcNode):
    def __init__(self, connection, scp_params=None):
        super().__init__()
        self.session = YubiOtpSession(connection, scp_params)

    def get_data(self):
        state = self.session.get_config_state()
        data: Dict[str, bool] = {}
        try:
            data.update(
                slot1_configured=state.is_configured(SLOT.ONE),
                slot2_configured=state.is_configured(SLOT.TWO),
            )
            data.update(
                slot1_touch_triggered=state.is_touch_triggered(SLOT.ONE),
                slot2_touch_triggered=state.is_touch_triggered(SLOT.TWO),
            )
            data.update(
                is_led_inverted=state.is_led_inverted(),
            )
        except NotSupportedError:
            pass
        return data

    @action
    def swap(self, params, event, signal):
        try:
            self.session.swap_slots()
        except CommandError:
            raise ValueError(_FAIL_MSG)
        return dict()

    @child
    def one(self):
        return SlotNode(self.session, SLOT.ONE)

    @child
    def two(self):
        return SlotNode(self.session, SLOT.TWO)

    @action(closes_child=False)
    def serial_modhex(self, params, event, signal):
        serial = params["serial"]
        return dict(encoded=modhex_encode(b"\xff\x00" + struct.pack(b">I", serial)))

    @action(closes_child=False)
    def generate_static(self, params, event, signal):
        layout, length = params["layout"], int(params["length"])
        return dict(password=generate_static_pw(length, KEYBOARD_LAYOUT[layout]))

    @action(closes_child=False)
    def keyboard_layouts(self, params, event, signal):
        return {layout.name: [sc for sc in layout.value] for layout in KEYBOARD_LAYOUT}

    @action(closes_child=False)
    def format_yubiotp_csv(self, params, even, signal):
        serial = params["serial"]
        public_id = modhex_decode(params["public_id"])
        private_id = bytes.fromhex(params["private_id"])
        key = bytes.fromhex(params["key"])

        return dict(csv=format_csv(serial, public_id, private_id, key))


_CONFIG_TYPES = dict(
    hmac_sha1=HmacSha1SlotConfiguration,
    hotp=HotpSlotConfiguration,
    static_password=StaticPasswordSlotConfiguration,
    yubiotp=YubiOtpSlotConfiguration,
    static_ticket=StaticTicketSlotConfiguration,
)


class SlotNode(RpcNode):
    def __init__(self, session, slot):
        super().__init__()
        self.session = session
        self.slot = slot
        self._state = self.session.get_config_state()

    def get_data(self):
        self._state = self.session.get_config_state()
        data: Dict[str, bool] = {}
        try:
            data.update(is_configured=self._state.is_configured(self.slot))
            data.update(is_touch_triggered=self._state.is_touch_triggered(self.slot))
        except NotSupportedError:
            pass
        return data

    def _maybe_configured(self, slot):
        try:
            return self._state.is_configured(slot)
        except NotSupportedError:
            return True

    def _can_calculate(self, slot):
        try:
            if not self._state.is_configured(slot):
                return False
            try:
                if self._state.is_touch_triggered(slot):
                    return False
            except NotSupportedError:
                pass
            return True
        except NotSupportedError:
            return False

    @action(condition=lambda self: self._maybe_configured(self.slot))
    def delete(self, params, event, signal):
        try:
            access_code = params.pop("curr_acc_code", None)
            access_code = bytes.fromhex(access_code) if access_code else None
            self.session.delete_slot(self.slot, access_code)
        except CommandError:
            raise ValueError(_FAIL_MSG)

    @action(condition=lambda self: self._can_calculate(self.slot))
    def calculate(self, params, event, signal):
        challenge = bytes.fromhex(params.pop("challenge"))
        response = self.session.calculate_hmac_sha1(self.slot, challenge, event)
        return dict(response=response)

    def _apply_options(self, config, options):
        for option in (
            "serial_api_visible",
            "serial_usb_visible",
            "allow_update",
            "dormant",
            "invert_led",
            "protect_slot2",
            "require_touch",
            "lt64",
            "append_cr",
            "use_numeric",
            "fast_trigger",
            "digits8",
            "imf",
            "send_reference",
            "short_ticket",
            "manual_update",
        ):
            if option in options:
                getattr(config, option)(options.pop(option))

        for option in ("tabs", "delay", "pacing", "strong_password"):
            if option in options:
                getattr(config, option)(*options.pop(option))

        if "token_id" in options:
            token_id, *args = options.pop("token_id")
            config.token_id(bytes.fromhex(token_id), *args)

        return config

    def _get_config(self, type, **kwargs):
        config = None

        if type in _CONFIG_TYPES:
            if type == "hmac_sha1":
                config = _CONFIG_TYPES[type](bytes.fromhex(kwargs["key"]))
            elif type == "hotp":
                config = _CONFIG_TYPES[type](parse_b32_key(kwargs["key"]))
            elif type == "static_password":
                config = _CONFIG_TYPES[type](
                    encode(
                        kwargs["password"], KEYBOARD_LAYOUT[kwargs["keyboard_layout"]]
                    )
                )
            elif type == "yubiotp":
                config = _CONFIG_TYPES[type](
                    fixed=modhex_decode(kwargs["public_id"]),
                    uid=bytes.fromhex(kwargs["private_id"]),
                    key=bytes.fromhex(kwargs["key"]),
                )
            else:
                raise ValueError("No supported configuration type provided.")
        return config

    @action
    def put(self, params, event, signal):
        type = params.pop("type")
        options = params.pop("options", {})
        access_code = params.pop("curr_acc_code", None)
        access_code = bytes.fromhex(access_code) if access_code else None
        args = params

        config = self._get_config(type, **args)
        self._apply_options(config, options)
        try:
            self.session.put_configuration(
                self.slot,
                config,
                access_code,
                access_code,
            )
            return dict()
        except CommandError:
            raise ValueError(_FAIL_MSG)

    @action(
        condition=lambda self: self._state.version >= (2, 2, 0)
        and self._maybe_configured(self.slot)
    )
    def update(self, params, event, signal):
        config = UpdateConfiguration()
        self._apply_options(config, params)
        self.session.update_configuration(
            self.slot,
            config,
            params.pop("acc_code", None),
            params.pop("cur_acc_code", None),
        )
        return dict()
