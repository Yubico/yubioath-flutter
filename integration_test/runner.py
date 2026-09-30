# /// script
# requires-python = ">=3.11"
# dependencies = ["click", "yubikey-manager", "fido2", "pyscard", "hidapi"]
# ///

import json
import os
import subprocess
import sys
import time
from dataclasses import asdict
from enum import StrEnum
from pathlib import Path
from urllib.parse import urlparse

import click
from controller import PicoController
from fido_prep import setup as setup_fido
from ykman.device import list_all_devices
from ykman.pcsc import list_devices
from yubikit.core.smartcard import SmartCardConnection
from yubikit.support import read_info

from run_artifacts import RunArtifacts


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
@click.option(
    "--manual/--no-manual",
    default=None,
    help="Run only / exclude interaction tests (default: include both with a controller)",
)
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
    "--artifacts-dir",
    type=click.Path(path_type=Path, file_okay=False),
    default=Path(__file__).resolve().parents[1] / "build" / "test-runs",
    help="Directory for timestamped test logs and failure diagnostics",
)
@click.option(
    "--service-log",
    type=click.Path(path_type=Path, dir_okay=False),
    help="Log from an externally started ykman-svc (start it at TRAFFIC level)",
)
@click.option(
    "--app",
    type=click.Choice(list(App)),
    multiple=True,
    default=None,
    help="YubiKey applications to test (default: all)",
)
def main(
    serial, reader, target, window_size, name, keyless, manual, controller,
    pico_port, setup, artifacts_dir, service_log, app,
):
    """Run UI tests for Yubico Authenticator.

    WARNING: This will run tests against a connected YubiKey. Its contents will be destroyed!

    For a full set of tests, run --keyless without a YubiKey connected, then the full keyed
    testsuite over both USB and NFC, both without and with the --manual flag.
    With --controller, both manual and non-manual tests run by default;
    --manual runs only interaction tests and --no-manual excludes them.

    Each run writes private, timestamped artifacts to build/test-runs by default.
    Desktop app/helper traffic is captured in app.log. To capture an external
    ykman-svc as well, start it with TRAFFIC logging to a private file and pass
    that file with --service-log. Logs may contain test PINs and protocol data.
    On Android, traffic goes to logcat and is not included in app.log.

    Example:

    \b
      $ ./testrunner.sh --keyless
      $ ./testrunner.sh --serial 123456
      $ ./testrunner.sh --serial 123456 --manual
      $ ./testrunner.sh --serial 123456 --controller http://192.168.7.1
      $ ./testrunner.sh --serial 123456 --controller http://192.168.7.1 --manual
      $ ./testrunner.sh --serial 123456 --controller http://192.168.7.1 --no-manual
      $ ./testrunner.sh --serial 123456 --app management --no-setup --window-size wide
      $ ./testrunner.sh --serial 123456 --service-log /path/to/ykman-svc.log
      $ ./testrunner.sh --reader hid --serial 123456
      $ ./testrunner.sh --reader hid --serial 123456 --manual

    You can also run the tests on an Android device connected via adb:

    \b
      $ ./testrunner.sh --target pixel --keyless
      $ ./testrunner.sh --target pixel --serial 123456
      $ ./testrunner.sh --target pixel --serial 123456 --manual
    """
    if service_log is not None and not service_log.is_file():
        raise click.BadParameter("Service log must exist before the run", param_hint="--service-log")
    os.umask(0o077)
    artifacts = RunArtifacts(artifacts_dir, service_log)
    click.echo(f"Test artifacts: {artifacts.path}")
    try:
        result = _run_tests(
            serial, reader, target, window_size, name, keyless, manual,
            controller, pico_port, setup, app, artifacts,
        )
    except BaseException as error:
        artifacts.event("runner_error", error=str(error))
        artifacts.finish(1, error)
        raise
    else:
        artifacts.finish(result)
        raise SystemExit(result)


def _run_tests(
    serial, reader, target, window_size, name, keyless, manual, controller,
    pico_port, setup, app, artifacts: RunArtifacts,
) -> int:
    flutter = "flutter"
    if sys.platform == "win32":
        flutter += ".bat"

    cmd = [flutter, "test", "--reporter=json"]
    apps = list(app) if app else list(App)
    dartvars = {
        "TEST_LOG_FILE": str(artifacts.app_log),
        "TEST_DIAGNOSTICS_DIR": str(artifacts.path),
    }
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

    artifacts.event(
        "run_config",
        serial=serial, target=target, apps=apps, name=name, manual=manual,
        window_size=window_size, controller=controller, pico_port=pico_port,
        setup=setup, service_log=str(artifacts.service_log) if artifacts.service_log else None,
    )
    artifacts.event("device_discovery_start")
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
    artifacts.event(
        "device_discovery_end",
        serial=info.serial if not keyless else None,
        pid=dev.pid if not keyless and not reader else None,
    )

    if target:
        cmd += ["-d", target]
    if window_size:
        dartvars["WINDOW_SIZE"] = window_size
    if name:
        cmd += ["--name", f".*{name}.*"]

    if manual is True:
        click.echo("ℹ️  Running only tests that require interaction!")
        cmd += ["--tags", "manual"]
    elif manual is False or pico is None:
        cmd += ["--exclude-tags", "manual"]
    else:
        click.echo("ℹ️  Running all tests, including those that require interaction!")

    if manual is True or (manual is None and pico is not None):
        if pico is None:
            msgs.append("Follow in-app instructions to interact with the YubiKey")
        else:
            msgs.append(f"Pico controller {pico.base_url}, USB port {pico.port}")

    dartvars["TEST_APPS"] = ",".join(apps)

    click.echo()
    click.echo("About to run tests, keep in mind:")
    for msg in msgs:
        click.echo(f"• {msg}")

    click.echo()
    click.confirm("Do you want to continue?", abort=True)

    click.echo("Starting tests...")

    result = None
    try:
        if pico is not None:
            with artifacts.phase("controller_verification"):
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
            with artifacts.phase("fixture_setup"):
                for fn in setup_fns:
                    fn(dev, controller=pico)
        result = artifacts.run_flutter(
            cmd + [f"--dart-define={k}={v}" for k, v in dartvars.items()]
        )
    finally:
        if pico is not None:
            try:
                with artifacts.phase("controller_restore"):
                    pico.restore()
            except Exception as error:
                click.echo(f"Pico restore failed: {error}", err=True)
                if result == 0 and sys.exc_info()[0] is None:
                    raise
    return result


if __name__ == "__main__":
    main()
