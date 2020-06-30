#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import logging
import types
import time
import ykman.logging_setup
import smartcard.pcsc.PCSCExceptions
from base64 import b32encode, b64decode
from binascii import a2b_hex, b2a_hex
from ykman.descriptor import (
    get_descriptors, list_devices, open_device,
    FailedOpeningDeviceException, Descriptor)
from ykman.util import (TRANSPORT, APPLICATION, Mode, parse_b32_key)
from ykman.device import YubiKey, device_config
from ykman.driver_otp import YkpersError
from ykman.driver_ccid import (
    APDUError, CCIDError, list_readers,
    open_devices as open_ccid)
from ykman.oath import (
    ALGO, OATH_TYPE, OathController,
    CredentialData, Credential, Code, SW)
from ykman.otp import OtpController
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
    return failure(str(exception))


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
        except CCIDError:
            return failure('ccid_error')
        except smartcard.pcsc.PCSCExceptions.EstablishContextException:
            return failure('no_pcscd')
        except Exception as e:
            if str(e) == 'Incorrect padding':
                return failure('incorrect_padding')
            logger.error('Uncaught exception', exc_info=e)
            return unknown_failure(e)
    return wrapped


def is_nfc(reader_name):
    return "yubico" not in reader_name.lower()


class OathContextManager(object):
    def __init__(self, dev):
        self._dev = dev

    def __enter__(self):
        return OathController(self._dev.driver)

    def __exit__(self, exc_type, exc_value, traceback):
        self._dev.close()


class OtpContextManager(object):
    def __init__(self, dev):
        self._dev = dev

    def __enter__(self):
        return OtpController(self._dev.driver)

    def __exit__(self, exc_type, exc_value, traceback):
        self._dev.close()


class Controller(object):

    _descs = []
    _descs_fps = []
    _devices = []

    _current_serial = None
    _current_derived_key = None

    _reader_filter = None
    _readers = []

    def __init__(self):
        self.settings = Settings('oath')

        # Wrap all args and return values as JSON.
        for f in dir(self):
            if not f.startswith('_'):
                func = getattr(self, f)
                if isinstance(func, types.MethodType):
                    setattr(self, f, as_json(catch_error(func)))

    def _open_oath(self):
        if self._reader_filter:
            dev = self._get_dev_from_reader()
            if dev:
                return OathContextManager(dev)
            else:
                raise ValueError('no_device_custom_reader')

        return OathContextManager(
            open_device(TRANSPORT.CCID, serial=self._current_serial))

    def _open_otp(self):
        return OtpContextManager(
            open_device(TRANSPORT.OTP, serial=self._current_serial))

    def _descriptors_changed(self):
        old_descs = self._descs[:]
        old_descs_fps = self._descs_fps[:]
        self._descs = get_descriptors()
        self._descs_fps = [desc.fingerprint for desc in self._descs]
        descs_changed = (old_descs_fps != self._descs_fps)
        n_descs_changed = len(self._descs) != len(old_descs)
        return n_descs_changed or descs_changed

    def check_descriptors(self):
        return success({
            'usbDescriptorsChanged': self._descriptors_changed()
        })

    def _readers_changed(self, filter):
        old_readers = self._readers
        self._readers = list(open_ccid(filter))
        readers_changed = len(self._readers) != len(old_readers)
        return readers_changed

    def check_readers(self, filter):
        return success({
            'needToRefresh': self._readers_changed(filter)
        })

    def _get_dev_from_reader(self):
        readers = list(open_ccid(self._reader_filter))
        if len(readers) == 1:
            drv = readers[0]
            return YubiKey(Descriptor.from_driver(drv), drv)
        return None

    def _get_devices(self):
        res = []
        descs_to_match = self._descs[:]
        handled_serials = set()
        time.sleep(0.5)  # Let macOS take time to see the reader
        for transport in [TRANSPORT.CCID, TRANSPORT.OTP, TRANSPORT.FIDO]:
            if not descs_to_match:
                return res
            for dev in list_devices(transport):
                if not descs_to_match:
                    return res

                serial = dev.serial

                if dev.version:
                    version = '.'.join(str(x) for x in dev.version)
                else:
                    version = ""

                try:
                    controller = OathController(dev.driver)
                    dev.has_password = controller.locked
                except Exception as e:
                    logger.debug("Could not read out password for oath")

                if serial not in handled_serials:
                    handled_serials.add(serial)

                    matches_all = [
                        d for d in self._descs[:] if (
                            d.key_type, d.mode) == (
                                dev.driver.key_type, dev.driver.mode)]

                    matches_left = [
                        d for d in descs_to_match if (
                            d.key_type, d.mode) == (
                                dev.driver.key_type, dev.driver.mode)]

                    if len(matches_left) > 0:

                        if len(matches_all) == 1 and version == "":
                            # Only one matching descriptor of all descriptors,
                            # try reading any missing version from it
                            descriptor = matches_all[0]
                            if descriptor.version and not dev.version:
                                dev._desc_version = descriptor.version
                        res.append(self._serialise_dev(dev))
                        descs_to_match.remove(matches_left[0])
        return res

    def _serialise_dev(self, dev):

        def _get_version(dev):
            if dev.version:
                return '.'.join(str(x) for x in dev.version)
            if hasattr(dev, '_desc_version') and dev._desc_version:
                return '.'.join(str(x) for x in dev._desc_version)
            return ''

        return {
            'name': dev.device_name,
            'version': _get_version(dev),
            'serial': dev.serial or '',
            'usbAppEnabled': [a.name for a in APPLICATION if a & dev.config.usb_enabled],
            'usbAppSupported': [a.name for a in APPLICATION if a & dev.config.usb_supported],
            'nfcAppEnabled': [a.name for a in APPLICATION if a & dev.config.nfc_enabled],
            'nfcAppSupported': [a.name for a in APPLICATION if a & dev.config.nfc_supported],
            'usbInterfacesSupported': [t.name for t in TRANSPORT if t & dev.config.usb_supported],
            'usbInterfacesEnabled': str(dev.mode).split('+'),
            'canWriteConfig': dev.can_write_config,
            'configurationLocked': dev.config.configuration_locked,
            'formFactor': dev.config.form_factor,
            'hasPassword': dev.has_password if hasattr(dev, 'has_password') else False,
            'isNfc': self._reader_filter and not self._reader_filter.lower().startswith("yubico yubikey"),
       }

    def load_devices_custom_reader(self, reader_filter):
        self._devices = []
        self._reader_filter = reader_filter
        dev = self._get_dev_from_reader()

        try:
            controller = OathController(dev.driver)
            dev.has_password = controller.locked
        except Exception as e:
            logger.debug("Could not read out password for oath")

        if dev:
            self._devices.append(self._serialise_dev(dev))
            return success({'devices': self._devices})
        else:
            return success({'devices': []})

    def load_devices_usb(self):
        self._devices = []
        # Forget current serial and derived key if no descriptors
        # Return empty list of devices
        if not self._descs:
            self._current_serial = None
            self._current_derived_key = None
            return success({'devices': []})

        self._devices = self._get_devices()

        # If no current serial, or current serial seems removed,
        # select the first serial found.
        if not self._current_serial or (
                self._current_serial not in [
                    dev['serial'] for dev in self._devices]):
            for dev in self._devices:
                if dev['serial']:
                    self._current_serial = dev['serial']
                    break
        return success({'devices': self._devices})

    def write_config(self, usb_applications, nfc_applications):

        usb_enabled = 0x00
        nfc_enabled = 0x00
        for app in usb_applications:
            usb_enabled |= APPLICATION[app]
        for app in nfc_applications:
            nfc_enabled |= APPLICATION[app]


        if self._reader_filter:
            dev = self._get_dev_from_reader()
            dev.write_config(
                device_config(
                    usb_enabled=usb_enabled,
                    nfc_enabled=nfc_enabled,
                    ),
                reboot=True)
        else:

            with open_device(serial=self._current_serial) as dev:
                dev.write_config(
                    device_config(
                        usb_enabled=usb_enabled,
                        nfc_enabled=nfc_enabled,
                        ),
                    reboot=True)

        return success()

    def set_mode(self, interfaces):
        with open_device(serial=self._current_serial) as dev:
            transports = sum([TRANSPORT[i] for i in interfaces])
            dev.mode = Mode(transports & TRANSPORT.usb_transports())
        return success()


    def select_current_serial(self, serial):
        self._current_serial = serial
        self._current_derived_key = None
        return success()

    def ccid_calculate_all(self, timestamp):
        with self._open_oath() as oath_controller:
            self._unlock(oath_controller)
            entries = oath_controller.calculate_all(timestamp)
            return success(
                {
                    'entries': [
                        pair_to_dict(
                            cred, code) for (
                                cred, code) in entries if not cred.is_hidden]
                }
            )

    def ccid_calculate(self, credential, timestamp):
        with self._open_oath() as oath_controller:
            self._unlock(oath_controller)
            code = oath_controller.calculate(
                cred_from_dict(credential), timestamp)
            return success({
                'credential': credential,
                'code': code_to_dict(code)
            })

    def ccid_add_credential(
            self, name, secret, issuer, oath_type,
            algo, digits, period, touch, overwrite=False):
        secret = parse_b32_key(secret)
        with self._open_oath() as oath_controller:
            try:
                self._unlock(oath_controller)
                cred_data = CredentialData(
                    secret, issuer, name, OATH_TYPE[oath_type], ALGO[algo],
                    int(digits), int(period), 0, touch
                )
                if not overwrite:
                    key = cred_data.make_key()
                    if key in [cred.key for cred in oath_controller.list()]:
                        return failure('credential_already_exists')
                oath_controller.put(cred_data)
            except APDUError as e:
                # NEO doesn't return a no space error if full,
                # but a command aborted error. Assume it's because of
                # no space in this context.
                if e.sw in (SW.NO_SPACE, SW.COMMAND_ABORTED):
                    return failure('no_space')
                else:
                    raise
            return success()

    def ccid_validate(self, password, remember=False):
        with self._open_oath() as oath_controller:
            key = oath_controller.derive_key(password)
            try:
                oath_controller.validate(key)
                self._current_derived_key = key
                if remember:
                    keys = self.settings.setdefault('keys', {})
                    keys[oath_controller.id] = b2a_hex(
                        self._current_derived_key).decode()
                    self.settings.write()
                return success()
            except APDUError as e:
                if e.sw == SW.INCORRECT_PARAMETERS:
                    return failure('validate_failed')

    def otp_slot_status(self):
        with self._open_otp() as otp_controller:
            return success({'status': otp_controller.slot_status})

    def _unlock(self, controller):
        if controller.locked:
            keys = self.settings.get('keys', {})
            if self._current_derived_key is not None:
                controller.validate(self._current_derived_key)
            elif controller.id in keys:
                controller.validate(a2b_hex(keys[controller.id]))
            else:
                return failure('failed_to_unlock_key')

    def ccid_delete_credential(self, credential):
        with self._open_oath() as oath_controller:
            self._unlock(oath_controller)
            oath_controller.delete(cred_from_dict(credential))
            return success()

    def ccid_reset(self):
        with self._open_oath() as oath_controller:
            oath_controller.reset()
            return success()

    def ccid_clear_local_passwords(self):
        self.settings.setdefault('keys', {})
        del self.settings['keys']
        self.settings.write()
        return success()

    def ccid_remove_password(self):
        with self._open_oath() as oath_controller:
            self._unlock(oath_controller)
            oath_controller.clear_password()
            self._current_derived_key = None
            keys = self.settings.setdefault('keys', {})
            if oath_controller.id in keys:
                del keys[oath_controller.id]
            self.settings.write()
            return success()

    def ccid_set_password(self, new_password, remember=False):
        with self._open_oath() as oath_controller:
            self._unlock(oath_controller)
            keys = self.settings.setdefault('keys', {})
            self._current_derived_key = \
                oath_controller.set_password(new_password)
            if remember:
                keys[oath_controller.id] = b2a_hex(
                    self._current_derived_key).decode()
            elif oath_controller.id in keys:
                del keys[oath_controller.id]
            self.settings.write()
            return success()

    def get_connected_readers(self):
        return success({'readers': [str(reader) for reader in list_readers()]})

    def parse_qr(self, screenshot):
        data = b64decode(screenshot['data'])
        image = PixelImage(data, screenshot['width'], screenshot['height'])
        for qr in qrparse.parse_qr_codes(image, 2):
            try:
                return success(
                    credential_data_to_dict(
                        CredentialData.from_uri(qrdecode.decode_qr_data(qr))))
            except Exception as e:
                logger.error('Failed to parse uri', exc_info=e)
                return failure('failed_to_parse_uri')
        return failure('no_credential_found')


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
