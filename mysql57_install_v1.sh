#!/bin/bash
# compiler install mysql5.7 v1
#by tansi 2019/12/5

src_package=/usr/local/src
install_path=/usr/local/mysql
data_path=/data/mysql
mysql_src=https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-5.7/mysql-boost-5.7.27.tar.gz
boost_src=http://file.ysjhlnu.top/software/boost_1_59_0.tar.gz

echo "start install mysql 5.7"

echo "***创建组和用户***"
groupadd mysql
useradd mysql -s /sbin/nologin -M -g mysql

echo "***创建数据存放的目录***"
mkdir -p ${data_path}
mkdir -p ${install_path}
chown -R mysql:mysql ${data_path}
chown -R mysql:mysql ${install_path}

echo "***安装依赖包***"
yum install -y gcc gcc-c++ cmake make tar openssl openssl-devel  ncurses ncurses-devel bison wget vim lrzsz libaio-devel

cd ${src_package}



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

if [ ! -f "mysql-boost-5.7.27.tar.gz" ];then
	wget ${mysql_src}
	if [ $? -eq 0 ];then	
		echo "download success"
	fi
fi
tar -zxf mysql-boost-5.7.27.tar.gz
cd mysql-5.7.27 

cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DMYSQL_USER=mysql -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DENABLED_LOCAL_INFILE=ON -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 -DWITH_EMBEDDED_SERVER=OFF -DDOWNLOAD_BOOST=1 -DWITH_BOOST=boost

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

echo "配置环境变量"
cat >> /etc/profile <<EOF
export PATH=\$PATH:/usr/local/mysql/bin
EOF

source /etc/profile

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
