---
title: "FlinkOperator 源码分析"
date: 2025-01-24T23:43:48+08:00
draft: false
description: "深入剖析FlinkOperator的启动流程，从核心变量到插件机制的完整实现"
---

## 4.1 FlinkOperator 启动流程

从第一章节的 Debug 流程中我们已知，Flink Operator 容器启动脚本中对应的启动类是 `org.apache.flink.kubernetes.operator.FlinkOperator`

FlinkOperator 的启动流程从标准的 `main` 函数开始:

```java
// FlinkOperator主类入口
public class FlinkOperator {
    
    public static void main(String... args) {
        // 记录环境信息和启动参数
        EnvUtils.logEnvironmentInfo(LOG, "Flink Kubernetes Operator", args);
        
        // 创建并启动FlinkOperator实例
        new FlinkOperator(null).run();
    }
    
    // 实际运行逻辑
    public void run() {
        // 注册所有控制器
        registerDeploymentController();
        registerSessionJobController();
        registerSnapshotController();
        
        // 安装关闭钩子
        operator.installShutdownHook(
            baseConfig.get(KubernetesOperatorConfigOptions.OPERATOR_TERMINATION_TIMEOUT));
        
        // 启动operator
        operator.start();
        
        // 启动健康服务
        if (operatorHealthService != null) {
            HealthProbe.INSTANCE.setRuntimeInfo(operator.getRuntimeInfo());
            Runtime.getRuntime().addShutdownHook(new Thread(operatorHealthService::stop));
            operatorHealthService.start();
        }
    }
}
```

整个启动流程的时序图如下：

{{< mermaid >}}
sequenceDiagram
    participant K8s as Kubernetes
    participant Pod as Pod Container
    participant JVM as JVM
    participant Main as FlinkOperator
    participant Components as 核心组件
    participant Controllers as 控制器
    participant K8sAPI as K8s API Server

    Note over K8s, K8sAPI: 1. 容器启动阶段
    K8s->>Pod: 创建Pod
    Pod->>JVM: 启动JVM进程
    
    Note over JVM, Main: 2. JVM启动阶段
    JVM->>Main: 调用main()方法
    Main->>Main: 记录环境信息
    
    Note over Main, Components: 3. 组件初始化阶段
    Main->>Components: 初始化11个核心组件
    Components-->>Main: 组件初始化完成
    
    Note over Main, Controllers: 4. 控制器注册阶段
    Main->>Controllers: 注册3个控制器
    Controllers-->>Main: 控制器注册完成
    
    Note over Main, K8sAPI: 5. 事件循环阶段
    Main->>K8sAPI: 建立事件监听
    K8sAPI-->>Main: 返回事件流
    Main->>Main: 进入事件循环
    
    Note over Main: 6. 健康服务阶段
    Main->>Main: 启动健康检查端点
    
    Note over JVM, Main: 7. 优雅关闭阶段
    JVM->>Main: 收到SIGTERM信号
    Main->>Main: 停止所有组件
    Main-->>JVM: 关闭完成
{{< /mermaid >}}

核心的启动流程包括：
1. **容器启动**：Kubernetes 创建 Pod，执行 docker-entrypoint 脚本
2. **JVM启动**：执行 main() 方法
3. **组件初始化**：按依赖顺序初始化11个核心成员变量
4. **控制器注册**：注册Deployment、SessionJob、Snapshot三个控制器
5. **事件循环**：启动 Operator 并启动事件循环
6. **健康服务**：启动HTTP健康检查端点
7. **优雅关闭**：通过JVM关闭钩子处理SIGTERM信号

#### 4.1.1 核心成员变量深度解析

FlinkOperator 作为入口类，其成员变量的设计体现了"配置驱动、插件扩展、事件统一"的架构理念。 FlinkOperator 的成员变量的代码如下：

```java
public class FlinkOperator {
    private final Operator operator;                                    // JOSDK核心控制器
    private final KubernetesClient client;                              // K8s API客户端
    private final FlinkResourceContextFactory ctxFactory;               // 资源上下文工厂
    private final FlinkConfigManager configManager;                     // 配置管理器
    private final Set<FlinkResourceValidator> validators;               // 验证器集合
    @VisibleForTesting final Set<RegisteredController<?>> registeredControllers; // 注册的控制器
    private final KubernetesOperatorMetricGroup metricGroup;            // 指标收集组
    private final Collection<FlinkResourceListener> listeners;          // 事件监听器集合
    private final OperatorHealthService operatorHealthService;          // 健康检查服务
    private final EventRecorder eventRecorder;                          // 事件记录器
    private final Configuration baseConfig;                             // 基础配置快照
}
```
其中对应的变量解析如下：

| 变量名 | 类型 | 核心作用 | 依赖关系 |
|--------|------|----------|----------|
| `configManager` | `FlinkConfigManager` | 配置管理器，支持动态配置更新和命名空间级别隔离 | 无依赖，其他组件的基础 |
| `baseConfig` | `Configuration` | 基础配置快照，组件配置基线 | 依赖configManager |
| `metricGroup` | `KubernetesOperatorMetricGroup` | 指标收集组，提供细粒度监控数据 | 依赖baseConfig |
| `client` | `KubernetesClient` | Fabric8客户端，负责与K8s API Server的所有交互 | 依赖configManager, metricGroup |
| `operator` | `Operator` | JOSDK核心控制器，管理Kubernetes调谐循环 | 依赖client, configManager |
| `validators` | `Set<FlinkResourceValidator>` | 插件化验证器集合，支持自定义验证逻辑 | 依赖configManager |
| `listeners` | `Collection<FlinkResourceListener>` | 事件监听器集合，实现观察者模式 | 依赖configManager |
| `eventRecorder` | `EventRecorder` | 统一事件管理器，智能去重机制 | 依赖client, listeners |
| `ctxFactory` | `FlinkResourceContextFactory` | 资源上下文工厂，为不同资源类型创建专用处理上下文 | 依赖configManager, metricGroup, eventRecorder |
| `registeredControllers` | `Set<RegisteredController<?>>` | 注册的控制器集合，支持运行时动态调整监听命名空间 | 依赖operator, ctxFactory |
| `operatorHealthService` | `OperatorHealthService` | 健康检查服务，提供HTTP端点 | 依赖configManager |

我们将在这一章节重点解析 FlinkConfigManager 、KubernetesOperatorMetricGroup、 OperatorHealthService 以及插件注册机制。 FlinkResourceContextFactory 和 RegisteredController 将在下一章节重点展开。

#### 4.1.2 Operator 创建

成员变量 operator 的创建过程比较简单，需要注意的是 Java Operator SDK 的 Operator 类也有一些配置项，这里代码通过 overrideOperatorConfigs() 方法来覆盖默认的配置。代码如下：

```java
@VisibleForTesting
protected Operator createOperator() {
    return new Operator(this::overrideOperatorConfigs);
}

private void overrideOperatorConfigs(ConfigurationServiceOverrider overrider) {
    overrider.withKubernetesClient(client);
    
    var conf = configManager.getDefaultConfig();
    var operatorConf = FlinkOperatorConfiguration.fromConfiguration(conf);
    
    // 配置并发度
    int parallelism = operatorConf.getReconcilerMaxParallelism();
    if (parallelism == -1) {
        LOG.info("Configuring operator with unbounded reconciliation thread pool.");
        overrider.withExecutorService(Executors.newCachedThreadPool());
    } else {
        LOG.info("Configuring operator with {} reconciliation threads.", parallelism);
        overrider.withConcurrentReconciliationThreads(parallelism);
    }
    
    // 配置指标
    if (operatorConf.isJosdkMetricsEnabled()) {
        overrider.withMetrics(new OperatorJosdkMetrics(metricGroup, configManager));
    }
    
    // 配置终止超时
    overrider.withTerminationTimeoutSeconds(
        (int) conf.get(KubernetesOperatorConfigOptions.OPERATOR_TERMINATION_TIMEOUT).toSeconds());
    
    // 配置启动错误处理
    overrider.withStopOnInformerErrorDuringStartup(
        conf.get(KubernetesOperatorConfigOptions.OPERATOR_STOP_ON_INFORMER_ERROR));
    
    // 配置领导者选举
    var leaderElectionConf = operatorConf.getLeaderElectionConfiguration();
    if (leaderElectionConf != null) {
        overrider.withLeaderElectionConfiguration(leaderElectionConf);
        LOG.info("Operator leader election is enabled.");
    } else {
        LOG.info("Operator leader election is disabled.");
    }
}
```

Flink Operator 支持能覆盖的 Operator 配置在[官方文档-系统配置](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-release-1.12/docs/operations/configuration/#system-configuration)中列出。这些系统配置包含了 Operator 本身以及 Controller 的配置。

需要注意的是，上述代码涉及的时初始化 Operator 时生效的配置，是无法进行热加载的。

另外，在注册 Controllers 时还有一个配置覆盖方法，也是对应这些系统配置，代码如下：

```java
private void overrideControllerConfigs(ControllerConfigurationOverrider<?> overrider) {
    // 获取 Operator 相关系统配置
    var operatorConf = configManager.getOperatorConfiguration();
    // 获取命名空间设置
    var watchNamespaces = operatorConf.getWatchedNamespaces();
    LOG.info("Configuring operator to watch the following namespaces: {}.", watchNamespaces);
    overrider.settingNamespaces(operatorConf.getWatchedNamespaces());

    // 获取重试配置
    overrider.withRetry(operatorConf.getRetryConfiguration());
    // 获取 RateLimiter 配置
    overrider.withRateLimiter(operatorConf.getRateLimiter());

    // 获取 label selector 配置
    var labelSelector = operatorConf.getLabelSelector();
    LOG.info(
            "Configuring operator to select custom resources with the {} labels.",
            labelSelector);
    overrider.withLabelSelector(labelSelector);
}
```
这些配置也是同样仅在注册时生效，无法进行热加载。


## 4.2 FlinkConfigManager 配置管理

我们需要深入理解其中最重要的组件之一 —— FlinkConfigManager。配置管理是任何分布式系统的核心，FlinkOperator 通过 FlinkConfigManager 实现了灵活、高效的配置管理机制。

### 4.2.1 配置加载架构

```java
public class FlinkConfigManager {
    private static final Logger LOG = LoggerFactory.getLogger(FlinkConfigManager.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    // 默认配置
    private volatile Configuration defaultConfig;
    // flink operator 配置
    private volatile FlinkOperatorConfiguration defaultOperatorConfiguration;
    // 是否安装 snapshot 的 crd
    private final boolean snapshotCrdInstalled;
    // 配置版本
    private final AtomicLong defaultConfigVersion = new AtomicLong(0);
    // 配置缓存
    private final LoadingCache<Key, Configuration> cache;
    // Namespace 的 监听函数
    private final Consumer<Set<String>> namespaceListener;
}

@Value
@Builder
private static class Key { // Guava Cache 的键
    // config 版本
    long configVersion;
    // 具体 CR 部署的 namespace
    String namespace;
    // 具体 CR 的名称
    String name;
    // 具体 CR 的 spec
    ObjectNode spec;
}
```

从 FlinkConfigManager 成员变量中可以看出，主要管理的是：
- defaultConfig: Operator 配置内容和对应版本号（defaultConfigVersion）
- cache：Flink 集群实例配置内容和对应版本（Key.configVersion)

### 4.2.2 Operator 配置覆盖机制

FlinkOperator 的配置加载以 `CONF_OVERRIDE_DIR` 容器实例的环境变量为配置文件路径，通过 `loadGlobalConfiguration()` 方法实现配置覆盖。

`CONF_OVERRIDE_DIR` 是 FlinkOperator 的核心配置环境变量，用于指定配置 Yaml 文件的目录。配置加载逻辑如下：

```java
private static Configuration loadGlobalConfiguration() {
    // 加载指定目录下的 flink-conf.yaml 或者是 conf.yaml
    return loadGlobalConfiguration(EnvUtils.get(EnvUtils.ENV_CONF_OVERRIDE_DIR));
}

protected static Configuration loadGlobalConfiguration(Optional<String> confOverrideDir) {
    if (confOverrideDir.isPresent()) {
        // 加载 CONF_OVERRIDE_DIR 中的配置
        Configuration configOverrides = GlobalConfiguration.loadConfiguration(confOverrideDir.get());
        LOG.debug("Loading default configuration with overrides from {}", confOverrideDir.get());
        return GlobalConfiguration.loadConfiguration(configOverrides);
    }
    // 如果没有 CONF_OVERRIDE_DIR，则加载默认配置
    LOG.debug("Loading default configuration");
    return GlobalConfiguration.loadConfiguration();
}
```

配置覆盖流程如下：

1. 检查 `CONF_OVERRIDE_DIR` 环境变量是否存在
2. 如果存在，从指定目录加载配置文件
3. 将覆盖配置应用到全局配置
4. 如果不存在，直接加载 Flink 默认配置

### 4.2.3 FlinkDeployment 实例配置缓存机制

```java
public FlinkConfigManager(
            Configuration defaultConfig,
            Consumer<Set<String>> namespaceListener,
            boolean snapshotCrdInstalled) {
    // other logics

    // 配置缓存配置
    Duration cacheTimeout = baseConfig.get(OPERATOR_CONFIG_CACHE_TIMEOUT);
    int cacheSize = baseConfig.get(OPERATOR_CONFIG_CACHE_SIZE);

    this.cache = CacheBuilder.newBuilder()
        .expireAfterWrite(cacheTimeout.toMillis(), TimeUnit.MILLISECONDS)
        .maximumSize(cacheSize)
        .removalListener(
            removalNotification ->
                    FlinkConfigBuilder.cleanupTmpFiles(
                            (Configuration) removalNotification.getValue()))
        .build(new CacheLoader<Key, Configuration>() {
            @Override
            public Configuration load(Key k) {
                return generateConfig(k);
            }
        });
    
    // other logics
    ScheduledExecutorService executorService = Executors.newSingleThreadScheduledExecutor();
        executorService.scheduleWithFixedDelay(
                cache::cleanUp,
                cacheTimeout.toMillis(),
                cacheTimeout.toMillis(),
                TimeUnit.MILLISECONDS);
}
```
其中 cacheTimeout 默认是 10 分钟，cacheSize 默认是 1000。需要注意的是，这个单 Operator 容器实例的缓存上限。
CacheBuilder 对应的 removalListener 逻辑清理的是 podTemplate 对应映射生成的临时文件。当缓存没命中时，对应的生成配置的逻辑是 `generateConfig(k)`, 对应代码如下：

```java
private Configuration generateConfig(Key key) {
        try {
            LOG.debug("Generating new config");
            // 注意这里只有 FlinkDeploymentSpec 能够被缓存
            var spec = objectMapper.convertValue(key.spec, FlinkDeploymentSpec.class);
            return FlinkConfigBuilder.buildFrom(
                    key.namespace,
                    key.name,
                    spec,
                    getDefaultConfig(key.namespace, spec.getFlinkVersion()));
        } catch (Exception e) {
            throw new RuntimeException("Failed to load configuration", e);
        }
    }
```

主要注意的是只有 FlinkDeployment 支持配置缓存，FlinkSessionJob 不具备。另外整体的复杂逻辑包含在 `FlinkConfigBuilder.buildFrom`，对应代码流程图如下： 

{{< mermaid >}}
flowchart TD
    A[开始: buildFrom 方法] --> B[创建 FlinkConfigBuilder 实例<br/>namespace, clusterId, spec, flinkConfig]
    
    B --> C[配置模块: applyFlinkConfiguration<br/>• 解析 spec 中的 flinkConfiguration<br/>• 设置默认 REST 服务类型<br/>• 设置 web.cancel.enable<br/>• 设置 Flink 版本]
    
    C --> D[日志配置模块: applyLogConfiguration<br/>• 处理 log4j/logback 配置<br/>• 创建日志配置文件<br/>• 设置 CONF_DIR]
    
    D --> E[镜像配置模块: applyImage<br/>• 设置容器镜像<br/>• 根据 Flink 版本选择配置键]
    
    E --> F[镜像拉取策略模块: applyImagePullPolicy<br/>• 设置镜像拉取策略]
    
    F --> G[服务账户模块: applyServiceAccount<br/>• 设置 Kubernetes 服务账户]
    
    G --> H[Pod 模板模块: applyPodTemplate<br/>• 合并通用和特定 Pod 模板<br/>• 应用资源配置<br/>• 创建临时模板文件<br/>• 设置 JM/TM Pod 模板]
    
    H --> I[JobManager 规格模块: applyJobManagerSpec<br/>• 设置 JM 资源配置<br/>• 设置 JM 副本数]
    
    I --> J[TaskManager 规格模块: applyTaskManagerSpec<br/>• 设置 TM 资源配置<br/>• 设置 TM 副本数<br/>• 计算并行度]
    
    J --> K[作业/会话规格模块: applyJobOrSessionSpec<br/>• 设置部署目标<br/>• 处理 JAR URI<br/>• 应用作业配置<br/>• 处理独立模式]
    
    K --> L[构建最终配置: build<br/>• 设置集群配置<br/>• 设置命名空间和集群 ID<br/>• 设置高可用配置]
    
    L --> M[返回最终 Configuration]
    
    style A fill:#e1f5fe
    style M fill:#c8e6c9
    style C fill:#fff3e0
    style D fill:#f3e5f5
    style E fill:#e8f5e8
    style F fill:#fff8e1
    style G fill:#fce4ec
    style H fill:#e0f2f1
    style I fill:#f1f8e9
    style J fill:#fff3e0
    style K fill:#e3f2fd
    style L fill:#f9fbe7
{{< /mermaid >}}

从流程图中可知，缓存生成过程是比较复杂的，对于每一个 FlinkDeployment 都会缓存配置。

另外，代码中还创建了一个单线程池，每10分钟会清理所有缓存。

### 4.2.4 Operator 配置热加载机制

**配置监控任务**
```java
public FlinkConfigManager(
            Configuration defaultConfig,
            Consumer<Set<String>> namespaceListener,
            boolean snapshotCrdInstalled) {
        // logic of cache

        // executorService 对应 cache cleanup 的单线程池
        if (defaultConfig.getBoolean(OPERATOR_DYNAMIC_CONFIG_ENABLED)) {
            scheduleConfigWatcher(executorService);
        }
    }

private void scheduleConfigWatcher(ScheduledExecutorService executorService) {
        var checkInterval = defaultConfig.get(OPERATOR_DYNAMIC_CONFIG_CHECK_INTERVAL);
        var millis = checkInterval.toMillis();
        executorService.scheduleAtFixedRate(
                new ConfigUpdater(), millis, millis, TimeUnit.MILLISECONDS);
        LOG.info("Enabled dynamic config updates, checking config changes every {}", checkInterval);
}
```

**配置变更处理逻辑**
```java
private class ConfigUpdater implements Runnable {
    public void run() {
        try {
            LOG.debug("Checking for config update changes...");
            // 更新默认配置
            updateDefaultConfig(loadGlobalConfiguration());
        } catch (Exception e) {
            LOG.error("Error while updating operator configuration", e);
        }
    }
}
```
从代码中，对应 updateDefaultConfig 的代码流程图如下：
{{< mermaid >}}
flowchart TD
    A[开始: updateDefaultConfig] --> B{配置是否发生变化?}
    
    B -->|否| C[直接返回]
    
    B -->|是| D[处理 FlinkSnapshot 配置<br/>检查 CRD 安装状态]
    D --> E[更新命名空间配置<br/>触发 Controller 修改监听命名空间]
    E --> F[更新默认配置<br/>递增版本号]
    F --> G[更新完成]
    
    style A fill:#e1f5fe
    style C fill:#ffcdd2
    style G fill:#c8e6c9
    style B fill:#fff3e0
    style D fill:#f3e5f5
    style E fill:#e8f5e8
    style F fill:#2196f3
{{< /mermaid >}}



## 4.3 EventRecorder 事件记录

EventRecorder 是 Flink Operator 的关键组件，负责创建和分发 Java Operator SDK 提供的 EventSource 支持不了的业务事件。EventRecorder 通过 EventUtils 工具类实现了多级事件去重机制，避免了自定义 Event 过多导致 Kubernetes 集群的异常负载。实现的事件是为了让用户从进行审计和业务层面上的监控，同时作为 EventSource 的补充。

### 4.3.1 自定义事件组成部分

EventRecorder 自定义的事件的主要组成部分是 Type、Component、Reason，对应代码如下：

```java
public enum Type {
    Normal,     // 正常事件
    Warning     // 警告事件
}

public enum Component {
    Operator,               // Operator组件
    JobManagerDeployment,   // JobManager部署
    Job,                    // 作业
    Snapshot               // 快照
}

public enum Reason {
    Suspended,              // 暂停
    SpecChanged,            // 规格变更
    Rollback,               // 回滚
    Submit,                 // 提交
    JobStatusChanged,       // 作业状态变更
    SavepointError,         // Savepoint错误
    CheckpointError,        // Checkpoint错误
    Cleanup,                // 清理
    CleanupFailed,          // 清理失败
    Missing,                // 缺失
    ValidationError,        // 验证错误
    RecoverDeployment,      // 恢复部署
    RestartUnhealthyJob,    // 重启不健康作业
    ScalingReport,          // 扩缩容报告
    IneffectiveScaling,     // 无效扩缩容
    MemoryPressure,         // 内存压力
    ResourceQuotaReached,   // 资源配额达到
    AutoscalerError,        // 自动扩缩容错误
    Scaling,                // 扩缩容
    UnsupportedFlinkVersion, // 不支持的Flink版本
    SnapshotError,          // 快照错误
    SnapshotAbandoned       // 快照放弃
}
```

### 4.3.2 四级去重策略

EventRecorder 通过 EventUtils 工具类实现了多级事件去重机制, 事件去重一共有四重策略，流程图如下：

{{< mermaid >}}
flowchart TD
    Start([事件触发]) --> L1[L1: 事件名哈希去重]
    L1 --> L2[L2: 事件窗口去重]
    L2 --> L3[L3: 标签去重]
    L3 --> L4[L4: 存在即替换]
    
    L1 -->|重复| Skip[跳过事件]
    L2 -->|重复| Skip
    L3 -->|无变化| Skip
    L4 -->|一次性| Create[创建事件]
    L4 -->|可重复| Update[更新事件]
    
    Skip --> Done([完成])
    Create --> Done
    Update --> Done

    style Start fill:#E1F5FE
    style L1 fill:#FFF3E0
    style L2 fill:#F3E5F5
    style L3 fill:#E8F5E8
    style L4 fill:#FFEBEE
    style Done fill:#C8E6C9
    style Skip fill:#FFCDD2
    style Create fill:#98FB98
    style Update fill:#87CEEB
{{< /mermaid >}}

其中，对应的代码如下：
```java
  // L1: 事件签名机制
  String eventName = EventUtils.generateEventName(
      target, type, reason, message, component);

  // L2: 时间窗口去重
  EventUtils.intervalCheck(Event existing, @Nullable Duration interval);

  // L3: 标签比较
  EventUtils.labelCheck(
            Event existing, Predicate<Map<String, String>> dedupePredicate)

  // L4: 一次性事件保护
  EventUtils.createOrReplaceEvent(KubernetesClient client, Event event)
```


### 4.3.3 事件监听器机制

```java
public static EventRecorder create(
        KubernetesClient client, Collection<FlinkResourceListener> listeners) {

    BiConsumer<AbstractFlinkResource<?, ?>, Event> biConsumerFlinkResource =
                (resource, event) -> {
                    var ctx = ... // create context;
                    listeners.forEach(
                            listener -> {
                                if (resource instanceof FlinkDeployment) {
                                    listener.onDeploymentEvent(ctx);
                                } else {
                                    listener.onSessionJobEvent(ctx);
                                }
                            });
                    AuditUtils.logContext(ctx);
                };

        BiConsumer<FlinkStateSnapshot, Event> biConsumerFlinkStateSnapshot =
                (resource, event) -> {
                    var ctx = .. // create context ;
                    listeners.forEach(listener -> listener.onStateSnapshotEvent(ctx));
                    AuditUtils.logContext(ctx);
                };
    
    return new EventRecorder(eventListenerFlinkResource, eventListenerFlinkStateSnapshot);
}
```
创建 EventRecorder 的过程，事实上是一个构建 context 和设置事件监听的过程。这里的 listeners 是 FlinkOperator 的事件监听插件，AuditUtils做的是日记输出的操作，用于潜在的日记审计实现。我们接下来将介绍 FlinkOperator 的三种插件机制。 

## 4.4 插件化架构（SPI机制）

为了支持扩展性和定制化需求，FlinkOperator 采用了插件化架构设计。通过Java的SPI（Service Provider Interface）机制，系统可以在运行时动态发现和加载扩展组件，如验证器、监听器等。

### 4.4.1 SPI机制原理

SPI（Service Provider Interface）是Java提供的一种服务发现机制，允许在运行时动态加载实现类。

**SPI工作流程：**
1. **定义接口**：定义服务接口
2. **实现类**：提供接口的具体实现
3. **配置文件**：在`META-INF/services/`目录下创建配置文件
4. **插件加载**：通过`ServiceLoader`加载实现类

### 4.4.2 插件发现机制

Flink Operator 提供两种扩展插件，validators 和 listeners，validators 用来校验资源的值，而 listeners 用来监听事件并进行处理。

```java
public FlinkOperator(@Nullable Configuration conf) {
        this.configManager =
                conf != null
                        ? new FlinkConfigManager(conf) // For testing only
                        : new FlinkConfigManager(
                                this::handleNamespaceChanges,
                                KubernetesClientUtils.isCrdInstalled(FlinkStateSnapshot.class));
        // ... other logic
        this.validators = ValidatorUtils.discoverValidators(configManager);
        this.listeners = ListenerUtils.discoverListeners(configManager);
        // ... other logic
    }
```

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

除了 validators 插件，listeners 的插件发现机制也是一样的，对应时序图如下：

{{< mermaid >}}
sequenceDiagram
  participant discoverListeners
  participant PluginUtils as PluginUtils
  participant PluginManager as PluginManager
  participant ServiceLoader as ServiceLoader
  participant Listener as FlinkResourceListener

  discoverListeners ->> PluginUtils: createPluginManagerFromRootFolder(conf)
  PluginUtils ->> PluginManager: new PluginManager(rootFolder)
  PluginManager -->> PluginUtils: pluginManager
  PluginUtils -->> discoverListeners: pluginManager
  discoverListeners ->> PluginManager: load(FlinkResourceListener.class)
  PluginManager ->> ServiceLoader: ServiceLoader.load(FlinkResourceListener.class)
  ServiceLoader ->> ServiceLoader: 扫描META-INF/services/目录
  ServiceLoader ->> ServiceLoader: 发现FlinkResourceListener实现类
  ServiceLoader -->> PluginManager: ServiceLoader迭代器
  PluginManager ->> Listener: 实例化实现类
  Listener -->> PluginManager: listener实例
  PluginManager ->> Listener: getClass().getName()
  Listener -->> PluginManager: 类名字符串

  PluginManager -->> discoverListeners: 返回listeners集合
{{< /mermaid >}}

可以从时序图中发现，整体 discoverListeners 插件的发现流程是一样的，核心类是 `PluginUtils`，这里比较复杂的是，需要从 `PluginUtils` 到 `ServiceLoader`的流程是比较长的。


### 4.4.3 自定义插件代码实例

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

笔者这里也写了一个 CustomResourceListener 供读者进行参考，代码如下：

``` java
// Listener 例子
public class CustomResourceListener implements FlinkResourceListener {

    @Override
    public void onDeploymentStatusUpdate(StatusUpdateContext<FlinkDeployment, FlinkDeploymentStatus> statusUpdateContext) {
        LOG.info("==============step into custom resource listener onDeploymentStatusUpdate.....===========");
        LOG.info(statusUpdateContext.getNewStatus().toString());
        LOG.info(statusUpdateContext.getPreviousStatus().toString());
        LOG.info(statusUpdateContext.getFlinkResource().toString());
        LOG.info("==============step out custom resource listener onDeploymentStatusUpdate.....===========");
    }

    @Override
    public void onDeploymentEvent(ResourceEventContext<FlinkDeployment> resourceEventContext) {
        LOG.info("==============step into custom resource listener onDeploymentEvent.....===========");
        if ("Submit".equals(resourceEventContext.getEvent().getReason()) &&
                "Starting deployment".equals(resourceEventContext.getEvent().getMessage())) {
            LOG.info("Job Manager的单Pod重启");
            LOG.info("准备开始修改Flink Conf Configmap");
        }
        LOG.info("==============step out custom resource listener onDeploymentEvent.....===========");
    }

    @Override
    public void onSessionJobStatusUpdate(StatusUpdateContext<FlinkSessionJob, FlinkSessionJobStatus> statusUpdateContext) {
        // ...
    }

    @Override
    public void onSessionJobEvent(ResourceEventContext<FlinkSessionJob> resourceEventContext) {
        // ...
    }
}
```

读者只需要对应实现接口及其方法，并按照 SPI 的方式进行打包，并将 jar 包放入对应镜像中的位置即可。

## 4.5 Controllers 注册机制

FlinkOperator v1.10 支持三种 Controllers，分别是：
- FlinkDeploymentController
- FlinkSessionJobController
- FlinkStateSnapshotController

在 FlinkOperator 的 run() 方法中进行 Controller 的注册，代码如下：

```java
public void run() {
        registerDeploymentController();
        registerSessionJobController();
        registerSnapshotController();
        // ... other logics
    }
```

而在每一个注册 Controllers 的关键代码中都会调用 `operator.register(controller, this::overrideControllerConfigs)` 这个方法。

我们在前面 4.1.1.3 Operator 创建章节有提到，在注册 Controllers 时对应的 overrideControllerConfigs 方法对应系统配置。

## 4.6 健康探针和优雅关闭

### 4.6.1 健康探针

健康探针指的是 Kubernetes 中的 livenessProbe 和 startupProbe，要这两个探针生效，需要在 Helm Chart 的 values.yaml 中增加如下内容：

```yaml
operatorHealth:
  port: 8085
  livenessProbe:
    periodSeconds: 10
    initialDelaySeconds: 30
  startupProbe:
    failureThreshold: 30
    periodSeconds: 10
```

配置完成之后，还需要在 Operator 的配置文件中加上以下内容：

```yaml
kubernetes.operator.health.probe.enabled = true
# 上述的端口 8085 也是能够修改的
# kubernetes.operator.health.probe.port = 8085
```

我们看一下代码是如何实现这个功能的。功能对应 FlinkOperator 的成员变量 operatorHealthService，对应代码如下：

```java
// FlinkOperator.java
public FlinkOperator(@Nullable Configuration conf) {
    this.configManager =
            conf != null
                    ? new FlinkConfigManager(conf) // For testing only
                    : new FlinkConfigManager(
                            this::handleNamespaceChanges,
                            KubernetesClientUtils.isCrdInstalled(FlinkStateSnapshot.class));

    // ... other members
    this.operatorHealthService = OperatorHealthService.fromConfig(configManager);
}

public void run() {
    // ... other logics
    if (operatorHealthService != null) {
        HealthProbe.INSTANCE.setRuntimeInfo(operator.getRuntimeInfo());
        Runtime.getRuntime().addShutdownHook(new Thread(operatorHealthService::stop));
        operatorHealthService.start();
    }
}
```

当 FlinkOperator 终止时，由于 JVM 钩子的设计，也会一并调用 `operatorHealthService::stop`。

健康检查服务 OperatorHealthService 对应的创建、启动和终止的代码如下：

```java 
// OperatorHealthService.java 
public static OperatorHealthService fromConfig(FlinkConfigManager configManager) {
    var defaultConfig = configManager.getDefaultConfig();
    // 如果开启健康检查
    if (defaultConfig.getBoolean(
            KubernetesOperatorConfigOptions.OPERATOR_HEALTH_PROBE_ENABLED)) {
        return new OperatorHealthService(configManager);
    } else { // 不开启健康检查
        LOG.info("Health probe disabled");
        return null;
    }
}

public void start() {
    // Start the service for the http endpoint
    try {
        httpBootstrap =
                new HttpBootstrap(
                        probe,
                        configManager
                                .getDefaultConfig()
                                .get(
                                        KubernetesOperatorConfigOptions
                                                .OPERATOR_HEALTH_PROBE_PORT));
    } catch (InterruptedException e) {
        throw new RuntimeException(e);
    }
}

public void stop() {
    httpBootstrap.stop();
}
```

启动时会读取配置中的端口号，而整体实现时依赖 `HttpBootstrap`，启动时会默认开启 8085 端口，当存活探针和启动探针访问 8085 端口时，返回 200 即表示正常。

### 4.6.2 优雅关闭
在 Operator 的 run() 方法中有优雅关闭的相关代码：

```java
public void run() {
    // ... 其他启动代码 ...
    
    // 安装关闭钩子，设置超时时间
    operator.installShutdownHook(
        baseConfig.get(KubernetesOperatorConfigOptions.OPERATOR_TERMINATION_TIMEOUT));
    
    // ... 其他代码 ...
}

// Operator.java
public void installShutdownHook(Duration gracefulShutdownTimeout) {
    if (!leaderElectionManager.isLeaderElectionEnabled()) {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> stop(gracefulShutdownTimeout)));
    } else {
        log.warn("Leader election is on, shutdown hook will not be installed.");
    }
}

// 关闭超时配置
@Documentation.Section(SECTION_ADVANCED)
public static final ConfigOption<Duration> OPERATOR_TERMINATION_TIMEOUT =
    operatorConfig("termination.timeout")
        .durationType()
        .defaultValue(Duration.ofMinutes(5))
        .withDescription(
            "The timeout for the operator to gracefully shutdown. "
            + "After this timeout, the operator will be forcefully terminated.");
```

从代码中可以看出优雅关闭的本质，也是添加一个 JVM 钩子。
