#!/usr/bin/env python3

from rpc import run_rpc_pipes, run_rpc_socket

import socket
import sys


if __name__ == "__main__":
    try:
        index = sys.argv.index("--tcp")
        port = int(sys.argv[index + 1])
        nonce = sys.argv[index + 2].encode()

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(("localhost", port))
        sock.sendall(nonce + b"\n")

        run_rpc_socket(sock)
    except ValueError:
        run_rpc_pipes(sys.stdout, sys.stdin)
