
import json
from database import Database
from strings import str_loc

def end_session(db, params, json_data):
    try:
        device_token = json_data['device_token']
        session_id = json_data['session_id']
        # delete device when we logout?
        if device_token != "": 
            db.deleteDevice(device_token=device_token)
        db.deleteSession(session_id)
        return {
            'message'   : str_loc("success"),
            'status'    : 200
        }
    except Exception as e:
        print(e)
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }
