#!/bin/bash
# by tansi 2019/12/14
# auto deploy java enviroment

jkd_url=""
tomcat_url=""
source_path="/usr/local/src"
jdk_package="jdk-8u202-linux-x64.tar.gz"
jdk_version="jdk1.8.0_202"
java_path="/usr/local/java"
tomcat_package="apache-tomcat-8.5.49.tar.gz"
tomcat_name="apache-tomcat-8.5.49"
tomcat_path="/usr/local/tomcat-base"

mkdir "${tomcat_path}"
mkdir "${java_path}"
cd "${source_path}"
tar -zxf "${jdk_package}" -C "${java_path}"


cat >>/etc/profile<<-EOF
export JAVA_HOME=/usr/local/java/"${jdk_version}"
export CLASS_PATH="\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib"
export PATH=$PATH:\$JAVA_HOME/bin
EOF

source /etc/profile
java -version

cd "${source_path}"

tar -xf "${tomcat_package}"  -C "${tomcat_path}"
cd "${tomcat_path}"
mv "${tomcat_name}"/* ./

echo "***启动tomcat***"
/usr/local/tomcat-base/bin/startup.sh
