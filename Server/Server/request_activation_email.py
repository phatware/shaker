import json

from email_util import sendActivationMail
from database import Database
from strings import str_loc
from pin import pin_gen

def request_activation_email(db, params, json_data):
    try:
        device_token = json_data["device_token"]
        dev = db.getDevice(device_token = device_token)
        if dev is None:
            return {
                'status'  : 404,
                'message' : str_loc("error404_2")
            }
        
        # generate new activation pin
        pin = pin_gen(6)
        db.setDeviceActivationPin(pin, device_id=dev["id"])
        sendActivationMail(db, params["user_id"], json_data['email'], pin)

        return {
            'message'   : str_loc("success"),
            'status'    : 200
        }
    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }

