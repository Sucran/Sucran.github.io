---
title: "FlinkOperator Source Code Analysis"
date: 2025-07-24T23:43:48+08:00
draft: false
description: "Deep dive into FlinkOperator startup process, from core variables to plugin mechanism complete implementation"
---

## 4.1 FlinkOperator Startup Process

From the Debug process in the first chapter, we know that the startup class corresponding to the Flink Operator container startup script is `org.apache.flink.kubernetes.operator.FlinkOperator`

The FlinkOperator startup process begins with the standard `main` function:

```java
// FlinkOperator main class entry
public class FlinkOperator {
    
    public static void main(String... args) {
        // Record environment information and startup parameters
        EnvUtils.logEnvironmentInfo(LOG, "Flink Kubernetes Operator", args);
        
        // Create and start FlinkOperator instance
        new FlinkOperator(null).run();
    }
    
    // Actual running logic
    public void run() {
        // Register all controllers
        registerDeploymentController();
        registerSessionJobController();
        registerSnapshotController();
        
        // Install shutdown hook
        operator.installShutdownHook(
            baseConfig.get(KubernetesOperatorConfigOptions.OPERATOR_TERMINATION_TIMEOUT));
        
        // Start operator
        operator.start();
        
        // Start health service
        if (operatorHealthService != null) {
            HealthProbe.INSTANCE.setRuntimeInfo(operator.getRuntimeInfo());
            Runtime.getRuntime().addShutdownHook(new Thread(operatorHealthService::stop));
            operatorHealthService.start();
        }
    }
}
```

The complete startup process sequence diagram is as follows:

{{< mermaid >}}
sequenceDiagram
    participant K8s as Kubernetes
    participant Pod as Pod Container
    participant JVM as JVM
    participant Main as FlinkOperator
    participant Components as Core Components
    participant Controllers as Controllers
    participant K8sAPI as K8s API Server

    Note over K8s, K8sAPI: 1. Container Startup Phase
    K8s->>Pod: Create Pod
    Pod->>JVM: Start JVM Process
    
    Note over JVM, Main: 2. JVM Startup Phase
    JVM->>Main: Call main() method
    Main->>Main: Record environment information
    
    Note over Main, Components: 3. Component Initialization Phase
    Main->>Components: Initialize 11 core components
    Components-->>Main: Component initialization complete
    
    Note over Main, Controllers: 4. Controller Registration Phase
    Main->>Controllers: Register 3 controllers
    Controllers-->>Main: Controller registration complete
    
    Note over Main, K8sAPI: 5. Event Loop Phase
    Main->>K8sAPI: Establish event monitoring
    K8sAPI-->>Main: Return event stream
    Main->>Main: Enter event loop
    
    Note over Main: 6. Health Service Phase
    Main->>Main: Start health check endpoint
    
    Note over JVM, Main: 7. Graceful Shutdown Phase
    JVM->>Main: Receive SIGTERM signal
    Main->>Main: Stop all components
    Main-->>JVM: Shutdown complete
{{< /mermaid >}}

The core startup process includes:
1. **Container Startup**: Kubernetes creates Pod, executes docker-entrypoint script
2. **JVM Startup**: Execute main() method
3. **Component Initialization**: Initialize 11 core member variables in dependency order
4. **Controller Registration**: Register Deployment, SessionJob, Snapshot three controllers
5. **Event Loop**: Start Operator and start event loop
6. **Health Service**: Start HTTP health check endpoint
7. **Graceful Shutdown**: Handle SIGTERM signal through JVM shutdown hook

#### 4.1.1 Deep Analysis of Core Member Variables

FlinkOperator, as the entry class, has member variable design that embodies the architectural philosophy of "configuration-driven, plugin extensibility, unified events". The member variables of FlinkOperator are as follows:

```java
public class FlinkOperator {
    private final Operator operator;                                    // JOSDK core controller
    private final KubernetesClient client;                              // K8s API client
    private final FlinkResourceContextFactory ctxFactory;               // Resource context factory
    private final FlinkConfigManager configManager;                     // Configuration manager
    private final Set<FlinkResourceValidator> validators;               // Validator collection
    @VisibleForTesting final Set<RegisteredController<?>> registeredControllers; // Registered controllers
    private final KubernetesOperatorMetricGroup metricGroup;            // Metric collection group
    private final Collection<FlinkResourceListener> listeners;          // Event listener collection
    private final OperatorHealthService operatorHealthService;          // Health check service
    private final EventRecorder eventRecorder;                          // Event recorder
    private final Configuration baseConfig;                             // Base configuration snapshot
}
```

The corresponding variable analysis is as follows:

| Variable Name | Type | Core Function | Dependencies |
|---------------|------|---------------|--------------|
| `configManager` | `FlinkConfigManager` | Configuration manager, supports dynamic configuration updates and namespace-level isolation | No dependencies, foundation for other components |
| `baseConfig` | `Configuration` | Base configuration snapshot, component configuration baseline | Depends on configManager |
| `metricGroup` | `KubernetesOperatorMetricGroup` | Metric collection group, provides fine-grained monitoring data | Depends on baseConfig |
| `client` | `KubernetesClient` | Fabric8 client, responsible for all interactions with K8s API Server | Depends on configManager, metricGroup |
| `operator` | `Operator` | JOSDK core controller, manages Kubernetes reconciliation loop | Depends on client, configManager |
| `validators` | `Set<FlinkResourceValidator>` | Plugin validator collection, supports custom validation logic | Depends on configManager |
| `listeners` | `Collection<FlinkResourceListener>` | Event listener collection, implements observer pattern | Depends on configManager |
| `eventRecorder` | `EventRecorder` | Unified event manager, intelligent deduplication mechanism | Depends on client, listeners |
| `ctxFactory` | `FlinkResourceContextFactory` | Resource context factory, creates dedicated processing contexts for different resource types | Depends on configManager, metricGroup, eventRecorder |
| `registeredControllers` | `Set<RegisteredController<?>>` | Registered controller collection, supports runtime dynamic adjustment of monitored namespaces | Depends on operator, ctxFactory |
| `operatorHealthService` | `OperatorHealthService` | Health check service, provides HTTP endpoint | Depends on configManager |

In this chapter, we will focus on analyzing FlinkConfigManager, KubernetesOperatorMetricGroup, OperatorHealthService, and plugin registration mechanisms. FlinkResourceContextFactory and RegisteredController will be covered in detail in the next chapter.

#### 4.1.2 Operator Creation

The creation process of the operator member variable is relatively simple. It's important to note that the Java Operator SDK's Operator class also has some configuration items. The code overrides default configurations through the `overrideOperatorConfigs()` method. The code is as follows:

```java
@VisibleForTesting
protected Operator createOperator() {
    return new Operator(this::overrideOperatorConfigs);
}

private void overrideOperatorConfigs(ConfigurationServiceOverrider overrider) {
    overrider.withKubernetesClient(client);
    
    var conf = configManager.getDefaultConfig();
    var operatorConf = FlinkOperatorConfiguration.fromConfiguration(conf);
    
    // Configure concurrency
    int parallelism = operatorConf.getReconcilerMaxParallelism();
    if (parallelism == -1) {
        LOG.info("Configuring operator with unbounded reconciliation thread pool.");
        overrider.withExecutorService(Executors.newCachedThreadPool());
    } else {
        LOG.info("Configuring operator with {} reconciliation threads.", parallelism);
        overrider.withConcurrentReconciliationThreads(parallelism);
    }
    
    // Configure metrics
    if (operatorConf.isJosdkMetricsEnabled()) {
        overrider.withMetrics(new OperatorJosdkMetrics(metricGroup, configManager));
    }
    
    // Configure termination timeout
    overrider.withTerminationTimeoutSeconds(
        (int) conf.get(KubernetesOperatorConfigOptions.OPERATOR_TERMINATION_TIMEOUT).toSeconds());
    
    // Configure startup error handling
    overrider.withStopOnInformerErrorDuringStartup(
        conf.get(KubernetesOperatorConfigOptions.OPERATOR_STOP_ON_INFORMER_ERROR));
    
    // Configure leader election
    var leaderElectionConf = operatorConf.getLeaderElectionConfiguration();
    if (leaderElectionConf != null) {
        overrider.withLeaderElectionConfiguration(leaderElectionConf);
        LOG.info("Operator leader election is enabled.");
    } else {
        LOG.info("Operator leader election is disabled.");
    }
}
```

The Operator configurations that Flink Operator supports overriding are listed in the [Official Documentation - System Configuration](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-release-1.12/docs/operations/configuration/#system-configuration). These system configurations include configurations for both the Operator itself and Controllers.

It's important to note that the configurations involved in the above code are those that take effect when initializing the Operator and cannot be hot-reloaded.

Additionally, when registering Controllers, there's also a configuration override method corresponding to these system configurations. The code is as follows:

```java
private void overrideControllerConfigs(ControllerConfigurationOverrider<?> overrider) {
    // Get Operator-related system configurations
    var operatorConf = configManager.getOperatorConfiguration();
    // Get namespace settings
    var watchNamespaces = operatorConf.getWatchedNamespaces();
    LOG.info("Configuring operator to watch the following namespaces: {}.", watchNamespaces);
    overrider.settingNamespaces(operatorConf.getWatchedNamespaces());

    // Get retry configuration
    overrider.withRetry(operatorConf.getRetryConfiguration());
    // Get RateLimiter configuration
    overrider.withRateLimiter(operatorConf.getRateLimiter());

    // Get label selector configuration
    var labelSelector = operatorConf.getLabelSelector();
    LOG.info(
            "Configuring operator to select custom resources with the {} labels.",
            labelSelector);
    overrider.withLabelSelector(labelSelector);
}
```

These configurations are also only effective during registration and cannot be hot-reloaded.

## 4.2 FlinkConfigManager Configuration Management

We need to deeply understand one of the most important components — FlinkConfigManager. Configuration management is the core of any distributed system. FlinkOperator implements a flexible and efficient configuration management mechanism through FlinkConfigManager.

### 4.2.1 Configuration Loading Architecture

```java
public class FlinkConfigManager {
    private static final Logger LOG = LoggerFactory.getLogger(FlinkConfigManager.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    // Default configuration
    private volatile Configuration defaultConfig;
    // flink operator configuration
    private volatile FlinkOperatorConfiguration defaultOperatorConfiguration;
    // Whether to install snapshot CRD
    private final boolean snapshotCrdInstalled;
    // Configuration version
    private final AtomicLong defaultConfigVersion = new AtomicLong(0);
    // Configuration cache
    private final LoadingCache<Key, Configuration> cache;
    // Namespace listener function
    private final Consumer<Set<String>> namespaceListener;
}

@Value
@Builder
private static class Key { // Guava Cache key
    // Config version
    long configVersion;
    // Specific CR deployment namespace
    String namespace;
    // Specific CR name
    String name;
    // Specific CR spec
    ObjectNode spec;
}
```

From the member variables of FlinkConfigManager, we can see that it mainly manages:
- defaultConfig: Operator configuration content and corresponding version number (defaultConfigVersion)
- cache: Flink cluster instance configuration content and corresponding version (Key.configVersion)

### 4.2.2 Operator Configuration Override Mechanism

FlinkOperator's configuration loading uses the `CONF_OVERRIDE_DIR` container instance environment variable as the configuration file path and implements configuration override through the `loadGlobalConfiguration()` method.

`CONF_OVERRIDE_DIR` is FlinkOperator's core configuration environment variable, used to specify the directory of configuration YAML files. The configuration loading logic is as follows:

```java
private static Configuration loadGlobalConfiguration() {
    // Load flink-conf.yaml or conf.yaml from the specified directory
    return loadGlobalConfiguration(EnvUtils.get(EnvUtils.ENV_CONF_OVERRIDE_DIR));
}

protected static Configuration loadGlobalConfiguration(Optional<String> confOverrideDir) {
    if (confOverrideDir.isPresent()) {
        // Load configuration from CONF_OVERRIDE_DIR
        Configuration configOverrides = GlobalConfiguration.loadConfiguration(confOverrideDir.get());
        LOG.debug("Loading default configuration with overrides from {}", confOverrideDir.get());
        return GlobalConfiguration.loadConfiguration(configOverrides);
    }
    // If CONF_OVERRIDE_DIR doesn't exist, load default configuration
    LOG.debug("Loading default configuration");
    return GlobalConfiguration.loadConfiguration();
}
```

The configuration override process is as follows:

1. Check if the `CONF_OVERRIDE_DIR` environment variable exists
2. If it exists, load configuration files from the specified directory
3. Apply override configuration to global configuration
4. If it doesn't exist, directly load Flink default configuration

### 4.2.3 FlinkDeployment Instance Configuration Cache Mechanism

```java
public FlinkConfigManager(
            Configuration defaultConfig,
            Consumer<Set<String>> namespaceListener,
            boolean snapshotCrdInstalled) {
    // other logics

    // Configuration cache configuration
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

Where cacheTimeout defaults to 10 minutes and cacheSize defaults to 1000. It's important to note that this is the cache limit for a single Operator container instance.

The removalListener logic corresponding to CacheBuilder cleans up temporary files generated by podTemplate mapping. When cache misses, the corresponding configuration generation logic is `generateConfig(k)`. The corresponding code is as follows:

```java
private Configuration generateConfig(Key key) {
        try {
            LOG.debug("Generating new config");
            // Note that only FlinkDeploymentSpec can be cached here
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

It's important to note that only FlinkDeployment supports configuration caching, while FlinkSessionJob does not. Additionally, the overall complex logic is contained in `FlinkConfigBuilder.buildFrom`. The corresponding code flow diagram is as follows:

{{< mermaid >}}
flowchart TD
    A[Start: buildFrom method] --> B[Create FlinkConfigBuilder instance<br/>namespace, clusterId, spec, flinkConfig]
    
    B --> C[Configuration Module: applyFlinkConfiguration<br/>• Parse flinkConfiguration in spec<br/>• Set default REST service type<br/>• Set web.cancel.enable<br/>• Set Flink version]
    
    C --> D[Log Configuration Module: applyLogConfiguration<br/>• Handle log4j/logback configuration<br/>• Create log configuration files<br/>• Set CONF_DIR]
    
    D --> E[Image Configuration Module: applyImage<br/>• Set container image<br/>• Select configuration keys based on Flink version]
    
    E --> F[Image Pull Policy Module: applyImagePullPolicy<br/>• Set image pull policy]
    
    F --> G[Service Account Module: applyServiceAccount<br/>• Set Kubernetes service account]
    
    G --> H[Pod Template Module: applyPodTemplate<br/>• Merge general and specific Pod templates<br/>• Apply resource configuration<br/>• Create temporary template files<br/>• Set JM/TM Pod templates]
    
    H --> I[JobManager Specification Module: applyJobManagerSpec<br/>• Set JM resource configuration<br/>• Set JM replica count]
    
    I --> J[TaskManager Specification Module: applyTaskManagerSpec<br/>• Set TM resource configuration<br/>• Set TM replica count<br/>• Calculate parallelism]
    
    J --> K[Job/Session Specification Module: applyJobOrSessionSpec<br/>• Set deployment target<br/>• Handle JAR URI<br/>• Apply job configuration<br/>• Handle standalone mode]
    
    K --> L[Build Final Configuration: build<br/>• Set cluster configuration<br/>• Set namespace and cluster ID<br/>• Set high availability configuration]
    
    L --> M[Return final Configuration]
    
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

From the flow diagram, we can see that the cache generation process is quite complex. For each FlinkDeployment, the configuration will be cached.

Additionally, the code creates a single-threaded pool that cleans up all caches every 10 minutes.

### 4.2.4 Operator Configuration Hot Reload Mechanism

**Configuration Monitoring Task**
```java
public FlinkConfigManager(
            Configuration defaultConfig,
            Consumer<Set<String>> namespaceListener,
            boolean snapshotCrdInstalled) {
        // logic of cache

        // executorService corresponds to the single-threaded pool for cache cleanup
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

**Configuration Change Handling Logic**
```java
private class ConfigUpdater implements Runnable {
    public void run() {
        try {
            LOG.debug("Checking for config update changes...");
            // Update default configuration
            updateDefaultConfig(loadGlobalConfiguration());
        } catch (Exception e) {
            LOG.error("Error while updating operator configuration", e);
        }
    }
}
```

From the code, the corresponding updateDefaultConfig code flow diagram is as follows:

{{< mermaid >}}
flowchart TD
    A[Start: updateDefaultConfig] --> B{Has configuration changed?}
    
    B -->|No| C[Return directly]
    
    B -->|Yes| D[Handle FlinkSnapshot configuration<br/>Check CRD installation status]
    D --> E[Update namespace configuration<br/>Trigger Controller to modify monitored namespaces]
    E --> F[Update default configuration<br/>Increment version number]
    F --> G[Update complete]
    
    style A fill:#e1f5fe
    style C fill:#ffcdd2
    style G fill:#c8e6c9
    style B fill:#fff3e0
    style D fill:#f3e5f5
    style E fill:#e8f5e8
    style F fill:#2196f3
{{< /mermaid >}}

## 4.3 EventRecorder Event Recording

EventRecorder is a key component of Flink Operator, responsible for creating and distributing business events that Java Operator SDK's EventSource cannot support. EventRecorder implements a multi-level event deduplication mechanism through the EventUtils utility class, avoiding excessive custom Events that could cause abnormal load on the Kubernetes cluster. The implemented events are designed to allow users to perform auditing and business-level monitoring, while serving as a supplement to EventSource.

### 4.3.1 Custom Event Components

The main components of EventRecorder's custom events are Type, Component, and Reason. The corresponding code is as follows:

```java
public enum Type {
    Normal,     // Normal event
    Warning     // Warning event
}

public enum Component {
    Operator,               // Operator component
    JobManagerDeployment,   // JobManager deployment
    Job,                    // Job
    Snapshot               // Snapshot
}

public enum Reason {
    Suspended,              // Suspended
    SpecChanged,            // Specification changed
    Rollback,               // Rollback
    Submit,                 // Submit
    JobStatusChanged,       // Job status changed
    SavepointError,         // Savepoint error
    CheckpointError,        // Checkpoint error
    Cleanup,                // Cleanup
    CleanupFailed,          // Cleanup failed
    Missing,                // Missing
    ValidationError,        // Validation error
    RecoverDeployment,      // Recover deployment
    RestartUnhealthyJob,    // Restart unhealthy job
    ScalingReport,          // Scaling report
    IneffectiveScaling,     // Ineffective scaling
    MemoryPressure,         // Memory pressure
    ResourceQuotaReached,   // Resource quota reached
    AutoscalerError,        // Autoscaler error
    Scaling,                // Scaling
    UnsupportedFlinkVersion, // Unsupported Flink version
    SnapshotError,          // Snapshot error
    SnapshotAbandoned       // Snapshot abandoned
}
```

### 4.3.2 Four-Level Deduplication Strategy

EventRecorder implements a multi-level event deduplication mechanism through the EventUtils utility class. There are four levels of event deduplication strategies. The flow diagram is as follows:

{{< mermaid >}}
flowchart TD
    Start([Event Trigger]) --> L1[L1: Event Name Hash Deduplication]
    L1 --> L2[L2: Event Window Deduplication]
    L2 --> L3[L3: Label Deduplication]
    L3 --> L4[L4: Replace if Exists]
    
    L1 -->|Duplicate| Skip[Skip Event]
    L2 -->|Duplicate| Skip
    L3 -->|No Change| Skip
    L4 -->|One-time| Create[Create Event]
    L4 -->|Repeatable| Update[Update Event]
    
    Skip --> Done([Complete])
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

The corresponding code is as follows:
```java
  // L1: Event signature mechanism
  String eventName = EventUtils.generateEventName(
      target, type, reason, message, component);

  // L2: Time window deduplication
  EventUtils.intervalCheck(Event existing, @Nullable Duration interval);

  // L3: Label comparison
  EventUtils.labelCheck(
            Event existing, Predicate<Map<String, String>> dedupePredicate)

  // L4: One-time event protection
  EventUtils.createOrReplaceEvent(KubernetesClient client, Event event)
```

### 4.3.3 Event Listener Mechanism

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

The process of creating EventRecorder is essentially a process of building context and setting up event listeners. The listeners here are FlinkOperator's event listener plugins. AuditUtils performs log output operations for potential log auditing implementation. We will introduce FlinkOperator's three plugin mechanisms next.

## 4.4 Plugin Architecture (SPI Mechanism)

To support extensibility and customization requirements, FlinkOperator adopts a plugin architecture design. Through Java's SPI (Service Provider Interface) mechanism, the system can dynamically discover and load extension components at runtime, such as validators, listeners, etc.

### 4.4.1 SPI Mechanism Principle

SPI (Service Provider Interface) is a service discovery mechanism provided by Java that allows dynamic loading of implementation classes at runtime.

**SPI Workflow:**
1. **Define Interface**: Define service interface
2. **Implementation Classes**: Provide specific implementations of the interface
3. **Configuration Files**: Create configuration files in the `META-INF/services/` directory
4. **Plugin Loading**: Load implementation classes through `ServiceLoader`

### 4.4.2 Plugin Discovery Mechanism

Flink Operator provides two types of extension plugins: validators and listeners. Validators are used to validate resource values, while listeners are used to monitor events and handle them.

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

In the FlinkOperator constructor, there's logic to construct validators plugins. The code here doesn't show any traces of ServiceLoader yet. The code is as follows:

```java
/**
 * Discover and load all FlinkResourceValidator plugins
 * Including default validators and custom plugin validators
 */
public static Set<FlinkResourceValidator> discoverValidators(FlinkConfigManager configManager) {
    // Get default configuration
    var conf = configManager.getDefaultConfig();
    Set<FlinkResourceValidator> resourceValidators = new HashSet<>();
    
    // 1. Create and configure default validator
    DefaultValidator defaultValidator = new DefaultValidator(configManager);
    defaultValidator.configure(conf);
    resourceValidators.add(defaultValidator);
    
    // 2. Load custom validators from plugin directory
    PluginUtils.createPluginManagerFromRootFolder(conf)
            .load(FlinkResourceValidator.class)  // Load FlinkResourceValidator type plugins
            .forEachRemaining(
                    validator -> {
                        // Record discovered plugin validators
                        LOG.info(
                                "Discovered resource validator from plugin directory[{}]: {}.",
                                System.getenv()
                                        .getOrDefault(
                                                ConfigConstants.ENV_FLINK_PLUGINS_DIR,  // Environment variable specified plugin directory
                                                ConfigConstants.DEFAULT_FLINK_PLUGINS_DIRS),  // Default plugin directory
                                validator.getClass().getName());
                        
                        // Configure plugin validator
                        validator.configure(conf);
                        // Add to validator collection
                        resourceValidators.add(validator);
                    });
    
    // Return collection of all validators
    return resourceValidators;
}
```

From the code, we can see that the main plugin inherits from the `FlinkResourceValidator.class` class. Then from the code, we can see that plugin JAR packages should be placed in the folder corresponding to the FLINK_PLUGINS_DIR environment variable. When building the Flink Operator image, we need to pay attention to adding this logic. `PluginUtils` comes from the flink-core library. The plugin discovery mechanism used here is consistent with the Flink framework.

In addition to validators plugins, the listeners plugin discovery mechanism is the same. The corresponding sequence diagram is as follows:

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
  ServiceLoader ->> ServiceLoader: Scan META-INF/services/ directory
  ServiceLoader ->> ServiceLoader: Discover FlinkResourceListener implementation classes
  ServiceLoader -->> PluginManager: ServiceLoader iterator
  PluginManager ->> Listener: Instantiate implementation classes
  Listener -->> PluginManager: listener instance
  PluginManager ->> Listener: getClass().getName()
  Listener -->> PluginManager: class name string

  PluginManager -->> discoverListeners: Return listeners collection
{{< /mermaid >}}

From the sequence diagram, we can see that the overall discoverListeners plugin discovery process is the same. The core class is `PluginUtils`. The complexity here is that the process from `PluginUtils` to `ServiceLoader` is quite long.

### 4.4.3 Custom Plugin Code Examples

For custom plugins, the following code is an example provided in the [official documentation](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-release-1.10/docs/operations/plugins/)

```java
// Validator example
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

I've also written a CustomResourceListener here for readers' reference. The code is as follows:

```java
// Listener example
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
            LOG.info("Job Manager single Pod restart");
            LOG.info("Prepare to modify Flink Conf Configmap");
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

Readers only need to implement the interface and its methods, package according to the SPI method, and place the JAR package in the corresponding location in the image.

## 4.5 Controllers Registration Mechanism

FlinkOperator v1.10 supports three types of Controllers:
- FlinkDeploymentController
- FlinkSessionJobController
- FlinkStateSnapshotController

Controller registration is performed in the FlinkOperator's run() method. The code is as follows:

```java
public void run() {
        registerDeploymentController();
        registerSessionJobController();
        registerSnapshotController();
        // ... other logics
    }
```

In each registration of Controllers, the key code calls the `operator.register(controller, this::overrideControllerConfigs)` method.

As mentioned in the previous section 4.1.1.3 Operator Creation, the overrideControllerConfigs method when registering Controllers corresponds to system configurations.

## 4.6 Health Probes and Graceful Shutdown

### 4.6.1 Health Probes

Health probes refer to livenessProbe and startupProbe in Kubernetes. For these two probes to take effect, you need to add the following content to the Helm Chart's values.yaml:

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

After configuration is complete, you also need to add the following content to the Operator's configuration file:

```yaml
kubernetes.operator.health.probe.enabled = true
# The port 8085 above can also be modified
# kubernetes.operator.health.probe.port = 8085
```

Let's see how the code implements this functionality. The functionality corresponds to the operatorHealthService member variable of FlinkOperator. The corresponding code is as follows:

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

When FlinkOperator terminates, due to the JVM hook design, it will also call `operatorHealthService::stop`.

The creation, startup, and termination code corresponding to the health check service OperatorHealthService is as follows:

```java 
// OperatorHealthService.java 
public static OperatorHealthService fromConfig(FlinkConfigManager configManager) {
    var defaultConfig = configManager.getDefaultConfig();
    // If health check is enabled
    if (defaultConfig.getBoolean(
            KubernetesOperatorConfigOptions.OPERATOR_HEALTH_PROBE_ENABLED)) {
        return new OperatorHealthService(configManager);
    } else { // If health check is not enabled
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

When starting, it reads the port number from the configuration. The overall implementation depends on `HttpBootstrap`. When starting, it opens port 8085 by default. When liveness probe and startup probe access port 8085, returning 200 indicates normal status.

### 4.6.2 Graceful Shutdown

In the Operator's run() method, there's graceful shutdown related code:

```java
public void run() {
    // ... other startup code ...
    
    // Install shutdown hook, set timeout
    operator.installShutdownHook(
        baseConfig.get(KubernetesOperatorConfigOptions.OPERATOR_TERMINATION_TIMEOUT));
    
    // ... other code ...
}

// Operator.java
public void installShutdownHook(Duration gracefulShutdownTimeout) {
    if (!leaderElectionManager.isLeaderElectionEnabled()) {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> stop(gracefulShutdownTimeout)));
    } else {
        log.warn("Leader election is on, shutdown hook will not be installed.");
    }
}

// Shutdown timeout configuration
@Documentation.Section(SECTION_ADVANCED)
public static final ConfigOption<Duration> OPERATOR_TERMINATION_TIMEOUT =
    operatorConfig("termination.timeout")
        .durationType()
        .defaultValue(Duration.ofMinutes(5))
        .withDescription(
            "The timeout for the operator to gracefully shutdown. "
            + "After this timeout, the operator will be forcefully terminated.");
```

From the code, we can see the essence of graceful shutdown is also adding a JVM hook. 