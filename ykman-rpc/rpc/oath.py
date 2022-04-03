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


from .base import (
    RpcNode,
    action,
    child,
    ChildResetException,
    TimeoutException,
    AuthRequiredException,
    encode_bytes,
    decode_bytes,
)
from ykman.settings import AppData
from yubikit.core import require_version, NotSupportedError
from yubikit.core.smartcard import ApduError, SW
from yubikit.oath import OathSession, CredentialData, OATH_TYPE, HASH_ALGORITHM
from dataclasses import asdict
from enum import Enum, unique
from time import time
import hmac
import os
import logging

logger = logging.getLogger(__name__)


@unique
class KEYSTORE(str, Enum):
    UNKNOWN = "unknown"
    ALLOWED = "allowed"
    FAILED = "failed"
    # DENIED = "denied"  # Maybe failed is enough?


class OathNode(RpcNode):
    _keystore_state = KEYSTORE.UNKNOWN

    @classmethod
    def _get_keys(cls):
        if not hasattr(cls, "_oath_keys"):
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
            return bytes.fromhex(keys.get_secret(self.session.device_id))
        return None

    def __init__(self, connection):
        super().__init__()
        self.session = OathSession(connection)

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
    def derive(self, params, event, signal):
        return dict(key=self.session.derive_key(params.pop("password")))

    @action
    def forget(self, params, event, signal):
        keys = self._get_keys()
        del keys[self.session.device_id]
        keys.write()
        return dict()

    def _remember_key(self, key):
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

    def _get_key(self, params):
        has_key = "key" in params
        has_pw = "password" in params
        if has_key and has_pw:
            raise ValueError("Only one of 'key' and 'password' can be provided.")
        if has_pw:
            return self.session.derive_key(params.pop("password"))
        if has_key:
            return decode_bytes(params.pop("key"))
        raise ValueError("One of 'key' and 'password' must be provided.")

    def _do_validate(self, key):
        self.session.validate(key)
        salt = os.urandom(32)
        digest = hmac.new(salt, key, "sha256").digest()
        self._key_verifier = (salt, digest)

    @action
    def validate(self, params, event, signal):
        remember = params.pop("remember", False)
        key = self._get_key(params)
        if self.session.locked:
            try:
                self._do_validate(key)
                valid = True
            except ApduError as e:
                if e.sw == SW.INCORRECT_PARAMETERS:
                    valid = False
                else:
                    raise e
        elif hasattr(self, "_key_verifier"):
            salt, digest = self._key_verifier
            verify = hmac.new(salt, key, "sha256").digest()
            valid = hmac.compare_digest(digest, verify)
        else:
            valid = False
        if valid and remember:
            remembered = self._remember_key(key)
        else:
            remembered = False
        return dict(valid=valid, remembered=remembered)

    @action
    def set_key(self, params, event, signal):
        remember = params.pop("remember", False)
        key = self._get_key(params)
        self.session.set_key(key)
        remember &= self._remember_key(key if remember else None)
        return dict(remembered=remember)

    @action(condition=lambda self: self.session.has_key)
    def unset_key(self, params, event, signal):
        self.session.unset_key()
        self._remember_key(None)
        return dict()

    @action
    def reset(self, params, event, signal):
        self.session.reset()
        self._remember_key(None)
        return dict()

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
    def calculate_all(self, params, event, signal):
        timestamp = params.pop("timestamp", None)
        result = self.session.calculate_all(timestamp)
        return dict(
            entries=[
                dict(credential=asdict(cred), code=(asdict(code) if code else None))
                for (cred, code) in result.items()
            ]
        )

    @action
    def put(self, params, event, signal):
        require_touch = params.pop("require_touch", False)
        if "uri" in params:
            data = CredentialData.parse_uri(params.pop("uri"))
            if params:
                raise ValueError("Unsupported parameters present")
        else:
            data = CredentialData(
                params.pop("name"),
                OATH_TYPE[params.pop("oath_type").upper()],
                HASH_ALGORITHM[params.pop("hash", "sha1".upper())],
                decode_bytes(params.pop("secret")),
                **params,
            )

        if data.get_id() in self._creds:
            raise ValueError("Credential already exists")
        credential = self.session.put_credential(data, require_touch)
        self._creds[credential.id] = credential
        return asdict(credential)


class CredentialNode(RpcNode):
    def __init__(self, session, credential, refresh):
        super().__init__()
        self.session = session
        self.credential = credential
        self.refresh = refresh

    def _require_version(self, major, minor, micro):
        try:
            require_version(self.session.version, (major, minor, micro))
            return True
        except NotSupportedError:
            return False

    def get_info(self):
        return asdict(self.credential)

    @action
    def code(self, params, event, signal):
        timestamp = params.pop("timestamp", None)
        try:
            start = time()
            code = self.session.calculate_code(self.credential, timestamp)
            return asdict(code)
        except ApduError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED and time() - start > 5:
                raise TimeoutException()
            raise

    @action
    def calculate(self, params, event, signal):
        challenge = decode_bytes(params.pop("challenge"))
        try:
            start = time()
            response = self.session.calculate(self.credential.id, challenge)
            return dict(response=response)
        except ApduError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED and time() - start > 5:
                raise TimeoutException()
            raise

    @action
    def delete(self, params, event, signal):
        self.session.delete_credential(self.credential.id)
        self.refresh()
        self.credential = None
        return dict()

    @action(condition=lambda self: self._require_version(5, 3, 1))
    def rename(self, params, event, signal):
        name = params.pop("name")
        issuer = params.pop("issuer", None)
        try:
            new_id = self.session.rename_credential(self.credential.id, name, issuer)
            self.refresh()
            return dict(credential_id=new_id)
        except ApduError as e:
            if e.sw == SW.INCORRECT_PARAMETERS:
                raise ValueError("Issuer/name too long")
            raise e
