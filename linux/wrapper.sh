#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SCRIPTPATH/lib/ $SCRIPTPATH/.yubico-authenticator
