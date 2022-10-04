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

from .base import RpcException, encode_bytes
from .device import RootNode

from queue import Queue
from threading import Thread, Event
from typing import Callable, Dict, List

import json
import logging

logger = logging.getLogger(__name__)


class _JsonLoggingFormatter(logging.Formatter):
    def format(self, record):
        data = {
            "time": record.created,
            "name": record.name,
            "level": record.levelname,
            "message": record.getMessage(),
        }
        if record.exc_info:
            if not record.exc_text:
                record.exc_text = self.formatException(record.exc_info)
            data["exc_text"] = record.exc_text
        return json.dumps(data)


def _init_logging(stream=None):
    logging.disable(logging.NOTSET)
    logging.basicConfig(stream=stream)
    logging.root.handlers[0].setFormatter(_JsonLoggingFormatter())


def _handle_incoming(event, recv, error, cmd_queue):
    while True:
        request = recv()
        if not request:
            break
        try:
            kind = request["kind"]
            if kind == "signal":
                # Cancel signals are handled here, the rest forwarded
                if request["status"] == "cancel":
                    event.set()
                else:
                    # Ignore other signals
                    logger.error("Unhandled signal: %r", request)
            elif kind == "command":
                cmd_queue.join()  # Wait for existing command to complete
                event.clear()  # Reset event for next command
                cmd_queue.put(request)
            else:
                error("invalid-command", "Unsupported request type")
        except KeyError as e:
            error("invalid-command", str(e))
        except RpcException as e:
            error(e.status, e.message, e.body)
        except Exception as e:
            logger.exception("Unhandled exception")
            error("exception", f"{e!r}")
    event.set()
    cmd_queue.put(None)


def process(
    send: Callable[[Dict], None],
    recv: Callable[[], Dict],
    handler: Callable[[str, List, Dict, Event, Callable[[str], None]], Dict],
) -> None:
    def error(status: str, message: str, body: Dict = {}):
        send(dict(kind="error", status=status, message=message, body=body))

    def signal(status: str, body: Dict = {}):
        send(dict(kind="signal", status=status, body=body))

    def success(body: Dict):
        send(dict(kind="success", body=body))

    event = Event()
    cmd_queue: Queue = Queue(1)
    read_thread = Thread(target=_handle_incoming, args=(event, recv, error, cmd_queue))
    read_thread.start()

    while True:
        request = cmd_queue.get()
        if request is None:
            break
        try:
            success(
                handler(
                    request["action"],
                    request.get("target", []),
                    request.get("body", {}),
                    event,
                    signal,
                )
            )
        except RpcException as e:
            error(e.status, e.message, e.body)
        except Exception as e:
            logger.exception("Unhandled exception")
            error("exception", f"{e!r}")
        cmd_queue.task_done()

    read_thread.join()


def run_rpc(
    send: Callable[[Dict], None],
    recv: Callable[[], Dict],
) -> None:
    process(send, recv, RootNode())


def run_rpc_pipes(stdout, stdin):
    _init_logging()

    def _json_encode(value):
        if isinstance(value, bytes):
            return encode_bytes(value)
        raise TypeError(type(value))

    def send(data):
        json.dump(data, stdout, default=_json_encode)
        stdout.write("\n")
        stdout.flush()

    def recv():
        line = (stdin.readline() or "").strip()
        if line:
            return json.loads(line)
        return None

    run_rpc(send, recv)


class _WriteLog:
    def __init__(self, socket):
        self._socket = socket

    def write(self, value):
        self._socket.sendall(b"E" + value.encode())


def run_rpc_socket(sock):
    _init_logging(_WriteLog(sock))

    def _json_encode(value):
        if isinstance(value, bytes):
            return encode_bytes(value)
        raise TypeError(type(value))

    def send(data):
        sock.sendall(b"O" + json.dumps(data, default=_json_encode).encode() + b"\n")

    def recv():
        line = b""
        while not line.endswith(b"\n"):
            chunk = sock.recv(1024)
            if not chunk:
                return None
            line += chunk
        line = line.strip()
        if line:
            return json.loads(line)
        return None

    run_rpc(send, recv)
