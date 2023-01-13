from database import Database
from tables import Tables
import hashlib
import sys, getopt
from api_setup import _config

if __name__ == '__main__':

    # Create Cleint API
    name = None     # 'shaker'
    bundle = None   # 'com.phatware.shaker'
    os = None       # 'macOS'
    delete = None   # delete
    list = False

    try:
        opts, args = getopt.getopt(sys.argv[1:],"n:b:o:d:l",["nname=","bbundle=","oos=","ddelete="])
    except getopt.GetoptError:
        print ('add_client.py -l | -n <name> -b <bundle> -o <iOS|macOS>')
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-n", "--nname"):
            name = arg
        elif opt in ("-o", "--oos"):
            os = arg
        elif opt in ("-b", "--bbundle"):
            bundle = arg
        elif opt in ("-d", "--ddelete"):
            delete = arg
        elif opt in "-l":
            list = True

    # test database API
    db = Database(
        host = _config['db_url'],
        user = _config['db_login'],
        password = _config['db_pass'],
        database_name = _config['db_name'],
        ssl_ca = _config['db_cert']
    )

    if list is True:
        if db.connect():
            clients = db.listClients()
            print("Clients:")
            for client in clients:
                print("Client named '" + client["name"] + "' for " + client["os"])
                print("UUID: " + client["uuid"])
                print("Secret SHA, not actual secret: " + client["secret"])
                print("")
            db.disconnect()

    elif delete is not None:
        if db.connect():
            res = db.deleteClient(delete)
            print( 'Deleting "' + delete + '" CLIENT.... Result: ' + ('Deleted' if res > 0 else 'Not Deleted') )
            db.disconnect()

    elif name is None or bundle is None or os is None:
        print ('add_client.py -l | -n <name> -b <bundle> -o <iOS|macOS>')
        sys.exit(2)

    else:
        if db.connect():
            res = db.deleteClient(name)
            print( 'Deleting OLD CLIENT.... Result: ' + ('Deleted' if res > 0 else 'Not Deleted') )
            client_uuid, secret = db.addClient(name, bundle, os)
            print( 'New Client ID: ' + client_uuid )
            print( 'Client Secret: ' + secret )

            res = db.verifyClient(client_uuid, secret)
            print( 'New CLIENT: ' + ('Verified' if res else 'Not Verified') )
            db.disconnect()
