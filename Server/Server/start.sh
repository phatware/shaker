#!/bin/bash
cd "$(dirname "$0")"

echo Starting services
# now runs under apache
# nohup python api.py > apilog.txt &
nohup python3 p2p_socket_server.py > socketlog.txt &
nohup python3 push.py --production > pushlog.txt &
nohup python3 push.py > pushlog.txt &
