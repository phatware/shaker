import json
import hashlib
import uuid

from database import Database
from api_setup import _config
from strings import str_loc

# user (GET, DELETE)

def get_user_info(db, params, jason_data):
    usr = db.findUser(params["user_id"])
    if usr is None:
        return {
            'status'    : 200,
            'message' : str_loc("error400_2")
        }
    return {
        'user_id'   : usr[0],
        'name'      : usr[1],
        'picture'   : usr[9],
        'status'    : 200,
        'message'   : str_loc("success")
    }
