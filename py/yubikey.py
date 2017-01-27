#!/usr/bin/env python
# -*- coding: utf-8 -*-


import os
import json
import types
import struct
from base64 import b32decode
from binascii import b2a_hex, a2b_hex, Error

from ykman.descriptor import get_descriptors
from ykman.util import CAPABILITY, TRANSPORT, Mode, modhex_encode, modhex_decode, generate_static_pw
from ykman.driver import ModeSwitchError
from ykman.driver_otp import YkpersError

NON_FEATURE_CAPABILITIES = [CAPABILITY.CCID, CAPABILITY.NFC]

def as_json(f):
    def wrapped(*args, **kwargs):
        return json.dumps(f(*args, **kwargs))
    return wrapped


class Controller(object):
    _descriptor = None
    _dev_info = None

    def __init__(self):
        # Wrap all return values as JSON.
        for f in dir(self):
            if not f.startswith('_'):
                func = getattr(self, f)
                if isinstance(func, types.MethodType):
                    setattr(self, f, as_json(func))

    def get_features(self):
        return [c.name for c in CAPABILITY if c not in NON_FEATURE_CAPABILITIES]

    def count_devices(self):
        return len(list(get_descriptors()))

    def refresh(self):
        descriptors = list(get_descriptors())
        if len(descriptors) != 1:
            self._descriptor = None
            return

        desc = descriptors[0]
        if desc.fingerprint != (self._descriptor.fingerprint if self._descriptor else None):
            dev = desc.open_device()
            if not dev:
                return
            self._dev_info = {
                'name': dev.device_name,
                'version': '.'.join(str(x) for x in dev.version),
                'serial': dev.serial or '',
                'enabled': [c.name for c in CAPABILITY if c & dev.enabled],
                'connections': [t.name for t in TRANSPORT if t & dev.capabilities]
            }
            self._descriptor = desc

        return self._dev_info

    def set_mode(self, connections):
        dev = self._descriptor.open_device()
        try:
            transports = sum([TRANSPORT[c] for c in connections])
            dev.mode = Mode(transports & TRANSPORT.usb_transports())
        except ModeSwitchError as e:
            return str(e)

    def program_oath_hotp(self, slot, key, digits):
        try:
            unpadded = key.upper().rstrip('=').replace(' ', '')
            key = b32decode(unpadded + '=' * (-len(unpadded) % 8))
            dev = self._descriptor.open_device(TRANSPORT.OTP)
            dev.driver.program_hotp(slot, key, hotp8=(digits == 8))
        except Error as e:
            return str(e)
        except YkpersError as e:
            return e.errno


controller = Controller()
