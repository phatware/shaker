
import json
from database import Database
from api_setup import _config
from strings import str_loc

def verifyClient(db, headers):
    client_uuid = headers['Api-Client-Id']
    client_secret = headers['Api-Client-Secret']
    # print('Client ID : ' + client_uuid + ' Secret : ' + client_secret)
    res = db.verifyClient(client_uuid, client_secret)
    return res

def verifyClientAndSession(db, headers, session_uuid):
    if not verifyClient(db, headers):
        return {}, 401, {
            'X-Error-Description' : str_loc("error401_1")
        }
    # app_version = float(headers['Api-Client-Version'])
    # if app_version < _config['min_client_version']:
    #     return {}, 426, {
    #         'X-Error-Description' : str_loc("error426_1")
    #     }                                
    if db.hasSessionExpired(session_uuid):
        return {}, 440, {
            'X-Error-Description' : str_loc("error440_1")
        }
    user_id = db.userWithSessionUUID(session_uuid)
    if user_id == 0 or user_id is None or user_id != int(headers['Api-User-Id']):
        return {}, 406, {
            'X-Error-Description' : str_loc("error406_3")
        }
    return {'user_id' : user_id}, 200, {}

def verify_session(db, params, json_data):
    try:
        os = json_data['os']
        version = json_data['version']
        headers = json_data["header"]
        ver = "minversion_" + os
        min_version = _config[ver]
        if version < min_version:
            raise Exception("Client version is too old")
        device_token = json_data["device_token"]
        if device_token != "" :
            my_device = db.getDevice(device_token = device_token)
            if my_device is None:
                return {
                    'message'   : str_loc("error403_1"),
                    'status'    : 403
                }   
            status = int(my_device["status"])
            if status == 255:
                return {
                    'message'   : str_loc("error403_1"),
                    'status'    : 403
                }   
            if status == 0:
                return {
                    'message'   : str_loc("activation"),
                    'status'    : 418
                }
        return {
            'message'   : str_loc("success"),
            'status'    : 200
        }

    except Exception as e:
        print("verify_session")
        print(e)
        return {
            'message'       : str_loc("error426_1"),
            'status'        : 426
        }

def verify_request(db, params, json_data):
    try:
        request_id = json_data['request_id']
        req = db.findRequest(request_id)
        if req is None or req[4] != 0:
            return {
                'message'   : str_loc("error421_1"),
                'status'    : 421
            }
        return {
            'message'       : str_loc("success"),
            'status'        : 200,
            'request_type'  : req[5]
        }
    except:
        return {
            'message'       : str_loc("error421_1"),
            'status'        : 421
        }

