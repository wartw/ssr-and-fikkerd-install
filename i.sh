
#!/bin/bash
curl -O https://raw.githubusercontent.com/wartw98/sshkey/master/install.sh
sh install.sh
yum install vim wget nload iftop -y
yum -y groupinstall "Development Tools"
wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.16.tar.gz 
tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig

cd /root
yum -y install python-setuptools python-pip python-devel -y
easy_install pipgit clone -b manyuser https://github.com/lizhongnian/shadowsocks.gitcd shadowsocks
pip install -r requirements.txt
cp apiconfig.py userapiconfig.py
cp config.json user-config.json
