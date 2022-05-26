# 极速安装[¶](https://docs.jumpserver.org/zh/master/install/setup_by_fast/#_1)

说明

全新安装的 Centos7 (7.x)
需要连接 互联网
使用 root 用户执行

- [安装视频](https://www.bilibili.com/video/bv19a4y1i7i9)

## 自动部署[¶](https://docs.jumpserver.org/zh/master/install/setup_by_fast/#_2)

- 安装目录在 /opt/jumpserver-installer-v2.6.1

一键安装 JumpServer

```
curl -sSL https://github.com/jumpserver/jumpserver/releases/download/v2.6.2/quick_start.sh | bash
```

## 手动部署[¶](https://docs.jumpserver.org/zh/master/install/setup_by_fast/#_3)

外置环境要求

- MySQL >= 5.7
- Redis >= 5.0.0

### 下载[¶](https://docs.jumpserver.org/zh/master/install/setup_by_fast/#_4)

下载文件

```
cd /opt
yum -y install wget
wget https://github.com/jumpserver/installer/releases/download/v2.6.1/jumpserver-installer-v2.6.1.tar.gz
tar -xf jumpserver-installer-v2.6.1.tar.gz
cd jumpserver-installer-v2.6.1
export DOCKER_IMAGE_PREFIX=docker.mirrors.ustc.edu.cn
cat config-example.txt
```

<details class="info" open="open" style="box-sizing: inherit; margin: 1.5625em 0px; padding: 0px 0.6rem; overflow: visible; color: rgba(0, 0, 0, 0.87); font-size: 0.64rem; break-inside: avoid; background-color: var(--md-admonition-bg-color); border-left: 0.2rem solid rgb(0, 184, 212); border-radius: 0.1rem; box-shadow: rgba(0, 0, 0, 0.05) 0px 0.2rem 0.5rem, rgba(0, 0, 0, 0.05) 0px 0.025rem 0.05rem; display: block; border-top-color: rgb(0, 184, 212); border-right-color: rgb(0, 184, 212); border-bottom-color: rgb(0, 184, 212); font-family: Roboto, -apple-system, BlinkMacSystemFont, Helvetica, Arial, sans-serif; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; white-space: normal; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;"><summary style="box-sizing: inherit; position: relative; margin: 0px -0.6rem 0px -0.8rem; padding: 0.4rem 1.8rem 0.4rem 2rem; font-weight: 700; background-color: rgba(0, 184, 212, 0.1); border-left: 0.2rem solid rgb(0, 184, 212); display: block; min-height: 1rem; border-top-left-radius: 0.1rem; border-top-right-radius: 0.1rem; cursor: pointer; border-top-color: rgb(0, 184, 212); border-right-color: rgb(0, 184, 212); border-bottom-color: rgb(0, 184, 212); outline: none; -webkit-tap-highlight-color: transparent;">配置文件说明</summary><div class="highlight" style="box-sizing: inherit; margin-bottom: 0.6rem;"><pre id="__code_2" style="box-sizing: inherit; color: var(--md-code-fg-color); font-feature-settings: &quot;kern&quot;; font-family: &quot;Roboto Mono&quot;, SFMono-Regular, Consolas, Menlo, monospace; direction: ltr; position: relative; margin: 1em 0px; line-height: 1.4;"><span style="box-sizing: inherit;"></span><button class="md-clipboard md-icon" title="复制" data-clipboard-target="#__code_2 > code" style="box-sizing: inherit; -webkit-tap-highlight-color: transparent; margin: 0px; padding: 0px; font-size: inherit; background: transparent; border: 0px; position: absolute; top: 0.5em; right: 0.5em; z-index: 1; width: 1.5em; height: 1.5em; color: var(--md-default-fg-color--lightest); border-radius: 0.1rem; cursor: pointer; transition: color 250ms ease 0s;"></button><code style="box-sizing: inherit; color: var(--md-code-fg-color); font-feature-settings: &quot;kern&quot;; font-family: &quot;Roboto Mono&quot;, SFMono-Regular, Consolas, Menlo, monospace; direction: ltr; padding: 0.772059em 1.17647em; font-size: 0.85em; word-break: normal; background-color: var(--md-code-bg-color); border-radius: 0.1rem; -webkit-box-decoration-break: slice; display: block; margin: 0px; overflow: auto; box-shadow: none; touch-action: auto; outline: none; -webkit-tap-highlight-color: transparent;"># 以下设置默认情况下不需要修改

# 说明
#### 这是项目总的配置文件<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">,</span> 会作为环境变量加载到各个容器中
#### 格式必须是 KEY<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>VALUE 不能有空格等

# Compose项目设置
COMPOSE_PROJECT_NAME<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>jms
COMPOSE_HTTP_TIMEOUT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">3600</span>
DOCKER_CLIENT_TIMEOUT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">3600</span>
DOCKER_SUBNET<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">192</span>.<span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">168</span>.<span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">250</span>.<span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">0</span>/<span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">24</span>

## IPV6
DOCKER_SUBNET_IPV6<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">2001</span>:db8:<span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">10</span>::/<span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">64</span>
USE_IPV6<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">0</span>

### 持久化目录<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">,</span> 安装启动后不能再修改<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">,</span> 除非移动原来的持久化到新的位置
VOLUME_DIR<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">/opt/</span>jumpserver

## 是否使用外部MYSQL和REDIS
USE_EXTERNAL_MYSQL<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">0</span>
USE_EXTERNAL_REDIS<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">0</span>

## Nginx 配置，这个Nginx是用来分发路径到不同的服务
HTTP_PORT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">80</span>
HTTPS_PORT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">443</span>
SSH_PORT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">2222</span>

## LB 配置<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">,</span> 这个Nginx是HA时可以启动负载均衡到不同的主机
USE_LB<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">0</span>
LB_HTTP_PORT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">80</span>
LB_HTTPS_PORT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">443</span>
LB_SSH_PORT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">2223</span>

## Task 配置
USE_TASK<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">1</span>

## XPack
USE_XPACK<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">0</span>

# Koko配置
CORE_HOST<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>http:<span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">//</span>core:<span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">8080</span>
ENABLE_PROXY_PROTOCOL<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>true

# Core 配置
### 启动后不能再修改，否则密码等等信息无法解密
SECRET_KEY<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>
BOOTSTRAP_TOKEN<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>
LOG_LEVEL<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>INFO
# SESSION_COOKIE_AGE<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">86400</span>
# SESSION_EXPIRE_AT_BROWSER_CLOSE<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>false

## MySQL数据库配置
DB_ENGINE<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>mysql
DB_HOST<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>mysql
DB_PORT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">3306</span>
DB_USER<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>root
DB_PASSWORD<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>
DB_NAME<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>jumpserver

## Redis配置
REDIS_HOST<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>redis
REDIS_PORT<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">6379</span>
REDIS_PASSWORD<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>

### Keycloak 配置方式
### AUTH_OPENID<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>true
### BASE_SITE_URL<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>https:<span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">//</span>jumpserver.company.<span class="k" style="box-sizing: inherit; color: var(--md-code-hl-keyword-color);">com</span>/
### AUTH_OPENID_SERVER_URL<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>https:<span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">//</span>keycloak.company.<span class="k" style="box-sizing: inherit; color: var(--md-code-hl-keyword-color);">com</span>/auth
### AUTH_OPENID_REALM_NAME<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="nb" style="box-sizing: inherit; color: var(--md-code-hl-constant-color);">cmp</span>
### AUTH_OPENID_CLIENT_ID<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>jumpserver
### AUTH_OPENID_CLIENT_SECRET<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>
### AUTH_OPENID_SHARE_SESSION<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>true
### AUTH_OPENID_IGNORE_SSL_VERIFICATION<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>true

# Guacamole 配置
JUMPSERVER_SERVER<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>http:<span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">//</span>core:<span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">8080</span>
JUMPSERVER_KEY_DIR<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">/config/</span>guacamole<span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">/data/</span><span class="nb" style="box-sizing: inherit; color: var(--md-code-hl-constant-color);">key</span>/
JUMPSERVER_RECORD_PATH<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">/config/</span>guacamole<span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">/data/</span>record/
JUMPSERVER_DRIVE_PATH<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">/config/</span>guacamole<span class="sr" style="box-sizing: inherit; color: var(--md-code-hl-special-color);">/data/</span>drive/
JUMPSERVER_ENABLE_DRIVE<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>true
JUMPSERVER_CLEAR_DRIVE_SESSION<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>true
JUMPSERVER_CLEAR_DRIVE_SCHEDULE<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span><span class="m" style="box-sizing: inherit; color: var(--md-code-hl-number-color);">24</span>

# Mysql 容器配置
MYSQL_ROOT_PASSWORD<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>
MYSQL_DATABASE<span class="p" style="box-sizing: inherit; color: var(--md-code-hl-punctuation-color);">=</span>jumpserver
</code></pre></div></details>

### 安装[¶](https://docs.jumpserver.org/zh/master/install/setup_by_fast/#_5)

Install

```
./jmsctl.sh install
```

### 帮助[¶](https://docs.jumpserver.org/zh/master/install/setup_by_fast/#_6)

Help

```
./jmsctl.sh -h
```

### 升级[¶](https://docs.jumpserver.org/zh/master/install/setup_by_fast/#_7)

Upgrade

```
./jmsctl.sh check_update
```

后续的使用请参考 [安全建议](https://docs.jumpserver.org/zh/master/install/install_security/) [快速入门](https://docs.jumpserver.org/zh/master/admin-guide/quick_start/)