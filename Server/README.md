## Shaker-Server

### Pre-requirements

1. Install python version 3.6+ and pip3
2. Run `install_dept.sh` to install python dependencies dependencies (This file assumes Ubuntu, if running on MAC OS, comment out adp-get commands)
3. Install mysql server and mysql Workbench

### Update Server configuration

Locate `api_setup.py` file.

1. Edit database parameters to match your configuration:

```json
    "db_url"                : "localhost",
    "db_login"              : "root",
    "db_name"               : "shaker",
    "db_pass"               : "....",
    "db_port"               : 3306,
```

2. Edit web socket parameters:

```json
    "srv_host"              : "192.168.0.77",
    "srv_port"              : 80,
    "ws_port"               : 80,

    "socket_ip"             : "ws://192.168.0.77:80",
```

### Configure database and rebuild Client

1. Run python3 `(sudo) python3 database_test.py`. You may need to run it twice. Make sure there is no errors on second run. This will create a new `shaker` database with all tables.

2. Register New Client(s):

 - iOS `python3 add_client.py -n "Shaker" -b com.phatware.shaker -o iOS`

3. Once the new client id/secret are generated, find `GlobalConstants.h` file in ShakerClient project and update `CLIENT_ID` and `CLIENT_SECRET`:

```objc

#if TARGET_OS_OSX
#define CLIENT_ID                   @"com.phatware.shaker_5facd8e272174d7f9e340891ce7e2675"
#define CLIENT_SECRET               @"5d3d41e3023f413eb9526ccba8da3f0086ed302d046f4fdfaffe9ef3d8711be2"
#else
#define CLIENT_ID                   @"com.phatware.shaker_81b321e937fe48f4a897cfddc7b6900a"
#define CLIENT_SECRET               @"462d485a7013453eaf2c52bd64f511be3b3c06f877e346fdaca1a2ed94492ce2"
#endif // TARGET_OS_OSX

```

4. Rebuild Client project in Xcode.

### Run Shaker Server

1. Open Terminal, go to `Server` folder and run `sudo python3 p2p_socket_server.py`. You will see message: `Started WebSocket server on <your port> port.`. Keep terminal open to view server log.

2. Open Terminal, go to `Server` folder and run `sudo python3 push.py`. You will see message: `Running in DEVELOPER mode.` Keep terminal open to view APNS service log.

