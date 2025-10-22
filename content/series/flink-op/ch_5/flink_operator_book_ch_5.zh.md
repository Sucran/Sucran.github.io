---
title: "Controller 源码解析"
date: 2025-02-24T23:44:58+08:00
draft: false
description: ""
---

本章将深入解析 FlinkOperator 中两个核心控制器的源码实现：FlinkDeploymentController 和 FlinkSessionJobController。我们将重点分析它们如何实现 Java Operator SDK 的 Reconciler 接口 的 `reconcile` 方法的实现逻辑。读者在阅读时可能需要回顾第三章的 CRD 结构和第四章的插件机制，为了更好的阅读体验，我们会适当重复一些核心概念。

## 5.1 共有设计模式

### 5.1.1 观察模式 - Observer

观察模式（Observer Pattern）是 Flink Kubernetes Operator 中用于监控和观察 Flink 应用状态变化的核心设计模式。该模式通过定义统一的观察接口，让不同的观察器能够独立地监控 Flink 应用的各种状态，如作业状态、集群健康状态、快照状态等，并将观察到的状态变化反映到 Kubernetes 资源上。

FlinkDeploymentController 和 FlinkSessionJobController 都继承自 Java Operator SDK 的 Reconciler 接口，以 `reconcile` 方法为核心实现调谐逻辑。在调谐过程中，通常遵循"观察 - 验证 - 调谐"的主要顺序，其中观察阶段负责收集当前状态，验证阶段检查配置有效性，调谐阶段执行必要的操作来达到期望状态。

观察模式的核心接口是 Observer，它定义了观察 Flink 应用状态的标准方法。以下是 Observer 接口的源码：

```java
public interface Observer<CR extends AbstractFlinkResource<?, ?>> {
    /**
     * Observe the flinkApp status, It will reflect the changed status on the flinkApp resource.
     *
     * @param ctx the context with which the operation is executed
     */
    void observe(FlinkResourceContext<CR> ctx);
}
```

**Observer 类层次结构**

{{< mermaid >}}
classDiagram
    class Observer {
        +observe(ctx)
    }
    
    class AbstractFlinkResourceObserver {
        +observeInternal(ctx)*
    }
    
    class AbstractFlinkDeploymentObserver {
        +observeInternal(ctx)*
    }
    
    class FlinkSessionJobObserver {
        +observeInternal(ctx)
    }
    
    class SessionObserver {
        +observeFlinkCluster(ctx)
    }
    
    class ApplicationObserver {
        +observeFlinkCluster(ctx)
    }
    
    Observer <|.. AbstractFlinkResourceObserver
    AbstractFlinkResourceObserver <|-- AbstractFlinkDeploymentObserver
    AbstractFlinkResourceObserver <|-- FlinkSessionJobObserver
    AbstractFlinkDeploymentObserver <|-- SessionObserver
    AbstractFlinkDeploymentObserver <|-- ApplicationObserver
{{< /mermaid >}}

**AbstractFlinkResourceObserver 的 observe 方法源码**

```java
@Override
public final void observe(FlinkResourceContext<CR> ctx) {
    // 检查资源是否准备好被观察（在特定状态下如暂停应用、升级回滚进行中时不需要观察）
    if (!isResourceReadyToBeObserved(ctx)) {
        return;
    }

    // 触发资源特定的观察逻辑
    observeInternal(ctx);

    // 重置快照触发器
    SnapshotUtils.resetSnapshotTriggers(
            ctx.getResource(), eventRecorder, ctx.getKubernetesClient());
}
```

**子类方法调用关系分析**

Observer 模式中的子类方法调用关系遵循模板方法模式的设计思想。整个调用链路从 `AbstractFlinkResourceObserver` 的 `observeInternal` 方法开始，通过多态机制分发到具体的子类实现。

1. `observe` - 模板方法入口（具体实现）
     - 定义在AbstractFlinkResourceObserver中的标准观察流程

2. `observeInternal` - CR资源特定观察
    - AbstractFlinkDeploymentObserver 实现的方法处理 FlinkDeployment 资源的观察
    - FlinkSessionJobObserver 实现的方法处理 FlinkSessionJob 资源的观察
    - 这两个子类定义了 observeFlinkCluster 抽象方法供子类实现

3. `observeFlinkCluster` - 集群模式特定观察
    - 由SessionObserver和ApplicationObserver分别实现Session模式和Application模式的集群观察
    - 会话模式：检查REST服务可用性
    - 应用模式：作业状态+快照状态+健康检查

4. 专门观察器调用（组合模式）
    - JobStatusObserver：作业状态同步
    - SnapshotObserver：快照状态管理
    - ClusterHealthObserver：集群健康监控

具体的调用关系，可以从这个时序图中看出：

**观察器调用时序图**

{{< mermaid >}}
sequenceDiagram
      participant Controller as Controller
      participant Observer as Observer
      participant AbstractFlinkResourceObserver as AbstractFlinkResourceObserver
      participant AbstractFlinkDeploymentObserver as AbstractFlinkDeploymentObserver
      participant SessionObserver as SessionObserver
      participant ApplicationObserver as ApplicationObserver
      participant JobStatusObserver as JobStatusObserver
      participant SnapshotObserver as SnapshotObserver
      participant ClusterHealthObserver as ClusterHealthObserver
      participant FlinkSessionJobObserver as FlinkSessionJobObserver


      rect rgb(255, 245, 240)
          Note left of Controller: 核心观察流程
          Controller->>Observer: observe(ctx)
          Observer->>AbstractFlinkResourceObserver: observe(ctx)

          alt 资源准备就绪
              AbstractFlinkResourceObserver->>AbstractFlinkResourceObserver: isResourceReadyToBeObserved(ctx)
              AbstractFlinkResourceObserver->>AbstractFlinkResourceObserver: observeInternal(ctx)

              alt FlinkDeployment资源
                  AbstractFlinkResourceObserver->>AbstractFlinkDeploymentObserver: observeInternal(ctx)
                  AbstractFlinkDeploymentObserver->>AbstractFlinkDeploymentObserver: observeJmDeployment(ctx)
                  Note right of AbstractFlinkDeploymentObserver: 观察JobManager部署状态

                  alt JobManager已就绪
                      AbstractFlinkDeploymentObserver->>AbstractFlinkDeploymentObserver: observeFlinkCluster(ctx)

                      alt 会话模式
                          AbstractFlinkDeploymentObserver->>SessionObserver: observeFlinkCluster(ctx)
                          SessionObserver->>SessionObserver: 检查REST服务可用性
                      else 应用模式
                          AbstractFlinkDeploymentObserver->>ApplicationObserver: observeFlinkCluster(ctx)
                          ApplicationObserver->>JobStatusObserver: observe(ctx)

                          alt 找到作业
                              ApplicationObserver->>SnapshotObserver: observeSavepointStatus(ctx)
                              ApplicationObserver->>SnapshotObserver: observeCheckpointStatus(ctx)
                              ApplicationObserver->>ClusterHealthObserver: observe(ctx)
                          end
                      end

                      AbstractFlinkDeploymentObserver->>AbstractFlinkDeploymentObserver: observeClusterInfo(ctx)
                  end
              else FlinkSessionJob资源
                  AbstractFlinkResourceObserver->>FlinkSessionJobObserver: observeInternal(ctx)
                  FlinkSessionJobObserver->>JobStatusObserver: observe(ctx)

                  alt 找到作业
                      FlinkSessionJobObserver->>SnapshotObserver: observeSavepointStatus(ctx)
                      FlinkSessionJobObserver->>SnapshotObserver: observeCheckpointStatus(ctx)
                  end
              end
          end

          AbstractFlinkResourceObserver->>AbstractFlinkResourceObserver: resetSnapshotTriggers(ctx)
          Note right of AbstractFlinkResourceObserver: 重置快照触发器
      end
{{< /mermaid >}}

专门观察器的作用说明：

1. JobStatusObserver - 作业状态观察器，观察 Flink 作业的状态变化，包括运行状态、暂停状态、完成状态等
- 使用场景：在 ApplicationObserver 和 FlinkSessionJobObserver 中被调用，确保作业状态与 Kubernetes 资源状态同步

2. SnapshotObserver - 快照观察器， 观察和管理 Flink 的保存点（Savepoint）和检查点（Checkpoint）状态
- 使用场景：在 ApplicationObserver 和 FlinkSessionJobObserver 中被调用，确保快照操作的可靠性和状态一致性

3. ClusterHealthObserver - 集群健康观察器， 评估 Flink 集群的健康状态，监控集群的稳定性和性能指标
- 使用场景：仅在 ApplicationObserver 中被调用，为应用模式提供集群健康监控，帮助及时发现和处理集群问题

由于作业状态观察器与快照观察器，在 ApplicationObserver 和 FlinkSessionJobObserver 中都会被调用，作为通用的逻辑，我们也进一步进行分析。

#### 5.1.1.1 作业状态观察器

JobStatusObserver 的关键函数是 observe，该方法的源码如下：

```java
public boolean observe(FlinkResourceContext<R> ctx) {
    // 从上下文中获取 Flink 资源对象
    var resource = ctx.getResource();
    
    // 检查作业是否处于挂起状态，如果是则直接返回 false
    // 这里通过反序列化上次调谐的规格来获取作业状态
    if (resource.getStatus()
                    .getReconciliationStatus()
                    .deserializeLastReconciledSpec()
                    .getJob()
                    .getState()
            == JobState.SUSPENDED) {
        return false;
    }
    
    // 获取作业状态对象和前一状态，用于后续比较
    var jobStatus = resource.getStatus().getJobStatus();
    LOG.debug("Observing job status");
    var previousJobStatus = jobStatus.getState();

    try {
        // 通过 FlinkService 调用 Flink 集群的 REST API 获取最新的作业状态
        // 使用作业 ID 和观察配置来查询
        var newJobStatusOpt =
                ctx.getFlinkService()
                        .getJobStatus(
                                ctx.getObserveConfig(),
                                JobID.fromHexString(jobStatus.getJobId()));

        if (newJobStatusOpt.isPresent()) {
            // 如果找到目标作业，更新作业状态
            // updateJobStatus 方法会更新作业名称、状态、开始时间等信息
            updateJobStatus(ctx, newJobStatusOpt.get());
            
            // 检查并更新稳定规格，如果作业正在运行则标记为稳定
            // checkAndUpdateStableSpec 会检查作业是否处于稳定运行状态
            ReconciliationUtils.checkAndUpdateStableSpec(resource.getStatus());
            return true;
        } else {
            // 如果未找到目标作业，触发相应的处理逻辑
            // onTargetJobNotFound 会记录事件、设置错误状态，并根据升级模式决定是否挂起
            onTargetJobNotFound(ctx);
        }
    } catch (Exception e) {
        // 访问 REST API 时出现异常，稍后会重试
        LOG.warn("Exception while getting job status", e);
        
        // 如果之前作业处于运行状态，现在不确定了，将其状态改为 RECONCILING
        // ifRunningMoveToReconciling 确保状态一致性，避免误判
        ifRunningMoveToReconciling(jobStatus, previousJobStatus);
        
        // 如果是超时异常，触发超时处理回调
        // onTimeout 允许子类实现特定的超时处理逻辑
        if (e instanceof TimeoutException) {
            onTimeout(ctx);
        }
    }
    
    // 异常情况下返回 false，表示观察失败
    return false;
}
```

从代码和注释中，我们可以看出，对于作业的观察主要来自于 REST API 的调用，这里 observe 方法的返回值表示了是否获取到作业的状态。主要的核心逻辑就是更新 FlinkDeployment 或者 FlinkSessionJob 的 status.jobStatus 字段。

---

**回顾第三章中作业状态设计**

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

调谐状态 ReconciliationStatus 对应的是 资源从创建到稳定的标准演进路径：
```
CREATED → DEPLOYED → STABLE
    ↓        ↓
  FAILED  UPGRADING
```

这个状态路径对应了集群的部署状态，这个状态流转将由 FlinkDeployment 和 FlinkSessionJob 对应的控制器来观察记录。

---

如果请求 REST API 有找到目标作业，updateJobStatus 方法会更新的就是 JobStatus 类中的字段，包括作业的名称、状态、开始时间等信息。ReconciliationUtils.checkAndUpdateStableSpec 方法更新的是调谐状态，负责根据作业的状态来将状态从 DEPLOYED 切换到 STABLE，或者保持 STABLE 不变。

如果未找到目标作业，对应调用的是 onTargetJobNotFound 方法，这个方法首先是先利用 eventRecorder 发送找不到作业的 Warning 事件，接着分成两种情况：
1. 如果资源是 FlinkSessionJob 类型，作业不是终止状态且升级模式是 STATELESS，那么需要将作业状态修改为 SUSPENDED 挂起。这样下一次作业状态观察时，就会直接退出，但进行调谐时会进行作业的重新提交。
2. 如果不满足上述条件，那么需要将调谐状态设置为 DEPLOYED，等待用户手动干预。
最后会设置资源的status中的错误信息为：Job Not Found。

如果查询作业时抛出了异常，并且异常是超时的异常，那么这里分为两种情况：
1. 如果资源是 FlinkDeployment 类型，这时需要查看集群状态，而 ApplicationObserver 中实现了一个私有子类 ApplicationJobObserver 继承了 JobObserver，并实现了其 onTimeout 抽象方法。当抛出超时异常时会调用该方法，具体逻辑就是查看 JobManager 的 Deployment 的部署情况。
2. 如果资源是 FlinkSessionJob 类型，则不处理超时情况。

对于异常的处理，统一都是查看作业前一次状态是否为 RUNNING，如果是，则改为 RECONCILING。

总的来说，对于作业状态的观察，主要就是更新作业状态和调谐状态。这里修改作业状态的目的，就是为了在调谐阶段能够根据作业状态和升级模式来决定进行什么调谐操作。

#### 5.1.1.2 快照观察器

快照观察器，SnapshotObserver 的关键函数是 observeSavepointStatus 和 observeCheckpointStatus，这两个方法的源码如下：

```java
public void observeSavepointStatus(FlinkResourceContext<CR> ctx) {
    LOG.debug("Observing savepoint status");
    // 从上下文中获取 Flink 资源对象和作业状态信息
    var resource = ctx.getResource();
    var jobStatus = resource.getStatus().getJobStatus();
    var jobId = jobStatus.getJobId();

    // 检查是否有手动或周期性保存点正在进行中
    // savepointInProgress 通过检查 savepointInfo.triggerId 是否为空来判断
    if (SnapshotUtils.savepointInProgress(jobStatus)) {
        // 如果有保存点正在进行，观察其进度状态
        // observeTriggeredSavepoint 会调用 FlinkService.fetchSavepointInfo 获取最新状态
        // 处理成功、失败、进行中等不同状态，包括宽限期重试机制
        observeTriggeredSavepoint(ctx, jobId);
    }

    // 如果作业处于全局终止状态（如 FINISHED、FAILED、CANCELED），观察最新的检查点
    // isJobInTerminalState 检查作业是否已经完成或失败
    if (ReconciliationUtils.isJobInTerminalState(resource.getStatus())) {
        // observeLatestCheckpoint 获取作业的最后一个检查点信息
        // 这对于升级恢复和状态管理很重要
        observeLatestCheckpoint(ctx, jobId);
    }

    // 清理保存点历史记录，根据配置的最大数量和最大年龄策略
    // cleanupSavepointHistory 会删除过期的 FlinkStateSnapshot 资源
    // 同时清理旧的 savepointHistory 数组，并调用 disposeSavepoint 删除存储数据
    cleanupSavepointHistory(ctx);
}

public void observeCheckpointStatus(FlinkResourceContext<CR> ctx) {
    // 检查是否支持检查点触发功能
    // isSnapshotTriggeringSupported 验证配置是否启用了检查点功能
    if (!isSnapshotTriggeringSupported(ctx.getObserveConfig())) {
        return;
    }
    
    // 获取资源对象和作业状态信息
    var resource = ctx.getResource();
    var jobStatus = resource.getStatus().getJobStatus();
    var jobId = jobStatus.getJobId();

    // 检查是否有手动或周期性检查点正在进行中
    // checkpointInProgress 通过检查 checkpointInfo.triggerId 是否为空来判断
    if (SnapshotUtils.checkpointInProgress(jobStatus)) {
        // 如果有检查点正在进行，观察其进度状态
        // observeTriggeredCheckpoint 会调用 FlinkService.fetchCheckpointInfo 获取最新状态
        // 处理成功、失败、进行中等不同状态，包括宽限期重试机制
        observeTriggeredCheckpoint(ctx, jobId);
    }
}
```

需要注意的是，从 1.10 版本完成的提案 FLIP-446 新增了 FlinkStateSnapshot 自定义资源对象，用于存储保存点（Savepoint）和检查点（Checkpoint）的状态信息。对应的 SnapshotObserver 只是为了兼容旧版本，在 1.10 之前的版本，保存点（Savepoint）和检查点（Checkpoint）的状态信息是存储在 FlinkDeployment 和 FlinkSessionJob 的 status.jobStatus 字段，而 1.10 版本之后，这部分内容已经解藕到 FlinkStateSnapshot 资源对象以及其对应的控制器的逻辑，我们将在第7章节进行具体分析。这里我们不具体拆解与被标记为 @Deprecated 的代码关联的函数，而是关注其核心步骤。

从本质上来说，保存点的观察阶段有三个步骤：
1. 检查是否有保存点正在处理，如果有则请求 REST API 获取对应的保存点信息并更新到对应状态字段
2. 检查作业是否处于全局终止状态，如果是则获取作业的最新一个检查点信息并更新为对应状态字段的保存点字段
3. 检查保存点历史记录，并清理过期的保存点

检查点（Checkpoint）的观察阶段有两个步骤：
1. 检查 Flink 版本是否大于 1.17，只有当版本大于 1.17 时才有 REST API 触发检查点
2. 检查是否有保存点正在处理，如果有则请求 REST API 检查对应的检查点信息并更新到对应状态字段

### 5.1.2 调谐模式 - Reconciler

调谐模式（Reconciler Pattern）是 Kubernetes Operator 的核心设计模式，用于确保期望状态（Desired State）与实际状态（Actual State）的一致性。在 Flink Kubernetes Operator 中，调谐模式负责将用户定义的 Flink 应用配置转换为实际的 Kubernetes 资源，并持续监控和维护这些资源的状态。在调谐模式中 Reconciler 接口及其子类是关键，接着将重点拆解这些接口设计。 

#### 5.1.2.1 基础接口与类层次

**Reconciler 接口源码**

```java
public interface Reconciler<R> {
    /**
     * 调谐资源。
     *
     * @param context 执行操作的上下文
     */
    void reconcile(FlinkResourceContext<R> context) throws Exception;
    
    /**
     * 清理资源
     *
     * @param context 执行操作的上下文
     */
    void cleanup(FlinkResourceContext<R> context);
}
```

**调谐器类层次结构**

{{< mermaid >}}
classDiagram
    class Reconciler {
        +reconcile(context)
        +cleanup(context)
    }
    
    class AbstractFlinkResourceReconciler {
        +reconcile(context)
        +cleanup(context)
        *readyToReconcile(context)
        *reconcileSpecChange(context)
        *reconcileOtherChanges(context)
        *deploy(context)
        *cleanupInternal(context)
    }
    
    class AbstractJobReconciler {
        +readyToReconcile(context)
        +reconcileSpecChange(context)
        +reconcileOtherChanges(context)
        *cancelJob(context)
        *cleanupAfterFailedJob(context)
        +getJobUpgrade(context, deployConfig)
        +restoreJob(context, spec, deployConfig, requireHaMetadata)
        +resubmitJob(context, requireHaMetadata)
    }
    
    class SessionReconciler {
        +readyToReconcile(context)
        +reconcileSpecChange(context)
        +reconcileOtherChanges(context)
        +deploy(context)
        +cleanupInternal(context)
    }
    
    class ApplicationReconciler {
        +reconcileOtherChanges(context)
        +deploy(context)
        +cancelJob(context)
        +cleanupAfterFailedJob(context)
        +cleanupInternal(context)
        +getJobUpgrade(context, deployConfig)
    }
    
    class SessionJobReconciler {
        +readyToReconcile(context)
        +deploy(context)
        +cancelJob(context)
        +cleanupAfterFailedJob(context)
        +cleanupInternal(context)
    }
    
    Reconciler <|.. AbstractFlinkResourceReconciler
    AbstractFlinkResourceReconciler <|-- SessionReconciler
    AbstractFlinkResourceReconciler <|-- AbstractJobReconciler
    AbstractJobReconciler <|-- ApplicationReconciler
    AbstractJobReconciler <|-- SessionJobReconciler
{{< /mermaid >}}

Flink Kubernetes Operator 采用了模板方法模式设计调谐器架构。

- `AbstractFlinkResourceReconciler` 专注于处理所有资源的通用调谐逻辑，而 `AbstractJobReconciler` 在此基础上进一步抽象出 Flink 作业通用生命周期管理的模版方法。
- `SessionJobReconciler` 在 `AbstractFlinkResourceReconciler` 基础上实现 FlinkSessionJob 资源相关的调谐逻辑。
- `ApplicationReconciler` 在 `AbstractFlinkResourceReconciler` 基础上处理 Application 模式下 FlinkDeployment 资源相关作业的调谐逻辑。
- `SessionReconciler` 处理 Session 模式的 FlinkDeployment 资源相关作业的调谐逻辑。

需要注意的是，AbstractFlinkResourceReconciler 抽象了包括 Application 模式下 FlinkDeployment 的作业以及 FlinkSessionJob 对应的作业的通用生命周期管理的模版方法。
而 Session 模式下 FlinkDeployment 的调谐逻辑对应的集群的调谐逻辑，不需要处理集群内作业的生命周期管理，所以这里的类继承关系是如此。

#### 5.1.2.2 通用调谐流程


核心的调谐流程被定义在 `AbstractFlinkResourceReconciler` 的 `reconcile` 模版方法中，确保了调谐流程的一致性，具体简要流程图如下：

**AbstractFlinkResourceReconciler 的 reconcile 的流程图**

{{< mermaid >}}
flowchart LR
    A["协调入口"] --> B{"准备就绪?"}
    B -- 否 --> C["退出"]
    B -- 是 --> D{"首次部署?"}
    D -- 是 --> E["部署流程"]
    D -- 否 --> F{"需要回滚?"}
    F -- 是 --> G["准备回滚"]
    F -- 否 --> H{"规格变更？"}
    H -- 是 --> I["集群伸缩"]
    H -- 否 --> J["其他变更处理"]
    I --> K["规格变更处理"]

    style A fill:#e1f5fe
    style B fill:#fff3e0
    style C fill:#ffcdd2
    style E fill:#fce4ec
    style G fill:#fff8e1
    style I fill:#ff9800
    style J fill:#e0f2f1
    style K fill:#ffcdd2

{{< /mermaid >}}

AbstractFlinkResourceReconciler 定义了通用的调谐流程遵循以下步骤：
1. **准备就绪**：通过 `readyToReconcile` 检查是否准备好进行协调
2. **部署流程**：通过 `deploy` 执行具体的集群部署逻辑
3. **伸缩处理**：通过 `scale` 处理集群的伸缩
3. **变更处理**：通过 `reconcileSpecChange` 处理资源配置的变化
4. **其他调谐**：通过 `reconcileOtherChanges` 处理其他类型的变化

集群伸缩的操作在 scale 函数中实现，这个函数主要是由 FlinkService，我们将在第七章节具体展开。调谐过程中，我们也不过多的去解释如何处理回滚。因为回滚过程本质上是调谐的一种情况，所以读者只需要理解好调谐的逻辑就能看懂回滚的逻辑。另外流程图中，如果需要集群伸缩操作且已完成，那么就不需要再处理规格变更处理了，因为变更需要的调谐已经做完了。

判断资源变更部分是否发生变化则比较简单，主要使用到第三章我们提到的 Diff 机制中的 ReflectiveDiffBuilder 的 差异检测，读者可以翻到前面的章节去查看具体的时序图。简要的说，这个机制最终是用来识别出变更的处理方式的。DiffType 枚举类定义了4种具体的变更类型，代码如下：

```java
@Experimental
public enum DiffType {

    /** 可忽略的规格变更 */
    IGNORE,
    /** 可扩缩容的规格变更 */
    SCALE,
    /** 可升级的规格变更 */
    UPGRADE,
    /** 从新状态完全重新部署 */
    SAVEPOINT_REDEPLOY;

    /**
     * 将一组 {@link DiffType} 聚合为能够最小程度涵盖所有差异的类型。
     * 我们依赖于枚举值按此方式排序的事实。
     *
     * @param diffs 差异集合
     * @return 聚合后的 {@link DiffType}
     */
    public static DiffType from(Collection<DiffType> diffs) {
        return diffs.stream().max(Comparator.comparing(DiffType::ordinal)).orElse(DiffType.IGNORE);
    }
}
```

我们能够从对应枚举值找到代码中，哪些地方的注解 @SpecDiff 使用了对应的枚举值，并给出下列的表格：

| DiffType | 使用场景 | 使用处情况说明 |
|----------|----------|----------------|
| **IGNORE** | 可忽略的规格变更，不需要特殊处理 | 主要用于 `flinkConfiguration` 配置字段中部分配置的变更，以及 jobSpec 中的部分配置变更 |
| **SCALE** | 可扩缩容的规格变更，通过扩缩容操作处理 | 适用于 `replicas`、`parallelism` 等字段，以及 `flinkConfiguration` 中 `pipeline.jobvertex-parallelism-overrides` 前缀的配置，仅在 NATIVE 部署模式下生效 |
| **UPGRADE** | 可升级的规格变更，需要重新部署 | 这是最常用的类型，适用于大多数没有 `@SpecDiff` 注解的字段，以及模式不匹配的注解字段，包括镜像版本、资源配置等 |
| **SAVEPOINT_REDEPLOY** | 需要从新状态完全重新部署 | 主要用于 `savepointRedeployNonce` 字段，通过修改该值来强制触发从保存点重新部署 |

在识别到变更范围之后，在什么时候停止变更以及如何识别变更已经完成，这里会使用到 ReconciliationStatus 中的部分字段，包括 lastReconciledSpec 和 state。其中，state 由 ReconciliationState 枚举类定义，代码如下：

```java
/** 协调的当前状态 */
public enum ReconciliationState {
    /** 当前已部署 lastReconciledSpec */
    DEPLOYED,
    /** 规格正在升级中 */
    UPGRADING,
    /** 正在回滚到 lastStableSpec 的过程中 */
    ROLLING_BACK,
    /** 已回滚到 lastStableSpec */
    ROLLED_BACK
}
```

因为每一次调谐中都能获取到当前资源的最新状态，所以这时只需要判断 lastReconciledSpec 的前后变化，就能够识别变更是否已经完成，另外判断当前的 state 字段是否为升级中或者是回滚中，就能判断是否需要停止变更。

**AbstractFlinkResourceReconciler 调谐流程时序图**

基于源码分析，`AbstractFlinkResourceReconciler` 的 `reconcile` 方法采用模板方法模式，定义了统一的调谐流程。以下是简化的时序图，展示了抽象方法如何调用子类的具体实现：

{{< mermaid >}}
  sequenceDiagram
      participant Controller
      participant AbstractFlinkResourceReconciler
      participant AbstractJobReconciler
      participant SessionReconciler
      participant ApplicationReconciler
      participant SessionJobReconciler
      participant FlinkService

  Note over Controller, FlinkService: 调谐流程开始
  Controller->>AbstractFlinkResourceReconciler: reconcile(ctx)

  Note over AbstractFlinkResourceReconciler: 1. 检查准备状态
  AbstractFlinkResourceReconciler->>SessionReconciler: readyToReconcile(ctx)
  AbstractFlinkResourceReconciler->>AbstractJobReconciler: readyToReconcile(ctx)
  AbstractFlinkResourceReconciler->>SessionJobReconciler: readyToReconcile(ctx)

  alt 首次部署
      Note over AbstractFlinkResourceReconciler: 2. 首次部署
      AbstractFlinkResourceReconciler->>SessionReconciler: deploy(ctx, spec, deployConfig, savepoint, false)
      SessionReconciler->>FlinkService: submitSessionCluster(deployConfig)
      FlinkService-->>SessionReconciler: 部署完成

      AbstractFlinkResourceReconciler->>ApplicationReconciler: deploy(ctx, spec, deployConfig, savepoint, false)
      ApplicationReconciler->>FlinkService: submitApplicationCluster(deployConfig, savepoint)
      FlinkService-->>ApplicationReconciler: 部署完成

      AbstractFlinkResourceReconciler->>SessionJobReconciler: deploy(ctx, spec, deployConfig, savepoint, false)
      SessionJobReconciler->>FlinkService: submitJobToSessionCluster(deployConfig, savepoint)
      FlinkService-->>SessionJobReconciler: 部署完成
  else 非首次部署
      Note over AbstractFlinkResourceReconciler: 3. 分析规格差异
      AbstractFlinkResourceReconciler->>AbstractFlinkResourceReconciler: 检测规格变更

      alt 非升级类变更
          AbstractFlinkResourceReconciler->>FlinkService: scale(ctx, deployConfig)
      else 需要升级处理
          Note over AbstractJobReconciler: 作业类资源升级处理
          AbstractFlinkResourceReconciler->>AbstractJobReconciler: reconcileSpecChange(...)
          Note right of AbstractJobReconciler: 详见 5.1.2.3\n升级模式流程图

          alt Application模式
              AbstractJobReconciler->>ApplicationReconciler: cancelJob(ctx, suspendMode)
              ApplicationReconciler->>FlinkService: cancelJob(jobId, cancelConfig)
              AbstractJobReconciler->>ApplicationReconciler: restoreJob(...)
              ApplicationReconciler->>FlinkService: submitApplicationCluster(...)
          else SessionJob模式
              AbstractJobReconciler->>SessionJobReconciler: cancelJob(ctx, suspendMode)
              SessionJobReconciler->>FlinkService: cancelSessionJob(jobId, cancelConfig)
              AbstractJobReconciler->>SessionJobReconciler: restoreJob(...)
              SessionJobReconciler->>FlinkService: submitJobToSessionCluster(...)
          else Session模式
              AbstractFlinkResourceReconciler->>SessionReconciler: reconcileSpecChange(...)
              SessionReconciler->>FlinkService: deleteClusterDeployment()
              SessionReconciler->>FlinkService: submitSessionCluster(deployConfig)
          end
      end

      Note over AbstractFlinkResourceReconciler: 4. 处理其他变更
      AbstractFlinkResourceReconciler->>SessionReconciler: reconcileOtherChanges(ctx)
      AbstractFlinkResourceReconciler->>ApplicationReconciler: reconcileOtherChanges(ctx)
      AbstractFlinkResourceReconciler->>SessionJobReconciler: reconcileOtherChanges(ctx)
  end

  AbstractFlinkResourceReconciler-->>Controller: 调谐完成
{{< /mermaid >}}

**关键调用链分析：**

1. **readyToReconcile()**: 
  - FlinkDeployment 资源 (Application 集群模式)：首次部署则直接开始调谐逻辑，非首次时会查看是否正在从保存点恢复
  - FlinkDeployment 资源 (Session 集群模式): 总是直接开始调谐逻辑
  - FlinkSessionJob 资源：查看 Session 模式集群是否就绪

2. **deploy()**: 
  - FlinkDeployment 资源 (Application 集群模式)：通过 FlinkService 调用submitApplicationCluster() 创建 Application 集群
  - FlinkDeployment 资源 (Session 集群模式): 通过 FlinkService 调用submitSessionCluster()，创建 Session 集群
  - FlinkSessionJob 资源：通过 FlinkService 调用 submitJobToSessionCluster() 提交作业到 Session 集群

> **注**：FlinkService 抽象了集群部署的相关逻辑，我们将在第六章节重点展开。

3. **reconcileSpecChange()**: 
  - FlinkDeployment 资源 (Application 集群模式)：处理作业状态转换和升级策略，根据情况重新部署、恢复作业或挂起作业
  - FlinkDeployment 资源 (Session 集群模式): 由于集群部署配置修改，删除旧集群并重新部署
  - FlinkSessionJob 资源：处理作业状态转换和升级策略，根据情况重新部署、恢复作业或挂起作业


4. **reconcileOtherChanges()**: 
  - FlinkDeployment 资源 (Application 集群模式)：触发周期/手动快照（savepoint/checkpoint），同时检查集群健康与恢复/重启，并可在失败时按配置重启作业
  - FlinkDeployment 资源 (Session 集群模式): 检查是否需要恢复部署
  - FlinkSessionJob 资源：触发周期/手动快照（savepoint/checkpoint），并可在失败时按配置重启作业

5. **cancelJob()**: 
  - FlinkDeployment 资源 (Application 集群模式)：取消 Application 模式的作业
  - FlinkSessionJob 资源：取消 Session 模式的作业

reconcileSpecChange 和 reconcileOtherChanges 的不同资源具有通用逻辑，是由于 AbstractJobReconciler 抽象了作业生命周期管理的调谐逻辑。我们将在 5.2 和 5.3 章节中分别展开对应资源的作业资源调谐逻辑，这里读者只需有一个直观认识就可以了。

### 5.1.3 状态记录器 - StatusRecorder 

StatusRecorder 采用了状态缓存+乐观锁的设计模式，通过 ConcurrentHashMap 本地缓存存储资源状态，并使用修改的乐观锁机制确保状态更新的最终一致性。同时，StatusRecorder 还集成了第四章介绍的 FlinkResourceListener 插件机制，在状态变更时触发自定义监听器进行扩展处理。

--- 

**回顾第四章插件机制**

FlinkOperator 采用了插件化架构设计，通过Java的SPI（Service Provider Interface）机制，系统可以在运行时动态发现和加载扩展组件。Flink Operator 提供两种扩展插件，validators 和 listeners，validators 用来校验资源的值，而 listeners 用来监听事件并进行处理。这里的FlinkResourceListener 插件机制对应就是 listeners。这是 FlinkOperator 的事件监听插件，在状态变更时会触发自定义监听器进行扩展处理。

--- 

**使用场景分析**

在 FlinkDeploymentController 和 FlinkSessionJobController 中，StatusRecorder 在调谐生命周期的关键节点发挥重要作用：

1. 状态恢复：从缓存更新资源状态，减少状态不一致的可能性
2. 状态缓存：缓存状态变更，避免频繁的 Kubernetes API 调用
3. 状态同步：将缓存的状态批量更新到 Kubernetes

#### 典型时序图

> **注**：实际实现包含更多边界处理逻辑。

{{< mermaid >}}
sequenceDiagram
    participant Controller as Controller
    participant StatusRecorder as StatusRecorder
    participant Cache as 状态缓存
    participant K8sAPI as Kubernetes API
    participant FlinkResourceListener as FlinkResourceListener

    Note over Controller, FlinkResourceListener: 调谐流程中的状态管理和监听器触发

    Controller->>StatusRecorder: updateStatusFromCache(flinkApp)
    StatusRecorder->>Cache: 获取缓存状态
    Cache-->>StatusRecorder: 返回缓存状态
    StatusRecorder->>Controller: 更新资源状态
    alt 首次调谐且状态为CREATED
        StatusRecorder->>FlinkResourceListener: statusUpdateListener.accept(resource, status)
        Note right of FlinkResourceListener: 根据资源类型触发：<br/>- onDeploymentStatusUpdate()<br/>- onSessionJobStatusUpdate()
    end

    Note over Controller: 执行调谐逻辑
    Controller->>Controller: 观察、验证、调谐

    Controller->>StatusRecorder: patchAndCacheStatus(flinkApp, client)
    StatusRecorder->>StatusRecorder: 比较状态变化
    alt 状态有变化
        StatusRecorder->>K8sAPI: 使用乐观锁机制更新状态
        K8sAPI-->>StatusRecorder: 更新结果
        StatusRecorder->>Cache: 更新缓存
        StatusRecorder->>FlinkResourceListener: statusUpdateListener.accept(resource, prevStatus)
        Note right of FlinkResourceListener: 构建StatusUpdateContext<br/>触发对应监听方法
    else 状态无变化
        StatusRecorder->>StatusRecorder: 跳过更新
    end
{{< /mermaid >}}

图中，StatusRecorder 不仅负责状态缓存和更新，还通过 `statusUpdateListener` 触发第四章介绍的 FlinkResourceListener 插件机制。当状态发生变化时，会构建 `StatusUpdateContext` 并调用所有已注册的监听器插件，实现状态变更的扩展处理。

#### 核心函数分析

**1. updateStatusFromCache - 从缓存更新状态**

```java
public void updateStatusFromCache(CR resource) {
    var key = ResourceID.fromResource(resource);
    var cachedStatus = statusCache.get(key);
    if (cachedStatus != null) {
        // 从缓存恢复状态到资源对象
        resource.setStatus(
                (STATUS)
                        objectMapper.convertValue(
                                cachedStatus, resource.getStatus().getClass()));
    } else {
        // 初始化缓存，记录当前状态
        statusCache.put(key, objectMapper.convertValue(resource.getStatus(), ObjectNode.class));
        if (resource.getStatus() instanceof CommonStatus<?>) {
            if (ResourceLifecycleState.CREATED.equals(
                    ((CommonStatus<?>) resource.getStatus()).getLifecycleState())) {
                statusUpdateListener.accept(resource, resource.getStatus());
            }
        }
    }
    metricManager.onUpdate(resource);
}
```

在调谐开始时从本地缓存恢复资源状态，减少状态不一致的可能性，避免因 JOSDK 缓存机制导致的状态不一致问题。对于首次调谐且状态为 CREATED 的资源，还会触发 FlinkResourceListener 插件的状态更新回调。

**2. patchAndCacheStatus - 补丁更新并缓存状态**

> **注**：此为简化版本，实际实现包含乐观锁冲突处理和3次重试机制。
```java
@SneakyThrows
public void patchAndCacheStatus(CR resource, KubernetesClient client) {
    ObjectNode newStatusNode =
            objectMapper.convertValue(resource.getStatus(), ObjectNode.class);
    var resourceId = ResourceID.fromResource(resource);
    ObjectNode previousStatusNode = statusCache.get(resourceId);

    // 比较状态是否有变化
    if (newStatusNode.equals(previousStatusNode)) {
        LOG.debug("No status change.");
        return;
    }

    // 使用乐观锁机制更新状态
    var prevStatus = (STATUS) objectMapper.convertValue(previousStatusNode, statusClass);
    
    Exception err = null;
    for (int i = 0; i < 3; i++) {
        // 重试3次，每次间隔1秒
        try {
            // 使用 lockResourceVersion() 进行乐观锁更新
            client.resource(resource).lockResourceVersion().updateStatus();
        statusCache.put(resourceId, newStatusNode);
        notifyListeners(resource, prevStatus);
    } catch (KubernetesClientException e) {
        err = e;
        LOG.warn("Status update failed, will retry", e);
    }
}
```

使用修改的乐观锁机制将状态变更更新到 Kubernetes，同时更新本地缓存。通过 `lockResourceVersion()` 和重试机制确保状态更新成功，即使底层资源规格同时被更新。状态更新成功后，会通过 `notifyListeners` 方法触发所有已注册的 FlinkResourceListener 插件，实现状态变更的扩展处理。

**技术细节说明**：
- **本地缓存**：使用 `ConcurrentHashMap<ResourceID, ObjectNode> statusCache` 存储资源状态
- **乐观锁机制**：通过 `lockResourceVersion()` 实现，遇到409冲突时自动重试
- **重试策略**：最多重试3次，每次间隔1秒，确保状态更新的可靠性

### 5.1.4 资源上下文工厂 - FlinkResourceContextFactory 

FlinkResourceContextFactory 采用了工厂模式的设计，为不同类型的 Flink 资源创建专用的处理上下文，并根据部署模式创建对应的 FlinkService 实现。

**使用场景分析**

在 FlinkDeploymentController 和 FlinkSessionJobController 中，FlinkResourceContextFactory 负责资源处理环境的构建：

1. 上下文创建：为当前资源创建专用的处理上下文
2. 服务工厂：根据部署模式（Native/Standalone）创建对应的 FlinkService
3. 配置管理：提供资源特定的配置管理功能

---

**回顾第三章节的内容**

NATIVE模式 采用 Flink 原生的 Kubernetes 集成，利用Flink自身的资源管理能力，对应两个特点：
- Flink 框架使用 Kubernetes 客户端来创建资源和释放
- 支持细粒度的资源申请和释放

NATIVE 模式将由 Flink 创建的 Kubernetes 客户端来创建 JobManager 的 Deployment，再由 JobManager 来创建和管理 TaskManager 的 Pod
这种集成意味着 Flink 集群可以直接与 Kubernetes 通信，并允许其管理 Kubernetes 资源，例如动态分配和释放 TaskManager pod。

另外，STANDALONE 模式 则是传统的仅将 Kubernetes 作为 Flink 集群运行的编排平台，对应两个特点：
- Flink 集群不清楚自身运行在 Kubernetes 集群
- Flink 框架和作业程序都无权限访问 Kubernetes 集群，这能提高安全性

> **注**：部署模式以及 FlinkService 的详细工作原理和配置方式将在下一章节进行深入讲解。读者可以暂时将FlinkService 理解为创建和管理 Flink 不同部署模式的对应调用代码链路的整合。

--- 

#### 典型时序图

{{< mermaid >}}
sequenceDiagram
    participant Controller as Controller
    participant ContextFactory as FlinkResourceContextFactory
    participant Context as FlinkResourceContext
    participant FlinkService as FlinkService

    Note over Controller, FlinkService: 资源上下文创建流程

    Controller->>ContextFactory: getResourceContext(flinkApp, josdkContext)
    ContextFactory->>ContextFactory: 根据资源类型创建上下文
    alt FlinkDeployment
        ContextFactory->>Context: new FlinkDeploymentContext()
    else FlinkSessionJob
        ContextFactory->>Context: new FlinkSessionJobContext()
    end
    ContextFactory-->>Controller: 返回资源上下文

    Controller->>Context: getFlinkService()
    Context->>ContextFactory: getFlinkService(ctx)
    ContextFactory->>ContextFactory: 根据部署模式选择服务
    alt Native Mode
        ContextFactory->>FlinkService: new NativeFlinkService()
    else Standalone Mode
        ContextFactory->>FlinkService: new StandaloneFlinkService()
    end
    ContextFactory-->>Context: 返回 FlinkService
    Context-->>Controller: 返回 FlinkService
{{< /mermaid >}}

#### 核心函数分析

**1. getResourceContext - 创建资源上下文**

```java
public <CR extends AbstractFlinkResource<?, ?>> FlinkResourceContext<CR> getResourceContext(
        CR resource, Context josdkContext) {
    var resMg =
            resourceMetricGroups.computeIfAbsent(
                    Tuple2.of(resource.getClass(), ResourceID.fromResource(resource)),
                    r ->
                            OperatorMetricUtils.createResourceMetricGroup(
                                    operatorMetricGroup, configManager, resource));

    if (resource instanceof FlinkDeployment) {
        var flinkDep = (FlinkDeployment) resource;
        return (FlinkResourceContext<CR>)
                new FlinkDeploymentContext(
                        flinkDep, josdkContext, resMg, configManager, this::getFlinkService);
    } else if (resource instanceof FlinkSessionJob) {
        return (FlinkResourceContext<CR>)
                new FlinkSessionJobContext(
                        (FlinkSessionJob) resource,
                        josdkContext,
                        resMg,
                        configManager,
                        this::getFlinkService);
    } else {
        throw new IllegalArgumentException(
                "Unknown resource type " + resource.getClass().getSimpleName());
    }
}
```

根据资源类型（FlinkDeployment 或 FlinkSessionJob）创建对应的专用上下文，为每种资源类型提供定制化的处理环境，包括指标收集、配置管理和服务工厂。

**2. getFlinkService - 创建 Flink 服务**

```java
@VisibleForTesting
protected FlinkService getFlinkService(FlinkResourceContext<?> ctx) {
    var deploymentMode = ctx.getDeploymentMode();
    switch (deploymentMode) {
        case NATIVE:
            return new NativeFlinkService(
                    ctx.getKubernetesClient(),
                    artifactManager,
                    clientExecutorService,
                    ctx.getOperatorConfig(),
                    eventRecorder);
        case STANDALONE:
            return new StandaloneFlinkService(
                    ctx.getKubernetesClient(),
                    artifactManager,
                    clientExecutorService,
                    ctx.getOperatorConfig());
        default:
            throw new UnsupportedOperationException(
                    String.format("Unsupported deployment mode: %s", deploymentMode));
    }
}
```
根据资源的部署模式（Native 或 Standalone）动态创建相应的 FlinkService 实现，为不同部署模式提供专门的服务逻辑。我们将在

### 5.1.5 Operator健康监控模式 - CanaryResourceManager

Operator健康监控模式（Operator Health Monitoring）是 Flink Kubernetes Operator 中用于监控 Operator 自身健康状态的特殊机制。该模式通过部署轻量级的"金丝雀资源"来检测 Operator 的响应能力和处理性能，确保 Operator 能够正常工作。

在 Flink Kubernetes Operator 中，CanaryResourceManager 实现了一种特殊的"健康监控"机制，与传统意义上的金丝雀升级有所不同。这里的金丝雀资源主要用于**Operator 健康状态检测**而非功能测试，是一种轻量级的 Operator 健康状态监控机制。

Operator健康监控模式中设计意图与解决的问题主要有以下几点：

1. Operator 响应能力监控：通过部署特殊的"虚拟"资源（金丝雀资源），监控 Operator 是否能在规定时间内响应和处理资源变更，确保 Operator 的调谐循环正常工作。

2. 早期问题发现：当 Operator 出现性能下降、资源竞争或死锁等问题时，金丝雀资源无法在预期时间内被调谐，从而触发健康检查失败，实现问题的早期发现。

3. 自动化故障恢复：当金丝雀资源调谐超时（默认1分钟）时，Operator 会被标记为不健康状态，触发 Kubernetes 的自动重启机制，实现故障的自动恢复。

4. 多命名空间监控：支持在多个命名空间中部署金丝雀资源，实现对不同命名空间下 Operator 工作状态的全面监控。

整体设计时的特点如下：

- 轻量级设计：金丝雀资源不需要定义完整的 spec，不会启动任何 Pod 或消耗集群资源，纯粹用于健康状态验证
- 智能识别：通过特殊标签 `flink.apache.org/canary: "true"` 识别金丝雀资源
- 定时检测：采用定时任务机制，定期检查资源版本号变化，验证调谐是否正常
- 可配置超时：通过 `kubernetes.operator.health.canary.resource.timeout` 配置超时时间（默认1分钟）

CanaryResourceManager 采用了资源状态监控+定时任务的设计模式，通过定期检查金丝雀资源的调谐状态来监控 Operator 的处理能力。

**使用场景分析**

在 FlinkDeploymentController 和 FlinkSessionJobController 中，CanaryResourceManager 专注于金丝雀资源的生命周期管理：

1. 资源识别：检查是否为金丝雀资源，如果是则进行特殊处理
2. 状态监控：定期验证金丝雀资源的调谐状态
3. 资源清理：清理金丝雀资源的状态

> **注**：金丝雀资源通过 metadata.labels 中的 `flink.apache.org/canary: "true"` 标识识别。

#### 典型时序图

 {{< mermaid >}}
  sequenceDiagram
      participant Controller as 控制器
      participant CanaryManager as 金丝雀管理器
      participant K8sAPI as Kubernetes API
      participant Timer as 定时器线程池

  Note over Controller, Timer: Operator健康监控资源生命周期管理

  rect rgb(240, 248, 255)
      Note left of Controller: 首次调谐阶段
      Controller->>CanaryManager: handleCanaryResourceReconciliation(resource, client)
      Note right of CanaryManager: 1. 检查资源标签 flink.apache.org/canary=true

      CanaryManager->>CanaryManager: isCanaryResource(resource)
      Note right of CanaryManager: 2. 验证metadata.labels中canary标识

      alt 确认为金丝雀资源
          CanaryManager->>CanaryManager: 初始化金丝雀状态
          Note right of CanaryManager: 3. 创建CanaryResourceState对象<br/>记录当前资源版本号

          CanaryManager->>K8sAPI: 更新restartNonce字段
          Note left of K8sAPI: 4. 触发资源重启<br/>spec.restartNonce++

          CanaryManager->>Timer: schedule健康检查任务
          Note left of Timer: 5. 调度定时任务<br/>默认30秒后执行
      end
  end

  Note over Timer: === 定时健康检查阶段 ===

  rect rgb(255, 245, 240)
      Timer->>CanaryManager: checkHealth(resourceId, client)
      Note right of CanaryManager: 6. 定时触发状态检查

      CanaryManager->>CanaryManager: 对比资源版本号
      Note right of CanaryManager: 7. 比较metadata.generation<br/>与previousGeneration

      alt 版本已更新(调谐正常)
          CanaryManager->>CanaryManager: 标记健康状态
          Note left of CanaryManager: 8. crs.isHealthy = true<br/>记录"金丝雀部署健康"
      else 版本未变(调谐异常)
          CanaryManager->>CanaryManager: 标记异常状态
          Note left of CanaryManager: 9. crs.isHealthy = false<br/>记录错误日志
      end

      CanaryManager->>Timer: 重新调度下次检查
      Note left of Timer: 10. 循环执行<br/>持续监控
  end

        Note over CanaryManager: 整个链路形成闭环监控<br/>确保Operator的健康状态监控能力
  {{< /mermaid >}}

#### 核心函数分析

**1. handleCanaryResourceReconciliation - 处理金丝雀资源调谐**

```java
public boolean handleCanaryResourceReconciliation(CR resource, KubernetesClient client) {
    if (!isCanaryResource(resource)) {
        return false;
    }

    var resourceId = ResourceID.fromResource(resource);

    LOG.info("Reconciling canary resource");

    canaryResources.compute(
            resourceId,
            (id, previousState) -> {
                boolean firstReconcile = false;
                if (previousState == null) {
                    firstReconcile = true;
                    previousState = new CanaryResourceState();
                }
                previousState.onReconcile(resource);
                if (firstReconcile) {
                    updateSpecAndScheduleHealthCheck(resourceId, previousState, client);
                }
                return previousState;
            });

    return true;
}
```

**函数用途**：识别并处理金丝雀资源，记录资源状态并调度状态监控任务。如果是首次调谐，会更新资源规格并设置定时状态监控，确保 Operator 的健康状态监控机制正常工作。

**2. checkHealth - 状态监控**

```java
@VisibleForTesting
protected void checkHealth(ResourceID resourceID, KubernetesClient client) {
    CanaryResourceState crs = canaryResources.get(resourceID);
    if (crs == null) {
        LOG.info("Canary resource {} not found. Stopping health checks", resourceID);
        return;
    }

    // 检查自上次规格更新后是否进行了调谐
    if (crs.canaryReconciledSinceUpdate()) {
        LOG.info("Canary deployment healthy");
        crs.isHealthy = true;
    } else {
        LOG.error(
                "Canary deployment {} latest spec not reconciled. Expected generation larger than {}, received {}",
                resourceID,
                crs.previousGeneration,
                crs.resource.getMetadata().getGeneration());
        crs.isHealthy = false;
    }

    // 更新规格并重新调度健康检查
    updateSpecAndScheduleHealthCheck(resourceID, crs, client);
}
```

**函数用途**：定期检查金丝雀资源的调谐状态，通过比较资源版本号判断 Operator 的健康状态。如果调谐正常则标记为健康，否则标记为不健康并记录错误日志。

## 5.2 FlinkDeployment Controller 源码解析

### 5.2.1 核心成员变量和方法

FlinkDeploymentController 是 FlinkOperator 中负责管理 FlinkDeployment 资源的核心控制器，实现了 Java Operator SDK 的多个接口。以下是其构造函数和核心成员变量：

```java
public class FlinkDeploymentController
        implements Reconciler<FlinkDeployment>,
                ErrorStatusHandler<FlinkDeployment>,
                EventSourceInitializer<FlinkDeployment>,
                Cleaner<FlinkDeployment> {
    
    // 核心成员变量
    private final Set<FlinkResourceValidator> validators;                    // 资源验证器集合
    private final FlinkResourceContextFactory ctxFactory;                   // 资源上下文工厂
    private final ReconcilerFactory reconcilerFactory;                      // 调谐器工厂
    private final FlinkDeploymentObserverFactory observerFactory;           // 观察者工厂
    private final StatusRecorder<FlinkDeployment, FlinkDeploymentStatus> statusRecorder;  // 状态记录器
    private final EventRecorder eventRecorder;                              // 事件记录器
    private final CanaryResourceManager<FlinkDeployment> canaryResourceManager;  // 金丝雀资源管理器
}
```

**成员变量说明**：
- **validators**：验证插件，用于验证 FlinkDeployment 资源
- **ctxFactory**：资源上下文工厂，负责创建 FlinkDeployment 的处理上下文
- **reconcilerFactory**：调谐器工厂，根据部署模式创建对应的调谐器
- **observerFactory**：观察者工厂，负责创建和管理 FlinkDeployment 的观察者
- **statusRecorder**：状态记录器，管理 FlinkDeployment 的状态缓存和更新
- **eventRecorder**：事件记录器，负责记录和触发 Kubernetes 事件
- **canaryResourceManager**：金丝雀资源管理器，处理金丝雀资源的特殊逻辑

#### 类图

{{< mermaid >}}
classDiagram
    class FlinkDeploymentController
    class Reconciler {
        +reconcile(context)
        +cleanup(context)
    }
    class ErrorStatusHandler {
        updateErrorStatus
    }
    class EventSourceInitializer {
        prepareEventSources
    }
    class Cleaner {
        cleanup
    }
    
    FlinkDeploymentController ..|> Reconciler
    FlinkDeploymentController ..|> ErrorStatusHandler
    FlinkDeploymentController ..|> EventSourceInitializer
    FlinkDeploymentController ..|> Cleaner
{{< /mermaid >}}

第二章我们已经解释过这些对应的函数，FlinkDeploymentController 的主要逻辑也就是实现这些接口的方法：
- Reconciler：Java Operator SDK 的核心接口，定义调谐逻辑的 reconcile 方法
- ErrorStatusHandler：错误状态处理接口，处理调谐过程中的异常的 updateErrorStatus 方法
- EventSourceInitializer：事件源初始化接口，设置事件监听 prepareEventSources 方法
- Cleaner：资源清理接口，处理资源删除逻辑的 cleanup 方法

这些方法对应都有一个特点，方法参数中都接收 Java Operator SDK 的 Context 类型的参数 josdkContext。在 Flink Operator 的代码中，主要使用这个参数获取次要资源，或者获取 Kubernetes 的客户端。读者能从 5.1.4 章节中看到，资源上下文工厂类中的 `getResourceContext` 方法，会对应资源类型（FlinkDeployment 或 FlinkSessionJob）创建对应的专用上下文，这时候也会用到这个参数。读者也能从 Controller 的代码中看到 `ctx.getJosdkContext()`，就是对应这个参数的使用。

### 5.2.2 调谐准备阶段

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {

    // 1. 金丝雀资源处理：如果是金丝雀资源，直接返回不更新
    if (canaryResourceManager.handleCanaryResourceReconciliation(
            flinkApp, josdkContext.getClient())) {
        return UpdateControl.noUpdate();
    }

    LOG.debug("Starting reconciliation");

    // 2. 状态恢复：从缓存更新资源状态，减少状态不一致的可能性。如果不在缓存中，则加入缓存
    statusRecorder.updateStatusFromCache(flinkApp);
    
    // 3. 资源克隆：创建当前资源的副本，用于后续状态比较
    FlinkDeployment previousDeployment = ReconciliationUtils.clone(flinkApp);
    
    // 4. 上下文创建：为当前资源创建专用的处理上下文
    var ctx = ctxFactory.getResourceContext(flinkApp, josdkContext);

    // 5. 版本验证：检查 Flink 版本是否支持，不支持则触发事件并退出
    if (!ValidatorUtils.validateSupportedVersion(ctx, eventRecorder)) {
        return UpdateControl.noUpdate();
    }

    // 6. 观察阶段：开始观察集群状态
}
```

**调谐准备阶段的核心步骤**

1. 金丝雀资源检查：优先处理金丝雀资源，如果是金丝雀资源则直接返回
2. 状态恢复：从本地缓存恢复资源状态，避免因 JOSDK 缓存导致的状态不一致
3. 资源备份：创建当前资源的副本，用于后续状态变更比较
4. 上下文构建：创建包含 Kubernetes 客户端、配置等信息的处理上下文
5. 版本验证：验证 Flink 版本兼容性，确保 Operator 能够处理该版本

这里的资源备份，只是将对象重新克隆一个，没有特殊逻辑。除了版本验证，其他的步骤前文都有提到，读者可以对照着函数直接看前文的介绍即可。我们这里着重说一下 FlinkOperator 与 Flink 的版本兼容关系：

**FlinkOperator 与 Flink 版本兼容关系**

根据官方文档和源码分析，FlinkOperator 对 Flink 版本的兼容性支持如下：

| Flink 版本 | 支持状态 | 说明 |
|-----------|---------|------|
| v1_13 | ❌ 不支持 | 自 Operator 1.7 版本起不再支持 |
| v1_14 | ❌ 不支持 | 自 Operator 1.7 版本起不再支持 |
| v1_15 | ⚠️ 已弃用 | 自 Operator 1.10 版本起已弃用 |
| v1_16 | ✅ 支持 | 当前支持 |
| v1_17 | ✅ 支持 | 当前支持 |
| v1_18 | ✅ 支持 | 当前支持 |
| v1_19 | ✅ 支持 | 当前支持 |
| v1_20 | ✅ 支持 | 当前支持 |

**版本验证代码实现**

```java
public static boolean validateSupportedVersion(
        FlinkResourceContext<?> ctx, EventRecorder eventRecorder) {
    // 获取当前资源的 Flink 版本
    var version = ctx.getFlinkVersion();
    
    // 检查版本是否支持：版本不为空且大于等于 v1_15
    if (!FlinkVersion.isSupported(version)) {
        // 触发不支持版本的事件警告
        eventRecorder.triggerEvent(
                ctx.getResource(),
                EventRecorder.Type.Warning,
                EventRecorder.Reason.UnsupportedFlinkVersion,
                EventRecorder.Component.Operator,
                "Flink version " + version + " is not supported by this operator version",
                ctx.getJosdkContext().getClient());
        return false; // 返回验证失败
    }
    return true; // 返回验证成功
}
```

**版本支持判断逻辑**

```java
public static boolean isSupported(FlinkVersion version) {
    // 版本不为空且大于等于 v1_15 才支持
    return version != null && version.isEqualOrNewer(FlinkVersion.v1_15);
}
```

**版本比较方法**

```java
public boolean isEqualOrNewer(FlinkVersion otherVersion) {
    // 通过枚举的 ordinal() 值进行版本比较
    return this.ordinal() >= otherVersion.ordinal();
}
```

当版本验证失败时，Operator 会触发警告事件并跳过调谐，确保不会处理不兼容的 Flink 版本。

### 5.2.3 调谐观察阶段

在 reconcile 方法中，观察阶段的代码实现如下：

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {
    // ... 前面的准备阶段代码 ...
    
    try {
        // 观察阶段：获取或创建观察器，然后执行观察逻辑
        observerFactory.getOrCreate(flinkApp).observe(ctx);
        
        // ... 后续的验证和调谐逻辑 ...
    } catch (Exception e) {
        // ... 异常处理 ...
    }
    return ReconciliationUtils.toUpdateControl(
                ctx.getOperatorConfig(), flinkApp, previousDeployment, true);
}
```

**ObserverFactory 设计模式**

FlinkDeploymentObserverFactory 采用了工厂模式+缓存的设计，根据 FlinkDeployment 的运行模式和部署模式动态创建对应的 Observer 实例。

```java
public class FlinkDeploymentObserverFactory {
    private final EventRecorder eventRecorder;
    // 使用 ConcurrentHashMap 缓存已创建的 Observer 实例
    private final Map<Tuple2<Mode, KubernetesDeploymentMode>, Observer<FlinkDeployment>> observerMap;

    public FlinkDeploymentObserverFactory(EventRecorder eventRecorder) {
        this.eventRecorder = eventRecorder;
        this.observerMap = new ConcurrentHashMap<>();
    }

    public Observer<FlinkDeployment> getOrCreate(FlinkDeployment flinkApp) {
        // 根据运行模式和部署模式创建缓存键
        return observerMap.computeIfAbsent(
                Tuple2.of(
                        Mode.getMode(flinkApp),                    // 获取运行模式：SESSION 或 APPLICATION
                        KubernetesDeploymentMode.getDeploymentMode(flinkApp)), // 获取部署模式：NATIVE 或 STANDALONE
                modes -> {
                    // 根据运行模式创建对应的 Observer
                    switch (modes.f0) {
                        case SESSION:
                            return new SessionObserver(eventRecorder);      // 会话模式观察器
                        case APPLICATION:
                            return new ApplicationObserver(eventRecorder);  // 应用模式观察器
                        default:
                            throw new UnsupportedOperationException(
                                    String.format("Unsupported running mode: %s", modes.f0));
                    }
                });
    }
}
```

根据 5.1 章节中，Observer 接口是观察器模式的核心接口，定义了 `observe` 方法来观察 Flink 应用状态。`AbstractFlinkResourceObserver` 是 Observer 接口的抽象实现，提供了通用的观察逻辑框架，包括资源就绪检查、快照触发器重置等。`AbstractFlinkDeploymentObserver` 专门用于观察 FlinkDeployment 资源，实现了部署相关的观察逻辑。`SessionObserver` 和 `ApplicationObserver` 是 `AbstractFlinkDeploymentObserver` 的两个具体子类，分别处理会话模式和应用模式的特定观察需求。

#### 集群部署观察

```java
@Override
public final void observe(FlinkResourceContext<CR> ctx) {
    // 检查资源是否准备好被观察（在特定状态下如暂停应用、升级回滚进行中时不需要观察）
    if (!isResourceReadyToBeObserved(ctx)) {
        return;
    }

    // 触发资源特定的观察逻辑
    observeInternal(ctx);

    // 重置快照触发器
    SnapshotUtils.resetSnapshotTriggers(
            ctx.getResource(), eventRecorder, ctx.getKubernetesClient());
}
```

根据 5.1 章节中，`observe` 方法的具体逻辑都已经详细说明。对于 FlinkDeployment 资源的调谐过程，`observeInternal` 对应的是 `AbstractFlinkResourceObserver` 中定义的抽象方法，具体代码如下：

```java
@Override
public void observeInternal(FlinkResourceContext<FlinkDeployment> ctx) {
    var flinkDep = ctx.getResource();
    if (!isJmDeploymentReady(flinkDep)) {
        // 只有当 JobManager 部署未就绪时才观察 JM 部署状态
        observeJmDeployment(ctx);
    }

    if (isJmDeploymentReady(flinkDep)) {
        // 只有当 JM 就绪后才观察 Flink 集群状态
        observeFlinkCluster(ctx);
    }

    if (isJmDeploymentReady(flinkDep)) {
        // 只有当 JM 就绪后才收集集群信息
        observeClusterInfo(ctx);
    }

    clearErrorsIfDeploymentIsHealthy(flinkDep);
}
```

根据 5.1 章节中，observeInternal 是 AbstractFlinkDeploymentObserver 中定义的抽象方法。observeInternal 方法中，observeFlinkCluster 是抽象方法，具体由子类实现。其他的方法都定义在 AbstractFlinkDeploymentObserver 中。我们将先说明 AbstractFlinkDeploymentObserver 中定义了的方法。

observeInternal 的方法参数是 ctx，是由 5.1.4 章节中介绍的资源上下文工厂的 getResourceContext 方法所创建的 FlinkDeploymentContext 类型，因此 `ctx.getResource()` 对应就是 FlinkDeployment 类型。接着我们直接查看 `isJmDeploymentReady` 的源码：

```java
protected boolean isJmDeploymentReady(FlinkDeployment dep) {
    return dep.getStatus().getJobManagerDeploymentStatus() == JobManagerDeploymentStatus.READY;
}
```
---

**回顾第三章 FlinkDeployment 的 Status 设计**

第三章节中，我们介绍了 FlinkDeployment 的 Status 设计，其中 jobManagerDeploymentStatus 对应的是 JobManager 的部署状态。默认的初始值是 MISSING。

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
}
```

--- 

`isJmDeploymentReady` 的方法逻辑很简单，就是判断 FlinkDeployment 的 JobManagerDeploymentStatus 是否为 READY。

**observeJmDeployment 方法的逻辑流程**

而 `observeJmDeployment` 方法的逻辑流程图和描述如下：

{{< mermaid >}}
flowchart TD
    A[开始: observeJmDeployment] --> B[获取当前状态 previousJmStatus]
    B --> C{是否为暂停作业?}
    C -->|是| D[跳过观察，直接返回]
    C -->|否| E[记录开始观察日志]
    
    E --> F{当前状态是否为 DEPLOYED_NOT_READY?}
    F -->|是| G[设置为 READY 状态并返回]
    F -->|否| H[获取 Kubernetes Deployment 资源]
    
    H --> I{Deployment 是否存在?}
    I -->|否| J[设置为 MISSING 状态]
    J --> K[设置作业状态为 RECONCILING]
    K --> L{之前状态是否为 MISSING/ERROR?}
    L -->|否| M[调用 onMissingDeployment 方法]
    L -->|是| N[结束]
    
    I -->|是| O[检查 Deployment 就绪性]
    O --> P{Deployment 是否就绪?<br/>且 JobManager 端口可用?}
    P -->|是| Q[设置为 DEPLOYED_NOT_READY 状态<br/>等待 Flink REST API 就绪]
    Q --> R[结束]
    
    P -->|否| S[检查部署失败情况]
    S --> T[检查容器重启情况]
    T --> U{是否抛出 DeploymentFailedException?}
    U -->|是| V{当前状态是否为 ERROR?}
    V -->|否| W[抛出异常]
    V -->|是| X[设置作业状态为 RECONCILING 并返回]
    U -->|否| Y[设置为 DEPLOYING 状态]
    Y --> Z[结束]
    
    M --> N
    
    style A fill:#e1f5fe
    style D fill:#ffebee
    style G fill:#e8f5e8
    style J fill:#fff3e0
    style Q fill:#f3e5f5
    style Y fill:#e8f5e8
    style W fill:#ffebee

{{< /mermaid >}}

`observeJmDeployment` 方法通过一系列条件判断来观察 JobManager 的部署状态，整体流程如下：

1. **暂停作业检查**  
   - 如果作业处于暂停状态，则直接跳过观察，方法返回。
   - 否则，继续后续流程。

2. **状态转换检查**  
   - 如果当前状态为 `DEPLOYED_NOT_READY`，则直接将状态升级为 `READY` 并返回。
   - 否则，继续检查底层资源。

3. **Deployment 存在性检查**  
   - 如果 Kubernetes Deployment 资源不存在，则将状态设置为 `MISSING`，并设置作业状态为 `RECONCILING`。
   - 此时，如果之前的状态不是 `MISSING` 或 `ERROR`，则会触发缺失部署的处理逻辑（调用 `onMissingDeployment` 方法）。

4. **Deployment 就绪性验证**  
   - 如果 Deployment 存在，则检查副本数是否匹配、可用副本是否达到期望值，以及 JobManager 端口是否可用。
   - 如果全部满足，则将状态设置为 `DEPLOYED_NOT_READY`，等待 Flink REST API 就绪。

5. **异常与部署中状态处理**  
   - 如果就绪性验证未通过，则进一步检查部署失败和容器重启情况。
   - 如果抛出 `DeploymentFailedException`，则判断当前状态：
     - 若不是 `ERROR`，则抛出异常；
     - 若已是 `ERROR`，则将作业状态设置为 `RECONCILING` 并返回。
   - 如果没有异常，则将状态设置为 `DEPLOYING`。

简而言之，由于 JobManagerDeploymentStatus 初始状体是 MISSING，当 JobManager 部署状态不等于 READY 时，会触发观察逻辑。同时，读者需要注意到的是，部署的逻辑并不在观察阶段，这里的观察更类似于一种定时轮询。当调谐阶段部署了 JobManager 的 Deployment 后，会触发观察逻辑，将 JobManagerDeploymentStatus 设置为 DEPLOYED_NOT_READY。等待下一次轮询时，状态就会改成 READY。代码设计时考虑了多种异常情况，比如 Deployment 不存在、Deployment 就绪性验证失败、Deployment 抛出异常等。最常见的异常情况是 Deployment 不存在，此时会触发 onMissingDeployment 方法，对应代码如下：

```java
private void onMissingDeployment(FlinkResourceContext<FlinkDeployment> ctx) {
    String err = "Missing JobManager deployment";
    logger.error(err);
    ReconciliationUtils.updateForReconciliationError(ctx, new MissingJobManagerException(err));
    eventRecorder.triggerEvent(
            ctx.getResource(),
            EventRecorder.Type.Warning,
            EventRecorder.Reason.Missing,
            EventRecorder.Component.JobManagerDeployment,
            err,
            ctx.getKubernetesClient());
}
```
onMissingDeployment 方法会设置 FlinkDeployment 的 status 中的 error 字段，同时利用 eventRecorder 触发 Warning 事件。

当 JobManagerDeploymentStatus 为 READY 后，读者可以认为，从部署层面上的集群观察阶段已经结束了，接下来，就进入到业务层面的观察阶段。

#### 业务层面观察


当 JobManagerDeploymentStatus 为 READY 后，会触发 observeClusterInfo 方法，对应代码如下：

```java
private void observeClusterInfo(FlinkResourceContext<FlinkDeployment> ctx) {
    var flinkApp = ctx.getResource();
    try {
        Map<String, String> clusterInfo =
                ctx.getFlinkService().getClusterInfo(ctx.getObserveConfig());
        flinkApp.getStatus().getClusterInfo().putAll(clusterInfo);
        logger.debug("ClusterInfo: {}", flinkApp.getStatus().getClusterInfo());
    } catch (Exception e) {
        logger.warn("Exception while fetching cluster info", e);
    }
}
```

这里的主要逻辑就是通过 flinkService 的 getClusterInfo 方法获取集群信息，并更新到 FlinkDeployment 的 status 中的 clusterInfo 字段。这个字段，一般包含的信息包括：flink-version, total-cpu, total-memory等信息，都是由 FlinkService 调用 Flink REST API 获取的。

当 JobManagerDeployment 的观察阶段结束后，会触发 clearErrorsIfDeploymentIsHealthy 方法，对应代码如下：

```java
protected void clearErrorsIfDeploymentIsHealthy(FlinkDeployment dep) {
    // 获取 FlinkDeployment 的状态信息
    FlinkDeploymentStatus status = dep.getStatus();
    // 获取调谐状态信息，用于判断规格是否稳定
    var reconciliationStatus = status.getReconciliationStatus();
    
    // 清除错误状态的条件判断：
    // 1. JobManager 部署状态不是 ERROR（集群部署正常）
    // 2. 作业状态不是 FAILED（作业运行正常）
    // 3. 上次调谐的规格已经稳定（没有进行中的规格变更）
    if (status.getJobManagerDeploymentStatus() != JobManagerDeploymentStatus.ERROR
            && !JobStatus.FAILED.equals(dep.getStatus().getJobStatus().getState())
            && reconciliationStatus.isLastReconciledSpecStable()) {
        // 满足所有条件时，清除错误状态，表示系统已恢复正常
        status.setError(null);
    }
}
```

代码逻辑比较简单，当满足条件时，就会将 FlinkDeployment 的 status 中的 error 字段设置为 null。

最后，我们来拆解一下最关键的业务观察部分 ApplicationObserver 的实现的 observeFlinkCluster 方法的时序图：

{{< mermaid >}}
sequenceDiagram
    participant ApplicationObserver as ApplicationObserver
    participant JobStatusObserver as JobStatusObserver
    participant SavepointObserver as SavepointObserver
    participant ClusterHealthObserver as ClusterHealthObserver
    participant FlinkResourceContext as FlinkResourceContext
    participant ObserveConfig as ObserveConfig

    Note over ApplicationObserver, ClusterHealthObserver: ApplicationObserver.observeFlinkCluster 观察流程

    ApplicationObserver->>ApplicationObserver: 记录调试日志："Observing application cluster"
    
    ApplicationObserver->>JobStatusObserver: observe(ctx)
    Note right of JobStatusObserver: 观察作业状态，返回是否找到作业
    
    JobStatusObserver-->>ApplicationObserver: jobFound (boolean)
    
    alt 找到作业 (jobFound = true)
        ApplicationObserver->>FlinkResourceContext: getObserveConfig()
        FlinkResourceContext-->>ApplicationObserver: observeConfig
        
        Note over ApplicationObserver, SavepointObserver: 开始观察保存点状态
        ApplicationObserver->>SavepointObserver: observeSavepointStatus(ctx)
        SavepointObserver->>SavepointObserver: 观察保存点触发状态、完成状态等
        
        Note over ApplicationObserver, CheckpointObserver: 开始观察检查点状态
        ApplicationObserver->>SavepointObserver: observeCheckpointStatus(ctx)
        Note right of SavepointObserver: 注意：这里调用的是 savepointObserver<br/>但实际观察的是检查点状态
        
        ApplicationObserver->>ObserveConfig: getBoolean(OPERATOR_CLUSTER_HEALTH_CHECK_ENABLED)
        ObserveConfig-->>ApplicationObserver: 是否启用集群健康检查
        
        alt 集群健康检查已启用
            Note over ApplicationObserver, ClusterHealthObserver: 开始观察集群健康状态
            ApplicationObserver->>ClusterHealthObserver: observe(ctx)
            ClusterHealthObserver->>ClusterHealthObserver: 检查集群健康指标<br/>如重启次数、检查点完成情况等
        else 集群健康检查未启用
            Note right of ApplicationObserver: 跳过集群健康检查
        end
        
    else 未找到作业 (jobFound = false)
        Note right of ApplicationObserver: 跳过所有后续观察步骤<br/>包括保存点、检查点和集群健康检查
    end
    
    Note over ApplicationObserver, ClusterHealthObserver: 观察流程结束
{{< /mermaid >}}

可以看出，关键还是在于作业状态和保存点、检查点的观察。如果有配置集群健康的观察，也会相应的进行集群健康的检查。我们已经在 5.1.1.1 和 5.1.1.2 章节中分别介绍了作业状态观察器和快照观察器，这里我们主要关注一下集群健康观察器 ClusterHealthObserver 的实现。

ClusterHealthObserver 的 observe 方法的源码如下：

```java
/**
 * 观察 Flink 集群的健康状态
 * 
 * 该方法通过收集 Flink 集群的关键指标来评估集群的健康状况，
 * 包括作业重启次数和完成的检查点数量，用于判断集群是否需要重启恢复。
 *
 * @param ctx 资源上下文，包含 Flink 集群的配置和状态信息
 */
public void observe(FlinkResourceContext<FlinkDeployment> ctx) {
    // 从上下文中获取 Flink 应用资源对象
    var flinkApp = ctx.getResource();
    try {
        LOG.debug("Observing cluster health");
        
        // 获取部署状态和作业状态信息
        var deploymentStatus = flinkApp.getStatus();
        var jobStatus = deploymentStatus.getJobStatus();
        var jobId = jobStatus.getJobId();
        
        // 通过 FlinkService 调用 Flink 集群的 REST API 获取关键指标
        // 收集三个重要的健康指标：完整重启次数、重启次数、完成的检查点数量
        var metrics =
                ctx.getFlinkService()
                        .getMetrics(
                                ctx.getObserveConfig(),
                                jobId,
                                List.of(
                                        FULL_RESTARTS_METRIC_NAME,        // 完整重启次数（旧版本 Flink）
                                        NUM_RESTARTS_METRIC_NAME,         // 重启次数（新版本 Flink）
                                        NUMBER_OF_COMPLETED_CHECKPOINTS_METRIC_NAME));  // 完成的检查点数量
        
        // 创建新的集群健康信息对象，用于存储本次观察到的健康状态
        ClusterHealthInfo observedClusterHealthInfo = new ClusterHealthInfo();
        
        // 优先使用新版本的 numRestarts 指标，如果不存在则回退到旧版本的 fullRestarts
        // 这种设计确保了向后兼容性，支持不同版本的 Flink 集群
        if (metrics.containsKey(NUM_RESTARTS_METRIC_NAME)) {
            LOG.debug(NUM_RESTARTS_METRIC_NAME + " metric is used");
            // 设置重启次数，用于评估集群的稳定性
            observedClusterHealthInfo.setNumRestarts(
                    Integer.parseInt(metrics.get(NUM_RESTARTS_METRIC_NAME)));
        } else if (metrics.containsKey(FULL_RESTARTS_METRIC_NAME)) {
            LOG.debug(
                    FULL_RESTARTS_METRIC_NAME
                            + " metric is used because "
                            + NUM_RESTARTS_METRIC_NAME
                            + " is missing");
            // 使用旧版本指标作为回退方案
            observedClusterHealthInfo.setNumRestarts(
                    Integer.parseInt(metrics.get(FULL_RESTARTS_METRIC_NAME)));
        } else {
            // 如果两个重启指标都不存在，说明集群配置有问题或版本不兼容
            // 抛出异常阻止后续的健康评估
            throw new IllegalStateException(
                    "No job restart metric found. Either "
                            + FULL_RESTARTS_METRIC_NAME
                            + "(old and deprecated in never Flink versions) or "
                            + NUM_RESTARTS_METRIC_NAME
                            + "(new) must exist.");
        }
        
        // 设置完成的检查点数量，用于评估集群的数据处理能力
        // 这个指标对于判断集群是否健康运行非常重要
        observedClusterHealthInfo.setNumCompletedCheckpoints(
                Integer.parseInt(metrics.get(NUMBER_OF_COMPLETED_CHECKPOINTS_METRIC_NAME)));
        
        // 记录观察到的集群健康信息，用于调试和监控
        LOG.debug("Observed cluster health: {}", observedClusterHealthInfo);

        // 调用集群健康评估器进行健康状态评估
        // evaluate 方法会：
        // 1. 比较当前健康信息与上次的健康信息
        // 2. 评估重启次数是否超过阈值（在配置的时间窗口内）
        // 3. 评估检查点进度是否正常（在配置的时间窗口内）
        // 4. 更新集群信息中的健康状态
        clusterHealthEvaluator.evaluate(
                ctx.getObserveConfig(),                    // 观察配置，包含健康检查的阈值和窗口设置
                deploymentStatus.getClusterInfo(),         // 集群信息，用于存储和比较健康状态
                observedClusterHealthInfo);                // 本次观察到的健康信息
                
    } catch (Exception e) {
        // 捕获并记录异常，但不抛出异常
        // 这是因为获取指标失败通常被视为临时问题，不应该阻止整个观察流程
        // 系统会在下次观察时重试，确保集群健康监控的连续性
        LOG.warn("Exception while observing cluster health: {}", e.getMessage());
        // 故意不抛出异常，因为我们将获取指标失败作为临时问题处理
    }
}

```

从代码注释中也可以看出，当集群监控时会获取三个重要的健康指标：完整重启次数、重启次数、完成的检查点数量。只是由于 Flink Operator 兼容多个版本的 Flink 所以需要兼容不同版本的指标名称。收集的指标会存储到 ClusterHealthInfo 对象中，然后调用 clusterHealthEvaluator 的 evaluate 方法进行健康评估。

ClusterHealthEvaluator 的 evaluate 方法的主要步骤如下：
1. 比较当前健康信息与上次的健康信息
2. 评估重启次数是否超过阈值（在配置的时间窗口内）
3. 评估检查点进度是否正常（在配置的时间窗口内）
4. 更新集群信息中的健康状态

最后评估的结果会写入 FlinkDeploymentStatus 的 clusterInfo 字段中。

总的来说，ApplicationObserver 的 业务层面观察，主要是利用 REST API 来获取作业状态，保存点，检查点以及集群运行指标来进行观察，最终的结果会更新 status 的对应字段。

接着我们补充一下，SessionObserver 的 observeFlinkCluster 方法，

```java
@Override
public void observeFlinkCluster(FlinkResourceContext<FlinkDeployment> ctx) {
    // Check if session cluster can serve rest calls following our practice in JobObserver
    try {
        logger.debug("Observing session cluster");
        ctx.getFlinkService().getClusterInfo(ctx.getObserveConfig());
        var rs = ctx.getResource().getStatus().getReconciliationStatus();
        if (rs.getState() == ReconciliationState.DEPLOYED) {
            rs.markReconciledSpecAsStable();
        }
    } catch (Exception e) {
        logger.error("REST service in session cluster timed out", e);
        if (e instanceof TimeoutException) {
            // check for problems with the underlying deployment
            observeJmDeployment(ctx);
        }
    }
}
```

SessionObserver 的 observeFlinkCluster 方法，主要是检查会话集群是否可以提供 REST 调用，如果可以，则标记为已调谐。如果不能，则观察 JobManager 的部署状态。可以看出与 ApplicationObserver 的 observeFlinkCluster 方法，主要区别在于，SessionObserver 的 observeFlinkCluster 方法，主要是检查会话集群是否开访问，而不关心作业状态及保存点。我们会在 5.3.3 章节中讲到 FlinkSessionJob 的观察方法，对应的就会检查作业状态和保存点状态，与 SessionObserver 本身是一个互补的关系。


### 5.2.4 调谐验证阶段

相比于观察和调谐阶段，验证阶段是逻辑比较简单。在第四章中，我们已经介绍过了 Operator 的插件机制，验证阶段的主要逻辑，就是调用内置的和自定义的插件的 validate 方法来验证资源是否符合预期。


在 reconcile 方法中，验证阶段的代码实现如下：

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {
    // ... 前面的准备阶段代码 ...
    
    try {
        // 前面观察阶段的代码
        // 验证阶段带啊吗
        if (!validateDeployment(ctx)) {
            // 如果验证失败，则更新状态，并设置不再重复调谐
            statusRecorder.patchAndCacheStatus(flinkApp, ctx.getKubernetesClient());
            return ReconciliationUtils.toUpdateControl(
                    ctx.getOperatorConfig(), flinkApp, previousDeployment, false); // false 表示不再 reschedule 调谐的逻辑
        }
        // ... 后续的调谐逻辑 ...
    } catch (Exception e) {
        // ... 异常处理 ...
    }
    return ReconciliationUtils.toUpdateControl(
                ctx.getOperatorConfig(), flinkApp, previousDeployment, true);
}
```

对应的核心函数 `validateDeployment` 源码如下：

```java
private boolean validateDeployment(FlinkResourceContext<FlinkDeployment> ctx) {
    var deployment = ctx.getResource();
    // 遍历所有的 validators 并调用每一个验证插件的 validateDeployment 方法
    for (FlinkResourceValidator validator : validators) {
        Optional<String> validationError = validator.validateDeployment(deployment);
        // 如果验证失败，则退出循环，并通过 eventRecorder 发送 Warning 事件，并返回 false
        if (validationError.isPresent()) {
            eventRecorder.triggerEvent(
                    deployment,
                    EventRecorder.Type.Warning,
                    EventRecorder.Reason.ValidationError,
                    EventRecorder.Component.Operator,
                    validationError.get(),
                    ctx.getKubernetesClient());
            return ReconciliationUtils.applyValidationErrorAndResetSpec(
                    ctx, validationError.get());
        }
    }
    return true;
}
```

我们回顾一下第四章节，关于插件发现机制以及自定义验证插件的写法：

---

在 FlinkOperator 的构造函数中就有构造 validators 插件的逻辑，这里的代码还看不出有任何 ServiceLoader 的痕迹 ，代码如下：

```java
/**
 * 发现并加载所有 FlinkResourceValidator 插件
 * 包括默认验证器和自定义插件验证器
 */
public static Set<FlinkResourceValidator> discoverValidators(FlinkConfigManager configManager) {
    // 获取默认配置
    var conf = configManager.getDefaultConfig();
    Set<FlinkResourceValidator> resourceValidators = new HashSet<>();
    
    // 1. 创建并配置默认验证器
    DefaultValidator defaultValidator = new DefaultValidator(configManager);
    defaultValidator.configure(conf);
    resourceValidators.add(defaultValidator);
    
    // 2. 从插件目录加载自定义验证器
    PluginUtils.createPluginManagerFromRootFolder(conf)
            .load(FlinkResourceValidator.class)  // 加载 FlinkResourceValidator 类型的插件
            .forEachRemaining(
                    validator -> {
                        // 记录发现的插件验证器
                        LOG.info(
                                "Discovered resource validator from plugin directory[{}]: {}.",
                                System.getenv()
                                        .getOrDefault(
                                                ConfigConstants.ENV_FLINK_PLUGINS_DIR,  // 环境变量指定的插件目录
                                                ConfigConstants.DEFAULT_FLINK_PLUGINS_DIRS),  // 默认插件目录
                                validator.getClass().getName());
                        
                        // 配置插件验证器
                        validator.configure(conf);
                        // 添加到验证器集合
                        resourceValidators.add(validator);
                    });
    
    // 返回所有验证器的集合
    return resourceValidators;
}
```

从代码中我们能看出，主要插件继承的类是 `FlinkResourceValidator.class`，然后我们从代码中可以看出，插件的 jar 包应该放在 FLINK_PLUGINS_DIR 环境变量对应的文件夹下，给 Flink Operator 打镜像的时候需要注意增加这个逻辑。`PluginUtils` 源自 flink-core 这个库，这里使用的插件发现机制，与 Flink 框架是一致的。

对于自定义插件，以下代码是官方文档提供的[示例](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-release-1.10/docs/operations/plugins/)

```java
// Valudator 例子
public class CustomValidator implements FlinkResourceValidator {

    @Override
    public Optional<String> validateDeployment(FlinkDeployment deployment) {
        if (deployment.getSpec().getFlinkVersion() == null) {
          return Optional.of("Flink Version must be defined.");
        }
        return Optional.empty();
    }

    @Override
    public Optional<String> validateSessionJob(
             FlinkSessionJob sessionJob, Optional<FlinkDeployment> session) {
        if (sessionJob.getSpec().getJob() == null) {
          return Optional.of("The job spec should not be empty");
        }
        return Optional.empty();
    }
}
```

---

从上述代码中，我们能看出实现插件时需要同时实现 validateDeployment 和 validateSessionJob 方法，但对应资源验证时，不同资源会调用其对应的方法。

验证阶段的核心逻辑就是遍历所有的 validators 并调用每一个验证插件的 validateDeployment 方法，如果验证失败，就不会再处理调谐逻辑了。

除了自定义的验证插件以外，FlinkOperator 提供了内置的验证类，DefaultValidator 类，该类实现了 FlinkResourceValidator 接口，并提供了一些默认的验证逻辑。对于 FlinkDeployment 资源，其 validateDeployment 方法的逻辑如下：

```java
@Override
public Optional<String> validateDeployment(FlinkDeployment deployment) {
    // 获取 FlinkDeployment 的规格配置
    FlinkDeploymentSpec spec = deployment.getSpec();
    
    // 构建有效配置：从默认配置开始，基于命名空间和 Flink 版本获取
    Map<String, String> effectiveConfig =
            configManager
                    .getDefaultConfig(
                            deployment.getMetadata().getNamespace(), spec.getFlinkVersion())
                    .toMap();
                    
    // 如果用户提供了自定义 Flink 配置，则覆盖默认配置
    // 用户配置具有更高的优先级
    if (spec.getFlinkConfiguration() != null) {
        effectiveConfig.putAll(spec.getFlinkConfiguration());
    }
    
    // 按顺序执行多项验证检查，一旦发现第一个错误就返回
    // firstPresent 方法会返回第一个非空的 Optional 结果
    return firstPresent(
            // 1. 验证部署名称的有效性（不能为空、符合命名规范等）
            validateDeploymentName(deployment.getMetadata().getName()),
            
            // 2. 验证 Flink 版本的兼容性和支持性
            validateFlinkVersion(deployment),
            
            // 3. 验证 Flink 部署相关的配置项
            validateFlinkDeploymentConfig(effectiveConfig),
            
            // 4. 验证 Ingress 配置的有效性（如果启用了 Ingress）
            validateIngress(
                    spec.getIngress(),
                    deployment.getMetadata().getName(),
                    deployment.getMetadata().getNamespace()),
                    
            // 5. 验证日志配置的有效性
            validateLogConfig(spec.getLogConfiguration()),
            
            // 6. 验证作业规格配置，包括并行度、资源配置等
            validateJobSpec(spec.getJob(), spec.getTaskManager(), effectiveConfig),
            
            // 7. 验证 JobManager 规格配置，包括资源限制、副本数等
            validateJmSpec(spec.getJobManager(), effectiveConfig),
            
            // 8. 验证 TaskManager 规格配置，包括资源限制、任务槽数等
            validateTmSpec(spec.getTaskManager(), effectiveConfig),
            
            // 9. 验证规格变更的有效性，检查升级路径是否合法
            validateSpecChange(deployment, effectiveConfig),
            
            // 10. 验证 ServiceAccount 配置的有效性
            validateServiceAccount(spec.getServiceAccount()),
            
            // 11. 验证自动伸缩相关的 Flink 配置项
            validateAutoScalerFlinkConfiguration(effectiveConfig));
}
```

对应代码的注释，读者就能大概猜出很多函数的功能，而每个函数的返回都是 `Option<String>` 类型，如果返回了 Optional.of 的值，则表示验证失败，返回的值就是错误信息。对应的 firstPresent 方法就是来检查是否有错误信息的。读者可以对应查看每一个函数的逻辑，对于验证逻辑的缺失，则需要自己实现自定义验证插件来予以补充。


### 5.2.5 调谐部署阶段

终于，我们要进入到 reconcile 方法中最核心的部分，调谐阶段的代码实现如下：

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {
    // ... 前面的准备阶段代码 ...
    
    try {
        // 前面观察阶段的代码
        // 验证阶段代码
        // 更新缓存中的状态（保存观察和校验阶段的修改）
        statusRecorder.patchAndCacheStatus(flinkApp, ctx.getKubernetesClient());
        // 调谐逻辑
        reconcilerFactory.getOrCreate(flinkApp).reconcile(ctx);
    } catch (Exception e) {
        // ... 异常处理 ...
    }
    return ReconciliationUtils.toUpdateControl(
                ctx.getOperatorConfig(), flinkApp, previousDeployment, true);
}
```

当完成观察阶段和验证阶段后，代码调用 statusRecorder 的 patchAndCacheStatus 方法来缓存状态。 
这里的 reconcilerFactory 是构造 FlinkDeploymentController 时创建的，目的是对于不同的集群部署类型，返回 SessionReconciler 或者是 ApplicationReconciler 实例，代码如下：

```java
public Reconciler<FlinkDeployment> getOrCreate(FlinkDeployment flinkApp) {
    return reconcilerMap.computeIfAbsent(
            Tuple2.of(
                    Mode.getMode(flinkApp),
                    KubernetesDeploymentMode.getDeploymentMode(flinkApp)),
            modes -> {
                switch (modes.f0) {
                    case SESSION:
                        return new SessionReconciler(eventRecorder, deploymentStatusRecorder);
                    case APPLICATION:
                        return new ApplicationReconciler(
                                eventRecorder, deploymentStatusRecorder, autoscaler);
                    default:
                        throw new UnsupportedOperationException(
                                String.format("Unsupported running mode: %s", modes.f0));
                }
            });
}
```

当从工厂模式创建出对应的 Reconciler 实例后，我们调用其对应的 reconcile 方法。我们在 5.1.2 章节中已经说明过了，AbstractFlinkResourceReconciler 的 reconcile 方法采用模版方法模式，定义了统一的调谐模式，包含了5个步骤，分别是准备就绪、部署流程、伸缩处理、变更处理、其他协调。我们将在接下来的叙述中将前两个步骤定义为集群调谐阶段，后两个步骤定义为业务调谐阶段。对应集群的伸缩处理，我们将在第7章中讲解 FlinkService 时重点展开，读者可以理解为，集群调谐阶段时，如果有规格变更并且集群已经伸缩处理了，那么就不会再进入变更处理步骤了。而我们这里说的变更处理，都是指无法通过集群伸缩处理解决的变更。

另外，5.1.2.2 章节我们给出了对应的核心流程图以及统一调谐流程中的时序图，读者可以翻到前面去回顾一下。接下来我们将与观察阶段相似将 FlinkDeployment 资源的调谐阶段分别集群调谐阶段和业务调谐阶段。集群调谐阶段中，我们会直接重点拆解 ApplicationReconciler 和 SessionReconciler 的方法。而业务调谐阶段中，我们将重点先拆解 AbstractJobReconciler 中关于 Application 模式下 FlinkDeployment 的作业的通用生命周期管理的模版方法，然后再对应不同部署模式下的业务调谐逻辑。

#### 集群调谐阶段

集群调谐阶段中，首先是准备就绪步骤，即对应 reconcile 方法中调用的 readyToReconcile 方法。

对应 Application 集群模式下，该抽象方法对应由 AbstractJobReconciler 实现，代码如下：

```java
@Override
public boolean readyToReconcile(FlinkResourceContext<CR> ctx) {
    var status = ctx.getResource().getStatus();
    // 判断是否是第一次部署
    if (status.getReconciliationStatus().isBeforeFirstDeployment()) {
        return true;
    }
    // 是否需要等待保存点完成
    if (shouldWaitForPendingSavepoint(status.getJobStatus(), ctx.getObserveConfig())) {
        LOG.info("Delaying job reconciliation until pending savepoint is completed.");
        return false;
    }
    return true;
}
```

该方法的逻辑比较简单，主要就是判断是否是第一次部署，以及是否需要等待保存点完成。具体方法代码很简略，读者可以自行查阅。

对应 Session 集群模式，该抽象方法对应由 AbstractJobReconciler 实现，代码如下：

```java
@Override
protected boolean readyToReconcile(FlinkResourceContext<FlinkDeployment> ctx) {
    return true;
}
```

该方法的逻辑比较简单，主要就是直接返回 true，表示可以进行调谐。

接下来，我们来看一下部署步骤，即对应 reconcile 方法中调用的 deploy 方法。

对应 Application 集群模式，该抽象方法对应由 ApplicationReconciler 实现，代码如下：

```java
public void deploy(
        FlinkResourceContext<FlinkDeployment> ctx,
        FlinkDeploymentSpec spec,
        Configuration deployConfig,
        Optional<String> savepoint,
        boolean requireHaMetadata)
        throws Exception {

    var relatedResource = ctx.getResource();
    var status = relatedResource.getStatus();
    var flinkService = ctx.getFlinkService();

    // 移除集群健康评估器中的最后有效集群健康信息
    // 这是为了确保每次部署都从干净的状态开始，避免使用过期的健康状态信息
    ClusterHealthEvaluator.removeLastValidClusterHealthInfo(
            relatedResource.getStatus().getClusterInfo());

    if (savepoint.isPresent()) {
        // Savepoint部署模式：如果提供了savepoint路径，则使用该路径进行状态恢复
        deployConfig.set(SavepointConfigOptions.SAVEPOINT_PATH, savepoint.get());
    } else if (requireHaMetadata && flinkService.atLeastOneCheckpoint(deployConfig)) {
        // 最后状态部署模式：需要HA元数据且配置中至少有一个checkpoint
        // 显式设置一个虚拟的savepoint路径，避免在HA元数据被用户删除时意外恢复错误状态
        deployConfig.set(SavepointConfigOptions.SAVEPOINT_PATH, LAST_STATE_DUMMY_SP_PATH);
        status.getJobStatus().setUpgradeSavepointPath(LAST_STATE_DUMMY_SP_PATH);
        
        // 重要说明：LAST_STATE_DUMMY_SP_PATH 是一个虚拟路径常量，值为 "KUBERNETES_OPERATOR_LAST_STATE"
        // 这个虚拟路径的作用是：
        // 1. 防止意外恢复：避免在HA元数据被用户删除时意外恢复错误状态
        // 2. 标记升级模式：表明这是一个"最后状态"升级，而不是真正的保存点升级
        // 3. 真实路径设置：真实的保存点路径是在Flink集群启动时，由Flink从HA元数据中自动读取和设置的
        // 4. 虚拟路径识别：Flink会识别这个虚拟路径并忽略它，转而使用HA元数据中的真实检查点信息
    } else {
        // 无状态部署：移除用户配置的任何savepoint路径
        deployConfig.removeConfig(SavepointConfigOptions.SAVEPOINT_PATH);
    }

    // 设置Kubernetes资源的所有者引用，确保资源生命周期管理
    // 这建立了FlinkDeployment CR与Kubernetes资源之间的从属关系
    setOwnerReference(relatedResource, deployConfig);
    
    // 设置随机的Job结果存储路径，避免JobManager故障转移时重启已终止的应用
    // 这是为了解决FLINK-27569问题：禁用Job结果清理，为每次部署创建唯一的存储路径
    setRandomJobResultStorePath(deployConfig);

    if (status.getJobManagerDeploymentStatus() != JobManagerDeploymentStatus.MISSING) {
        // 如果JobManager部署状态不是MISSING，说明之前有部署
        // 检查作业是否处于终止状态，然后删除集群部署
        Preconditions.checkArgument(ReconciliationUtils.isJobInTerminalState(status));
        LOG.info("Deleting cluster with terminated application before new deployment");
        flinkService.deleteClusterDeployment(
                relatedResource.getMetadata(), status, deployConfig, !requireHaMetadata);
        // 更新并缓存状态信息到Kubernetes
        statusRecorder.patchAndCacheStatus(relatedResource, ctx.getKubernetesClient());
    }

    // 根据部署模式设置Job ID
    // 对于非最后状态部署，生成新的Job ID以避免checkpoint路径冲突
    // 对于最后状态部署，保持现有Job ID以确保状态恢复
    setJobIdIfNecessary(
            relatedResource, deployConfig, ctx.getKubernetesClient(), requireHaMetadata);

    // 触发事件记录，记录作业提交事件
    // 这提供了操作审计和监控能力
    eventRecorder.triggerEvent(
            relatedResource,
            EventRecorder.Type.Normal,
            EventRecorder.Reason.Submit,
            EventRecorder.Component.JobManagerDeployment,
            MSG_SUBMIT,
            ctx.getKubernetesClient());
    
    // 提交应用集群到Flink服务
    // 这是实际启动Flink集群的核心操作
    flinkService.submitApplicationCluster(spec.getJob(), deployConfig, requireHaMetadata);
    
    // 设置作业状态为RECONCILING（协调中）
    status.getJobStatus().setState(org.apache.flink.api.common.JobStatus.RECONCILING);
    
    // 设置JobManager部署状态为DEPLOYING（部署中）
    status.setJobManagerDeploymentStatus(JobManagerDeploymentStatus.DEPLOYING);

    // 更新Ingress规则，配置外部访问路由
    // 如果spec中配置了ingress，会创建或更新相应的Kubernetes Ingress资源
    // 这允许外部流量通过Ingress访问Flink集群的REST API
    IngressUtils.updateIngressRules(
            relatedResource.getMetadata(), spec, deployConfig, ctx.getKubernetesClient());
}
```

在 Application 模式下部署的集群调谐逻辑是比较复杂的，需要兼顾作业依赖的保存点和检查点的配置，以及 jobId 的设置。这里兼顾作业依赖的保存点和检查点的配置的目的，是为了在业务调谐阶段时，当集群重新部署时，作业是需要从保存点和检查点进行恢复的，这时候也会走 deploy 的逻辑。


我们进入这个 deploy 逻辑时会将 jobStatus 设置为 RECONCILING（协调中），将 jobManagerDeploymentStatus 设置为 DEPLOYING（部署中）。最核心的函数调用就是 flinkService 的 submitApplicationCluster 方法，该方法会按照用户配置的启动 mode，按照对应的方式来启动 Flink 的 Application 模式的集群。这个 mode 我们在第三章有提到，具体是两种模式，一种是 native，另一种是 standalone，分别对应于 flink 控制集群创建和以传统方式部署运行 flink 集群。关于 FlinkService 是如何实现这两种模式的，我们将在第七章节中进行详细介绍，这里读者只需要理解整个调谐阶段过程是如何实现的即可。

需要额外提醒读者的是，这里的 deployConfig 是贯穿整个部署调谐的，在经过 setOwnerReference 的调用之后会加入 `kubernetes.jobmanager.owner.reference` 配置，后续调用 flinkService 创建集群的次要资源时就会读取这个配置来设置次要资源与主要资源之间的从属关系。无论是 Session 模式还是 Application 模式都是如此。

对应 Session 集群模式，该抽象方法对应由 SessionReconciler 实现，代码如下：

```java
public void deploy(
        FlinkResourceContext<FlinkDeployment> ctx,
        FlinkDeploymentSpec spec,
        Configuration deployConfig,
        Optional<String> savepoint,
        boolean requireHaMetadata)
        throws Exception {
    var cr = ctx.getResource();
    
    // 设置Kubernetes资源的所有者引用，确保资源生命周期管理
    // 这建立了FlinkDeployment CR与Kubernetes资源之间的从属关系
    setOwnerReference(cr, deployConfig);
    
    // 提交会话集群到Flink服务
    // 这是启动Flink会话集群的核心操作，与Application模式不同，Session模式不需要处理作业状态恢复
    ctx.getFlinkService().submitSessionCluster(deployConfig);
    
    // 设置JobManager部署状态为DEPLOYING（部署中）
    // 表示会话集群正在部署过程中
    cr.getStatus().setJobManagerDeploymentStatus(JobManagerDeploymentStatus.DEPLOYING);
    
    // 更新Ingress规则，配置外部访问路由
    // 如果spec中配置了ingress，会创建或更新相应的Kubernetes Ingress资源
    // 这允许外部流量通过Ingress访问Flink会话集群的REST API
    IngressUtils.updateIngressRules(
            cr.getMetadata(), spec, deployConfig, ctx.getKubernetesClient());
}
```

从代码以及注释，读者能够很清楚的看出，由于 Session 模式只需要创建集群，不需要关心作业，所以这里的逻辑省去了兼顾保存点、检查点和作业状态的逻辑。

在了解集群部署阶段，接下来我们继续要查看业务调谐阶段。

#### 业务调谐阶段

在业务调谐过程中，首先的步骤是变更处理，即对应 reconcile 方法中调用的 reconcileSpecChange 方法。

对应 Session 集群模式，该抽象方法对应由 SessionReconciler 实现，代码如下：

```java
@Override
protected boolean reconcileSpecChange(
        DiffType diffType,
        FlinkResourceContext<FlinkDeployment> ctx,
        Configuration deployConfig,
        FlinkDeploymentSpec lastReconciledSpec)
        throws Exception {
    var deployment = ctx.getResource();
    
    // 删除现有的会话集群，为新的部署做准备
    deleteSessionCluster(ctx);

    // 在部署前，我们将目标规格记录到升级状态中
    // 这确保了状态跟踪的准确性，即使在部署过程中发生错误
    ReconciliationUtils.updateStatusBeforeDeploymentAttempt(deployment, deployConfig, clock);
    
    // 将状态更新同步到Kubernetes并缓存到本地
    // 这提供了状态持久化和一致性保证
    statusRecorder.patchAndCacheStatus(deployment, ctx.getKubernetesClient());

    // 执行部署操作，使用空的savepoint和不需要HA元数据
    // Session模式不需要处理作业状态恢复，所以使用Optional.empty()
    deploy(ctx, deployment.getSpec(), deployConfig, Optional.empty(), false);
    
    // 部署完成后，更新已部署规格的状态信息
    // 这标志着升级过程的完成
    ReconciliationUtils.updateStatusForDeployedSpec(deployment, deployConfig, clock);
    
    return true;
}
```

读者这里可能会感觉奇怪，为什么要删除现有的会话集群？读者可以翻到 5.1.2.2 通用调谐流程中有一个 DiffType 的使用场景，可见大部分能够触发变更的场景都会涉及到集群配置的变更。而当集群伸缩操作处理不了这个变更时，我们就需要重新部署集群。所以你会看到这里先删除集群，再调用 deploy 重新部署集群的操作。对于 Session 集群模式，我们不需要关心作业的升级操作，所以这里的处理非常简单。

而对于 Session 集群模式，如果不存在规格变更，那么就会进入到其他变更处理。该抽象方法 reconcileOtherChanges 对应由 SessionReconciler 实现，代码如下：

```java
@Override
public boolean reconcileOtherChanges(FlinkResourceContext<FlinkDeployment> ctx)
        throws Exception {
    // 如果需要恢复部署，则恢复部署
    if (shouldRecoverDeployment(ctx.getObserveConfig(), ctx.getResource())) {
        // 通过 FlinkService 的 submitSessionCluster 方法创建 Session 集群
        recoverSession(ctx);
        return true;
    }
    return false;
}
```

这里判断是否需要恢复的逻辑，需要依赖于查看用户是否开启这个配置 `jm-deployment-recovery.enabled`，如果开启并且 JobManager 对应的 Deployment 部署确实是不存在的，那么就会进入到恢复部署的逻辑。这里相当于对应规格没有变更时，调谐阶段的一个补偿逻辑。

解释完 Session 集群模式的业务调谐阶段，我们接着解释更为复杂的 Application 集群模式。

对应 Application 集群模式，该抽象方法 reconcileSpecChange 对应由 AbstractJobReconciler 实现，代码如下：

```java
@Override
protected boolean reconcileSpecChange(
        DiffType diffType,
        FlinkResourceContext<CR> ctx,
        Configuration deployConfig,
        SPEC lastReconciledSpec)
        throws Exception {

    var resource = ctx.getResource();
    STATUS status = resource.getStatus();
    SPEC currentDeploySpec = resource.getSpec();

    // 获取作业的当前状态和期望状态
    JobState currentJobState = lastReconciledSpec.getJob().getState();
    JobState desiredJobState = currentDeploySpec.getJob().getState();

    // 处理SAVEPOINT_REDEPLOY类型的变更：从保存点重新部署
    if (diffType == DiffType.SAVEPOINT_REDEPLOY) {
        redeployWithSavepoint(
                ctx, deployConfig, resource, status, currentDeploySpec, desiredJobState);
        return true;
    }

    // 如果作业当前正在运行，需要先处理升级逻辑
    if (currentJobState == JobState.RUNNING) {
        var jobUpgrade = getJobUpgrade(ctx, deployConfig);
        if (!jobUpgrade.isAvailable()) {
            // 如果作业升级当前不可用（例如检查点信息不可用），检查是否允许其他协调操作
            LOG.info(
                    "Job is not running and checkpoint information is not available for executing the upgrade, waiting for upgradeable state");
            return !jobUpgrade.allowOtherReconcileActions;
        }
        LOG.debug("Job upgrade available: {}", jobUpgrade);

        var suspendMode = jobUpgrade.getSuspendMode();
        if (suspendMode != SuspendMode.NOOP) {
            // 触发作业暂停事件
            eventRecorder.triggerEvent(
                    resource,
                    EventRecorder.Type.Normal,
                    EventRecorder.Reason.Suspended,
                    EventRecorder.Component.JobManagerDeployment,
                    MSG_SUSPENDED,
                    ctx.getKubernetesClient());
        }

        // 尝试取消作业，获取是否为异步取消
        boolean async = cancelJob(ctx, suspendMode);
        if (async) {
            // 异步取消将在后台完成，所以我们必须提前退出协调
            // 并等待其完成以完成升级
            resource.getStatus()
                    .getReconciliationStatus()
                    .setState(ReconciliationState.UPGRADING);
            // 更新最后协调的规格，记录升级模式和部署状态
            ReconciliationUtils.updateLastReconciledSpec(
                    resource,
                    (s, m) -> {
                        s.getJob().setUpgradeMode(jobUpgrade.getRestoreMode());
                        m.setFirstDeployment(false);
                    });
            return true; // 异步取消，调谐结束
        }

        // 记录使用的升级模式到状态中
        currentDeploySpec.getJob().setUpgradeMode(jobUpgrade.getRestoreMode());

        // 根据期望的作业状态更新状态信息
        if (desiredJobState == JobState.RUNNING) {
            // 期望运行状态：更新部署尝试前的状态
            ReconciliationUtils.updateStatusBeforeDeploymentAttempt(
                    resource, deployConfig, clock);
        } else {
            // 其他状态：更新已部署规格的状态
            ReconciliationUtils.updateStatusForDeployedSpec(resource, deployConfig, clock);
        }

        if (suspendMode == SuspendMode.NOOP) {
            // 如果已经是取消状态，我们想要立即恢复，所以修改当前状态
            // 当我们实际执行了可能耗时的取消操作时，我们不这样做，以允许协调规格
            lastReconciledSpec.getJob().setUpgradeMode(jobUpgrade.getRestoreMode());
            currentJobState = JobState.SUSPENDED;
        }
    }

    // 如果作业当前已暂停且期望运行，执行恢复逻辑
    if (currentJobState == JobState.SUSPENDED && desiredJobState == JobState.RUNNING) {
        // 除非请求无状态升级，否则我们继承升级模式
        if (currentDeploySpec.getJob().getUpgradeMode() != UpgradeMode.STATELESS) {
            currentDeploySpec
                    .getJob()
                    .setUpgradeMode(lastReconciledSpec.getJob().getUpgradeMode());
        }
        // 在部署前，我们将目标规格记录到升级状态中
        ReconciliationUtils.updateStatusBeforeDeploymentAttempt(resource, deployConfig, clock);
        statusRecorder.patchAndCacheStatus(resource, ctx.getKubernetesClient());

        // 恢复作业，根据之前暂停时的升级模式决定是否强制使用HA
        restoreJob(
                ctx,
                currentDeploySpec,
                deployConfig,
                // 我们根据作业之前如何暂停来决定是否强制使用HA
                lastReconciledSpec.getJob().getUpgradeMode() == UpgradeMode.LAST_STATE);

        // 更新已部署规格的状态
        ReconciliationUtils.updateStatusForDeployedSpec(resource, deployConfig, clock);
    }
    return true;
}
```

根据上述的代码，我们可以把逻辑分为三部分：
1. 处理保存点重新部署的逻辑
2. 获取作业升级逻辑，并处理取消作业
3. 如果作业当前已经暂停，并期望运行，则恢复作业

读者需要注意的是，当第二部分取消作业时，如果是异步取消，第一次调谐时会直接返回。而此时也不会进入到其他规格变更的处理步骤里，而是等待作业取消过程中被观察阶段所观察到，然后更新相应的状态。等待作业已经被取消而且状态也被修改正确后，将再次进入这部分的第三部分的逻辑。如果作业是同步取消，那么就会接着恢复作业。

读者另外需要注意到的一点是，这里有一个新的概念是作业升级逻辑，对应实现类是 JobUpgrade 代码如下：

```java
@Value
public static class JobUpgrade {
    SuspendMode suspendMode;
    UpgradeMode restoreMode;
    boolean available;
    boolean allowFallback;
    boolean allowOtherReconcileActions;

    static JobUpgrade stateless(boolean terminal) {
        return new JobUpgrade(
                terminal ? SuspendMode.NOOP : SuspendMode.STATELESS,
                UpgradeMode.STATELESS,
                true,
                false,
                false);
    }

    static JobUpgrade savepoint(boolean terminal) {
        return new JobUpgrade(
                terminal ? SuspendMode.NOOP : SuspendMode.SAVEPOINT,
                UpgradeMode.SAVEPOINT,
                true,
                false,
                false);
    }

    static JobUpgrade lastStateUsingHaMeta() {
        return new JobUpgrade(
                SuspendMode.LAST_STATE, UpgradeMode.LAST_STATE, true, false, false);
    }

    static JobUpgrade lastStateUsingCancel() {
        return new JobUpgrade(SuspendMode.CANCEL, UpgradeMode.SAVEPOINT, true, false, false);
    }

    static JobUpgrade pendingCancellation() {
        return new JobUpgrade(null, null, false, false, false);
    }

    static JobUpgrade pendingUpgrade() {
        return new JobUpgrade(null, null, false, false, true);
    }

    static JobUpgrade unavailable() {
        return new JobUpgrade(null, null, false, true, true);
    }
}
```

基于上述的 `JobUpgrade` 类，我们结合 Flink Operator 的文档给出下表，详细对比了这三种模式的特点：

| 升级模式 | 无状态升级 | 最新状态升级 | 保存点升级 |
|----------|------------|--------------|------------|
| **配置要求** | 无 | 启用检查点 | 定义检查点/保存点目录 |
| **作业状态要求** | 无 | 作业或HA元数据可访问 | 作业运行中* |
| **暂停机制** | 取消/删除 | 取消/删除（保留HA元数据） | 创建保存点后取消 |
| **恢复机制** | 空状态 | 使用HA元数据或最后的检查点/保存点 | 从保存点恢复 |
| **生产环境使用** | 不推荐 | 推荐 | 推荐 |

三种升级模式和代码的对应关系如下：
- **无状态升级**：对应 `JobUpgrade.stateless()` 方法，适用于不需要保留状态的场景，但会丢失所有作业状态
- **最新状态升级**：对应 `JobUpgrade.lastStateUsingHaMeta()` 或者 `JobUpgrade.lastStateUsingCancel()` 方法，利用Flink的高可用机制，从集群高可用元数据中恢复最后的检查点状态。如果元数据不存在，则需要手动恢复。`JobUpgrade.lastStateUsingCancel()` 一般是用于 FlinkSessionJob 的场景，而 FlinkDeployment 的场景一般对应 `JobUpgrade.lastStateUsingHaMeta()`。
- **保存点升级**：对应 `JobUpgrade.savepoint()` 方法，在升级前创建保存点，确保状态不丢失。作业恢复时通过保存点来恢复。

这三种升级模式与 `JobUpgrade` 类的设计完全对应，`SuspendMode` 决定了如何暂停作业，`UpgradeMode` 决定了如何恢复状态，两者结合实现了完整的升级策略。

为了更清楚地理解 `getJobUpgrade` 方法的逻辑，我们绘制一个流程图来梳理各种情况的判断：

{{< mermaid >}}
flowchart TD
    A[开始 getJobUpgrade] --> B{检查升级模式}
    
    B -->|STATELESS| C[无状态升级]
    C --> C1[返回 JobUpgrade.stateless terminal]
    
    B -->|SAVEPOINT| D[保存点升级逻辑]
    B -->|LAST_STATE| E[最后状态升级逻辑]
    
    D --> D1{作业是否运行中}
    D1 -->|是| D2[返回 JobUpgrade.savepoint]
    D1 -->|否| D3{版本是否变更 或 启用回退}
    D3 -->|是| D4[回退到 LAST_STATE 模式]
    D3 -->|否| D5[返回 JobUpgrade.pendingUpgrade]
    
    E --> E1{版本是否变更}
    E1 -->|是| E2[版本升级特殊处理]
    E1 -->|否| E3{作业是否运行中}
    
    E2 --> E2A{是否可以创建保存点}
    E2A -->|是| E2B[返回 JobUpgrade.savepoint]
    E2A -->|否| E2C{作业是否可取消}
    E2C -->|是| E2D[返回 JobUpgrade.lastStateUsingCancel]
    E2C -->|否| E2E[返回 JobUpgrade.pendingUpgrade]
    
    E3 -->|是| E4[基于作业回退时间决定升级模式]
    E3 -->|否| E5{是否允许取消}
    E5 -->|是| E6[返回 JobUpgrade.lastStateUsingCancel]
    E5 -->|否| E7[返回 JobUpgrade.unavailable]
    
    E4 --> E4A{回退时间是否超过阈值}
    E4A -->|是| E4B[返回 JobUpgrade.savepoint]
    E4A -->|否| E4C[返回 JobUpgrade.lastStateUsingHaMeta]
    
    F[前置检查 作业状态] --> F1{作业是否已取消}
    F1 -->|是| F2{是否有已知的保存点}
    F2 -->|是| F3[返回 JobUpgrade.savepoint]
    F2 -->|否| F4[抛出升级失败异常]
    
    F1 -->|否| F5{作业是否正在取消}
    F5 -->|是| F6[返回 JobUpgrade.pendingCancellation]
    
    F1 -->|否| F7[继续正常升级逻辑]
    F7 --> B
    
    style A fill:#e1f5fe
    style C1 fill:#c8e6c9
    style D2 fill:#c8e6c9
    style D5 fill:#ffcdd2
    style E2B fill:#c8e6c9
    style E2D fill:#c8e6c9
    style E2E fill:#ffcdd2
    style E4B fill:#c8e6c9
    style E4C fill:#c8e6c9
    style E6 fill:#c8e6c9
    style E7 fill:#ffcdd2
    style F3 fill:#c8e6c9
    style F4 fill:#ff9800
    style F6 fill:#fff3e0
{{< /mermaid >}}

流程图中有判断作业是否为终止状态或者运行中，这些状态的判断都来自于观察阶段写入的作业状态。而流程图中提到的版本变更，指的是 Flink 的版本变更，这里指的是 spec 中的 flinkVersion 字段。模式有两种暂停机制，一种是删除集群，另一种是取消作业。另外保存点升级模式在作业处于非健康状态时会回退到最新状态升级模式。这个回退操作目前只支持 FlinkDeployment 资源的 Application 集群模式，如果不想要这个回退操作，可以设置 `job.upgrade.last-state-fallback.enabled` 为 false。而最新状态升级模式中所谓的回退时间这里主要使用到的配置是 `job.upgrade.last-state.max.allowed.checkpoint.age`，如果作业的最新的检查点超过了这个配置，即检查点过旧就会使用保存点升级模式。

上述的逻辑是 FlinkDeployment 和 FlinkSessionJob 共有的逻辑，正如我们在 5.1.2.1 基础接口与类层次的章节中提到的， AbstractJobReconciler 抽象了包括 Application 模式下 FlinkDeployment 的作业以及 FlinkSessionJob 对应的作业的通用生命周期管理的共有逻辑。

针对 Application 集群模式下的升级模式，ApplicationReconciler 在 AbstractJobReconciler 的 getJobUpgrade 方法基础上进一步扩展了如下的逻辑，代码如下：

```java
@Override
protected JobUpgrade getJobUpgrade(
        FlinkResourceContext<FlinkDeployment> ctx, Configuration deployConfig)
        throws Exception {

    var deployment = ctx.getResource();
    var status = deployment.getStatus();
    
    // 首先调用父类方法获取基础的升级策略
    var availableUpgradeMode = super.getJobUpgrade(ctx, deployConfig);

    // 如果升级策略可用或不允许回退，直接返回父类的结果
    if (availableUpgradeMode.isAvailable() || !availableUpgradeMode.isAllowFallback()) {
        return availableUpgradeMode;
    }
    
    var flinkService = ctx.getFlinkService();

    // 检查高可用模式是否激活，以及HA元数据是否可用
    // 如果作业不在运行但HA元数据可用，可以进行最后状态恢复升级
    if (HighAvailabilityMode.isHighAvailabilityModeActivated(deployConfig)
            && HighAvailabilityMode.isHighAvailabilityModeActivated(ctx.getObserveConfig())
            && flinkService.isHaMetadataAvailable(deployConfig)) {
        LOG.info(
                "Job is not running but HA metadata is available for last state restore, ready for upgrade");
        return JobUpgrade.lastStateUsingHaMeta();
    }

    var jmDeployStatus = status.getJobManagerDeploymentStatus();
    
    // 特殊处理：如果JM部署状态不是MISSING，且升级模式不是LAST_STATE，且JM Pod从未启动过
    // 这种情况需要删除未启动的JM，然后重新评估升级策略
    if (jmDeployStatus != JobManagerDeploymentStatus.MISSING
            && status.getReconciliationStatus()
                            .deserializeLastReconciledSpec()
                            .getJob()
                            .getUpgradeMode()
                    != UpgradeMode.LAST_STATE
            && FlinkUtils.jmPodNeverStarted(ctx.getJosdkContext())) {
        
        // 删除从未启动过的JM，清理异常状态
        deleteJmThatNeverStarted(flinkService, deployment, deployConfig);
        
        // 递归调用自身方法，基于清理后的状态重新评估升级策略
        // 注意：这是一个有条件的递归，通过状态变化确保能够终止
        return getJobUpgrade(ctx, deployConfig);
    }

    // 检查JM部署状态：如果JM缺失或出错，且HA元数据不可用
    // 这种情况下无法进行有状态升级，抛出异常
    if ((jmDeployStatus == JobManagerDeploymentStatus.MISSING
                    || jmDeployStatus == JobManagerDeploymentStatus.ERROR)
            && !flinkService.isHaMetadataAvailable(deployConfig)) {
        throw new UpgradeFailureException(
                "JobManager deployment is missing and HA data is not available to make stateful upgrades. "
                        + "It is possible that the job has finished or terminally failed, or the configmaps have been deleted. "
                        + "Manual restore required.",
                "UpgradeFailed");
    }

    // 如果以上所有条件都不满足，返回不可用的升级策略
    return JobUpgrade.unavailable();
}
```

对于 Application 集群模式，这里补充的逻辑在于最新状态升级模式，其中最核心的两点在于，一是补充 AbstractJobReconciler 中当作业升级模式是最新状态时，如果有开启HA则按照HA的元数据中的最新检查点进行作业恢复；二是考虑了当配置错误导致的 JobManager 的 Deployment 就不曾正常启动的情况，代码会删除旧的 Deployment，并按照最新的部署配置来重新部署，然后重新评估升级模式。最后，如果这个部署就是有报错，那么会抛出 UpgradeFailureException 异常。

如果读者理解了不同的情况下的升级模式，那么对于 Application 集群模式下的规格变更处理就能有一定感性的认知，读者就能理解其实规格变更处理的核心在于根据升级模式，取消作业和恢复作业，换句话说就是管理作业的生命周期。


对于其他规格变更的处理，对于 Application 集群模式，该抽象方法 reconcileOtherChanges 由 AbstractJobReconciler 和 ApplicationReconciler 实现，AbstractJobReconciler 中的代码如下：

```java
@Override
public boolean reconcileOtherChanges(FlinkResourceContext<CR> ctx) throws Exception {
    var status = ctx.getResource().getStatus();
    var jobStatus = status.getJobStatus().getState();
    
    // 检查作业是否失败，以及是否启用了失败作业重启功能
    if (jobStatus == org.apache.flink.api.common.JobStatus.FAILED
            && ctx.getObserveConfig().getBoolean(OPERATOR_JOB_RESTART_FAILED)) {
        
        LOG.info("Stopping failed Flink job...");
        
        // 清理失败作业的相关资源
        cleanupAfterFailedJob(ctx);
    
        // 清除错误状态，为重新提交做准备
        status.setError(null);
        
        // 重新提交作业，不要求HA元数据（因为作业失败，可能没有可用的检查点）
        resubmitJob(ctx, false);
        
        return true;
    } else {
        // 如果作业没有失败，检查是否需要触发快照操作
        
        // 检查是否需要触发保存点（savepoint）
        // 这通常用于作业升级或手动快照需求
        boolean savepointTriggered = triggerSnapshotIfNeeded(ctx, SAVEPOINT);
        
        // 检查是否需要触发检查点（checkpoint）
        // 这通常用于自动检查点或配置的检查点策略
        boolean checkpointTriggered = triggerSnapshotIfNeeded(ctx, CHECKPOINT);

        // 返回是否有任何快照操作被触发
        // 如果触发了保存点或检查点，返回true；否则返回false
        return savepointTriggered || checkpointTriggered;
    }
}
```

在代码中，作业失败重启的逻辑对应的配置是 `job.restart.failed` 默认是不开启的（对应是 false），因为如果作业配置了失败次数，当达到失败次数时作业就会变成失败状态，而再加上这个失败重启时，这个作业就永远循环重启，所以也不建议开启。因此这个函数，一般是周期性的触发触发保存点或者检查点。如果触发成功，则表示集群和作业都是正常的。内部实现中也是使用的 FlinkService 来进行 REST API 的调用，如果调用成功则返回 true。如果任何一个触发失败了，那么就会返回 false，而在 ApplicationReconciler 的实现就会进一步检查集群和作业的健康状态，并进行恢复。

ApplicationReconciler 中代码实现如下：

```java
@Override
public boolean reconcileOtherChanges(FlinkResourceContext<FlinkDeployment> ctx)
        throws Exception {
    
    // 首先调用父类方法处理基础的变更（如失败作业重启、快照触发等）
    // 如果父类方法返回true，说明已经处理了变更，直接返回
    if (super.reconcileOtherChanges(ctx)) {
        return true;
    }

    var deployment = ctx.getResource();
    var observeConfig = ctx.getObserveConfig();
    
    // 检查是否因为作业不健康而需要重启
    // 这通常基于集群健康检查的结果
    boolean shouldRestartJobBecauseUnhealthy =
            shouldRestartJobBecauseUnhealthy(deployment, observeConfig);
    
    // 检查是否需要恢复部署
    // 这通常检查JobManager的Deployment是否存在且正常
    boolean shouldRecoverDeployment = shouldRecoverDeployment(observeConfig, deployment);
    
    // 如果需要重启不健康的作业或恢复部署，执行相应的操作
    if (shouldRestartJobBecauseUnhealthy || shouldRecoverDeployment) {
        
        // 如果需要恢复部署，触发恢复部署事件
        if (shouldRecoverDeployment) {
            eventRecorder.triggerEvent(
                    deployment,
                    EventRecorder.Type.Warning,           // 事件类型：警告
                    EventRecorder.Reason.RecoverDeployment, // 事件原因：恢复部署
                    EventRecorder.Component.Job,           // 事件组件：作业
                    MSG_RECOVERY,                          // 恢复消息
                    ctx.getKubernetesClient());
        }

        // 如果需要重启不健康的作业，触发重启事件并清理资源
        if (shouldRestartJobBecauseUnhealthy) {
            eventRecorder.triggerEvent(
                    deployment,
                    EventRecorder.Type.Warning,                // 事件类型：警告
                    EventRecorder.Reason.RestartUnhealthyJob,  // 事件原因：重启不健康作业
                    EventRecorder.Component.Job,               // 事件组件：作业
                    MSG_RESTART_UNHEALTHY,                     // 重启不健康作业消息
                    ctx.getKubernetesClient());
            
            // 清理失败作业的相关资源，为重新提交做准备
            cleanupAfterFailedJob(ctx);
        }

        // 重新提交作业
        // 根据是否启用高可用模式决定是否需要HA元数据
        resubmitJob(
                ctx,
                HighAvailabilityMode.isHighAvailabilityModeActivated(ctx.getObserveConfig()));
        
        return true; // 表示已处理变更
    }

    // 如果没有需要重启或恢复的情况，检查是否需要清理过期的JobManager
    // 这通常用于清理已经终止但还未被删除的JobManager资源
    return cleanupTerminalJmAfterTtl(ctx.getFlinkService(), deployment, observeConfig);
}
```
函数首先调用的是父类的 reconcileOtherChanges 方法，如果返回是 true，则表示父类已经重启了作业或者是保存了保存点或者是检查点，那么就无需再检查作业或者是集群的健康情况，就直接退出。`shouldRestartJobBecauseUnhealthy` 方法中判断的依据是我们在 5.2.3.1 ApplicationObserver 观察过程章节中的业务观察阶段中进行的集群健康的检查，用户需要配置 `cluster.health-check.enabled` 开启集群健康检查，集群健康检查结果是 clusterHealthInfo。如果集群不是健康的而且升级模式是无状态升级、或者集群的高可用是开启的，那么就需要重启作业。`shouldRecoverDeployment` 方法中判断依据是 JobManager 对应的 Deployment 部署是否正常，如果不正常则需要进行部署的恢复，但用户需要配置 `jm-deployment-recovery.enabled` 才能开启这个逻辑。当集群不健康时，代码调用 `cleanupAfterFailedJob` 方法清理集群的部署，接着调用的 `resubmitJob` 方法重新创建集群和提交作业。

如果作业已经处于终止状态，这时保存点和检查点的操作也不会处理，所以父类方法会返回 false。这时需要清理集群，代码对应调用 `cleanupTerminalJmAfterTtl` 方法，清理集群时会对应配置 `jm-deployment.shutdown-ttl`，默认值是 1 天，也就是如果作业处于终止状态的更新时间已经是 1 天前了，那么就会清理集群。

最后，读者会经常在代码中看到清理集群的逻辑，即 FlinkService 的 deleteClusterDeployment 方法，这个方法有一个 deleteHaData 的布尔类型的参数，对应是否删除 HA 的数据，对于集群清理的时候，一般是 false，则对应不清理。读者可能会感到困惑，究竟 HA 数据什么时候清理，答案是当清理 FlinkDeployment 自定义资源的时候，才会一并清理。

### 5.2.6 资源清理阶段

在资源清理阶段，FlinkDeploymentController 实现了 Java Operator SDK 的 Cleaner 接口，其 cleanup 方法的实现如下：

```java
@Override
public DeleteControl cleanup(FlinkDeployment flinkApp, Context josdkContext) {
    if (canaryResourceManager.handleCanaryResourceDeletion(flinkApp)) {
        return DeleteControl.defaultDelete();
    }
    eventRecorder.triggerEvent(
            flinkApp,
            EventRecorder.Type.Normal,
            EventRecorder.Reason.Cleanup,
            EventRecorder.Component.Operator,
            "Cleaning up FlinkDeployment",
            josdkContext.getClient());
    statusRecorder.updateStatusFromCache(flinkApp);
    var ctx = ctxFactory.getResourceContext(flinkApp, josdkContext);
    try {
        observerFactory.getOrCreate(flinkApp).observe(ctx);
    } catch (Exception err) {
        LOG.error("Error while observing for cleanup", err);
    }

    var deleteControl = reconcilerFactory.getOrCreate(flinkApp).cleanup(ctx);
    if (deleteControl.isRemoveFinalizer()) {
        statusRecorder.removeCachedStatus(flinkApp);
        ctxFactory.cleanup(flinkApp);
    } else {
        statusRecorder.patchAndCacheStatus(flinkApp, ctx.getKubernetesClient());
    }
    return deleteControl;
}
```

我们能看到这个函数的主要逻辑中会先进行金丝雀资源的判断，然后也会进行观察和调谐，调谐的时候调用的是 cleanup 这个方法。接着，我们主要看一下这个方法的实现，代码如下：

```java
@Override
public DeleteControl cleanup(FlinkResourceContext<CR> ctx) {
    autoscaler.cleanup(ResourceID.fromResource(ctx.getResource()));
    return cleanupInternal(ctx);
}
```

我们先忽略 autoscaler 的逻辑，主要看一下 cleanupInternal 方法在 ApplicationReconciler 中的实现，代码如下：

```java
@Override
@SneakyThrows
protected DeleteControl cleanupInternal(FlinkResourceContext<FlinkDeployment> ctx) {
    // 获取Flink部署资源和状态信息
    var deployment = ctx.getResource();
    var status = deployment.getStatus();
    var conf = ctx.getDeployConfig(ctx.getResource().getSpec());
    
    // 检查是否在首次部署之前或者作业已经处于终止状态
    if (status.getReconciliationStatus().isBeforeFirstDeployment()
            || ReconciliationUtils.isJobInTerminalState(status)) {
        // 如果作业从未部署过或已经终止，直接删除集群部署
        // deleteClusterDeployment方法会：
        // 1. 删除Kubernetes中的JobManager和TaskManager部署
        // 2. 根据deleteHaData参数决定是否删除高可用元数据
        // 3. 更新部署状态为已删除
        ctx.getFlinkService()
                .deleteClusterDeployment(deployment.getMetadata(), status, conf, true);
    } else {
        // 如果作业正在运行，需要先优雅地停止作业
        var observeConfig = ctx.getObserveConfig();
        // 根据配置决定停止模式：
        // SAVEPOINT: 创建保存点后停止作业，保留状态用于恢复
        // STATELESS: 无状态停止，不创建保存点
        var suspendMode =
                observeConfig.getBoolean(KubernetesOperatorConfigOptions.SAVEPOINT_ON_DELETION)
                        ? SuspendMode.SAVEPOINT
                        : SuspendMode.STATELESS;
        // cancelJob方法会根据suspendMode执行不同的停止策略：
        // - SAVEPOINT: 创建保存点后取消作业，然后删除集群
        // - STATELESS: 直接取消作业，然后删除集群
        cancelJob(ctx, suspendMode);
    }
    // 返回默认删除控制，表示可以安全删除资源
    return DeleteControl.defaultDelete();
}
```

从代码注释可以看出，当清理 FlinkDeployment 资源时，清理集群资源时才会彻底删除高可用元数据。但是如果作业正在运行，则会先进行作业的优雅停止，然后删除集群。删除集群时，如果用户有配置 `job.savepoint-on-deletion` 为 true，则会在停止作业时创建保存点，然后不删除集群，等待下一次清理触发时，删除集群。如果用户有配置 `job.savepoint-on-deletion` 为 false，则会在停止作业时直接删除集群并同时删除元数据。

上述就是业务调谐阶段的所有内容，接下来我们将进入 FlinkSessionJobController 的源码解析。


## 5.3 FlinkSessionJob Controller 源码解析

### 5.3.1 核心成员变量和方法

FlinkSessionJobController 是负责管理 FlinkSessionJob 资源的控制器，其结构与 FlinkDeploymentController 类似，但专门处理会话作业资源。

```java
@ControllerConfiguration()
public class FlinkSessionJobController
        implements Reconciler<FlinkSessionJob>,
                ErrorStatusHandler<FlinkSessionJob>,
                EventSourceInitializer<FlinkSessionJob>,
                Cleaner<FlinkSessionJob> {

    // 核心成员变量
    private final Set<FlinkResourceValidator> validators;                    // 资源验证器集合
    private final FlinkResourceContextFactory ctxFactory;                   // 资源上下文工厂
    private final Reconciler<FlinkSessionJob> reconciler;                   // 调谐器
    private final Observer<FlinkSessionJob> observer;                       // 观察者
    private final StatusRecorder<FlinkSessionJob, FlinkSessionJobStatus> statusRecorder;  // 状态记录器
    private final EventRecorder eventRecorder;                              // 事件记录器
    private final CanaryResourceManager<FlinkSessionJob> canaryResourceManager;  // 金丝雀资源管理器
}
```

**成员变量说明**：
- **validators**：验证插件，用于验证 FlinkSessionJob 资源
- **ctxFactory**：资源上下文工厂，负责创建 FlinkSessionJob 的处理上下文
- **reconciler**：调谐器，根据部署模式创建对应的调谐器
- **observer**：观察者，负责创建和管理 FlinkSessionJob 的观察者
- **statusRecorder**：状态记录器，管理 FlinkSessionJob 的状态缓存和更新
- **eventRecorder**：事件记录器，负责记录和触发 Kubernetes 事件
- **canaryResourceManager**：金丝雀资源管理器，处理金丝雀资源的特殊逻辑

#### 类图

{{< mermaid >}}
classDiagram
    class FlinkSessionJobController
    class Reconciler {
        +reconcile(context)
        +cleanup(context)
    }
    class ErrorStatusHandler {
        updateErrorStatus
    }
    class EventSourceInitializer {
        prepareEventSources
    }
    class Cleaner {
        cleanup
    }
    
    FlinkSessionJobController ..|> Reconciler
    FlinkSessionJobController ..|> ErrorStatusHandler
    FlinkSessionJobController ..|> EventSourceInitializer
    FlinkSessionJobController ..|> Cleaner
{{< /mermaid >}}

第二章我们已经解释过这些对应的函数，FlinkSessionJobController 的主要逻辑也就是实现这些接口的方法：
- Reconciler：Java Operator SDK 的核心接口，定义调谐逻辑的 reconcile 方法
- ErrorStatusHandler：错误状态处理接口，处理调谐过程中的异常的 updateErrorStatus 方法
- EventSourceInitializer：事件源初始化接口，设置事件监听 prepareEventSources 方法
- Cleaner：资源清理接口，处理资源删除逻辑的 cleanup 方法

这些方法在 5.2.1 章节中也有提过了，这里不再赘述。

### 5.3.2 调谐准备阶段

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {

    // 1. 金丝雀资源处理：如果是金丝雀资源，直接返回不更新
    // 金丝雀资源用于测试和验证，不需要进行实际的调谐操作
     if (canaryResourceManager.handleCanaryResourceReconciliation(
            flinkSessionJob, josdkContext.getClient())) {
        return UpdateControl.noUpdate();
    }

    LOG.info("Starting reconciliation");

    // 2. 状态恢复：从缓存更新资源状态，减少状态不一致的可能性
    // 如果资源不在缓存中，则加入缓存，确保状态的一致性
    statusRecorder.updateStatusFromCache(flinkSessionJob);
    
    // 3. 资源克隆：创建当前资源的副本，用于后续状态比较
    // 这个副本将用于检测资源状态的变化，决定是否需要更新
    FlinkSessionJob previousJob = ReconciliationUtils.clone(flinkSessionJob);
    
    // 4. 上下文创建：为当前资源创建专用的处理上下文
    // 上下文包含了 Kubernetes 客户端、配置信息等调谐过程中需要的所有组件
    var ctx = ctxFactory.getResourceContext(flinkSessionJob, josdkContext);

    // 5. 版本验证：检查 Flink 版本是否支持，不支持则触发事件并退出
    // 确保 Operator 能够处理当前 Flink 版本，避免版本不兼容导致的问题
    if (!ValidatorUtils.validateSupportedVersion(ctx, eventRecorder)) {
        return UpdateControl.noUpdate();
    }

    // 6. 观察、验证、调谐阶段代码
    // ... other code ...

    // 返回更新控制指令，告知 JOSDK 需要更新资源
    return UpdateControl.update(flinkSessionJob);
}
```

**调谐准备阶段的核心步骤**

1. 金丝雀资源检查：优先处理金丝雀资源，如果是金丝雀资源则直接返回
2. 状态恢复：从本地缓存恢复资源状态，避免因 JOSDK 缓存导致的状态不一致
3. 资源备份：创建当前资源的副本，用于后续状态变更比较
4. 上下文构建：创建包含 Kubernetes 客户端、配置等信息的处理上下文
5. 版本验证：验证 Flink 版本兼容性，确保 Operator 能够处理该版本

这里的资源备份，只是将对象重新克隆一个，没有特殊逻辑。除了版本验证，其他的步骤前文都有提到，读者可以对照着函数直接看前文的介绍即可。FlinkOperator 与 Flink 的版本兼容关系在 5.2.2 章节中已经提过了，读者可以翻到前面回顾，这里不再赘述。

### 5.3.3 调谐观察阶段

在 FlinkSessionJobController 的 reconcile 方法中，观察阶段的代码实现如下：

```java
@Override
public UpdateControl<FlinkSessionJob> reconcile(FlinkSessionJob flinkSessionJob, Context josdkContext) {
    // ... 前面的准备阶段代码 ...
    
    // 观察阶段：执行FlinkSessionJob的观察逻辑
    observer.observe(ctx);
    
    // ... 后续的验证和调谐逻辑 ...
}
```

与 FlinkDeploymentController 不同，FlinkSessionJobController 使用的是单一的观察器实例，而不是工厂模式。这是因为 FlinkSessionJob 只有一种运行模式，不需要根据不同模式创建不同的观察器。

**FlinkSessionJobObserver 观察流程**

FlinkSessionJobObserver 继承自 AbstractFlinkResourceObserver，其观察逻辑专门针对会话作业进行了优化。

```java
@Override
public final void observe(FlinkResourceContext<CR> ctx) {
    // 检查资源是否准备好被观察
    if (!isResourceReadyToBeObserved(ctx)) {
        return;
    }

    // 触发资源特定的观察逻辑
    observeInternal(ctx);

    // 重置快照触发器
    SnapshotUtils.resetSnapshotTriggers(
            ctx.getResource(), eventRecorder, ctx.getKubernetesClient());
}
```

**FlinkSessionJob 特有的就绪检查**

FlinkSessionJobObserver 重写了 `isResourceReadyToBeObserved` 方法，增加了会话作业特有的检查：

```java
@Override
protected boolean isResourceReadyToBeObserved(FlinkResourceContext<FlinkSessionJob> ctx) {
    // 1. 调用父类的基础检查（暂停状态、升级状态、回滚状态等）
    // 2. 额外检查：确保 FlinkService 可用（目标会话集群必须可访问）
    return super.isResourceReadyToBeObserved(ctx) && ctx.getFlinkService() != null;
}
```

这个额外的检查很重要：`ctx.getFlinkService() != null` 确保目标会话集群可访问。如果会话集群不可访问，就无法进行作业状态的观察。

**核心观察逻辑（observeInternal）**

根据源码，FlinkSessionJobObserver 的 observeInternal 方法实现非常简洁：

```java
@Override
protected void observeInternal(FlinkResourceContext<FlinkSessionJob> ctx) {
    // 1. 首先观察作业状态，返回是否找到作业
    var jobFound = jobStatusObserver.observe(ctx);
    
    // 2. 只有在找到作业的情况下，才进行快照状态观察
    if (jobFound) {
        // 观察保存点状态
        savepointObserver.observeSavepointStatus(ctx);
        // 观察检查点状态
        savepointObserver.observeCheckpointStatus(ctx);
    }
}
```

jobStatusObserver 和 savepointObserver 我们在 5.1.1.1 和 5.1.1.2 章节中已经提过了，读者可以翻到前面回顾，这里不再赘述。总的来说，FlinkSessionJobObserver 和 SessionObserver 的观察逻辑是相互补充的，SessionObserver 观察了 Session 集群状态，而 FlinkSessionJobObserver 观察了作业状态和保存点/检查点的状态。

**与 FlinkDeployment 观察的关键差异**

| 对比项 | FlinkSessionJob | FlinkDeployment |
|--------|-----------------|------------------|
| 观察器创建 | 单一观察器实例 | 工厂模式创建多种观察器 |
| JobManager管理 | 依赖现有会话集群 | 需要观察自己的JobManager部署 |
| 就绪检查 | 额外检查FlinkService可用性 | 检查JobManager部署状态 |
| 观察内容 | 作业状态 + 快照状态 | 集群部署 + 作业状态 + 快照状态 + 集群健康 |
| 复杂度 | 相对简单 | 较为复杂 |

FlinkSessionJob 的观察逻辑体现了会话模式的特点：**依赖现有集群、关注作业本身**。这种设计使得会话作业的观察更加高效和专注。

### 5.3.4 调谐验证阶段

FlinkSessionJob 的验证阶段在 FlinkSessionJobController 中通过 `validateSessionJob` 方法实现，其复杂度高于 FlinkDeployment，因为需要验证会话作业与目标会话集群的兼容性。

在 reconcile 方法中，验证阶段的代码实现如下：

```java
@Override
public UpdateControl<FlinkSessionJob> reconcile(FlinkSessionJob flinkSessionJob, Context josdkContext) {
    // ... 前面的观察阶段代码 ...
    
    // 验证阶段：验证FlinkSessionJob资源配置的有效性
    if (!validateSessionJob(ctx)) {
        // 验证失败：更新状态并停止调谐流程
        statusRecorder.patchAndCacheStatus(flinkSessionJob, ctx.getKubernetesClient());
        return ReconciliationUtils.toUpdateControl(
                ctx.getOperatorConfig(), flinkSessionJob, previousJob, false);
    }
    
    // ... 后续的调谐逻辑 ...
}
```

**核心验证方法（validateSessionJob）**

根据源码，FlinkSessionJobController 中的 `validateSessionJob` 方法实现如下：

```java
private boolean validateSessionJob(FlinkResourceContext<FlinkSessionJob> ctx) {
    var sessionJob = ctx.getResource();
    
    // 遍历所有验证插件
    for (FlinkResourceValidator validator : validators) {
        Optional<String> validationError =
                validator.validateSessionJob(
                        sessionJob,
                        // 关键：通过JOSDK获取目标会话集群资源
                        // 这是会话作业验证的核心 - 需要目标集群信息进行兼容性验证
                        ctx.getJosdkContext().getSecondaryResource(FlinkDeployment.class));
                        
        if (validationError.isPresent()) {
            // 验证失败处理
            eventRecorder.triggerEvent(
                    sessionJob,
                    EventRecorder.Type.Warning,
                    EventRecorder.Reason.ValidationError,
                    EventRecorder.Component.Operator,
                    validationError.get(),
                    ctx.getKubernetesClient());
            
            // 应用验证错误并重置规格
            return ReconciliationUtils.applyValidationErrorAndResetSpec(
                    ctx, validationError.get());
        }
    }
    return true; // 所有验证都通过
}
```

内置的 DefaultValidator 实现了在实现 validateSessionJob 中有两层逻辑，由于创建 FlinkSessionJob 资源时，需要指定 deploymentName 来对应 Session 集群的 FlinkDeployment 资源。由于 FlinkDeployment 资源是先创建的，所以 FlinkSessionJob 资源创建时，FlinkDeployment 资源可能还不存在，所以需要进行两层验证。

```java
@Override
public Optional<String> validateSessionJob(
        FlinkSessionJob sessionJob, Optional<FlinkDeployment> sessionOpt) {
    
    if (sessionOpt.isEmpty()) {
        // 目标会话集群不存在或未就绪：仅进行会话作业本身的验证
        return validateSessionJobOnly(sessionJob);
    } else {
        // 目标会话集群存在：进行完整的兼容性验证
        return firstPresent(
                validateSessionJobOnly(sessionJob),           // 作业独立验证
                validateSessionJobWithCluster(sessionJob, sessionOpt.get()));  // 集群兼容性验证
    }
}
```

第一层负责会话作业独立验证（validateSessionJobOnly）

```java
private Optional<String> validateSessionJobOnly(FlinkSessionJob sessionJob) {
    return firstPresent(
            // 1. 部署名称验证：检查deploymentName是否有效
            validateDeploymentName(sessionJob.getSpec().getDeploymentName()),
            
            // 2. 作业配置验证：检查job配置是否为空
            validateJobNotEmpty(sessionJob),
            
            // 3. 规格变更验证：检查规格变更的有效性
            validateSpecChange(sessionJob));
}
```

第二层负责集群兼容性验证（validateSessionJobWithCluster）

```java
private Optional<String> validateSessionJobWithCluster(
        FlinkSessionJob sessionJob, FlinkDeployment sessionCluster) {
    
    // 1. 构建有效配置：合并默认配置、会话集群配置、会话作业配置
    Map<String, String> effectiveConfig =
            configManager.getDefaultConfig(
                    sessionJob.getMetadata().getNamespace(),
                    sessionCluster.getSpec().getFlinkVersion()).toMap();
                    
    // 合并会话集群的Flink配置
    if (sessionCluster.getSpec().getFlinkConfiguration() != null) {
        effectiveConfig.putAll(sessionCluster.getSpec().getFlinkConfiguration());
    }
    
    // 合并会话作业的Flink配置（优先级最高）
    if (sessionJob.getSpec().getFlinkConfiguration() != null) {
        effectiveConfig.putAll(sessionJob.getSpec().getFlinkConfiguration());
    }
    
    // 2. 执行多项兼容性检查
    return firstPresent(
            // 确保目标不是应用模式集群
            validateNotApplicationCluster(sessionCluster),
            
            // 验证会话集群ID的一致性
            validateSessionClusterId(sessionJob, sessionCluster),
            
            // 验证作业规格与合并后配置的兼容性
            validateJobSpec(sessionJob.getSpec().getJob(), null, effectiveConfig),
            
            // 验证自动伸缩配置
            validateAutoScalerFlinkConfiguration(effectiveConfig));
}
```

### 5.3.5 调谐部署阶段

FlinkSessionJob 的调谐部署阶段是整个 reconcile 流程的核心，负责实际的作业生命周期管理。与 FlinkDeployment 不同，FlinkSessionJob 不需要管理集群部署，而是专注于作业的提交、更新和管理。

在 reconcile 方法中，调谐部署阶段的代码实现如下：

```java
@Override
public UpdateControl<FlinkSessionJob> reconcile(FlinkSessionJob flinkSessionJob, Context josdkContext) {
    // ... 前面的观察、验证阶段代码 ...
    
    try {
        // 更新缓存中的状态（保存观察和验证阶段的修改）
        statusRecorder.patchAndCacheStatus(flinkSessionJob, ctx.getKubernetesClient());
        
        // 调谐阶段：执行实际的作业生命周期管理
        reconciler.reconcile(ctx);
        
    } catch (Exception e) {
        // ... 异常处理 ...
    }
    
    // 最终状态更新并返回控制指令
    statusRecorder.patchAndCacheStatus(flinkSessionJob, ctx.getKubernetesClient());
    return ReconciliationUtils.toUpdateControl(
            ctx.getOperatorConfig(), flinkSessionJob, previousJob, true);
}
```

与 FlinkDeployment 不同，FlinkSessionJob 使用单一的 SessionJobReconciler 实例作为调谐器，无需工厂模式。SessionJobReconciler 继承自 AbstractJobReconciler，复用了 AbstractFlinkResourceReconciler 的模板方法模式，包含了准备就绪、部署流程、伸缩处理、变更处理、其他协调等5个步骤。而我们仍旧是按照 5.2.5 章节的方式，将5个步骤分为两个阶段：集群调谐阶段和业务调谐阶段。

#### 集群调谐阶段

集群调谐阶段的第一个步骤是准备就绪检查，检查会话集群是否准备就绪。SessionJobReconciler 重写了 readyToReconcile 方法，增加了会话作业特有的就绪检查：

```java
@Override
public boolean readyToReconcile(FlinkResourceContext<FlinkSessionJob> ctx) {
    // 1. 检查会话集群是否准备就绪
    return sessionClusterReady(
                    ctx.getJosdkContext().getSecondaryResource(FlinkDeployment.class))
            // 2. 调用父类的基础就绪检查（是否首次部署、是否需要等待保存点等）
            && super.readyToReconcile(ctx);
}
```

其中 `sessionClusterReady` 方法专门检查目标会话集群的状态：

```java
public static boolean sessionClusterReady(Optional<FlinkDeployment> flinkDeploymentOpt) {
    if (flinkDeploymentOpt.isPresent()) {
        var flinkdep = flinkDeploymentOpt.get();
        var jobmanagerDeploymentStatus = flinkdep.getStatus().getJobManagerDeploymentStatus();
        
        // 只有当会话集群的JobManager处于READY状态时，才能提交作业
        if (jobmanagerDeploymentStatus != JobManagerDeploymentStatus.READY) {
            LOG.info("Session cluster deployment is in {} status, not ready for serve",
                    jobmanagerDeploymentStatus);
            return false;
        } else {
            return true;
        }
    } else {
        LOG.warn("Session cluster deployment is not found");
        return false;
    }
}
```

这个检查确保了作业只有在目标会话集群完全就绪后才会进行调谐，避免了向未就绪集群提交作业的问题。

集群调谐阶段的第二个步骤是部署流程，SessionJobReconciler 的 deploy 方法专门处理作业提交逻辑，相比 FlinkDeployment 的集群部署简化了很多：

```java
@Override
public void deploy(
        FlinkResourceContext<FlinkSessionJob> ctx,
        FlinkSessionJobSpec sessionJobSpec,
        Configuration deployConfig,
        Optional<String> savepoint,
        boolean requireHaMetadata)
        throws Exception {

    // 1. 触发作业提交事件记录
    eventRecorder.triggerEvent(
            ctx.getResource(),
            EventRecorder.Type.Normal,
            EventRecorder.Reason.Submit,
            EventRecorder.Component.Job,
            MSG_SUBMIT,
            ctx.getKubernetesClient());

    // 2. 生成作业ID并记录到状态中以确保持久性
    // 这确保了作业ID在部署过程中的一致性和可追踪性
    var jobId = JobID.generate();
    ctx.getResource().getStatus().getJobStatus().setJobId(jobId.toHexString());
    statusRecorder.patchAndCacheStatus(ctx.getResource(), ctx.getKubernetesClient());

    // 3. 通过FlinkService提交作业到会话集群
    // 这是核心的作业提交操作，将作业jar和配置提交到现有的会话集群
    ctx.getFlinkService()
            .submitJobToSessionCluster(
                    ctx.getResource().getMetadata(),
                    sessionJobSpec,
                    jobId,
                    deployConfig,
                    savepoint.orElse(null));

    // 4. 设置作业状态为协调中
    // 表示作业已提交，正在等待Flink集群处理
    var status = ctx.getResource().getStatus();
    status.getJobStatus().setState(org.apache.flink.api.common.JobStatus.RECONCILING);
}
```

部署逻辑相对简单，只是依赖 FlinkService 调用其 submitJobToSessionCluster 方法，通过 REST API 来将作业提交到会话集群。

#### 业务调谐阶段

业务调谐阶段的第一个步骤是规格变更处理，由于 SessionJobReconciler 继承了 AbstractJobReconciler 抽象类，因此 FlinkSessionJob 的规格变更处理逻辑与 5.2.5 章节中业务调谐阶段提到的 AbstractJobReconciler 实现的抽象方法 reconcileSpecChange 的逻辑是一致的。读者可以翻到 5.2.5 章节回顾。

不同的是，SessionJobReconciler 实现了专门的作业取消逻辑：

```java
@Override
protected boolean cancelJob(FlinkResourceContext<FlinkSessionJob> ctx, SuspendMode suspendMode)
        throws Exception {
    // 1. 调用FlinkService取消会话作业
    var result =
            ctx.getFlinkService()
                    .cancelSessionJob(ctx.getResource(), suspendMode, ctx.getObserveConfig());
    
    // 2. 如果取消时创建了保存点，则记录保存点路径用于后续升级
    result.getSavepointPath().ifPresent(location -> setUpgradeSavepointPath(ctx, location));
    
    // 3. 返回是否还有待处理的取消操作
    return result.isPending();
}
```

业务调谐阶段的第二个步骤是其他规格变更处理，由于 SessionJobReconciler 继承了 AbstractJobReconciler 抽象类，因此 FlinkSessionJob 的其他规格变更处理逻辑与 5.2.5 章节中业务调谐阶段提到的 AbstractJobReconciler 实现的抽象方法 reconcileOtherChanges 的逻辑是一致的。

不同的是，SessionJobReconciler 将 cleanupAfterFailedJob 方法实现为一个空方法：

```java
@Override
protected void cleanupAfterFailedJob(FlinkResourceContext<FlinkSessionJob> ctx) {
    // 对于会话作业，失败的作业已经停止，无需额外清理
    // 这与Application模式不同，Application模式失败时需要清理整个集群
}
```

原因是，作业已经是失败状态时，对应于 FlinkSessionJob 的资源调谐过程里不需要再清理集群部署了。


### 5.3.6 资源清理阶段

在资源清理阶段，FlinkSessionJobController 实现了 Java Operator SDK 的 Cleaner 接口，其 cleanup 方法的实现如下：

```java
@Override
public DeleteControl cleanup(FlinkSessionJob sessionJob, Context josdkContext) {
    if (canaryResourceManager.handleCanaryResourceDeletion(sessionJob)) {
        return DeleteControl.defaultDelete();
    }
    eventRecorder.triggerEvent(
            sessionJob,
            EventRecorder.Type.Normal,
            EventRecorder.Reason.Cleanup,
            EventRecorder.Component.Operator,
            "Cleaning up FlinkSessionJob",
            josdkContext.getClient());
    var ctx = ctxFactory.getResourceContext(sessionJob, josdkContext);
    try {
        observer.observe(ctx);
    } catch (Exception err) {
        LOG.error("Error while observing for cleanup", err);
    }

    var deleteControl = reconciler.cleanup(ctx);
    if (deleteControl.isRemoveFinalizer()) {
        ctxFactory.cleanup(sessionJob);
        statusRecorder.removeCachedStatus(sessionJob);
    } else {
        statusRecorder.patchAndCacheStatus(sessionJob, ctx.getKubernetesClient());
    }
    return deleteControl;
}
```

我们能看到这个函数的主要逻辑中会先进行金丝雀资源的判断，然后也会进行观察和调谐，调谐的时候调用的是 cleanup 这个方法。接着，我们主要看一下这个方法的实现，代码如下：

```java
@Override
public DeleteControl cleanup(FlinkResourceContext<CR> ctx) {
    autoscaler.cleanup(ResourceID.fromResource(ctx.getResource()));
    return cleanupInternal(ctx);
}
```

我们先忽略 autoscaler 的逻辑，

当删除 FlinkSessionJob 资源时，SessionJobReconciler 的 cleanupInternal 方法负责清理作业：

```java
@Override
public DeleteControl cleanupInternal(FlinkResourceContext<FlinkSessionJob> ctx) {
    var status = ctx.getResource().getStatus();
    long delay = ctx.getOperatorConfig().getProgressCheckInterval().toMillis();
    
    // 1. 如果作业未部署或已终止，直接删除
    if (status.getReconciliationStatus().isBeforeFirstDeployment()
            || ReconciliationUtils.isJobInTerminalState(status)
            || status.getReconciliationStatus()
                            .deserializeLastReconciledSpec()
                            .getJob()
                            .getState()
                    == JobState.SUSPENDED
            || JobStatusObserver.JOB_NOT_FOUND_ERR.equals(status.getError())) {
        return DeleteControl.defaultDelete();
    }

    // 2. 如果作业正在取消中，等待取消完成
    if (ReconciliationUtils.isJobCancelling(status)) {
        LOG.info("Waiting for pending cancellation");
        return DeleteControl.noFinalizerRemoval().rescheduleAfter(delay);
    }

    // 3. 获取目标会话集群并取消作业
    Optional<FlinkDeployment> flinkDepOptional =
            ctx.getJosdkContext().getSecondaryResource(FlinkDeployment.class);

    if (flinkDepOptional.isPresent()) {
        String jobID = ctx.getResource().getStatus().getJobStatus().getJobId();
        if (jobID != null) {
            try {
                // 根据配置决定是否创建保存点
                var observeConfig = ctx.getObserveConfig();
                var suspendMode =
                        observeConfig.getBoolean(
                                        KubernetesOperatorConfigOptions.SAVEPOINT_ON_DELETION)
                                ? SuspendMode.SAVEPOINT
                                : SuspendMode.STATELESS;
                                
                // 取消作业
                if (cancelJob(ctx, suspendMode)) {
                    LOG.info("Waiting for pending cancellation");
                    return DeleteControl.noFinalizerRemoval().rescheduleAfter(delay);
                }
            } catch (Exception e) {
                LOG.error("Failed to cancel job, will reschedule after {} milliseconds.",
                        delay, e);
                return DeleteControl.noFinalizerRemoval().rescheduleAfter(delay);
            }
        }
    } else {
        LOG.info("Session cluster deployment not available");
    }
    return DeleteControl.defaultDelete();
}
```

而当清理 FlinkSessionJob 资源时，则不会清理集群部署，因为 FlinkSessionJob 资源不会管理集群部署。但是当其所提交集群对应的 FlinkDeployment 资源需要清理时，会查看其所提交的 FlinkSessionJob 资源是否还有其他的作业，如果有，则会报错，等待下次清理触发时，再进行清理。如果没有，则会先停止作业，然后删除集群，并同时删除元数据。这里我们可以看下代码：

```java
@Override
public DeleteControl cleanupInternal(FlinkResourceContext<FlinkDeployment> ctx) {
    // 获取当前会话集群关联的所有FlinkSessionJob资源
    // getSecondaryResources方法会返回与当前FlinkDeployment关联的所有FlinkSessionJob
    Set<FlinkSessionJob> sessionJobs =
            ctx.getJosdkContext().getSecondaryResources(FlinkSessionJob.class);
    var deployment = ctx.getResource();
    
    // 检查是否还有未删除的会话作业
    if (!sessionJobs.isEmpty()) {
        // 如果还有会话作业存在，不能删除会话集群
        // 构造错误信息，列出所有需要先删除的会话作业名称
        var error =
                String.format(
                        "The session jobs %s should be deleted first",
                        sessionJobs.stream()
                                .map(job -> job.getMetadata().getName())
                                .collect(Collectors.toList()));
        
        // 触发Kubernetes事件，记录清理失败的原因
        // triggerEvent方法会创建一个Warning类型的事件，记录清理失败的原因
        if (eventRecorder.triggerEvent(
                deployment,
                EventRecorder.Type.Warning,
                EventRecorder.Reason.CleanupFailed,
                EventRecorder.Component.Operator,
                error,
                ctx.getKubernetesClient())) {
            LOG.warn(error);
        }
        
        // 返回不删除finalizer的控制，并安排重新调度
        // noFinalizerRemoval(): 不删除finalizer，保持资源不被完全删除
        // rescheduleAfter(): 在指定时间后重新调度清理操作
        return DeleteControl.noFinalizerRemoval()
                .rescheduleAfter(ctx.getOperatorConfig().getReconcileInterval().toMillis());
    } else {
        // 如果没有会话作业，可以安全地停止会话集群
        LOG.info("Stopping session cluster");
        var conf = ctx.getDeployConfig(ctx.getResource().getSpec());
        
        // 删除集群部署
        // deleteClusterDeployment方法会：
        // 1. 删除Kubernetes中的JobManager和TaskManager部署
        // 2. 删除高可用元数据（第三个参数为true）
        // 3. 更新部署状态
        ctx.getFlinkService()
                .deleteClusterDeployment(
                        deployment.getMetadata(), deployment.getStatus(), conf, true);
        
        // 返回默认删除控制，表示可以安全删除资源
        return DeleteControl.defaultDelete();
    }
}
```

从代码中就能够看出，清理 FlinkDeployment 的 Session 模式的资源时，只要还有作业存在，就不会删除集群。








