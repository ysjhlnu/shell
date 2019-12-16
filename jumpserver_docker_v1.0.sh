#!/bin/bash
# by tansi 2019/12/16
# auto install jumpserver
if [ "$SECRET_KEY" = "" ]; then SECRET_KEY=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 50`; echo "SECRET_KEY=$SECRET_KEY" >> ~/.bashrc; echo $SECRET_KEY; else echo $SECRET_KEY; fi
if [ "$BOOTSTRAP_TOKEN" = "" ]; then BOOTSTRAP_TOKEN=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`; echo "BOOTSTRAP_TOKEN=$BOOTSTRAP_TOKEN" >> ~/.bashrc; echo $BOOTSTRAP_TOKEN; else echo $BOOTSTRAP_TOKEN; fi

#启动docker

docker run --name mysql-server -t \
    --hostname mysql-server \
    --restart=always \
    -v /etc/localtime:/etc/localtime \
    -v /opt/docker/mysql/:/var/lib/mysql \
    -e MYSQL_DATABASE="jumpserver" \
    -e MYSQL_USER="jumpserver" \
    -e MYSQL_PASSWORD="jumpserver" \
    -e MYSQL_ROOT_PASSWORD="password" \
    -p 3306:3306 \
    -d mysql:5.7.28 \
    --character-set-server=utf8 --collation-server=utf8_bin
if [ $? -eq 0 ];then
	echo "mysql部署成功"
fi	
	
docker run --name redis-server -t \
	--hostname redis-server \
	--restart=always \
	-v /etc/localtime:/etc/localtime \
	-d redis:latest

if [ $? -eq 0 ];then
	echo "redis部署成功"
fi

docker run --name jms_all -t \
	--hostname jms_all \
	--restart=always \
	-v /etc/localtime:/etc/localtime \
	-p 80:80 \
	-p 2222:2222 \
	-e SECRET_KEY=$SECRET_KEY \
	-e BOOTSTRAP_TOKEN=$BOOTSTRAP_TOKEN \
	-e DB_HOST="mysql-server" \
	-e DB_PORT=3306 \
	-e DB_NAME="jumpserver" \
	-e DB_USER="jumpserver" \
	-e DB_PASSWORD="jumpserver" \
	--link mysql-server:mysql \
	-e REDIS_HOST="redis-server" \
	-e REDIS_PORT="6379" \
	--link redis-server:redis \
	-d jumpserver/jms_all:latest
if [ $? -eq 0 ];then
	echo "jumpserver部署成功"
fi
echo "http://`hostname -I`"
