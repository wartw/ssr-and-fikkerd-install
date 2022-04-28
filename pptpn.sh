yum -y install epel-release
yum -y install ppp pptpd net-tools iptables-services
mv /etc/pptpd.conf /etc/pptpd.conf.bkp
mv -f /etc/ppp/options.pptpd /etc/ppp/options.pptpd.bkp
echo 'name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
proxyarp
lock
nobsdcomp
novj
novjccomp
nologfd
ms-dns 8.8.8.8
ms-dns 8.8.4.4' > /etc/ppp/options.pptpd
echo 'option /etc/ppp/options.pptpd
logwtmp
localip 10.0.10.1
remoteip 10.0.10.2-254' > /etc/pptpd.conf
echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
sysctl -p
systemctl stop firewalld.service
systemctl disable firewalld.service
service iptables save
service iptables stop
chkconfig iptables off
iptables -F
chmod +x /etc/rc.d/rc.local
echo "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> /etc/rc.d/rc.local
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables-save
echo "vpn * vpn *" >> /etc/ppp/chap-secrets
service pptpd restart
systemctl enable pptpd
