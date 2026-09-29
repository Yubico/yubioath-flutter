# /// script
# requires-python = ">=3.11"
# dependencies = ["click", "yubikey-manager", "fido2", "pyscard", "hidapi"]
# ///

import json
import subprocess
import sys
import time
from dataclasses import asdict
from enum import StrEnum
from urllib.parse import urlparse

import click
from controller import PicoController
from fido_prep import setup as setup_fido
from ykman.device import list_all_devices
from ykman.pcsc import list_devices
from yubikit.core.smartcard import SmartCardConnection
from yubikit.support import read_info


class App(StrEnum):
    oath = "oath"
    fido = "fido"
    piv = "piv"
    otp = "otp"
    management = "management"


app_setup = {
    App.fido: setup_fido,
}


def verify_controller(pico: PicoController, serial: int) -> None:
    """Do not run destructive tests until the selected Pico port controls this key."""
    click.echo(f"Verifying Pico port {pico.port} controls YubiKey {serial}...")
    try:
        pico.remove()
        time.sleep(1)
        if any(info.serial == serial for _, info in list_all_devices()):
            raise click.ClickException(
                f"YubiKey {serial} is still present after powering off Pico port {pico.port}"
            )
    finally:
        pico.restore()

    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if any(info.serial == serial for _, info in list_all_devices()):
            time.sleep(2)
            if any(info.serial == serial for _, info in list_all_devices()):
                return
        time.sleep(0.5)
    raise click.ClickException(f"YubiKey {serial} did not return after restoring Pico power")


@click.command()
@click.option("--serial", "-s", type=str, help="Device serial number")
@click.option("--reader", "-r", type=str, help="NFC reader name")
@click.option("--target", "-d", type=str, help="flutter device to target")
@click.option("--window-size", type=click.Choice(["narrow", "medium", "wide"]))
@click.option("--name", "-k", type=str, help="Test names to match against")
@click.option("--keyless", is_flag=True, help="Run tests without a YubiKey")
@click.option("--manual", is_flag=True, help="Run tests requiring manual interaction")
@click.option(
    "--controller",
    envvar="CONTROLLER",
    help="Pico controller URL for automated USB touch and power (e.g. http://192.168.7.1)",
)
@click.option(
    "--pico-port",
    envvar="PICO_PORT",
    type=click.IntRange(1, 12),
    default=6,
    show_default=True,
    help="USB port on the Pico fixture",
)
@click.option("--setup/--no-setup", default=None, help="Run pre-test setup for YubiKey")
@click.option(
    "--app",
    type=click.Choice(list(App)),
    multiple=True,
    default=None,
    help="YubiKey applications to test (default: all)",
)
def main(
    serial, reader, target, window_size, name, keyless, manual, controller, pico_port, setup, app
):
    """Run UI tests for Yubico Authenticator.

    WARNING: This will run tests against a connected YubiKey. Its contents will be destroyed!

    For a full set of tests, run --keyless without a YubiKey connected, then the full keyed
    testsuite over both USB and NFC, both without and with the --manual flag.

    Example:

    \b
      $ ./testrunner.sh --keyless
      $ ./testrunner.sh --serial 123456
      $ ./testrunner.sh --serial 123456 --manual
      $ ./testrunner.sh --serial 123456 --controller http://192.168.7.1
      $ ./testrunner.sh --serial 123456 --controller http://192.168.7.1 --manual
      $ ./testrunner.sh --serial 123456 --app management --no-setup --window-size wide
      $ ./testrunner.sh --reader hid --serial 123456
      $ ./testrunner.sh --reader hid --serial 123456 --manual

    You can also run the tests on an Android device connected via adb:

    \b
      $ ./testrunner.sh --target pixel --keyless
      $ ./testrunner.sh --target pixel --serial 123456
      $ ./testrunner.sh --target pixel --serial 123456 --manual
    """
    flutter = "flutter"
    if sys.platform == "win32":
        flutter += ".bat"

    cmd = [flutter, "test"]
    apps = list(app) if app else list(App)
    dartvars = {}
    msgs = []
    pico = None
    setup_fns = []
    if controller:
        parsed = urlparse(controller)
        if parsed.scheme not in ("http", "https") or not parsed.netloc:
            raise click.BadParameter("Expected an HTTP(S) URL", param_hint="--controller")
        if keyless or reader:
            raise click.UsageError("--controller requires a USB YubiKey test run")
        if serial is None:
            raise click.UsageError("--controller requires --serial to verify the Pico port")
        pico = PicoController(controller, pico_port)
        dartvars["CONTROLLER"] = pico.base_url
        dartvars["PICO_PORT"] = pico_port

    if keyless:
        cmd.append("integration_test/keyless_test.dart")
        click.echo("ℹ️  Running tests without a YubiKey")
        msgs.append("Ensure no YubiKey(s) are connected")
    else:
        cmd.append("integration_test/keyed_test.dart")
        click.echo("ℹ️  Running tests with a YubiKey")

        if reader:
            dartvars["READER"] = reader
            devs = list_devices(reader)
            if not devs:
                raise click.ClickException("No NFC reader found matching name")
            if len(devs) > 1:
                raise click.ClickException("Multiple NFC readers found matching name")
            dev = devs[0]
            with dev.open_connection(SmartCardConnection) as conn:
                info = read_info(conn, dev.pid)
        else:
            devs = list_all_devices()
            if not devs:
                raise click.ClickException("No devices found")
            if len(devs) > 1:
                raise click.ClickException(
                    "Multiple devices found, please connect just one"
                )

            dev, info = devs[0]

        if serial:
            serial = int(serial)
            click.echo("Connecting to YubiKey with specified serial number...")
            dartvars["TEST_SERIALS"] = serial
            if info.serial != serial:
                raise click.ClickException(
                    f"Device serial {info.serial} does not match {serial}"
                )
        else:
            click.echo("Connecting to YubiKey with no serial number...")
            dartvars["TEST_SERIALS"] = 0
            if info.serial is not None:
                raise click.ClickException(
                    f"Connected YubiKey has serial {info.serial}, expecting no serial "
                    "(use --serial to specify a serial number)"
                )

        click.echo(f"⚠️  Using YubiKey with serial {serial}, tests are destructive!")
        dartvars["INFO"] = json.dumps(asdict(info))

        click.echo(f"Running tests for: {', '.join(apps)}")
        setup_fns = [app_setup[a] for a in apps if a in app_setup and not manual]

        if setup_fns:
            if setup is None:
                click.echo()
                setup = click.confirm(
                    "Configure the YubiKey for tests? This may be destructive!",
                    default=False,
                )
        msgs.append("Ensure the YubiKey is connected to the test machine")

    if target:
        cmd += ["-d", target]
    if window_size:
        dartvars["WINDOW_SIZE"] = window_size
    if name:
        cmd += ["--name", f".*{name}.*"]

    if manual:
        click.echo("ℹ️  Running tests that require interaction!")
        if pico is None:
            msgs.append("Follow in-app instructions to interact with the YubiKey")
        else:
            msgs.append(f"Pico controller {pico.base_url}, USB port {pico.port}")
        cmd += ["--tags", "manual"]
    else:
        cmd += ["--exclude-tags", "manual"]

    dartvars["TEST_APPS"] = ",".join(apps)

    click.echo()
    click.echo("About to run tests, keep in mind:")
    for msg in msgs:
        click.echo(f"• {msg}")

    click.echo()
    click.confirm("Do you want to continue?", abort=True)

    click.echo("Starting tests...")

    try:
        if pico is not None:
            verify_controller(pico, serial)
            dev = next(
                (device for device, info in list_all_devices() if info.serial == serial),
                None,
            )
            if dev is None:
                raise click.ClickException(
                    f"YubiKey {serial} disappeared after controller verification"
                )
        if setup:
            for fn in setup_fns:
                fn(dev, controller=pico)
        result = subprocess.run(
            cmd + [f"--dart-define={k}={v}" for k, v in dartvars.items()],
            shell=False,
            check=False,
        )
    finally:
        if pico is not None:
            pico.restore()
    raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
