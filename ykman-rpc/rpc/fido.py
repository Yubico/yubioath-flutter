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
from fido2.ctap2 import (
    Ctap2,
    ClientPin,
    CredentialManagement,
    FPBioEnrollment,
    CaptureError,
)
from dataclasses import asdict
import logging

logger = logging.getLogger(__name__)


class Ctap2Node(RpcNode):
    def __init__(self, connection):
        super().__init__()
        self.ctap = Ctap2(connection)
        self._info = self.ctap.info
        self.client_pin = ClientPin(self.ctap)
        self._pin = None

    def get_data(self):
        self._info = self.ctap.get_info()
        logger.debug(f"Info: {self._info}")
        data = dict(info=asdict(self._info), locked=False)
        if self._info.options.get("clientPin"):
            data["locked"] = self._pin is None
            pin_retries, power_cycle = self.client_pin.get_pin_retries()
            data.update(
                pin_retries=pin_retries,
                power_cycle=power_cycle,
            )
            if self._info.options.get("bioEnroll"):
                uv_retries = self.client_pin.get_uv_retries()
                if isinstance(uv_retries, tuple):
                    uv_retries = uv_retries[0]
                data.update(uv_retries=uv_retries)
        return data

    @action
    def reset(self, params, event, signal):
        self.ctap.reset(event)
        self._pin = None
        return dict()

    @action(condition=lambda self: self._info.options["clientPin"])
    def verify_pin(self, params, event, signal):
        pin = params.pop("pin")
        self.client_pin.get_pin_token(
            pin, ClientPin.PERMISSION.GET_ASSERTION, "ykman.example.com"
        )
        self._pin = pin
        return dict()

    @action
    def set_pin(self, params, event, signal):
        has_pin = self.ctap.get_info().options["clientPin"]
        if has_pin:
            self.client_pin.change_pin(
                params.pop("pin"),
                params.pop("new_pin"),
            )
        else:
            self.client_pin.set_pin(
                params.pop("new_pin"),
            )
        self._pin = None
        return dict()

    @child(condition=lambda self: "bioEnroll" in self._info.options and self._pin)
    def fingerprints(self):
        token = self.client_pin.get_pin_token(
            self._pin, ClientPin.PERMISSION.BIO_ENROLL
        )
        bio = FPBioEnrollment(self.ctap, self.client_pin.protocol, token)
        return FingerprintsNode(bio)

    # TODO: Use CredentialManagement.is_supported when released
    @child(condition=lambda self: self._pin)
    def credentials(self):
        token = self.client_pin.get_pin_token(
            self._pin, ClientPin.PERMISSION.CREDENTIAL_MGMT
        )
        creds = CredentialManagement(self.ctap, self.client_pin.protocol, token)
        return CredentialsRpsNode(creds)


class CredentialsRpsNode(RpcNode):
    def __init__(self, credman):
        super().__init__()
        self.credman = credman
        self.refresh()

    def refresh(self):
        data = self.credman.get_metadata()
        if data.get(CredentialManagement.RESULT.EXISTING_CRED_COUNT) == 0:
            self._rps = {}
        else:
            self._rps = {
                rp[CredentialManagement.RESULT.RP]["id"]: dict(
                    rp_id=rp[CredentialManagement.RESULT.RP]["id"],
                    rp_id_hash=rp[CredentialManagement.RESULT.RP_ID_HASH],
                )
                for rp in self.credman.enumerate_rps()
            }

    def list_children(self):
        return self._rps

    def create_child(self, name):
        if name in self._rps:
            return CredentialsRpNode(self.credman, self._rps[name], self.refresh)
        return super().create_child(name)


class CredentialsRpNode(RpcNode):
    def __init__(self, credman, rp_data, refresh):
        super().__init__()
        self.credman = credman
        self.data = rp_data
        self.refresh_rps = refresh
        self.refresh()

    def refresh(self):
        self.refresh_rps()
        self._creds = {
            cred[CredentialManagement.RESULT.CREDENTIAL_ID]["id"].hex(): dict(
                credential_id=cred[CredentialManagement.RESULT.CREDENTIAL_ID],
                user_id=cred[CredentialManagement.RESULT.USER]["id"],
                user_name=cred[CredentialManagement.RESULT.USER]["name"],
            )
            for cred in self.credman.enumerate_creds(self.data["rp_id_hash"])
        }

    def list_children(self):
        return self._creds

    def create_child(self, name):
        if name in self._creds:
            return CredentialNode(
                self.credman,
                self._creds[name],
                self.refresh,
            )
        return super().create_child(name)


class CredentialNode(RpcNode):
    def __init__(self, credman, credential_data, refresh):
        super().__init__()
        self.credman = credman
        self.data = credential_data
        self.refresh = refresh

    def get_data(self):
        return self.data

    @action
    def delete(self, params, event, signal):
        self.credman.delete_cred(self.data["credential_id"])
        self.refresh()


class FingerprintsNode(RpcNode):
    def __init__(self, bio):
        super().__init__()
        self.bio = bio
        self.refresh()

    def refresh(self):
        self._templates = self.bio.enumerate_enrollments()

    def list_children(self):
        return {
            template_id.hex(): dict(name=name)
            for template_id, name in self._templates.items()
        }

    def create_child(self, name):
        template_id = bytes.fromhex(name)
        if template_id in self._templates:
            return FingerprintNode(
                self.bio, template_id, self._templates[template_id], self.refresh
            )
        return super().create_child(name)

    @action
    def add(self, params, event, signal):
        name = params.get("name", None)
        enroller = self.bio.enroll()
        template_id = None
        while template_id is None:
            try:
                template_id = enroller.capture(event)
                signal("capture", dict(remaining=enroller.remaining))
            except CaptureError as e:
                signal("capture-error", dict(code=e.code))
        if name:
            self.bio.set_name(template_id, name)
        self._templates[template_id] = name
        return dict(template_id=template_id, name=name)


class FingerprintNode(RpcNode):
    def __init__(self, bio, template_id, name, refresh):
        super().__init__()
        self.bio = bio
        self.refresh = refresh
        self.template_id = template_id
        self.name = name

    def get_data(self):
        return dict(template_id=self.template_id, name=self.name)

    @action
    def rename(self, params, event, signal):
        name = params.pop("name")
        self.bio.set_name(self.template_id, name)
        self.name = name
        self.refresh()

    @action
    def delete(self, params, event, signal):
        self.bio.remove_enrollment(self.template_id)
        self.refresh()
