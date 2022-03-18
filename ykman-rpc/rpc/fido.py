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


from .base import RpcNode, action, child, RpcException, TimeoutException
from fido2.ctap import CtapError
from fido2.ctap2 import (
    Ctap2,
    ClientPin,
    CredentialManagement,
    FPBioEnrollment,
    CaptureError,
)
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


class Ctap2Node(RpcNode):
    def __init__(self, connection):
        super().__init__()
        self.ctap = Ctap2(connection)
        self._info = self.ctap.info
        self.client_pin = ClientPin(self.ctap)
        self._pin = None
        self._auth_blocked = False

    def get_data(self):
        self._info = self.ctap.get_info()
        logger.debug(f"Info: {self._info}")
        data = dict(
            info=asdict(self._info), locked=False, auth_blocked=self._auth_blocked
        )
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
            sleep(0.5)
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
            sleep(0.5)
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
        self.ctap.reset(event)
        self._info = self.ctap.get_info()
        self._pin = None
        self._auth_blocked = False
        return dict()

    def _handle_pin_error(self, e):
        if e.code in (
            CtapError.ERR.PIN_INVALID,
            CtapError.ERR.PIN_BLOCKED,
            CtapError.ERR.PIN_AUTH_BLOCKED,
        ):
            pin_retries, _ = self.client_pin.get_pin_retries()
            raise PinValidationException(
                pin_retries, e.code == CtapError.ERR.PIN_AUTH_BLOCKED
            )
        raise e

    @action(condition=lambda self: self._info.options["clientPin"])
    def verify_pin(self, params, event, signal):
        pin = params.pop("pin")
        try:
            self.client_pin.get_pin_token(
                pin, ClientPin.PERMISSION.GET_ASSERTION, "ykman.example.com"
            )
            self._pin = pin
            return dict()
        except CtapError as e:
            return self._handle_pin_error(e)

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
            self._pin = None
            return dict()
        except CtapError as e:
            return self._handle_pin_error(e)

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
