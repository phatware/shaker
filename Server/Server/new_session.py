
import json
import hashlib
import uuid

from database import Database
from oauth2client import client, crypt
from verify import verifyClient
from strings import str_loc

# login (POST)

def login_with_google(db, json_data):
    try:
        if not verifyClient(db, json_data['header']):
            return {
                'status'  : 401,
                'message' : str_loc("error401_1")
            }
        token = json_data['token']
        client_id = json_data['client']
        idinfo = client.verify_id_token(token, client_id)

        # Or, if multiple clients access the backend server:
        # idinfo = client.verify_id_token(token, None)
        # if idinfo['aud'] not in [CLIENT_ID_1, CLIENT_ID_2, CLIENT_ID_3]:
        #    raise crypt.AppIdentityError("Unrecognized client.")

        if idinfo['iss'] not in ['accounts.google.com', 'https://accounts.google.com']:
            raise crypt.AppIdentityError("Wrong issuer.")

        # If auth request is from a G Suite domain:
        #if idinfo['hd'] != GSUITE_DOMAIN_NAME:
        #    raise crypt.AppIdentityError("Wrong hosted domain.")

        email = idinfo['email']
        name = idinfo['name']
        picture = idinfo['picture']

        email_id = hashlib.sha256()
        email_id.update(email.lower().encode('utf-8'))
        eid = email_id.hexdigest()
        usr = db.findUserByEmailId(eid)
        if usr is None:
            key = hashlib.sha1()
            account_key = uuid.uuid4().hex + '_' + name
            key.update(account_key.encode('utf-8'))
            usr = db.addUser(name, eid, key.hexdigest(), status=1, picture=picture)
            if usr is None:
                return {
                    'status'  : 500,
                    'message' : str_loc("error10909")
                }

        session_uuid = db.createNewSession(usr[0])
        if session_uuid == '':
            return {
                'status'  : 500,
                'message' : str_loc("error10910")
            }
        return {
            'user_info' : {
                'user_id'   : usr[0],
                'name'      : name,
                'email'     : email
            },
            'session_id'    : session_uuid,
            'message'       : str_loc("success_login"),
            'status'        : 200
        }

    except crypt.AppIdentityError:
        # Invalid token
        return {
            'status'  : 406,
            'message' : str_loc("error406_1")
        }

    except Exception as e:
        print(e)
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }

def login_with_apple(db, json_data):
    try:
        if not verifyClient(db, json_data['header']):
            return {
                'status'  : 401,
                'message' : str_loc("error401_1")
            }
        token = json_data['token']
        # client_id = json_data['client']
        payload = jwt.decode(token, verify=False)
        token_data = json.loads(payload)

        if token_data['email_verified'] == False or len(token_data['email']) < 6:
            return {
                'status'  : 511,
                'message' : str_loc("error_email")
            }

        if token_data['is_private_email'] == True:
            return {
                'status'  : 539,
                'message' : str_loc("error_email_private")
            }

        email = token_data['email']
        picture = 'none'
        name = token_data['sub']

        email_id = hashlib.sha256()
        email_id.update(email.lower().encode('utf-8'))
        eid = email_id.hexdigest()
        usr = db.findUserByEmailId(eid)
        if usr is None:
            key = hashlib.sha1()
            account_key = uuid.uuid4().hex + '_' + name
            key.update(account_key.encode('utf-8'))
            usr = db.addUser(name, eid, key.hexdigest(), status=1, picture=picture)
            if usr is None:
                return {
                    'status'  : 500,
                    'message' : str_loc("error10909")
                }

        session_uuid = db.createNewSession(usr[0])
        if session_uuid == '':
            return {
                'status'  : 500,
                'message' : str_loc("error10912")
            }
        return {
            'user_info' : {
                'user_id'   : usr[0],
                'name'      : 'Shaker User',
                'email'     : email
            },
            'session_id'    : session_uuid,
            'message'       : str_loc("success_login"),
            'status'        : 200
        }

    except crypt.AppIdentityError:
        # Invalid token
        return {
            'status'  : 406,
            'message' : str_loc("error406_2")
        }

    except Exception as e:
        print(e)
        return {
            'status'  : 500,
            'message' : str_loc("error10907")
        }
