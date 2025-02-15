#!/bin/bash

# 设置脚本路径和服务名称
SCRIPT_PATH="/root/dns.py"
SERVICE_NAME="my_python_script.service"

# 创建 Python 脚本
echo "正在创建 Python 脚本..."

cat <<EOL > $SCRIPT_PATH
import requests
import tldextract
import time

API_TOKEN = ''  # 您的 API Token
ZONE_NAME = ''  # 主域名
RECORD_NAME = ''  # 需要更新的子域名

# 获取 Zone ID
def get_zone_id():
    url = f'https://api.cloudflare.com/client/v4/zones?name={ZONE_NAME}'
    headers = {'Authorization': f'Bearer {API_TOKEN}'}
    response = requests.get(url, headers=headers)
    data = response.json()
    return data['result'][0]['id']

# 获取 DNS Record ID
def get_dns_record_id(zone_id):
    url = f'https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?name={RECORD_NAME}'
    headers = {'Authorization': f'Bearer {API_TOKEN}'}
    response = requests.get(url, headers=headers)
    data = response.json()
    return data['result'][0]['id']

# 获取当前 IP 地址
def get_current_ip():
    response = requests.get('https://api.ipify.org?format=json')
    return response.json()['ip']

# 更新 DNS 记录
def update_dns_record(zone_id, record_id, ip):
    url = f'https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}'
    headers = {'Authorization': f'Bearer {API_TOKEN}', 'Content-Type': 'application/json'}
    data = {
        'type': 'A',
        'name': RECORD_NAME,
        'content': ip,
        'ttl': 1,
        'proxied': False
    }
    response = requests.put(url, json=data, headers=headers)
    return response.json()

# 获取 Zone ID 和 DNS Record ID
zone_id = get_zone_id()
record_id = get_dns_record_id(zone_id)

while True:
    current_ip = get_current_ip()
    response = update_dns_record(zone_id, record_id, current_ip)
    print(f'IP 更新为 {current_ip}：{response["success"]}')
    time.sleep(600)  # 每10分钟检查一次并更新
EOL

# 设置 Python 脚本权限
chmod +x $SCRIPT_PATH

# 创建 systemd 服务文件
echo "正在创建 systemd 服务文件..."

cat <<EOL > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=My Python DNS Update Script
After=network.target

[Service]
ExecStart=/usr/bin/python3 $SCRIPT_PATH
WorkingDirectory=/root
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOL

# 重新加载 systemd 配置
echo "重载 systemd 配置..."
systemctl daemon-reload

# 启用并启动服务
echo "启用并启动服务..."
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# 检查服务状态
echo "服务状态："
systemctl status $SERVICE_NAME

echo "完成！Python 脚本和 systemd 服务已成功创建并配置。"
