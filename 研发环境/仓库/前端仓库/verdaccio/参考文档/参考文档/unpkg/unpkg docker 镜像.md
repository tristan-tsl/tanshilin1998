# unpkg docker 镜像

 原创

[dalongrong](https://blog.51cto.com/rongfengliang)2021-07-18 14:52:48©著作权

*阅读数*11

## unpkg docker 镜像

目的很简单，因为unpkg 的一些设计上可以解决我们web 开发中多版本的问题，而且unpkg 是开源的，所以
自己制作一个docker 镜像方便使用

## 构建

- clone 代码

 

```
git clone https://github.com/mjackson/unpkg.git1.
```

- 修改代码
  主要是去掉关于cloudflare 部分的，我们不需要,需要修改的代码为modules/createServer.js
  删除以下代码

 

```
- import serveStats from './actions/serveStats.js';1.
- app.get('/api/stats', serveStats);1.
```

- 构建

```
yarn 1.
yarn build1.
```

## Dockerfile

注意目前需要使用node 12（代码部分固定的）

```
FROM node:12.20.2-alpine3.121.
WORKDIR /app1.
COPY package.json /app/package.json 1.
COPY server.js /app/server.js1.
COPY public/ /app/public/1.
RUN export NODE_ENV=production1.
RUN yarn 1.
EXPOSE 80801.
CMD [ "yarn","serve" ]1.
```

## 使用

- 运行
  使用已经构建好的docker 镜像

 

```
docker run -d -p 8080:8080 dalongrong/unpkg1.
```

- 效果

![watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=](https://s4.51cto.com/images/blog/202107/18/2c48f60537e92c02bdd427658b228690.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

 

 


![watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=](https://s4.51cto.com/images/blog/202107/18/d8ab84039085783ac8c6bcbb21fa2f30.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

 

 

## 说明

利用unpkg的一些处理npm的特性，我们可以方便的管理我们的web 应用，是一个很不错的选择，同时webpack联邦应用的多版本开发
基于unpkg解决也是一个不错的选择

## 参考资料

https://github.com/mjackson/unpkg