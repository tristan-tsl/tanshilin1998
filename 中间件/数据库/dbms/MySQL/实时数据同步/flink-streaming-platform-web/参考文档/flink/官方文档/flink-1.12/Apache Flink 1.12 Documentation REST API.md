1.  Operations
2.  

3. REST API

# REST API

**本文档是 Apache Flink 的旧版本。建议访问 [最新的稳定版本](https://ci.apache.org/projects/flink/flink-docs-stable/zh)。**

Flink 具有监控 API ，可用于查询正在运行的作业以及最近完成的作业的状态和统计信息。该监控 API 被用于 Flink 自己的仪表盘，同时也可用于自定义监控工具。

该监控 API 是 REST-ful 风格的，可以接受 HTTP 请求并返回 JSON 格式的数据。

- [概览](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/ops/rest_api.html#概览)
- [拓展](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/ops/rest_api.html#拓展)
- [API](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/ops/rest_api.html#api)



## 概览

该监控 API 由作为 *JobManager* 一部分运行的 web 服务器提供支持。默认情况下，该服务器监听 8081 端口，端口号可以通过修改 `flink-conf.yaml` 文件的 `rest.port` 进行配置。请注意，该监控 API 的 web 服务器和仪表盘的 web 服务器目前是相同的，因此在同一端口一起运行。不过，它们响应不同的 HTTP URL 。

在多个 JobManager 的情况下（为了高可用），每个 JobManager 将运行自己的监控 API 实例，当 JobManager 被选举成为集群 leader 时，该实例将提供已完成和正在运行作业的相关信息。



## 拓展

该 REST API 后端位于 `flink-runtime` 项目中。核心类是 `org.apache.flink.runtime.webmonitor.WebMonitorEndpoint` ，用来配置服务器和请求路由。

我们使用 *Netty* 和 *Netty Router* 库来处理 REST 请求和转换 URL 。选择该选项是因为这种组合具有轻量级依赖关系，并且 Netty HTTP 的性能非常好。

添加新的请求，需要

- 添加一个新的 `MessageHeaders` 类，作为新请求的接口，
- 添加一个新的 `AbstractRestHandler` 类，该类接收并处理 `MessageHeaders` 类的请求，
- 将处理程序添加到 `org.apache.flink.runtime.webmonitor.WebMonitorEndpoint#initializeHandlers()` 中。

一个很好的例子是使用 `org.apache.flink.runtime.rest.messages.JobExceptionsHeaders` 的 `org.apache.flink.runtime.rest.handler.job.JobExceptionsHandler` 。



## API

该 REST API 已版本化，可以通过在 URL 前面加上版本前缀来查询指定版本。前缀格式始终为 `v[version_number]` 。 例如，要访问版本 1 的 `/foo/bar` 接口，将查询 `/v1/foo/bar` 。

如果未指定版本， Flink 将默认使用支持该请求的最旧版本。

查询 不支持/不存在 的版本将返回 404 错误。

这些 API 中存在几种异步操作，例如：`trigger savepoint` 、 `rescale a job` 。它们将返回 `triggerid` 来标识你刚刚执行的 POST 请求，然后你需要使用该 `triggerid` 查询该操作的状态。

- [**V1**](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/ops/rest_api.html#tab_V1_0)

#### JobManager

| **/cluster**           |                         |
| ---------------------- | ----------------------- |
| Verb: `DELETE`         | Response code: `200 OK` |
| Shuts down the cluster |                         |
| Request                |                         |
| Response               |                         |

| **/config**                             |                         |
| --------------------------------------- | ----------------------- |
| Verb: `GET`                             | Response code: `200 OK` |
| Returns the configuration of the WebUI. |                         |
| Request                                 |                         |
| Response                                |                         |

| **/datasets**                  |                         |
| ------------------------------ | ----------------------- |
| Verb: `GET`                    | Response code: `200 OK` |
| Returns all cluster data sets. |                         |
| Request                        |                         |
| Response                       |                         |

| **/datasets/delete/:triggerid**                              |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the status for the delete operation of a cluster data set. |                         |
| Path parameters                                              |                         |
| `triggerid` - 32-character hexadecimal string that identifies an asynchronous operation trigger ID. The ID was returned then the operation was triggered. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/datasets/:datasetid**                                     |                               |
| ------------------------------------------------------------ | ----------------------------- |
| Verb: `DELETE`                                               | Response code: `202 Accepted` |
| Triggers the deletion of a cluster data set. This async operation would return a 'triggerid' for further query identifier. |                               |
| Path parameters                                              |                               |
| `datasetid` - 32-character hexadecimal string value that identifies a cluster data set. |                               |
| Request                                                      |                               |
| Response                                                     |                               |

| **/jars**                                                    |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns a list of all jars previously uploaded via '/jars/upload'. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jars/upload**                                             |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `POST`                                                 | Response code: `200 OK` |
| Uploads a jar to the cluster. The jar must be sent as multi-part data. Make sure that the "Content-Type" header is set to "application/x-java-archive", as some http libraries do not add the header by default. Using 'curl' you can upload a jar via 'curl -X POST -H "Expect:" -F "jarfile=@path/to/flink-job.jar" http://hostname:port/jars/upload'. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jars/:jarid**                                             |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `DELETE`                                               | Response code: `200 OK` |
| Deletes a jar previously uploaded via '/jars/upload'.        |                         |
| Path parameters                                              |                         |
| `jarid` - String value that identifies a jar. When uploading the jar a path is returned, where the filename is the ID. This value is equivalent to the `id` field in the list of uploaded jars (/jars). |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jars/:jarid/plan**                                        |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the dataflow plan of a job contained in a jar previously uploaded via '/jars/upload'. Program arguments can be passed both via the JSON request (recommended) or query parameters. |                         |
| Path parameters                                              |                         |
| `jarid` - String value that identifies a jar. When uploading the jar a path is returned, where the filename is the ID. This value is equivalent to the `id` field in the list of uploaded jars (/jars). |                         |
| Query parameters                                             |                         |
| `program-args` (optional): Deprecated, please use 'programArg' instead. String value that specifies the arguments for the program or plan`programArg` (optional): Comma-separated list of program arguments.`entry-class` (optional): String value that specifies the fully qualified name of the entry point class. Overrides the class defined in the jar file manifest.`parallelism` (optional): Positive integer value that specifies the desired parallelism for the job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jars/:jarid/plan**                                        |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `POST`                                                 | Response code: `200 OK` |
| Returns the dataflow plan of a job contained in a jar previously uploaded via '/jars/upload'. Program arguments can be passed both via the JSON request (recommended) or query parameters. |                         |
| Path parameters                                              |                         |
| `jarid` - String value that identifies a jar. When uploading the jar a path is returned, where the filename is the ID. This value is equivalent to the `id` field in the list of uploaded jars (/jars). |                         |
| Query parameters                                             |                         |
| `program-args` (optional): Deprecated, please use 'programArg' instead. String value that specifies the arguments for the program or plan`programArg` (optional): Comma-separated list of program arguments.`entry-class` (optional): String value that specifies the fully qualified name of the entry point class. Overrides the class defined in the jar file manifest.`parallelism` (optional): Positive integer value that specifies the desired parallelism for the job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jars/:jarid/run**                                         |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `POST`                                                 | Response code: `200 OK` |
| Submits a job by running a jar previously uploaded via '/jars/upload'. Program arguments can be passed both via the JSON request (recommended) or query parameters. |                         |
| Path parameters                                              |                         |
| `jarid` - String value that identifies a jar. When uploading the jar a path is returned, where the filename is the ID. This value is equivalent to the `id` field in the list of uploaded jars (/jars). |                         |
| Query parameters                                             |                         |
| `allowNonRestoredState` (optional): Boolean value that specifies whether the job submission should be rejected if the savepoint contains state that cannot be mapped back to the job.`savepointPath` (optional): String value that specifies the path of the savepoint to restore the job from.`program-args` (optional): Deprecated, please use 'programArg' instead. String value that specifies the arguments for the program or plan`programArg` (optional): Comma-separated list of program arguments.`entry-class` (optional): String value that specifies the fully qualified name of the entry point class. Overrides the class defined in the jar file manifest.`parallelism` (optional): Positive integer value that specifies the desired parallelism for the job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobmanager/config**             |                         |
| ---------------------------------- | ----------------------- |
| Verb: `GET`                        | Response code: `200 OK` |
| Returns the cluster configuration. |                         |
| Request                            |                         |
| Response                           |                         |

| **/jobmanager/logs**                             |                         |
| ------------------------------------------------ | ----------------------- |
| Verb: `GET`                                      | Response code: `200 OK` |
| Returns the list of log files on the JobManager. |                         |
| Request                                          |                         |
| Response                                         |                         |

| **/jobmanager/metrics**                                      |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Provides access to job manager metrics.                      |                         |
| Query parameters                                             |                         |
| `get` (optional): Comma-separated list of string values to select specific metrics. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs**                                                  |                         |
| ---------------------------------------------------------- | ----------------------- |
| Verb: `GET`                                                | Response code: `200 OK` |
| Returns an overview over all jobs and their current state. |                         |
| Request                                                    |                         |
| Response                                                   |                         |

| **/jobs**                                                    |                               |
| ------------------------------------------------------------ | ----------------------------- |
| Verb: `POST`                                                 | Response code: `202 Accepted` |
| Submits a job. This call is primarily intended to be used by the Flink client. This call expects a multipart/form-data request that consists of file uploads for the serialized JobGraph, jars and distributed cache artifacts and an attribute named "request" for the JSON payload. |                               |
| Request                                                      |                               |
| Response                                                     |                               |

| **/jobs/metrics**                                            |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Provides access to aggregated job metrics.                   |                         |
| Query parameters                                             |                         |
| `get` (optional): Comma-separated list of string values to select specific metrics.`agg` (optional): Comma-separated list of aggregation modes which should be calculated. Available aggregations are: "min, max, sum, avg".`jobs` (optional): Comma-separated list of 32-character hexadecimal strings to select specific jobs. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/overview**                 |                         |
| ---------------------------------- | ----------------------- |
| Verb: `GET`                        | Response code: `200 OK` |
| Returns an overview over all jobs. |                         |
| Request                            |                         |
| Response                           |                         |

| **/jobs/:jobid**                                             |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns details of a job.                                    |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid**                                             |                               |
| ------------------------------------------------------------ | ----------------------------- |
| Verb: `PATCH`                                                | Response code: `202 Accepted` |
| Terminates a job.                                            |                               |
| Path parameters                                              |                               |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                               |
| Query parameters                                             |                               |
| `mode` (optional): String value that specifies the termination mode. The only supported value is: "cancel". |                               |
| Request                                                      |                               |
| Response                                                     |                               |

| **/jobs/:jobid/accumulators**                                |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the accumulators for all tasks of a job, aggregated across the respective subtasks. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Query parameters                                             |                         |
| `includeSerializedValue` (optional): Boolean value that specifies whether serialized user task accumulators should be included in the response. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/checkpoints**                                 |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns checkpointing statistics for a job.                  |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/checkpoints/config**                          |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the checkpointing configuration.                     |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/checkpoints/details/:checkpointid**           |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns details for a checkpoint.                            |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`checkpointid` - Long value that identifies a checkpoint. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/checkpoints/details/:checkpointid/subtasks/:vertexid** |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns checkpoint statistics for a task and its subtasks.   |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`checkpointid` - Long value that identifies a checkpoint.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/config**                                      |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the configuration of a job.                          |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/exceptions**                                  |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the non-recoverable exceptions that have been observed by the job. The truncated flag defines whether more exceptions occurred, but are not listed, because the response would otherwise get too big. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Query parameters                                             |                         |
| `maxExceptions` (optional): Comma-separated list of integer values that specifies the upper limit of exceptions to return. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/execution-result**                            |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the result of a job execution. Gives access to the execution time of the job and to all accumulators created by this job. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/metrics**                                     |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Provides access to job metrics.                              |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Query parameters                                             |                         |
| `get` (optional): Comma-separated list of string values to select specific metrics. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/plan**                                        |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the dataflow plan of a job.                          |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/rescaling**                                   |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `PATCH`                                                | Response code: `200 OK` |
| Triggers the rescaling of a job. This async operation would return a 'triggerid' for further query identifier. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                         |
| Query parameters                                             |                         |
| `parallelism` (mandatory): Positive integer value that specifies the desired parallelism. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/rescaling/:triggerid**                        |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the status of a rescaling operation.                 |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`triggerid` - 32-character hexadecimal string that identifies an asynchronous operation trigger ID. The ID was returned then the operation was triggered. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/savepoints**                                  |                               |
| ------------------------------------------------------------ | ----------------------------- |
| Verb: `POST`                                                 | Response code: `202 Accepted` |
| Triggers a savepoint, and optionally cancels the job afterwards. This async operation would return a 'triggerid' for further query identifier. |                               |
| Path parameters                                              |                               |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                               |
| Request                                                      |                               |
| Response                                                     |                               |

| **/jobs/:jobid/savepoints/:triggerid**                       |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the status of a savepoint operation.                 |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`triggerid` - 32-character hexadecimal string that identifies an asynchronous operation trigger ID. The ID was returned then the operation was triggered. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/stop**                                        |                               |
| ------------------------------------------------------------ | ----------------------------- |
| Verb: `POST`                                                 | Response code: `202 Accepted` |
| Stops a job with a savepoint. Optionally, it can also emit a MAX_WATERMARK before taking the savepoint to flush out any state waiting for timers to fire. This async operation would return a 'triggerid' for further query identifier. |                               |
| Path parameters                                              |                               |
| `jobid` - 32-character hexadecimal string value that identifies a job. |                               |
| Request                                                      |                               |
| Response                                                     |                               |

| **/jobs/:jobid/vertices/:vertexid**                          |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns details for a task, with a summary for each of its subtasks. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/accumulators**             |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns user-defined accumulators of a task, aggregated across all subtasks. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/backpressure**             |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns back-pressure information for a job, and may initiate back-pressure sampling if necessary. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/metrics**                  |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Provides access to task metrics.                             |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Query parameters                                             |                         |
| `get` (optional): Comma-separated list of string values to select specific metrics. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/subtasks/accumulators**    |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns all user-defined accumulators for all subtasks of a task. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/subtasks/metrics**         |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Provides access to aggregated subtask metrics.               |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Query parameters                                             |                         |
| `get` (optional): Comma-separated list of string values to select specific metrics.`agg` (optional): Comma-separated list of aggregation modes which should be calculated. Available aggregations are: "min, max, sum, avg".`subtasks` (optional): Comma-separated list of integer ranges (e.g. "1,3,5-9") to select specific subtasks. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/subtasks/:subtaskindex**   |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns details of the current or latest execution attempt of a subtask. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex.`subtaskindex` - Positive integer value that identifies a subtask. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/subtasks/:subtaskindex/attempts/:attempt** |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns details of an execution attempt of a subtask. Multiple execution attempts happen in case of failure/recovery. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex.`subtaskindex` - Positive integer value that identifies a subtask.`attempt` - Positive integer value that identifies an execution attempt. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/subtasks/:subtaskindex/attempts/:attempt/accumulators** |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the accumulators of an execution attempt of a subtask. Multiple execution attempts happen in case of failure/recovery. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex.`subtaskindex` - Positive integer value that identifies a subtask.`attempt` - Positive integer value that identifies an execution attempt. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/subtasks/:subtaskindex/metrics** |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Provides access to subtask metrics.                          |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex.`subtaskindex` - Positive integer value that identifies a subtask. |                         |
| Query parameters                                             |                         |
| `get` (optional): Comma-separated list of string values to select specific metrics. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/subtasktimes**             |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns time-related information for all subtasks of a task. |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/taskmanagers**             |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns task information aggregated by task manager.         |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/jobs/:jobid/vertices/:vertexid/watermarks**               |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the watermarks for all subtasks of a task.           |                         |
| Path parameters                                              |                         |
| `jobid` - 32-character hexadecimal string value that identifies a job.`vertexid` - 32-character hexadecimal string value that identifies a job vertex. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/overview**                               |                         |
| ------------------------------------------- | ----------------------- |
| Verb: `GET`                                 | Response code: `200 OK` |
| Returns an overview over the Flink cluster. |                         |
| Request                                     |                         |
| Response                                    |                         |

| **/savepoint-disposal**                                      |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `POST`                                                 | Response code: `200 OK` |
| Triggers the desposal of a savepoint. This async operation would return a 'triggerid' for further query identifier. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/savepoint-disposal/:triggerid**                           |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the status of a savepoint disposal operation.        |                         |
| Path parameters                                              |                         |
| `triggerid` - 32-character hexadecimal string that identifies an asynchronous operation trigger ID. The ID was returned then the operation was triggered. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/taskmanagers**                           |                         |
| ------------------------------------------- | ----------------------- |
| Verb: `GET`                                 | Response code: `200 OK` |
| Returns an overview over all task managers. |                         |
| Request                                     |                         |
| Response                                    |                         |

| **/taskmanagers/metrics**                                    |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Provides access to aggregated task manager metrics.          |                         |
| Query parameters                                             |                         |
| `get` (optional): Comma-separated list of string values to select specific metrics.`agg` (optional): Comma-separated list of aggregation modes which should be calculated. Available aggregations are: "min, max, sum, avg".`taskmanagers` (optional): Comma-separated list of 32-character hexadecimal strings to select specific task managers. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/taskmanagers/:taskmanagerid**                             |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns details for a task manager. "metrics.memorySegmentsAvailable" and "metrics.memorySegmentsTotal" are deprecated. Please use "metrics.nettyShuffleMemorySegmentsAvailable" and "metrics.nettyShuffleMemorySegmentsTotal" instead. |                         |
| Path parameters                                              |                         |
| `taskmanagerid` - 32-character hexadecimal string that identifies a task manager. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/taskmanagers/:taskmanagerid/logs**                        |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the list of log files on a TaskManager.              |                         |
| Path parameters                                              |                         |
| `taskmanagerid` - 32-character hexadecimal string that identifies a task manager. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/taskmanagers/:taskmanagerid/metrics**                     |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Provides access to task manager metrics.                     |                         |
| Path parameters                                              |                         |
| `taskmanagerid` - 32-character hexadecimal string that identifies a task manager. |                         |
| Query parameters                                             |                         |
| `get` (optional): Comma-separated list of string values to select specific metrics. |                         |
| Request                                                      |                         |
| Response                                                     |                         |

| **/taskmanagers/:taskmanagerid/thread-dump**                 |                         |
| ------------------------------------------------------------ | ----------------------- |
| Verb: `GET`                                                  | Response code: `200 OK` |
| Returns the thread dump of the requested TaskManager.        |                         |
| Path parameters                                              |                         |
| `taskmanagerid` - 32-character hexadecimal string that identifies a task manager. |                         |
| Request                                                      |                         |
| Response                                                     |                         |