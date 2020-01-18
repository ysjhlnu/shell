#!/bin/bash
# by tansi 2019/12/6
# auto install php v1

php_url=http://file.ysjhlnu.top/software/php-7.3.3.tar.gz
libzip_url=http://file.ysjhlnu.top/software/libzip-1.2.0.tar.gz
software_path=/usr/local/src

groupadd www
useradd -g www  -s /sbin/nologin -M www

echo "创建安装目录"
mkdir /usr/local/php

cat <<-EOF >>/etc/ld.so.conf 
/usr/local/lib64
/usr/local/lib
/usr/lib
/usr/lib64 
EOF
ldconfig -v
if [ $? -ne 0 ];then
	exit 1
fi

cp /usr/local/lib/libzip/include/zipconf.h /usr/local/include/zipconf.h

echo "开始安装php"
yum install -y wget gcc gcc-c++ make pcre pcre-devel openssl openssl-devel libxml2 libxml2-devel libcurl libcurl-devel libjpeg libjepg-devel libpng libpng-devel freetype freetype-devel openldap openldap-devel libmcrypt libmcrypt-devel libjpeg-devel php-mcrypt

echo "安装依赖"
yum install  -y epel-release

cd "${software_path}"
if [ ! -f "libzip-1.2.0.tar.gz" ];then
	wget "${libzip_url}"
fi
tar -zxf libzip-1.2.0.tar.gz


cd libzip-1.2.0

./configure

make && make install


cd "${software_path}"
echo "下载php"

if [ ! -f "php-7.3.3.tar.gz" ];then
	wget "${php_url}"
	if [ $? -eq 0 ];then
		echo "php download success"
	fi
fi
tar -zxf php-7.3.3.tar.gz
cd php-7.3.3 


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
echo "export PATH=\$PATH:/usr/local/php/sbin/:/usr/local/php/bin/" >>/etc/profile
source /etc/profile

sed -ri 's/;pid = run\/php-fpm.pid/pid =\/usr\/local\/php\/var\/run\/php-fpm.pid/' /usr/local/php/etc/php-fpm.conf

echo "使用systemctl管理php"
cat <<-EOF > /usr/lib/systemd/system/php-fpm.service
[Unit]
Description=php-fpm
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/usr/local/php/var/run/php-fpm.pid
ExecStart=/usr/local/php/sbin/php-fpm
ExecReload=/bin/kill -USR2 \$MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl start php-fpm

php --version

echo "php安装完成"



