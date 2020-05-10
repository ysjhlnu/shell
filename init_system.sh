#!/bin/bash


if [ "$(whoami)" != 'root' ];then
	echo -e "\033[32mplease use root account run this script\033[0m"
fi

init(){
	# 同步时间
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	date
	yum install -y vim wget curl 
}

yum_config(){
	cd /etc/yum.repos.d/ && mkdir /etc/yum.repos.d/backup && mv -f *.repo backup/

	wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

	yum clean all && yum makecache

	yum -y install iotop iftop net-tools lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel bash-completion
}

disable_selinux(){
	sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	timedatectl set-local-rtc 1 && timedatectl set-timezone Asia/Shanghai
	yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service
}

main(){
	init
	clear
	PS3="Please select num:[3 is exit]: "
	select num in yum_config disable_selinux quit
	do
		case $num in 
			yum_config)
				yum_config
			;;
			disable_selinux)
				disable_selinux
			;;
			quit)
				break
			;;
			*)
				echo -e "\033[32mselect num error,please try again!\033[0m"
			;;
		esac
	done
}

main
