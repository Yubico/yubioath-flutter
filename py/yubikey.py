#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import types
import re
from base64 import b32decode, b64decode
from binascii import a2b_hex, b2a_hex

from ykman.descriptor import get_descriptors
from ykman.util import CAPABILITY, TRANSPORT, derive_key, parse_uri, parse_b32_key
from ykman.driver_otp import YkpersError
from ykman.oath import OathController, Credential
from py.qr import qrparse
from py.qr import qrdecode

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

    def refresh_credentials(self, timestamp, password_key=None):
        return [c.to_dict() for c in self._calculate_all(timestamp, password_key)]

    def calculate(self, credential, timestamp, password_key):
        return self._calculate(Credential.from_dict(credential), timestamp, password_key).to_dict()

    def calculate_slot_mode(self, slot, digits, timestamp):
        dev = self._descriptor.open_device(TRANSPORT.OTP)
        code = dev.driver.calculate(slot, challenge=timestamp, totp=True, digits=int(digits), wait_for_touch=True)
        return Credential(self._slot_name(slot), code=code, oath_type='totp', touch=True, algo='SHA1', expiration=self._expiration(timestamp)).to_dict()

    def refresh_slot_credentials(self, slots, digits, timestamp):
        result = []
        if slots[0]:
            cred = self._read_slot_cred(1, digits[0], timestamp)
            if cred:
                result.append(cred)
        if slots[1]:
            cred = self._read_slot_cred(2, digits[1], timestamp)
            if cred:
                result.append(cred)
        return [c.to_dict() for c in result]

    def _read_slot_cred(self, slot, digits, timestamp):
        try:
            dev = self._descriptor.open_device(TRANSPORT.OTP)
            code = dev.driver.calculate(slot, challenge=timestamp, totp=True, digits=int(digits), wait_for_touch=False)
            return Credential(self._slot_name(slot), code=code, oath_type='totp', touch=False, algo='SHA1', expiration=self._expiration(timestamp))
        except YkpersError as e:
                if e.errno == 11:
                    return Credential(self._slot_name(slot), oath_type='totp', touch=True, algo='SHA1')
        except:
            pass
        return None

    def _slot_name(self, slot):
        return "YubiKey Slot {}".format(slot)

    def _expiration(self, timestamp):
        return ((timestamp + 30) // 30) * 30

    def needs_validation(self):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            controller = OathController(dev.driver)
            return controller.locked
        except:
            return False


    def get_oath_id(self):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        return b2a_hex(controller.id).decode('utf-8')

    def derive_key(self, password):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        key = derive_key(controller.id, password)
        return b2a_hex(key).decode('utf-8')

    def validate(self, key):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        if key is not None:
            try:
                controller.validate(a2b_hex(key))
                return True
            except:
                return False

    def set_password(self, new_password, password_key):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        if controller.locked and password_key is not None:
            controller.validate(a2b_hex(password_key))
        if new_password is not None:
            key = derive_key(controller.id, new_password)
            controller.set_password(key)
        else:
            controller.clear_password()

    def add_credential(self, name, key, oath_type, digits, algo, touch, password_key):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        if controller.locked and password_key is not None:
            controller.validate(a2b_hex(password_key))
        try:
            key = parse_b32_key(key)
        except Exception as e:
            return str(e)
        controller.put(key, name, oath_type, digits, algo=algo, require_touch=touch)

    def add_slot_credential(self, slot, key, touch):
        dev = self._descriptor.open_device(TRANSPORT.OTP)
        key = parse_b32_key(key)
        if len(key) > 64:  # Keys longer than 64 bytes are hashed.
            key = hashlib.sha1(key).digest()
        if len(key) > 20:
            raise ValueError('YubiKey Slots cannot handle TOTP keys over 20 bytes.')
        key += b'\x00' * (20 - len(key))  # Keys must be padded to 20 bytes.
        code = dev.driver.program_chalresp(int(slot), key, touch)

    def delete_slot_credential(self, slot):
        dev = self._descriptor.open_device(TRANSPORT.OTP)
        dev.driver.zap_slot(slot)

    def delete_credential(self, credential, password_key):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        if controller.locked and password_key is not None:
            controller.validate(a2b_hex(password_key))
        controller.delete(Credential.from_dict(credential))

    def _calculate(self, credential, timestamp, password_key):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        if controller.locked and password_key is not None:
            controller.validate(a2b_hex(password_key))
        cred = controller.calculate(credential, timestamp)
        return cred

    def _calculate_all(self, timestamp, password_key):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        if controller.locked and password_key is not None:
            controller.validate(a2b_hex(password_key))
        creds = controller.calculate_all(timestamp)
        creds = [c for c in creds if not c.hidden]
        return creds

    def parse_qr(self, screenshot):
        data = b64decode(screenshot['data'])
        image = PixelImage(data, screenshot['width'], screenshot['height'])
        for qr in qrparse.parse_qr_codes(image, 2):
            return parse_uri(qrdecode.decode_qr_data(qr))

    def reset(self):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        controller.reset()


class PixelImage(object):

    def __init__(self, data, width, height):
        self.data = data
        self.width = width
        self.height = height

    def get_line(self, line_number):
        return self.data[self.width * line_number:self.width * (line_number + 1)]

controller = Controller()
