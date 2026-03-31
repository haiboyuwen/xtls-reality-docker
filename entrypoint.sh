#!/bin/bash

# 定义路径
LOCKFILE="/opt/xray/config/.lockfile"
CONFIG_FILE="/opt/xray/config/config.json"
TEMPLATE_FILE="/opt/xray/config.json"

# 初始化配置目录和文件

if [ ! -f "$CONFIG_FILE" ]; then
    cp "$TEMPLATE_FILE" "$CONFIG_FILE"
fi

if [ ! -f "$LOCKFILE" ]; then
    echo "首次启动：生成 UUID 和 Keys..."
    /opt/xray/xray uuid > /opt/xray/config/uuid
    /opt/xray/xray x25519 > /opt/xray/config/keys

    # 提取密钥和 UUID
    UUID=$(cat /opt/xray/config/uuid)
    PRIV=$(awk '/Private/{print $2}' /opt/xray/config/keys)
    PUB=$(awk '/Public/{print $3}' /opt/xray/config/keys)

    echo "$PRIV" > /opt/xray/config/private
    echo "$PUB" > /opt/xray/config/public

    # 使用 jq 精准注入 UUID 和 私钥，绝不破坏其它结构
    jq --arg id "$UUID" --arg pk "$PRIV" \
    '.inbounds[0].settings.clients[0].id = $id | .inbounds[0].streamSettings.realitySettings.privateKey = $pk' \
    "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    touch "$LOCKFILE"
fi

# 无论是否首启，动态更新 SNI 和 ShortID
# 顺便确保 tcpFastOpen 始终为 true
jq --arg sni "$SNI" --arg sid "$SHORT_ID" \
' .inbounds[0].streamSettings.realitySettings.dest = ($sni + ":443") |
  .inbounds[0].streamSettings.realitySettings.serverNames = [$sni] |
  .inbounds[0].streamSettings.realitySettings.shortIds = [$sid] |
  .inbounds[0].streamSettings.sockopt.tcpFastOpen = true' \
"$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "XTLS reality starting with TFO enabled..."
exec /opt/xray/xray run -config "$CONFIG_FILE"