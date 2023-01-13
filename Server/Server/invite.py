import json

from database import Database
from api_setup import _config
from email_util import sendInvitationEmail
from strings import str_loc

def invite_new_user(db, params, json_data):
    try:
        user = db.findUser(params["user_id"])
        if user is not None:
            to_email = json_data['to_email']
            to_name = json_data['to_name']
            from_email = json_data['from_email']
            sendInvitationEmail(user[1], from_email, to_email, to_name)
            return {
                'message'       : str_loc("success"),
                'status'        : 200
            }
        return {
            'status'  : 500,
            'message' : str_loc("error10916")
        }

    except:
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }
