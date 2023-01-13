import json
from database import Database
from api_setup import _config
from strings import str_loc


def get_pending_requests(db, params, json_data):
    try:
        user_id = params['user_id']
        active_requests = db.activeRequestsForUser(user_id)
        if len(active_requests) < 1:
            # no active requests
            return {
                'user_id'       : user_id,
                'status'        : 204,
                'message'       : str_loc("success")
            }
        return {
            'user_id'       : user_id,
            'status'        : 200,
            'message'       : str_loc("success"),
            'requests'      : active_requests
        }
    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }


def reject_request(db, params, json_data):
    try:
        request_id = int(json_data["request_id"])
        req = db.findRequest(request_id)
        qid = 0
        status = 204
        if req is not None:
            status = 200
            from_device_token = req[2]
            from_user_id = req[0]
            device_token = json_data["device_token"]
            db.updateRequestToken(request_id, device_token)
            code = int(json_data["rejection_code"])
            # queue response notification
            if code == 10:
                # rejected
                cmd = '{"c":"REJ","i":"' + str(request_id) + '","u":"' + str(req[1]) + '","t":"' + str(req[5]) + '"}'
            elif code == 11:
                # busy
                cmd = '{"c":"BSY","i":"' + str(request_id) + '","u":"' + str(req[1]) + '","t":"' + str(req[5]) + '"}'
            else:
                # timeout
                cmd = '{"c":"TOT","i":"' + str(request_id) + '","u":"' + str(req[1]) + '","t":"' + str(req[5]) + '"}'

            dev_from = db.getDevice(device_token=from_device_token)
            if dev_from is not None:
                qid = db.queuePushRequest(from_device_token, dev_from["production"], custom=cmd, badge=0, sound='default', content=True)
                if qid > 0:
                    user_devices = db.listDevices(req[1])
                    for dev in user_devices:
                        if dev['status'] == 0 or dev['status'] == 255:
                            continue    # not activate or disabled
                        if dev["token"] != device_token and dev["token"] != from_device_token:
                            # queue CLEAR notification
                            cmd = '{"c":"CLR","i":"' + str(request_id) + '","u":"' + str(from_user_id) + '"}'
                            db.queuePushRequest(dev["token"], dev["production"], custom=cmd, badge=0, content=True)
            # delete this request
            db.deleteRequest(request_id)

        return {
            'message'       : str_loc("success"),
            'status'        : status,
            'queue_id'      : qid,
            'request_id'    : request_id
        }

    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }

def delete_request(db, params, json_data):
    try:
        user_id = params['user_id']
        req = db.findRequest(int(request_id))
        if req is not None:
            to_user_id = req[1]
            from_user_id = req[0]
            if from_user_id != user_id:
                return {
                    'status'  : 400,
                    'message' : str_loc("error10921")
                }

            user_devices = db.listDevices(to_user_id)
            for dev in user_devices:
                if dev['status'] == 0 or dev['status'] == 255:
                    continue    # not activate or disabled
                # queue CLEAR notification
                cmd = '{"c":"CLR","i":"' + str(request_id) + '","u":"' + str(from_user_id) + '"}'
                db.queuePushRequest(dev["token"], dev["production"], custom=cmd, badge=0, content=True)

        deleted = db.deleteRequest(int(request_id))
        return {
            'message'       : str_loc("success"),
            'status'        : 200,
            'deleted'       : deleted,
            'request_id'    : request_id
        }
    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }

def upload_request(db, params, json_data):
    try:
        # TODO:
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
        # TOD: add user attrib later
        # if _config['user_attrib'] is True:
        #     attributes = db.userAttributesAndStats(from_user_id)
        #     if attributes is None:
        #         return {
        #             'status'  : 500,
        #             'message' : str_loc("error10919")
        #         }
        #     elif attributes['attributes'] & 0x2 == 0:
        #         return {
        #             'status'  : 400,
        #             'message' : str_loc("error400_6")
        #         }
        #     elif attributes['attributes'] & 0x10 == 0 and attributes['sent_teleportations'] >= attributes['limit_teleportations']:
        #         return {
        #             'status'  : 413,
        #             'message' : str_loc("error413_1")
        #         }
        #     elif attributes['attributes'] & 0x10 != 0 and attributes['attributes'] & 0x100 != 0 and attributes['expires'] < time.time():
        #         return {
        #             'status'  : 414,
        #             'message' : str_loc("error414_1")
        #         }
            # TODO: check other attributes as needed

        to_token = None
        if recipient_id > 0:
            to_token = recipient_id
        else:
            to_user_id = 0
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

        # request_type 0 is File Upload request
        req_id = db.createRequest(from_user_id, to_user_id, device_token, request_type=0)
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
            print( "To device token: " + to_token)
            to_dev = db.getDevice(device_token = to_token)
            if to_dev is not None:
                alert = ''
                if to_dev['os'] == 'iOS':
                    # iOS may need alert message
                    msg = str_loc( "retry_msg")
                    alert = '{ "title" : "Shaker", "body" :"' +  msg + '","action-loc-key" : "Accept" }'
                cmd = '{"c":"RTY","n":"' + from_user[1] + '","i":"' + str(req_id) + '","u":"' + str(from_user_id) + '","t":"0"}'
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
            cmd = '{"c":"OPN","n":"' + from_user[1] + '","i":"' + str(req_id) + '","u":"' + str(from_user_id) + '","t":"0"}'
            msg = str_loc("request_msg") + from_user[1] + "."
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
                print( "To dev(token): " + dev['token'] )
                qid = db.queuePushRequest(dev['token'], dev['production'], custom=cmd, badge=badge, message=alert, sound=sound)
                if qid <= 0:
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

    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }
