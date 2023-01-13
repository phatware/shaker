#!/usr/bin/python

# Turn on debug mode.
# import cgitb
#cgitb.enable()

# Print necessary headers.
# print("Content-Type: text/html")

# Connect to the database.
import uuid
import hashlib
import json
import datetime
import time
from pin import pin_gen
import mysql.connector
from mysql.connector import errorcode

class Push:
    def __init__(self, p):
        self.id = p[0]
        self.device_id = p[1]
        self.token_id = p[2]
        self.alert = p[4]
        if len(p[5]) > 0:
            try:
                self.custom = json.loads(p[5])
            except:
                print("Bad Custom Json: " + p[5])
                self.custom = {}
        else:
            self.custom = {}
        self.badge = p[6]
        self.sound = p[7]
        self.sent = False if p[8] is None else True
        self.production = p[11]
        self.content = True if p[12] == 1 else False
        self.retry_count = p[13]

class Database:

    def __init__(self, mysql = None, host = None, user = None, password = None, database_name = None, port = 3306, ssl_ca = None):
        self.user = user
        self.password = password
        self.database_name = database_name
        self.host = host
        self.port = port
        self.ssl_ca = ssl_ca
        self.connected = False
        self.mysql = mysql
        if mysql is not None:
            self.ctx = mysql.connection
            self.cursor = self.ctx.cursor()
            self.connected = True

        # self.ctx = self.connectToDatabase()
        # self.cursor = self.ctx.cursor()

    def __del__(self):
        self.disconnect()

    def connectToDatabase(self):
        try:
            cnx = mysql.connector.connect(
                user = self.user,                           # "<login-name>",
                password = self.password,                   # "<password>",
                host = self.host,                           # "localhost",
                port = self.port,                           # 3306,
                database = self.database_name,              # "shaker",
                auth_plugin='mysql_native_password'
              #  ssl_ca = self.ssl_ca,                      # "MyServerCACert.pem"
              #  ssl_verify_cert = False
            )
        except mysql.connector.Error as err:
            if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
                print("Something is wrong with your user name or password")
            elif err.errno == errorcode.ER_BAD_DB_ERROR:
                print("Database does not exist")
            else:
                print(err)
            return None
        else:
            return cnx

    def connect(self):
        if self.connected is True:
            return
        self.ctx = self.connectToDatabase()
        if self.ctx is None:
            try:
                print("Creating database {}: ".format(self.database_name))
                db = mysql.connector.connect(
                        user = self.user,                           # "<login-name>",
                        password = self.password,                   # "quantumFoam68",
                        host = self.host,                           # "localhost",
                        port = self.port,                           # 3306
                        auth_plugin='mysql_native_password')
                cur = db.cursor()
                sql = 'CREATE DATABASE ' + self.database_name
                cur.execute(sql)
            except mysql.connector.Error as err:
                print(err)
            self.ctx = self.connectToDatabase()

        if self.ctx is None:
            return False
        self.cursor = self.ctx.cursor(buffered=True)
        self.connected = True
        return True

    def disconnect(self):
        if self.connected is True:
            try:
                self.cursor.close()
                self.ctx.close()
            except Exception as err:
                print(str(err))
            self.connected = False

    def now(self):
        dt = datetime.datetime.now()
        now = dt.strftime('%Y-%m-%d %H:%M:%S')
        return now

    # push notifications

    def execute_insert_sql(self, sql, param = None):
        try:
            self.cursor.execute(sql, param)
            self.ctx.commit()
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return 0

    def queuePushRequest(self, device_token, production, custom='', badge=0, message='', sound='', content=True, retry_count=1):
        device = self.getDevice(device_token = device_token)
        if device is None:
            return 0

        try:
            dt = datetime.datetime.now() + datetime.timedelta(minutes=10)
            expires = dt.strftime('%Y-%m-%d %H:%M:%S')
            cont = 1 if content is True else 0
            sql = """INSERT INTO push_queue ( device_token, `os`, `custom`, device_id, `alert`, badge, `sound`, `expires`, production, content, retry_count ) VALUES ( '%s','%s', '%s', %d, '%s', %d, '%s', '%s', %d, %d, %d )""" \
                  % (device_token, device['os'], custom, device['id'], message, badge, sound, expires, production, cont, retry_count )
            self.cursor.execute(sql)
            self.ctx.commit()
            return self.cursor.lastrowid
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return 0

    def pendingPushNotifications(self, production=0, os='macOS'):
        try:
            now = self.now()
            sql = """SELECT * FROM push_queue WHERE `retry_count` > 0 AND `os` = '%s' AND `production` = %d AND `expires` > '%s'""" % (os, production, now)
            self.cursor.execute(sql)
            push_list = []
            rows = self.cursor.fetchall()
            for p in rows:
                push = Push(p)
                push_list.append(push)
            return push_list
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return []

    def pushNotificationSent(self, queue_id, retry_count=0):
        try:
            now = self.now()
            sql = """UPDATE push_queue SET `sent` = '%s', retry_count = %d WHERE queue_id = %d""" % (now, retry_count, queue_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def deleteNotification(self, queue_id):
        try:
            sql = """DELETE FROM push_queue WHERE queue_id = '%s'""" % queue_id
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return -1 # , err.msg

    def deleteSentNotifications(self):
        try:
            sql = """DELETE FROM push_queue WHERE sent IS NOT NULL AND retry_count = 0"""
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return -1 # , err.msg

    def deleteExpiredNotifications(self):
        try:
            now = self.now()
            sql = """DELETE FROM push_queue WHERE `expires` < '%s'""" % now
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return -1 # , err.msg

    # sessions

    def createNewSession(self, user_id):
        try:
            session_uuid = uuid.uuid4().hex
            dt = datetime.datetime.now() + datetime.timedelta(days=90)
            expires = dt.strftime('%Y-%m-%d %H:%M:%S')
            sql = """INSERT INTO sessions ( user_id, session_uuid, `expires` ) VALUES ( %d, '%s', '%s' )""" \
                  % (user_id, session_uuid, expires)
            self.cursor.execute(sql)
            self.ctx.commit()
            return session_uuid
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return None # , err.msg

    def deleteSession(self, session_uuid):
        try:
            sql = """DELETE FROM sessions WHERE session_uuid = '%s'""" % session_uuid
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    def deleteSessions(self, user_id):
        try:
            sql = """DELETE FROM sessions WHERE user_id = %d""" % user_id
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    def hasSessionExpired(self, session_uuid):
        try:
            now = self.now()
            sql = """SELECT expires FROM sessions WHERE session_uuid = '%s' AND expires < '%s'""" % (session_uuid, now)
            self.cursor.execute(sql)
            expires = self.cursor.fetchone()
            if expires is not None:
                # delete expired session
                self.deleteSession(session_uuid)
                return True
            return False
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def deleteExpiredSessions(self):
        try:
            now = self.now()
            sql = """DELETE FROM sessions WHERE `expires` < '%s'""" % now
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return -1 # , err.msg

    def userWithSessionUUID(self, session_uuid):
        try:
            sql = """SELECT user_id FROM sessions WHERE session_uuid = '%s'""" % session_uuid
            self.cursor.execute(sql)
            user_id = self.cursor.fetchone()
            if user_id is not None:
                return user_id[0]
            return 0
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return 0 # , err.msg

    # Add/Delete CLIENT

    def addClient(self, name, bundle, os, version = 1):
        try:
            sql = """SELECT client_uuid FROM clients WHERE `name` = '%s'""" % (name)
            self.cursor.execute(sql)
            client = self.cursor.fetchone()
            if client is not None:
                return client[0], ''
            client_uuid = bundle + '_' + uuid.uuid4().hex
            client_secret = uuid.uuid4().hex + uuid.uuid4().hex
            secret_sha = hashlib.sha1()
            key = client_uuid + client_secret
            secret_sha.update(key.encode('utf-8'))
            sql = """INSERT INTO clients ( `name`, client_uuid, `secret`, os, `version` ) VALUES ( %s, %s, %s, %s, %s )"""
            self.cursor.execute(sql, (name, client_uuid, secret_sha.hexdigest(), os, str(version)))
            self.ctx.commit()
            return (client_uuid, client_secret)
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return (None, None)

    def deleteClient(self, name):
        try:
            sql = """DELETE FROM clients WHERE `name` = '%s'""" % (name)
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    def listClients(self):
        clients = []
        try:
            sql = """SELECT * FROM clients"""
            self.cursor.execute(sql)
            rows = self.cursor.fetchall()
            for client in rows:
                cln = {
                    "secret"    : client[1],
                    "uuid"      : client[2],
                    "name"      : client[4],
                    "os"        : client[5]
                }
                clients.append(cln)
            return clients
        except Exception as err:
            print(str(err))
            return clients

    def verifyClient(self, client_uuid, client_secret=None):
        try:
            sql = """SELECT `secret` FROM clients WHERE `client_uuid` = '%s'""" % (client_uuid)
            self.cursor.execute(sql)
            client = self.cursor.fetchone()
            if client is not None:
                if client_secret is None:
                    return True
                secret_sha = hashlib.sha1()
                key = client_uuid + client_secret
                secret_sha.update(key.encode('utf-8'))
                if secret_sha.hexdigest() == client[0]:
                    return True
            return False
        except Exception as err:
            print(str(err))
            return False # , err.msg

    # LOCATION

    def findLocation(self, longi, lati):
        try:
            sql = """SELECT location_id FROM locations WHERE longi = %s AND lati = %s""" % (longi, lati)
            self.cursor.execute(sql)
            location = self.cursor.fetchone()
            if location is not None:
                return location[0]
            return 0
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    def addLocation(self, longi, lati, address = ""):
        try:
            sql = """INSERT INTO locations ( longi, lati, `address` ) VALUES ( %s, %s, %s )"""
            # ; SELECT LAST_INSERT_ID();
            self.cursor.execute(sql, (longi, lati, address))
            self.ctx.commit()
            return self.cursor.lastrowid
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return 0

    # User attributes

    def createUserAttributes(self, user_id, attrib=0xf, limit_teleportations=10, limit_devices=5, limit_chats=100):
        try:
            sql = """INSERT INTO user_attrib ( user_id, attributes, limit_teleportations, limit_devices, limit_chats ) VALUES ( %d, %d, %d, %d, %d )""" \
                    % (user_id, attrib, limit_teleportations, limit_devices, limit_chats)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def userAttributesAndStats(self, user_id):
        try:
            sql = """SELECT `sent`, `received`, chats_in, chats_out, limit_teleportations, limit_devices, limit_chats, attributes, created, modified, expires FROM user_attrib WHERE user_id = %d""" % user_id
            self.cursor.execute(sql)
            attrib = self.cursor.fetchone()
            if attrib is not None:
                user_attrib = {
                    'sent_teleportations'       : attrib[0],
                    'received_teleportations'   : attrib[1],
                    'chats_in'                  : attrib[2],
                    'chats_out'                 : attrib[3],
                    'limit_teleportations'      : attrib[4],
                    'limit_devices'             : attrib[5],
                    'limit_chats'               : attrib[6],
                    'attributes'                : attrib[7],
                    'created'                   : time.mktime(attrib[8].timetuple()),
                    'modified'                  : time.mktime(attrib[9].timetuple()),
                    'expires'                   : time.mktime(attrib[10].timetuple())
                }
                return user_attrib
            return None # , 'User attributes not found'
        except Exception as err:
            print(str(err))
            return None # , err.msg

    def userAttributes(self, user_id):
        try:
            sql = """SELECT attributes FROM user_attrib WHERE user_id = %d""" % user_id
            self.cursor.execute(sql)
            attrib = self.cursor.fetchone()
            if attrib is not None:
                return attrib[0]
            return 0 # , 'User attributes not found'
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    def updateUserLimits(self, user_id, attrib=0, limit_teleportations=0, limit_devices=0, limit_chats=0, expires=0):
        attrib_stats = self.userAttributesAndStats(user_id)
        if attrib_stats is None:
            self.createUserAttributes(user_id)
            if attrib == 0:
                attrib = 0xf
            if limit_teleportations == 0:
                limit_teleportations = 10
            if limit_devices == 0:
                limit_devices = 5
            if limit_chats == 0:
                limit_chats = 100
        else:
            if attrib == 0:
                attrib = attrib_stats['attributes']
            limit_teleportations += attrib_stats['limit_teleportations']
            limit_devices += attrib_stats['limit_devices']
            limit_chats += attrib_stats['limit_chats']
        # Update the database
        try:
            dt = datetime.datetime.now() #  + datetime.timedelta(hours=12)
            modified = dt.strftime('%Y-%m-%d %H:%M:%S')
            dt = datetime.datetime.now() + datetime.timedelta(days=expires)
            expdate = dt.strftime('%Y-%m-%d %H:%M:%S')
            sql = """UPDATE user_attrib SET attributes = %d, limit_teleportations = %d, limit_devices = %d, limit_chats = %d, `modified`='%s', `expires`='%s' WHERE user_id = %d""" \
                    % (attrib, limit_teleportations, limit_devices, limit_chats, modified, expdate, user_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def updateUserStats(self, user_id, sent=0, received=0, chats_in=0, chats_out=0):
        attrib_stats = self.userAttributesAndStats(user_id)

        if attrib_stats is None:
            self.createUserAttributes(user_id)
        else:
            sent += attrib_stats['sent_teleportations']
            received += attrib_stats['received_teleportations']
            chats_in += attrib_stats['chats_in']
            chats_out += attrib_stats['chats_out']

        try:
            dt = datetime.datetime.now() + datetime.timedelta(hours=12)
            modified = dt.strftime('%Y-%m-%d %H:%M:%S')
            sql = """UPDATE user_attrib SET `sent` = %d, `received` = %d, chats_in = %d, chats_out = %d, `modified`='%s' WHERE user_id = %d""" \
                    % (sent, received, chats_in, chats_out, modified, user_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def deleteUserAttrib(self, user_id):
        try:
            sql = """DELETE FROM user_attrib WHERE user_id = %d""" % (user_id)
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            # delete all user's attributes
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    # Password reset

    def requestPinWithEmail(self, email_id):
        usr = self.findUserByEmailId(email_id)
        if usr == None:
            return None
        return self.requestPin(usr[0])

    def requestPin(self, user_id):
        try:
            pin = pin_gen(8)
            sql = """INSERT INTO user_ext ( user_id, pin ) VALUES ( %d, '%s' )""" % (user_id, pin)
            self.cursor.execute(sql)
            self.ctx.commit()
            return pin
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return None

    def findPin(self, user_id):
        try:
            sql = """SELECT pin, `date` FROM user_ext WHERE user_id = %d""" % user_id
            self.cursor.execute(sql)
            ext = self.cursor.fetchone()
            if ext is not None:
                return { 'pin' : ext[0], 'date' : ext[1] }
            return None # , 'User not found'
        except Exception as err:
            print(str(err))
            return None # , err.msg

    def deletePin(self, user_id):
        try:
            sql = """DELETE FROM user_ext WHERE user_id = %d""" % user_id
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            # delete all user's sessions
            if deleted_row_count > 0:
                self.deleteSessions(user_id)
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    # Add/manage users

    def findUserByName(self, name):
        try:
            sql = """SELECT * FROM users WHERE name = %s"""
            self.cursor.execute(sql, (name))
            user = self.cursor.fetchone()
            if user is None:
                return None
            return user # , 'User not found'
        except Exception as err:
            print(str(err))
            return None # , err.msg

    def findUser(self, user_id):
        try:
            sql = """SELECT * FROM users WHERE user_id = %d""" % int(user_id)
            self.cursor.execute(sql)
            user = self.cursor.fetchone()
            if user is None:
                return None
            return user # , 'User not found'
        except Exception as err:
            print(str(err))
            return None # , err.msg

    def findUserByEmailId(self, email_id):
        try:
            sql = """SELECT * FROM users WHERE `login_id` = '%s'""" % email_id
            self.cursor.execute(sql)
            user = self.cursor.fetchone()
            if user is None:
                return None
            return user # , 'User not found'
        except Exception as err:
            print(str(err))
            return None # , err.msg

    def setNewKey(self, user_id, key):
        try:
            sql = """UPDATE users SET `key` = %s WHERE user_id = %d""" % (key, user_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def addUser(self, name, email_id, key, status=0, longi=0.0, lati=0.0, address="", picture=""):
        try:
            user = self.findUserByEmailId(email_id)
            if user is None:
                # if user != name:
                #    user = self.findUserByName(name)
                # if user is None:
                location_id = self.findLocation(longi, lati)
                if location_id == 0:
                    location_id = self.addLocation(longi, lati, address)
                sql = """INSERT INTO users ( `name`, `login_id`, `key`, `status`, location_id, picture ) VALUES ( %s, %s, %s, %s, %s, %s )"""
                self.cursor.execute(sql, (name, email_id, key, str(status), str(location_id), picture))
                self.ctx.commit()
                user = self.findUserByEmailId(email_id)
                if user is not None:
                    self.updateUserStats(user[0])
            return user
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return None # , err.msg

    def deleteUser(self, user_id):
        try:
            sql = """DELETE FROM users WHERE user_id = %d""" % user_id
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            # delete all user's sessions
            if deleted_row_count > 0:
                self.deleteSessions(user_id)
                self.deleteUserAttrib(user_id)
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    def setUserStatus(self, user_id, status):
        try:
            sql = """UPDATE users SET `status` = %d WHERE user_id = %d""" % (status, user_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    # add/delete DEVICES

    def addDevice(self, device_token, user_id, name, os, production = 0, status = 0, pin="", version = 1):
        try:
            sql = """INSERT INTO devices ( device_token, user_id, `name`, os, `status`, `version`, production, `pin` ) VALUES ( %s, %s, %s, %s, %s, %s, %s, %s)"""
            self.cursor.execute(sql, (device_token, str(user_id), name, os, str(status), str(version), str(production), pin))
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def setDeviceStatus(self, status, device_token=None, device_id=0):
        try:
            if device_token is not None:
                sql = """UPDATE devices SET `status` = %d WHERE device_token = '%s'""" % (status, device_token)
            elif device_id > 0:
                sql = """UPDATE devices SET `status` = %d WHERE device_id = %d"""  % (status, device_id)
            else:
                return 0
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def setDeviceName(self, name, device_id):
        try:
            sql = """UPDATE devices SET `name`=%s WHERE device_id=%s"""
            self.cursor.execute(sql, (name, str(device_id)))
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def setDeviceActivationPin(self, pin, device_id):
        try:
            sql = """UPDATE devices SET `pin`=%s WHERE device_id=%s"""
            self.cursor.execute(sql, (pin, str(device_id)))
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def updateDeviceToken(self, old_token, new_token, production):
        try:
            sql = """UPDATE devices SET `device_token` = '%s', production = %d WHERE device_token = '%s'""" % (new_token, production, old_token)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def deleteDevice(self, device_token=None, device_id=0):
        try:
            if device_token is not None:
                sql = """DELETE FROM devices WHERE device_token = '%s'""" % device_token
            elif device_id > 0:
                sql = """DELETE FROM devices WHERE device_id = %d""" % device_id
            else:
                return 0
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err_msg

    def deleteUserDevices(self, user_id):
        try:
            sql = """DELETE FROM devices WHERE user_id = %d""" % user_id
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            # delete all user's sessions
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    def listDevices(self, user_id):
        try:
            # note: do not return devices that have not been activated yet
            devices = []
            sql = """SELECT `device_token`, `name`, `added`, `status`, `os`, `device_id`, `version`, `production` FROM devices WHERE `status` > 0 AND user_id = %d""" % (user_id)
            self.cursor.execute(sql)
            rows = self.cursor.fetchall()
            for device in rows:
                device_info = {
                    'token'   : device[0],  'name'       : device[1],
                    'added'   : time.mktime(device[2].timetuple()),
                    'status'  : device[3],  'os'         : device[4],
                    'user_id' : user_id,    'version'    : device[6],
                    'id'      : device[5],  'production' : device[7]
                }
                devices.append(device_info)
            return devices
        except Exception as err:
            print(str(err))
            return []

    def getDevice(self, device_token=None, device_id=0):
        try:
            if device_token is not None:
                sql = """SELECT user_id, `name`, `added`, `status`, `os`, device_id, `version`, device_token, production, `pin` FROM devices WHERE device_token = '%s'""" % (device_token)
            elif device_id > 0:
                sql = """SELECT user_id, `name`, `added`, `status`, `os`, device_id, `version`, device_token, production, `pin` FROM devices WHERE device_id = %d""" % (device_id)
            else:
                return None
            self.cursor.execute(sql)
            device = self.cursor.fetchone()
            if device is not None:
                device_info = {
                    'user_id'    : device[0],   'name'      : device[1],
                    'added'      : time.mktime(device[2].timetuple()),
                    'os'         : device[4],   'id'        : device[5],
                    'token'      : device[7],   'version'   : device[6],
                    'production' : device[8],   'status'    : device[3],
                    'pin'        : device[9]
                }
                return device_info
            return None

        except Exception as err:
            print(str(err))
            return None

# requests

    def createRequest(self, from_user, to_user, device_token, request_type=0):
        try:
            dt = datetime.datetime.now() + datetime.timedelta(hours=12)
            expires = dt.strftime('%Y-%m-%d %H:%M:%S')
            sql = """INSERT INTO active_requests ( from_user_id, to_user_id, from_token, `expires`, `type` ) VALUES ( %d, %d, '%s', '%s', %d)""" \
                  % (from_user, to_user, device_token, expires, request_type)
            self.cursor.execute(sql)
            self.ctx.commit()
            return self.cursor.lastrowid
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return -1

    def deleteExpiredRequests(self):
        try:
            now = self.now()
            sql = """DELETE FROM active_requests WHERE `expires` < '%s'""" % now
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return -1 # , err.msg

    def deleteRequest(self, request_id):
        try:
            sql = """DELETE FROM active_requests WHERE request_id = %d""" % (request_id)
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return -1 # , err.msg

    def activeRequestsForUser(self, user_id):
        try:
            now = self.now()
            requests = []
            sql = """SELECT from_user_id, request_id, `status`, `type`, from_token FROM active_requests WHERE to_user_id = %d AND `expires` > '%s'""" % (user_id, now)
            self.cursor.execute(sql)
            rows = self.cursor.fetchall()
            for req in rows:
                usr = self.findUser(req[0])
                request = {
                    "from_user_id"  : req[0],
                    "from_name"     : usr[1],
                    "to_user_id"    : user_id,
                    "request_id"    : req[1],
                    "status"        : req[2],
                    "type"          : req[3],
                    "device_token"  : req[4]
                }
                requests.append(request)
            return requests
        except Exception as err:
            print(str(err))
            return [] # , err.msg

    def findRequest(self, request_id):
        try:
            now = self.now()
            sql = """SELECT from_user_id, to_user_id, from_token, to_token, `status`, `type` FROM active_requests WHERE request_id = %d AND `expires` > '%s'""" % (request_id, now)
            self.cursor.execute(sql)
            req = self.cursor.fetchone()
            if req is None:
                return None
            return req
        except Exception as err:
            print(str(err))
            return None # , err.msg

    def updateRequestToken(self, request_id, to_token):
        try:
            sql = """UPDATE active_requests SET `to_token` = '%s' WHERE request_id = %d""" % (to_token, request_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            return False # , err.msg

    def updateRequestStatus(self, request_id, new_status):
        try:
            sql = """UPDATE active_requests SET `status` = %d WHERE request_id = %d""" % (new_status, request_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            return False # , err.msg

# upgrade codes

    def addUpgradeCode(self, upgrade_code, type, asset, user_id):
        try:
            sql = """INSERT INTO upgrades ( upgrade_code, `type`, asset, user_id ) VALUES ( '%s', %d, %d, %d )""" \
                  % (upgrade_code, type, asset, user_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def userForUpgradeCode(self, upgrade_code):
        try:
            sql = """SELECT user_id, `type`, asset FROM upgrades WHERE upgrade_code = '%s'""" % (upgrade_code)
            self.cursor.execute(sql)
            upgrade = self.cursor.fetchone()
            if upgrade is None:
                return None
            return upgrade
        except Exception as err:
            print(str(err))
            return None # , err.msg

# peripherals

    def addPeripheral(self, serial_number, user_id, name, device_type, longi=0.0, lati=0.0, address="", version=1, status=1):
        try:
            location_id = self.findLocation( longi, lati )
            if location_id == 0:
                location_id = self.addLocation(longi, lati, address)
            sql = """INSERT INTO peripherals ( serial_number, user_id, `name`, `version`, `status`, `type`, location_id ) VALUES ( '%s', %d, '%s', %d, %d, %d, %d )""" \
                  % (serial_number, user_id, name, version, status, device_type, location_id)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def setPeripheralStatus(self, serial_number, status):
        try:
            sql = """UPDATE peripherals SET `status` = %d WHERE serial_number = '%s'""" % (status, serial_number)
            self.cursor.execute(sql)
            self.ctx.commit()
            return True
        except Exception as err:
            print(str(err))
            self.ctx.rollback()
            return False

    def deletePeripheral(self, peripheral_id):
        try:
            sql = """DELETE FROM peripherals WHERE peripheral_id = %d""" % peripheral_id
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            # delete all user's sessions
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err_msg

    def deletePeripheralWithSN(self, serial_number):
        try:
            sql = """DELETE FROM peripherals WHERE serial_number = '%s'""" % serial_number
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            # delete all user's sessions
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err_msg

    def deleteUserPeripherals(self, user_id):
        try:
            sql = """DELETE FROM peripherals WHERE user_id = %d""" % user_id
            self.cursor.execute(sql)
            deleted_row_count = self.cursor.rowcount
            self.ctx.commit()
            # delete all user's sessions
            return deleted_row_count
        except Exception as err:
            print(str(err))
            return 0 # , err.msg

    def listPeripherals(self, user_id):
        peripherals = []
        try:
            # sql = """SELECT p.serial_number, p.name, p.added, p.status, p.version, p.peripheral_id, l.longi, l.lati FROM peripherals p JOIN locations l ON p.location_id = l.location_id WHERE p.user_id = %d""" % (user_id)
            # sql = """SELECT serial_number, name, added, status, version, peripheral_id FROM peripherals WHERE user_id = %d""" % (user_id)
            sql = """SELECT peripherals.serial_number, peripherals.name, peripherals.added, peripherals.status, peripherals.version, peripherals.peripheral_id, peripherals.type, locations.longi, locations.lati FROM peripherals, locations WHERE peripherals.location_id = locations.location_id AND peripherals.user_id = %d""" % (user_id)
            self.cursor.execute(sql)
            rows = self.cursor.fetchall()
            for device in rows:
                peripheral_info = {
                    'sn'         : device[0],       'name'      : device[1],
                    'added'      : str(device[2]),  'status'    : device[3],
                    'version'    : device[4],       'id'        : device[5],
                    'type'       : device[6],       'user_id'   : user_id,
                    'longi'      : device[7],       'lati'      : device[8]
                }
                peripherals.append(peripheral_info)
            return peripherals
        except Exception as err:
            print(str(err))
            return peripherals

    def getPeripheral(self, peripheral_id):
        try:
            sql = """SELECT peripherals.serial_number, peripherals.name, peripherals.added, peripherals.status, peripherals.version, peripherals.type, locations.longi, locations.lati, peripherals.user_id FROM peripherals, locations WHERE peripherals.location_id = locations.location_id AND peripherals.peripheral_id = %d""" % (peripheral_id)
            self.cursor.execute(sql)
            device = self.cursor.fetchone()
            if device is not None:
                peripheral_info = {
                    'sn'         : device[0],       'name'      : device[1],
                    'added'      : str(device[2]),  'status'    : device[3],
                    'version'    : device[4],       'id'        : peripheral_id,
                    'type'       : device[5],       'user_id'   : device[8],
                    'longi'      : device[6],       'lati'      : device[7]
                }
                return peripheral_info
            return None
        except Exception as err:
            print(str(err))
            return None

    def getPeripheralBySN(self, serial_number):
        try:
            sql = """SELECT peripherals.peripheral_id, peripherals.name, peripherals.added, peripherals.status, peripherals.version, peripherals.type, locations.longi, locations.lati, peripherals.user_id FROM peripherals, locations WHERE peripherals.location_id = locations.location_id AND peripherals.serial_number = '%s'""" % (serial_number)
            self.cursor.execute(sql)
            device = self.cursor.fetchone()
            if device is not None:
                peripheral_info = {
                    'sn'         : serial_number,   'name'      : device[1],
                    'added'      : str(device[2]),  'status'    : device[3],
                    'version'    : device[4],       'id'        : device[0],
                    'type'       : device[5],       'user_id'   : device[8],
                    'longi'      : device[6],       'lati'      : device[7]
                }
                return peripheral_info
            return None
        except Exception as err:
            print(str(err))
            return None
