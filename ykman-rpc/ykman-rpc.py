#!/usr/bin/env python3

from rpc import run_rpc_pipes
import sys


if __name__ == "__main__":
    run_rpc_pipes(sys.stdout, sys.stdin)
