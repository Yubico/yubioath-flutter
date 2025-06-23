#!/usr/bin/env python3
"""This script prepares a YubiKey for FIDO testing by registering multiple users.

It is intended to prepare a YubiKey for the test_fido.dart tests.

By default, it registers three users, but you can change the number of users by
passing the number as an argument when running the script.
Usage:
    python prep_fido.py [number_of_users]
"""

import sys

from fido2.client import DefaultClientDataCollector, Fido2Client, UserInteraction
from fido2.ctap import CtapError
from fido2.server import Fido2Server
from ykman import scripting as s
from yubikit.core.fido import FidoConnection

TEST_PIN = "23452345"


# Handle user interaction via CLI prompts
class CliInteraction(UserInteraction):
    def prompt_up(self):
        print("👉 Touch your authenticator device now...")

    def request_pin(self, permissions, rp_id):
        return TEST_PIN

    def request_uv(self, permissions, rp_id):
        print("User Verification required.")
        return True


def setup(dev, num_users=3):
    server = Fido2Server(
        {"id": "delete.example.com", "name": "Example RP"}, attestation="none"
    )

    for i in range(num_users):
        with dev.open_connection(FidoConnection) as conn:
            client = Fido2Client(
                conn,
                client_data_collector=DefaultClientDataCollector(
                    "https://delete.example.com"
                ),
                user_interaction=CliInteraction(),
            )

            create_options, state = server.register_begin(
                {"id": b"user_id_" + str(i).encode(), "name": f"User no. {i + 1}"},
                resident_key_requirement="required",
                user_verification="discouraged",
                authenticator_attachment="cross-platform",
            )

            try:
                client.make_credential(create_options["publicKey"])
            except CtapError:
                raise ValueError(
                    "Failed setup. Manually FIDO reset the YubiKey and try again."
                )


if __name__ == "__main__":
    if len(sys.argv) > 1:
        num_users = int(sys.argv[1])
    else:
        num_users = 3

    yk = s.single()

    setup(yk, num_users)
