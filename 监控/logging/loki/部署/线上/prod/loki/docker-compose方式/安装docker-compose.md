建议不要在服务器上直接下载docker-compose, 而是上传二进制文件上去

```
echo "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)"
# 在网络良好的地方下载上面那个文件, 然后上传到服务器中
mv -f docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
```

