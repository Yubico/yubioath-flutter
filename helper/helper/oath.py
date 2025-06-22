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

import hmac
import logging
import os
from dataclasses import asdict
from enum import Enum, unique
from threading import Timer
from time import time

from ykman.settings import AppData, UnwrapValueError
from yubikit.core import NotSupportedError, require_version
from yubikit.core.smartcard import SW, ApduError
from yubikit.oath import HASH_ALGORITHM, OATH_TYPE, CredentialData, OathSession

from .base import (
    AuthRequiredException,
    ChildResetException,
    RpcNode,
    RpcResponse,
    TimeoutException,
    action,
    child,
    decode_bytes,
    encode_bytes,
)

logger = logging.getLogger(__name__)


@unique
class KEYSTORE(str, Enum):
    UNKNOWN = "unknown"
    ALLOWED = "allowed"
    FAILED = "failed"
    # DENIED = "denied"  # Maybe failed is enough?


class OathNode(RpcNode):
    _keystore_state = KEYSTORE.UNKNOWN
    _oath_keys = None

    @classmethod
    def _get_keys(cls):
        if not cls._oath_keys:
            cls._oath_keys = AppData("oath_keys")
        return cls._oath_keys

    @classmethod
    def _unlock_keystore(cls):
        keys = cls._get_keys()
        state = cls._keystore_state
        if state == KEYSTORE.UNKNOWN:
            try:
                keys.ensure_unlocked()
                cls._keystore_state = KEYSTORE.ALLOWED
            except Exception:  # TODO: Use more specific exceptions
                logger.warning("Couldn't read key from Keychain", exc_info=True)
                cls._keystore_state = KEYSTORE.FAILED
        return cls._keystore_state == KEYSTORE.ALLOWED

    def _get_access_key(self, device_id):
        keys = self._get_keys()
        if self.session.device_id in keys and self._unlock_keystore():
            try:
                return bytes.fromhex(keys.get_secret(self.session.device_id))
            except UnwrapValueError:
                logger.warning("Failed to unwrap access key", exc_info=True)
        return None

    def __init__(self, connection, scp_params=None):
        super().__init__()
        self.session = OathSession(connection, scp_params)
        self._key_verifier = None

        if self.session.locked:
            key = self._get_access_key(self.session.device_id)
            if key:
                try:
                    self._do_validate(key)
                except ApduError as e:
                    # Wrong key, delete
                    if e.sw == SW.INCORRECT_PARAMETERS:
                        keys = self._get_keys()
                        del keys[self.session.device_id]
                        keys.write()
                except Exception:
                    logger.warning("Error authenticating", exc_info=True)

    def __call__(self, *args, **kwargs):
        try:
            return super().__call__(*args, **kwargs)
        except ApduError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED:
                raise AuthRequiredException()
            # TODO: This should probably be in a baseclass of all "AppNodes".
            raise ChildResetException(f"SW: {e.sw:x}")

    def get_data(self):
        keys = self._get_keys()
        return dict(
            version=self.session.version,
            device_id=self.session.device_id,
            has_key=self.session.has_key,
            locked=self.session.locked,
            remembered=self.session.device_id in keys,
            keystore=self._keystore_state,
        )

    @action
    def derive(self, password: str):
        return dict(key=self.session.derive_key(password))

    @action
    def forget(self):
        keys = self._get_keys()
        del keys[self.session.device_id]
        keys.write()
        return dict()

    def _remember_key(self, key: bytes | None):
        keys = self._get_keys()
        if key is None:
            if self.session.device_id in keys:
                del keys[self.session.device_id]
                keys.write()
            return True
        elif self._unlock_keystore():
            keys.put_secret(self.session.device_id, key.hex())
            keys.write()
            return True
        else:
            return False

    def _get_key(self, key: bytes | None, password: str | None):
        if key and password:
            raise ValueError("Only one of 'key' and 'password' can be provided.")
        if password:
            return self.session.derive_key(password)
        if key:
            return key
        raise ValueError("One of 'key' and 'password' must be provided.")

    def _set_key_verifier(self, key: bytes):
        salt = os.urandom(32)
        digest = hmac.new(salt, key, "sha256").digest()
        self._key_verifier = (salt, digest)

    def _do_validate(self, key: bytes):
        self.session.validate(key)
        self._set_key_verifier(key)

    @action
    def validate(
        self,
        key: bytes | None = None,
        password: str | None = None,
        remember: bool = False,
    ):
        access_key = self._get_key(key, password)
        if self.session.locked:
            try:
                self._do_validate(access_key)
                valid = True
            except ApduError as e:
                if e.sw == SW.INCORRECT_PARAMETERS:
                    valid = False
                else:
                    raise e
        elif self._key_verifier:
            salt, digest = self._key_verifier
            verify = hmac.new(salt, access_key, "sha256").digest()
            valid = hmac.compare_digest(digest, verify)
        else:
            valid = False
        if valid and remember:
            remembered = self._remember_key(access_key)
        else:
            remembered = False
        return dict(valid=valid, remembered=remembered)

    @action
    def set_key(
        self,
        key: bytes | None = None,
        password: str | None = None,
        remember: bool = False,
    ):
        access_key = self._get_key(key, password)
        self.session.set_key(access_key)
        self._set_key_verifier(access_key)
        remember &= self._remember_key(access_key if remember else None)
        return RpcResponse(dict(remembered=remember), ["device_info"])

    @action(condition=lambda self: self.session.has_key)
    def unset_key(self):
        self.session.unset_key()
        self._key_verifier = None
        self._remember_key(None)
        return dict()

    @action
    def reset(self):
        self.session.reset()
        self._key_verifier = None
        self._remember_key(None)
        return RpcResponse(dict(), ["device_info"])

    @child
    def accounts(self):
        if self.session.locked:
            raise AuthRequiredException()
        return CredentialsNode(self.session)


class CredentialsNode(RpcNode):
    def __init__(self, session):
        super().__init__()
        self.session = session
        self.refresh()

    def refresh(self):
        # N.B. We use 'calculate_all' since it tells us if a TOTP credential
        # requires touch or not.
        self._creds = {c.id: c for c in self.session.calculate_all().keys()}
        if self._child and self._child_name not in self._creds:
            self._close_child()

    def list_children(self):
        return {encode_bytes(c_id): asdict(c) for c_id, c in self._creds.items()}

    def create_child(self, name):
        key = decode_bytes(name)
        if key in self._creds:
            return CredentialNode(self.session, self._creds[key], self.refresh)
        return super().create_child(name)

    @action
    def calculate_all(self, timestamp: int | None = None):
        result = self.session.calculate_all(timestamp)
        return dict(
            entries=[
                dict(credential=asdict(cred), code=(asdict(code) if code else None))
                for (cred, code) in result.items()
            ]
        )

    @action
    def put(
        self,
        require_touch: bool = False,
        **kwargs,
    ):
        if "uri" in kwargs:
            data = CredentialData.parse_uri(kwargs.pop("uri"))
            if kwargs:
                raise ValueError("Unsupported parameters present")
        else:
            data = CredentialData(
                kwargs.pop("name"),
                OATH_TYPE[kwargs.pop("oath_type").upper()],
                HASH_ALGORITHM[kwargs.pop("hash", "sha1".upper())],
                decode_bytes(kwargs.pop("secret")),
                **kwargs,
            )

        if data.get_id() in self._creds:
            raise ValueError("Credential already exists")
        try:
            credential = self.session.put_credential(data, require_touch)
        except ApduError as e:
            if e.sw == SW.INCORRECT_PARAMETERS:
                raise ValueError("Issuer/name too long")
            raise e

        self._creds[credential.id] = credential
        return asdict(credential)


class CredentialNode(RpcNode):
    def __init__(self, session, credential, refresh):
        super().__init__()
        self.session = session
        self.credential = credential
        self.refresh = refresh
        self._touch = credential.touch_required

    def _require_version(self, major, minor, micro):
        try:
            require_version(self.session.version, (major, minor, micro))
            return True
        except NotSupportedError:
            return False

    def get_info(self):
        return asdict(self.credential)

    def _do_with_touch(self, signal, action):
        timer = None
        try:
            start = time()
            if self._touch:
                signal("touch")
            elif self.credential.oath_type == OATH_TYPE.HOTP:

                def on_timeout():
                    signal("touch")
                    self._touch = True

                timer = Timer(0.5, on_timeout)
                timer.start()

            return action()
        except ApduError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED and time() - start > 5:
                raise TimeoutException()
            raise
        finally:
            if timer:
                timer.cancel()

    @action
    def code(self, signal, timestamp: int | None = None):
        code = self._do_with_touch(
            signal, lambda: self.session.calculate_code(self.credential, timestamp)
        )
        return asdict(code)

    @action
    def calculate(self, signal, challenge: str):
        response = self._do_with_touch(
            signal,
            lambda: self.session.calculate(self.credential.id, decode_bytes(challenge)),
        )
        return dict(response=response)

    @action
    def delete(self):
        self.session.delete_credential(self.credential.id)
        self.refresh()
        self.credential = None
        return dict()

    @action(condition=lambda self: self._require_version(5, 3, 1))
    def rename(self, name: str, issuer: str | None = None):
        try:
            new_id = self.session.rename_credential(self.credential.id, name, issuer)
            self.refresh()
            return dict(credential_id=new_id)
        except ApduError as e:
            if e.sw == SW.INCORRECT_PARAMETERS:
                raise ValueError("Issuer/name too long")
            raise e
