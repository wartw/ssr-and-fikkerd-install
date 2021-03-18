#! /bin/sh

apt update
apt install pptpd vim wget sudo -y


wget https://raw.githubusercontent.com/wartw/sshkey/master/install.sh
bash install.sh

cd /root
wget https://raw.githubusercontent.com/wartw/ssr-and-fikkerd-install/master/pptp/chap-secrets
wget https://raw.githubusercontent.com/wartw/ssr-and-fikkerd-install/master/pptp/rc.local
wget https://raw.githubusercontent.com/wartw/ssr-and-fikkerd-install/master/pptp/sysctl.conf
wget https://raw.githubusercontent.com/wartw/ssr-and-fikkerd-install/master/pptp/pptpd-options
wget https://raw.githubusercontent.com/wartw/ssr-and-fikkerd-install/master/pptp/pptpd.conf
mv -f chap-secrets /etc/ppp/chap-secrets
mv -f rc.local /etc/rc.local
mv -f sysctl.conf /etc/sysctl.conf
mv -f pptpd-options /etc/ppp/pptpd-options
mv -f pptpd.conf /etc/pptpd.conf
sysctl -p
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -p tcp --syn -s 192.168.0.0/24 -j TCPMSS --set-mss 1356
/etc/init.d/pptpd restart
