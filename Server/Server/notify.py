import json
from database import Database
from strings import str_loc

# notify (POST)
def send_push_notification(db, params, json_data):
    try:
        user_id = params['user_id']
        badge = int(json_data['badge'])
        message = json_data['message']
        custom = json_data['custom']
        token_id = json_data['device_token']
        sound = json_data['sound']

        devs = db.listDevices(user_id)
        qids = []
        for dev in devs:
            # print( "queueing message to device token: " + dev['token'])
            if token_id == dev['token']:
                continue
            if dev['status'] == 0 or dev['status'] == 255:
                continue

            alert = '{"title":"Shaker","body":"' +  message + '","action-loc-key":"Accept"}'
            qid = db.queuePushRequest(dev['token'], dev['production'], custom=custom, message=alert, badge=badge, sound=sound)
            if qid < 0:
                return {
                    'status'  : 500,
                    'message' : str_loc("error10915")
                }
            qids.append(qid)
        if qids.count < 1:
            return {
                'status'  : 404,
                'message' : str_loc("error404_1")
            }
        return {
            'message'       : str_loc("success"),
            'status'        : 200,
            'queue_ids'     : qids
        }

    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }


