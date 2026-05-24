#!/bin/sh

# 1. 自动生成一个随机的 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 2. 写入 sing-box 的 VLESS+WS 配置文件
cat <<EOF > /config.json
{
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "0.0.0.0",
      "listen_port": 8080,
      "users": [
        {
          "uuid": "${UUID}",
          "flow": ""
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/${UUID}",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

# 3. 在后台启动 sing-box 核心
sing-box run -c /config.json &

# 4. 在后台启动 cloudflared 隧道
cloudflared tunnel --url http://0.0.0.0:8080 --no-autoupdate > /tmp/cloudflared.log 2>&1 &

# 5. 循环读取日志，抓取自动生成的 trycloudflare 域名
echo "正在向 Cloudflare 申请免费隧道，请稍候 (大约需要10-20秒)..."
sleep 5

ARGO_DOMAIN=""
for i in $(seq 1 15); do
    ARGO_DOMAIN=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" /tmp/cloudflared.log | head -n 1 | sed 's/https:\/\///')
    if [ -n "$ARGO_DOMAIN" ]; then
        break
    fi
    sleep 2
done

if [ -z "$ARGO_DOMAIN" ]; then
    echo "⚠️ 获取隧道域名失败，请重试。"
    cat /tmp/cloudflared.log
    exit 1
fi

# 6. 生成最终的一键批量连接
echo "=========================================================="
echo "🚀 终极版节点启动成功！"
echo "UUID: ${UUID}"
echo "伪装域名 (SNI/Host): ${ARGO_DOMAIN}"
echo "----------------------------------------------------------"
echo "🔗 批量导入链接 (请直接复制下方所有 vless:// 链接，然后在客户端选择[从剪贴板导入批量URL]):"
echo ""

# 使用 cat 直接输出拼接好的多个节点
cat <<EOF
vless://${UUID}@www.airasia.com:443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${UUID}%3Fed%3D2048#cf_tunnel_airasia_443
vless://${UUID}@www.visa.com.tw:443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${UUID}%3Fed%3D2048#cf_tunnel_visa_tw_443
vless://${UUID}@www.visa.com.hk:2053?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${UUID}%3Fed%3D2048#cf_tunnel_visa_hk_2053
vless://${UUID}@www.visa.com.br:8443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${UUID}%3Fed%3D2048#cf_tunnel_visa_br_8443
vless://${UUID}@usa.visa.com:2053?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${UUID}%3Fed%3D2048#cf_tunnel_visa_us_2053
vless://${UUID}@icook.hk:8443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${UUID}%3Fed%3D2048#cf_tunnel_icook_hk_8443
vless://${UUID}@time.is:8443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${UUID}%3Fed%3D2048#cf_tunnel_time_is_8443
EOF

echo ""
echo "=========================================================="

wait
