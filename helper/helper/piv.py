#  Copyright (C) 2023 Yubico.
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
    ChildResetException,
    TimeoutException,
    AuthRequiredException,
)
from yubikit.core import NotSupportedError, BadResponseError, InvalidPinError
from yubikit.core.smartcard import ApduError, SW
from yubikit.piv import (
    PivSession,
    OBJECT_ID,
    MANAGEMENT_KEY_TYPE,
    SLOT,
    require_version,
    KEY_TYPE,
    PIN_POLICY,
    TOUCH_POLICY,
)
from ykman.piv import (
    get_pivman_data,
    get_pivman_protected_data,
    derive_management_key,
    pivman_set_mgm_key,
    pivman_change_pin,
    generate_self_signed_certificate,
    generate_csr,
    generate_chuid,
    parse_rfc4514_string,
)
from ykman.util import (
    parse_certificates,
    parse_private_key,
    get_leaf_certificates,
    InvalidPasswordError,
)
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from cryptography.hazmat.primitives import hashes
from dataclasses import asdict
from enum import Enum, unique
from threading import Timer
from time import time
import datetime
import logging

logger = logging.getLogger(__name__)

_date_format = "%Y-%m-%d"


class InvalidPinException(RpcException):
    def __init__(self, cause):
        super().__init__(
            "invalid-pin",
            "Wrong PIN",
            dict(attempts_remaining=cause.attempts_remaining),
        )


@unique
class GENERATE_TYPE(str, Enum):
    CSR = "csr"
    CERTIFICATE = "certificate"


class PivNode(RpcNode):
    def __init__(self, connection):
        super().__init__()
        self.session = PivSession(connection)
        self._pivman_data = get_pivman_data(self.session)
        self._authenticated = False

    def __call__(self, *args, **kwargs):
        try:
            return super().__call__(*args, **kwargs)
        except ApduError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED:
                raise AuthRequiredException()
            # TODO: This should probably be in a baseclass of all "AppNodes".
            raise ChildResetException(f"SW: {e.sw:x}")
        except InvalidPinError as e:
            raise InvalidPinException(cause=e)

    def _get_object(self, object_id):
        try:
            return self.session.get_object(object_id)
        except ApduError as e:
            if e.sw == SW.FILE_NOT_FOUND:
                return None
            raise
        except BadResponseError:
            logger.warning(f"Couldn't read data object {object_id}", exc_info=True)
            return None

    def get_data(self):
        try:
            pin_md = self.session.get_pin_metadata()
            puk_md = self.session.get_puk_metadata()
            mgm_md = self.session.get_management_key_metadata()
            pin_attempts = pin_md.attempts_remaining
            metadata = dict(
                pin_metadata=asdict(pin_md),
                puk_metadata=asdict(puk_md),
                management_key_metadata=asdict(mgm_md),
            )
        except NotSupportedError:
            pin_attempts = self.session.get_pin_attempts()
            metadata = None

        return dict(
            version=self.session.version,
            authenticated=self._authenticated,
            derived_key=self._pivman_data.has_derived_key,
            stored_key=self._pivman_data.has_stored_key,
            chuid=self._get_object(OBJECT_ID.CHUID),
            ccc=self._get_object(OBJECT_ID.CAPABILITY),
            pin_attempts=pin_attempts,
            metadata=metadata,
        )

    def _authenticate(self, key, signal):
        try:
            metadata = self.session.get_management_key_metadata()
            key_type = metadata.key_type
            if metadata.touch_policy != TOUCH_POLICY.NEVER:
                signal("touch")
            timer = None
        except NotSupportedError:
            key_type = MANAGEMENT_KEY_TYPE.TDES
            timer = Timer(0.5, lambda: signal("touch"))
            timer.start()
        try:
            # TODO: Check if this is needed, maybe SW is enough
            start = time()
            self.session.authenticate(key_type, key)
        except ApduError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED and time() - start > 5:
                raise TimeoutException()
            raise
        finally:
            if timer:
                timer.cancel()
        self._authenticated = True

    @action
    def verify_pin(self, params, event, signal):
        pin = params.pop("pin")

        self.session.verify_pin(pin)
        key = None

        if self._pivman_data.has_derived_key:
            key = derive_management_key(pin, self._pivman_data.salt)
        elif self._pivman_data.has_stored_key:
            pivman_prot = get_pivman_protected_data(self.session)
            key = pivman_prot.key
        if key:
            try:
                self._authenticate(key, signal)
            except ApduError as e:
                if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED:
                    pass  # Authenticate failed, bad derived key?

            # Ensure verify was the last thing we did
            self.session.verify_pin(pin)

        return dict(status=True, authenticated=self._authenticated)

    @action
    def authenticate(self, params, event, signal):
        key = bytes.fromhex(params.pop("key"))
        try:
            self._authenticate(key, signal)
            return dict(status=True)
        except ApduError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED:
                return dict(status=False)
            raise

    @action(condition=lambda self: self._authenticated)
    def set_key(self, params, event, signal):
        key_type = MANAGEMENT_KEY_TYPE(params.pop("key_type", MANAGEMENT_KEY_TYPE.TDES))
        key = bytes.fromhex(params.pop("key"))
        store_key = params.pop("store_key", False)
        pivman_set_mgm_key(self.session, key, key_type, False, store_key)
        self._pivman_data = get_pivman_data(self.session)
        return dict()

    @action
    def change_pin(self, params, event, signal):
        old_pin = params.pop("pin")
        new_pin = params.pop("new_pin")
        pivman_change_pin(self.session, old_pin, new_pin)
        return dict()

    @action
    def change_puk(self, params, event, signal):
        old_puk = params.pop("puk")
        new_puk = params.pop("new_puk")
        self.session.change_puk(old_puk, new_puk)
        return dict()

    @action
    def unblock_pin(self, params, event, signal):
        puk = params.pop("puk")
        new_pin = params.pop("new_pin")
        self.session.unblock_pin(puk, new_pin)
        return dict()

    @action
    def reset(self, params, event, signal):
        self.session.reset()
        self._authenticated = False
        self._pivman_data = get_pivman_data(self.session)
        return dict()

    @child
    def slots(self):
        return SlotsNode(self.session)

    @action(closes_child=False)
    def examine_file(self, params, event, signal):
        data = bytes.fromhex(params.pop("data"))
        password = params.pop("password", None)
        try:
            private_key, certs = _parse_file(data, password)
            certificate = _choose_cert(certs)

            return dict(
                status=True,
                password=password is not None,
                key_type=KEY_TYPE.from_public_key(private_key.public_key())
                if private_key
                else None,
                cert_info=_get_cert_info(certificate),
            )
        except InvalidPasswordError:
            logger.debug("Invalid or missing password", exc_info=True)
            return dict(status=False)

    @action(closes_child=False)
    def validate_rfc4514(self, params, event, signal):
        try:
            parse_rfc4514_string(params.pop("data"))
            return dict(status=True)
        except ValueError:
            return dict(status=False)


def _slot_for(name):
    return SLOT(int(name, base=16))


def _parse_file(data, password=None):
    if password:
        password = password.encode()
    try:
        certs = parse_certificates(data, password)
    except (ValueError, TypeError):
        certs = []

    try:
        private_key = parse_private_key(data, password)
    except (ValueError, TypeError):
        private_key = None

    return private_key, certs


def _choose_cert(certs):
    if certs:
        if len(certs) > 1:
            leafs = get_leaf_certificates(certs)
            return leafs[0]
        else:
            return certs[0]
    return None


def _get_cert_info(cert):
    if cert is None:
        return None
    return dict(
        subject=cert.subject.rfc4514_string(),
        issuer=cert.issuer.rfc4514_string(),
        serial=hex(cert.serial_number)[2:],
        not_valid_before=cert.not_valid_before.isoformat(),
        not_valid_after=cert.not_valid_after.isoformat(),
        fingerprint=cert.fingerprint(hashes.SHA256()),
    )


class SlotsNode(RpcNode):
    def __init__(self, session):
        super().__init__()
        self.session = session
        try:
            require_version(session.version, (5, 3, 0))
            self._has_metadata = True
        except NotSupportedError:
            self._has_metadata = False
        self.refresh()

    def refresh(self):
        self._slots = {}
        for slot in set(SLOT) - {SLOT.ATTESTATION}:
            metadata = None
            if self._has_metadata:
                try:
                    metadata = self.session.get_slot_metadata(slot)
                except (ApduError, BadResponseError):
                    pass
            try:
                certificate = self.session.get_certificate(slot)
            except (ApduError, BadResponseError):
                # TODO: Differentiate between none and malformed
                certificate = None
            self._slots[slot] = (metadata, certificate)
        if self._child and _slot_for(self._child_name) not in self._slots:
            self._close_child()

    def list_children(self):
        return {
            f"{int(slot):02x}": dict(
                slot=int(slot),
                name=slot.name,
                has_key=metadata is not None if self._has_metadata else None,
                cert_info=_get_cert_info(cert),
            )
            for slot, (metadata, cert) in self._slots.items()
        }

    def create_child(self, name):
        slot = _slot_for(name)
        if slot in self._slots:
            metadata, certificate = self._slots[slot]
            return SlotNode(self.session, slot, metadata, certificate, self.refresh)
        return super().create_child(name)


class SlotNode(RpcNode):
    def __init__(self, session, slot, metadata, certificate, refresh):
        super().__init__()
        self.session = session
        self.slot = slot
        self.metadata = metadata
        self.certificate = certificate
        self._refresh = refresh

    def get_data(self):
        return dict(
            id=f"{int(self.slot):02x}",
            name=self.slot.name,
            metadata=asdict(self.metadata) if self.metadata else None,
            certificate=self.certificate.public_bytes(encoding=Encoding.PEM).decode()
            if self.certificate
            else None,
        )

    @action(condition=lambda self: self.certificate)
    def delete(self, params, event, signal):
        self.session.delete_certificate(self.slot)
        self.session.put_object(OBJECT_ID.CHUID, generate_chuid())
        self._refresh()
        self.certificate = None
        return dict()

    @action
    def import_file(self, params, event, signal):
        data = bytes.fromhex(params.pop("data"))
        password = params.pop("password", None)

        try:
            private_key, certs = _parse_file(data, password)
        except InvalidPasswordError:
            logger.debug("Invalid or missing password", exc_info=True)
            raise ValueError("Wrong/Missing password")

        # Exception?
        if not certs and not private_key:
            raise ValueError("Failed to parse")

        metadata = None
        if private_key:
            pin_policy = PIN_POLICY(params.pop("pin_policy", PIN_POLICY.DEFAULT))
            touch_policy = TOUCH_POLICY(
                params.pop("touch_policy", TOUCH_POLICY.DEFAULT)
            )
            self.session.put_key(self.slot, private_key, pin_policy, touch_policy)
            try:
                metadata = self.session.get_slot_metadata(self.slot)
            except (ApduError, BadResponseError):
                pass

        certificate = _choose_cert(certs)
        if certificate:
            self.session.put_certificate(self.slot, certificate)
            self.session.put_object(OBJECT_ID.CHUID, generate_chuid())
            self.certificate = certificate

        self._refresh()

        return dict(
            metadata=asdict(metadata) if metadata else None,
            public_key=private_key.public_key()
            .public_bytes(
                encoding=Encoding.PEM, format=PublicFormat.SubjectPublicKeyInfo
            )
            .decode()
            if private_key
            else None,
            certificate=self.certificate.public_bytes(encoding=Encoding.PEM).decode()
            if certs
            else None,
        )

    @action
    def generate(self, params, event, signal):
        key_type = KEY_TYPE(params.pop("key_type"))
        pin_policy = PIN_POLICY(params.pop("pin_policy", PIN_POLICY.DEFAULT))
        touch_policy = TOUCH_POLICY(params.pop("touch_policy", TOUCH_POLICY.DEFAULT))
        subject = params.pop("subject")
        generate_type = GENERATE_TYPE(
            params.pop("generate_type", GENERATE_TYPE.CERTIFICATE)
        )
        public_key = self.session.generate_key(
            self.slot, key_type, pin_policy, touch_policy
        )

        if pin_policy != PIN_POLICY.NEVER:
            # TODO: Check if verified?
            pin = params.pop("pin")
            self.session.verify_pin(pin)

        if touch_policy in (TOUCH_POLICY.ALWAYS, TOUCH_POLICY.CACHED):
            signal("touch")

        if generate_type == GENERATE_TYPE.CSR:
            result = generate_csr(self.session, self.slot, public_key, subject)
        elif generate_type == GENERATE_TYPE.CERTIFICATE:
            now = datetime.datetime.utcnow()
            then = now + datetime.timedelta(days=365)
            valid_from = params.pop("valid_from", now.strftime(_date_format))
            valid_to = params.pop("valid_to", then.strftime(_date_format))
            result = generate_self_signed_certificate(
                self.session,
                self.slot,
                public_key,
                subject,
                datetime.datetime.strptime(valid_from, _date_format),
                datetime.datetime.strptime(valid_to, _date_format),
            )
            self.session.put_certificate(self.slot, result)
            self.session.put_object(OBJECT_ID.CHUID, generate_chuid())
        else:
            raise ValueError("Unsupported GENERATE_TYPE")

        self._refresh()

        return dict(
            public_key=public_key.public_bytes(
                encoding=Encoding.PEM, format=PublicFormat.SubjectPublicKeyInfo
            ).decode(),
            result=result.public_bytes(encoding=Encoding.PEM).decode(),
        )
