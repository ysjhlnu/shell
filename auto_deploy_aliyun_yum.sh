#!/bin/bash
#by tansi 2019/12/8
# edit yum source 

echo "1.禁用 yum插件 fastestmirror"
yum install -y wget 

echo "1)修改插件的配置文件"

cp /etc/yum/pluginconf.d/fastestmirror.conf /etc/yum/pluginconf.d/fastestmirror.conf.bak 

sed -ri 's/^enabled=.*/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf

echo "2)修改yum的配置文件"

cp /etc/yum.conf /etc/yum.conf.bak

sed -ri 's/^plugins=.*/plugins=0/' /etc/yum.conf


echo "2.获取阿里云 repo"

cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak

wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

if [ -f "/etc/yum.repos.d/epel.repo" ];then
	cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak	
fi

wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

echo "3.清理原来的缓存，重新缓存 "

yum clean all

yum makecache

