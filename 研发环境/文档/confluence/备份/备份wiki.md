

```
/var/atlassian/application-data/confluence/backups
```
服务器ip: 192.168.90.238 老版本: 6.7.1

# 备份

```
yum install -y sshpass
mkdir -p  /data/tristan/laashub-soa/executor-backup/sh   && chmod 777 -R /data/tristan/laashub-soa/executor-backup/sh
tee /data/tristan/laashub-soa/executor-backup/sh/wiki.sh <<-'EOF'
#! /bin/bash
sshpass -p '' scp $(ls /var/atlassian/application-data/confluence/backups/*.zip) root@172.30.1.153:/home/backup/wiki/
sshpass -p '' scp $(ls /var/atlassian/application-data/confluence/backups/*.zip) root@192.168.90.196:/home/backup/wiki/
rm -rf /var/atlassian/application-data/confluence/backups/*.zip
EOF
chmod +x /data/tristan/laashub-soa/executor-backup/sh/wiki.sh
crontab -e
0 23 * * * /data/tristan/laashub-soa/executor-backup/sh/wiki.sh
crontab -l
```



目标端

```
mkdir -p /home/backup/wiki && chmod 777 /home/backup/wiki
```



# 还原

