## [unpkg +verdaccio+ webpack 联邦实现多版本控制](https://www.cnblogs.com/rongfengliang/p/14411836.html)

参考了jherr 的webpack 联邦多版本，基于unpkg 以及verdaccio实现一个私有版本的测试环境

## 环境准备

- docker-compose

```
version: "3"
services: 
    unpkg:
      image: dalongrong/unpkg:http-env
      environment: 
      - "NPM_REGISTRY_URL=http://npm-registry:4873"
      ports: 
      - "8080:8080"
    npm-registry:
      image: verdaccio/verdaccio
      ports: 
      - "4873:4873"
```

简单说明:dalongrong/unpkg:http-env 是基于官方修改的一个版本，支持http以及基于环境变量配置npm repo，具体可以参考
https://github.com/rongfengliang/unpkg

## 使用说明

- fork jherr 参考代码

```
git clone https://github.com/jherr/unpkg-mf-react-finished
```

- 添加本地npm 配置
  .npmrc

 

```
registry=http://localhost:4873
```

- 使用
  首先构建jherr-mf-slider，然后publish npm私服(参考提示操作)

 

```
cd jherr-mf-slider 
yarn && yarn build && yarn publish
```

修改react-unpkg-mf-consumer-starter
package.json 修改端口 (8080 冲突)

 

```
"scripts": {
    "build": "webpack --mode production",
    "build:dev": "webpack --mode development",
    "build:start": "cd dist && PORT=8090 npx serve",
    "start": "webpack serve",
    "start:live": "webpack-dev-server --open --mode development --liveReload",
    "docker:build": "docker build . -t wp5-starter",
    "docker:run": "docker run -p 8090:8090 wp5-starter"
  }
```

webpack.config.js 修改（主要是默认unpkg 地址）

```
const HtmlWebPackPlugin = require("html-webpack-plugin");
const ModuleFederationPlugin = require("webpack/lib/container/ModuleFederationPlugin");
const { camelCase } = require("camel-case");
```

 

```
const federatedRemotes = {
  "jherr-mf-slider": "1.0.2",
};
const deps = {
  ...federatedRemotes,
  ...require("./package.json").dependencies,
};
```

 

```
const unpkgRemote = (name) =>
  `${camelCase(name)}@http://localhost:8080/${name}@${
    deps[name]
  }/dist/browser/remote-entry.js`;
const remotes = Object.keys(federatedRemotes).reduce(
  (remotes, lib) => ({
    ...remotes,
    [lib]: unpkgRemote(lib),
  }),
  {}
);
```

 

```
module.exports = {
  output: {
    publicPath: "http://localhost:8090/",
  },
```

 

```
  resolve: {
    extensions: [".jsx", ".js", ".json"],
  },
```

 

```
  devServer: {
    port: 8090,
  },
```

 

```
  module: {
    rules: [
      {
        test: /\.m?js/,
        type: "javascript/auto",
        resolve: {
          fullySpecified: false,
        },
      },
      {
        test: /\.css$/i,
        use: ["style-loader", "css-loader"],
      },
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
        },
      },
    ],
  },
```

 

```
  plugins: [
    new ModuleFederationPlugin({
      remotes,
      shared: {
        ...deps,
        react: {
          singleton: true,
          requiredVersion: deps.react,
        },
        "react-dom": {
          singleton: true,
          requiredVersion: deps["react-dom"],
        },
      },
    }),
    new HtmlWebPackPlugin({
      template: "./src/index.html",
    }),
  ],
};
```

- 运行

```
cd react-unpkg-mf-consumer-starter
yarn 
yarn start
```

说明: 修改webpack 使用不同版本，我们可以看到效果

```
const federatedRemotes = {
  "jherr-mf-slider": "1.0.2",
};
```

## 说明

以上只是一些工具集成的使用，webpack 的ModuleFederationPlugin 是一个很不错的微前端实践方案

## 参考资料

https://github.com/mjackson/unpkg
https://github.com/jdxcode/npm-register
https://github.com/verdaccio/verdaccio
https://github.com/rongfengliang/unpkg
https://github.com/jherr/unpkg-mf-react-finished
[https://github.com/rongfengliang/unpkg_verdaccio_webpack_federated](https://github.com/jherr/unpkg-mf-react-finished)

分类: [webpack](https://www.cnblogs.com/rongfengliang/category/1109898.html), [web 构建工具](https://www.cnblogs.com/rongfengliang/category/1108713.html), [云运维&&云架构](https://www.cnblogs.com/rongfengliang/category/1107309.html), [web框架](https://www.cnblogs.com/rongfengliang/category/789574.html)