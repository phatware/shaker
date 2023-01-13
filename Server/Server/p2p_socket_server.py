#!/usr/bin/python

import signal
import ssl
import json
import uuid
from SimpleWebSocketServer import WebSocket, SimpleWebSocketServer, SimpleSSLWebSocketServer
from optparse import OptionParser
import struct
import sys
from verify import verifyClient, verifyClientAndSession, verify_session, verify_request
from random_data import randomData

from api_setup import _config
from strings import str_loc
from database import Database

from devices import register_device, list_devices, get_device_info, delete_device, set_device_info, activate_device
from end_session import end_session
from new_session import login_with_google, login_with_apple

from requests import get_pending_requests, reject_request, delete_request, upload_request
from user import get_user_info
from request_activation_email import request_activation_email
from notify import send_push_notification
from invite import invite_new_user


clients = []

# unpacker = struct.Struct('I I I I I')
rd = randomData()
db = Database(
    host = _config['db_url'],
    user = _config['db_login'],
    password = _config['db_pass'],
    database_name = _config['db_name'],
    ssl_ca = _config['db_cert']
    )

class P2PSocket(WebSocket):

    def process_login_request(self, db, message_id, message):
        if message_id == "user_login_with_google" :
            return login_with_google(db, message)

        elif message_id == "user_login_with_apple" :
            return login_with_apple(db, message)

        elif message_id == "server_version":
            return {
                'version'   : _config["server_version"],
                'message'   : "Shaker Server",
                'status'    : 200
            }
        else:
            return None

    def process_user_request(self, db, message_id, params, message):

        if message_id == "user_send_email_request" :
            return request_activation_email(db, params, message)

        if message_id == "user_register_device" :
            return register_device(db, params, message)

        if message_id == "user_end_session" :
            return end_session(db, params, message)

        if message_id == "user_verify_session" :
            return verify_session(db, params, message)

        if message_id == "user_verify_request" :
            return verify_request(db, params, message)

        if message_id == "user_get_active_requests" :
            return get_pending_requests(db, params, message)

        if message_id == "user_send_push_notification" :
            return send_push_notification(db, params, message)

        if message_id == "user_send_files" :
            return upload_request(db, params, message)

        if message_id == "user_delete_request" :
            return delete_request(db, params, message)

        if message_id == "user_reject_request" :
            return reject_request(db, params, message)

        if message_id == "user_send_invite" :
            return invite_new_user(db, params, message)

        if message_id == "user_list_devices" :
            return list_devices(db, params, message)

        if message_id == "user_get_device_info" :
            return get_device_info(db, params, message)

        if message_id == "user_delete_device" :
            return delete_device(db, params, message)

        if message_id == "user_set_device_info" :
            return set_device_info(db, params, message)

        if message_id == "user_activate_device" :
            return activate_device(db, params, message)

        #print("process_user_request: unknown command " + message_id)
        return None

    def handleMessage(self):

        try:
            js = self.data.decode('utf8').replace("'", '"')
            #print(js)
            message = json.loads(js)
            message_id = message["message_id"]
            headers = message["header"]
        except:
            print("bad message format: headers")
            self.close()
            return

        if not db.connect():
            print("Cant Open database")
            self.close()
            return

        # got message
        print("got message: " + message_id)
        try:
            # could be a login message, check it first
            response = self.process_login_request(db, message_id, message)
            if response is not None:
                response["message_id"] = message_id
                strResponse = json.dumps(response)
                print("process_login_request response: " +  strResponse)
                self.sendMessage( str(strResponse) )
                db.disconnect()
                return
        except Exception as e:
            print("error while processing process_login_request: ")
            print(e)
            self.close()
            db.disconnect()
            return

        try:
            session_id = message["session_id"]
        except:
            print("bad message format: session_id")
            self.close()
            db.disconnect()
            return

        # print( "Received message '" + message_id + "' for session " + session_id )
        # client_uuid = headers['Api-Client-Id']
        # client_secret = headers['Api-Client-Secret']
        params, status, hdr = verifyClientAndSession(db, headers, session_id)
        if status != 200:
            # response = {
            #     "message_id"      : "unauthorized_response",
            #     "status"     : 404,
            #     "status_message"  : "Unauthorized client or session ID."
            # }
            # strResponse = json.dumps(response)
            # self.sendMessage( str(strResponse) )
            print("message authentication failed")
            db.disconnect()
            self.close(status=400)
            return

        try:
            response = self.process_user_request(db, message_id, params, message)
            if response is not None:
                response["message_id"] = message_id
                strResponse = json.dumps(response)
                print("process_user_request response: " +  strResponse)
                self.sendMessage( str(strResponse) )
                db.disconnect()
                return

        except Exception as e:
            print("error while processing process_user_request: ")
            print(e)
            self.close()
            db.disconnect()
            return

        try:
            self.connection_id = int(message["request_id"])
        except:
            print("bad message format: request_id")
            self.close()
            db.disconnect()
            return

        if message_id == "teleporter_randomdata_request" :
            data = rd.getRND(10013, message["s"], message["h"], self.connection_id)
            self.sendMessage( data )

        elif message_id == "teleporter_connect_request":
            req = db.findRequest(self.connection_id)
            if req is None:
                response = {
                    "message_id"      : "teleporter_connect_response",
                    "status"     : 500,
                    "status_message"  : str_loc( "error11000")
                }
            else:
                from_device_token = req[2]
                from_user_id = req[0]
                device_token = message["device_token"]
                # from_user = db.findUser(from_user_id)
                is_chat = True if req[5]==1 else False
                db.updateRequestToken(self.connection_id, device_token)
                # queue UPLOAD push notification
                # TODO: production!!!
                dev_from = db.getDevice(device_token=from_device_token)
                if dev_from is None:
                    response = {
                        "message_id"      : "teleporter_connect_response",
                        "status"     : 500,
                        "status_message"  : str_loc( "error11001")
                    }
                else:
                    production = dev_from['production']
                    # upload  - UPL, chat - CTA
                    c = "CTA" if is_chat else "UPL"
                    cmd = '{"c":"' + c + '","i":"' + str(self.connection_id) + '","u":"' + str(req[1]) + '","t":"' + str(req[5]) + '"}'
                    alert = ''
                    content = False
                    if dev_from['os'] == 'iOS':
                        # iOS needs alert message
                        msg = str_loc( "chat_msg") if is_chat else str_loc( "upload_msg")
                        alert = '{ "title" : "Shaker", "body" :"' +  msg + '","action-loc-key" : "Accept" }'
                    else:
                        content = True
                    self.qid = db.queuePushRequest(from_device_token, production, message=alert, custom=cmd, badge=0, content=content)
                    if self.qid < 1:
                        response = {
                            "message_id"      : "teleporter_connect_response",
                            "status"     : 500,
                            "status_message"  : str_loc( "error11001")
                        }
                    else:
                        user_devices = db.listDevices(req[1])
                        for dev in user_devices:
                            if dev['status'] == 0 or dev['status'] == 255:
                                continue    # not active or disabled
                            token = dev["token"]
                            if token != device_token and token != from_device_token:
                                # queue CLEAR push notification
                                production = dev["production"]
                                cmd = '{"c":"CLR","i":"' + str(self.connection_id) + '","u":"' + str(from_user_id) + '"}'
                                db.queuePushRequest(token, production, custom=cmd, badge=0, content=True)

                        # mark request as accepted
                        db.updateRequestStatus(self.connection_id, 1)
                        response = {
                            "message_id"      : "teleporter_connect_response",
                            "status"     : 200,
                            "status_message"  : str_loc( "success"),
                            "queue_id"        : self.qid,
                            "request_id"      : self.connection_id
                        }

            strResponse = json.dumps(response)
            self.sendMessage( str(strResponse) )

        elif message_id == "teleporter_connection_ack" :
            for client in clients :
                if self != client and client.connection_id == self.connection_id:

                    if client.qid > 0:
                        # reset retry counter for this notification
                        print( "reseting push notification retry count to 0" )
                        db.pushNotificationSent(client.qid)

                    response = {
                        "message_id"      : "teleporter_connection_ack_response",
                        "status"          : 200,
                        "status_message"  : str_loc( "success"),
                        "queue_id"        : client.qid,
                        "request_id"      : self.connection_id
                    }
                    strResponse = json.dumps(response)
                    client.sendMessage( str(strResponse) )
                    break

        elif message_id == "teleporter_openchannel_request" :
            for client in clients :
                if self != client and client.connection_id == self.connection_id:
                    response = {
                        "message_id"      : "teleporter_openchannel_request",
                        "status"          : 200,
                        "status_message"  : str_loc( "success"),
                        "request_id"      : self.connection_id
                    }

                    strResponse = json.dumps(response)
                    client.sendMessage( str(strResponse) )
                    break

        elif message_id == "rtcdata_connection_request" :
            try:
                for client in clients :
                    if self != client and client.connection_id == self.connection_id:
                        response = {
                            "message_id"      : "rtcdata_connection_request_forward",
                            "request_id"      : self.connection_id,
                            "status"          : 200,
                            "status_message"  : str_loc( "success"),
                            "channel_id"      : message["channel_id"],
                            "sdp_description" : message["sdp_description"],
                            "sdp_type"        : message["sdp_type"]
                        }
                        strResponse = json.dumps(response)
                        client.sendMessage( str(strResponse) )
                        break
            except:
                print("rtcdata_connection_request error")

        elif message_id == "rtcdata_connection_response" :
            try:
                for client in clients :
                    if self != client and client.connection_id == self.connection_id:
                        response = {
                            "message_id"      : "rtcdata_connection_response_forward",
                            "request_id"      : self.connection_id,
                            "status"          : 200,
                            "status_message"  : str_loc( "success"),
                            "channel_id"      : message["channel_id"],
                            "sdp_description" : message["sdp_description"],
                            "sdp_type"        : message["sdp_type"]
                        }
                        strResponse = json.dumps(response)
                        client.sendMessage( str(strResponse) )
                        break
            except:
                print("rtcdata_connection_response error")

        elif message_id == "rtcdata_ice_candidate_request" :
            try:
                for client in clients :
                    if self != client and client.connection_id == self.connection_id:
                        response = {
                            "message_id"      : "rtcdata_ice_candidate_request_forward",
                            "request_id"      : self.connection_id,
                            "status"          : 200,
                            "status_message"  : str_loc( "success"),
                            "channel_id"      : message["channel_id"],
                            "sdp"             : message["sdp"],
                            "sdp_mid"         : message["sdp_mid"],
                            "sdp_index"       : message["sdp_index"]
                        }
                        strResponse = json.dumps(response)
                        client.sendMessage( str(strResponse) )
                        break

                        # if message["confirm"] is True:
                        #     response2 = {
                        #         "message_id"      : "rtcdata_ice_candidate_request_next",
                        #         "status"     : 200,
                        #         "status_message"  : str_loc( "success"),
                        #         "channel_id"      : message["channel_id"],
                        #         "request_id"      : self.connection_id
                        #     }
                        #     strResponse2 = json.dumps(response2)
                        #     self.sendMessage( str(strResponse2) )
            except:
                print("rtcdata_ice_candidate_request error")

        elif message_id == "rtcdata_ice_candidate_request_next" :
            for client in clients :
                if self != client and client.connection_id == self.connection_id:
                    response2 = {
                        "message_id"      : "rtcdata_ice_candidate_request_next",
                        "status"          : 200,
                        "status_message"  : str_loc( "success"),
                        "channel_id"      : message["channel_id"],
                        "request_id"      : self.connection_id
                    }
                    strResponse2 = json.dumps(response2)
                    self.sendMessage( str(strResponse2) )
                    break

        elif message_id == "teleporter_complete_request" :
            print("teleporter_complete_request " + str(self.connection_id))
            # ignore result here
            db.deleteRequest(self.connection_id)

        elif message_id == "rtcdata_status_report" :
            print("Status report received from client " + str(self.connection_id))
            status_code = message['status']
            user_id = int(params['user_id'])
            if status_code == 220:
                # file successfully uploaded
                db.updateUserStats(user_id, sent = 1)
            elif status_code == 221:
                # file successfully downloaded
                db.updateUserStats(user_id, received = 1)
            elif status_code == 231:
                # IN chat ready
                db.updateUserStats(user_id, chats_in = 1)
            elif status_code == 232:
                # OUT chat ready
                db.updateUserStats(user_id, chats_out = 1)
            elif status_code == 522:
                # ice gathering error, data channel cant be opened
                for client in clients :
                    if self != client and client.connection_id == self.connection_id:
                        response = {
                            "message_id"    : "rtcdata_status_forward",
                            "request_id"    : self.connection_id,
                            "status"        : status_code,
                            "message"       : message["status_message"],
                            "channel_id"    : message["channel_id"]
                        }
                        strResponse = json.dumps(response)
                        client.sendMessage( str(strResponse) )
                        break


        db.disconnect()

    def handleConnected(self):
        print (self.address, 'connected')
        self.connection_id = 0
        self.epoch = 0
        self.handler_id = 0
        self.size = 0
        self.checksum = 0
        self.qid = 0
        clients.append(self)

    def handleClose(self):
        self.connection_id = 0
        clients.remove(self)
        print (self.address, 'closed')

""" --- MAIN --- """

if __name__ == "__main__":

    # parser = OptionParser(usage="usage: %prog [options]", version="%prog 1.0")
    # parser.add_option("--host", default='', type='string', action="store", dest="host", help="hostname (localhost)")
    # parser.add_option("--port", default=8000, type='int', action="store", dest="port", help="port (8000)")
    # parser.add_option("--ssl", default=0, type='int', action="store", dest="ssl", help="ssl (1: on, 0: off (default))")
    # parser.add_option("--cert", default='./cert.pem', type='string', action="store", dest="cert", help="cert (./cert.pem)")
    # parser.add_option("--ver", default=ssl.PROTOCOL_TLSv1, type=int, action="store", dest="ver", help="ssl version")
    # (options, args) = parser.parse_args()

    cls = P2PSocket

    if _config['wssl'] is True:
        server = SimpleSSLWebSocketServer(_config['srv_host'], _config['srv_port'], cls, _config['srv_cert'], _config['srv_key'], version=ssl.PROTOCOL_TLSv1)
    else:
        server = SimpleWebSocketServer(_config['srv_host'], _config['srv_port'], cls)

    def close_sig_handler(signal, frame):
        server.close()
        sys.exit()

    print('Started WebSocket server on ' + str(_config['srv_port']) + ' port.')
    signal.signal(signal.SIGINT, close_sig_handler)

    server.serveforever()

