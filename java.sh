#!/bin/bash
# by tansi 2020.1.5
# auto deploy java enviroment

jdk_url=http://file.ysjhlnu.top/software/jdk-8u202-linux-x64.tar.gz
java_path=/usr/local/java
yum install -y wget vim
mkdir "${java_path}"
cd /usr/local/src
wget "${jdk_url}"
tar -zxf jdk-8u202-linux-x64.tar.gz -C "${java_path}"

cat >> /etc/profile<<-EOF
export JAVA_HOME=${java_path}/jdk1.8.0_202
export CLASS_PATH=\${JAVA_HOME}/jre/lib:\${JAVA_HOME}/lib
export PATH=\${PATH}:\${JAVA_HOME}/bin
EOF

source /etc/profile
java -version
echo "*** java 安装完成***"


