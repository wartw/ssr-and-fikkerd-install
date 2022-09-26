#!/bin/bash
wget https://download.mikrotik.com/routeros/6.49.6/chr-6.49.6.img.zip -O chr.img.zip  && \
gunzip -c chr.img.zip > chr.img  && \
dd if=chr.img bs=1024 of=/dev/vda 

一般建立 Vultr VPS 的方式進行，不過在選擇 Server Type 的時候改成選擇 Upload ISO 並選擇 iPXE ， 填入 http://boot.ipxe.org/demo/boot.php 。
