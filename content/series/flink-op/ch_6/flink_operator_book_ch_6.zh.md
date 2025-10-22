---
title: "FlinkService 与 Flink Kubernetes HA"
date: 2025-07-24T23:44:58+08:00
draft: true
description: ""
---

## 6.1 FlinkService 源码解析

我们在第五章节讲解 Controller 源码时，在实际部署和调用 Flink 的 REST API 时都提到了 FlinkService。FlinkService 是 Flink Operator 封装 Flink REST API 调用和集群部署逻辑的主要接口。

FlinkService 定义了统一的接口，并使用模版方法模式，定义了抽象类 AbstractFlinkService 来定义通用的作业处理逻辑、集群处理逻辑和保存点/检查点的处理逻辑，然后根据不同的部署模式来定义不同的实现类中集群部署和作业取消逻辑，如NativeFlinkService 和 StandaloneFlinkService。类图如下：

{{< mermaid >}}
classDiagram
    class FlinkService {
        +getKubernetesClient() KubernetesClient
        +submitApplicationCluster(JobSpec, Configuration, boolean) void
        +isHaMetadataAvailable(Configuration) boolean
        +atLeastOneCheckpoint(Configuration) boolean
        +submitSessionCluster(Configuration) void
        +submitJobToSessionCluster(ObjectMeta, FlinkSessionJobSpec, JobID, Configuration, String) JobID
        +isJobManagerPortReady(Configuration) boolean
        +getJobStatus(Configuration, JobID) Optional~JobStatusMessage~
        +requestJobResult(Configuration, JobID) JobResult
        +cancelJob(FlinkDeployment, SuspendMode, Configuration) CancelResult
        +deleteClusterDeployment(ObjectMeta, FlinkDeploymentStatus, Configuration, boolean) void
        +cancelSessionJob(FlinkSessionJob, SuspendMode, Configuration) CancelResult
        +triggerSavepoint(String, SavepointFormatType, String, Configuration) String
        +triggerCheckpoint(String, CheckpointType, Configuration) String
        +getLastCheckpoint(JobID, Configuration) Optional~Savepoint~
        +fetchSavepointInfo(String, String, Configuration) SavepointFetchResult
        +fetchCheckpointInfo(String, String, Configuration) CheckpointFetchResult
        +fetchCheckpointStats(String, Long, Configuration) CheckpointStatsResult
        +getCheckpointInfo(JobID, Configuration) Tuple2~Optional~CompletedCheckpointInfo~,Optional~PendingCheckpointInfo~~
        +disposeSavepoint(String, Configuration) void
        +getClusterInfo(Configuration) Map~String,String~
        +getJmPodList(FlinkDeployment, Configuration) PodList
        +scale(FlinkResourceContext, Configuration) boolean
        +getMetrics(Configuration, String, List~String~) Map~String,String~
        +getClusterClient(Configuration) RestClusterClient~String~
    }

    class AbstractFlinkService {
        #kubernetesClient: KubernetesClient
        #executorService: ExecutorService
        #operatorConfig: FlinkOperatorConfiguration
        #artifactManager: ArtifactManager
        +getKubernetesClient() KubernetesClient
        +submitApplicationCluster(JobSpec, Configuration, boolean) void
        +submitSessionCluster(Configuration) void
        +isHaMetadataAvailable(Configuration) boolean
        +atLeastOneCheckpoint(Configuration) boolean
        +submitJobToSessionCluster(ObjectMeta, FlinkSessionJobSpec, JobID, Configuration, String) JobID
        +isJobManagerPortReady(Configuration) boolean
        +getJobStatus(Configuration, JobID) Optional~JobStatusMessage~
        +requestJobResult(Configuration, JobID) JobResult
        +cancelSessionJob(FlinkSessionJob, SuspendMode, Configuration) CancelResult
        +cancelJobOrError(RestClusterClient, CommonStatus, boolean) void
        +savepointJobOrError(RestClusterClient, CommonStatus, Configuration) String
        +triggerSavepoint(String, SavepointFormatType, String, Configuration) String
        +triggerCheckpoint(String, CheckpointType, Configuration) String
        +getLastCheckpoint(JobID, Configuration) Optional~Savepoint~
        +disposeSavepoint(String, Configuration) void
        +fetchSavepointInfo(String, String, Configuration) SavepointFetchResult
        +fetchCheckpointInfo(String, String, Configuration) CheckpointFetchResult
        +fetchCheckpointStats(String, Long, Configuration) CheckpointStatsResult
        +getCheckpointInfo(JobID, Configuration) Tuple2~Optional~CompletedCheckpointInfo~,Optional~PendingCheckpointInfo~~
        +getClusterInfo(Configuration) Map~String,String~
        +getJmPodList(FlinkDeployment, Configuration) PodList
        +getClusterClient(Configuration) RestClusterClient~String~
        +getMetrics(Configuration, String, List~String~) Map~String,String~
        +deleteClusterDeployment(ObjectMeta, FlinkDeploymentStatus, Configuration, boolean) void
        #getJmPodList(String, String) PodList*
        #deployApplicationCluster(JobSpec, Configuration) void*
        #deploySessionCluster(Configuration) void*
        #getSocketAddress(RestClusterClient) SocketAddress
        #cancelJob(FlinkDeployment, SuspendMode, Configuration, boolean) CancelResult
        #runJar(RestClusterClient, String, String, String, Configuration) void
        #uploadJar(RestClusterClient, String, Configuration) JarUploadResponseBody
        #getRestClient(Configuration) RestClient
        #deleteDeploymentBlocking(String, String, Configuration) Duration
        #removeOperatorConfigs(Configuration) Configuration
        #deleteClusterInternal(ObjectMeta, FlinkDeploymentStatus, Configuration, boolean) void*
        #deleteHAData(String, String, Configuration) void
        #updateStatusAfterClusterDeletion(FlinkDeploymentStatus) void
        #deleteBlocking(String, String, Configuration) Duration
    }

    class NativeFlinkService {
        +deploySessionCluster(Configuration) void
        +cancelJob(FlinkDeployment, SuspendMode, Configuration) CancelResult
        +scale(FlinkResourceContext, Configuration) boolean
        #deployApplicationCluster(JobSpec, Configuration) void
        #getJmPodList(String, String) PodList
        #submitClusterInternal(Configuration) void
        #deleteClusterInternal(ObjectMeta, FlinkDeploymentStatus, Configuration, boolean) void
        #updateVertexResources(FlinkResourceContext, Configuration, Map) void
        #getVertexResources(Configuration, JobID) Map~JobVertexID,JobVertexResourceRequirements~
    }

    class StandaloneFlinkService {
        +deploySessionCluster(Configuration) void
        +cancelJob(FlinkDeployment, SuspendMode, Configuration) CancelResult
        +scale(FlinkResourceContext, Configuration) boolean
        #deployApplicationCluster(JobSpec, Configuration) void
        #getJmPodList(String, String) PodList
        #createNamespacedKubeClient(Configuration) FlinkStandaloneKubeClient
        #submitClusterInternal(Configuration, Mode) void
        #deleteClusterInternal(ObjectMeta, FlinkDeploymentStatus, Configuration, boolean) void
    }

    class CancelResult {
        +completed(String) CancelResult
        +pending() CancelResult
        +getSavepointPath() Optional~String~
    }

    FlinkService <|.. AbstractFlinkService : implements
    AbstractFlinkService <|-- NativeFlinkService : extends
    AbstractFlinkService <|-- StandaloneFlinkService : extends
    FlinkService --> CancelResult : returns

{{< /mermaid >}}

类图中，

- FlinkService 接口：定义了所有 Flink 服务操作的标准接口，包括集群部署、作业管理、检查点操作等核心功能。

- AbstractFlinkService 抽象类：提供了大部分通用实现，包括：
    - 集群部署管理类
        - submitApplicationCluster(): 部署应用集群，作业与集群生命周期绑定
        - submitSessionCluster(): 部署会话集群，支持多个作业共享集群资源
        - deleteClusterDeployment(): 删除集群部署，支持选择性删除HA数据
        - deployApplicationCluster()*: 抽象方法，具体实现集群部署逻辑
        - deploySessionCluster()*: 抽象方法，具体实现会话集群部署逻辑
        - deleteClusterInternal()*: 抽象方法，具体实现集群删除逻辑
    - 作业生命周期管理类
        - submitJobToSessionCluster(): 向会话集群提交作业
        - getJobStatus(): 获取作业运行状态
        - requestJobResult(): 请求作业执行结果
        - cancelJob(): 取消应用集群中的作业，支持多种挂起模式
        - cancelSessionJob(): 取消会话集群中的作业
        - cancelJobOrError(): 取消作业或处理错误
        - savepointJobOrError(): 创建保存点或处理错误
    - 检查点与保存点管理类
        - triggerSavepoint(): 触发保存点创建
        - triggerCheckpoint(): 触发检查点创建
        - getLastCheckpoint(): 获取最新的检查点信息
        - fetchSavepointInfo(): 获取保存点操作结果
        - fetchCheckpointInfo(): 获取检查点操作结果
        - fetchCheckpointStats(): 获取检查点统计信息
        - getCheckpointInfo(): 获取检查点历史信息
        - disposeSavepoint(): 删除指定的保存点
    - 集群监控与信息获取类
        - getClusterInfo(): 获取集群基本信息（版本、CPU、内存等）
        - getJmPodList(): 获取JobManager Pod列表
        - getJmPodList()*: 抽象方法，具体实现获取JobManager Pod列表
        - getMetrics(): 获取作业或集群指标数据
        - isJobManagerPortReady(): 检查JobManager端口是否就绪
    - 高可用性管理类
        - isHaMetadataAvailable(): 检查HA元数据是否可用
        - atLeastOneCheckpoint(): 检查是否至少有一个检查点
    - 扩缩容管理类
        - scale(): 执行集群或作业的扩缩容操作
    - 工具与辅助类
        - getKubernetesClient(): 获取Kubernetes客户端
        - getClusterClient(): 获取Flink集群REST客户端
        - getSocketAddress(): 获取Socket地址
        - runJar(): 运行JAR文件
        - uploadJar(): 上传JAR文件
        - getRestClient(): 获取REST客户端
        - removeOperatorConfigs(): 移除Operator配置
        - deleteHAData(): 删除HA数据
        - updateStatusAfterClusterDeletion(): 更新集群删除后状态
        - deleteDeploymentBlocking(): 阻塞删除部署
        - deleteBlocking(): 阻塞删除

- NativeFlinkService：基于 Flink 原生 Kubernetes 集成实现，具体实现方法：
    - deployApplicationCluster(): 实现应用集群部署
    - getJmPodList(): 实现获取JobManager Pod列表
    - submitClusterInternal(): 内部提交集群逻辑
    - deleteClusterInternal(): 实现删除集群内部逻辑
    - updateVertexResources(): 更新顶点资源
    - getVertexResources(): 获取顶点资源

- StandaloneFlinkService：基于独立 Kubernetes 部署实现，具体实现方法：
    - deployApplicationCluster(): 实现应用集群部署
    - getJmPodList(): 实现获取JobManager Pod列表
    - createNamespacedKubeClient(): 创建命名空间Kubernetes客户端
    - submitClusterInternal(): 内部提交集群逻辑
    - deleteClusterInternal(): 实现删除集群内部逻辑

为了更好地理解前一章节中的调谐逻辑的集群部署、作业提交和取消逻辑、以及保存点/检查点的处理逻辑，我们将分为三个部分展开讲解。

### 6.1.1 保存点/检查点处理逻辑

### 6.1.2 集群部署逻辑

在集群部署逻辑中，

#### NativeFlinkService 集群部署逻辑

#### StandaloneFlinkService 集群部署逻辑

### 6.1.3 作业提交和取消逻辑

#### NativeFlinkService 作业提交和取消逻辑

#### StandaloneFlinkService 作业提交和取消逻辑

## 6.2 Flink Kubernetes HA 解析

