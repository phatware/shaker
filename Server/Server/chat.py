import json
from database import Database
import time
from strings import str_loc
from api_setup import _config

def post_chat_request(db, params, json_data):
    # TODO: this is a template for future enhancements, currently unused
    from_user_id = params["user_id"]
    badge = json_data["badge"]
    sound = json_data["sound"]
    device_token = json_data['device_token']
    headers = json_data["header"]

    recipient_id = 0
    try:
        recipient_id = json_data['recipient_id']
    except:
        pass

    from_user = db.findUser(from_user_id)
    my_device = db.getDevice(device_token = device_token)
    if my_device is None:
        return {
            'status'  : 400,
            'message' : str_loc("error400_5")
        }

    status = int(my_device["status"])
    if status == 255:
        return {
            'status'  : 403,
            'message' : str_loc("error403_1")
        }
    elif status == 0:
        return {
            'status'  : 418,
            'message' : str_loc("activation")
        }
    if _config['user_attrib'] is True:
        # TODO: user attributes disabled
        attributes = db.userAttributesAndStats(from_user_id)
        if attributes is None:
            return {
                'status'  : 500,
                'message' : str_loc("error10919")
            }
        elif attributes['attributes'] & 0x8 == 0:
            return {
                'status'  : 400,
                'message' : str_loc("error400_6")
            }
        elif attributes['attributes'] & 0x20 == 0 and attributes['chats_out'] >= attributes['limit_chats']:
            return {
                'status'  : 413,
                'message' : str_loc("error413_1")
            }
        elif attributes['attributes'] & 0x20 != 0 and attributes['attributes'] & 0x100 != 0 and attributes['expires'] < time.time():
            return {
                'status'  : 414,
                'message' : str_loc("error414_1")
            }
        # TODO: check other attributes as needed

    to_token = None
    to_user_id = 0
    if recipient_id > 0:
        to_user_id = recipient_id
    else:
        old_request = int(json_data['old_request_id'])
        if old_request > 0:
            old_req = db.findRequest(old_request)
            if old_req is not None:
                to_token = old_req[3]
                to_user_id = old_req[1]
                # also delete old request
                db.deleteRequest(old_request)
        else:
            recipient = db.findUserByEmailId(json_data["recipient"])
            if recipient is not None :
                to_user_id = recipient[0]

    if to_user_id < 1 :
        # todo: send email to the user if not registered, if "recipient" is a valid email address
        return {
            'status'  : 410,
            'message' : str_loc("error410_1")
        }

    if _config['user_attrib'] is True:
        attrib = db.userAttributes(to_user_id)
        if (attrib & 1) == 0:
            return {
                'status'  : 411,
                'message' : str_loc("error411_1")
            }
        # TODO: check other attributes as needed

    # request_type 1 is Chat request
    req_id = db.createRequest(from_user_id, to_user_id, device_token, request_type=1)
    if req_id < 1:
        return {
            'status'  : 500,
            'message' : str_loc("error10901")
        }

    qids = []
    if to_token is not None:
        #resending
        # db.updateRequestToken(req_id, to_token)
        # retry
        to_dev = db.getDevice(device_token = to_token)
        if to_dev is not None:
            alert = ''
            if to_dev['os'] == 'iOS':
                # iOS may need alert message
                msg = str_loc( "retry_chat")
                alert = '{ "title" : "Shaker", "body" :"' +  msg + '","action-loc-key" : "Accept" }'
            # retry chat (CTR)
            cmd = '{"c":"CTR","n":"' + from_user[1] + '","i":"' + str(req_id) + '","u":"' + str(from_user_id) + '","t":"1"}'
            qid = db.queuePushRequest(to_token, to_dev["production"], message = alert, custom=cmd, badge=0, content=True)
            if qid < 0:
                return {
                    'status'  : 500,
                    'message' : str_loc("error10903")
                }
            qids.append(qid)
        else:
            return {
                'status'  : 500,
                'message' : str_loc("error10903")
            }

    else:
        # request chat (CHT)
        cmd = '{"c":"CHT","n":"' + from_user[1] + '","i":"' + str(req_id) + '","u":"' + str(from_user_id) + '","t":"1"}'
        msg = str_loc("request_chat") + from_user[1] + "."
        alert = '{ "title" : "Shaker", "body" :"' +  msg + '","action-loc-key" : "Accept" }'

        devices = db.listDevices(to_user_id)
        for dev in devices:
            # TODO: create remote notification message and send to recipient
            if device_token == dev['token']:
                continue
            if int(dev['status']==0):
                # device not activated yet
                continue
            if int(dev['status']==255):
                # device disabled
                continue
            # todo: test upload
            qid = db.queuePushRequest(dev['token'], dev['production'], custom=cmd, badge=badge, message=alert, sound=sound, content=True)
            if qid < 0:
                return {
                    'status'  : 500,
                    'message' : str_loc("error10904")
                }
            qids.append(qid)

    if len(qids) < 1:
        return {
            'status'  : 404,
            'message' : str_loc("error10902")
        }
    return {
        'message'       : str_loc("success"),
        'status'        : 200,
        'queue_ids'     : qids,
        'recipient_id'  : to_user_id,
        'request_id'    : req_id
    }
