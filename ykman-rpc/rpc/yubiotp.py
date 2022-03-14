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


class YubiOtpNode(RpcNode):
    def __init__(self, connection):
        super().__init__()
        self.session = YubiOtpSession(connection)

    def get_data(self):
        state = self.session.get_config_state()
        data = {}
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
        data = {}
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
