#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import types
import hashlib
from base64 import b64decode
from binascii import a2b_hex, b2a_hex

from ykman.descriptor import get_descriptors
from ykman.util import (
    CAPABILITY, TRANSPORT, parse_b32_key)
from ykman.driver_otp import YkpersError
from ykman.driver_ccid import APDUError
from ykman.oath import (ALGO, OATH_TYPE, OathController, CredentialData,
        Credential, Code, SW)
from ykman.settings import Settings
from qr import qrparse, qrdecode


def as_json(f):
    def wrapped(*args):
        return json.dumps(f(*(json.loads(a) for a in args)))
    return wrapped


def cred_to_dict(cred):
    return {
        'key': cred.key.decode('utf8'),
        'issuer': cred.issuer,
        'name': cred.name,
        'oath_type': cred.oath_type.name,
        'period': cred.period,
        'touch': cred.touch
    }


def cred_from_dict(data):
    return Credential(
        data['key'].encode('utf-8'),
        OATH_TYPE[data['oath_type']],
        data['touch']
    )


def code_to_dict(code):
    return {
        'value': code.value,
        'valid_from': code.valid_from,
        'valid_to': min(code.valid_to, 9999999999)  # No Inf in JSON.
    } if code else None


def pair_to_dict(cred, code):
    return {
        'credential': cred_to_dict(cred),
        'code': code_to_dict(code)
    }


class Controller(object):
    _descriptor = None
    _dev_info = None
    _key = None

    def __init__(self):
        self.settings = Settings('oath')

        # Wrap all args and return values as JSON.
        for f in dir(self):
            if not f.startswith('_'):
                func = getattr(self, f)
                if isinstance(func, types.MethodType):
                    setattr(self, f, as_json(func))

    def count_devices(self):
        return len(get_descriptors())

    def refresh(self, otp_mode=False):
        descriptors = get_descriptors()
        if len(descriptors) != 1:
            self._descriptor = None
            return None

        desc = descriptors[0]
        if desc.fingerprint != (
                self._descriptor.fingerprint if self._descriptor else None):
            try:
                dev = desc.open_device(TRANSPORT.OTP if otp_mode else TRANSPORT.CCID)
            except:
                return None
            self._descriptor = desc
            self._dev_info = {
                'name': dev.device_name,
                'version': '.'.join(str(x) for x in dev.version),
                'serial': dev.serial or '',
                'enabled': [c.name for c in CAPABILITY if c & dev.enabled],
                'connections': [
                    t.name for t in TRANSPORT if t & dev.capabilities],
            }

        return self._dev_info

    def _unlock(self, controller):
        if controller.locked:
            keys = self.settings.get('keys', {})
            if self._key is not None:
                controller.validate(self._key)
            elif controller.id in keys:
                controller.validate(a2b_hex(keys[controller.id]))
            else:
                return False
        return True

    def refresh_credentials(self, timestamp):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            controller = OathController(dev.driver)
            self._unlock(controller)
            entries = controller.calculate_all(timestamp)
            return [pair_to_dict(cred, code) for (cred, code) in entries if not cred.is_hidden]
        except:
            return []

    def calculate(self, credential, timestamp):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            controller = OathController(dev.driver)
            self._unlock(controller)
        except:
            return None
        code = controller.calculate(cred_from_dict(credential), timestamp)
        return code_to_dict(code)

    def calculate_slot_mode(self, slot, digits, timestamp):
        dev = self._descriptor.open_device(TRANSPORT.OTP)
        code = dev.driver.calculate(
            slot, challenge=timestamp, totp=True, digits=int(digits),
            wait_for_touch=True)
        valid_from = timestamp - (timestamp % 30)
        valid_to = valid_from + 30
        code = Code(code, valid_from, valid_to)
        return pair_to_dict(Credential(self._slot_name(slot), OATH_TYPE.TOTP, True), code)

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
        return [pair_to_dict(cred, code) for (cred, code) in result]

    def _read_slot_cred(self, slot, digits, timestamp):
        try:
            dev = self._descriptor.open_device(TRANSPORT.OTP)
            code = dev.driver.calculate(
                slot, challenge=timestamp, totp=True, digits=int(digits),
                wait_for_touch=False)
            valid_from = timestamp - (timestamp % 30)
            valid_to = valid_from + 30
            code = Code(code, valid_from, valid_to)
            return (Credential(self._slot_name(slot), OATH_TYPE.TOTP, False), code)
        except YkpersError as e:
            if e.errno == 11:
                return (Credential(self._slot_name(slot), OATH_TYPE.TOTP, True), None)
        except Exception as e:
            return (Credential(str(e).encode(), OATH_TYPE.TOTP, True), None)
        return None

    def _slot_name(self, slot):
        return "YubiKey Slot {}".format(slot).encode('utf-8')

    def _expiration(self, timestamp):
        return ((timestamp + 30) // 30) * 30

    def needs_validation(self):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            return not self._unlock(OathController(dev.driver))
        except:
            return True

    def get_oath_id(self):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            return OathController(dev.driver).id
        except:
            return None

    def provide_password(self, password, remember=False):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        self._key = controller.derive_key(password)
        try:
            controller.validate(self._key)
        except:
            return False
        if remember:
            keys = self.settings.setdefault('keys', {})
            keys[controller.id] = b2a_hex(self._key).decode()
            self.settings.write()
        return True

    def set_password(self, new_password, remember=False):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        self._unlock(controller)
        keys = self.settings.setdefault('keys', {})
        if new_password is not None:
            self._key = controller.set_password(new_password)
            if remember:
                keys[controller.id] = b2a_hex(self._key).decode()
            elif controller.id in keys:
                del keys[controller.id]
        else:
            controller.clear_password()
            del keys[controller.id]
            self._key = None
        self.settings.write()

    def add_credential(
            self, name, secret, issuer, oath_type, algo, digits,
            period, touch):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        self._unlock(controller)
        try:
            secret = parse_b32_key(secret)
        except Exception as e:
            return str(e)
        try:
            controller.put(CredentialData(secret, issuer, name,
                OATH_TYPE[oath_type], ALGO[algo], int(digits), int(period), 0,
                touch))
        except APDUError as e:
            # NEO doesn't return a no space error if full,
            # but a command aborted error. Assume it's because of
            # no space in this context.
            if e.sw in (SW.NO_SPACE, SW.COMMAND_ABORTED):
                return 'No space'
            else:
                raise

    def add_slot_credential(self, slot, key, touch):
        dev = self._descriptor.open_device(TRANSPORT.OTP)
        key = parse_b32_key(key)
        try:
            dev.driver.program_chalresp(int(slot), key, touch)
        except Exception as e:
            return str(e)

    def delete_slot_credential(self, slot):
        dev = self._descriptor.open_device(TRANSPORT.OTP)
        dev.driver.zap_slot(slot)

    def delete_credential(self, credential):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        self._unlock(controller)
        controller.delete(cred_from_dict(credential))

    def parse_qr(self, screenshot):
        data = b64decode(screenshot['data'])
        image = PixelImage(data, screenshot['width'], screenshot['height'])
        for qr in qrparse.parse_qr_codes(image, 2):
            return CredentialData.from_uri(qrdecode.decode_qr_data(qr))

    def reset(self):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        controller.reset()

    def slot_status(self):
        dev = self._descriptor.open_device(TRANSPORT.OTP)
        return list(dev.driver.slot_status)


class PixelImage(object):

    def __init__(self, data, width, height):
        self.data = data
        self.width = width
        self.height = height

    def get_line(self, line_number):
        return self.data[
            self.width * line_number:self.width * (line_number + 1)]


controller = Controller()
