#!/bin/bash
# by tansi 2020.1.6
# auto deploy java nginx mysql

stop_firewalld() {
	echo "关闭防火墙"
	systemctl stop firewalld.service
	systemctl disable firewalld.service
}

# java
java_env() {
	jdk_url=http://file.ysjhlnu.top/software/jdk-8u202-linux-x64.tar.gz
	java_path=/usr/local/java

	yum install -y wget vim
	mkdir "$java_path"
	cd /usr/local/src
	wget "${jdk_url}"
	tar -zxf jdk-8u202-linux-x64.tar.gz -C "$java_path"

	cat >> /etc/profile<<-EOF
	export JAVA_HOME=${java_path}/jdk1.8.0_202
	export CLASS_PATH=\${JAVA_HOME}/jre/lib:\${JAVA_HOME}/lib
	export PATH=\${PATH}:\${JAVA_HOME}/bin
	EOF

	source /etc/profile
	java -version
	echo "*** java 安装完成***"
}

nginx_env() {
	echo "开始安装nginx"

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

	echo "创建用户和组:"
	groupadd nginx && useradd -s /sbin/nologin -g nginx -M nginx

	echo "安装依赖包:"
	yum install -y gcc gcc-c++ gd gd-devel unzip git wget vim 

	echo "创建安装目录和nginx安装目录"

	mkdir "${src_path}"
	mkdir "${ngx_path}"

	echo "进入目录：/usr/local/src"
	cd "${src_path}"

	echo "下载$ngx_cache_purge"

	if [ ! -f "$ngx_cache_purge-2.3.tar.gz" ];then
		wget "${ngx_cache_purge_url}" 
	fi



	echo "解压ngx_cache_purge"
	tar -zxf ngx_cache_purge-2.3.tar.gz


	echo "下载nginx-sticky-module"

	if [ ! -f "nginx-goodies-nginx-sticky-module-ng-08a395c66e42.zip" ];then
		wget "${ngx_sticky_module}"
	fi
	unzip nginx-goodies-nginx-sticky-module-ng-08a395c66e42.zip
	mv nginx-goodies-nginx-sticky-module-ng-08a395c66e42 nginx_sticky_module
	 
	echo "下载nginx-http-concat"
	if [ ! -d "nginx-http-concat" ];then
			git clone https://github.com/alibaba/nginx-http-concat.git
	fi

	 
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


	echo "下载ngx_cache_purge-2.3模块"
	if [ ! -f "ngx_cache_purge-2.3.tar.gz" ];then
		wget "${ngx_cache_purge_url}"
	fi
	echo "解压ngx_cache_purge"
	tar -zxf ngx_cache_purge-2.3.tar.gz

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

	echo "设置开机自启动"
	systemctl daemon-reload
	systemctl enable nginx 
	systemctl start nginx

	echo "安装路径: " "${src_path}"
	echo "安装完成!"
	source /etc/profile
}

mysql_env() {
	src_package=/usr/local/src
	install_path=/usr/local/mysql
	data_path=/data/mysql
	mysql_src="https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.16.tar.gz"
	boost_src="http://file.ysjhlnu.top/software/boost_1_59_0.tar.gz"
	cmake_src="https://cmake.org/files/v3.7/cmake-3.7.2.tar.gz"

	echo "start install mysql 5.7"

#	echo "***创建组和用户***"
#	groupadd mysql
#	useradd mysql -s /sbin/nologin -M -g mysql

#	echo "***创建数据存放的目录***"
#	mkdir -p ${data_path}
#	mkdir -p ${install_path}
#	chown -R mysql:mysql ${data_path}
#	chown -R mysql:mysql ${install_path}

	echo "***安装依赖包***"
#	yum install -y gcc gcc-c++ make tar openssl openssl-devel cmake ncurses ncurses-devel bison wget vim lrzsz

	cd ${src_package}

#	echo "***下载cmake包***"
#
#	if [ ! -f "cmake-3.7.2.tar.gz" ];then
#		wget ${cmake_src}
#		if [ $? -eq 0 ];then
#			echo "download success"
#		fi
#	fi
#	tar -zxf cmake-3.7.2.tar.gz 
#	cd cmake-3.7.2
#	./configure
#	make && make install
#	if [ $? -eq 0 ];then
#		echo "cmake make success!" >> /tmp/compile_mysql.txt
#	fi

	cd ${src_package}
	echo "下载boost包"

	if [ ! -f "boost_1_59_0.tar.gz" ];then
		wget ${boost_src}
		if [ $? -eq 0 ];then	
			echo "download success"
		fi
	fi
	tar -xf boost_1_59_0.tar.gz
	mv boost_1_59_0 boost

	echo "下载mysql 5.7源码包"
	cd ${src_package}

	if [ ! -f "mysql-5.7.16.tar.gz" ];then
		wget ${mysql_src}
		if [ $? -eq 0 ];then	
			echo "download success"
		fi
	fi
	tar -zxf mysql-5.7.16.tar.gz
	cd mysql-5.7.16 

	cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DMYSQL_USER=mysql -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DENABLED_LOCAL_INFILE=ON -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 -DWITH_EMBEDDED_SERVER=OFF -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/local/src/boost

	if [ $? -eq 0 ];then
		echo "检查成功"
		echo "mysql config checkout success" >> /tmp/compile_mysql.txt
	else
		echo "检查失败"
		rm -rf CMakeCache.txt
		exit 1
	fi

	make
	make install

	if [ $? -eq 0 ];then
		echo "mysql make install success" >> /tmp/compile_mysql.txt
	else
		exit 1
	fi

	echo "***复制配置文件***"
	mv /etc/my.cnf /etc/my.cnf.bak
	cat <<-EOF >> /etc/my.cnf
	[mysqld]
	port = 3306
	socket = /tmp/mysql.sock
	user = mysql
	datadir = /data/mysql
	pid-file = /data/mysql/mysql.pid

	log_error = /data/mysql/mysql-error.log
	slow_query_log = 1
	long_query_time = 1
	slow_query_log_file = /data/mysql/mysql-slow.log

	skip-external-locking
	key_buffer_size = 32M
	max_allowed_packet = 1024M
	table_open_cache = 128
	sort_buffer_size = 768K
	net_buffer_length = 8K
	read_buffer_size = 768K
	read_rnd_buffer_size = 512K
	myisam_sort_buffer_size = 8M
	thread_cache_size = 16
	query_cache_size = 16M
	tmp_table_size = 32M
	performance_schema_max_table_instances = 1000

	explicit_defaults_for_timestamp = true
	max_connections = 500
	max_connect_errors = 100
	open_files_limit = 65535

	log_bin=mysql-bin
	binlog_format=mixed
	server_id   = 232
	expire_logs_days = 10
	early-plugin-load = ""

	default_storage_engine = InnoDB
	innodb_file_per_table = 1
	innodb_buffer_pool_size = 128M
	innodb_log_file_size = 32M
	innodb_log_buffer_size = 8M
	innodb_flush_log_at_trx_commit = 1
	innodb_lock_wait_timeout = 50

	[mysqldump]
	quick
	max_allowed_packet = 16M

	[mysql]
	no-auto-rehash

	[myisamchk]
	key_buffer_size = 32M
	sort_buffer_size = 768K
	read_buffer = 2M
	write_buffer = 2M
	EOF

	echo "***初始化mysql***"

	/usr/local/mysql/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql

	chmod -R 755 /data/mysql/
	chown -R mysql:mysql /data/mysql/


	echo "***配置环境变量***"
	echo "export PATH=\$PATH:/usr/local/mysql/bin" >> /etc/profile
	source /etc/profile 

	ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql

	ln -s /usr/local/mysql/include/mysql /usr/include/mysql

	echo "***设置mysql开机自启动***"

	cat <<-EOF >> /usr/lib/systemd/system/mysqld.service
	[Unit]
	Description=MySQL Server
	Documentation=man:mysqld(8)
	Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
	After=network.target
	After=syslog.target
	[Install]
	WantedBy=multi-user.target
	[Service]
	User=mysql
	Group=mysql
	ExecStart=/usr/local/mysql/bin/mysqld 
	LimitNOFILE = 5000
	EOF

	systemctl enable mysqld
	systemctl start mysqld
	systemctl status mysqld

}
stop_firewalld
sleep 2
java_env
sleep 2
nginx_env
sleep 2
mysql_env
echo "如果nginx提示不可用,请执行source /etc/profile使环境变量立即生效。"


