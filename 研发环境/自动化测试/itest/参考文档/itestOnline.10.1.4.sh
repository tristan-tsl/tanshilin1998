#!/bin/bash
#mkdir -p /root/itest/mysql/mysql
#cp  my.cnf /root/itest/mysql/
#docker run --name itest_mysql_server -t -p 6033:3306 -v /root/itest/mysql/my.cnf:/etc/mysql/conf.d/mysql.cnf -v /root/itest/mysql/mysql:/var/lib/mysql -v /etc/localtime:/etc/localtime -d registry.cn-shenzhen.aliyuncs.com/iitest/mysql:5.7

echo "pull and run itest_mysql_server"
docker run -d --name itest_mysql_server -p 6033:3306 -v /etc/localtime:/etc/localtime registry.cn-shenzhen.aliyuncs.com/iitest/mysql:5.7.4
sleep 15
echo "pull and run itest_jmeter_server"
docker run --privileged -d --name itest_jmeter_server -p 0.0.0.0:8020:8080  --link itest_mysql_server:itest-mysql-server  registry.cn-shenzhen.aliyuncs.com/iitest/jmeter:10.1.4
docker exec itest_jmeter_server tar -xvf  /usr/local/tomcat/webapps/jmeter/jmeter/apache-jmeter-jre.tar.gz  -C  /usr/local/tomcat/webapps/jmeter/jmeter/
echo "pull and run itest_web_server" 

docker run --privileged -d --name itest_web_server -p 0.0.0.0:8010:8080 -p 8062:8062 -p 8063:8063 --link itest_mysql_server:itest-mysql-server --link itest_jmeter_server:jmeter  registry.cn-shenzhen.aliyuncs.com/iitest/itest:10.1.4


echo   "access port 8010  "
echo   "login  with admin  ,pwd admin  "
echo   "any question  please QQ qun  2155613  "