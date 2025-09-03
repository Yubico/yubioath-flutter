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

import datetime
import logging
from dataclasses import asdict
from enum import Enum, unique
from threading import Timer
from time import time

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from ykman.piv import (
    derive_management_key,
    generate_chuid,
    generate_csr,
    generate_self_signed_certificate,
    get_pivman_data,
    get_pivman_protected_data,
    parse_rfc4514_string,
    pivman_change_pin,
    pivman_set_mgm_key,
)
from ykman.util import (
    InvalidPasswordError,
    get_leaf_certificates,
    parse_certificates,
    parse_private_key,
)
from yubikit.core import BadResponseError, InvalidPinError, NotSupportedError
from yubikit.core.smartcard import SW, ApduError
from yubikit.management import CAPABILITY
from yubikit.piv import (
    KEY_TYPE,
    MANAGEMENT_KEY_TYPE,
    OBJECT_ID,
    PIN_POLICY,
    SLOT,
    TOUCH_POLICY,
    PivSession,
    require_version,
)

from .base import (
    AuthRequiredException,
    ChildResetException,
    PinComplexityException,
    RpcException,
    RpcNode,
    RpcResponse,
    TimeoutException,
    action,
    child,
)

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
    PUBLIC_KEY = "publicKey"
    CSR = "csr"
    CERTIFICATE = "certificate"


def _handle_pin_puk_error(e):
    if isinstance(e, ApduError):
        if e.sw == SW.CONDITIONS_NOT_SATISFIED:
            raise PinComplexityException()
    if isinstance(e, InvalidPinError):
        raise InvalidPinException(cause=e)
    raise e


class PivNode(RpcNode):
    def __init__(self, connection, capabilities, scp_params=None):
        super().__init__()
        self.session = PivSession(connection, scp_params)
        self._pivman_data = get_pivman_data(self.session)
        self._authenticated = False
        self._capabilities = capabilities

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

    def _get_object(self, object_id: int):
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

        try:
            self.session.get_bio_metadata()
            supports_bio = True
        except NotSupportedError:
            supports_bio = False

        if metadata and (supports_bio and CAPABILITY.FIDO2 not in self._capabilities):
            # The default PIN flag may be set incorrectly on BIO MPE when FIDO2 is disabled
            metadata["pin_metadata"]["default_value"] = False

        return dict(
            version=self.session.version,
            authenticated=self._authenticated,
            derived_key=self._pivman_data.has_derived_key,
            stored_key=self._pivman_data.has_stored_key,
            supports_bio=supports_bio,
            chuid=self._get_object(OBJECT_ID.CHUID),
            ccc=self._get_object(OBJECT_ID.CAPABILITY),
            pin_attempts=pin_attempts,
            metadata=metadata,
        )

    def _authenticate(self, key: bytes, signal):
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
    def verify_pin(self, signal, pin: str):
        self.session.verify_pin(pin)
        key = None

        if self._pivman_data.has_derived_key:
            assert self._pivman_data.salt  # noqa: S101
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
    def authenticate(self, signal, key: bytes):
        try:
            self._authenticate(key, signal)
            return dict(status=True)
        except ApduError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED:
                return dict(status=False)
            raise

    @action(condition=lambda self: self._authenticated)
    def set_key(
        self,
        key: bytes,
        key_type: int = MANAGEMENT_KEY_TYPE.TDES,
        store_key: bool = False,
    ):
        pivman_set_mgm_key(
            self.session,
            key,
            MANAGEMENT_KEY_TYPE(key_type),
            False,
            store_key,
        )
        self._pivman_data = get_pivman_data(self.session)
        return RpcResponse(dict(), ["device_info"])

    @action
    def change_pin(self, pin: str, new_pin: str):
        try:
            pivman_change_pin(self.session, pin, new_pin)
            return RpcResponse(dict(), ["device_info"])
        except Exception as e:
            _handle_pin_puk_error(e)

    @action
    def change_puk(self, puk: str, new_puk: str):
        try:
            self.session.change_puk(puk, new_puk)
            return RpcResponse(dict(), ["device_info"])
        except Exception as e:
            _handle_pin_puk_error(e)

    @action
    def unblock_pin(self, puk: str, new_pin: str):
        try:
            self.session.unblock_pin(puk, new_pin)
            return RpcResponse(dict(), ["device_info"])
        except Exception as e:
            _handle_pin_puk_error(e)

    @action
    def reset(self):
        self.session.reset()
        self._authenticated = False
        self._pivman_data = get_pivman_data(self.session)
        return RpcResponse(dict(), ["device_info"])

    @child
    def slots(self):
        return SlotsNode(self.session)

    @action(closes_child=False)
    def validate_rfc4514(self, data: str):
        try:
            parse_rfc4514_string(data)
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
    try:  # Prefer timezone-aware variant (cryptography >= 42)
        not_before = cert.not_valid_before_utc
        not_after = cert.not_valid_after_utc
    except AttributeError:
        not_before = cert.not_valid_before
        not_after = cert.not_valid_after

    try:
        key_type = KEY_TYPE.from_public_key(cert.public_key())
    except ValueError:
        key_type = None

    return dict(
        key_type=key_type,
        subject=cert.subject.rfc4514_string(),
        issuer=cert.issuer.rfc4514_string(),
        serial=hex(cert.serial_number)[2:],
        not_valid_before=not_before.isoformat(),
        not_valid_after=not_after.isoformat(),
        fingerprint=cert.fingerprint(hashes.SHA256()),
    )


def _public_key_match(cert, metadata):
    if not cert or not metadata:
        return None
    slot_public_key = metadata.public_key
    cert_public_key = cert.public_key()
    return slot_public_key.public_bytes(
        encoding=Encoding.DER, format=PublicFormat.SubjectPublicKeyInfo
    ) == cert_public_key.public_bytes(
        encoding=Encoding.DER, format=PublicFormat.SubjectPublicKeyInfo
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
                metadata=_metadata_dict(metadata),
                cert_info=_get_cert_info(cert),
                public_key_match=_public_key_match(cert, metadata),
            )
            for slot, (metadata, cert) in self._slots.items()
        }

    def create_child(self, name):
        slot = _slot_for(name)
        if slot in self._slots:
            metadata, certificate = self._slots[slot]
            return SlotNode(self.session, slot, metadata, certificate, self.refresh)
        return super().create_child(name)


def _metadata_dict(metadata):
    if not metadata:
        return None
    data = asdict(metadata)
    data["public_key"] = metadata.public_key.public_bytes(
        encoding=Encoding.PEM, format=PublicFormat.SubjectPublicKeyInfo
    ).decode()
    del data["public_key_encoded"]
    return data


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
            metadata=_metadata_dict(self.metadata),
            certificate=(
                self.certificate.public_bytes(encoding=Encoding.PEM).decode()
                if self.certificate
                else None
            ),
        )

    @action(condition=lambda self: self.certificate or self.metadata)
    def delete(self, delete_cert: bool = False, delete_key: bool = False):
        if not delete_cert and not delete_key:
            raise ValueError("Missing delete option")

        if delete_cert:
            self.session.delete_certificate(self.slot)
            self.session.put_object(OBJECT_ID.CHUID, generate_chuid())
            self.certificate = None
        if delete_key:
            self.session.delete_key(self.slot)
        self._refresh()
        return dict()

    @action(condition=lambda self: self.metadata)
    def move_key(
        self, destination: str, overwrite_key: bool, include_certificate: bool
    ):
        if include_certificate:
            source_object = self.session.get_object(OBJECT_ID.from_slot(self.slot))
        dest = SLOT(int(destination, base=16))
        if overwrite_key:
            self.session.delete_key(dest)
        self.session.move_key(self.slot, dest)
        if include_certificate:
            self.session.put_object(OBJECT_ID.from_slot(dest), source_object)
            self.session.delete_certificate(self.slot)
            self.session.put_object(OBJECT_ID.CHUID, generate_chuid())
            self.certificate = None
        self._refresh()
        return dict()

    @action
    def examine_file(self, data: bytes, password: str | None = None):
        try:
            private_key, certs = _parse_file(data, password)
            certificate = _choose_cert(certs)

            response = dict(
                status=True,
                password=password is not None,
                key_type=(
                    KEY_TYPE.from_public_key(private_key.public_key())
                    if private_key
                    else None
                ),
                cert_info=_get_cert_info(certificate),
            )

            if self.metadata and certificate and not private_key:
                # Verify that the public key of a cert matches the
                # private key in the slot
                response["public_key_match"] = _public_key_match(
                    certificate, self.metadata
                )

            return response
        except InvalidPasswordError:
            logger.debug("Invalid or missing password", exc_info=True)
            return dict(status=False)

    @action
    def import_file(self, data: bytes, password: str | None = None, **kwargs):
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
            pin_policy = PIN_POLICY(kwargs.pop("pin_policy", PIN_POLICY.DEFAULT))
            touch_policy = TOUCH_POLICY(
                kwargs.pop("touch_policy", TOUCH_POLICY.DEFAULT)
            )
            self.session.put_key(self.slot, private_key, pin_policy, touch_policy)
            try:
                metadata = self.session.get_slot_metadata(self.slot)
            except (ApduError, BadResponseError, NotSupportedError):
                pass

        certificate = _choose_cert(certs)
        if certificate:
            self.session.put_certificate(self.slot, certificate)
            self.session.put_object(OBJECT_ID.CHUID, generate_chuid())
            self.certificate = certificate

        self._refresh()

        response = dict(
            metadata=_metadata_dict(metadata),
            public_key=(
                private_key.public_key()
                .public_bytes(
                    encoding=Encoding.PEM, format=PublicFormat.SubjectPublicKeyInfo
                )
                .decode()
                if private_key
                else None
            ),
            certificate=(
                self.certificate.public_bytes(encoding=Encoding.PEM).decode()
                if certs
                else None
            ),
        )
        return RpcResponse(response, ["device_info"])

    @action
    def generate(
        self,
        signal,
        key_type: int,
        pin_policy: int = PIN_POLICY.DEFAULT,
        touch_policy: int = TOUCH_POLICY.DEFAULT,
        generate_type: str = GENERATE_TYPE.CERTIFICATE,
        subject: str | None = None,
        pin: str | None = None,
        **kwargs,
    ):
        generate_type = GENERATE_TYPE(generate_type)
        public_key = self.session.generate_key(
            self.slot,
            KEY_TYPE(key_type),
            PIN_POLICY(pin_policy),
            TOUCH_POLICY(touch_policy),
        )
        public_key_pem = public_key.public_bytes(
            encoding=Encoding.PEM, format=PublicFormat.SubjectPublicKeyInfo
        ).decode()

        if pin_policy != PIN_POLICY.NEVER:
            # TODO: Check if verified?
            self.session.verify_pin(pin)

        if touch_policy in (TOUCH_POLICY.ALWAYS, TOUCH_POLICY.CACHED):
            signal("touch")

        match GENERATE_TYPE(generate_type):
            case GENERATE_TYPE.PUBLIC_KEY:
                result = public_key_pem
            case GENERATE_TYPE.CSR:
                assert subject  # noqa: S101
                csr = generate_csr(self.session, self.slot, public_key, subject)
                result = csr.public_bytes(encoding=Encoding.PEM).decode()
            case GENERATE_TYPE.CERTIFICATE:
                assert subject  # noqa: S101
                now = datetime.datetime.utcnow()
                then = now + datetime.timedelta(days=365)
                valid_from = kwargs.pop("valid_from", now.strftime(_date_format))
                valid_to = kwargs.pop("valid_to", then.strftime(_date_format))
                cert = generate_self_signed_certificate(
                    self.session,
                    self.slot,
                    public_key,
                    subject,
                    datetime.datetime.strptime(valid_from, _date_format),
                    datetime.datetime.strptime(valid_to, _date_format),
                )
                result = cert.public_bytes(encoding=Encoding.PEM).decode()
                self.session.put_certificate(self.slot, cert)
                self.session.put_object(OBJECT_ID.CHUID, generate_chuid())
            case other:
                raise ValueError(f"Unsupported GENERATE_TYPE: {other}")

        self._refresh()

        response = dict(public_key=public_key_pem, result=result)
        return RpcResponse(response, ["device_info"])
