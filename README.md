# ssr-nistall
```
FikkerInstallDir="/root" # 安裝位置(建議不要改)
FikkerNewVersion="fikkerd-3.8.2-linux-x86-64" # 版本
service iptables stop 2> /dev/null ; chkconfig iptables off 2> /dev/null ; service httpd stop 2> /dev/null ; service nginx stop 2> /dev/null ; chkconfig httpd off 2> /dev/null ; chkconfig nginx off 2> /dev/null ; systemctl stop firewalld.service 2> /dev/null ; systemctl disable firewalld.service 2> /dev/null ; systemctl stop httpd.service 2> /dev/null ; systemctl stop nginx.service 2> /dev/null ; systemctl disable httpd.service 2> /dev/null ; systemctl disable nginx.service 2> /dev/null ; if [ -f "/usr/bin/apt-get" ]; then apt-get install -y wget tar; fi ; if [ -f "/usr/bin/yum" ]; then yum install -y wget tar; fi ; cd $FikkerInstallDir ; rm -rf $FikkerNewVersion.tar.gz ; wget -c --no-check-certificate https://github.com/wartw/ssr-and-fikkerd-install/raw/master/$FikkerNewVersion.tar.gz && tar zxf $FikkerNewVersion.tar.gz && rm -rf $FikkerNewVersion.tar.gz && cd $FikkerNewVersion && ./fikkerd.sh install && ./fikkerd.sh start && cd $FikkerInstallDir && sleep 5 && echo 'finished!'
```
