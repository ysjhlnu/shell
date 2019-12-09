#!/bin/bash
# by tansi 2019/12/6
# auto install php v1

php_src="http://cn2.php.net/distributions/php-7.3.3.tar.gz"

groupadd www
useradd -g www  -s /sbin/nologin -M www

echo "开始安装php"
cd /usr/local/src
echo "下载php"
while [ ! -d "php" ];do
	if [ ! -f "php-7.3.3.tar.gz" ];then
		wget ${php_src}
		if [ $? -eq 0 ];then
			echo "php download success"
		fi
	fi
	tar -zxf php-7.3.3.tar.gz
	mv php-7.3.3 php
done

echo "安装依赖"
yum install  -y epel-release

while [ ! -d "libzip-1.2.0" ];do
	if [ ! -f "libzip-1.2.0.tar.gz" ];then
		wget https://libzip.org/download/libzip-1.2.0.tar.gz
	fi
	tar -zxf libzip-1.2.0.tar.gz
done

cd libzip-1.2.0

./configure

make && make install

yum install -y gcc gcc-c++ make pcre pcre-devel openssl openssl-devel libxml2 libxml2-devel libcurl libcurl-devel libjpeg libjepg-devel libpng libpng-devel freetype freetype-devel openldap openldap-devel libmcrypt libmcrypt-devel libjpeg-devel php-mcrypt

echo "创建安装目录"
mkdir /usr/local/php
cd /usr/local/src/php


cat <<-EOF >>/etc/ld.so.conf 
/usr/local/lib64
/usr/local/lib
/usr/lib
/usr/lib64 
EOF
ldconfig -v &>/dev/null 

cp /usr/local/lib/libzip/include/zipconf.h /usr/local/include/zipconf.h

./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --enable-ctype  --enable-mysqlnd  --with-mysqli=mysqlnd --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-gd  --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-ldap-sasl --with-xmlrpc --enable-zip --enable-soap --with-gettext --enable-fpm --with-fpm-user=www --with-fpm-group=www


make && make install
if [ $? -eq 0 ];then
	echo "php编译安装完成"
fi
echo "拷贝配置文件"
cp php.ini-production /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf

echo "配置环境变量"
echo "export PATH=$PATH:/usr/local/php/sbin/:/usr/local/php/bin/" >>/etc/profile
source /etc/profile


sed -ri 's/^\; pid.*pid/pid=\/var\/run\/php-fpm.pid/' /usr/local/php/etc/php-fpm.conf


echo "使用systemctl管理php"
cat <<-EOF >> /usr/lib/systemd/system/php-fpm.service
[Unit]
Description=php-fpm
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/var/run/php-fpm.pid
ExecStart=/usr/local/php/sbin/php-fpm
ExecReload=/bin/kill -USR2 $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl start php-fpm

php-version

echo "php安装完成"



