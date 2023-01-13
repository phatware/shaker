import json
import hashlib
import uuid
import base64
import sys

from database import Database
from api_setup import _config
from email_util import sendActivationMail
from urllib.parse import quote
from strings import str_loc
from pin import pin_gen

def register_device(db, params, json_data):
    try:
        device_token = json_data['device_token']
        old_token = json_data['old_token']
        device_os = json_data['os']
        name = json_data['name']
        user_id = params['user_id']
        user_email = json_data['email']
        production = int(json_data['production'])
        headers = json_data["header"]

        # delete old device, if specified
        if user_id == 0:
            return {
                'status'  : 406,
                'message' : str_loc("error406_3")
            }

        dev = db.getDevice(device_token = device_token)

        if dev is not None and device_token == old_token and dev['production'] == production:
            status = int(dev['status'])
            msg = str_loc("error205_1")
            if status == 255:
                return {
                    'status'  : 403,
                    'message' : str_loc("error403_1")
                }
            elif status == 0:
                # generate new pin
                # pin = pin_gen(6)
                # setDeviceActivationPin(pin, device_id=dev["id"])
                # print("Sending email to " + user_email)
                # sendActivationMail(db, user_id, user_email, pin )
                msg = str_loc("activation")
            else:
                if dev["user_id"] != user_id:
                    # invalid user! disable device token
                    db.setDeviceStatus(255, device_token = device_token)
                    # cmd = '{"c":"STS","u":"' + str(user_id) + '"}'
                    # db.queuePushRequest( device_token, production, custom = cmd, badge = 0, content = True )
                    return {
                        'status'  : 403,
                        'message' : str_loc("error403_1")
                    }

            httpstatus = 208 if status == 1 else 205
            if httpstatus == 205:
                msg = str_loc("error205_1")
            return {
                'device_info' : {
                    'device_token'  : device_token,
                    'user_id'       : user_id,
                    'status'        : status
                },
                'message'       : msg,
                'status'        : httpstatus
            }

        # delete old device
        success = False
        if dev is not None: # and (device_token != old_token or dev['production'] != production):
            if len(old_token) < 1:
                old_token = device_token
            success = db.updateDeviceToken(old_token, device_token, production)
        else:
            if _config['user_attrib'] is True:
                attributes = db.userAttributesAndStats(user_id)
                if attributes is None:
                    db.createUserAttributes(user_id)
                    attributes = db.userAttributesAndStats(user_id)
                if attributes is None:
                    return {
                        'status'  : 400,
                        'message' : str_loc("error400_1")
                    }

                if (attributes['attributes'] & 0x40) == 0:
                    # check if device limit is exceeded
                    devices = db.listDevices(user_id)
                    if len(devices) >= attributes['limit_devices']:
                        return {
                            'status'  : 429,
                            'message' : str_loc("error429_1")
                        }

            status = 1 if _config['dev_confirm'] is False else 0
            pin = pin_gen(6)
            success = db.addDevice(device_token, user_id, name, device_os, production=production, status=status, pin=pin)
            if status == 0:
                # send activation email
                print("Sending email to " + user_email)
                sendActivationMail(db, user_id, user_email, pin)

        if success is True:
            dev = db.getDevice(device_token = device_token)
            if dev is not None:
                status = int(dev['status'])
                if status == 255:
                    # device is disabled
                    return {
                        'status'  : 403,
                        'message' : str_loc("error403_1")
                    }

                httpstatus = 200 if status == 1 else 205
                msg = str_loc("registered") if status == 1 else str_loc("activation")
                return {
                    'device_info' : {
                        'device_token'  : device_token,
                        'user_id'       : user_id,
                        'status'        : status
                    },
                    'message'       : msg,
                    'status'        : httpstatus
                }
    except:
        pass

    return {
        'status'  : 500,
        'message' : str_loc("error10907")
    }

def list_devices(db, params, json_data):
    ''' get list of devices '''
    try:
        user_id = params['user_id']
        devs = db.listDevices(user_id)
        return {
            'devices'   : devs,
            'user_id'   : user_id,
            'status'    : 200,
            'message'   : str_loc("success")
        }
    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }

def get_device_info(db, params, json_data):
    try:
        user_id = params['user_id']
        device_id = json_data['device_id']
        dev = db.getDevice(device_id = int(device_id))
        if dev is None:
            return {
                'status'  : 404,
                'message' : str_loc("error404_2")
            }
        return {
            'device'    : dev,
            'user_id'   : user_id,
            'status'    : 200,
            'message'   : str_loc("success")
        }
    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }


def delete_device(db, params, json_data):
    try:
        user_id = params['user_id']
        device_id = json_data['device_id']
        deleted = db.deleteDevice(device_id = int(device_id))
        if deleted > 0:
            return {
                'device_id'     : device_id,
                'user_id'       : user_id,
                'status'        : 200,
                'message'       : str_loc("success")
            }
        return {
            'status'  : 404,
            'message' : str_loc("error404_2")
        }
    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }

def set_device_info(db, params, json_data):
    try:
        user_id = params['user_id']
        status = json_data['status']
        device_id = json_data['device_id']
        name = json_data['name']
        res = False
        dev_id = int(device_id)
        if name != '':
            res = db.setDeviceName( name, dev_id )
        if status == 1 or status == 255:
            res = db.setDeviceStatus( status, device_id = dev_id)
            if res is True:
                ### device status may have changed
                dev = db.getDevice(device_id = dev_id)
                if dev is not None:
                    cmd = '{"c":"STS","u":"' + str(user_id) + '"}'
                    db.queuePushRequest(dev["token"], dev["production"], custom=cmd, badge=0, content=True)

        if res is True:
            return {
                'device_id'     : device_id,
                'user_id'       : user_id,
                'status'        : 200,
                'message'       : str_loc("success")
            }
    except Exception as e:
        print(e)
        pass

    return {
        'status'  : 404,
        'message' : str_loc("error404_2")
    }

""" May need to  have HTTP request for this """
def activate_device(db, params, json_data):

    try:
        user_id = params['user_id']
        token = json_data['token']
        pin = json_data['pin']

        user = db.findUser(user_id)
        if user is None:
            return {
                'status'  : 500,
                'message' : str_loc("error10921")
            }
        dev = db.getDevice(device_token=token)
        if dev is None:
            return {
                'status'  : 500,
                'message' : str_loc("error10922")
            }
        # check device user ID
        if dev['user_id'] != user_id:
            return {
                'status'  : 500,
                'message' : str_loc("error10921")
            }

        # activate Shaker Client (aka device)
        status = int(dev['status'])
        if status == 1:
            # already registered
            return {
                'status'  : 200,
                'message' : str_loc("registered")
            }
        if status == 255:
            return {
                'status'  : 403,
                'message' : str_loc("error403_1")
            }

        # check activation pin
        # Note: activation pin is 6 char string
        if dev['pin'] != pin:
            return {
                'status'  : 500,
                'message' : str_loc("error11002")
            }

        if db.setDeviceStatus(1, device_token = dev['token']):

            # notify device that it was activated
            cmd = '{"c":"STS","u":"' + str(user_id) + '"}'
            db.queuePushRequest(dev["token"], dev["production"], custom=cmd, badge=0, content=True)

            return {
                'status'  : 200,
                'message' : str_loc("registered")
            }
        return {
            'status'  : 500,
            'message' : str_loc("error10908")
        }
    except Exception as e:
        print("Device Activation Error")
        print(e)

    return {
        'status'  : 400,
        'message' : str_loc("error400_4")
    }
