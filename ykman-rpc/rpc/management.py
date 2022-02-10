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


from .base import RpcNode, action
from yubikit.core import require_version, NotSupportedError
from yubikit.management import ManagementSession, DeviceConfig
from dataclasses import asdict


class ManagementNode(RpcNode):
    def __init__(self, connection):
        super().__init__()
        self.session = ManagementSession(connection)

    def get_data(self):
        return asdict(self.session.read_device_info())

    def list_actions(self):
        actions = super().list_actions()
        try:
            require_version(self.session.version, (5, 0, 0))
            actions.remove("set_mode")
        except NotSupportedError:
            actions.remove("configure")
        return actions

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
        self.session.write_device_config(config, reboot, cur_lock_code, new_lock_code)
        return dict()

    @action
    def set_mode(self, params, event, signal):
        self.session.set_mode(
            params.pop("mode"),
            params.pop("challenge_response_timeout", 0),
            params.pop("auto_eject_timeout", 0),
        )
        return dict()
