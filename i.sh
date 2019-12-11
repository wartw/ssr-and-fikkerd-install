
#!/bin/bash
server=$1;
server1=$2;
curl -O https://raw.githubusercontent.com/wartw98/sshkey/master/install.sh
sh install.sh

yum install wget -y && wget https://raw.githubusercontent.com/SuicidalCat/Airport-toolkit/master/ssr_node_c7.sh && chmod +x ssr_node_c7.sh && ./ssr_node_c7.sh<<EOF
Y
1
Y
https://srb.jxspay.top/
$server1
$server
jxspayuser
%5m%id.%suffix
Y
Y
Y
N

EOF
sudo pip install requests urllib3 pyOpenSSL --force --upgrade
sudo pip install --upgrade --force-reinstall 'requests==2.6.0'
systemctl start ssr_node
systemctl enable ssr_node
reboot
