#!/bin/bash
# by tansi 2019/12/19
# auto install zabbix agent 
PACKAGE_SRC=/usr/local/src
PACKAGE_NAME=zabbix-4.0.13.tar.gz
ZAB_URL=https://nchc.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/4.0.13/zabbix-4.0.13.tar.gz
SERVER_IP=192.168.1.6
LOCAL_IP="`hostname-I` | awk '{print $1}'"
echo "***编译安装zabbix agent***"
echo "***创建组和用户***"
groupadd zabbix
useradd -s /sbin/nologin -g zabbix -M zabbix
setenforce 0
systemctl stop firewalld
systemctl disable firewalld

echo "***安装依赖包***"
yum install -y gcc gcc-c++ make pcre-devel

echo "***下载${PACKAGE_NAME}源码包***"
cd "${PACKAGE_SRC}"
if [ ! -f "${PACKAGE_NAME}" ];then
	wget "${ZAB_URL}" 
fi

tar -xf "${PACKAGE_NAME}"
cd zabbix-4.0.13
./configure --prefix=/usr/local/zabbix --enable-agent

make && make install
if [ $? -eq 0 ];then
	echo "***zabbix agentd 编译完成***"
fi 

chown -R zabbix:zabbix /usr/local/zabbix/
cat >>/etc/profile <<-EOF
export PATH=$PATH:/usr/local/zabbix/bin/:/usr/local/zabbix/sbin/
EOF
source /etc/profile

sed -i "s/Server=127.0.0.1/Server=${SERVER_IP}/g"  /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i "s/Hostname=.*/Hostname=${LOCAL_IP}/g" /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=${SERVER_IP}/g" /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i "s/# HostnameItem=system.hostname/HostnameItem=system.hostname/g" /usr/local/zabbix/etc/zabbix_agentd.conf

cat >/usr/lib/systemd/system/zabbix-agentd.service <<-EOF
[Unit]
Description=zabbix-agentd
After=network.target

[Service]
Environment="CONFFILE=/usr/local/zabbix/etc/zabbix_agentd.conf"
Type=forking
Restart=on-failure
PIDFile=/tmp/zabbix_agentd.pid
KillMode=control-group
ExecStart=/usr/local/zabbix/sbin/zabbix_agentd -c "\$CONFFILE"
ExecStop=/bin/kill -SIGTERM "\$MAINPID"
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable zabbix-agentd
systemctl start zabbix-agentd
if [ $? -ne 0 ];then
	pkill zabbix_agentd
fi
echo "zabbix agentd 安装完成"
