"""Creates one discoverable test credential on a YubiKey (needs a touch).

Run with an interpreter that has python-fido2, e.g. ykman's:
  $(head -1 $(which ykman) | cut -c3-) tools/make_test_passkey.py PIN
"""

import sys

from fido2.client import DefaultClientDataCollector, Fido2Client, UserInteraction
from fido2.hid import CtapHidDevice
from fido2.webauthn import (
    PublicKeyCredentialCreationOptions,
    PublicKeyCredentialParameters,
    PublicKeyCredentialRpEntity,
    PublicKeyCredentialUserEntity,
    ResidentKeyRequirement,
    AuthenticatorSelectionCriteria,
    UserVerificationRequirement,
)


class Interaction(UserInteraction):
    def __init__(self, pin):
        self.pin = pin

    def prompt_up(self):
        print("Touch the YubiKey now", flush=True)

    def request_pin(self, permissions, rp_id):
        return self.pin

    def request_uv(self, permissions, rp_id):
        return True


pin = sys.argv[1]
device = next(CtapHidDevice.list_devices())
client = Fido2Client(
    device,
    client_data_collector=DefaultClientDataCollector("https://sdk-eval.example.com"),
    user_interaction=Interaction(pin),
)
options = PublicKeyCredentialCreationOptions(
    rp=PublicKeyCredentialRpEntity(id="sdk-eval.example.com", name="SDK eval"),
    user=PublicKeyCredentialUserEntity(id=b"sdk-eval-user-1", name="passkey-test", display_name="Passkey Test"),
    challenge=b"0123456789abcdef0123456789abcdef",
    pub_key_cred_params=[PublicKeyCredentialParameters(type="public-key", alg=-7)],
    authenticator_selection=AuthenticatorSelectionCriteria(
        resident_key=ResidentKeyRequirement.REQUIRED,
        user_verification=UserVerificationRequirement.REQUIRED,
    ),
)
result = client.make_credential(options)
print("Created credential", result.response.attestation_object.auth_data.credential_data.credential_id.hex())
