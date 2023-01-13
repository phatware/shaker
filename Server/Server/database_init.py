from database import Database
from tables import Tables
import hashlib
from api_setup import _config
from import_drinks import ImportDrinks

if __name__ == '__main__':
    # test database API

    # test database API
    db = Database(
        host = _config['db_url'],
        user = _config['db_login'],
        password = _config['db_pass'],
        database_name = _config['db_name'],
        ssl_ca = _config['db_cert']
    )

    if not db.connect():
        print('Cant open database')
        quit()

    print('Database opened; creating tables')
    tables = Tables(db.cursor)

    tables.dropAllTables()
    #exit()
    #tables.dropTable('user_attrib')
    #tables.dropTable('push_queue')

    tables.createAllTables()

    key = hashlib.sha1()
    line = "stas.usa_stan"

    key.update(line.encode('utf-8'))
    email = "stan@phatware.com"

    email_id = hashlib.sha256()
    email_id.update(email.encode('utf-8'))

    # test user API
    user = db.addUser("stan", email_id.hexdigest(), key.hexdigest(),picture="http://www.google.com/pictures/user/12398492759823579238/image.jpg")
    user_id = user[0]
    print( "new user_id: " + str(user_id) )

    session_uuid = db.createNewSession(user_id)
    print( 'session_id = ' + session_uuid )
    res = db.hasSessionExpired(session_uuid)
    print( 'Session: ' + ('Expired' if res == True else 'Not Expired') )
    user_id = db.userWithSessionUUID(session_uuid)
    print( 'user_id from session_id: ' + str(user_id) )

    res = db.deleteSession(session_uuid)
    print( 'Delete result: ' + ('Deleted' if res > 0 else 'Not Deleted') )

    db.updateUserLimits( user_id, attrib=0xf, limit_teleportations=10 )
    db.updateUserStats( user_id, sent = 1)
    db.updateUserStats( user_id, received = 3)
    db.updateUserStats( user_id, chats_in = 6)
    db.updateUserStats( user_id, chats_out = 8)
    db.updateUserLimits( user_id, attrib=0x1ff, expires=90 )

    print( 'User Attributes:' );
    attrib = db.userAttributesAndStats(user_id)
    for k, v in attrib.items():
        print( '   ' + k + ' : ' + str(v) )

    # test Client API
    client_uuid, secret = db.addClient('Test', 'com.phatware.shaker', 'macOS')
    print( 'New Client ID: ' + client_uuid )
    print( 'Client Secret: ' + secret )

    res = db.verifyClient(client_uuid, secret)
    print( 'New CLIENT: ' + ('Verified' if res else 'Not Verified') )

    user = db.findUserByEmailId(email_id.hexdigest())
    if user is not None and user_id != user[0]:
        print('Wrong User ID: ' + str(user_id) + ' != ' + str(user[0]))
    elif user is None:
        print('User not found: ' + email_id.hexdigest())
    else:
        print('User found! Hash: ' + email_id.hexdigest())

    # test Device API
    dev_token = '123467678676543121242879816928764528736365748548i128578978374'
    db.addDevice(dev_token, user_id, 'My MAC', 'macOS')
    db.setDeviceStatus(1, device_token=dev_token)
    dev = db.listDevices(user_id)
    if dev is not None:
        print('Registered Devices:')
        for d in dev :
            print(d)
    dv = db.getDevice(device_token = dev_token)
    print('Added Device Token: ' + dv['token'] + ' name: ' + dv['name'])

    alert = '{ "title" : "Shaker", "body" :"Test message","action-loc-key" : "Accept" }'
    qid = db.queuePushRequest(dev_token, 0, badge=1, message=alert, sound='default')
    if qid > 0:
        print("Added notification " + str(qid))
        list = db.pendingPushNotifications(production=0, os='macOS')
        if len(list) > 0:
            print( "alert: " + list[0].alert )

    # test requests                                                             !
    dev_token_to = '9023840937498263487265478512874523784521387468712534067246521'
    request_id = db.createRequest( user_id, user_id, dev_token, request_type=1 )
    print('New request ID: ' + str(request_id))
    if request_id >= 0:
        req = db.activeRequestsForUser(user_id)
        print(req)
        rec1 = db.findRequest(request_id)
        db.updateRequestToken(request_id, dev_token_to)
        rec2 = db.findRequest(request_id)
    db.deleteExpiredRequests()

    res = db.deleteSentNotifications()
    print( 'Delete Sent Notifications  result: ' + str(res))

    res = db.pushNotificationSent(qid)
    res = db.deleteSentNotifications()
    print( 'Delete Sent Notifications  result: ' + str(res))

    # res = db.deleteNotification(qid)
    # print( 'Delete Notification ' + str(res) + ' result: ' + str(res))

    res = db.deleteDevice(device_token = dev_token)
    print( 'Delete DEVICE result: ' + ('Deleted' if res > 0 else 'Not Deleted') )

    # test Peripheral API
    serial_number = '1242623534-2353645-24543'
    res = db.deletePeripheralWithSN(serial_number)
    print( 'Delete Peripheral result: ' + ('Deleted' if res > 0 else 'Not Deleted') )

    db.addPeripheral(serial_number, user_id, 'my awesome device', 10)
    peripherals = db.listPeripherals(user_id)
    for p in peripherals:
        print(' * Peripheral SN: ' + p['sn'] + ' name: "' + p['name'] + '" added: ' + str(p['added']))
        pid = int(p['id'])
    # res = db.deleteUserPeripherals(user_id)

    per = db.getPeripheral(pid)
    if per is not None:
        print('Added Peripheral SN: ' + per['sn'] + ' name: "' + per['name'] + '" added: ' + str(per['added']))

    res = db.deletePeripheral(pid)
    print( 'Delete Peripheral result: ' + ('Deleted' if res > 0 else 'Not Deleted') )


    upgrade_codes = {
        "5d0ce6b27f0d4deeaf27135b9bfd7c1d" : { "t" : 1, "a" : 180 },
        "7188de1593294613b8cc19d506643d0d" : { "t" : 2, "a" : 180 },
        "16af54bbb04f455ab7649169a9057c7b" : { "t" : 1, "a" : 90 },
        "16af54bbb04f455ab7649169a9057c7b" : { "t" : 1, "a" : 30 },
        "11ce7e66b4f548fd92a8bc44d7f058fa" : { "t" : 2, "a" : 10 }
    }

    # TODO: later check if the code is already in use
    # user_info = db.userForUpgradeCode(upgrade_code)
    # if user_info is not None:
    code = "7188de1593294613b8cc19d506643d0d"

    try:
        data = upgrade_codes[code]
        type = data['t']
        asset = data['a']
        db.addUpgradeCode(code, type, asset, user_id)
        # check
        user_info = db.userForUpgradeCode(code)
        if user_info is None:
            print('**** userForUpgradeCode error!')
        else:
            print("**** user ID for code: " + str(user_info[0]))
    except:
        print( '**** Could not find code: ' + code )

    print(user)


    # delete USER

    res = db.deleteUser(user_id)
    print('Delete USER result: ' + ('Deleted' if res > 0 else 'Not Deleted'))

    res = db.deleteClient('Test')
    print( 'Delete `Test` CLIENT result: ' + ('Deleted' if res > 0 else 'Not Deleted') )

    db.disconnect()

    print('Import Drinks from sqlite3')
    id = ImportDrinks('../../database/drinks.sql')
    id.import_all()

