#!/bin/bash

# 设置文件路径
SCRIPT_PATH="/root/check_and_curl.sh"
SERVICE_PATH="/etc/systemd/system/ping_curl.service"

# 1. 创建 check_and_curl.sh 脚本
echo "正在创建 check_and_curl.sh 脚本..."

cat << 'EOF' > $SCRIPT_PATH
#!/bin/bash
# 脚本：check_and_curl.sh
# 作用：每分钟检查10.10.8.2是否可达，如果不可达，执行curl命令调用http://10.84.91.10/changeip/changeip.aspx

# 目标 IP 和 URL
TARGET_IP="10.10.8.2"
CURL_URL="http://10.84.91.10/changeip/changeip.aspx"

while true; do
    # 使用ping检测目标IP，-w 30表示总共等待30秒
    ping -w 30 "$TARGET_IP" > /dev/null 2>&1

    # 检查ping命令的退出状态，如果不为0，则表示ping失败
    if [ $? -ne 0 ]; then
        echo "$(date) - Ping to $TARGET_IP failed. Executing curl command..."
        curl "$CURL_URL"
    else
        echo "$(date) - Ping to $TARGET_IP succeeded."
    fi

    # 每次检查后等待60秒
    sleep 60
done
EOF

# 赋予脚本执行权限
chmod +x $SCRIPT_PATH

# 2. 创建 systemd 服务文件
echo "正在创建 systemd 服务文件..."

cat << 'EOF' > $SERVICE_PATH
[Unit]
Description=Ping and Curl Service
After=network.target

[Service]
ExecStart=/bin/bash /root/check_and_curl.sh
Restart=always
User=root
Group=root
WorkingDirectory=/root
StandardOutput=journal
StandardError=journal
TimeoutSec=0

[Install]
WantedBy=multi-user.target
EOF

# 3. 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
systemctl daemon-reload

# 4. 启动并设置服务开机自启
echo "启动服务并设置为开机自启..."
systemctl start ping_curl.service
systemctl enable ping_curl.service

# 5. 检查服务状态
echo "检查服务状态..."
systemctl status ping_curl.service

echo "所有步骤完成，脚本已设置为开机自启并正在运行。"
