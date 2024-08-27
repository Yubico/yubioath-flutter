#!/usr/bin/env python3

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

import cmd
import json
import click
import subprocess  # nosec
import sys

import logging
from threading import Thread
from typing import IO, cast

logger = logging.getLogger(__name__)


def red(value):
    return f"\u001b[31;1m{value}\u001b[0m"


def green(value):
    return f"\u001b[32;1m{value}\u001b[0m"


def yellow(value):
    return f"\u001b[33;1m{value}\u001b[0m"


def cyan(value):
    return f"\u001b[36;1m{value}\u001b[0m"


class RpcShell(cmd.Cmd):
    def __init__(self, stdin, stdout):
        super().__init__()
        self._stdin = stdin
        self._stdout = stdout
        self._echo = False
        self._path = []
        self._node = None
        self.do_cd(None)

    def _send(self, data):
        if self._echo:
            print("SEND:", cyan(json.dumps(data)))
        json.dump(data, self._stdin)
        self._stdin.write("\n")
        self._stdin.flush()

    def _recv(self):
        line = self._stdout.readline()
        if self._echo:
            print("RECV:", cyan(line))
        try:
            return json.loads(line)
        except Exception:
            print("failed to parse:", line)
            raise

    @property
    def prompt(self):
        return "/" + "/".join(self._path) + "> "

    def resolve_path(self, line):
        if line:
            parts = line.split("/")
            if parts[0]:
                parts = self._path + parts
            else:
                parts.pop(0)
            while ".." in parts:
                pos = parts.index("..")
                parts.pop(pos - 1)
                parts.pop(pos - 1)
        else:
            parts = self._path + [""]
        return parts

    def completepath(self, text, nodes_only=False):
        target = self.resolve_path(text)
        cmd = target.pop() if target else ""
        node = self.get_node(target)
        if node:
            body = node.get("body", {})
            names = [n + "/" for n in body.get("children", [])]
            if not nodes_only:
                actions = body.get("actions", [])
                if "get" in actions:
                    actions.remove("get")
                names += actions
            res = [n for n in names if n.startswith(cmd)]
            return res
        return []

    def completedefault(self, cmd, text, *args):  # type: ignore
        return self.completepath(text)

    def completenames(self, cmd, text, *ignored):  # type: ignore
        return self.completepath(text)

    def emptyline(self):
        self.do_ls(None)

    def get_node(self, target):
        logger.debug("sending get: %r", target)
        self._send({"kind": "command", "action": "get", "target": target})
        result = self._recv()
        logger.debug("got info: %r", result)
        kind = result["kind"]
        if kind == "success":
            return result
        elif kind == "error":
            status = result["status"]
            print(red(f"{status.upper()}: {result['message']}"))
        else:
            print(red(f"Invalid response: {result}"))

    def do_echo(self, args):
        self._echo = not self._echo
        print("ECHO is", "on" if self._echo else "off")

    def do_quit(self, args):
        return True

    def do_cd(self, args):
        if args:
            target = self.resolve_path(args)
            if target and not target[-1]:
                target.pop()
        else:
            target = []
        logger.debug("Get info for %r", target)
        if self.get_node(target):
            self._path = target
            logger.debug("set path %r", target)

    def complete_cd(self, cmd, text, *args):
        return self.completepath(text[3:], True)

    def do_ls(self, args):
        self._send({"kind": "command", "action": "get", "target": self._path})
        result = self._recv()
        kind = result["kind"]
        if kind == "success":
            self._node = result["body"]
            data = self._node.get("data", None)
            if data:
                for k, v in data.items():
                    print(yellow(f"{k}: {v}"))

            for c, c_data in self._node.get("children", {}).items():
                print(green(f"{c}/"))
                if c_data:
                    for k, v in c_data.items():
                        print(yellow(f"  {k}: {v}"))

            for name in self._node.get("actions", []):
                if name != "get":  # Don't show get, always available
                    print(cyan(f"{name}"))
        elif kind == "error":
            status = result["status"]
            print(red(f"{status.upper()}: {result['body']}"))
        else:
            print(red(f"Invalid response: {result}"))

    def default(self, line):
        parts = line.strip().split(maxsplit=1)
        if len(parts) == 2:
            try:
                args = json.loads(parts[1])
                if not isinstance(args, dict):
                    logger.error("Argument must be a JSON Object")
                    return
            except json.JSONDecodeError as e:
                logger.error("Error decoding JSON.", exc_info=e)
                return
        else:
            args = {}
        target = self.resolve_path(parts[0])
        action = target.pop()
        self._send(
            {
                "kind": "command",
                "action": action or "get",
                "target": target,
                "body": args,
            }
        )

        while True:
            result = self._recv()
            kind = result["kind"]

            if kind == "signal":
                print(cyan(f"{result['status']}: {result.get('body', None)}"))
            else:
                break

        if kind == "success":
            body = result.get("body", None)
            if body:
                print(yellow(json.dumps(body)))
        elif kind == "error":
            print(red(f"{result['status']}: {result['message']}"))
            body = result.get("body", None)
            if result:
                print(red(json.dumps(body)))
        else:
            print(red(f"Invalid response: {result}"))

    def do_EOF(self, args):
        return True


def log_stderr(stderr):
    while True:
        line = stderr.readline()
        if not line:
            break
        try:
            record = json.loads(line)
            print(red(f"{record['level']} {record['name']}: {record['message']}"))
            exc_text = record.get("exc_text")
            if exc_text:
                print(red(exc_text))
        except Exception:
            logger.exception(f"Failed to parse error: {line}")


@click.command()
@click.argument("executable", nargs=-1)
def shell(executable):
    """A basic shell for interacting with the Yubico Authenticator Helper."""
    helper = subprocess.Popen(  # nosec
        executable or [sys.executable, "authenticator-helper.py"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf8",
    )

    Thread(daemon=True, target=log_stderr, args=(helper.stderr,)).start()

    click.echo("Shell starting...")
    shell = RpcShell(helper.stdin, cast(IO[str], helper.stdout))
    shell.cmdloop()
    click.echo("Stopping...")
    helper.communicate()


if __name__ == "__main__":
    shell()
