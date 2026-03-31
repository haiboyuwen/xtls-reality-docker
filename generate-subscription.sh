#!/bin/bash

CONFIG_DIR="/opt/xray/config"
SUB_FILE="${CONFIG_DIR}/subscription.txt"

echo "Generating subscription..."

> "$SUB_FILE"

for f in ${CONFIG_DIR}/clients/*.json; do
    uuid=$(jq -r '.id' "$f")
    host=$(jq -r '.host' "$f")
    port=$(jq -r '.port' "$f")
    pbk=$(jq -r '.pbk' "$f")
    sid=$(jq -r '.sid' "$f")

    echo "vless://${uuid}@${host}:${port}?security=reality&pbk=${pbk}&sid=${sid}&fp=chrome&type=tcp&flow=xtls-rprx-vision#Reality-${uuid}" >> "$SUB_FILE"
done

base64 -w 0 /opt/xray/config/subscription.txt > /opt/xray/config/sub