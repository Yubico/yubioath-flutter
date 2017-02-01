#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import json
import types

from ykman.descriptor import get_descriptors
from ykman.driver import ModeSwitchError
from ykman.util import CAPABILITY, TRANSPORT, Mode
from ykman.oath import OathController, Credential


NON_FEATURE_CAPABILITIES = [CAPABILITY.CCID, CAPABILITY.NFC]


def as_json(f):
    def wrapped(*args):
        return json.dumps(f(*(json.loads(a) for a in args)))
    return wrapped


class Controller(object):
    _descriptor = None
    _dev_info = None

    def __init__(self):
        # Wrap all args and return values as JSON.
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
            self._descriptor = desc
            self._dev_info = {
                'name': dev.device_name,
                'version': '.'.join(str(x) for x in dev.version),
                'serial': dev.serial or '',
                'enabled': [c.name for c in CAPABILITY if c & dev.enabled],
                'connections': [t.name for t in TRANSPORT if t & dev.capabilities],
            }

        return self._dev_info

    def refresh_credentials(self, timestamp):
        return [c.to_dict() for c in self._calculate_all(timestamp)]

    def calculate(self, credential, timestamp):
        return self._calculate(Credential.from_dict(credential), timestamp).to_dict()

    def set_mode(self, connections):
        dev = self._descriptor.open_device()
        try:
            transports = sum([TRANSPORT[c] for c in connections])
            dev.mode = Mode(transports & TRANSPORT.usb_transports())
        except ModeSwitchError as e:
            return str(e)

    def _calculate(self, credential, timestamp):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        cred = controller.calculate(credential, timestamp)
        return cred

    def _calculate_all(self, timestamp):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        creds = controller.calculate_all(timestamp)
        creds = [c for c in creds if not c.hidden]
        return creds


controller = Controller()
