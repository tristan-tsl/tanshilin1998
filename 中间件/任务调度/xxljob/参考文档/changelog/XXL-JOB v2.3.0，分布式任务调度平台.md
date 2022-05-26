- 1、【新增】调度过期策略：调度中心错过调度时间的补偿处理策略，包括：忽略、立即补偿触发一次等；
- 2、【新增】触发策略：除了常规Cron、API、父子任务触发方式外，新增提供 "固定间隔触发、（固定延时触发，实验中）" 新触发方式；
- 3、【新增】新增任务辅助工具 "XxlJobHelper"：提供统一任务辅助能力，包括：任务上下文信息维护获取（任务参数、任务ID、分片参数）、日志输出、任务结果设置……等；
  - 3.1、"ShardingUtil" 组件废弃：改用 "XxlJobHelper.getShardIndex()/getShardTotal();" 获取分片参数；
  - 3.2、"XxlJobLogger" 组件废弃：改用 "XxlJobHelper.log" 进行日志输出；
- 4、【优化】任务核心类 "IJobHandler" 的 "execute" 方法取消出入参设计。改为通过 "XxlJobHelper.getJobParam" 获取任务参数并替代方法入参，通过 "XxlJobHelper.handleSuccess/handleFail" 设置任务结果并替代方法出参，示例代码如下；

```
@XxlJob("demoJobHandler")
public void execute() {
  String param = XxlJobHelper.getJobParam();    // 获取参数
  XxlJobHelper.handleSuccess();                 // 设置任务结果
}
```

- 5、【优化】Cron编辑器增强：Cron编辑器修改cron时可实时查看最近运行时间;
- 6、【优化】执行器示例项目规范整理；
- 7、【优化】任务调度生命周期重构：调度（schedule）、触发(trigger)、执行（handle）、回调(callback)、结束（complete）；
- 8、【优化】执行器注册组件优化：注册逻辑调整为异步方式，提高注册性能；
- 9、【优化】执行器鉴权校验：执行器启动时主动校验accessToken，为空则主动Warn告警；（已规划安全强化：AccessToken动态生成、动态启停等）
- 10、【优化】邮箱告警配置优化：将"spring.mail.from"与"spring.mail.username"属性拆分开，更加灵活的支持一些无密码邮箱服务；
- 11、【优化】多个项目依赖升级至较新稳定版本，如netty、groovy、spring、springboot、mybatis等；
- 12、【优化】UI组件常规升级，提升组件稳定性；
- 13、【优化】调度中心页面交互优化：用户管理模块密码列取消；多处表达autocomplete取消；执行器管理模块XSS拦截校验等；
- 14、【优化】调度中心任务状态探测慢SQL问题优化；
- 15、【修复】GLUE-Java模式任务，init/destroy无法执行问题修复；
- 16、【修复】Cron编辑器问题修复：修复小概率情况下cron单个字段修改时导致其他字段被重置问题；
- 17、【修复】通用HTTP任务Handler（httpJobHandler）优化：修复 "setDoOutput(true)" 导致任务请求GetMethod失效问题；
- 18、【修复】执行器Commandhandler示例任务优化，修复极端情况下脚本进程挂起问题；
- 19、【修复】调度通讯组件优化，修复RestFul方式调用 DotNet 版本执行器时心跳检测失败问题；
- 20、【修复】调度中心远程执行日志查询乱码问题修复；
- 21、【修复】调度中心组件加载顺序优化，修复极端情况下调度组件初始慢导致的调度失败问题；
- 22、【修复】执行器注册线程优化，修复极端情况下初始化失败时导致NPE问题；
- 23、【修复】调度线程连接池优化，修复连接有效性校验超时问题；
- 24、【修复】执行器注册表字段优化，解决执行器注册节点过多导致注册信息存储和更新失败的问题；
- 25、【修复】轮训路由策略优化，修复小概率下并发问题；
- 26、【修复】页面redirect跳转后https变为http问题修复；
- 27、【修复】执行器日志清理优化，修复小概率下日志文件为空导致清理异常问题；