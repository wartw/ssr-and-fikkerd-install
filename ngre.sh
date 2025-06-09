#!/bin/bash

# =========================
# 自訂 GRE 內部 IP 前綴
IP_PREFIX="10.10.0"
# =========================

PEER_INNER_IP="${IP_PREFIX}.2"
MY_INNER_IP="${IP_PREFIX}.1"
PEER_OUTER_IP="53.49.211.241"

# 安裝必要工具
dnf -y install epel-release
dnf -y install htop tcpdump net-tools bind-utils wget nano \
               unzip zip vim nload iftop sudo git curl mtr ca-certificates
dnf -y install iptables iptables-services network-scripts

# 停用 NetworkManager，改用傳統 network
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl enable network
systemctl start network

# 設定 crontab 每分鐘 ping 對方內部 IP
(crontab -l 2>/dev/null; echo "* * * * * ping ${PEER_INNER_IP} -c 3 -W 1") | crontab -

# 建立 GRE interface 設定
cat >/etc/sysconfig/network-scripts/ifcfg-tun0 <<EOF
DEVICE=tun0
ONBOOT=yes
TYPE=GRE
PEER_OUTER_IPADDR=${PEER_OUTER_IP}
PEER_INNER_IPADDR=${PEER_INNER_IP}
MY_INNER_IPADDR=${MY_INNER_IP}
BOOTPROTO=static
MTU=1402
EOF

# 載入 GRE 模組
modprobe ip_gre
cat >/etc/sysconfig/modules/ip_gre.modules <<EOF
#!/bin/sh
/sbin/modinfo -F filename ip_gre > /dev/null 2>&1
[ \$? -eq 0 ] && /sbin/modprobe ip_gre
EOF
chmod +x /etc/sysconfig/modules/ip_gre.modules

# 重啟 network 載入 GRE 設定
systemctl restart network

# 調整核心參數
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

# 改用 iptables
systemctl stop firewalld
systemctl disable firewalld
systemctl enable iptables
systemctl start iptables

# iptables NAT & GRE 規則
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
iptables -A INPUT -p gre -j ACCEPT
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables-save > /etc/sysconfig/iptables

# 確保開機載入 iptables
echo "iptables-restore < /etc/sysconfig/iptables" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
