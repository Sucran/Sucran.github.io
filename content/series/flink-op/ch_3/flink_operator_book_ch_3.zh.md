---
title: "Flink Operator CRD 解析"
date: 2024-12-14T23:34:54+08:00
draft: false
description: ""
---

## 3.1 CRD 与 API 分层设计

当我们简单了解完 Java Operator SDK 之后，这一章将会进入 Flink Operator 源码解析的正题。我们重新打开第一章节中从 Github 上拉取的代码。我们先只看项目中的module，你能看到以下模块：

```shell
flink-kubernetes-operator/
├── flink-kubernetes-operator/          # 主要的 Operator 实现，包含 Controller 和调谐逻辑
├── flink-kubernetes-operator-api/      # API 定义和 CRD，定义 FlinkDeployment 等自定义资源
├── flink-kubernetes-operator-autoscaler/ # Operator 中的自动扩缩容功能实现
├── flink-kubernetes-webhook/           # Webhook 实现，用于资源验证和修改
├── flink-autoscaler/                   # 自动扩缩容核心模块，独立的扩缩容服务
├── flink-autoscaler-plugin-jdbc/      # JDBC 插件，用于数据库连接池监控
├── flink-autoscaler-standalone/       # 独立部署版本，不依赖 Operator
└── flink-kubernetes-standalone/       # Standalone 部署模式，传统 Flink 集群部署
```

其中，webhook 和 autoscaler 以及 standalone 相关的模块我们会在后续章节展开，这里先跳过。你会发现剩下的 operator 相关的模块有两个，一个是 operator 实现本身，另一个就是 operator 的 api 定义和 crd 实现了。

为什么要将实现和 api & crd 定义分开呢？我们从本质上来说，CRD 是 Operator 模式中 API 定义的一种表现形式，放在同一个模块给调用者免去了同步修改的麻烦。根据关注点分离原则，其他关键模块也都会依赖 api 模块。读者要读懂 Operator 的代码，最先需要读懂的是 CRD，所以这一章我们着重讲解该模块中的 CRD。在第二章笔者已经详细讲解过 CRD 的定义、由来以及生成原理，这里不再赘述。

### 3.1.1 FlinkDeployment & FlinkSessionJob

Flink Operator 最初只有两个 CRD，即 FlinkDeployment 和 FlinkSessionJob。在 1.10 版本新增了 FlinkStateSnapshot 的 CRD，这个 CRD 我们后续章节进行讲解。

官方文档中关于这两个自定义资源的介绍是：

> FlinkDeployment CR defines Flink Application and Session cluster deployments. The FlinkSessionJob CR defines the session job on the Session cluster and each Session cluster can run multiple FlinkSessionJob.
>
> FlinkDeployment CR 定义了 Flink 应用和会话集群部署。FlinkSessionJob CR 定义了会话集群上的会话作业，并且每个会话集群可以运行多个 FlinkSessionJob。
>
> ...
>
> With these two Custom Resources, we can support two different operational models:
> 
> 通过这两个自定义资源，我们可以支持两种不同的操作模式
>
> - Flink application managed by the FlinkDeployment
> 
> - 由 FlinkDeployment 管理的 Flink 应用程序
> 
> - Empty Flink session managed by the FlinkDeployment + multiple jobs managed by the FlinkSessionJobs. The operations on the session jobs are independent of each other.
> 
> - 由 FlinkDeployment 管理的空 Flink 会话 + 由 FlinkSessionJobs 管理的多个作业。会话作业的操作是相互独立的。

从文档描述可知，FlinkSessionJob 本身是依赖 FlinkDeployment，所以接下来我们先看 FlinkDeployment 的类定义。

```java
@Experimental
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonDeserialize()
@Group(CrdConstants.API_GROUP)
@Version(CrdConstants.API_VERSION)
@ShortNames({"flinkdep"})
public class FlinkDeployment
        extends AbstractFlinkResource<FlinkDeploymentSpec, FlinkDeploymentStatus>
        implements Namespaced {
        // methods
}
```
从类定义中可以看出，继承了泛型父类 AbstractFlinkResource，父类有两个泛型参数，FlinkDeploymentSpec 和 FlinkDeploymentStatus。同时实现了 Namespaced 接口，这个接口是表示这个自定义资源的作用域在命名空间内。

是否 FlinkSessionJob 也一样继承了泛型父类 AbstractFlinkResource？我们也一并看一下其定义：

```java
@Experimental
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonDeserialize()
@Group(CrdConstants.API_GROUP)
@Version(CrdConstants.API_VERSION)
@ShortNames({"sessionjob"})
public class FlinkSessionJob
        extends AbstractFlinkResource<FlinkSessionJobSpec, FlinkSessionJobStatus>
        implements Namespaced {
        // methods
}
```

从代码上来看是的，但是泛型参数是不同的。接着我们直接看 AbstractFlinkResource 的定义：

```java
@Experimental
public class AbstractFlinkResource<
                SPEC extends AbstractFlinkSpec, STATUS extends CommonStatus<SPEC>>
        extends CustomResource<SPEC, STATUS> implements Namespaced {}
```

我们可以看到最终继承的接口是 CustomResource，这个是 Fabric8 的 kubernetes-client-api 的库中代码，这本质上是一个自定义资源的 Yaml 定义的 Java 实现。你可以把 AbstractFlinkResource 本身认为是自定义资源的声明的一部分，它只是将 FlinkSessionJob 和 FlinkDeployment 公用的部分抽出来了。SPEC 是一个泛型占位符，指的是 SPEC 的类都是继承  AbstractFlinkSpec， 而 STATUS 的类是继承 CommonStatus。换句话说，AbstractFlinkSpec 包含了 Yaml 定义中 spec 结构里重复的部分，CommonStatus 包含了 Yaml 定义中 status 结构里重复的部分。

但是为什么 AbstractFlinkResource 没有被 Fabric8 开发的 crd-generator-apt 的库自动生成成yaml 文件呢？原因是这个接口没有写上对应的注解，这个在第二章节中 Operator 开发流程中有提到，读者可以返回去看一下例子。

具体的依赖关系可以直接看下图：
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/spec_diagram.png "CRD 类依赖关系图")

## 3.2 CRD 代码设计解析

### 3.2.1作业层级设计

#### AbstractFlinkSpec - 作业提交配置声明

深入到`AbstractFlinkSpec`的设计，我们会发现其体现了"最小完备集"的设计原则：

```java
public abstract class AbstractFlinkSpec implements Diffable<AbstractFlinkSpec> {
    private JobSpec job;                    // 可选的作业配置
    private Long restartNonce;             // 重启触发器
    private Map<String, String> flinkConfiguration; // 配置覆盖
}
```

这三个字段构成了 Flink 作业提交的配置抽象
- job 对应作业配置，包括常见的 jar 包 URI，并行度、类名、执行参数等
- restartNonce 用于重启的触发值，当修改值后，控制器会检测到时会重启作业
- flinkConfiguration 作业配置参数，对应作业提交时的 conf.yaml

其中，restartNonce 对应的重启检测机制遵循以下模式：
```
用户: restartNonce=1 → 控制器检测到变化 → 触发重启操作
用户: restartNonce=2 → 控制器检测到变化 → 再次触发重启
```

设计者刻意将 job 和 flinkConfiguration 字段抽象到 AbstractFlinkSpec，这样就能让 FlinkDeployment 同时支持 Flink 的 Application 模式和 Session 模式。当 FlinkDeployment 不配置 job 时，就对应是一个 Session 模式的集群。

更近一步，job 对应的作业配置，主要包含的是：

```java
public class JobSpec implements Diffable<JobSpec> {
    private String jarURI;
    private int parallelism;
    private String entryClass;
    private String[] args = new String[0];
    private JobState state = JobState.RUNNING;
    private Long savepointTriggerNonce;
    private String initialSavepointPath;
    private Long checkpointTriggerNonce;
    private UpgradeMode upgradeMode = UpgradeMode.STATELESS;
    private Boolean allowNonRestoredState;
    private Long savepointRedeployNonce;
}
```

JobSpec 类定义了 job 的配置字段：
- `jarURI`：作业 JAR 包在 Flink 容器内的 URI 路径，如 `local:///opt/flink/examples/streaming/StateMachineExample.jar`
- `parallelism`：Flink 作业的并行度设置
- `entryClass`：Flink 作业主类的完全限定类名
- `args`：传递给 Flink 作业主类的参数数组
- `state`：作业的期望状态，默认为 `RUNNING`
- `savepointTriggerNonce`：手动触发保存点的触发器，修改此值可触发保存点操作
- `initialSavepointPath`：作业首次部署或保存点重新部署时使用的保存点路径
- `checkpointTriggerNonce`：手动触发检查点的触发器，修改此值可触发检查点操作
- `upgradeMode`：作业的升级模式，默认为 `STATELESS`（无状态）
- `allowNonRestoredState`：是否允许无法映射到任何作业顶点的检查点状态
- `savepointRedeployNonce`：触发从指定保存点路径完全重新部署作业的触发器

这些配置都可以在 yaml 中进行指定，在下一章的控制流中会讲到对参数值的校验逻辑
其中 savepointTriggerNonce、checkpointTriggerNonce、savepointRedeployNonce 的生效过程跟前文提到的 restartNonce 是一样的。

#### CommonStatus - 作业状态

CommonStatus 的设计体现了状态观测的"统一语言"思想：

```java
public abstract class CommonStatus<SPEC extends AbstractFlinkSpec> {
    private JobStatus jobStatus = new JobStatus();           // 作业状态
    private String error;                                     // 错误信息
    private Long observedGeneration;                          // 版本追踪
    private ResourceLifecycleState lifecycleState;            // 生命周期状态
    
    public abstract ReconciliationStatus<SPEC> getReconciliationStatus(); // 调谐状态获取
}
```

这个抽象类通过组合而非继承的方式，将不同层面的状态信息有机地整合在一起：
- `jobStatus` 提供作业层面的运行时洞察
- `error` 结合框架的 ErrorStatusHandler 进行错误传播
- `observedGeneration` 确保Spec与Status的版本一致性
- `lifecycleState` 通过算法计算而对应集群中提供资源级别的生命周期

其中 调谐状态 ReconciliationStatus 对应的是 资源从创建到稳定的标准演进路径：
```
CREATED → DEPLOYED → STABLE
    ↓        ↓
  FAILED  UPGRADING
```

这个状态路径对应了集群的部署状态，这个状态流转将由 FlinkDeployment 和 FlinkSessionJob 对应的控制器来观察记录。

其中，jobStatus 对应的是 JobStatus 类，它提供了作业运行时的完整状态信息：

```java
public class JobStatus {
    private String jobName;
    private String jobId;
    private org.apache.flink.api.common.JobStatus state;
    private String startTime;
    private String updateTime;
    private String upgradeSavepointPath;
}
```

JobStatus 类定义了作业运行时的状态字段：
- `jobName`：作业的名称
- `jobId`：Flink 作业的唯一标识符
- `state`：作业的当前状态，对应 Flink 的 JobStatus 枚举（如 RUNNING、FINISHED、FAILED 等）
- `startTime`：作业的启动时间
- `updateTime`：作业状态的最后更新时间
- `upgradeSavepointPath`：升级时使用的保存点路径的确认信息

代码中有两个兼容作用但已废弃的字段：
- `savepointInfo`：保存点相关信息（已废弃），功能被新的 CRD FlinkSnapshot 覆盖。
- `checkpointInfo`：检查点相关信息（已废弃），功能被新的 CRD FlinkSnapshot 覆盖。

从代码设计中可以看出 jobStatus 主要是对 Flink 框架原本的 JobStatus 的一种封装。

而 lifecycleState 其实在下一章的控制流代码解析中，本质上来说就是与 ReconciliationStatus 是一个表和里的映射关系。lifecycleState 对应的枚举类 ResourceLifecycleState 定义了更加详细的资源部署状态。代码如下

```java
public enum ResourceLifecycleState {
    CREATED(false, "The resource was created in Kubernetes but not yet handled by the operator"),
    SUSPENDED(true, "The resource (job) has been suspended"),
    UPGRADING(false, "The resource is being upgraded"),
    DEPLOYED(false, "The resource is deployed/submitted to Kubernetes, but it's not yet considered to be stable and might be rolled back in the future"),
    STABLE(true, "The resource deployment is considered to be stable and won't be rolled back"),
    ROLLING_BACK(false, "The resource is being rolled back to the last stable spec"),
    ROLLED_BACK(true, "The resource is deployed with the last stable spec"),
    FAILED(true, "The job terminally failed");
}
```

lifecycleState（ResourceLifecycleState）枚举定义了资源生命周期的各个状态：
- `CREATED`：资源已在 Kubernetes 中创建，但尚未被 operator 处理
- `SUSPENDED`：资源（作业）已被暂停
- `UPGRADING`：资源正在升级中
- `DEPLOYED`：资源已部署/提交到 Kubernetes，但尚未稳定，可能会回滚
- `STABLE`：资源部署被认为是稳定的，不会回滚
- `ROLLING_BACK`：资源正在回滚到最后一个稳定的规格
- `ROLLED_BACK`：资源已使用最后一个稳定的规格部署
- `FAILED`：作业最终失败



### 3.2.3 集群层级设计

#### FlinkDeployment 双模式声明

FlinkDeployment 的双模式分别是：
- 集群模式：Application mode vs. Session mode
- 集群部署模式：Native mode vs. Standalone mode

FlinkDeployment 体现了"集群即资源"的完整语义，可以将对应声明分为 4 层：
- **镜像层**：`image + imagePullPolicy + flinkVersion` 对应运行时容器环境
- **资源层**：`jobManager + taskManager + mode` 对应完整集群资源规格
- **网络层**：`serviceAccount + ingress` 对应集群权限和网络配置
- **模板层**：`podTemplate + logConfiguration` 对应模版配置和日志配置

除此之外 mode 配置对应 通过`KubernetesDeploymentMode`枚举实现：

```java
public enum KubernetesDeploymentMode {
    NATIVE("Deploys Flink using Flink's native Kubernetes support"),
    STANDALONE("Deploys Flink on-top of kubernetes in standalone mode");
}
```

其中，NATIVE模式 采用 Flink 原生的 Kubernetes 集成，利用Flink自身的资源管理能力，对应两个特点：
- Flink 框架使用 Kubernetes 客户端来创建资源和释放
- 支持细粒度的资源申请和释放

NATIVE 模式将由 Flink 创建的 Kubernetes 客户端来创建 JobManager 的 Deployment，再由 JobManager 来创建和管理 TaskManager 的 Pod
这种集成意味着 Flink 集群可以直接与 Kubernetes 通信，并允许其管理 Kubernetes 资源，例如动态分配和释放 TaskManager pod。


另外，STANDALONE 模式 则是传统的仅将 Kubernetes 作为 Flink 集群运行的编排平台，对应两个特点：
- Flink 集群不清楚自身运行在 Kubernetes 集群
- Flink 框架和作业程序都无权限访问 Kubernetes 集群，这能提高安全性

上述是集群的部署双模式声明：NATIVE 和 STANDALONE 模式。

Flink Operator 还有另一个双模式值得注意，就是其支持 Flink Cluster 的 Application 和 Session 两种集群模式，这两者的差异只在于 job (JobSpec) 字段是否声明的区别。当声明 job 字段，对应 Application mode，反之则是 Session mode。

#### FlinkDeployment 状态设计

FlinkDeployment 的 status 对应的类是 FlinkDeploymentStatus，它继承了 CommonStatus 类，因此它也包含 jobStatus、error、observedGeneration、lifecycleState 这几个字段。对应代码如下：

```java
@Experimental
@Data
@AllArgsConstructor
@NoArgsConstructor
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@SuperBuilder
@JsonIgnoreProperties(ignoreUnknown = true)
public class FlinkDeploymentStatus extends CommonStatus<FlinkDeploymentSpec> {

    /** 运行中集群的信息。 */
    private Map<String, String> clusterInfo = new HashMap<>();

    /** JobManager 部署的最新观测状态。 */
    private JobManagerDeploymentStatus jobManagerDeploymentStatus =
            JobManagerDeploymentStatus.MISSING;

    /** 上一次调谐操作的状态。 */
    private FlinkDeploymentReconciliationStatus reconciliationStatus =
            new FlinkDeploymentReconciliationStatus();

    /** 用于扩缩容子资源的 TaskManager 信息。 */
    private TaskManagerInfo taskManager;
}
```

其中，clusterInfo 对应的是集群的元信息，比如集群的版本、配置等。一般是通过 Flink Rest API 获取的集群信息的缓存。jobManagerDeploymentStatus 对应的是 JobManager 的部署状态，对应代码如下：

```java
public enum JobManagerDeploymentStatus {
    /** JobManager 已经运行并且可以接收 REST API 调用。 */
    READY,

    /** JobManager 已经运行但还不能接收 REST API 调用。 */
    DEPLOYED_NOT_READY,

    /** JobManager 进程正在启动中。 */
    DEPLOYING,

    /** 未找到 JobManager 部署，可能尚未启动或被用户杀死。 */
    // TODO: 当前是 SUSPENDED 和 ERROR 的混合状态，需要进一步清理
    MISSING,

    /** 部署处于终态错误，需要修改 spec 后才能继续调谐。 */
    ERROR;
```

reconciliationStatus 对应的是上一次调谐操作的状态，对应代码如下：

```java
@Data
@NoArgsConstructor
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@JsonIgnoreProperties(ignoreUnknown = true)
public class FlinkDeploymentReconciliationStatus extends ReconciliationStatus<FlinkDeploymentSpec> {

    @Override
    public Class<FlinkDeploymentSpec> getSpecClass() {
        return FlinkDeploymentSpec.class;
    }
}
```
FlinkDeploymentReconciliationStatus 主要设计就是继承了 ReconciliationStatus 类。对应字段信息与 ReconciliationStatus 类一致。

taskManager 对应的是 TaskManager 的部署状态，主要是两个信息，一个是 labelSelector 对应的是 TaskManager 的 labelSelector，另一个是 replicas 对应的是 TaskManager 的副本数。


#### FlinkSessionJob 作业提交声明

FlinkSessionJob 多数配置都来源于  AbstractFlinkSpec

```java
public class FlinkSessionJobSpec extends AbstractFlinkSpec {
    private String deploymentName;  // 唯一必需的字段
}
```

唯一额外的字段就是 deploymentName，这对应了 FlinkDeployment 的 name 字段。
真实配置时会显得复杂，举个完整例子如下：
```yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkSessionJob
metadata:
  name: basic-session-job-example2
spec:
  deploymentName: basic-session-deployment-example
  flinkConfiguration:
    taskmanager.numberOfTaskSlots: "2"
    state.savepoints.dir: file:///flink-data/savepoints
    state.checkpoints.dir: file:///flink-data/checkpoints
    high-availability.type: kubernetes
    high-availability.storageDir: file:///flink-data/ha
  job:
    jarURI: https://repo1.maven.org/maven2/org/apache/flink/flink-examples-streaming_2.12/1.16.1/flink-examples-streaming_2.12-1.16.1.jar
    parallelism: 2
    upgradeMode: stateless
    entryClass: org.apache.flink.streaming.examples.statemachine.StateMachineExample
```

#### FlinkDeployment 模版设计

通过`PodTemplateSpec`实现的配置继承机制：
```yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment
metadata:
  name: pod-template-example
spec:
  image: flink:1.17
  flinkVersion: v1_17
  flinkConfiguration:
    taskmanager.numberOfTaskSlots: "2"
  serviceAccount: flink
  podTemplate:
    spec:
      containers:
        # Do not change the main container name
        - name: flink-main-container
          volumeMounts:
            - mountPath: /opt/flink/log
              name: flink-logs
            - mountPath: /opt/flink/downloads
              name: downloads
        # Sample sidecar container for log forwarding
        - name: fluentbit
          image: fluent/fluent-bit:1.9.6-debug
          command: [ 'sh','-c','/fluent-bit/bin/fluent-bit -i tail -p path=/flink-logs/*.log -p multiline.parser=java -o stdout' ]
          volumeMounts:
            - mountPath: /flink-logs
              name: flink-logs
      volumes:
        - name: flink-logs
          emptyDir: { }
        - name: downloads
          emptyDir: { }
  jobManager:
    resource:
      memory: "2048m"
      cpu: 1
    podTemplate:
      spec:
        initContainers:
          # Sample init container for fetching remote artifacts
          - name: busybox
            image: busybox:1.35.0
            volumeMounts:
              - mountPath: /opt/flink/downloads
                name: downloads
            command:
            - /bin/sh
            - -c
            - "wget -O /opt/flink/downloads/flink-examples-streaming.jar \
              https://repo1.maven.org/maven2/org/apache/flink/flink-examples-streaming_2.12/1.16.1/flink-examples-streaming_2.12-1.16.1.jar"
  taskManager:
    resource:
      memory: "2048m"
      cpu: 1
  job:
    jarURI: local:///opt/flink/downloads/flink-examples-streaming.jar
    entryClass: org.apache.flink.streaming.examples.statemachine.StateMachineExample
    parallelism: 2

```

这是官方代码仓库中讲解 podTemplate 如何生效的例子，主要是以下几个要点：
- FlinkDeployment 本身有一个 PodTemplate，这里主要是挂载两个 emptyDir 类型的持久卷 flink-logs 和 downloads，分别是用来采集日志和保存下载的作业 jar 包
- FlinkDeployment 的 PodTemplate 是同时作用 TaskManager 和 JobManager 的，所以名为 fluent 的 sidecar 容器的作用是采集所有组件的日志
- JobManager 的 PodTemplate 主要是声明一个初始容器，用来下载作业的 jar 包
- job.jarURI 指向的作业 jar 包地址就是 JobManager 的初始容器下载的 jar 包

总的来说，FlinkDeployment 的 podTemplate 是全局的，而 JobManager / TaskManager 中如果有 podTemplate 配置将覆盖全局配置或者补充全局配置。


## 3.3 Kubectl 的配置代码

不管是 FlinkDeployment 还是 FlinkSessionJob 都能够使用 kubectl 来进行查看，比如：
```shell
# flinkdep == FlinkDeployment
kubectl get flinkdep

# sessionjob == FlinkSessionJob
kubectl get sessionjob

# 你会看到输出：
NAME            JOB STATUS   LIFECYCLE STATE
basic-example   RUNNING      STABLE
```

我们先来说明一下如何实现 FlinkDeployment 和 FlinkSessionJob 的缩写的，这里对应的代码如下：
```java
@Experimental
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonDeserialize()
@Group(CrdConstants.API_GROUP)
@Version(CrdConstants.API_VERSION)
@ShortNames({"sessionjob"}) // 这里对应配置了缩写
public class FlinkSessionJob
        extends AbstractFlinkResource<FlinkSessionJobSpec, FlinkSessionJobStatus>
        implements Namespaced {
        // methods
}


@Experimental
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonDeserialize()
@Group(CrdConstants.API_GROUP)
@Version(CrdConstants.API_VERSION)
@ShortNames({"flinkdep"}) // 这里对应配置了缩写
public class FlinkDeployment
        extends AbstractFlinkResource<FlinkDeploymentSpec, FlinkDeploymentStatus>
        implements Namespaced {
      // methods
}
```

另外，我们来说明一下输出中的 NAME、JOB STATUS、LIFECYCLE STATE 这三列信息如何来的？

其中的 NAME，是对应资源的 metadata.name，这个不管是 CR 还是内置的资源对象，都是如此。
JOB STATUS 和 LIFECYCLE STATE 由 Fabric8 generator-annotation 库的 @PrinterColumn 注解来实现
JOB STATUS 对应的是 job 的实现类 JobStatus 中对应 Flink 作业状态的 state，对应代码段如下：
```java
public class JobStatus {
    // other members

    /** Last observed state of the job. */
    @PrinterColumn(name = "Job Status")
    private org.apache.flink.api.common.JobStatus state;

    // other members & methods
}
```

LIFECYCLE STATE 对应的 status 的抽象类 CommonStatus 中对应的 lifecycleState，对应代码段如下：

```java
public abstract class CommonStatus<SPEC extends AbstractFlinkSpec> {

    // other members

    /** Lifecycle state of the Flink resource (including being rolled back, failed etc.). */
    @PrinterColumn(name = "Lifecycle State")
    // Calculated from the status, requires no setter. The purpose of this is to expose as a printer
    // column.
    private ResourceLifecycleState lifecycleState;

    // other members and methods
}
```

## 3.4 Diff 机制代码

Diff 机制，是为了从大量的配置信息中抽取需要关注的和过滤不需要关注的信息的机制，并且封装了一些工具方法来提取和生成对应的信息，从而简化对比前后配置的难度。

具体设计是参考 apache.commons.lang3 里的实现中的 Diff，DiffResul，DiffBuilder 等核心实现，但最核心的主要还是重写了 ReflectiveDiffBuilder 的 appendFileds 的方法，这里最核心的就是设计了 SpecDiff 注解，来达成上述的目的。


### Diff、DiffResult 类

Diff 类是单一的不同的包装类，主要的成员变量是：
- String fieldName
- T left
- T right
- DiffType type

其中T是泛型占位符，DiffType 是一个枚举类，包含如下三种：
- IGNORE （忽略差异）对应是0
- SCALE （关注大小差异）对应是1
- UPGRADE （关注版本升级差异）对应是2

是用来标记对应字段需要关注的方式。

DiffResult 是多个差异的包装类，主要成员变量是：
- List<Diff<?>> diffList
- T left
- T right
- DiffType type

当出现多个 Diff 的时候，决定 DiffType 的方式就需要特别的逻辑，一句话概括就是取最大的，如果 List 里面有一个 UPGRADE，那么 DiffResult 的 type 就是 UPGRADE。

### 接口 Diffable & 注解 SpecDiff

接口Diffable是用来声明，这个类的实例是可以被用来和同类型的实例做字段的对比，这个就一个接口。

需要使用 SpecDiff 注解的类都需要实现这个 Diffable 接口。

SpecDiff 注解是设计上用来标识，每个字段比较的不同方式，以及是否需要进一步处理。

SpecDiff 有包含两个接口：
- @interface Config 
- @interface Entry 

Config 接口包含 Entry 接口，Entry 接口主要是用来标注在 flink.conf 类似的文字段的配置上，Entry接口定义了两个成员函数：
- String prefix()
- DiffType type()

其中 prefix 是用来筛选字段的前缀的，type是用来筛选配置的类型的。

具体例子如下：
```java
public abstract class AbstractFlinkSpec implements Diffable<AbstractFlinkSpec> {

    // other members
    
    // if not set, just ignore
    @SpecDiff(onNullIgnore = true)
    private Long restartNonce;

    // check prefix and check these config changes
    @SpecDiff.Config({
        @SpecDiff.Entry(prefix = "job.autoscaler", type = DiffType.IGNORE),
        @SpecDiff.Entry(prefix = "parallelism.default", type = DiffType.IGNORE),
        @SpecDiff.Entry(prefix = "kubernetes.operator", type = DiffType.IGNORE),
        @SpecDiff.Entry(
                prefix = "pipeline.jobvertex-parallelism-overrides",
                type = DiffType.SCALE,
                mode = KubernetesDeploymentMode.NATIVE)
    })
    private Map<String, String> flinkConfiguration;
}
```

### DiffBuilder 和 ReflectiveDiffBuilder

DiffBuilder 是继承了apache.commons.lang3 包域名里的Builder接口，对应的核心接口是 build。

ReflectiveDiffBuilder 和 DiffBuilder 本身都在 apache.commons.lang3 包里有对应实现，但是这里重载的目的，主要在于 ReflectiveDiffBuilder 利用 SpecDiff 注解，来做逐一逻辑适配。

这里Operator的主要的代码段有两个：
```java
var specDiff = new ReflectiveDiffBuilder<>(currentDeploySpec, lastReconciledSpec).build();

boolean specChanged = DiffType.IGNORE != specDiff.getType()
    || reconciliationStatus.getState() == ReconciliationState.UPGRADING;
```
用户可以直接认为，ReflectiveDiffBuilder 调用 build() 方法之后获得的是一个 DiffResult，这里后续就只判断了 DiffResult 的 type。（对应变更点可能很多，但是这里operator只需要知道是否有关注字段的变更）。

至于 ReflectiveDiffBuilder 的 build 的内部实现，其实就是一堆Java的反射和值对比的逻辑，这里是比较偏工具类的。

### ReflectiveDiffBuilder 差异检测时序图

下面通过时序图来详细展示 ReflectiveDiffBuilder 的差异检测流程：

{{< mermaid >}}
sequenceDiagram
    participant Reconciler as AbstractFlinkResourceReconciler
    participant ReflectiveBuilder as ReflectiveDiffBuilder
    participant SpecAnalyzer as SpecDiff注解分析器
    participant DiffBuilder as DiffBuilder
    participant DiffResult as DiffResult聚合器

    Reconciler->>ReflectiveBuilder: 创建实例<br/>ReflectiveDiffBuilder(deploymentMode,<br/>beforeSpec, afterSpec)
    ReflectiveBuilder->>DiffBuilder: 初始化DiffBuilder(before, after)

    Reconciler->>ReflectiveBuilder: 调用build()开始差异检测

    loop 遍历所有字段
        ReflectiveBuilder->>SpecAnalyzer: 获取字段SpecDiff注解
        SpecAnalyzer-->>ReflectiveBuilder: 返回注解配置<br/>{value, mode, onNullIgnore}

        alt 字段有SpecDiff注解
            ReflectiveBuilder->>ReflectiveBuilder: 检查部署模式匹配
            ReflectiveBuilder->>ReflectiveBuilder: 处理空值(onNullIgnore)

            alt 字段是Map类型且有Config注解
                ReflectiveBuilder->>SpecAnalyzer: 解析Config.Entry配置
                SpecAnalyzer-->>ReflectiveBuilder: 返回配置映射
                loop 遍历Map每个键值对
                    ReflectiveBuilder->>DiffBuilder: append(fieldName, oldValue,<br/>newValue, diffType)
                end
            else 普通字段
                ReflectiveBuilder->>DiffBuilder: append(fieldName, oldValue,<br/>newValue, annotation.value)
            end
        else 无注解字段
            ReflectiveBuilder->>DiffBuilder: append(fieldName, oldValue,<br/>newValue, UPGRADE)
        end
    end

    ReflectiveBuilder->>DiffBuilder: 调用build()生成结果
    DiffBuilder->>DiffResult: 创建结果对象(diffs列表)
    DiffResult->>DiffResult: 聚合所有DiffType<br/>max(ordinal)确定最终类型

    DiffResult-->>ReflectiveBuilder: 返回DiffResult
    ReflectiveBuilder-->>Reconciler: 返回最终差异结果
{{< /mermaid >}}

这个时序图展示了 ReflectiveDiffBuilder 的完整差异检测流程：

1. 初始化阶段：Reconciler 创建 ReflectiveDiffBuilder 实例，传入部署模式和前后规格
2. 字段遍历：通过反射遍历所有字段，获取每个字段的 SpecDiff 注解
3. 注解处理：根据注解配置决定差异检测策略（IGNORE/SCALE/UPGRADE）
4. 特殊处理：对 Map 类型的配置字段进行特殊处理，支持前缀匹配
5. 差异收集：将检测到的差异添加到 DiffBuilder 中
6. 结果聚合：最终聚合所有差异，确定整体的 DiffType

这个机制确保了 Flink Operator 能够精确识别配置变更，并据此决定是否需要执行相应的协调操作。

### 实际应用示例

以FlinkDeploymentSpec为例：

{{< mermaid >}}
sequenceDiagram
    participant Spec as FlinkDeploymentSpec
    participant Reflective as ReflectiveDiffBuilder
    participant Builder as DiffBuilder

    Spec->>Reflective: 比较两个FlinkDeploymentSpec实例
    Note over Spec: 字段示例：<br/>- restartNonce (SpecDiff.UPGRADE)<br/>- flinkConfiguration (SpecDiff.Config)<br/>- job.parallelism (SpecDiff.SCALE)

    Reflective->>Reflective: 处理restartNonce
    Reflective->>Builder: append("restartNonce", old, new, UPGRADE)

    Reflective->>Reflective: 处理flinkConfiguration
    loop 遍历配置项
        Reflective->>Builder: append("flinkConfiguration.key", oldVal, newVal, IGNORE/SCALE)
    end

    Reflective->>Reflective: 处理job.parallelism
    Reflective->>Builder: append("job.parallelism", old, new, SCALE)

    Builder-->>Reflective: 返回DiffResult<br/>类型=max(UPGRADE, IGNORE, SCALE) = UPGRADE
{{< /mermaid >}}

这个时序图展示了SpecDiff注解如何在运行时驱动差异检测过程，实现了声明式的差异分类机制。

