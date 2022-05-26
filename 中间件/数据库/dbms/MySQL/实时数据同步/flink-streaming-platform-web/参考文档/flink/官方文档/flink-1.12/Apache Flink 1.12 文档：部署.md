# 部署

**本文档是 Apache Flink 的旧版本。建议访问[最新的稳定版本](https://ci.apache.org/projects/flink/flink-docs-stable/zh)。**

Flink 是一个多功能框架，以混搭方式支持许多不同的部署场景。

下面，我们简要解释 Flink 集群的构建块、它们的用途和可用的实现。如果你只是想在本地启动 Flink，我们建议设置一个[Standalone Cluster](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/resource-providers/standalone/)。

- [概述和参考架构](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/#overview-and-reference-architecture)
- [部署模式](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/#deployment-modes)
- [供应商解决方案](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/#vendor-solutions)

## 概述和参考架构

下图展示了每个 Flink 集群的构建块。总是有客户端在运行。它获取 Flink 应用程序的代码，将其转换为 JobGraph 并提交给 JobManager。

JobManager 将工作分配到 TaskManagers 上，在那里运行实际的操作符（例如源、转换和接收器）。

在部署 Flink 时，每个构建块通常有多个选项可用。我们在图下方的表格中列出了它们。

![概述和参考架构图](https://ci.apache.org/projects/flink/flink-docs-release-1.12/fig/deployment_overview.svg)

| 成分                     | 目的                                                         | 实现                                                         |
| :----------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| Flink 客户端             | 将批处理或流应用程序编译成数据流图，然后将其提交给 JobManager。 | [命令行界面](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/cli.html)[REST端点](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/ops/rest_api.html)[SQL客户端](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/dev/table/sqlClient.html)[Python REPL](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/repls/python_shell.html)[Scala REPL](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/repls/scala_shell.html) |
| 作业管理器               | JobManager 是 Flink 的中心工作协调组件的名称。它具有针对不同资源提供者的实现，这些实现在高可用性、资源分配行为和支持的作业提交模式方面有所不同。 作业[提交的](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/#deployment-modes)JobManager[模式](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/#deployment-modes)：**应用模式**：专为一个应用运行集群。作业的主要方法（或客户端）在 JobManager 上执行。支持在应用程序中多次调用 `execute`/`executeAsync`。**Per-Job 模式**：专门为一项作业运行集群。作业的主要方法（或客户端）仅在集群创建之前运行。**会话模式**：一个 JobManager 实例管理共享同一个 TaskManager 集群的多个作业 | [独立](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/resource-providers/standalone/)（这是一种只需要启动 JVM 的准系统模式。在这种模式下可以通过手动设置使用[Docker、Docker Swarm / Compose](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/resource-providers/standalone/docker.html)、[非原生 Kubernetes](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/resource-providers/standalone/kubernetes.html)和其他模型进行部署）[Kubernetes](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/resource-providers/native_kubernetes.html)[纱](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/resource-providers/yarn.html)[金币](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/resource-providers/mesos.html) |
| 任务管理器               | TaskManager 是实际执行 Flink 作业工作的服务。                |                                                              |
| **外部组件**（全部可选） |                                                              |                                                              |
| 高可用性服务提供商       | Flink 的 JobManager 可以运行在高可用模式下，这使得 Flink 从 JobManager 故障中恢复。为了更快地进行故障转移，可以启动多个备用 JobManager 作为备份。 | [动物园管理员](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/ha/zookeeper_ha.html)[高可用性](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/ha/kubernetes_ha.html) |
| 文件存储和持久性         | 对于检查点（流作业的恢复机制），Flink 依赖于外部文件存储系统 | 请参阅[文件系统](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/filesystems/)页面。 |
| 资源提供者               | Flink 可以通过不同的资源提供者框架进行部署，例如 Kubernetes、YARN 或 Mesos。 | 请参阅上面的[JobManager](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/#jmimpls)实现。 |
| 指标存储                 | Flink 组件报告内部指标，Flink 作业也可以报告额外的、特定于作业的指标。 | 请参阅[指标报告器](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/metric_reporters.html)页面。 |
| 应用程序级数据源和接收器 | 虽然应用级数据源和接收器在技术上不是 Flink 集群组件部署的一部分，但在规划新的 Flink 生产部署时应该考虑它们。使用 Flink 托管常用数据可以带来显着的性能优势 | 例如：卡夫卡亚马逊 S3弹性搜索阿帕奇卡桑德拉请参阅[连接器](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/dev/connectors/)页面。 |

## 部署模式

Flink 可以通过以下三种方式之一执行应用程序：

- 在应用模式下，
- 在 Per-Job 模式下，
- 在会话模式中。

上述模式的区别在于：

- 集群生命周期和资源隔离保证
- 应用程序的`main()`方法是在客户端还是在集群上执行。

![部署模式图](https://ci.apache.org/projects/flink/flink-docs-release-1.12/fig/deployment_modes.svg)

#### 应用模式

在所有其他模式中，应用程序的`main()`方法在客户端执行。此过程包括在本地下载应用程序的依赖项，执行`main()`以提取 Flink 的运行时可以理解的应用程序表示（即`JobGraph`），并将依赖项和`JobGraph(s)`传送到集群。这使得客户端成为大量资源消耗者，因为它可能需要大量网络带宽来下载依赖项并将二进制文件发送到集群，并且需要 CPU 周期来执行 `main()`. 当客户端在用户之间共享时，这个问题会更加明显。

基于这个观察，*Application Mode*为每个提交的应用程序创建一个集群，但这一次，`main()`应用程序的方法是在 JobManager 上执行的。为每个应用程序创建一个集群可以看作是创建一个仅在特定应用程序的作业之间共享的会话集群，并在应用程序完成时拆除。使用这种架构，*应用程序模式*提供与*Per-Job*模式相同的资源隔离和负载平衡保证，但以整个应用程序的粒度。执行`main()`在 JobManager 上允许节省所需的 CPU 周期，但也节省了本地下载依赖项所需的带宽。此外，它允许更均匀地分布网络负载以下载集群中应用程序的依赖项，因为每个应用程序有一个 JobManager。

**注意：**在应用程序模式下，`main()`与其他模式一样，在集群上执行而不是在客户端上执行。这可能会对您的代码产生影响，例如，您在环境中使用 注册的任何路径都`registerCachedFile()`必须可由应用程序的 JobManager 访问。

与*Per-Job*模式相比，*Application Mode*允许提交由多个作业组成的应用程序。作业执行的顺序不受部署模式的影响，而是受用于启动作业的调用的影响。使用`execute()`阻塞，建立一个顺序，它将导致“下一个”作业的执行被推迟，直到“这个”作业完成。使用`executeAsync()`非阻塞，将导致“下一个”作业在“此”作业完成之前开始。

**注意：**应用模式允许多`execute()`应用，但在这些情况下不支持高可用性。应用程序模式下的高可用性仅支持单一`execute()`应用程序。

#### 每作业模式

*Per-Job*模式旨在提供更好的资源隔离保证，使用可用的资源提供者框架（例如 YARN、Kubernetes）为每个提交的作业启动一个集群。此集群仅可用于该作业。作业完成后，集群将被拆除并清除所有遗留资源（文件等）。这提供了更好的资源隔离，因为行为不当的作业只能降低其自己的 TaskManager。此外，它将簿记负载分散到多个 JobManager 中，因为每个作业有一个。由于这些原因，*Per-Job*资源分配模型是许多生产原因的首选模式。

#### 会话模式

*会话模式*假设一个已经在运行的集群并使用该集群的资源来执行任何提交的应用程序。在同一（会话）集群中执行的应用程序使用并因此竞争相同的资源。这样做的好处是您无需为每个提交的作业支付启动完整集群的资源开销。但是，如果其中一个作业行为不当或关闭了 TaskManager，那么在该 TaskManager 上运行的所有作业都将受到故障的影响。除了对导致失败的作业的负面影响之外，这还意味着潜在的大规模恢复过程，所有重新启动的作业同时访问文件系统并使其对其他服务不可用。此外，让单个集群运行多个作业意味着 JobManager 的负载更大，

#### 概括

在*会话模式下*，集群生命周期独立于集群上运行的任何作业的生命周期，并且资源在所有作业之间共享。在*每个作业*方式支付旋转起来为每个提交的作业集群的价格，但这种带有更好的隔离保证的资源不能跨岗位共享。在这种情况下，集群的生命周期与作业的生命周期绑定。最后， *Application Mode*为每个应用程序创建一个会话集群，并`main()` 在集群上执行应用程序的方法。

## 供应商解决方案

许多供应商提供托管或完全托管的 Flink 解决方案。这些供应商均未得到 Apache Flink PMC 的正式支持或认可。请参阅供应商维护的有关如何使用这些产品的文档。

#### 阿里云实时计算

[网站](https://www.alibabacloud.com/products/realtime-compute)

支持环境： **阿里云**

#### 亚马逊电子病历

[网站](https://aws.amazon.com/emr/)

支持的环境： **AWS**

#### 适用于 Apache Flink 的 Amazon Kinesis 数据分析

[网站](https://docs.aws.amazon.com/kinesisanalytics/latest/java/what-is.html)

支持的环境： **AWS**

#### Cloudera 数据流

[网站](https://www.cloudera.com/products/cdf.html)

支持的环境： **AWS** **Azure** **Google Cloud** **On-Premise**

#### 事件

[网站](https://eventador.io/)

支持环境： **AWS**

#### 华为云流服务

[网站](https://www.huaweicloud.com/en-us/product/cs.html)

支持环境： **华为云**

#### 维维卡平台

[网站](https://www.ververica.com/platform-overview)

支持的环境： **阿里** **云****AWS** **Azure** **Google Cloud** **On-Premise**