#!/bin/bash
# by tansi 2019/12/3
# install nginx
echo "开始安装"

zlib_version=1.2.11
nginx_version=1.17.6
pcre_version=8.43
openssl_version=1.1.1
src_path=/usr/local/src
ngx_path=/usr/local/nginx
nginx_url="http://nginx.org/download/nginx-${nginx_version}.tar.gz"
zlib_url="http://file.ysjhlnu.top/software/zlib-1.2.11.tar.gz"
openssl_url="http://www.openssl.org/source/openssl-${openssl_version}.tar.gz"
ngx_cache_purge_url="http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz"
pcre_url="http://file.ysjhlnu.top/software/pcre-8.43.tar.gz"
ngx_sticky_module="http://file.ysjhlnu.top/software/nginx-goodies-nginx-sticky-module-ng-08a395c66e42.zip"

src_path=/usr/local/src
ngx_path=/usr/local/nginx

echo "关闭防火墙"
systemctl stop firewalld.service
systemctl disable firewalld.service 


echo "创建用户和组:"
groupadd nginx && useradd -s /sbin/nologin -g nginx -M nginx

echo "安装依赖包:"
yum install -y gcc gcc-c++ gd gd-devel unzip git wget vim 

echo "创建安装目录和nginx安装目录"

mkdir "${src_path}"
mkdir "${ngx_path}"

echo "进入目录：/usr/local/src"
cd "${src_path}"

ngx_sticky_module(){
	cd /usr/local/src
	echo "下载nginx-sticky-module"

	if [ ! -f "nginx-goodies-nginx-sticky-module-ng-08a395c66e42.zip" ];then
		wget "${ngx_sticky_module}"
	fi
	unzip nginx-goodies-nginx-sticky-module-ng-08a395c66e42.zip
	mv nginx-goodies-nginx-sticky-module-ng-08a395c66e42 nginx_sticky_module
}

nginx-http-concat(){
	cd /usr/local/src
	echo "下载nginx-http-concat"
	if [ ! -d "nginx-http-concat" ];then
			git clone https://github.com/alibaba/nginx-http-concat.git
	fi
}

pcre(){
	cd /usr/local/src
	echo "下载：pcre"

	if [ ! -f "pcre-8.43.tar.gz" ];then
		wget "${pcre_url}"
	fi

	echo "解压：pcre-${pcre_version}.tar.gz"
	tar -zxf pcre-"${pcre_version}".tar.gz

	cd pcre-"$pcre_version"
	echo "编译安装：pcre-${pcre_version}"
	./configure 
	make && make install	
}

ngx_cache_purge(){
	cd /usr/local/src
	echo "下载ngx_cache_purge-2.3模块"
	if [ ! -f "ngx_cache_purge-2.3.tar.gz" ];then
		wget "${ngx_cache_purge_url}"
	fi
	echo "解压ngx_cache_purge"
	tar -zxf ngx_cache_purge-2.3.tar.gz
}

openssl(){
	cd /usr/local/src
	echo "下载：openssl-${openssl_version}"
	if [ ! -f "openssl-1.1.1.tar.gz" ];then
		wget "${openssl_url}" 
	fi
	tar -zxf openssl-"${openssl_version}".tar.gz
	cd openssl-"{$openssl_version}"
	echo "编译安装：openssl-${openssl_version}"
	./configure 
	make && make install 
}

zlib(){
	echo "返回到目录：/usr/local/src"
	cd /usr/local/src


	echo "下载：zlib-1.2.11"

	if [ ! -f "zlib-1.2.11.tar.gz" ];then
		wget "${zlib_url}"		
	fi
	tar -zxf zlib-"${zlib_version}".tar.gz
	cd zlib-"${zlib_version}"
	./configure 
	make && make install 	
}

nginx(){
	cd "${src_path}"

	echo "下载：nginx-${nginx_version}"

	if [ ! -f "nginx-1.17.6.tar.gz" ];then
		wget "${nginx_url}"	
	fi
	echo "解压：nginx-"${nginx_version}".tar.gz"
	tar -zxf nginx-"${nginx_version}".tar.gz	
	mv nginx-"${nginx_version}" nginx


	echo "进入目录：nginx"
	cd nginx
	echo "编译安装：nginx-${nginx_version}"
	./configure --user=nginx --group=nginx --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_gzip_static_module --with-http_realip_module --with-http_sub_module --with-http_ssl_module --with-http_v2_module --with-http_image_filter_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_flv_module --with-http_addition_module --with-http_mp4_module --with-pcre=/usr/local/src/pcre-8.43 --with-zlib=/usr/local/src/zlib-1.2.11 --with-openssl=/usr/local/src/openssl-1.1.1 --add-module=/usr/local/src/nginx_sticky_module --add-module=/usr/local/src/nginx-http-concat --add-module=/usr/local/src/ngx_cache_purge-2.3 --with-cc-opt=-Wno-error


	make && make install 
	if [ $? -ne 0 ];then
		echo "请重新检查"
		exit 1
	fi


	cat >>/etc/profile<<-EOF
	export PATH=\$PATH:/usr/local/nginx/sbin
	EOF

	source /etc/profile
	source /etc/profile

	echo "创建启动服务"
	cat > /lib/systemd/system/nginx.service <<-EOF
	[Unit]
	Description=nginx
	After=network.target remote-fs.target nss-lookup.target
	[Service]
	Type=forking
	PIDFile=${ngx_path}/logs/nginx.pid
	ExecStartPre=${ngx_path}/sbin/nginx -t
	ExecStart=${ngx_path}/sbin/nginx 
	ExecReload=/bin/kill -s HUP \$MAINPID
	ExecStop=/bin/kill -s QUIT \$MAINPID
	PrivateTmp=true
	[Install]
	WantedBy=multi-user.target
	EOF
}

echo "设置开机自启动"
systemctl daemon-reload
systemctl enable nginx 
systemctl start nginx

echo "安装路径: " "${src_path}"
echo "安装完成!"
source /etc/profile
