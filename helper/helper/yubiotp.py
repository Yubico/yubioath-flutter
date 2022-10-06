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

from yubikit.core import NotSupportedError
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
from typing import Dict


class YubiOtpNode(RpcNode):
    def __init__(self, connection):
        super().__init__()
        self.session = YubiOtpSession(connection)

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
        self.session.swap_slots()
        return dict()

    @child
    def one(self):
        return SlotNode(self.session, SLOT.ONE)

    @child
    def two(self):
        return SlotNode(self.session, SLOT.TWO)


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
        self.session.delete_slot(self.slot, params.pop("cur_acc_code", None))

    @action(condition=lambda self: self._can_calculate(self.slot))
    def calculate(self, params, event, signal):
        challenge = bytes.fromhex(params.pop("challenge"))
        response = self.session.calculate_hmac_sha1(self.slot, challenge, event)
        return dict(response=response)

    def _apply_config(self, config, params):
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
            if option in params:
                getattr(config, option)(params.pop(option))

        for option in ("tabs", "delay", "pacing", "strong_password"):
            if option in params:
                getattr(config, option)(*params.pop(option))

        if "token_id" in params:
            token_id, *args = params.pop("token_id")
            config.token_id(bytes.fromhex(token_id), *args)

        return config

    @action
    def put(self, params, event, signal):
        config = None
        for key in _CONFIG_TYPES:
            if key in params:
                if config is not None:
                    raise ValueError("Only one configuration type can be provided.")
                config = _CONFIG_TYPES[key](
                    *(bytes.fromhex(arg) for arg in params.pop(key))
                )
        if config is None:
            raise ValueError("No supported configuration type provided.")
        self._apply_config(config, params)
        self.session.put_configuration(
            self.slot,
            config,
            params.pop("acc_code", None),
            params.pop("cur_acc_code", None),
        )
        return dict()

    @action(
        condition=lambda self: self._state.version >= (2, 2, 0)
        and self._maybe_configured(self.slot)
    )
    def update(self, params, event, signal):
        config = UpdateConfiguration()
        self._apply_config(config, params)
        self.session.update_configuration(
            self.slot,
            config,
            params.pop("acc_code", None),
            params.pop("cur_acc_code", None),
        )
        return dict()
