#!/bin/bash

CONFIG_DIR="/opt/xray/config"
EXT_IP=$(curl -s ifconfig.me)
UUID=$(cat config/uuid)
PUB_KEY=$(cat config/public)
LINK="vless://${UUID}@${EXT_IP}:443?security=reality&encryption=none&pbk=${PUB_KEY}&headerType=none&fp=chrome&type=tcp&flow=xtls-rprx-vision&sni=${SNI}&sid=${SHORT_ID}#MyVLESS"


# 输出二维码
echo "$LINK" > ${CONFIG_DIR}/client_qr.txt
qrencode -t ansiutf8 < ${CONFIG_DIR}/client_qr.txt

base64 -w 0 ${CONFIG_DIR}/client_qr.txt > ${CONFIG_DIR}/sub