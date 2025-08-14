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

import logging
from dataclasses import asdict
from time import sleep

from fido2.ctap import STATUS, CtapError
from fido2.ctap2 import ClientPin, Config, Ctap2
from fido2.ctap2.bio import BioEnrollment, CaptureError, FPBioEnrollment
from fido2.ctap2.credman import CredentialManagement
from ykman.base import REINSERT_STATUS
from ykman.settings import AppData
from yubikit.core.fido import FidoConnection

from .base import (
    AuthRequiredException,
    PinComplexityException,
    RpcException,
    RpcNode,
    RpcResponse,
    TimeoutException,
    action,
    child,
)

logger = logging.getLogger(__name__)


class PinValidationException(RpcException):
    def __init__(self, retries, auth_blocked):
        super().__init__(
            "pin-validation",
            "Authentication is required",
            dict(retries=retries, auth_blocked=auth_blocked),
        )


class InactivityException(RpcException):
    def __init__(self):
        super().__init__("user-action-timeout", "Failed action due to user inactivity.")


def _handle_pin_error(e, client_pin):
    if e.code in (
        CtapError.ERR.PIN_INVALID,
        CtapError.ERR.PIN_BLOCKED,
        CtapError.ERR.PIN_AUTH_BLOCKED,
    ):
        pin_retries, _ = client_pin.get_pin_retries()
        raise PinValidationException(
            pin_retries, e.code == CtapError.ERR.PIN_AUTH_BLOCKED
        )
    if e.code == CtapError.ERR.PIN_POLICY_VIOLATION:
        raise PinComplexityException()
    raise e


class Ctap2Node(RpcNode):
    def __init__(self, connection, device, reader_name):
        super().__init__()
        self._connection = connection
        self.ctap = Ctap2(connection)
        self._info = self.ctap.info
        self.client_pin = ClientPin(self.ctap)
        self._ppuat_store = AppData("ppuats")
        self._token = None
        self._ident = None
        self._ppuat = self._get_ppuat()
        self._device = device
        self._reader_name = reader_name

    def __call__(self, *args, **kwargs):
        try:
            return super().__call__(*args, **kwargs)
        except CtapError as e:
            if e.code == CtapError.ERR.PIN_AUTH_INVALID:
                self._delete_ppuat()
                logger.debug("Throwing auth required from __call__")
                raise AuthRequiredException()
            raise

    def _get_ppuat(self) -> bytes | None:
        if CredentialManagement.is_readonly_supported(self._info):
            idents = self._ppuat_store.keys()
            for ident in idents:
                ppuat = self._ppuat_store.get_secret(ident)
                curr_ident = self._info.get_identifier(bytes.fromhex(ppuat))
                if curr_ident and bytes.fromhex(ident) == curr_ident:
                    logger.debug("Using stored PPUAT")
                    self._ident = curr_ident
                    return bytes.fromhex(ppuat)
        return None

    def _delete_ppuat(self):
        if not self._ppuat:
            return

        logger.debug("Deleting stored PPUAT")
        if self._ident:
            del self._ppuat_store[self._ident.hex()]
            self._ppuat_store.write()
            self._ppuat = None
            self._ident = None

    def get_data(self):
        self._info = self.ctap.get_info()
        logger.debug(f"Info: {self._info}")
        data = dict(
            info=asdict(self._info),
            unlocked_read=self._token is not None or self._ppuat is not None,
            unlocked=self._token is not None,
        )
        if self._info.options.get("clientPin"):
            pin_retries, power_cycle = self.client_pin.get_pin_retries()
            data.update(
                pin_retries=pin_retries,
                power_cycle=power_cycle,
            )
            if self._info.options.get("bioEnroll"):
                uv_retries = self.client_pin.get_uv_retries()
                # For compatibility with python-fido2 < 1.0
                if isinstance(uv_retries, tuple):
                    uv_retries = uv_retries[0]
                data.update(uv_retries=uv_retries)
        return data

    @action
    def reset(self, event, signal):
        _signals = {
            REINSERT_STATUS.REMOVE: "remove",
            REINSERT_STATUS.REINSERT: "insert",
            STATUS.UPNEEDED: "touch",
            STATUS.PROCESSING: "wait",
        }

        def signal_status(status):
            signal("reset", dict(state=_signals[status]))

        self._connection.close()
        self._device.reinsert(reinsert_cb=signal_status, event=event)

        self._connection = self._device.open_connection(FidoConnection)
        self.ctap = Ctap2(self._connection)

        logger.debug("Performing reset...")
        try:
            self.ctap.reset(event=event, on_keepalive=signal_status)
        except CtapError as e:
            if e.code in (
                # Different keys respond with different errors here
                CtapError.ERR.USER_ACTION_TIMEOUT,
                CtapError.ERR.ACTION_TIMEOUT,
            ):
                raise InactivityException()
            raise
        self._info = self.ctap.get_info()
        self._token = None
        self._delete_ppuat()
        return RpcResponse(dict(), ["device_info", "device_closed"])

    @action(condition=lambda self: self._info.options["clientPin"])
    def unlock(self, pin: str):
        permissions = ClientPin.PERMISSION(0)
        if CredentialManagement.is_supported(self._info):
            permissions |= ClientPin.PERMISSION.CREDENTIAL_MGMT
        if BioEnrollment.is_supported(self._info):
            permissions |= ClientPin.PERMISSION.BIO_ENROLL
        if Config.is_supported(self._info):
            permissions |= ClientPin.PERMISSION.AUTHENTICATOR_CFG
        try:
            if not self._ppuat and CredentialManagement.is_readonly_supported(
                self._info
            ):
                self._ppuat = self.client_pin.get_pin_token(
                    pin, ClientPin.PERMISSION.PERSISTENT_CREDENTIAL_MGMT
                )
                self._ident = self._info.get_identifier(self._ppuat)
                if self._ident:
                    self._ppuat_store.put_secret(self._ident.hex(), self._ppuat.hex())
                    self._ppuat_store.write()
            if permissions:
                self._token = self.client_pin.get_pin_token(pin, permissions)
            else:
                self.client_pin.get_pin_token(
                    pin, ClientPin.PERMISSION.GET_ASSERTION, "ykman.example.com"
                )

            return dict()
        except CtapError as e:
            return _handle_pin_error(e, self.client_pin)

    @action
    def set_pin(self, new_pin: str, pin: str | None = None):
        has_pin = self.ctap.get_info().options["clientPin"]
        try:
            if has_pin:
                assert pin  # noqa: S101
                self.client_pin.change_pin(pin, new_pin)
            else:
                self.client_pin.set_pin(new_pin)
            self._info = self.ctap.get_info()
            return RpcResponse(dict(), ["device_info"])
        except CtapError as e:
            self._token = None
            return _handle_pin_error(e, self.client_pin)

    @action(condition=lambda self: Config.is_supported(self._info))
    def enable_ep_attestation(self):
        if self._info.options["clientPin"] and not self._token:
            raise AuthRequiredException()
        config = Config(self.ctap, self.client_pin.protocol, self._token)
        config._call(Config.CMD.ENABLE_ENTERPRISE_ATT)
        return dict()

    @child(condition=lambda self: BioEnrollment.is_supported(self._info))
    def fingerprints(self):
        if not self._token:
            raise AuthRequiredException()
        bio = FPBioEnrollment(
            self.client_pin.ctap, self.client_pin.protocol, self._token
        )
        return FingerprintsNode(bio)

    @child(condition=lambda self: CredentialManagement.is_supported(self._info))
    def credentials(self):
        token = self._token or self._ppuat
        if not token:
            logger.debug("Throwing auth required from credentials")
            raise AuthRequiredException()
        creds = CredentialManagement(self.ctap, self.client_pin.protocol, token)
        return CredentialsRpsNode(creds)


class CredentialsRpsNode(RpcNode):
    def __init__(self, credman):
        super().__init__()
        self.credman = credman
        self._rps = {}
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
        self._creds = {
            cred[CredentialManagement.RESULT.CREDENTIAL_ID]["id"].hex(): dict(
                credential_id=cred[CredentialManagement.RESULT.CREDENTIAL_ID],
                user_id=cred[CredentialManagement.RESULT.USER]["id"],
                user_name=cred[CredentialManagement.RESULT.USER]["name"],
                display_name=cred[CredentialManagement.RESULT.USER].get(
                    "displayName", None
                ),
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
                self.refresh_rps,
            )
        return super().create_child(name)


class CredentialNode(RpcNode):
    def __init__(self, credman, credential_data, refresh_rps):
        super().__init__()
        self.credman = credman
        self.data = credential_data
        self.refresh_rps = refresh_rps

    def get_data(self):
        return self.data

    @action
    def delete(self):
        self.credman.delete_cred(self.data["credential_id"])
        self.refresh_rps()
        return dict()


class FingerprintsNode(RpcNode):
    def __init__(self, bio):
        super().__init__()
        self.bio = bio
        self._templates = {}
        self.refresh()

    def refresh(self):
        self._templates = {
            # Treat empty strings as None
            k: v if v else None
            for k, v in self.bio.enumerate_enrollments().items()
        }

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
    def add(self, event, signal, name: str | None = None):
        enroller = self.bio.enroll()
        template_id = None
        while template_id is None:
            try:
                template_id = enroller.capture(event=event)
                signal("capture", dict(remaining=enroller.remaining))
            except CaptureError as e:
                signal("capture-error", dict(code=e.code))
            except CtapError as e:
                if e.code == CtapError.ERR.USER_ACTION_TIMEOUT:
                    raise InactivityException()
                raise
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
    def rename(self, name: str):
        self.bio.set_name(self.template_id, name)
        self.name = name
        self.refresh()
        return dict()

    @action
    def delete(self):
        self.bio.remove_enrollment(self.template_id)
        self.refresh()
        return dict()
