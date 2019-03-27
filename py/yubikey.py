#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import logging
import types
import ykman.logging_setup

from base64 import b32encode, b64decode
from binascii import a2b_hex, b2a_hex

from ykman.device import YubiKey
from ykman.descriptor import (
    get_descriptors, Descriptor, FailedOpeningDeviceException)
from ykman.util import (TRANSPORT, parse_b32_key)
from ykman.driver_otp import YkpersError
from ykman.otp import OtpController
from ykman.driver_ccid import APDUError, open_devices as open_ccid
from ykman.oath import (
    ALGO, OATH_TYPE, OathController,
    CredentialData, Credential, Code, SW)
from ykman.settings import Settings
from qr import qrparse, qrdecode


logger = logging.getLogger(__name__)


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


def credential_data_to_dict(credentialData):
    return {
        'secret': b32encode(credentialData.secret).decode(),
        'issuer': credentialData.issuer,
        'name': credentialData.name,
        'oath_type': credentialData.oath_type.name,
        'algorithm': credentialData.algorithm.name,
        'digits': credentialData.digits,
        'period': credentialData.period,
        'counter': credentialData.counter,
        'touch': credentialData.touch
    }


def success(result={}):
    result['success'] = True
    return result


def failure(err_id, result={}):
    result['success'] = False
    result['error_id'] = err_id
    return result


def unknown_failure(exception):
    return failure(None, {'error_message': str(exception)})


def catch_error(f):
    def wrapped(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except YkpersError as e:
            if e.errno == 3:
                return failure('write error')
            if e.errno == 4:
                return failure('timeout')
            logger.error('Uncaught exception', exc_info=e)
            return unknown_failure(e)
        except FailedOpeningDeviceException:
            return failure('open_device_failed')
        except APDUError as e:
            if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED:
                return failure('access_denied')
            raise
        except Exception as e:
            logger.error('Uncaught exception', exc_info=e)
            return unknown_failure(e)
    return wrapped


class Controller(object):
    _devices = []
    _desc_fingerprints = []
    _key = None

    def __init__(self):
        self.settings = Settings('oath')

        # Wrap all args and return values as JSON.
        for f in dir(self):
            if not f.startswith('_'):
                func = getattr(self, f)
                if isinstance(func, types.MethodType):
                    setattr(self, f, as_json(catch_error(func)))

    def calculate_all(self, timestamp, filter='yubico'):
        readers = list(open_ccid(filter))
        if not readers:
            return failure('no_readers_found')
        if len(readers) == 1:
            dev = YubiKey(Descriptor.from_driver(readers[0]), readers[0])
            controller = OathController(dev.driver)
            entries = controller.calculate_all(timestamp)
            return success(
                {
                    'entries':
                        [pair_to_dict(cred, code) for (
                            cred, code) in entries if not cred.is_hidden]
                }
            )
        else:
            return failure('too_many_readers_found')

    def calculate(self, credential, timestamp, filter='yubico'):
        readers = list(open_ccid(filter))
        if not readers:
            return failure('no_readers_found')
        if len(readers) == 1:
            dev = YubiKey(Descriptor.from_driver(readers[0]), readers[0])
            controller = OathController(dev.driver)
            code = controller.calculate(cred_from_dict(credential), timestamp)
            return success({
                'credential': credential,
                'code': code_to_dict(code)
            })
        else:
            return failure('too_many_readers_found')

    def add_credential(
            self, name, secret, issuer, oath_type, algo, digits,
            period, touch, filter='yubico'):
        secret = parse_b32_key(secret)
        readers = list(open_ccid(filter))
        if not readers:
            return failure('no_readers_found')
        if len(readers) == 1:
            dev = YubiKey(Descriptor.from_driver(readers[0]), readers[0])
            controller = OathController(dev.driver)
            try:
                controller.put(CredentialData(
                    secret, issuer, name, OATH_TYPE[oath_type], ALGO[algo],
                    int(digits), int(period), 0, touch
                ))
            except APDUError as e:
                # NEO doesn't return a no space error if full,
                # but a command aborted error. Assume it's because of
                # no space in this context.
                if e.sw in (SW.NO_SPACE, SW.COMMAND_ABORTED):
                    return failure('no_space')
                else:
                    raise
            return success()
        else:
            return failure('too_many_readers_found')

    def delete_credential(self, credential, filter='yubico'):
        readers = list(open_ccid(filter))
        if not readers:
            return failure('no_readers_found')
        if len(readers) == 1:
            dev = YubiKey(Descriptor.from_driver(readers[0]), readers[0])
            controller = OathController(dev.driver)
            controller.delete(cred_from_dict(credential))
            return success()
        else:
            return failure('too_many_readers_found')

    def parse_qr(self, screenshot):
            data = b64decode(screenshot['data'])
            image = PixelImage(data, screenshot['width'], screenshot['height'])
            for qr in qrparse.parse_qr_codes(image, 2):
                return success(credential_data_to_dict(
                    CredentialData.from_uri(qrdecode.decode_qr_data(qr))))
            return failure('no_credential_found')

    def refresh_ccid(self, filter='yubico'):
        new_desc_fingerprints = [desc.fingerprint for desc in get_descriptors()]
        descriptors_changed = (new_desc_fingerprints != self._desc_fingerprints)
        self._desc_fingerprints = new_desc_fingerprints

        if descriptors_changed:
            self._devices = []
            readers = list(open_ccid(filter))
            if not readers:
                return failure('no_readers_found')
            for reader in readers:
                dev = YubiKey(Descriptor.from_driver(reader), reader)
                self._devices.append({
                    'name': dev.device_name,
                    'version': dev.version,
                    'serial': dev.serial,
                })

        return success({'devices': self._devices})

    def refresh(self, otp_mode=False):
        descriptors = get_descriptors()
        if len(descriptors) != 1:
            self._descriptor = None
            return None

        desc = descriptors[0]

        unmatched_otp_mode = otp_mode and not desc.mode.has_transport(
            TRANSPORT.OTP)
        unmatched_ccid_mode = not otp_mode and not desc.mode.has_transport(
            TRANSPORT.CCID)

        if unmatched_otp_mode or unmatched_ccid_mode:
            return {
                'transports': [
                    t.name for t in TRANSPORT.split(desc.mode.transports)
                ],
                'usable': False,
            }

        if desc.fingerprint != (
                self._descriptor.fingerprint if self._descriptor else None) \
                or not otp_mode and not self._dev_info.get('version'):
            try:
                dev = desc.open_device(TRANSPORT.OTP if otp_mode
                                       else TRANSPORT.CCID)
                if otp_mode:
                    version = None
                else:
                    controller = OathController(dev.driver)
                    version = controller.version
            except Exception as e:
                logger.debug('Failed to refresh YubiKey', exc_info=e)
                return None

            self._descriptor = desc
            self._dev_info = {
                'usable': True,
                'name': dev.device_name,
                'version': version,
                'serial': dev.serial or '',
                'usb_interfaces_supported': [
                    t.name for t in TRANSPORT
                    if t & dev.config.usb_supported],
                'usb_interfaces_enabled': str(dev.mode).split('+')
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

    def clear_key(self):
        self._key = None

    def refresh_credentials(self, timestamp):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            controller = OathController(dev.driver)
            self._unlock(controller)
            entries = controller.calculate_all(timestamp)
            return [pair_to_dict(cred, code) for (cred, code) in entries
                    if not cred.is_hidden]
        except Exception:
            return []

    def _calculate(self, credential, timestamp):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            controller = OathController(dev.driver)
            self._unlock(controller)
        except Exception:
            return None
        code = controller.calculate(cred_from_dict(credential), timestamp)
        return code_to_dict(code)

    def calculate_slot_mode(self, slot, digits, timestamp):
        try:
            code = self._read_slot_code(
                slot, digits, timestamp, wait_for_touch=True)
            return pair_to_dict(Credential(self._slot_name(slot),
                                           OATH_TYPE.TOTP, True), code)
        except YkpersError as e:
            if e.errno == 4:
                logger.debug(
                    'Time out error, user probably did not touch the device.')
            else:
                logger.error(
                    'Failed to calculate code in slot mode', exc_info=e)
        except Exception as e:
            logger.error('Failed to calculate code in slot mode', exc_info=e)
        return None

    def refresh_slot_credentials(self, slots, digits, timestamp):
        result = []
        if slots[0]:
            entry = self._read_slot_cred(1, digits[0], timestamp)
            if entry:
                result.append(entry)
        if slots[1]:
            entry = self._read_slot_cred(2, digits[1], timestamp)
            if entry:
                result.append(entry)
        return [pair_to_dict(cred, code) for (cred, code) in result]

    def _read_slot_cred(self, slot, digits, timestamp):
        try:
            code = self._read_slot_code(
                slot, digits, timestamp, wait_for_touch=False)
            return (Credential(self._slot_name(slot), OATH_TYPE.TOTP, False),
                    code)
        except YkpersError as e:
            if e.errno == 11:
                return (Credential(self._slot_name(slot), OATH_TYPE.TOTP, True
                                   ), None)
        except Exception as e:
            return (Credential(str(e).encode(), OATH_TYPE.TOTP, True), None)
        return None

    def _read_slot_code(self, slot, digits, timestamp, wait_for_touch):
        with self._descriptor.open_device(TRANSPORT.OTP) as dev:
            controller = OtpController(dev.driver)
            code = controller.calculate(
                slot, challenge=timestamp, totp=True, digits=int(digits),
                wait_for_touch=wait_for_touch)
            valid_from = timestamp - (timestamp % 30)
            valid_to = valid_from + 30
            return Code(code, valid_from, valid_to)

    def _slot_name(self, slot):
        return "YubiKey Slot {}".format(slot).encode('utf-8')

    def needs_validation(self):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            return not self._unlock(OathController(dev.driver))
        except Exception:
            return True

    def get_oath_id(self):
        try:
            dev = self._descriptor.open_device(TRANSPORT.CCID)
            return OathController(dev.driver).id
        except Exception:
            return None

    def provide_password(self, password, remember=False):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        self._key = controller.derive_key(password)
        try:
            controller.validate(self._key)
        except Exception:
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

    def add_slot_credential(self, slot, key, touch):
        try:
            key = parse_b32_key(key)
            with self._descriptor.open_device(TRANSPORT.OTP) as dev:
                controller = OtpController(dev.driver)
                controller.program_chalresp(int(slot), key, touch)
                return {'success': True, 'error': None}
        except Exception as e:
            if str(e) == 'Incorrect padding':
                return {'success': False, 'error': 'wrong padding'}
            if str(e) == 'key lengths >20 bytes not supported':
                return {'success': False, 'error': 'too large key'}
            return {'success': False, 'error': str(e)}

    def delete_slot_credential(self, slot):
        with self._descriptor.open_device(TRANSPORT.OTP) as dev:
            controller = OtpController(dev.driver)
            controller.zap_slot(slot)

    def reset(self):
        dev = self._descriptor.open_device(TRANSPORT.CCID)
        controller = OathController(dev.driver)
        controller.reset()

    def slot_status(self):
        with self._descriptor.open_device(TRANSPORT.OTP) as dev:
            controller = OtpController(dev.driver)
            return list(controller.slot_status)


class PixelImage(object):

    def __init__(self, data, width, height):
        self.data = data
        self.width = width
        self.height = height

    def get_line(self, line_number):
        return self.data[
            self.width * line_number:self.width * (line_number + 1)]


controller = None


def init_with_logging(log_level, log_file=None):
    logging_setup = as_json(ykman.logging_setup.setup)
    logging_setup(log_level, log_file)

    init()


def init():
    global controller
    controller = Controller()
