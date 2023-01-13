from database import Database
import json

##
## Setup global resources
##

# TODO: change to quantum1net.com domain
_config = {
    "name"                  : "Shaker",
    "minversion_iOS"        : 1,
    "minversion_macOS"      : 1,
    "minversion_android"    : 1,
    "minversion_windows"    : 1,
    "server_version"        : "0.1",
    "db_url"                : "localhost",
    "db_login"              : "root",
    "db_name"               : "shaker",
    "db_pass"               : "phatware68",
    "db_port"               : 3306,
    "db_cert"               : "MyServerCACert.pem",
    "email_from"            : "shaker@phatware.com",    # TODO:
    "email_host"            : "mail.phatware.com",          # TODO: mail.quantum1net.com",
    "email_port"            : 587,                          # 465
    "email_pass"            : "longlongpassword123!",       # TODO:
    "srv_host"              : "0.0.0.0", # "192.168.0.99",
    "rng_host"              : "0.0.0.0", # "192.168.0.99",
    "rng_port"              : 81,
    "srv_port"              : 80,
    # TODO: enable WSSL
    "wssl"                  : True,
    "srv_cert"              : "/Users/stan/work/new/shaker/Server/Server/public.pem",       # TODO:
    "srv_key"               : "/Users/stan/work/new/shaker/Server/Server/private.pem",      # TODO:
    "srv_url"               : "https://node1.quantum1net.com/api/v1/",
    "dev_confirm"           : False,
    "sandbox"               : True,
    "prph_confirm"          : False,
    "user_attrib"           : False,
    "dev_cert_macos"        : "apns-macos-dev.pem",
    "prd_cert_macos"        : "apns-macos-prod.pem",
    "dev_cert_ios"          : "apns-ios-dev.pem",
    "prd_cert_ios"          : "apns-ios-prod.pem",
    "language"              : "en",

    # TODO: set Shaker download page here, on macOS/iOS/Android point directly to the app in the store
    "download_url"          : "http://shaker.phatware.com",
    "turn_ip"               : "turn:node1.quantum1net.com:8080",
    # TOD:
    "stun_ips"              : [
        "stun:stun.l.google.com:19305",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302",
        "stun:stun.ekiga.net",
        "stun:stun.ideasip.com",
        "stun:stun.xten.com",
        "stun:stun.voiparound.com"
    ]
}

try:
    with open('config.json') as data_file:
        _config = json.load(data_file)
except Exception:
    pass

# initialize database
# db = Database(_config['db_url'], _config['db_login'], _config['db_pass'], _config['db_name'], ssl_ca = _config['db_cert'])
