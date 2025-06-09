#!/bin/bash

# 1. 設定 crontab ping 測試
(crontab -l 2>/dev/null; echo "* * * * * ping 10.10.3.2 -c 3 -W 1") | crontab -

# 2. 建立 GRE 介面設定檔
cat >/etc/sysconfig/network-scripts/ifcfg-tun0 <<EOF
DEVICE=tun0
ONBOOT=yes
TYPE=GRE
PEER_OUTER_IPADDR=53.49.211.241
PEER_INNER_IPADDR=10.10.0.2
MY_INNER_IPADDR=10.10.0.1
BOOTPROTO=static
MTU=1402
EOF

# 3. 安裝必要套件
dnf install -y epel-release
dnf install -y htop tcpdump net-tools bind-utils wget nano iptables iptables-services \
    unzip zip vim nload iftop sudo git curl mtr ca-certificates

# 4. 啟用 GRE 模組並開機自動載入
modprobe ip_gre
lsmod | grep gre
cat >/etc/sysconfig/modules/ip_gre.modules <<EOF
#!/bin/sh
/sbin/modinfo -F filename ip_gre > /dev/null 2>&1
[ \$? -eq 0 ] && /sbin/modprobe ip_gre
EOF
chmod +x /etc/sysconfig/modules/ip_gre.modules

# 5. 停用 firewalld，改用 iptables
systemctl stop firewalld
systemctl disable firewalld
dnf install -y iptables iptables-services
systemctl enable iptables
systemctl start iptables

# 6. 核心參數優化
cat >>/etc/sysctl.conf <<EOF
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.eth0.accept_redirects = 0
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.eth0.rp_filter=0
net.ipv4.conf.gre0.rp_filter=0
net.ipv4.conf.gretap0.rp_filter=0
net.ipv4.conf.ip_vti0.rp_filter=0
net.ipv4.conf.tunl0.rp_filter=0
net.ipv4.conf.erspan0.rp_filter=0
vm.overcommit_memory = 1
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 87380 8388608
net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
EOF
sysctl -p

# 7. 設定 iptables 規則
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A INPUT -p gre -j ACCEPT
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# 8. 儲存 iptables 規則並設為開機自動套用
iptables-save > /etc/sysconfig/iptables
echo "iptables-restore < /etc/sysconfig/iptables" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

# 9. 重啟網路服務
systemctl restart network
