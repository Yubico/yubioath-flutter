#!/usr/bin/env python3
"""This script prepares a YubiKey for FIDO testing by registering multiple users.

It is intended to prepare a YubiKey for the test_fido.dart tests.

By default, it registers three users, but you can change the number of users by
passing the number as an argument when running the script.
Usage:
    python prep_fido.py [number_of_users]
"""

import sys
from concurrent.futures import Future, ThreadPoolExecutor

from fido2.client import DefaultClientDataCollector, Fido2Client, UserInteraction
from fido2.ctap import CtapError
from fido2.server import Fido2Server
from ykman import scripting as s
from yubikit.core.fido import FidoConnection

from controller import PicoController

TEST_PIN = "23452345"


# Handle user interaction via CLI prompts
class CliInteraction(UserInteraction):
    def __init__(self, controller: PicoController | None, executor: ThreadPoolExecutor):
        self.controller = controller
        self.executor = executor
        self.touch_future: Future | None = None

    def prompt_up(self):
        if self.controller:
            self.touch_future = self.executor.submit(self.controller.touch)
        else:
            print("👉 Touch your authenticator device now...")

    def request_pin(self, permissions, rp_id):
        return TEST_PIN

    def request_uv(self, permissions, rp_id):
        print("User Verification required.")
        return True


def setup(dev, num_users=3, controller: PicoController | None = None):
    server = Fido2Server(
        {"id": "delete.example.com", "name": "Example RP"}, attestation="none"
    )

    with ThreadPoolExecutor(max_workers=1) as executor:
        for i in range(num_users):
            interaction = CliInteraction(controller, executor)
            try:
                with dev.open_connection(FidoConnection) as conn:
                    client = Fido2Client(
                        conn,
                        client_data_collector=DefaultClientDataCollector(
                            "https://delete.example.com"
                        ),
                        user_interaction=interaction,
                    )

                    create_options, _ = server.register_begin(
                        {"id": b"user_id_" + str(i).encode(), "name": f"User no. {i + 1}"},
                        resident_key_requirement="required",
                        user_verification="discouraged",
                        authenticator_attachment="cross-platform",
                    )

                    try:
                        client.make_credential(create_options["publicKey"])
                    except CtapError as e:
                        raise ValueError(
                            "Failed setup. Manually FIDO reset the YubiKey and try again."
                        ) from e
            finally:
                if interaction.touch_future is not None:
                    interaction.touch_future.result(timeout=5)
                    controller.release()


if __name__ == "__main__":
    if len(sys.argv) > 1:
        num_users = int(sys.argv[1])
    else:
        num_users = 3

    yk = s.single()

    setup(yk, num_users)
