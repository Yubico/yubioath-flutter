import json
import subprocess
from dataclasses import asdict
from enum import StrEnum

import click
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


app_setup = {
    App.fido: setup_fido,
}


@click.command()
@click.option("--serial", "-s", type=str, help="Device serial number")
@click.option("--reader", "-r", type=str, help="NFC reader name")
@click.option("--target", "-d", type=str, help="flutter device to target")
@click.option("--name", "-k", type=str, help="Test names to match against")
@click.option("--keyless", is_flag=True, help="Run tests without a YubiKey")
@click.option("--manual", is_flag=True, help="Run tests requiring manual interaction")
@click.option("--setup/--no-setup", default=None, help="Run pre-test setup for YubiKey")
@click.option(
    "--app",
    type=click.Choice(list(App)),
    multiple=True,
    default=None,
    help="YubiKey applications to test (default: all)",
)
def main(serial, reader, target, name, keyless, manual, setup, app):
    cmd = ["flutter", "test"]
    apps = list(app) if app else list(App)
    dartvars = {}
    msgs = []

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
            dartvars["TEST_SERIALS"] = serial
            if info.serial != serial:
                raise click.ClickException(
                    f"Device serial {info.serial} does not match {serial}"
                )
        else:
            dartvars["TEST_SERIALS"] = 0
            if info.serial is not None:
                raise click.ClickException(
                    f"Device serial {info.serial} does not match None"
                )

        click.echo(f"⚠️  Using YubiKey with serial {serial}, tests are destructive!")
        dartvars["INFO"] = json.dumps(asdict(info))

        click.echo(f"Running tests for: {', '.join(apps)}")
        setup_fns = [app_setup[a] for a in apps if a in app_setup]

        if setup_fns:
            if setup is None:
                click.echo()
                setup = click.confirm(
                    "Configure the YubiKey for tests? This may be destructive!",
                    default=False,
                )
            if setup:
                for fn in setup_fns:
                    fn(dev)

        msgs.append("Ensure the YubiKey is connected to the test machine")

    if target:
        cmd += ["-d", target]
    if name:
        cmd += ["--name", f".*{name}.*"]

    if manual:
        click.echo("ℹ️  Running tests that require manual interaction!")
        msgs.append("Follow in-app instructions to interact with the YubiKey")
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

    subprocess.run(
        cmd + [f"--dart-define={k}={v}" for k, v in dartvars.items()], shell=False
    )


if __name__ == "__main__":
    main()
