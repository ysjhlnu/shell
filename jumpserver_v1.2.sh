#!/bin/bash
# by tansi 2019/12/15
# auto install jumpserver v1.2
DEBUG=0
DB_ENGINE=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_ROOT_PASSWD=tansi201407@
DB_NAME=jumpserver
DB_USER=jumpserver
DB_PASSWORD=tansi201407@
REDIS_PASSWORD=redis

# 生成随机SECRET_KEY
if [ "$SECRET_KEY" = "" ]; then 
	SECRET_KEY=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 50` 
	echo "SECRET_KEY=$SECRET_KEY" >> ~/.bashrc; echo $SECRET_KEY
else echo $SECRET_KEY 
fi
export SECRET_KEY=$SECRET_KEY

# 生成随机BOOTSTRAP_TOKEN
if [ "$BOOTSTRAP_TOKEN" = "" ]; then 
	BOOTSTRAP_TOKEN=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`
	echo "BOOTSTRAP_TOKEN=$BOOTSTRAP_TOKEN" >> ~/.bashrc
	echo $BOOTSTRAP_TOKEN; else echo $BOOTSTRAP_TOKEN
fi

#yum update -y

echo "***设置防火墙***"
systemctl stop firewalld
systemctl disable firewalld
#systemctl start firewalld
#firewall-cmd --zone=public --add-port=80/tcp --permanent  # nginx 端口
#firewall-cmd --zone=public --add-port=2222/tcp --permanent  # 用户SSH登录端口 koko
#firewall-cmd --reload  # 重新载入规则

echo "*** 修改系统字符集 ***"
export LC_ALL=zh_CN.UTF-8
export AUTOENV_ASSUME_YES=1
localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
echo 'LANG="zh_CN.UTF-8"' > /etc/locale.conf

echo "1.禁用 yum插件 fastestmirror"
yum install -y wget 

echo "1)修改插件的配置文件"
cp /etc/yum/pluginconf.d/fastestmirror.conf /etc/yum/pluginconf.d/fastestmirror.conf.bak 
sed -ri 's/^enabled=.*/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf

echo "2)修改yum的配置文件"
cp /etc/yum.conf /etc/yum.conf.bak
sed -ri 's/^plugins=.*/plugins=0/' /etc/yum.conf

echo "2.aliyun yum"
cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://192.168.1.11/yum/Centos-7.repo

# epel 
mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
#wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
wget -O /etc/yum.repos.d/epel.repo http://192.168.1.11/yum/epel-7.repo
yum install -y epel-release
#wget -O /etc/yum.repos.d/nginx.repo https://files.ysjhlnu.top/service/nginx.repo


# mariadb 
cat > /etc/yum.repos.d/mariadb.repo <<-EOF
[mariadb]
name = MariaDB
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1 
EOF

cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
fs.nr_open = 10245760000
 
EOF

sysctl -p

echo "***设置selinux***"
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

echo "3)清理原来的缓存，重新缓存 "
yum clean all && yum makecache

echo "***安装服务***"
yum install -y gcc epel-release git yum-utils python36 python36-devel python-pip redis nginx mariadb mariadb-devel mariadb-server MariaDB-shared  krb5-devel openssl-devel expect
yum groupinstall "Development Tools" -y

mkdir ~/.pip
cat <<-EOF >> ~/.pip/pip.conf
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host=mirrors.aliyun.com
EOF

#
mkdir ~/.cache && cd ~/.cache
wget http://192.168.1.11/package/jumpserver_pip_cache.tar.gz
tar -xf jumpserver_pip_cache.tar.gz
#

# 配置并载入 Python3 虚拟环境
cd /opt
python3.6 -m venv py3  
source /opt/py3/bin/activate  

echo ""
echo "***** 配置自动进入py3虚拟环境 *****"
#git clone https://github.com/kennethreitz/autoenv.git
#
wget http://192.168.1.11/package/autoenv.tar.gz
tar -xf autoenv.tar.gz
#
echo 'source /opt/autoenv/activate.sh' >> ~/.bashrc

# 下载 Jumpserver
cd /opt/

#if [ ! -d "jumpserver" ];then
#	git clone --depth=1 https://github.com/jumpserver/jumpserver.git
#fi

#
wget http://192.168.1.11/package/jumpserver.tar.gz
tar -xf jumpserver.tar.gz
#

echo "source /opt/py3/bin/activate" > /opt/jumpserver/.env

# 安装依赖 RPM 包
yum -y install $(cat /opt/jumpserver/requirements/rpm_requirements.txt)

# 安装 Python 库依赖
pip install wheel
#pip install --upgrade pip setuptools
pip install -r /opt/jumpserver/requirements/requirements.txt

echo ""
echo "***** 启动redis *****"
sed -i 's/^# requirepass .*/requirepass redis/' /etc/redis.conf
sed -i 's/^# appendonly no/appendonly yes/' /etc/redis.conf
systemctl enable redis
systemctl start redis

echo ""
echo "***** 启动mariadb *****"
systemctl enable mariadb
systemctl start mariadb


# 创建数据库 Jumpserver 并授权

echo -e "\033[31m 你的数据库密码是 ${DB_PASSWORD} \033[0m"
mysql -uroot -e "create database ${DB_NAME} default charset 'utf8'; grant all on ${DB_NAME}.* to '${DB_USER}'@'${DB_HOST}' identified by '$DB_PASSWORD'; flush privileges;"



echo "***** 修改jumpserver配置文件 *****"
cp /opt/jumpserver/config_example.yml /opt/jumpserver/config.yml


sed -i "s/SECRET_KEY:/SECRET_KEY: $SECRET_KEY/g" /opt/jumpserver/config.yml
sed -i "s/BOOTSTRAP_TOKEN:/BOOTSTRAP_TOKEN: $BOOTSTRAP_TOKEN/g" /opt/jumpserver/config.yml
sed -i "s/# DEBUG: true/DEBUG: false/g" /opt/jumpserver/config.yml
sed -i "s/# LOG_LEVEL: DEBUG/LOG_LEVEL: ERROR/g" /opt/jumpserver/config.yml
sed -i "s/# SESSION_EXPIRE_AT_BROWSER_CLOSE: false/SESSION_EXPIRE_AT_BROWSER_CLOSE: true/g" /opt/jumpserver/config.yml
sed -i "s/DB_PASSWORD: /DB_PASSWORD: $DB_PASSWORD/g" /opt/jumpserver/config.yml
sed -i "s/# REDIS_PASSWORD: /REDIS_PASSWORD: $REDIS_PASSWORD/g" /opt/jumpserver/config.yml

echo -e "\033[31m 你的SECRET_KEY是 $SECRET_KEY \033[0m"
echo -e "\033[31m 你的BOOTSTRAP_TOKEN是 $BOOTSTRAP_TOKEN \033[0m"


echo ""
echo "***** 建立jumpserver数据库结构 *****"
cd /opt/jumpserver/requirements
sh /opt/jumpserver/utils/make_migrations.sh

echo ""
echo "*** 启动jumpserver ***"
/opt/jumpserver/jms start all -d

echo "***systemd 管理jumpserver***"
#wget -O /usr/lib/systemd/system/jms.service https://demo.jumpserver.org/download/shell/centos/jms.service
#
wget -O /usr/lib/systemd/system/jms.service http://192.168.1.11/service/jms.service
#
chmod 755 /usr/lib/systemd/system/jms.service
systemctl enable jms  

# coco
cd /opt

#git clone https://github.com/jumpserver/coco.git

#
wget http://192.168.1.11/package/coco.tar.gz
tar -xf coco.tar.gz
#

echo "source /opt/py3/bin/activate" > /opt/coco/.env
yum -y  install $(cat /opt/coco/requirements/rpm_requirements.txt)
pip install -r /opt/coco/requirements/requirements.txt
mkdir /opt/coco/keys /opt/coco/logs
cp /opt/coco/config_example.yml /opt/coco/config.yml	#注意：将BOOTSTRAP_TOKEN设置和Jumpserver的一样
cd /opt/coco/
sed -i "s/BOOTSTRAP_TOKEN: <PleasgeChangeSameWithJumpserver>/BOOTSTRAP_TOKEN: $BOOTSTRAP_TOKEN/g" /opt/coco/config.yml
/opt/coco/cocod start -d

# Web Terminal
cd /opt
if [ ! -f "luna.tar.gz" ];then
	#wget https://github.com/jumpserver/luna/releases/download/1.5.5/luna.tar.gz
	wget http://192.168.1.11/package/luna.tar.gz
fi

tar xf luna.tar.gz
chown -R root:root luna

# windows 组件
rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
#yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm \
yum -y localinstall --nogpgcheck http://192.168.1.11/service/rpmfusion-free-release-7.noarch.rpm \
#  https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm
	http://192.168.1.11/service/rpmfusion-nonfree-release-7.noarch.rpm
yum install -y --nogpgcheck java-1.8.0-openjdk libtool cairo-devel libjpeg-turbo-devel libpng-devel uuid-devel ffmpeg-devel \
  freerdp-devel pango-devel libssh2-devel libtelnet-devel libvncserver-devel pulseaudio-libs-devel openssl-devel libvorbis-devel libwebp-devel ghostscript

if [ -d "/usr/local/lib/freerdp/" ];then
	ln -s /usr/local/lib/freerdp/guacsnd.so /usr/lib64/freerdp/
	ln -s /usr/local/lib/freerdp/guacdr.so /usr/lib64/freerdp/
	ln -s /usr/local/lib/freerdp/guacai.so /usr/lib64/freerdp/
	ln -s /usr/local/lib/freerdp/guacsvc.so /usr/lib64/freerdp/
fi

# guacamole
cd /opt
if [ ! -d "docker-guacamole" ];then
	#git clone https://github.com/jumpserver/docker-guacamole.git
	wget http://192.168.1.11/package/docker-guacamole.tar.gz
	tar -xf docker-guacamole.tar.gz
fi

cd /opt/docker-guacamole/
tar -xf guacamole-server-1.0.0.tar.gz
cd guacamole-server-1.0.0
autoreconf -fi
./configure --with-init-dir=/etc/init.d
make && make install
cd ..
# rm -rf guacamole-server-0.9.14
ldconfig

# Tomcat
mkdir -p /config/guacamole/{lib,extensions} 
cp /opt/docker-guacamole/guacamole-auth-jumpserver-1.0.0.jar /config/guacamole/extensions/guacamole-auth-jumpserver-1.0.0.jar
# guacamole 配置文件
cp /opt/docker-guacamole/root/app/guacamole/guacamole.properties /config/guacamole/
cd /config
if [ ! -f "apache-tomcat-8.5.49.tar.gz" ];then
	#wget http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v8.5.49/bin/apache-tomcat-8.5.49.tar.gz
	wget http://192.168.1.11/package/apache-tomcat-8.5.49.tar.gz
fi
tar -xf apache-tomcat-8.5.49.tar.gz
rm -rf apache-tomcat-8.5.49.tar.gz
mv apache-tomcat-8.5.49 tomcat8
rm -rf /config/tomcat8/webapps/*
# guacamole client
cp /opt/docker-guacamole/guacamole-1.0.0.war /config/tomcat8/webapps/ROOT.war
# 修改默认端口为 8081
sed -i 's/Connector port="8080"/Connector port="8081"/g' `grep 'Connector port="8080"' -rl /config/tomcat8/conf/server.xml`
# 修改 log 等级为 WARNING
sed -i 's/FINE/WARNING/g' `grep 'FINE' -rl /config/tomcat8/conf/logging.properties`

cd /config
if [ ! -f "linux-amd64.tar.gz" ];then
	#wget https://github.com/ibuler/ssh-forward/releases/download/v0.0.5/linux-amd64.tar.gz
	wget http://192.168.1.11/package/linux-amd64.tar.gz
fi
tar -xf linux-amd64.tar.gz -C /bin/
chmod +x /bin/ssh-forward

# http://127.0.0.1:8080 指 jumpserver 访问地址
export JUMPSERVER_SERVER=http://127.0.0.1:8080
echo "export JUMPSERVER_SERVER=http://127.0.0.1:8080" >> ~/.bashrc
export JUMPSERVER_KEY_DIR=/config/guacamole/keys
echo "export JUMPSERVER_KEY_DIR=/config/guacamole/keys" >> ~/.bashrc
export GUACAMOLE_HOME=/config/guacamole
echo "export GUACAMOLE_HOME=/config/guacamole" >> ~/.bashrc

/etc/init.d/guacd start
sh /config/tomcat8/bin/startup.sh

# nginx
rm -f /etc/nginx/nginx.conf
cat <<-EOT >> /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
}
EOT
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
cat << EOT >> /etc/nginx/conf.d/jumpserver.conf
server {
    listen 80;
    server_name default_server;

    client_max_body_size 100m;

    location /luna/ {
        try_files \$uri / /index.html;
        alias /opt/luna/;
    }

    location /media/ {
        add_header Content-Encoding gzip;
        root /opt/jumpserver/data/;
    }

    location /static/ {
        root /opt/jumpserver/data/;
    }

    location /socket.io/ {
        proxy_pass       http://localhost:5000/socket.io/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        access_log off;
    }

    location /coco/ {
        proxy_pass       http://localhost:5000/coco/;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        access_log off;
    }

    location /guacamole/ {
        proxy_pass       http://localhost:8081/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        access_log off;
    }

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOT

systemctl enable nginx
systemctl start nginx
systemctl status nginx

ipaddress=`hostname -I | awk '{print $1}'`
echo "***jumpserver install success***"
echo "***默认账号: admin 密码: admin***"
echo "***http://${address}"
