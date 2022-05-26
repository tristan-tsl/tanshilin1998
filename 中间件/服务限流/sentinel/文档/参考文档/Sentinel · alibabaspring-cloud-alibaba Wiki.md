# Sentinel

Eric Zhao edited this page on 15 Jan · [34 revisions](https://github.com/alibaba/spring-cloud-alibaba/wiki/Sentinel/_history)

## Spring Cloud Alibaba Sentinel

### Sentinel 介绍

随着微服务的流行，服务和服务之间的稳定性变得越来越重要。 [Sentinel](https://github.com/alibaba/Sentinel) 以流量为切入点，从流量控制、熔断降级、系统负载保护等多个维度保护服务的稳定性。

[Sentinel](https://github.com/alibaba/Sentinel) 具有以下特征:

- **丰富的应用场景**： Sentinel 承接了阿里巴巴近 10 年的双十一大促流量的核心场景，例如秒杀（即突发流量控制在系统容量可以承受的范围）、消息削峰填谷、实时熔断下游不可用应用等。
- **完备的实时监控**： Sentinel 同时提供实时的监控功能。您可以在控制台中看到接入应用的单台机器秒级数据，甚至 500 台以下规模的集群的汇总运行情况。
- **广泛的开源生态**： Sentinel 提供开箱即用的与其它开源框架/库的整合模块，例如与 Spring Cloud、Dubbo、gRPC 的整合。您只需要引入相应的依赖并进行简单的配置即可快速地接入 Sentinel。
- **完善的 SPI 扩展点**： Sentinel 提供简单易用、完善的 SPI 扩展点。您可以通过实现扩展点，快速的定制逻辑。例如定制规则管理、适配数据源等。

### 如何使用 Sentinel

如果要在您的项目中引入 Sentinel，使用 group ID 为 `com.alibaba.cloud` 和 artifact ID 为 `spring-cloud-starter-alibaba-sentinel` 的 starter。

```
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>
```

下面这个例子就是一个最简单的使用 Sentinel 的例子:

```
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(ServiceApplication.class, args);
    }
}

@Service
public class TestService {

    @SentinelResource(value = "sayHello")
    public String sayHello(String name) {
        return "Hello, " + name;
    }
}

@RestController
public class TestController {

    @Autowired
    private TestService service;

    @GetMapping(value = "/hello/{name}")
    public String apiHello(@PathVariable String name) {
        return service.sayHello(name);
    }
}
```

`@SentinelResource` 注解用来标识资源是否被限流、降级。上述例子上该注解的属性 `sayHello` 表示资源名。

`@SentinelResource` 还提供了其它额外的属性如 `blockHandler`，`blockHandlerClass`，`fallback` 用于表示限流或降级的操作（注意有方法签名要求），更多内容可以参考 [Sentinel 注解支持文档](https://github.com/alibaba/Sentinel/wiki/注解支持)。若不配置 `blockHandler`、`fallback` 等函数，则被流控降级时方法会直接抛出对应的 BlockException；若方法未定义 `throws BlockException` 则会被 JVM 包装一层 `UndeclaredThrowableException`。

> 注：一般推荐将 `@SentinelResource` 注解加到服务实现上，而在 Web 层直接使用 Spring Cloud Alibaba 自带的 Web 埋点适配。Sentinel Web 适配同样支持配置自定义流控处理逻辑，参考 [相关文档](https://github.com/alibaba/Sentinel/wiki/主流框架的适配#web-适配)。

以上例子都是在 Web Servlet 环境下使用的。Sentinel 目前已经支持 Spring WebFlux，需要配合 `spring-boot-starter-webflux` 依赖触发 sentinel-starter 中 WebFlux 相关的自动化配置。

```
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(ServiceApplication.class, args);
    }

}

@RestController
public class TestController {

    @GetMapping("/mono")
    public Mono<String> mono() {
	return Mono.just("simple string");
    }

}
```

当 Spring WebFlux 应用接入 Sentinel starter 后，所有的 URL 就自动成为 Sentinel 中的埋点资源，可以针对某个 URL 进行流控。

##### Sentinel 控制台

Sentinel 控制台提供一个轻量级的控制台，它提供机器发现、单机资源实时监控、集群资源汇总，以及规则管理的功能。您只需要对应用进行简单的配置，就可以使用这些功能。

**注意**: 集群资源汇总仅支持 500 台以下的应用集群，有大概 1 - 2 秒的延时。

![50678855 aa6e9700 103b 11e9 83de 2a33e580325f](Sentinel · alibabaspring-cloud-alibaba Wiki.assets/50678855-aa6e9700-103b-11e9-83de-2a33e580325f.png)

Figure 1. Sentinel Dashboard

开启该功能需要3个步骤：

###### 获取控制台

您可以从 [release 页面](https://github.com/alibaba/Sentinel/releases) 下载最新版本的控制台 jar 包。

您也可以从最新版本的源码自行构建 Sentinel 控制台：

- 下载 [控制台](https://github.com/alibaba/Sentinel/tree/master/sentinel-dashboard) 工程
- 使用以下命令将代码打包成一个 fat jar: `mvn clean package`

###### 启动控制台

Sentinel 控制台是一个标准的 Spring Boot 应用，以 Spring Boot 的方式运行 jar 包即可。

```
java -Dserver.port=8080 -Dcsp.sentinel.dashboard.server=localhost:8080 -Dproject.name=sentinel-dashboard -jar sentinel-dashboard.jar
```

如若8080端口冲突，可使用 `-Dserver.port=新端口` 进行设置。

#### 配置控制台信息

application.yml

```
spring:
  cloud:
    sentinel:
      transport:
        port: 8719
        dashboard: localhost:8080
```

这里的 `spring.cloud.sentinel.transport.port` 端口配置会在应用对应的机器上启动一个 Http Server，该 Server 会与 Sentinel 控制台做交互。比如 Sentinel 控制台添加了一个限流规则，会把规则数据 push 给这个 Http Server 接收，Http Server 再将规则注册到 Sentinel 中。

更多 Sentinel 控制台的使用及问题参考： [Sentinel 控制台文档](https://github.com/alibaba/Sentinel/wiki/控制台) 以及 [Sentinel FAQ](https://github.com/alibaba/Sentinel/wiki/FAQ)

### Feign 支持

Sentinel 适配了 [Feign](https://github.com/OpenFeign/feign) 组件。如果想使用，除了引入 `spring-cloud-starter-alibaba-sentinel` 的依赖外还需要 2 个步骤：

- 配置文件打开 Sentinel 对 Feign 的支持：`feign.sentinel.enabled=true`
- 加入 `spring-cloud-starter-openfeign` 依赖使 Sentinel starter 中的自动化配置类生效：

```
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

这是一个 `FeignClient` 的简单使用示例：

```
@FeignClient(name = "service-provider", fallback = EchoServiceFallback.class, configuration = FeignConfiguration.class)
public interface EchoService {
    @RequestMapping(value = "/echo/{str}", method = RequestMethod.GET)
    String echo(@PathVariable("str") String str);
}

class FeignConfiguration {
    @Bean
    public EchoServiceFallback echoServiceFallback() {
        return new EchoServiceFallback();
    }
}

class EchoServiceFallback implements EchoService {
    @Override
    public String echo(@PathVariable("str") String str) {
        return "echo fallback";
    }
}
```

| Note | Feign 对应的接口中的资源名策略定义：httpmethod:protocol://requesturl。`@FeignClient` 注解中的所有属性，Sentinel 都做了兼容。 |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

`EchoService` 接口中方法 `echo` 对应的资源名为 `GET:http://service-provider/echo/{str}`。

### RestTemplate 支持

Spring Cloud Alibaba Sentinel 支持对 `RestTemplate` 的服务调用使用 Sentinel 进行保护，在构造 `RestTemplate` bean的时候需要加上 `@SentinelRestTemplate` 注解。

```
@Bean
@SentinelRestTemplate(blockHandler = "handleException", blockHandlerClass = ExceptionUtil.class)
public RestTemplate restTemplate() {
    return new RestTemplate();
}
```

`@SentinelRestTemplate` 注解的属性支持限流(`blockHandler`, `blockHandlerClass`)和降级(`fallback`, `fallbackClass`)的处理。

其中 `blockHandler` 或 `fallback` 属性对应的方法必须是对应 `blockHandlerClass` 或 `fallbackClass` 属性中的静态方法。

该方法的参数跟返回值跟 `org.springframework.http.client.ClientHttpRequestInterceptor#interceptor` 方法一致，其中参数多出了一个 `BlockException` 参数用于获取 Sentinel 捕获的异常。

比如上述 `@SentinelRestTemplate` 注解中 `ExceptionUtil` 的 `handleException` 属性对应的方法声明如下：

```
public class ExceptionUtil {
    public static ClientHttpResponse handleException(HttpRequest request, byte[] body, ClientHttpRequestExecution execution, BlockException exception) {
        ...
    }
}
```

| Note | 应用启动的时候会检查 `@SentinelRestTemplate` 注解对应的限流或降级方法是否存在，如不存在会抛出异常 |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

`@SentinelRestTemplate` 注解的限流(`blockHandler`, `blockHandlerClass`)和降级(`fallback`, `fallbackClass`)属性不强制填写。

当使用 `RestTemplate` 调用被 Sentinel 熔断后，会返回 `RestTemplate request block by sentinel` 信息，或者也可以编写对应的方法自行处理返回信息。这里提供了 `SentinelClientHttpResponse` 用于构造返回信息。

Sentinel RestTemplate 限流的资源规则提供两种粒度：

- `httpmethod:schema://host:port/path`：协议、主机、端口和路径
- `httpmethod:schema://host:port`：协议、主机和端口

| Note | 以 `https://www.taobao.com/test` 这个 url 并使用 GET 方法为例。对应的资源名有两种粒度，分别是 `GET:https://www.taobao.com` 以及 `GET:https://www.taobao.com/test` |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

### 动态数据源支持

`SentinelProperties` 内部提供了 `TreeMap` 类型的 `datasource` 属性用于配置数据源信息。

比如配置 4 个数据源：

```
spring.cloud.sentinel.datasource.ds1.file.file=classpath: degraderule.json
spring.cloud.sentinel.datasource.ds1.file.rule-type=flow

#spring.cloud.sentinel.datasource.ds1.file.file=classpath: flowrule.json
#spring.cloud.sentinel.datasource.ds1.file.data-type=custom
#spring.cloud.sentinel.datasource.ds1.file.converter-class=com.alibaba.cloud.examples.JsonFlowRuleListConverter
#spring.cloud.sentinel.datasource.ds1.file.rule-type=flow

spring.cloud.sentinel.datasource.ds2.nacos.server-addr=localhost:8848
spring.cloud.sentinel.datasource.ds2.nacos.data-id=sentinel
spring.cloud.sentinel.datasource.ds2.nacos.group-id=DEFAULT_GROUP
spring.cloud.sentinel.datasource.ds2.nacos.data-type=json
spring.cloud.sentinel.datasource.ds2.nacos.rule-type=degrade

spring.cloud.sentinel.datasource.ds3.zk.path = /Sentinel-Demo/SYSTEM-CODE-DEMO-FLOW
spring.cloud.sentinel.datasource.ds3.zk.server-addr = localhost:2181
spring.cloud.sentinel.datasource.ds3.zk.rule-type=authority

spring.cloud.sentinel.datasource.ds4.apollo.namespace-name = application
spring.cloud.sentinel.datasource.ds4.apollo.flow-rules-key = sentinel
spring.cloud.sentinel.datasource.ds4.apollo.default-flow-rule-value = test
spring.cloud.sentinel.datasource.ds4.apollo.rule-type=param-flow
```

这种配置方式参考了 Spring Cloud Stream Binder 的配置，内部使用了 `TreeMap` 进行存储，comparator 为 `String.CASE_INSENSITIVE_ORDER` 。

| Note | d1, ds2, ds3, ds4 是 `ReadableDataSource` 的名字，可随意编写。后面的 `file` ，`zk` ，`nacos` , `apollo` 就是对应具体的数据源，它们后面的配置就是这些具体数据源各自的配置。注意数据源的依赖要单独引入（比如 `sentinel-datasource-nacos`)。 |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

每种数据源都有两个共同的配置项： `data-type`、 `converter-class` 以及 `rule-type`。

`data-type` 配置项表示 `Converter` 类型，Spring Cloud Alibaba Sentinel 默认提供两种内置的值，分别是 `json` 和 `xml` (不填默认是json)。 如果不想使用内置的 `json` 或 `xml` 这两种 `Converter`，可以填写 `custom` 表示自定义 `Converter`，然后再配置 `converter-class` 配置项，该配置项需要写类的全路径名(比如 `spring.cloud.sentinel.datasource.ds1.file.converter-class=com.alibaba.cloud.examples.JsonFlowRuleListConverter`)。

`rule-type` 配置表示该数据源中的规则属于哪种类型的规则(`flow`，`degrade`，`authority`，`system`, `param-flow`, `gw-flow`, `gw-api-group`)。

| Note | 当某个数据源规则信息加载失败的情况下，不会影响应用的启动，会在日志中打印出错误信息。 |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

| Note | 默认情况下，xml 格式是不支持的。需要添加 `jackson-dataformat-xml` 依赖后才会自动生效。 |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

| Note | 如果规则加载没有生效，有可能是 jdk 版本导致的，请关注 [759 issue](https://github.com/alibaba/spring-cloud-alibaba/issues/759) 的处理。 |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

关于 Sentinel 动态数据源的实现原理，参考： [动态规则扩展](https://github.com/alibaba/Sentinel/wiki/动态规则扩展)

### Zuul 支持

[参考 Sentinel 网关限流文档](https://github.com/alibaba/Sentinel/wiki/网关限流)

若想跟 Sentinel Starter 配合使用，需要加上 `spring-cloud-alibaba-sentinel-gateway` 依赖，同时需要添加 `spring-cloud-starter-netflix-zuul` 依赖来让 `spring-cloud-alibaba-sentinel-gateway` 模块里的 Zuul 自动化配置类生效：

```
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>

<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-alibaba-sentinel-gateway</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-zuul</artifactId>
</dependency>
```

同时请将 `spring.cloud.sentinel.filter.enabled` 配置项置为 false（若在网关流控控制台上看到了 URL 资源，就是此配置项没有置为 false）。

### Spring Cloud Gateway 支持

[参考 Sentinel 网关限流文档](https://github.com/alibaba/Sentinel/wiki/网关限流)

若想跟 Sentinel Starter 配合使用，需要加上 `spring-cloud-alibaba-sentinel-gateway` 依赖，同时需要添加 `spring-cloud-starter-gateway` 依赖来让 `spring-cloud-alibaba-sentinel-gateway` 模块里的 Spring Cloud Gateway 自动化配置类生效：

```
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>

<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-alibaba-sentinel-gateway</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway</artifactId>
</dependency>
```

同时请将 `spring.cloud.sentinel.filter.enabled` 配置项置为 false（若在网关流控控制台上看到了 URL 资源，就是此配置项没有置为 false）。

### Endpoint 支持

在使用 Endpoint 特性之前需要在 Maven 中添加 `spring-boot-starter-actuator` 依赖，并在配置中允许 Endpoints 的访问。

- Spring Boot 1.x 中添加配置 `management.security.enabled=false`。暴露的 endpoint 路径为 `/sentinel`
- Spring Boot 2.x 中添加配置 `management.endpoints.web.exposure.include=*`。暴露的 endpoint 路径为 `/actuator/sentinel`

Sentinel Endpoint 里暴露的信息非常有用。包括当前应用的所有规则信息、日志目录、当前实例的 IP，Sentinel Dashboard 地址，Block Page，应用与 Sentinel Dashboard 的心跳频率等等信息。

### 配置

下表显示当应用的 `ApplicationContext` 中存在对应的Bean的类型时，会进行自动化设置：

| 存在Bean的类型        | 操作                                                         | 作用                                                         |
| --------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `UrlCleaner`          | `WebCallbackManager.setUrlCleaner(urlCleaner)`               | 资源清理(资源（比如将满足 /foo/:id 的 URL 都归到 /foo/* 资源下）) |
| `UrlBlockHandler`     | `WebCallbackManager.setUrlBlockHandler(urlBlockHandler)`     | 自定义限流处理逻辑                                           |
| `RequestOriginParser` | `WebCallbackManager.setRequestOriginParser(requestOriginParser)` | 设置来源信息                                                 |

Spring Cloud Alibaba Sentinel 提供了这些配置选项:

| 配置项                                                  | 含义                                                         | 默认值            |
| ------------------------------------------------------- | ------------------------------------------------------------ | ----------------- |
| `spring.application.name` or `project.name`             | Sentinel项目名                                               |                   |
| `spring.cloud.sentinel.enabled`                         | Sentinel自动化配置是否生效                                   | true              |
| `spring.cloud.sentinel.eager`                           | 是否提前触发 Sentinel 初始化                                 | false             |
| `spring.cloud.sentinel.transport.port`                  | 应用与Sentinel控制台交互的端口，应用本地会起一个该端口占用的HttpServer | 8719              |
| `spring.cloud.sentinel.transport.dashboard`             | Sentinel 控制台地址                                          |                   |
| `spring.cloud.sentinel.transport.heartbeat-interval-ms` | 应用与Sentinel控制台的心跳间隔时间                           |                   |
| `spring.cloud.sentinel.transport.client-ip`             | 此配置的客户端IP将被注册到 Sentinel Server 端                |                   |
| `spring.cloud.sentinel.filter.order`                    | Servlet Filter的加载顺序。Starter内部会构造这个filter        | Integer.MIN_VALUE |
| `spring.cloud.sentinel.filter.url-patterns`             | 数据类型是数组。表示Servlet Filter的url pattern集合          | /*                |
| `spring.cloud.sentinel.filter.enabled`                  | Enable to instance CommonFilter                              | true              |
| `spring.cloud.sentinel.metric.charset`                  | metric文件字符集                                             | UTF-8             |
| `spring.cloud.sentinel.metric.file-single-size`         | Sentinel metric 单个文件的大小                               |                   |
| `spring.cloud.sentinel.metric.file-total-count`         | Sentinel metric 总文件数量                                   |                   |
| `spring.cloud.sentinel.log.dir`                         | Sentinel 日志文件所在的目录                                  |                   |
| `spring.cloud.sentinel.log.switch-pid`                  | Sentinel 日志文件名是否需要带上 pid                          | false             |
| `spring.cloud.sentinel.servlet.block-page`              | 自定义的跳转 URL，当请求被限流时会自动跳转至设定好的 URL     |                   |
| `spring.cloud.sentinel.flow.cold-factor`                | WarmUp 模式中的 冷启动因子                                   | 3                 |
| `spring.cloud.sentinel.zuul.order.pre`                  | SentinelZuulPreFilter 的 order                               | 10000             |
| `spring.cloud.sentinel.zuul.order.post`                 | SentinelZuulPostFilter 的 order                              | 1000              |
| `spring.cloud.sentinel.zuul.order.error`                | SentinelZuulErrorFilter 的 order                             | -1                |
| `spring.cloud.sentinel.scg.fallback.mode`               | Spring Cloud Gateway 流控处理逻辑 (选择 `redirect` or `response`) |                   |
| `spring.cloud.sentinel.scg.fallback.redirect`           | Spring Cloud Gateway 响应模式为 'redirect' 模式对应的重定向 URL |                   |
| `spring.cloud.sentinel.scg.fallback.response-body`      | Spring Cloud Gateway 响应模式为 'response' 模式对应的响应内容 |                   |
| `spring.cloud.sentinel.scg.fallback.response-status`    | Spring Cloud Gateway 响应模式为 'response' 模式对应的响应码  | 429               |
| `spring.cloud.sentinel.scg.fallback.content-type`       | Spring Cloud Gateway 响应模式为 'response' 模式对应的 content-type | application/json  |

| Note | 请注意。这些配置只有在 Servlet 环境下才会生效，RestTemplate 和 Feign 针对这些配置都无法生效 |
| ---- | ------------------------------------------------------------ |
|      |                                                              |