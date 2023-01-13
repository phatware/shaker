
import json
from database import Database
from sqldb import getDatabase
from config import _config
from strings import str_loc

# attributes (GET)

# TODO: temporarily hardcode the upgrade codes, later will depend on user id, may be reported from merchant database
upgrade_codes = {
    "5d0ce6b27f0d4deeaf27135b9bfd7c1d" : { "t" : 1, "a" : 180 },        # add 180 days subscription 
    "7188de1593294613b8cc19d506643d0d" : { "t" : 2, "a" : 100 },        # add 100 teleports 
    "9f0b5044fcfa4688990765cb16deaed1" : { "t" : 1, "a" : 90 },         # add 90 days subscription 
    "16af54bbb04f455ab7649169a9057c7b" : { "t" : 1, "a" : 30 },         # add 30 days subscription 
    "11ce7e66b4f548fd92a8bc44d7f058fa" : { "t" : 2, "a" : 10 },         # add 10 teleports
    "897b12d550844c4884e4c1c1483d0865" : { "t" : 3, "a" : 1000 },       # add 1000 chats
    "4a925fc4fdfc45b6830c3fa8fdca7215" : { "t" : 4, "a" : 5 },          # add 5 devices
    "756c542bf9c84a57a3c6333f2345a79a" : { "t" : 5, "a" : 0 }           # set unlimited account
}

class attributes():

    def get(self, session_id):
        db = getDatabase()
        params, status, headers = verifyClientAndSession(db, request.headers, session_id)
        if status != 200:
            return params, status, headers
        user_id = params['user_id']
        attrib = db.userAttributesAndStats(user_id)
        if attrib is None:
            db.createUserAttributes(user_id)
            attrib = db.userAttributesAndStats(user_id)
        if attrib is None:
            return {}, 400, {
                'X-Error-Description' : str_loc("error400_1")
            }
        return attrib, 200

    def post(self, session_id):
        db = getDatabase()
        params, status, headers = verifyClientAndSession(db, request.headers, session_id)
        if status != 200:
            return params, status, headers
        user_id = params['user_id']
        json_data = request.get_json(force=True)
        
        # TODO: verify upgrade_code here
        upgrade_code = json_data['upgrade_code']

        # TODO: later check if the code is already in use
        # user_info = db.userForUpgradeCode(upgrade_code)
        # if user_info is not None:

        try:
            data = upgrade_codes[upgrade_code]
        except:
           return {}, 427, {
                'X-Error-Description' : str_loc("error427_1")
            }
            
        res = False
        type = data['t']
        asset = data['a'] 
        if type == 1:
            res = db.updateUserLimits(user_id, attrib = 0x13F, expires = asset)
        elif type == 2:
            res = db.updateUserLimits(user_id, attrib = 0x0F, limit_teleportations = asset)
        elif type == 3:
            res = db.updateUserLimits(user_id, attrib = 0x0F, limit_chats = asset)
        elif type == 4:
            res = db.updateUserLimits(user_id, attrib = 0x0F, limit_devices = asset)
        elif type == 5:
            res = db.updateUserLimits(user_id, attrib = 0x03F)
        if not res:
            return {}, 500, {
                'X-Error-Description' : str_loc("error10917")
            }
        db.addUpgradeCode(upgrade_code, type, asset, user_id)
        attrib = db.userAttributesAndStats(user_id)
        if attrib is None:
           return {}, 400, {
                'X-Error-Description' : str_loc("error400_1")
            }
        return attrib, 200
