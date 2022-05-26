#!/bin/bash
docker stop itest_web_server
docker stop itest_jmeter_server
docker cp mysql.tar.gz itest_mysql_server:/var/lib/
docker exec -it itest_mysql_server /bin/bash -c 'cd /var/lib && tar -zxvf mysql.tar.gz && rm -rf mysql.tar.gz'
docker restart itest_mysql_server
docker restart itest_web_server
docker start   itest_jmeter_server