#!/usr/bin/python

import sched, time
from database import Database
from apns import *
from binascii import a2b_hex
import os
import time
from apns import APNs, Frame, Payload
from api_setup import _config
import sys
from database import Database

sandbox = True
global_index = 0

db = Database(
    host = _config['db_url'], 
    user = _config['db_login'], 
    password = _config['db_pass'], 
    database_name = _config['db_name'], 
    ssl_ca = _config['db_cert']
    )

def sendPendingMessages(sc, os):
    global global_index

    # print('sending macOS push notifications')
    if not db.connect():
        print("sendPendingMessages: Cant Open database")
        return

    if os == 'macOS':
        cert = _config["dev_cert_macos"] if sandbox else _config["prd_cert_macos"]
    else:
        cert = _config["dev_cert_ios"] if sandbox else _config["prd_cert_ios"]
    apns = APNs(use_sandbox=sandbox, cert_file=cert, key_file=cert)

    last_id = 0
    retry_count = 0
    global_index = global_index + 1
    try:
        # frame = Frame()
        # expiry = time.time() + 3600
        production = 0 if sandbox else 1
        push_list = db.pendingPushNotifications(production, os)
        cnt = len(push_list)
        identifier = 0
        if cnt > 0:
            print('Enumerating ' + str(cnt) + ' pending push message(s) for ' + os + '.')
            for push in push_list:
                last_id = push.id
                token_hex  = push.token_id
                retry_count = push.retry_count - 1
                # if notification sent 
                if push.sent is True and global_index%3 != 0:
                    continue
                if push.alert is not None and len(push.alert) > 1 and push.alert[0] == '{':
                    alert = json.loads(push.alert)
                else:
                    alert = push.alert
                # content = False if os == 'macOS' else push.content
                content = push.content
                payload    = Payload(
                    alert  = alert,
                    sound  = push.sound,
                    badge  = push.badge,
                    custom = push.custom,
                    content_available = content,
                    colapse_id = 0
                )
                res = apns.gateway_server.send_notification(token_hex, payload)
                # frame.add_item(push.token_id, payload, identifier, expiry, priority)
                if res > 0:
                    print('Sent notification: ' + str(push.id))
                    db.pushNotificationSent(push.id, retry_count)
                else:
                    print('Error sending notification: ' + str(push.id))
                identifier += 1
        # print('Closing')
    except Exception as e:
        print("sendPendingMessages: Unexpected error:", sys.exc_info()[0])
        print(e)
        if last_id > 0:
            print('Deleting notification: ' + str(last_id))
            db.pushNotificationSent(last_id, retry_count)
    # apns = null
    db.disconnect()
    sc.enter(5, 1, sendPendingMessages, (sc,os))

def feedbackService(sc, os):

    """ this function is called twice a day """
    if not db.connect():
        print("feedbackService: Cant Open database")
        return

    # delete all expired requests and notifications from the database 
    deleted_req = db.deleteExpiredRequests()
    deleted_not = db.deleteExpiredNotifications()
    selected_ses = db.deleteExpiredSessions()

    print('Deleted expired...\n    Requests: %d\n    Sessions: %d\n    Notifications: %d' % (deleted_req, selected_ses, deleted_not) )

    if os == 'macOS':
        cert = _config["dev_cert_macos"] if sandbox else _config["prd_cert_macos"]
    else:
        cert = _config["dev_cert_ios"] if sandbox else _config["prd_cert_ios"]
    apns = APNs(use_sandbox=sandbox, cert_file=cert, key_file=cert)

    try:
        feedback_server = apns.feedback_server
        print('Enumerating feedback services.')
        i = 0
        for (token_hex, fail_time) in feedback_server.items():
            if token_hex is not None and token_hex != "":
                i += db.deleteDevice(device_token = token_hex)
        print('Deleted failed tokens: ' + str(i))
    except:
        print("FeedbackService: Unexpected error:", sys.exc_info()[0])

    db.disconnect()
    if os == 'macOS':
        sc.enter(43243, 1, feedbackService, (sc,os))
    else:
        sc.enter(43234, 1, feedbackService, (sc,os))
  
if __name__ == '__main__':
    for arg in sys.argv[1:]:
        if arg == "--production":
            sandbox = False
        elif arg == "--development":
            sandbox = True
    print( "Running in " + ("DEVELOPER" if sandbox else "PRODUCTION") + " mode.")

    s = sched.scheduler(time.time, time.sleep)
    
    # feedbackService(s, 'macOS')

    # schedule push notifications check every 5-7 seconds 
    s.enter(7, 1, sendPendingMessages, (s,'iOS'))
    s.enter(5, 1, sendPendingMessages, (s,'macOS'))

    # schedule database cleanup every 12 hours 
    s.enter(43243, 1, feedbackService, (s,'iOS'))
    s.enter(43234, 1, feedbackService, (s,'macOS'))

    s.run()
