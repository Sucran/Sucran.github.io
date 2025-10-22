---
title: "Flink Operator CRD Analysis"
date: 2024-12-14T23:34:54+08:00
draft: false
description: ""
---

## 3.1 CRD and API Layered Design

After briefly understanding the Java Operator SDK, this chapter will dive into the main topic of Flink Operator source code analysis. Let's reopen the code pulled from Github in the first chapter. Looking at the modules in the project, you can see the following modules:

```shell
flink-kubernetes-operator/
├── flink-kubernetes-operator/          # Main Operator implementation, containing Controller and reconciliation logic
├── flink-kubernetes-operator-api/      # API definitions and CRDs, defining custom resources like FlinkDeployment
├── flink-kubernetes-operator-autoscaler/ # Autoscaling functionality implementation in the Operator
├── flink-kubernetes-webhook/           # Webhook implementation for resource validation and modification
├── flink-autoscaler/                   # Core autoscaling module, independent scaling service
├── flink-autoscaler-plugin-jdbc/      # JDBC plugin for database connection pool monitoring
├── flink-autoscaler-standalone/       # Standalone deployment version, independent of Operator
└── flink-kubernetes-standalone/       # Standalone deployment mode, traditional Flink cluster deployment
```

Among these, webhook, autoscaler, and standalone-related modules will be covered in subsequent chapters, so we'll skip them for now. You'll notice that there are two remaining operator-related modules: one is the operator implementation itself, and the other is the operator's API definitions and CRD implementation.

Why separate the implementation from the API & CRD definitions? Essentially, CRDs are a manifestation of API definitions in the Operator pattern. Placing them in the same module eliminates the hassle of synchronous modifications for callers. According to the principle of separation of concerns, other key modules will also depend on the API module. For readers to understand the Operator code, the first thing they need to understand is the CRD, so this chapter focuses on explaining the CRDs in this module. In Chapter 2, I have already detailed the definition, origin, and generation principles of CRDs, so I won't repeat them here.

### 3.1.1 FlinkDeployment & FlinkSessionJob

The Flink Operator initially had only two CRDs: FlinkDeployment and FlinkSessionJob. In version 1.10, a new CRD called FlinkStateSnapshot was added, which we'll cover in subsequent chapters.

The official documentation describes these two custom resources as follows:

> FlinkDeployment CR defines Flink Application and Session cluster deployments. The FlinkSessionJob CR defines the session job on the Session cluster and each Session cluster can run multiple FlinkSessionJob.
>
> ...
>
> With these two Custom Resources, we can support two different operational models:
>
> - Flink application managed by the FlinkDeployment
>
> - Empty Flink session managed by the FlinkDeployment + multiple jobs managed by the FlinkSessionJobs. The operations on the session jobs are independent of each other.

From the documentation description, we can see that FlinkSessionJob itself depends on FlinkDeployment, so let's first look at the FlinkDeployment class definition.

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

From the class definition, we can see that it inherits from the generic parent class AbstractFlinkResource, which has two generic parameters: FlinkDeploymentSpec and FlinkDeploymentStatus. It also implements the Namespaced interface, which indicates that this custom resource's scope is within a namespace.

Does FlinkSessionJob also inherit from the generic parent class AbstractFlinkResource? Let's also look at its definition:

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

From the code, yes, but the generic parameters are different. Let's look directly at the AbstractFlinkResource definition:

```java
@Experimental
public class AbstractFlinkResource<
                SPEC extends AbstractFlinkSpec, STATUS extends CommonStatus<SPEC>>
        extends CustomResource<SPEC, STATUS> implements Namespaced {}
```

We can see that it ultimately inherits from the CustomResource interface, which is code from the Fabric8 kubernetes-client-api library. This is essentially a Java implementation of a custom resource YAML definition. You can think of AbstractFlinkResource itself as part of the custom resource declaration, it just extracts the common parts of FlinkSessionJob and FlinkDeployment. SPEC is a generic placeholder, meaning that SPEC classes all inherit from AbstractFlinkSpec, while STATUS classes inherit from CommonStatus. In other words, AbstractFlinkSpec contains the repeated parts in the spec structure of the YAML definition, and CommonStatus contains the repeated parts in the status structure of the YAML definition.

But why isn't AbstractFlinkResource automatically generated into YAML files by the crd-generator-apt library developed by Fabric8? The reason is that this interface doesn't have the corresponding annotations. This was mentioned in the Operator development process in Chapter 2, and readers can refer back to the example.

The specific dependency relationships can be seen directly in the following diagram:
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/spec_diagram.png "CRD Class Dependency Diagram")

## 3.2 CRD Code Design Analysis

### 3.2.1 Job Level Design

#### AbstractFlinkSpec - Job Submission Configuration Declaration

Delving into the design of `AbstractFlinkSpec`, we find that it embodies the "minimal complete set" design principle:

```java
public abstract class AbstractFlinkSpec implements Diffable<AbstractFlinkSpec> {
    private JobSpec job;                    // Optional job configuration
    private Long restartNonce;             // Restart trigger
    private Map<String, String> flinkConfiguration; // Configuration override
}
```

These three fields constitute the configuration abstraction for Flink job submission:
- job corresponds to job configuration, including common jar package URI, parallelism, class name, execution parameters, etc.
- restartNonce is used for restart trigger value. When the value is modified, the controller will detect it and restart the job
- flinkConfiguration are job configuration parameters, corresponding to conf.yaml during job submission

The restart detection mechanism for restartNonce follows the following pattern:
```
User: restartNonce=1 → Controller detects change → Triggers restart operation
User: restartNonce=2 → Controller detects change → Triggers restart again
```

The designers deliberately abstracted the job and flinkConfiguration fields into AbstractFlinkSpec, which allows FlinkDeployment to support both Application mode and Session mode of Flink. When FlinkDeployment doesn't configure job, it corresponds to a Session mode cluster.

Further, the job configuration mainly contains:

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

The JobSpec class defines the job configuration fields:
- `jarURI`: URI path of the job JAR package within the Flink container, such as `local:///opt/flink/examples/streaming/StateMachineExample.jar`
- `parallelism`: Flink job parallelism setting
- `entryClass`: Fully qualified class name of the Flink job main class
- `args`: Parameter array passed to the Flink job main class
- `state`: Expected state of the job, default is `RUNNING`
- `savepointTriggerNonce`: Manual savepoint trigger, modifying this value can trigger savepoint operation
- `initialSavepointPath`: Savepoint path used when the job is first deployed or during savepoint redeployment
- `checkpointTriggerNonce`: Manual checkpoint trigger, modifying this value can trigger checkpoint operation
- `upgradeMode`: Job upgrade mode, default is `STATELESS` (stateless)
- `allowNonRestoredState`: Whether to allow checkpoint state that cannot be mapped to any job vertex
- `savepointRedeployNonce`: Trigger for complete redeployment from the specified savepoint path

These configurations can all be specified in YAML, and the parameter value validation logic will be covered in the next chapter's control flow. The activation process of savepointTriggerNonce, checkpointTriggerNonce, and savepointRedeployNonce is the same as the restartNonce mentioned earlier.

#### CommonStatus - Job Status

The design of CommonStatus embodies the "unified language" philosophy of status observation:

```java
public abstract class CommonStatus<SPEC extends AbstractFlinkSpec> {
    private JobStatus jobStatus = new JobStatus();           // Job status
    private String error;                                     // Error information
    private Long observedGeneration;                          // Version tracking
    private ResourceLifecycleState lifecycleState;            // Lifecycle state
    
    public abstract ReconciliationStatus<SPEC> getReconciliationStatus(); // Reconciliation status retrieval
}
```

This abstract class organically integrates status information from different levels through composition rather than inheritance:
- `jobStatus` provides runtime insights at the job level
- `error` combines with the framework's ErrorStatusHandler for error propagation
- `observedGeneration` ensures version consistency between Spec and Status
- `lifecycleState` is calculated through algorithms and corresponds to resource-level lifecycle in the cluster

The reconciliation status ReconciliationStatus corresponds to the standard evolution path from creation to stability:
```
CREATED → DEPLOYED → STABLE
    ↓        ↓
  FAILED  UPGRADING
```

This state path corresponds to the cluster deployment state, and this state flow will be observed and recorded by the controllers corresponding to FlinkDeployment and FlinkSessionJob.

The jobStatus corresponds to the JobStatus class, which provides complete runtime status information for the job:

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

The JobStatus class defines the job runtime status fields:
- `jobName`: Name of the job
- `jobId`: Unique identifier of the Flink job
- `state`: Current state of the job, corresponding to Flink's JobStatus enum (such as RUNNING, FINISHED, FAILED, etc.)
- `startTime`: Job start time
- `updateTime`: Last update time of job status
- `upgradeSavepointPath`: Confirmation information of savepoint path used during upgrade

There are two compatibility fields that are deprecated:
- `savepointInfo`: Savepoint-related information (deprecated), functionality covered by the new CRD FlinkSnapshot
- `checkpointInfo`: Checkpoint-related information (deprecated), functionality covered by the new CRD FlinkSnapshot

From the code design, we can see that jobStatus is mainly a wrapper around Flink framework's original JobStatus.

The lifecycleState, in the next chapter's control flow code analysis, is essentially a mapping relationship with ReconciliationStatus - one is the surface and the other is the core. The lifecycleState corresponds to the ResourceLifecycleState enum class, which defines more detailed resource deployment states. The code is as follows:

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

The lifecycleState (ResourceLifecycleState) enum defines the various states of resource lifecycle:
- `CREATED`: Resource has been created in Kubernetes but not yet handled by the operator
- `SUSPENDED`: Resource (job) has been suspended
- `UPGRADING`: Resource is being upgraded
- `DEPLOYED`: Resource has been deployed/submitted to Kubernetes, but not yet stable, may be rolled back
- `STABLE`: Resource deployment is considered stable and won't be rolled back
- `ROLLING_BACK`: Resource is being rolled back to the last stable spec
- `ROLLED_BACK`: Resource has been deployed with the last stable spec
- `FAILED`: Job has terminally failed

### 3.2.3 Cluster Level Design

#### FlinkDeployment Dual Mode Declaration

The dual modes of FlinkDeployment are:
- Cluster mode: Application mode vs. Session mode
- Cluster deployment mode: Native mode vs. Standalone mode

FlinkDeployment embodies the complete semantics of "cluster as resource" and can be divided into 4 layers:
- **Image layer**: `image + imagePullPolicy + flinkVersion` corresponds to the runtime container environment
- **Resource layer**: `jobManager + taskManager + mode` corresponds to complete cluster resource specifications
- **Network layer**: `serviceAccount + ingress` corresponds to cluster permissions and network configuration
- **Template layer**: `podTemplate + logConfiguration` corresponds to template configuration and log configuration

In addition, the mode configuration corresponds to the `KubernetesDeploymentMode` enum:

```java
public enum KubernetesDeploymentMode {
    NATIVE("Deploys Flink using Flink's native Kubernetes support"),
    STANDALONE("Deploys Flink on-top of kubernetes in standalone mode");
}
```

Among these, NATIVE mode adopts Flink's native Kubernetes integration, leveraging Flink's own resource management capabilities, corresponding to two characteristics:
- Flink framework uses Kubernetes client to create and release resources
- Supports fine-grained resource application and release

NATIVE mode will have Flink create a Kubernetes client to create JobManager's Deployment, and then JobManager will create and manage TaskManager's Pods. This integration means that Flink clusters can directly communicate with Kubernetes and allow it to manage Kubernetes resources, such as dynamically allocating and releasing TaskManager pods.

On the other hand, STANDALONE mode is the traditional approach of using Kubernetes only as an orchestration platform for Flink cluster operation, corresponding to two characteristics:
- Flink cluster doesn't know it's running in a Kubernetes cluster
- Flink framework and job programs have no permission to access the Kubernetes cluster, which improves security

The above are the dual mode declarations for cluster deployment: NATIVE and STANDALONE modes.

Another dual mode worth noting in Flink Operator is that it supports both Application and Session cluster modes for Flink Cluster. The difference between these two is only whether the job (JobSpec) field is declared. When the job field is declared, it corresponds to Application mode, otherwise it's Session mode.

#### FlinkSessionJob Job Submission Declaration

Most configurations of FlinkSessionJob come from AbstractFlinkSpec:

```java
public class FlinkSessionJobSpec extends AbstractFlinkSpec {
    private String deploymentName;  // The only required field
}
```

The only additional field is deploymentName, which corresponds to the name field of FlinkDeployment. The real configuration will be complex, here's a complete example:
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

#### FlinkDeployment Template Design

Configuration inheritance mechanism implemented through `PodTemplateSpec`:
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

This is an example from the official code repository explaining how podTemplate takes effect. The main points are:
- FlinkDeployment itself has a PodTemplate, mainly mounting two emptyDir-type persistent volumes: flink-logs and downloads, used for log collection and saving downloaded job jar packages respectively
- FlinkDeployment's PodTemplate applies to both TaskManager and JobManager, so the fluent sidecar container's role is to collect logs from all components
- JobManager's PodTemplate mainly declares an init container for downloading the job's jar package
- The job.jarURI points to the job jar package address that the JobManager's init container downloads

In summary, FlinkDeployment's podTemplate is global, while if JobManager/TaskManager has podTemplate configuration, it will override or supplement the global configuration.

#### FlinkDeployment Status Design

The status field of FlinkDeployment corresponds to the FlinkDeploymentStatus class, which extends CommonStatus class. Therefore, it also contains the fields jobStatus, error, observedGeneration, and lifecycleState. The corresponding code is as follows:

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

    /** Information about the running cluster. */
    private Map<String, String> clusterInfo = new HashMap<>();

    /** Latest observed status of JobManager deployment. */
    private JobManagerDeploymentStatus jobManagerDeploymentStatus =
            JobManagerDeploymentStatus.MISSING;

    /** Status of the last reconciliation operation. */
    private FlinkDeploymentReconciliationStatus reconciliationStatus =
            new FlinkDeploymentReconciliationStatus();

    /** TaskManager information for scaling sub-resources. */
    private TaskManagerInfo taskManager;
}
```

Among them, clusterInfo corresponds to the cluster's metadata information, such as cluster version, configuration, etc. It is generally a cache of cluster information obtained through Flink REST API. jobManagerDeploymentStatus corresponds to the deployment status of JobManager, with the corresponding code as follows:

```java
public enum JobManagerDeploymentStatus {
    /** JobManager is running and can receive REST API calls. */
    READY,

    /** JobManager is running but cannot yet receive REST API calls. */
    DEPLOYED_NOT_READY,

    /** JobManager process is starting up. */
    DEPLOYING,

    /** JobManager deployment not found, may not have started or was killed by user. */
    // TODO: Currently a mix of SUSPENDED and ERROR states, needs further cleanup
    MISSING,

    /** Deployment is in terminal error state, requires spec modification to continue reconciliation. */
    ERROR;
}
```

reconciliationStatus corresponds to the status of the last reconciliation operation, with the corresponding code as follows:

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

The main design of FlinkDeploymentReconciliationStatus is that it extends the ReconciliationStatus class. The corresponding field information is consistent with the ReconciliationStatus class.

taskManager corresponds to the deployment status of TaskManager, mainly containing two pieces of information: one is labelSelector which corresponds to the TaskManager's labelSelector, and the other is replicas which corresponds to the number of TaskManager replicas.

## 3.3 Kubectl Configuration Code

Both FlinkDeployment and FlinkSessionJob can be viewed using kubectl, for example:
```shell
# flinkdep == FlinkDeployment
kubectl get flinkdep

# sessionjob == FlinkSessionJob
kubectl get sessionjob

# You'll see output:
NAME            JOB STATUS   LIFECYCLE STATE
basic-example   RUNNING      STABLE
```

Let's first explain how to implement the abbreviations for FlinkDeployment and FlinkSessionJob. The corresponding code is:
```java
@Experimental
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonDeserialize()
@Group(CrdConstants.API_GROUP)
@Version(CrdConstants.API_VERSION)
@ShortNames({"sessionjob"}) // This configures the abbreviation
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
@ShortNames({"flinkdep"}) // This configures the abbreviation
public class FlinkDeployment
        extends AbstractFlinkResource<FlinkDeploymentSpec, FlinkDeploymentStatus>
        implements Namespaced {
      // methods
}
```

Also, let's explain how the three columns NAME, JOB STATUS, and LIFECYCLE STATE in the output come from?

The NAME corresponds to the resource's metadata.name, which is the same for both CR and built-in resource objects.
JOB STATUS and LIFECYCLE STATE are implemented by the @PrinterColumn annotation from the Fabric8 generator-annotation library.
JOB STATUS corresponds to the state field in the JobStatus implementation class that corresponds to Flink job status. The corresponding code segment is:
```java
public class JobStatus {
    // other members

    /** Last observed state of the job. */
    @PrinterColumn(name = "Job Status")
    private org.apache.flink.api.common.JobStatus state;

    // other members & methods
}
```

LIFECYCLE STATE corresponds to the lifecycleState in the CommonStatus abstract class in the status. The corresponding code segment is:

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

## 3.4 Diff Mechanism Code

The Diff mechanism is designed to extract information that needs attention and filter out information that doesn't need attention from a large amount of configuration information, and encapsulates some utility methods to extract and generate corresponding information, thereby simplifying the difficulty of comparing before and after configurations.

The specific design references the core implementations of Diff, DiffResult, DiffBuilder, etc. in apache.commons.lang3, but the most core part is mainly rewriting the appendFields method of ReflectiveDiffBuilder. The most core part here is designing the SpecDiff annotation to achieve the above purpose.

### Diff, DiffResult Classes

The Diff class is a single difference wrapper class, with main member variables:
- String fieldName
- T left
- T right
- DiffType type

Where T is a generic placeholder, DiffType is an enum class containing the following three types:
- IGNORE (ignore differences) corresponds to 0
- SCALE (focus on size differences) corresponds to 1
- UPGRADE (focus on version upgrade differences) corresponds to 2

Used to mark how the corresponding field needs attention.

DiffResult is a wrapper class for multiple differences, with main member variables:
- List<Diff<?>> diffList
- T left
- T right
- DiffType type

When multiple Diffs appear, the logic for determining DiffType needs special handling. In one sentence, it takes the maximum. If there's one UPGRADE in the List, then the DiffResult's type is UPGRADE.

### Diffable Interface & SpecDiff Annotation

The Diffable interface is used to declare that instances of this class can be used to compare fields with instances of the same type. This is just an interface.

Classes that need to use the SpecDiff annotation must implement this Diffable interface.

The SpecDiff annotation is designed to identify different ways of comparing each field and whether further processing is needed.

SpecDiff contains two interfaces:
- @interface Config 
- @interface Entry 

The Config interface contains the Entry interface. The Entry interface is mainly used to annotate configuration fields like flink.conf. The Entry interface defines two member functions:
- String prefix()
- DiffType type()

Where prefix is used to filter field prefixes, and type is used to filter configuration types.

Specific example:
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

### DiffBuilder and ReflectiveDiffBuilder

DiffBuilder inherits from the Builder interface in the apache.commons.lang3 package, with the core interface being build.

ReflectiveDiffBuilder and DiffBuilder themselves have corresponding implementations in the apache.commons.lang3 package, but the purpose of overloading here is mainly for ReflectiveDiffBuilder to use SpecDiff annotations for individual logic adaptation.

The main code segments in the Operator are:
```java
var specDiff = new ReflectiveDiffBuilder<>(currentDeploySpec, lastReconciledSpec).build();

boolean specChanged = DiffType.IGNORE != specDiff.getType()
    || reconciliationStatus.getState() == ReconciliationState.UPGRADING;
```

Users can directly think that after calling the build() method, ReflectiveDiffBuilder gets a DiffResult, and here we only judge the type of DiffResult later. (There may be many change points, but here the operator only needs to know whether there are changes in fields of interest).

As for the internal implementation of ReflectiveDiffBuilder's build, it's actually a bunch of Java reflection and value comparison logic, which is more of a utility class.

### ReflectiveDiffBuilder Difference Detection Sequence Diagram

Below is a sequence diagram to detail the difference detection process of ReflectiveDiffBuilder:

{{< mermaid >}}
sequenceDiagram
    participant Reconciler as AbstractFlinkResourceReconciler
    participant ReflectiveBuilder as ReflectiveDiffBuilder
    participant SpecAnalyzer as SpecDiff Annotation Analyzer
    participant DiffBuilder as DiffBuilder
    participant DiffResult as DiffResult Aggregator

    Reconciler->>ReflectiveBuilder: Create instance<br/>ReflectiveDiffBuilder(deploymentMode,<br/>beforeSpec, afterSpec)
    ReflectiveBuilder->>DiffBuilder: Initialize DiffBuilder(before, after)

    Reconciler->>ReflectiveBuilder: Call build() to start difference detection

    loop Traverse all fields
        ReflectiveBuilder->>SpecAnalyzer: Get field SpecDiff annotation
        SpecAnalyzer-->>ReflectiveBuilder: Return annotation config<br/>{value, mode, onNullIgnore}

        alt Field has SpecDiff annotation
            ReflectiveBuilder->>ReflectiveBuilder: Check deployment mode match
            ReflectiveBuilder->>ReflectiveBuilder: Handle null values (onNullIgnore)

            alt Field is Map type and has Config annotation
                ReflectiveBuilder->>SpecAnalyzer: Parse Config.Entry configuration
                SpecAnalyzer-->>ReflectiveBuilder: Return configuration mapping
                loop Traverse each key-value pair in Map
                    ReflectiveBuilder->>DiffBuilder: append(fieldName, oldValue,<br/>newValue, diffType)
                end
            else Regular field
                ReflectiveBuilder->>DiffBuilder: append(fieldName, oldValue,<br/>newValue, annotation.value)
            end
        else No annotation field
            ReflectiveBuilder->>DiffBuilder: append(fieldName, oldValue,<br/>newValue, UPGRADE)
        end
    end

    ReflectiveBuilder->>DiffBuilder: Call build() to generate result
    DiffBuilder->>DiffResult: Create result object (diffs list)
    DiffResult->>DiffResult: Aggregate all DiffTypes<br/>max(ordinal) determines final type

    DiffResult-->>ReflectiveBuilder: Return DiffResult
    ReflectiveBuilder-->>Reconciler: Return final difference result
{{< /mermaid >}}

This sequence diagram shows the complete difference detection process of ReflectiveDiffBuilder:

1. Initialization phase: Reconciler creates ReflectiveDiffBuilder instance, passing in deployment mode and before/after specifications
2. Field traversal: Traverse all fields through reflection, getting SpecDiff annotations for each field
3. Annotation processing: Decide difference detection strategy based on annotation configuration (IGNORE/SCALE/UPGRADE)
4. Special processing: Special handling for Map-type configuration fields, supporting prefix matching
5. Difference collection: Add detected differences to DiffBuilder
6. Result aggregation: Finally aggregate all differences to determine the overall DiffType

This mechanism ensures that Flink Operator can precisely identify configuration changes and decide whether to execute corresponding reconciliation operations accordingly.

### Practical Application Example

Taking FlinkDeploymentSpec as an example:

{{< mermaid >}}
sequenceDiagram
    participant Spec as FlinkDeploymentSpec
    participant Reflective as ReflectiveDiffBuilder
    participant Builder as DiffBuilder

    Spec->>Reflective: Compare two FlinkDeploymentSpec instances
    Note over Spec: Field examples:<br/>- restartNonce (SpecDiff.UPGRADE)<br/>- flinkConfiguration (SpecDiff.Config)<br/>- job.parallelism (SpecDiff.SCALE)

    Reflective->>Reflective: Process restartNonce
    Reflective->>Builder: append("restartNonce", old, new, UPGRADE)

    Reflective->>Reflective: Process flinkConfiguration
    loop Traverse configuration items
        Reflective->>Builder: append("flinkConfiguration.key", oldVal, newVal, IGNORE/SCALE)
    end

    Reflective->>Reflective: Process job.parallelism
    Reflective->>Builder: append("job.parallelism", old, new, SCALE)

    Builder-->>Reflective: Return DiffResult<br/>Type=max(UPGRADE, IGNORE, SCALE) = UPGRADE
{{< /mermaid >}}

This sequence diagram shows how SpecDiff annotations drive the difference detection process at runtime, implementing a declarative difference classification mechanism. 