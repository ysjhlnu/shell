#!/bin/bash
# by tansi 2019/12/3
# install nginx
echo "开始安装"
pcre_version="8.43"
openssl_version="1.1.1"
nginx_version="1.17.6"
nginx-sticky-module=""
nginx-http-concat=""
ngx_cache_purge="ngx_cache_purge-2.3"
purge_url="http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz"
src_path=/usr/local/src
ngx_path=/usr/local/nginx

echo "关闭防火墙"
systemctl stop firewalld.service
systemctl disable firewalld.service 

echo "创建用户和组:"
groupadd nginx && useradd -s /sbin/nologin -g nginx -M nginx

echo "安装依赖包:"
yum install -y gcc gcc-c++ gd gd-devel unzip

echo "创建安装目录和nginx安装目录"
if [ ! -d "$src_path" ];then
	mkdir $src_path
fi

if [ ! -d "$ngx_path" ];then
	mkdir "$ngx_path"
fi

echo "进入目录：/usr/local/src"
cd "$src_path"

echo "下载$ngx_cache_purge"
if [ -d "$ngx_cache_purge" ];then
	echo "$ngx_cache_purge已下载"
elif [ ! -f "$ngx_cache_purge-2.3.tar.gz" ];then
		wget $ngx_cache_purge_url &>/dev/null
		if [ $? -eq 0 ];then
			echo "ngx_cache_purge2.3 下载完成"
		fi
fi



echo "解压ngx_cache_purge"
tar -zxf ngx_cache_purge-2.3.tar.gz
echo ""

echo "下载nginx-sticky-module"
if [ ! -d nginx-sticky-module ];then
	if [ ! -f 08a395c66e42.zip ];then
		wget https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/08a395c66e42.zip
		if [ $? -eq 0 ];then
			echo "nginx-sticky-module下载完成"
		fi
	else
		unzip 08a395c66e42.zip
		mv nginx-goodies-nginx-sticky-module-ng-08a395c66e42/ nginx-sticky-module
	fi
fi





 
echo "下载nginx-http-concat"
if [ ! -d nginx-http-concat ];then
		git clone https://github.com/alibaba/nginx-http-concat.git
fi

if [ $? -eq 0 ];then
	echo "nginx-http-concat下载完成"
fi
 
echo "下载：pcre-"$pcre_version""
if [ ! -d pcre-8.43 ];then
	if [ ! -f pcre-8.43.tar.gz ];then
		wget https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
		echo "解压：pcre-${pcre_version}.tar.gz"
		tar -zxf pcre-"$pcre_version".tar.gz
	fi
else
	echo "进入目录：/usr/local/src/pcre-${pcre_version}"
	cd pcre-"$pcre_version"
	echo "编译安装：pcre-${pcre_version}"
	./configure &>/dev/null
	make && make install	&>/dev/null	
fi

echo "下载ngx_cache_purge-2.3模块"
if [ ! -d "ngx_cache_purge-2.3" ];then
	if [ ! -f "ngx_cache_purge-2.3.tar.gz" ];then
		wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz
		echo "解压ngx_cache_purge"
		tar -zxf ngx_cache_purge-2.3.tar.gz
	fi
else
	echo "ngx_cache_purge-2.3.tar.gz已下载"
fi

	

echo "返回到目录：/usr/local/src"
cd /usr/local/src
echo ""


echo "下载：openssl-${openssl_version}"
if [ ! -d "openssl-1.1.1" ];then
	if [ ! -f "openssl-1.1.1.tar.gz" ];then
			openssl_url="http://www.openssl.org/source/openssl-${openssl_version}.tar.gz"
			wget ${openssl_url} &>/dev/null
	
	else
			echo "解压：openssl-${openssl_version}.tar.gz"
			tar -zxf openssl-"$openssl_version".tar.gz
	fi
else
	echo "进入目录：openssl-${openssl_version}"
	cd openssl-"$openssl_version"
	echo "编译安装：openssl-${openssl_version}"
	./config &>/dev/null
	make && make install &>/dev/null
fi


echo "返回到目录：/usr/local/src"
cd /usr/local/src
echo ""
 
 
echo "下载：zlib-${zlib_version}"
if [ !-d "zlib-1.2.11" ];then
	if [! -f "zlib-1.2.11.tar.gz" ];then
			zlib_url="http://zlib.net/zlib-${zlib_version}.tar.gz"
			wget $zlib_url	&>/dev/null	
	else
			echo "解压：zlib-${zlib_version}.tar.gz"
			tar -zxf zlib-"$zlib_version".tar.gz
	fi
else
	echo "进入目录：zlib-${zlib_version}"
	cd zlib-"$zlib_version"
	echo "编译安装：zlib-${zlib_version}"
	./configure &>/dev/null
	make && make install &>/dev/null	
fi

	

echo "返回到目录：/usr/local/src"
cd "$src_path"
echo ""

echo "下载：nginx-${nginx_version}"
if [ !-d "nginx" ];then
	if [ !-f "nginx-1.17.6.tar.gz" ];then
		nginx_url="http://nginx.org/download/nginx-${nginx_version}.tar.gz"
		wget $nginx_url	&>/dev/null
	else
		echo "解压：nginx-"$nginx_version".tar.gz"
		tar -zxf nginx-"$nginx_version".tar.gz	
		echo "重命名nginx-${nginx_version}为nginx"
		mv nginx-"$nginx_version" nginx
	fi
else
	echo "进入目录：nginx"
	cd nginx
	echo "编译安装：nginx-${nginx_version}"
	./configure --user=nginx --group=nginx --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_gzip_static_module --with-http_realip_module --with-http_sub_module --with-http_ssl_module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_image_filter_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-pcre=/usr/local/src/pcre-8.43 --with-zlib=/usr/local/src/zlib-1.2.11 --with-openssl=/usr/local/src/openssl-1.1.1 --add-module=/usr/local/src/nginx-sticky-module --add-module=/usr/local/src/nginx-http-concat --add-module=/usr/local/src/ngx_cache_purge-2.3 --with-http_realip_module  --with-cc-opt=-Wno-error
	if [ $? -ne 0 ];then
		echo "请重新检查!"
	else
		make && make install &>/dev/null
		echo "创建目录：/usr/local/nginx/logs"
		if [ ! -d "/usr/local/nginx/logs" ];then
			mkdir /usr/local/nginx/logs
		fi
	fi 		
fi

echo "创建启动服务"
vim /lib/systemd/system/nginx.service <<-EOF
[Unit]
Description=nginx
After=network.target

[Service]
Type=forking
PIDFile=$ngx_path/logs/nginx.pid
ExecStart=$ngx_path/sbin/nginx -c $ngx_path/conf/nginx.conf
ExecStartPre=$ngx_path/sbin/nginx -t -c $ngx_path/conf/nginx.conf
ExecReload=$ngx_path/sbin/nginx reload
ExecStop=$ngx_path/sbin/nginx quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo "设置开机自启动"
systemctl enable nginx && systemctl start nginx

echo "设置nginx别名"
vim ~/.bashrc <<-EOF
alias nginx="$ngx_path/sbin/nginx"
EOF

source ~/.bashrc


echo "返回到目录：/usr/local/src"
cd "$src_path"
echo ""
 
 
read -p "是否需要删除下载的安装（输入y/Y删除，其他不删除）：" inputMsg
if [ "$inputMsg" == 'y' ] || [ "$inputMsg" == 'Y' ] 
then
    rm -rf *.tar.gz
    rm -rf *.zip
    echo "删除完成"
else
    echo "不删除"
fi
echo ""
 
echo "安装路径: " $src_path
echo "安装完成!"
