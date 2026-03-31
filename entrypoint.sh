#!/bin/bash

# 定义路径
LOCKFILE="/opt/xray/config/.lockfile"
CONFIG_FILE="/opt/xray/config/config.json"
TEMPLATE_FILE="/opt/xray/config.json"

# 1. 初始化：确保目录存在
mkdir -p /opt/xray/config

# 2. 关键：每次启动强制从模板复制基础结构，确保 tcpFastOpen 模板在位
cp "$TEMPLATE_FILE" "$CONFIG_FILE"

# 3. 密钥生成逻辑
if [ ! -f "$LOCKFILE" ]; then
    echo "首次启动：生成 UUID 和 Keys..."
    /opt/xray/xray uuid > /opt/xray/config/uuid
    /opt/xray/xray x25519 > /opt/xray/config/keys

    UUID=$(cat /opt/xray/config/uuid)
    PRIV=$(awk '/Private/{print $2}' /opt/xray/config/keys)
    PUB=$(awk '/Public/{print $3}' /opt/xray/config/keys)

    echo "$PRIV" > /opt/xray/config/private
    echo "$PUB" > /opt/xray/config/public
    touch "$LOCKFILE"
fi

# 4. 从持久化文件读取当前生效的 ID 和 KEY
UUID_VAL=$(cat /opt/xray/config/uuid)
PRIV_VAL=$(cat /opt/xray/config/private)

echo "正在注入动态配置（SNI: $SNI）并强制启用 TFO..."

# 5. 使用 jq 统一注入，并强制修正 sockopt 结构
jq --arg id "$UUID_VAL" \
   --arg pk "$PRIV_VAL" \
   --arg sni "$SNI" \
   --arg sid "$SHORT_ID" \
   ' .inbounds[0].settings.clients[0].id = $id |
     .inbounds[0].streamSettings.realitySettings.privateKey = $pk |
     .inbounds[0].streamSettings.realitySettings.dest = ($sni + ":443") |
     .inbounds[0].streamSettings.realitySettings.serverNames = [$sni] |
     .inbounds[0].streamSettings.realitySettings.shortIds = [$sid] |
     .inbounds[0].streamSettings.sockopt = {"tcpFastOpen": true}' \
   "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"


echo "XTLS reality starting..."
exec /opt/xray/xray run -config "$CONFIG_FILE"