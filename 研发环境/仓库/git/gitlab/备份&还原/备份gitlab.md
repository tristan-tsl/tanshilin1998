# 备份

服务器ip: 192.168.90.190 老gitlab版本: 11.8.1 (657d508)

定时备份

```
yum install -y sshpass
mkdir -p  /data/tristan/laashub-soa/executor-backup/sh   && chmod 777 -R /data/tristan/laashub-soa/executor-backup/sh
tee /data/tristan/laashub-soa/executor-backup/sh/gitlab.sh <<-'EOF'
rm -rf /var/opt/gitlab/backups/*.tar
/opt/gitlab/bin/gitlab-rake gitlab:backup:create
sshpass -p '' scp $(ls /var/opt/gitlab/backups/*.tar) root@172.30.1.153:/home/backup/gitlab
sshpass -p '' scp $(ls /var/opt/gitlab/backups/*.tar) root@192.168.90.196:/home/backup/gitlab
EOF
chmod +x /data/tristan/laashub-soa/executor-backup/sh/gitlab.sh
crontab -e
0 2 * * * sh /data/tristan/laashub-soa/executor-backup/sh/gitlab.sh
crontab -l
```



目标端

```
mkdir -p /home/backup/gitlab && chmod 777 /home/backup/gitlab
```



# 还原

```
1635338334_2021_10_27_11.8.1_gitlab_backup.tar
通过alt+p上传文件
mv ~/1635338334_2021_10_27_11.8.1_gitlab_backup.tar /k8slpv/registry-gitlab/data/backups/

kubectl -n registry exec -it gitlab-0 -c gitlab -- bash
chmod 777 /var/opt/gitlab/backups/1635338334_2021_10_27_11.8.1_gitlab_backup.tar

gitlab-rake gitlab:backup:restore BACKUP=1635338334_2021_10_27_11.8.1
```



# 其他



跨版本升级的时候,需要渐进, 参考文档: https://docs.gitlab.com/ee/update/index.html

思路: 先升级到最高兼容版本, 然后重试几次直到升级到最高版本

例如: 

目前我们是 `11.8.1` -> [`11.11.8`](https://docs.gitlab.com/ee/update/index.html#1200) -> `12.0.12` -> [`12.1.17`](https://docs.gitlab.com/ee/update/index.html#1210) -> `12.10.14` -> `13.0.14` -> [`13.1.11`](https://docs.gitlab.com/ee/update/index.html#1310) -> [`13.8.8`](https://docs.gitlab.com/ee/update/index.html#1388) -> [latest `13.12.Z`](https://about.gitlab.com/releases/categories/releases/) -> [latest `14.0.Z`](https://docs.gitlab.com/ee/update/index.html#1400) -> [`14.1.Z`](https://docs.gitlab.com/ee/update/index.html#1410) -> [latest `14.Y.Z`](https://about.gitlab.com/releases/categories/releases/)



为了暂时减少不必要的麻烦, 暂时还是不升级版本了
