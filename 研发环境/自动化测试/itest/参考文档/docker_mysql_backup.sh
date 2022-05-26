#!/bin/bash
docker stop itest_web_server
docker stop itest_jmeter_server
docker exec -it itest_mysql_server /bin/bash -c 'cd /var/lib && tar -zcf mysql.tar.gz mysql'
docker cp itest_mysql_server:/var/lib/mysql.tar.gz ./
docker start   itest_web_server
docker start   itest_jmeter_server


