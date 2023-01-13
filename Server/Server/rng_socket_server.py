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


clients = []

# unpacker = struct.Struct('I I I I I')
rd = randomData()

teleporter_randomdata_request = 10012
teleporter_randomdata_response = 10013


class RNGSocket(WebSocket):

    def handleMessage(self):

        try:
            js = self.data.decode('utf8').replace("'", '"')
            #print(js)
            message = json.loads(js)
            message_id = int(message["id"])
            if message_id == teleporter_randomdata_request :
                data = rd.getRND(teleporter_randomdata_response, int(message["s"]), message["i"], message["c"])     # c=10013, i = client_id 
                self.sendMessage( data )
        except:
            print("bad message format: headers")
            self.close()
            return

    def handleConnected(self):
        print (self.address, 'connected')
        self.epoch = 0
        self.handler_id = 0
        self.size = 0
        self.checksum = 0
        self.qid = 0
        clients.append(self)

    def handleClose(self):
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

    cls = RNGSocket

    server = SimpleWebSocketServer(_config['rng_host'], _config['rng_port'], cls)

    def close_sig_handler(signal, frame):
        server.close()
        sys.exit()

    print('Started WebSocket server on ' + str(_config['rng_port']) + ' port.')
    signal.signal(signal.SIGINT, close_sig_handler)

    server.serveforever()

