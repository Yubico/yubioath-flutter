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

from .base import (
    RpcNode,
    action,
    child,
    RpcException,
    TimeoutException,
    AuthRequiredException,
)
from fido2.ctap import CtapError
from fido2.ctap2 import Ctap2, ClientPin
from fido2.ctap2.credman import CredentialManagement
from fido2.ctap2.bio import BioEnrollment, FPBioEnrollment, CaptureError
from fido2.pcsc import CtapPcscDevice
from yubikit.core.fido import FidoConnection
from ykman.hid import list_ctap_devices as list_ctap
from ykman.pcsc import list_devices as list_ccid
from smartcard.Exceptions import NoCardException, CardConnectionException

from dataclasses import asdict
from time import sleep
import logging

logger = logging.getLogger(__name__)


class PinValidationException(RpcException):
    def __init__(self, retries, auth_blocked):
        super().__init__(
            "pin-validation",
            "Authentication is required",
            dict(retries=retries, auth_blocked=auth_blocked),
        )


def _ctap_id(ctap):
    return (ctap.info.aaguid, ctap.info.firmware_version)


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
    raise e


class Ctap2Node(RpcNode):
    def __init__(self, connection):
        super().__init__()
        self.ctap = Ctap2(connection)
        self._info = self.ctap.info
        self.client_pin = ClientPin(self.ctap)
        self._auth_blocked = False
        self._token = None

    def get_data(self):
        self._info = self.ctap.get_info()
        logger.debug(f"Info: {self._info}")
        data = dict(
            info=asdict(self._info),
            auth_blocked=self._auth_blocked,
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

    def _prepare_reset_nfc(self, event, signal):
        reader_name = self.ctap.device._name
        devices = list_ccid(reader_name)
        if not devices or devices[0].reader.name != reader_name:
            raise ValueError("Unable to isolate NFC reader")
        dev = devices[0]
        logger.debug(f"Reset over NFC using reader: {dev.reader.name}")

        signal("reset", dict(state="remove"))
        removed = False
        while not event.wait(0.5):
            try:
                with dev.open_connection(FidoConnection):
                    if removed:
                        sleep(1.0)  # Wait for the device to settle
                        return dev.open_connection(FidoConnection)
            except CardConnectionException:
                pass  # Expected, ignore
            except NoCardException:
                if not removed:
                    signal("reset", dict(state="insert"))
                    removed = True

        raise TimeoutException()

    def _prepare_reset_usb(self, event, signal):
        dev_path = self.ctap.device.descriptor.path
        logger.debug(f"Reset over USB: {dev_path}")

        signal("reset", dict(state="remove"))
        removed_state = None
        while not event.wait(0.5):
            keys = list_ctap()
            present = {k.descriptor.path for k in keys}
            if removed_state is None:
                if dev_path not in present:
                    signal("reset", dict(state="insert"))
                    removed_state = present
            else:
                added = present - removed_state
                if len(added) == 1:
                    dev_path = next(iter(added))  # Path may have changed
                    key = next(k for k in keys if k.descriptor.path == dev_path)
                    connection = key.open_connection(FidoConnection)
                    signal("reset", dict(state="touch"))
                    return connection
                elif len(added) > 1:
                    raise ValueError("Multiple YubiKeys inserted")

        raise TimeoutException()

    @action
    def reset(self, params, event, signal):
        target = _ctap_id(self.ctap)
        if isinstance(self.ctap.device, CtapPcscDevice):
            connection = self._prepare_reset_nfc(event, signal)
        else:
            connection = self._prepare_reset_usb(event, signal)

        logger.debug("Performing reset...")
        self.ctap = Ctap2(connection)
        if target != _ctap_id(self.ctap):
            raise ValueError("Re-inserted YubiKey does not match initial device")
        self.ctap.reset(event=event)
        self._info = self.ctap.get_info()
        self._auth_blocked = False
        self._token = None
        return dict()

    @action(condition=lambda self: self._info.options["clientPin"])
    def unlock(self, params, event, signal):
        pin = params.pop("pin")
        permissions = 0
        if CredentialManagement.is_supported(self._info):
            permissions |= ClientPin.PERMISSION.CREDENTIAL_MGMT
        if BioEnrollment.is_supported(self._info):
            permissions |= ClientPin.PERMISSION.BIO_ENROLL
        try:
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
    def set_pin(self, params, event, signal):
        has_pin = self.ctap.get_info().options["clientPin"]
        try:
            if has_pin:
                self.client_pin.change_pin(
                    params.pop("pin"),
                    params.pop("new_pin"),
                )
            else:
                self.client_pin.set_pin(
                    params.pop("new_pin"),
                )
            self._info = self.ctap.get_info()
            return dict()
        except CtapError as e:
            return _handle_pin_error(e, self.client_pin)

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
        if not self._token:
            raise AuthRequiredException()
        creds = CredentialManagement(self.ctap, self.client_pin.protocol, self._token)
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
    def add(self, params, event, signal):
        name = params.get("name", None)
        enroller = self.bio.enroll()
        template_id = None
        while template_id is None:
            try:
                template_id = enroller.capture(event=event)
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
