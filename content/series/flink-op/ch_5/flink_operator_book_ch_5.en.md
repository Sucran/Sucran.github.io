---
title: "Controller Source Code Analysis"
date: 2025-02-24T23:44:58+08:00
draft: false
description: ""
---

## Chapter Overview

This chapter will deeply analyze the source code implementation of two core controllers in FlinkOperator: **FlinkDeploymentController** and **FlinkSessionJobController**. We will focus on analyzing how they implement the Java Operator SDK's Reconciler interface, particularly the implementation logic of the `reconcile` method. Readers may need to review the CRD structure from Chapter 3 and the plugin mechanism from Chapter 4 while reading. For a better reading experience, we will appropriately repeat some core concepts.

## 5.1 Common Design Patterns

### 5.1.1 Observer Pattern

The Observer Pattern is a core design pattern in Flink Kubernetes Operator used for monitoring and observing state changes in Flink applications. This pattern defines a unified observation interface that allows different observers to independently monitor various states of Flink applications, such as job status, cluster health status, snapshot status, etc., and reflect observed state changes to Kubernetes resources.

Both FlinkDeploymentController and FlinkSessionJobController inherit from the Java Operator SDK's Reconciler interface, with the `reconcile` method as the core implementation of reconciliation logic. During the reconciliation process, they typically follow the main sequence of "Observe - Validate - Reconcile", where the observation phase is responsible for collecting current state, the validation phase checks configuration validity, and the reconciliation phase executes necessary operations to reach the desired state.

The core interface of the Observer pattern is Observer, which defines standard methods for observing Flink application states. Here is the source code of the Observer interface:

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

**Observer Class Hierarchy**

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

**Source Code of AbstractFlinkResourceObserver's observe Method**

```java
@Override
public final void observe(FlinkResourceContext<CR> ctx) {
    // Check if the resource is ready to be observed (no observation needed in specific states like suspended applications, upgrade rollback in progress)
    if (!isResourceReadyToBeObserved(ctx)) {
        return;
    }

    // Trigger resource-specific observation logic
    observeInternal(ctx);

    // Reset snapshot triggers
    SnapshotUtils.resetSnapshotTriggers(
            ctx.getResource(), eventRecorder, ctx.getKubernetesClient());
}
```

**Subclass Method Call Relationship Analysis**

The subclass method call relationships in the Observer pattern follow the design philosophy of the Template Method pattern. The entire call chain starts from the `observeInternal` method of `AbstractFlinkResourceObserver` and is dispatched to specific subclass implementations through polymorphism.

1. `observe` - Template method entry (concrete implementation)
     - Standard observation process defined in AbstractFlinkResourceObserver

2. `observeInternal` - CR resource-specific observation
    - AbstractFlinkDeploymentObserver implements methods to handle FlinkDeployment resource observation
    - FlinkSessionJobObserver implements methods to handle FlinkSessionJob resource observation
    - These two subclasses define the observeFlinkCluster abstract method for subclass implementation

3. `observeFlinkCluster` - Cluster mode-specific observation
    - Implemented separately by SessionObserver and ApplicationObserver for Session mode and Application mode cluster observation
    - Session mode: Check REST service availability
    - Application mode: Job status + snapshot status + health check

4. Specialized observer calls (Composite pattern)
    - JobStatusObserver: Job status synchronization
    - SnapshotObserver: Snapshot status management
    - ClusterHealthObserver: Cluster health monitoring

The specific call relationships can be seen from this sequence diagram:

**Observer Call Sequence Diagram**

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
          Note left of Controller: Core Observation Process
          Controller->>Observer: observe(ctx)
          Observer->>AbstractFlinkResourceObserver: observe(ctx)

          alt Resource Ready
              AbstractFlinkResourceObserver->>AbstractFlinkResourceObserver: isResourceReadyToBeObserved(ctx)
              AbstractFlinkResourceObserver->>AbstractFlinkResourceObserver: observeInternal(ctx)

              alt FlinkDeployment Resource
                  AbstractFlinkResourceObserver->>AbstractFlinkDeploymentObserver: observeInternal(ctx)
                  AbstractFlinkDeploymentObserver->>AbstractFlinkDeploymentObserver: observeJmDeployment(ctx)
                  Note right of AbstractFlinkDeploymentObserver: Observe JobManager deployment status

                  alt JobManager Ready
                      AbstractFlinkDeploymentObserver->>AbstractFlinkDeploymentObserver: observeFlinkCluster(ctx)

                      alt Session Mode
                          AbstractFlinkDeploymentObserver->>SessionObserver: observeFlinkCluster(ctx)
                          SessionObserver->>SessionObserver: Check REST service availability
                      else Application Mode
                          AbstractFlinkDeploymentObserver->>ApplicationObserver: observeFlinkCluster(ctx)
                          ApplicationObserver->>JobStatusObserver: observe(ctx)

                          alt Job Found
                              ApplicationObserver->>SnapshotObserver: observeSavepointStatus(ctx)
                              ApplicationObserver->>SnapshotObserver: observeCheckpointStatus(ctx)
                              ApplicationObserver->>ClusterHealthObserver: observe(ctx)
                          end
                      end

                      AbstractFlinkDeploymentObserver->>AbstractFlinkDeploymentObserver: observeClusterInfo(ctx)
                  end
              else FlinkSessionJob Resource
                  AbstractFlinkResourceObserver->>FlinkSessionJobObserver: observeInternal(ctx)
                  FlinkSessionJobObserver->>JobStatusObserver: observe(ctx)

                  alt Job Found
                      FlinkSessionJobObserver->>SnapshotObserver: observeSavepointStatus(ctx)
                      FlinkSessionJobObserver->>SnapshotObserver: observeCheckpointStatus(ctx)
                  end
              end
          end

          AbstractFlinkResourceObserver->>AbstractFlinkResourceObserver: resetSnapshotTriggers(ctx)
          Note right of AbstractFlinkResourceObserver: Reset snapshot triggers
      end
{{< /mermaid >}}

**Specialized Observer Functions:**

1. JobStatusObserver - Job status observer that monitors Flink job state changes, including running status, suspended status, completed status, etc.
   - Use case: Called in ApplicationObserver and FlinkSessionJobObserver to ensure job status synchronization with Kubernetes resource status

2. SnapshotObserver - Snapshot observer that monitors and manages Flink savepoint and checkpoint status
   - Use case: Called in ApplicationObserver and FlinkSessionJobObserver to ensure reliability and state consistency of snapshot operations

3. ClusterHealthObserver - Cluster health observer that evaluates Flink cluster health status and monitors cluster stability and performance metrics
   - Use case: Only called in ApplicationObserver to provide cluster health monitoring for application mode, helping to detect and handle cluster issues promptly

Since job status observer and snapshot observer are called in both ApplicationObserver and FlinkSessionJobObserver as common logic, we will analyze them further.

#### 5.1.1.1 Job Status Observer

The key function of JobStatusObserver is observe, and the source code of this method is as follows:

```java
public boolean observe(FlinkResourceContext<R> ctx) {
    // Get Flink resource object from context
    var resource = ctx.getResource();
    
    // Check if job is in suspended state, return false if so
    // Here we get job state by deserializing the last reconciled spec
    if (resource.getStatus()
                    .getReconciliationStatus()
                    .deserializeLastReconciledSpec()
                    .getJob()
                    .getState()
            == JobState.SUSPENDED) {
        return false;
    }
    
    // Get job status object and previous state for subsequent comparison
    var jobStatus = resource.getStatus().getJobStatus();
    LOG.debug("Observing job status");
    var previousJobStatus = jobStatus.getState();

    try {
        // Call Flink cluster's REST API through FlinkService to get latest job status
        // Use job ID and observation config to query
        var newJobStatusOpt =
                ctx.getFlinkService()
                        .getJobStatus(
                                ctx.getObserveConfig(),
                                JobID.fromHexString(jobStatus.getJobId()));

        if (newJobStatusOpt.isPresent()) {
            // If target job is found, update job status
            // updateJobStatus method will update job name, status, start time, etc.
            updateJobStatus(ctx, newJobStatusOpt.get());
            
            // Check and update stable spec, mark as stable if job is running
            // checkAndUpdateStableSpec will check if job is in stable running state
            ReconciliationUtils.checkAndUpdateStableSpec(resource.getStatus());
            return true;
        } else {
            // If target job is not found, trigger corresponding handling logic
            // onTargetJobNotFound will record events, set error status, and decide whether to suspend based on upgrade mode
            onTargetJobNotFound(ctx);
        }
    } catch (Exception e) {
        // Exception occurred when accessing REST API, will retry later
        LOG.warn("Exception while getting job status", e);
        
        // If job was previously running, now uncertain, change its status to RECONCILING
        // ifRunningMoveToReconciling ensures state consistency, avoiding misjudgment
        ifRunningMoveToReconciling(jobStatus, previousJobStatus);
        
        // If it's a timeout exception, trigger timeout handling callback
        // onTimeout allows subclass to implement specific timeout handling logic
        if (e instanceof TimeoutException) {
            onTimeout(ctx);
        }
    }
    
    // Return false in exception case, indicating observation failure
    return false;
}
```

From the code and comments, we can see that job observation mainly comes from REST API calls, where the return value of the observe method indicates whether job status was obtained. The main core logic is to update the status.jobStatus field of FlinkDeployment or FlinkSessionJob.

---

**Review of Job Status Design from Chapter 3**

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

The JobStatus class defines the status fields during job runtime:
- `jobName`: The name of the job
- `jobId`: Unique identifier of the Flink job
- `state`: Current status of the job, corresponding to Flink's JobStatus enum (such as RUNNING, FINISHED, FAILED, etc.)
- `startTime`: Job startup time
- `updateTime`: Last update time of job status
- `upgradeSavepointPath`: Confirmation information of savepoint path used during upgrade

The reconciliation status ReconciliationStatus corresponds to the standard evolution path of resources from creation to stability:
```
CREATED → DEPLOYED → STABLE
    ↓        ↓
  FAILED  UPGRADING
```

This status path corresponds to the cluster deployment status, and this status flow will be observed and recorded by the controllers corresponding to FlinkDeployment and FlinkSessionJob.

---

If the REST API request finds the target job, the updateJobStatus method will update the fields in the JobStatus class, including job name, status, start time, etc. The ReconciliationUtils.checkAndUpdateStableSpec method updates the reconciliation status, responsible for switching the status from DEPLOYED to STABLE based on job status, or keeping STABLE unchanged.

If the target job is not found, the onTargetJobNotFound method is called, which first uses eventRecorder to send a Warning event for job not found, then divides into two cases:
1. If the resource is FlinkSessionJob type, the job is not in terminal state and upgrade mode is STATELESS, then the job status needs to be modified to SUSPENDED. This way, the next job status observation will exit directly, but during reconciliation, the job will be resubmitted.
2. If the above conditions are not met, then the reconciliation status needs to be set to DEPLOYED, waiting for manual user intervention.
Finally, it will set the error information in the resource's status to: Job Not Found.

If an exception is thrown when querying the job, and the exception is a timeout exception, then there are two cases:
1. If the resource is FlinkDeployment type, then we need to check the cluster status, and ApplicationObserver implements a private subclass ApplicationJobObserver that inherits from JobObserver and implements its onTimeout abstract method. When a timeout exception is thrown, this method will be called, with the specific logic being to check the JobManager's Deployment deployment status.
2. If the resource is FlinkSessionJob type, then timeout situations are not handled.

For exception handling, the unified approach is to check if the job's previous status was RUNNING, and if so, change it to RECONCILING.

Overall, for job status observation, the main purpose is to update job status and reconciliation status. The purpose of modifying job status here is to enable the reconciliation phase to decide what reconciliation operations to perform based on job status and upgrade mode.

#### 5.1.1.2 Snapshot Observer

The key functions of SnapshotObserver are observeSavepointStatus and observeCheckpointStatus, and the source code of these two methods is as follows:

```java
public void observeSavepointStatus(FlinkResourceContext<CR> ctx) {
    LOG.debug("Observing savepoint status");
    // Get Flink resource object and job status information from context
    var resource = ctx.getResource();
    var jobStatus = resource.getStatus().getJobStatus();
    var jobId = jobStatus.getJobId();

    // Check if manual or periodic savepoint is in progress
    // savepointInProgress checks by verifying if savepointInfo.triggerId is empty
    if (SnapshotUtils.savepointInProgress(jobStatus)) {
        // If savepoint is in progress, observe its progress status
        // observeTriggeredSavepoint will call FlinkService.fetchSavepointInfo to get latest status
        // Handle different states like success, failure, in progress, including grace period retry mechanism
        observeTriggeredSavepoint(ctx, jobId);
    }

    // If job is in global terminal state (like FINISHED, FAILED, CANCELED), observe latest checkpoint
    // isJobInTerminalState checks if job has completed or failed
    if (ReconciliationUtils.isJobInTerminalState(resource.getStatus())) {
        // observeLatestCheckpoint gets the last checkpoint information of the job
        // This is important for upgrade recovery and state management
        observeLatestCheckpoint(ctx, jobId);
    }

    // Clean up savepoint history based on configured maximum count and maximum age policies
    // cleanupSavepointHistory will delete expired FlinkStateSnapshot resources
    // Also clean up old savepointHistory arrays and call disposeSavepoint to delete stored data
    cleanupSavepointHistory(ctx);
}

public void observeCheckpointStatus(FlinkResourceContext<CR> ctx) {
    // Check if checkpoint triggering functionality is supported
    // isSnapshotTriggeringSupported verifies if checkpoint functionality is enabled in configuration
    if (!isSnapshotTriggeringSupported(ctx.getObserveConfig())) {
        return;
    }
    
    // Get resource object and job status information
    var resource = ctx.getResource();
    var jobStatus = resource.getStatus().getJobStatus();
    var jobId = jobStatus.getJobId();

    // Check if manual or periodic checkpoint is in progress
    // checkpointInProgress checks by verifying if checkpointInfo.triggerId is empty
    if (SnapshotUtils.checkpointInProgress(jobStatus)) {
        // If checkpoint is in progress, observe its progress status
        // observeTriggeredCheckpoint will call FlinkService.fetchCheckpointInfo to get latest status
        // Handle different states like success, failure, in progress, including grace period retry mechanism
        observeTriggeredCheckpoint(ctx, jobId);
    }
}
```

It should be noted that starting from version 1.10, the completed proposal FLIP-446 added the FlinkStateSnapshot custom resource object for storing savepoint and checkpoint status information. The corresponding SnapshotObserver is only for backward compatibility. In versions before 1.10, savepoint and checkpoint status information was stored in the status.jobStatus field of FlinkDeployment and FlinkSessionJob, while after version 1.10, this part has been decoupled to the FlinkStateSnapshot resource object and its corresponding controller logic, which we will analyze in detail in Chapter 7. Here we don't specifically break down functions related to code marked as @Deprecated, but focus on their core steps.

Essentially, the savepoint observation phase has three steps:
1. Check if a savepoint is being processed, and if so, request REST API to get corresponding savepoint information and update to corresponding status fields
2. Check if the job is in global terminal state, and if so, get the job's latest checkpoint information and update to the savepoint field of corresponding status fields
3. Check savepoint history and clean up expired savepoints

The checkpoint observation phase has two steps:
1. Check if Flink version is greater than 1.17, as REST API checkpoint triggering is only available when version is greater than 1.17
2. Check if a checkpoint is being processed, and if so, request REST API to check corresponding checkpoint information and update to corresponding status fields

### 5.1.2 Reconciliation Pattern - Reconciler

The Reconciliation Pattern (Reconciler Pattern) is the core design pattern of Kubernetes Operator, used to ensure consistency between desired state and actual state. In Flink Kubernetes Operator, the reconciliation pattern is responsible for converting user-defined Flink application configurations into actual Kubernetes resources and continuously monitoring and maintaining the status of these resources. In the reconciliation pattern, the Reconciler interface and its subclasses are key, and we will focus on breaking down these interface designs.

#### 5.1.2.1 Basic Interface and Class Hierarchy

**Reconciler Interface Source Code**

```java
public interface Reconciler<R> {
    /**
     * Reconcile the resource.
     *
     * @param context the context with which the operation is executed
     */
    void reconcile(FlinkResourceContext<R> context) throws Exception;
    
    /**
     * Clean up the resource
     *
     * @param context the context with which the operation is executed
     */
    void cleanup(FlinkResourceContext<R> context);
}
```

**Reconciler Class Hierarchy**

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

Flink Kubernetes Operator adopts the Template Method pattern to design the reconciler architecture.

- `AbstractFlinkResourceReconciler` focuses on handling common reconciliation logic for all resources, while `AbstractJobReconciler` further abstracts template methods for common Flink job lifecycle management on this basis.
- `SessionJobReconciler` implements reconciliation logic related to FlinkSessionJob resources based on `AbstractFlinkResourceReconciler`.
- `ApplicationReconciler` handles reconciliation logic related to jobs in Application mode FlinkDeployment resources based on `AbstractFlinkResourceReconciler`.
- `SessionReconciler` handles reconciliation logic related to jobs in Session mode FlinkDeployment resources.

It should be noted that AbstractFlinkResourceReconciler abstracts template methods for common lifecycle management including jobs in Application mode FlinkDeployment and jobs corresponding to FlinkSessionJob. The reconciliation logic for Session mode FlinkDeployment corresponds to cluster reconciliation logic and doesn't need to handle lifecycle management of jobs within the cluster, so the class inheritance relationship is structured this way.

#### 5.1.2.2 Common Reconciliation Flow

The core reconciliation flow is defined in the `reconcile` template method of `AbstractFlinkResourceReconciler`, ensuring consistency of the reconciliation process. The specific brief flow diagram is as follows:

**AbstractFlinkResourceReconciler's reconcile Flow Diagram**

{{< mermaid >}}
flowchart LR
    A["Reconciliation Entry"] --> B{"Ready?"}
    B -- No --> C["Exit"]
    B -- Yes --> D{"First Deployment?"}
    D -- Yes --> E["Deployment Flow"]
    D -- No --> F{"Need Rollback?"}
    F -- Yes --> G["Prepare Rollback"]
    F -- No --> H{"Spec Change?"}
    H -- Yes --> I["Cluster Scaling"]
    H -- No --> J["Other Change Handling"]
    I --> K["Spec Change Processing"]

    style A fill:#e1f5fe
    style B fill:#fff3e0
    style C fill:#ffcdd2
    style E fill:#fce4ec
    style G fill:#fff8e1
    style I fill:#ff9800
    style J fill:#e0f2f1
{{< /mermaid >}}

AbstractFlinkResourceReconciler defines a common reconciliation flow that follows these steps:
1. **Ready Check**: Check if ready for reconciliation through `readyToReconcile`
2. **Deployment Flow**: Execute specific cluster deployment logic through `deploy`
3. **Scaling Processing**: Handle cluster scaling through `scale`
4. **Change Processing**: Handle resource configuration changes through `reconcileSpecChange`
5. **Other Reconciliation**: Handle other types of changes through `reconcileOtherChanges`

Cluster scaling operations are implemented in the scale function, which is mainly handled by FlinkService, which we will cover in detail in Chapter 7. In the reconciliation process, we won't explain too much about how to handle rollbacks. Since the rollback process is essentially a type of reconciliation, readers only need to understand the reconciliation logic to understand the rollback logic. Also, in the flow diagram, if cluster scaling operations are needed and completed, then there's no need to handle spec change processing anymore, because the reconciliation needed for the changes has been completed.

The part that determines whether resource changes have occurred is relatively simple, mainly using the Diff mechanism's ReflectiveDiffBuilder difference detection mentioned in Chapter 3. Readers can refer to the previous chapters to see the specific sequence diagram. Briefly, this mechanism is ultimately used to identify the processing method for changes. The DiffType enum class defines 4 specific change types, with the following code:

```java
@Experimental
public enum DiffType {

    /** Ignorable spec changes */
    IGNORE,
    /** Scalable spec changes */
    SCALE,
    /** Upgradable spec changes */
    UPGRADE,
    /** Complete redeployment from new state */
    SAVEPOINT_REDEPLOY;

    /**
     * Aggregate a set of {@link DiffType} into a type that can minimally cover all differences.
     * We rely on the fact that enum values are sorted in this way.
     *
     * @param diffs Collection of differences
     * @return Aggregated {@link DiffType}
     */
    public static DiffType from(Collection<DiffType> diffs) {
        return diffs.stream().max(Comparator.comparing(DiffType::ordinal)).orElse(DiffType.IGNORE);
    }
}
```

We can find from the corresponding enum values which places in the code use the corresponding enum values with the @SpecDiff annotation, and provide the following table:

| DiffType | Usage Scenario | Usage Description |
|----------|----------------|-------------------|
| **IGNORE** | Ignorable spec changes that don't require special handling | Mainly used for some configuration changes in `flinkConfiguration` config fields and some config changes in jobSpec |
| **SCALE** | Scalable spec changes handled through scaling operations | Applicable to fields like `replicas`, `parallelism`, and configurations with `pipeline.jobvertex-parallelism-overrides` prefix in `flinkConfiguration`, only effective in NATIVE deployment mode |
| **UPGRADE** | Upgradable spec changes that require redeployment | This is the most commonly used type, applicable to most fields without `@SpecDiff` annotation and annotation fields with mismatched modes, including image versions, resource configurations, etc. |
| **SAVEPOINT_REDEPLOY** | Complete redeployment from new state required | Mainly used for `savepointRedeployNonce` field, by modifying this value to force trigger redeployment from savepoint |

After identifying the scope of changes, when to stop changes and how to identify that changes are complete, some fields in ReconciliationStatus are used, including lastReconciledSpec and state. The state is defined by the ReconciliationState enum class, with the following code:

```java
/** Current state of reconciliation */
public enum ReconciliationState {
    /** Currently deployed lastReconciledSpec */
    DEPLOYED,
    /** Spec is being upgraded */
    UPGRADING,
    /** Rolling back to lastStableSpec */
    ROLLING_BACK,
    /** Rolled back to lastStableSpec */
    ROLLED_BACK
}
```

Since the latest state of the current resource can be obtained in each reconciliation, we only need to judge the changes in lastReconciledSpec to identify whether the changes are complete. Additionally, by judging whether the current state field is upgrading or rolling back, we can determine whether to stop changes.

**AbstractFlinkResourceReconciler Reconciliation Flow Sequence Diagram**

Based on source code analysis, the `reconcile` method of `AbstractFlinkResourceReconciler` adopts the Template Method pattern, defining a unified reconciliation flow. The following is a simplified sequence diagram showing how abstract methods call specific implementations of subclasses:

{{< mermaid >}}
  sequenceDiagram
      participant Controller
      participant AbstractFlinkResourceReconciler
      participant AbstractJobReconciler
      participant SessionReconciler
      participant ApplicationReconciler
      participant SessionJobReconciler
      participant FlinkService

  Note over Controller, FlinkService: Reconciliation Flow Start
  Controller->>AbstractFlinkResourceReconciler: reconcile(ctx)

  Note over AbstractFlinkResourceReconciler: 1. Check Ready State
  AbstractFlinkResourceReconciler->>SessionReconciler: readyToReconcile(ctx)
  AbstractFlinkResourceReconciler->>AbstractJobReconciler: readyToReconcile(ctx)
  AbstractFlinkResourceReconciler->>SessionJobReconciler: readyToReconcile(ctx)

  alt First Deployment
      Note over AbstractFlinkResourceReconciler: 2. First Deployment
      AbstractFlinkResourceReconciler->>SessionReconciler: deploy(ctx, spec, deployConfig, savepoint, false)
      SessionReconciler->>FlinkService: submitSessionCluster(deployConfig)
      FlinkService-->>SessionReconciler: Deployment Complete

      AbstractFlinkResourceReconciler->>ApplicationReconciler: deploy(ctx, spec, deployConfig, savepoint, false)
      ApplicationReconciler->>FlinkService: submitApplicationCluster(deployConfig, savepoint)
      FlinkService-->>ApplicationReconciler: Deployment Complete

      AbstractFlinkResourceReconciler->>SessionJobReconciler: deploy(ctx, spec, deployConfig, savepoint, false)
      SessionJobReconciler->>FlinkService: submitJobToSessionCluster(deployConfig, savepoint)
      FlinkService-->>SessionJobReconciler: Deployment Complete
  else Non-First Deployment
      Note over AbstractFlinkResourceReconciler: 3. Analyze Spec Differences
      AbstractFlinkResourceReconciler->>AbstractFlinkResourceReconciler: Detect Spec Changes

      alt Non-Upgrade Changes
          AbstractFlinkResourceReconciler->>FlinkService: scale(ctx, deployConfig)
      else Upgrade Processing Required
          Note over AbstractJobReconciler: Job Resource Upgrade Processing
          AbstractFlinkResourceReconciler->>AbstractJobReconciler: reconcileSpecChange(...)
          Note right of AbstractJobReconciler: See 5.1.2.3\nUpgrade Mode Flow Diagram

          alt Application Mode
              AbstractJobReconciler->>ApplicationReconciler: cancelJob(ctx, suspendMode)
              ApplicationReconciler->>FlinkService: cancelJob(jobId, cancelConfig)
              AbstractJobReconciler->>ApplicationReconciler: restoreJob(...)
              ApplicationReconciler->>FlinkService: submitApplicationCluster(...)
          else SessionJob Mode
              AbstractJobReconciler->>SessionJobReconciler: cancelJob(ctx, suspendMode)
              SessionJobReconciler->>FlinkService: cancelSessionJob(jobId, cancelConfig)
              AbstractJobReconciler->>SessionJobReconciler: restoreJob(...)
              SessionJobReconciler->>FlinkService: submitJobToSessionCluster(...)
          else Session Mode
              AbstractFlinkResourceReconciler->>SessionReconciler: reconcileSpecChange(...)
              SessionReconciler->>FlinkService: deleteClusterDeployment()
              SessionReconciler->>FlinkService: submitSessionCluster(deployConfig)
          end
      end

      Note over AbstractFlinkResourceReconciler: 4. Handle Other Changes
      AbstractFlinkResourceReconciler->>SessionReconciler: reconcileOtherChanges(ctx)
      AbstractFlinkResourceReconciler->>ApplicationReconciler: reconcileOtherChanges(ctx)
      AbstractFlinkResourceReconciler->>SessionJobReconciler: reconcileOtherChanges(ctx)
  end

  AbstractFlinkResourceReconciler-->>Controller: Reconciliation Complete
{{< /mermaid >}}

**Key Call Chain Analysis:**

1. **readyToReconcile()**: 
  - FlinkDeployment resource (Application cluster mode): If first deployment, directly start reconciliation logic; if not first, check if currently restoring from savepoint
  - FlinkDeployment resource (Session cluster mode): Always directly start reconciliation logic
  - FlinkSessionJob resource: Check if Session mode cluster is ready

2. **deploy()**: 
  - FlinkDeployment resource (Application cluster mode): Create Application cluster through FlinkService calling submitApplicationCluster()
  - FlinkDeployment resource (Session cluster mode): Create Session cluster through FlinkService calling submitSessionCluster()
  - FlinkSessionJob resource: Submit job to Session cluster through FlinkService calling submitJobToSessionCluster()

> **Note**: FlinkService abstracts cluster deployment related logic, which we will focus on in Chapter 6.

3. **reconcileSpecChange()**: 
  - FlinkDeployment resource (Application cluster mode): Handle job state transitions and upgrade strategies, redeploy, restore jobs, or suspend jobs based on situation
  - FlinkDeployment resource (Session cluster mode): Delete old cluster and redeploy due to cluster deployment configuration changes
  - FlinkSessionJob resource: Handle job state transitions and upgrade strategies, redeploy, restore jobs, or suspend jobs based on situation

4. **reconcileOtherChanges()**: 
  - FlinkDeployment resource (Application cluster mode): Trigger periodic/manual snapshots (savepoint/checkpoint), check cluster health and recovery/restart, and restart jobs on failure according to configuration
  - FlinkDeployment resource (Session cluster mode): Check if deployment recovery is needed
  - FlinkSessionJob resource: Trigger periodic/manual snapshots (savepoint/checkpoint), and restart jobs on failure according to configuration

5. **cancelJob()**: 
  - FlinkDeployment resource (Application cluster mode): Cancel Application mode jobs
  - FlinkSessionJob resource: Cancel Session mode jobs

The different resources in reconcileSpecChange and reconcileOtherChanges have common logic because AbstractJobReconciler abstracts the reconciliation logic for job lifecycle management. We will expand on the job resource reconciliation logic for corresponding resources in sections 5.2 and 5.3 respectively. Readers only need to have an intuitive understanding here.

### 5.1.3 Status Recorder - StatusRecorder 

StatusRecorder adopts a state cache + optimistic locking design pattern, using ConcurrentHashMap local cache to store resource states and using modified optimistic locking mechanism to ensure eventual consistency of state updates. At the same time, StatusRecorder also integrates the FlinkResourceListener plugin mechanism introduced in Chapter 4, triggering custom listeners for extended processing when state changes occur.

---

**Review of Chapter 4 Plugin Mechanism**

FlinkOperator adopts a plugin architecture design. Through Java's SPI (Service Provider Interface) mechanism, the system can dynamically discover and load extension components at runtime. Flink Operator provides two types of extension plugins: validators and listeners. Validators are used to validate resource values, while listeners are used to listen to events and handle them. The FlinkResourceListener plugin mechanism here corresponds to listeners. This is FlinkOperator's event listening plugin, which triggers custom listeners for extended processing when state changes occur.

---

**Usage Scenario Analysis**

In FlinkDeploymentController and FlinkSessionJobController, StatusRecorder plays an important role at key nodes of the reconciliation lifecycle:

1. State Recovery: Update resource state from cache, reducing the possibility of state inconsistency
2. State Caching: Cache state changes, avoiding frequent Kubernetes API calls
3. State Synchronization: Batch update cached states to Kubernetes

#### Typical Sequence Diagram

> **Note**: The actual implementation includes more boundary handling logic.

{{< mermaid >}}
sequenceDiagram
    participant Controller as Controller
    participant StatusRecorder as StatusRecorder
    participant Cache as State Cache
    participant K8sAPI as Kubernetes API
    participant FlinkResourceListener as FlinkResourceListener

    Note over Controller, FlinkResourceListener: State Management and Listener Triggering in Reconciliation Flow

    Controller->>StatusRecorder: updateStatusFromCache(flinkApp)
    StatusRecorder->>Cache: Get Cached State
    Cache-->>StatusRecorder: Return Cached State
    StatusRecorder->>Controller: Update Resource State
    alt First Reconciliation and State is CREATED
        StatusRecorder->>FlinkResourceListener: statusUpdateListener.accept(resource, status)
        Note right of FlinkResourceListener: Trigger based on resource type:<br/>- onDeploymentStatusUpdate()<br/>- onSessionJobStatusUpdate()
    end

    Note over Controller: Execute Reconciliation Logic
    Controller->>Controller: Observe, Validate, Reconcile

    Controller->>StatusRecorder: patchAndCacheStatus(flinkApp, client)
    StatusRecorder->>StatusRecorder: Compare State Changes
    alt State Has Changes
        StatusRecorder->>K8sAPI: Update State Using Optimistic Locking Mechanism
        K8sAPI-->>StatusRecorder: Update Result
        StatusRecorder->>Cache: Update Cache
        StatusRecorder->>FlinkResourceListener: statusUpdateListener.accept(resource, prevStatus)
        Note right of FlinkResourceListener: Build StatusUpdateContext<br/>Trigger Corresponding Listener Methods
    else No State Changes
        StatusRecorder->>StatusRecorder: Skip Update
    end
{{< /mermaid >}}

In the diagram, StatusRecorder is not only responsible for state caching and updating, but also triggers the FlinkResourceListener plugin mechanism introduced in Chapter 4 through `statusUpdateListener`. When state changes occur, it builds `StatusUpdateContext` and calls all registered listener plugins, implementing extended processing for state changes.

#### Core Function Analysis

**1. updateStatusFromCache - Update State from Cache**

```java
public void updateStatusFromCache(CR resource) {
    var key = ResourceID.fromResource(resource);
    var cachedStatus = statusCache.get(key);
    if (cachedStatus != null) {
        // Restore state from cache to resource object
        resource.setStatus(
                (STATUS)
                        objectMapper.convertValue(
                                cachedStatus, resource.getStatus().getClass()));
    } else {
        // Initialize cache, record current state
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

At the beginning of reconciliation, restore resource state from local cache, reducing the possibility of state inconsistency and avoiding state inconsistency issues caused by JOSDK cache mechanism. For resources in first reconciliation and CREATED state, it also triggers the state update callback of FlinkResourceListener plugin.

**2. patchAndCacheStatus - Patch Update and Cache State**

> **Note**: This is a simplified version. The actual implementation includes optimistic lock conflict handling and 3 retry mechanisms.
```java
@SneakyThrows
public void patchAndCacheStatus(CR resource, KubernetesClient client) {
    ObjectNode newStatusNode =
            objectMapper.convertValue(resource.getStatus(), ObjectNode.class);
    var resourceId = ResourceID.fromResource(resource);
    ObjectNode previousStatusNode = statusCache.get(resourceId);

    // Compare if state has changed
    if (newStatusNode.equals(previousStatusNode)) {
        LOG.debug("No status change.");
        return;
    }

    // Update state using optimistic locking mechanism
    var prevStatus = (STATUS) objectMapper.convertValue(previousStatusNode, statusClass);
    
    Exception err = null;
    for (int i = 0; i < 3; i++) {
        // Retry 3 times, 1 second interval each time
        try {
            // Use lockResourceVersion() for optimistic lock update
            client.resource(resource).lockResourceVersion().updateStatus();
        statusCache.put(resourceId, newStatusNode);
        notifyListeners(resource, prevStatus);
    } catch (KubernetesClientException e) {
        err = e;
        LOG.warn("Status update failed, will retry", e);
    }
}
```

Use modified optimistic locking mechanism to update state changes to Kubernetes while updating local cache. Through `lockResourceVersion()` and retry mechanism, ensure successful state updates even when underlying resource specs are updated simultaneously. After successful state update, it triggers all registered FlinkResourceListener plugins through the `notifyListeners` method, implementing extended processing for state changes.

**Technical Details**:
- **Local Cache**: Use `ConcurrentHashMap<ResourceID, ObjectNode> statusCache` to store resource states
- **Optimistic Locking Mechanism**: Implemented through `lockResourceVersion()`, automatically retry on 409 conflicts
- **Retry Strategy**: Maximum 3 retries, 1 second interval each time, ensuring reliability of state updates

### 5.1.4 Resource Context Factory - FlinkResourceContextFactory 

FlinkResourceContextFactory adopts a factory pattern design, creating dedicated processing contexts for different types of Flink resources and creating corresponding FlinkService implementations based on deployment modes.

**Usage Scenario Analysis**

In FlinkDeploymentController and FlinkSessionJobController, FlinkResourceContextFactory is responsible for building resource processing environments:

1. Context Creation: Create dedicated processing contexts for current resources
2. Service Factory: Create corresponding FlinkService based on deployment mode (Native/Standalone)
3. Configuration Management: Provide resource-specific configuration management functionality

---

**Review of Chapter 3 Content**

NATIVE mode adopts Flink's native Kubernetes integration, utilizing Flink's own resource management capabilities, corresponding to two characteristics:
- Flink framework uses Kubernetes client to create and release resources
- Supports fine-grained resource application and release

NATIVE mode will use the Kubernetes client created by Flink to create JobManager's Deployment, then JobManager will create and manage TaskManager's Pods. This integration means Flink clusters can directly communicate with Kubernetes and allow it to manage Kubernetes resources, such as dynamically allocating and releasing TaskManager pods.

Additionally, STANDALONE mode is the traditional approach that only uses Kubernetes as an orchestration platform for running Flink clusters, corresponding to two characteristics:
- Flink cluster is unaware that it's running in a Kubernetes cluster
- Neither Flink framework nor job programs have permission to access the Kubernetes cluster, which improves security

> **Note**: Deployment modes and detailed working principles and configuration methods of FlinkService will be explained in depth in the next chapter. Readers can temporarily understand FlinkService as the integration of corresponding calling code paths for creating and managing different deployment modes of Flink.

---

#### Typical Sequence Diagram

{{< mermaid >}}
sequenceDiagram
    participant Controller as Controller
    participant ContextFactory as FlinkResourceContextFactory
    participant Context as FlinkResourceContext
    participant FlinkService as FlinkService

    Note over Controller, FlinkService: Resource Context Creation Flow

    Controller->>ContextFactory: getResourceContext(flinkApp, josdkContext)
    ContextFactory->>ContextFactory: Create Context Based on Resource Type
    alt FlinkDeployment
        ContextFactory->>Context: new FlinkDeploymentContext()
    else FlinkSessionJob
        ContextFactory->>Context: new FlinkSessionJobContext()
    end
    ContextFactory-->>Controller: Return Resource Context

    Controller->>Context: getFlinkService()
    Context->>ContextFactory: getFlinkService(ctx)
    ContextFactory->>ContextFactory: Select Service Based on Deployment Mode
    alt Native Mode
        ContextFactory->>FlinkService: new NativeFlinkService()
    else Standalone Mode
        ContextFactory->>FlinkService: new StandaloneFlinkService()
    end
    ContextFactory-->>Context: Return FlinkService
    Context-->>Controller: Return FlinkService
{{< /mermaid >}}

#### Core Function Analysis

**1. getResourceContext - Create Resource Context**

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

Create corresponding dedicated contexts based on resource type (FlinkDeployment or FlinkSessionJob), providing customized processing environments for each resource type, including metrics collection, configuration management, and service factory.

**2. getFlinkService - Create Flink Service**

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

Dynamically create corresponding FlinkService implementations based on resource deployment mode (Native or Standalone), providing specialized service logic for different deployment modes. We will cover this in detail in the next chapter.

### 5.1.5 Operator Health Monitoring Pattern - CanaryResourceManager

The Operator Health Monitoring pattern is a special mechanism in Flink Kubernetes Operator used to monitor the health status of the Operator itself. This pattern detects Operator responsiveness and processing performance by deploying lightweight "canary resources", ensuring the Operator can work normally.

In Flink Kubernetes Operator, CanaryResourceManager implements a special "health monitoring" mechanism, which is different from traditional canary upgrades. The canary resources here are mainly used for **Operator health status detection** rather than functional testing, and are a lightweight Operator health status monitoring mechanism.

The design intent and problems solved in the Operator health monitoring pattern mainly include the following points:

1. Operator Responsiveness Monitoring: By deploying special "virtual" resources (canary resources), monitor whether the Operator can respond to and handle resource changes within the specified time, ensuring the Operator's reconciliation loop works normally.

2. Early Problem Detection: When the Operator experiences performance degradation, resource contention, or deadlock issues, canary resources cannot be reconciled within the expected time, triggering health check failures and achieving early problem detection.

3. Automated Fault Recovery: When canary resource reconciliation times out (default 1 minute), the Operator will be marked as unhealthy, triggering Kubernetes' automatic restart mechanism and achieving automated fault recovery.

4. Multi-Namespace Monitoring: Support deploying canary resources in multiple namespaces, achieving comprehensive monitoring of Operator working status in different namespaces.

The overall design characteristics are as follows:

- Lightweight Design: Canary resources don't need to define complete specs, won't start any Pods or consume cluster resources, purely used for health status verification
- Smart Identification: Identify canary resources through special label `flink.apache.org/canary: "true"`
- Timed Detection: Adopt timed task mechanism, regularly check resource version number changes, verify if reconciliation is normal
- Configurable Timeout: Configure timeout time through `kubernetes.operator.health.canary.resource.timeout` (default 1 minute)

CanaryResourceManager adopts a resource status monitoring + timed task design pattern, monitoring Operator processing capabilities by regularly checking canary resource reconciliation status.

**Usage Scenario Analysis**

In FlinkDeploymentController and FlinkSessionJobController, CanaryResourceManager focuses on canary resource lifecycle management:

1. Resource Identification: Check if it's a canary resource, if so, perform special handling
2. Status Monitoring: Regularly verify canary resource reconciliation status
3. Resource Cleanup: Clean up canary resource status

> **Note**: Canary resources are identified through `flink.apache.org/canary: "true"` in metadata.labels.

#### Typical Sequence Diagram

 {{< mermaid >}}
  sequenceDiagram
      participant Controller as Controller
      participant CanaryManager as Canary Manager
      participant K8sAPI as Kubernetes API
      participant Timer as Timer Thread Pool

  Note over Controller, Timer: Operator Health Monitoring Resource Lifecycle Management

  rect rgb(240, 248, 255)
      Note left of Controller: First Reconciliation Phase
      Controller->>CanaryManager: handleCanaryResourceReconciliation(resource, client)
      Note right of CanaryManager: 1. Check resource label flink.apache.org/canary=true

      CanaryManager->>CanaryManager: isCanaryResource(resource)
      Note right of CanaryManager: 2. Verify canary identifier in metadata.labels

      alt Confirmed as Canary Resource
          CanaryManager->>CanaryManager: Initialize Canary State
          Note right of CanaryManager: 3. Create CanaryResourceState object<br/>Record current resource version number

          CanaryManager->>K8sAPI: Update restartNonce field
          Note left of K8sAPI: 4. Trigger resource restart<br/>spec.restartNonce++

          CanaryManager->>Timer: Schedule health check task
          Note left of Timer: 5. Schedule timed task<br/>Execute after default 30 seconds
      end
  end

  Note over Timer: === Timed Health Check Phase ===

  rect rgb(255, 245, 240)
      Timer->>CanaryManager: checkHealth(resourceId, client)
      Note right of CanaryManager: 6. Timed trigger status check

      CanaryManager->>CanaryManager: Compare resource version numbers
      Note right of CanaryManager: 7. Compare metadata.generation<br/>with previousGeneration

      alt Version Updated (Reconciliation Normal)
          CanaryManager->>CanaryManager: Mark Healthy Status
          Note left of CanaryManager: 8. crs.isHealthy = true<br/>Record "Canary deployment healthy"
      else Version Unchanged (Reconciliation Abnormal)
          CanaryManager->>CanaryManager: Mark Abnormal Status
          Note left of CanaryManager: 9. crs.isHealthy = false<br/>Record error logs
      end

      CanaryManager->>Timer: Reschedule next check
      Note left of Timer: 10. Loop execution<br/>Continuous monitoring
  end

        Note over CanaryManager: The entire chain forms closed-loop monitoring<br/>Ensuring Operator health status monitoring capability
  {{< /mermaid >}}

#### Core Function Analysis

**1. handleCanaryResourceReconciliation - Handle Canary Resource Reconciliation**

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

**Function Purpose**: Identify and handle canary resources, record resource status and schedule status monitoring tasks. If it's the first reconciliation, it will update resource specs and set timed status monitoring, ensuring the Operator's health status monitoring mechanism works normally.

**2. checkHealth - Status Monitoring**

```java
@VisibleForTesting
protected void checkHealth(ResourceID resourceID, KubernetesClient client) {
    CanaryResourceState crs = canaryResources.get(resourceID);
    if (crs == null) {
        LOG.info("Canary resource {} not found. Stopping health checks", resourceID);
        return;
    }

    // Check if reconciliation has occurred since last spec update
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

    // Update spec and reschedule health check
    updateSpecAndScheduleHealthCheck(resourceID, crs, client);
}
```

**Function Purpose**: Regularly check canary resource reconciliation status, judge Operator health status by comparing resource version numbers. If reconciliation is normal, mark as healthy; otherwise, mark as unhealthy and record error logs.

## 5.2 FlinkDeployment Controller Source Code Analysis

### 5.2.1 Core Member Variables and Methods

FlinkDeploymentController is the core controller in FlinkOperator responsible for managing FlinkDeployment resources, implementing multiple interfaces from Java Operator SDK. Here are its constructor and core member variables:

```java
public class FlinkDeploymentController
        implements Reconciler<FlinkDeployment>,
                ErrorStatusHandler<FlinkDeployment>,
                EventSourceInitializer<FlinkDeployment>,
                Cleaner<FlinkDeployment> {
    
    // Core member variables
    private final Set<FlinkResourceValidator> validators;                    // Resource validator collection
    private final FlinkResourceContextFactory ctxFactory;                   // Resource context factory
    private final ReconcilerFactory reconcilerFactory;                      // Reconciler factory
    private final FlinkDeploymentObserverFactory observerFactory;           // Observer factory
    private final StatusRecorder<FlinkDeployment, FlinkDeploymentStatus> statusRecorder;  // Status recorder
    private final EventRecorder eventRecorder;                              // Event recorder
    private final CanaryResourceManager<FlinkDeployment> canaryResourceManager;  // Canary resource manager
}
```

**Member Variable Description**:
- **validators**: Validation plugins for validating FlinkDeployment resources
- **ctxFactory**: Resource context factory responsible for creating FlinkDeployment processing contexts
- **reconcilerFactory**: Reconciler factory that creates corresponding reconcilers based on deployment mode
- **observerFactory**: Observer factory responsible for creating and managing FlinkDeployment observers
- **statusRecorder**: Status recorder managing FlinkDeployment status caching and updates
- **eventRecorder**: Event recorder responsible for recording and triggering Kubernetes events
- **canaryResourceManager**: Canary resource manager handling special logic for canary resources

#### Class Diagram

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

We explained these corresponding functions in Chapter 2. The main logic of FlinkDeploymentController is to implement methods of these interfaces:
- Reconciler: Core interface of Java Operator SDK, defining the reconcile method for reconciliation logic
- ErrorStatusHandler: Error status handling interface, handling exceptions during reconciliation with updateErrorStatus method
- EventSourceInitializer: Event source initialization interface, setting up event listening with prepareEventSources method
- Cleaner: Resource cleanup interface, handling resource deletion logic with cleanup method

These methods all have a common characteristic: they receive a Context type parameter josdkContext from Java Operator SDK. In Flink Operator code, this parameter is mainly used to get secondary resources or get Kubernetes clients. As readers can see from section 5.1.4, the `getResourceContext` method in the resource context factory class creates corresponding dedicated contexts based on resource type (FlinkDeployment or FlinkSessionJob), and this parameter is also used here. Readers can also see `ctx.getJosdkContext()` in the Controller code, which corresponds to the use of this parameter.

### 5.2.2 Reconciliation Preparation Phase

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {

    // 1. Canary resource handling: if it's a canary resource, return directly without update
    if (canaryResourceManager.handleCanaryResourceReconciliation(
            flinkApp, josdkContext.getClient())) {
        return UpdateControl.noUpdate();
    }

    LOG.debug("Starting reconciliation");

    // 2. Status recovery: update resource status from cache, reduce possibility of status inconsistency. If not in cache, add to cache
    statusRecorder.updateStatusFromCache(flinkApp);
    
    // 3. Resource cloning: create a copy of current resource for subsequent status comparison
    FlinkDeployment previousDeployment = ReconciliationUtils.clone(flinkApp);
    
    // 4. Context creation: create dedicated processing context for current resource
    var ctx = ctxFactory.getResourceContext(flinkApp, josdkContext);

    // 5. Version validation: check if Flink version is supported, if not trigger event and exit
    if (!ValidatorUtils.validateSupportedVersion(ctx, eventRecorder)) {
        return UpdateControl.noUpdate();
    }

    // 6. Observation phase: start observing cluster status
}
```

**Core Steps of Reconciliation Preparation Phase**

1. Canary resource check: Prioritize handling canary resources, return directly if it's a canary resource
2. Status recovery: Recover resource status from local cache, avoid status inconsistency caused by JOSDK cache
3. Resource backup: Create a copy of current resource for subsequent status change comparison
4. Context construction: Create processing context containing Kubernetes client, configuration and other information
5. Version validation: Validate Flink version compatibility, ensure Operator can handle this version

The resource backup here just clones the object again, with no special logic. Except for version validation, other steps have been mentioned in previous sections. Readers can refer to the previous introduction by looking at the functions directly. We will focus on the version compatibility relationship between FlinkOperator and Flink:

**FlinkOperator and Flink Version Compatibility Relationship**

According to official documentation and source code analysis, FlinkOperator's compatibility support for Flink versions is as follows:

| Flink Version | Support Status | Notes |
|---------------|----------------|-------|
| v1_13 | ❌ Not Supported | No longer supported since Operator 1.7 |
| v1_14 | ❌ Not Supported | No longer supported since Operator 1.7 |
| v1_15 | ⚠️ Deprecated | Deprecated since Operator 1.10 |
| v1_16 | ✅ Supported | Currently supported |
| v1_17 | ✅ Supported | Currently supported |
| v1_18 | ✅ Supported | Currently supported |
| v1_19 | ✅ Supported | Currently supported |
| v1_20 | ✅ Supported | Currently supported |

**Version Validation Code Implementation**

```java
public static boolean validateSupportedVersion(
        FlinkResourceContext<?> ctx, EventRecorder eventRecorder) {
    // Get current resource's Flink version
    var version = ctx.getFlinkVersion();
    
    // Check if version is supported: version is not null and greater than or equal to v1_15
    if (!FlinkVersion.isSupported(version)) {
        // Trigger unsupported version event warning
        eventRecorder.triggerEvent(
                ctx.getResource(),
                EventRecorder.Type.Warning,
                EventRecorder.Reason.UnsupportedFlinkVersion,
                EventRecorder.Component.Operator,
                "Flink version " + version + " is not supported by this operator version",
                ctx.getJosdkContext().getClient());
        return false; // Return validation failure
    }
    return true; // Return validation success
}
```

**Version Support Judgment Logic**

```java
public static boolean isSupported(FlinkVersion version) {
    // Only support if version is not null and greater than or equal to v1_15
    return version != null && version.isEqualOrNewer(FlinkVersion.v1_15);
}
```

**Version Comparison Method**

```java
public boolean isEqualOrNewer(FlinkVersion otherVersion) {
    // Compare versions through enum's ordinal() value
    return this.ordinal() >= otherVersion.ordinal();
}
```

### 5.2.3 Observation Phase

In the reconcile method, the observation phase code implementation is as follows:

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {
    // ... Previous preparation phase code ...
    
    try {
        // Observation phase: Get or create observer, then execute observation logic
        observerFactory.getOrCreate(flinkApp).observe(ctx);
        
        // ... Subsequent validation and reconciliation logic ...
    } catch (Exception e) {
        // ... Exception handling ...
    }
    return ReconciliationUtils.toUpdateControl(
                ctx.getOperatorConfig(), flinkApp, previousDeployment, true);
}
```

**ObserverFactory Design Pattern**

FlinkDeploymentObserverFactory adopts a factory pattern + cache design, dynamically creating corresponding Observer instances based on FlinkDeployment's running mode and deployment mode.

```java
public class FlinkDeploymentObserverFactory {
    private final EventRecorder eventRecorder;
    // Use ConcurrentHashMap to cache created Observer instances
    private final Map<Tuple2<Mode, KubernetesDeploymentMode>, Observer<FlinkDeployment>> observerMap;

    public FlinkDeploymentObserverFactory(EventRecorder eventRecorder) {
        this.eventRecorder = eventRecorder;
        this.observerMap = new ConcurrentHashMap<>();
    }

    public Observer<FlinkDeployment> getOrCreate(FlinkDeployment flinkApp) {
        // Create cache key based on running mode and deployment mode
        return observerMap.computeIfAbsent(
                Tuple2.of(
                        Mode.getMode(flinkApp),                    // Get running mode: SESSION or APPLICATION
                        KubernetesDeploymentMode.getDeploymentMode(flinkApp)), // Get deployment mode: NATIVE or STANDALONE
                modes -> {
                    // Create corresponding Observer based on running mode
                    switch (modes.f0) {
                        case SESSION:
                            return new SessionObserver(eventRecorder);      // Session mode observer
                        case APPLICATION:
                            return new ApplicationObserver(eventRecorder);  // Application mode observer
                        default:
                            throw new UnsupportedOperationException(
                                    String.format("Unsupported running mode: %s", modes.f0));
                    }
                });
    }
}
```

Based on section 5.1, the Observer interface is the core interface of the observer pattern, defining the `observe` method to observe Flink application status. `AbstractFlinkResourceObserver` is the abstract implementation of the Observer interface, providing a common observation logic framework including resource readiness checks, snapshot trigger resets, etc. `AbstractFlinkDeploymentObserver` is specifically used to observe FlinkDeployment resources, implementing deployment-related observation logic. `SessionObserver` and `ApplicationObserver` are two specific subclasses of `AbstractFlinkDeploymentObserver`, handling specific observation requirements for session mode and application mode respectively.

#### Cluster Deployment Observation

```java
@Override
public final void observe(FlinkResourceContext<CR> ctx) {
    // Check if resource is ready to be observed (no observation needed in specific states like suspended applications, upgrade rollback in progress)
    if (!isResourceReadyToBeObserved(ctx)) {
        return;
    }

    // Trigger resource-specific observation logic
    observeInternal(ctx);

    // Reset snapshot triggers
    SnapshotUtils.resetSnapshotTriggers(
            ctx.getResource(), eventRecorder, ctx.getKubernetesClient());
}
```

Based on section 5.1, the specific logic of the `observe` method has been explained in detail. For the reconciliation process of FlinkDeployment resources, `observeInternal` corresponds to the abstract method defined in `AbstractFlinkResourceObserver`, with the following specific code:

```java
@Override
public void observeInternal(FlinkResourceContext<FlinkDeployment> ctx) {
    var flinkDep = ctx.getResource();
    if (!isJmDeploymentReady(flinkDep)) {
        // Only observe JM deployment status when JobManager deployment is not ready
        observeJmDeployment(ctx);
    }

    if (isJmDeploymentReady(flinkDep)) {
        // Only observe Flink cluster status when JM is ready
        observeFlinkCluster(ctx);
    }

    if (isJmDeploymentReady(flinkDep)) {
        // Only collect cluster information when JM is ready
        observeClusterInfo(ctx);
    }

    clearErrorsIfDeploymentIsHealthy(flinkDep);
}
```

Based on section 5.1, observeInternal is the abstract method defined in AbstractFlinkDeploymentObserver. In the observeInternal method, observeFlinkCluster is an abstract method, specifically implemented by subclasses. Other methods are all defined in AbstractFlinkDeploymentObserver. We will first explain the methods defined in AbstractFlinkDeploymentObserver.

The method parameter of observeInternal is ctx, which is the FlinkDeploymentContext type created by the getResourceContext method of the resource context factory introduced in section 5.1.4, so `ctx.getResource()` corresponds to the FlinkDeployment type. Let's directly look at the source code of `isJmDeploymentReady`:

```java
protected boolean isJmDeploymentReady(FlinkDeployment dep) {
    return dep.getStatus().getJobManagerDeploymentStatus() == JobManagerDeploymentStatus.READY;
}
```

---

**Review of Chapter 3 FlinkDeployment Status Design**

In Chapter 3, we introduced the Status design of FlinkDeployment, where jobManagerDeploymentStatus corresponds to the deployment status of JobManager. The default initial value is MISSING.

```java
public enum JobManagerDeploymentStatus {
    /** JobManager is running and can receive REST API calls. */
    READY,

    /** JobManager is running but cannot receive REST API calls yet. */
    DEPLOYED_NOT_READY,

    /** JobManager process is starting. */
    DEPLOYING,

    /** JobManager deployment not found, may not have started or was killed by user. */
    // TODO: Currently a mixed state of SUSPENDED and ERROR, needs further cleanup
    MISSING,

    /** Deployment is in terminal error state, needs to modify spec before continuing reconciliation. */
    ERROR;
}
```

---

The logic of the `isJmDeploymentReady` method is simple: it just checks if the JobManagerDeploymentStatus of FlinkDeployment is READY.

**observeJmDeployment Method Logic Flow**

The logic flow diagram and description of the `observeJmDeployment` method are as follows:

{{< mermaid >}}
flowchart TD
    A[Start: observeJmDeployment] --> B[Get current status previousJmStatus]
    B --> C{Is it a suspended job?}
    C -->|Yes| D[Skip observation, return directly]
    C -->|No| E[Log start observation]
    
    E --> F{Is current status DEPLOYED_NOT_READY?}
    F -->|Yes| G[Set to READY status and return]
    F -->|No| H[Get Kubernetes Deployment resource]
    
    H --> I{Does Deployment exist?}
    I -->|No| J[Set to MISSING status]
    J --> K[Set job status to RECONCILING]
    K --> L{Was previous status MISSING/ERROR?}
    L -->|No| M[Call onMissingDeployment method]
    L -->|Yes| N[End]
    
    I -->|Yes| O[Check Deployment readiness]
    O --> P{Is Deployment ready?<br/>and JobManager port available?}
    P -->|Yes| Q[Set to DEPLOYED_NOT_READY status<br/>Wait for Flink REST API to be ready]
    Q --> R[End]
    
    P -->|No| S[Check deployment failure]
    S --> T[Check container restart]
    T --> U{Does it throw DeploymentFailedException?}
    U -->|Yes| V{Is current status ERROR?}
    V -->|No| W[Throw exception]
    V -->|Yes| X[Set job status to RECONCILING and return]
    U -->|No| Y[Set to DEPLOYING status]
    Y --> Z[End]
    
    M --> N
    
    style A fill:#e1f5fe
    style D fill:#ffebee
    style G fill:#e8f5e8
    style J fill:#fff3e0
    style Q fill:#f3e5f5
    style Y fill:#e8f5e8
    style W fill:#ffebee

{{< /mermaid >}}

The `observeJmDeployment` method observes JobManager deployment status through a series of conditional judgments. The overall flow is as follows:

1. **Suspended Job Check**  
   - If the job is in suspended state, skip observation directly and return.
   - Otherwise, continue with subsequent flow.

2. **Status Transition Check**  
   - If current status is `DEPLOYED_NOT_READY`, directly upgrade status to `READY` and return.
   - Otherwise, continue checking underlying resources.

3. **Deployment Existence Check**  
   - If Kubernetes Deployment resource doesn't exist, set status to `MISSING` and set job status to `RECONCILING`.
   - At this time, if the previous status was not `MISSING` or `ERROR`, trigger missing deployment handling logic (call `onMissingDeployment` method).

4. **Deployment Readiness Verification**  
   - If Deployment exists, check if replica count matches, available replicas reach expected value, and JobManager port is available.
   - If all are satisfied, set status to `DEPLOYED_NOT_READY`, waiting for Flink REST API to be ready.

5. **Exception and Deploying Status Handling**  
   - If readiness verification fails, further check deployment failure and container restart.
   - If `DeploymentFailedException` is thrown, judge current status:
     - If not `ERROR`, throw exception;
     - If already `ERROR`, set job status to `RECONCILING` and return.
   - If no exception, set status to `DEPLOYING`.

In short, since the initial state of JobManagerDeploymentStatus is MISSING, when JobManager deployment status is not equal to READY, observation logic will be triggered. At the same time, readers need to note that deployment logic is not in the observation phase. The observation here is more like a timed polling. When the reconciliation phase deploys JobManager's Deployment, it will trigger observation logic, setting JobManagerDeploymentStatus to DEPLOYED_NOT_READY. When the next polling occurs, the status will change to READY. The code design considers various exception situations, such as Deployment not existing, Deployment readiness verification failure, Deployment throwing exceptions, etc. The most common exception situation is Deployment not existing, which triggers the onMissingDeployment method. The corresponding code is as follows:

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

The onMissingDeployment method will set the error field in FlinkDeployment's status and use eventRecorder to trigger a Warning event.

When JobManagerDeploymentStatus is READY, readers can consider that the cluster observation phase from the deployment level has ended, and then enter the business-level observation phase.

#### Business-Level Observation

When JobManagerDeploymentStatus is READY, the observeClusterInfo method will be triggered. The corresponding code is as follows:

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

The main logic here is to get cluster information through flinkService's getClusterInfo method and update it to the clusterInfo field in FlinkDeployment's status. This field generally contains information such as: flink-version, total-cpu, total-memory, etc., all obtained by FlinkService calling Flink REST API.

When the JobManagerDeployment observation phase ends, the clearErrorsIfDeploymentIsHealthy method will be triggered. The corresponding code is as follows:

```java
protected void clearErrorsIfDeploymentIsHealthy(FlinkDeployment dep) {
    // Get FlinkDeployment status information
    FlinkDeploymentStatus status = dep.getStatus();
    // Get reconciliation status information for judging if spec is stable
    var reconciliationStatus = status.getReconciliationStatus();
    
    // Conditions for clearing error status:
    // 1. JobManager deployment status is not ERROR (cluster deployment normal)
    // 2. Job status is not FAILED (job running normal)
    // 3. Last reconciled spec is stable (no ongoing spec changes)
    if (status.getJobManagerDeploymentStatus() != JobManagerDeploymentStatus.ERROR
            && !JobStatus.FAILED.equals(dep.getStatus().getJobStatus().getState())
            && reconciliationStatus.isLastReconciledSpecStable()) {
        // When all conditions are met, clear error status, indicating system has returned to normal
        status.setError(null);
    }
}
```

The code logic is simple: when conditions are met, it sets the error field in FlinkDeployment's status to null.

Finally, let's break down the sequence diagram of the most critical business observation part - the observeFlinkCluster method implementation of ApplicationObserver:

{{< mermaid >}}
sequenceDiagram
    participant ApplicationObserver as ApplicationObserver
    participant JobStatusObserver as JobStatusObserver
    participant SavepointObserver as SavepointObserver
    participant ClusterHealthObserver as ClusterHealthObserver
    participant FlinkResourceContext as FlinkResourceContext
    participant ObserveConfig as ObserveConfig

    Note over ApplicationObserver, ClusterHealthObserver: ApplicationObserver.observeFlinkCluster Observation Flow

    ApplicationObserver->>ApplicationObserver: Log debug: "Observing application cluster"
    
    ApplicationObserver->>JobStatusObserver: observe(ctx)
    Note right of JobStatusObserver: Observe job status, return whether job found
    
    JobStatusObserver-->>ApplicationObserver: jobFound (boolean)
    
    alt Job Found (jobFound = true)
        ApplicationObserver->>FlinkResourceContext: getObserveConfig()
        FlinkResourceContext-->>ApplicationObserver: observeConfig
        
        Note over ApplicationObserver, SavepointObserver: Start observing savepoint status
        ApplicationObserver->>SavepointObserver: observeSavepointStatus(ctx)
        SavepointObserver->>SavepointObserver: Observe savepoint trigger status, completion status, etc.
        
        Note over ApplicationObserver, CheckpointObserver: Start observing checkpoint status
        ApplicationObserver->>SavepointObserver: observeCheckpointStatus(ctx)
        Note right of SavepointObserver: Note: This calls savepointObserver<br/>but actually observes checkpoint status
        
        ApplicationObserver->>ObserveConfig: getBoolean(OPERATOR_CLUSTER_HEALTH_CHECK_ENABLED)
        ObserveConfig-->>ApplicationObserver: Whether cluster health check is enabled
        
        alt Cluster health check enabled
            Note over ApplicationObserver, ClusterHealthObserver: Start observing cluster health status
            ApplicationObserver->>ClusterHealthObserver: observe(ctx)
            ClusterHealthObserver->>ClusterHealthObserver: Check cluster health metrics<br/>like restart count, checkpoint completion, etc.
        else Cluster health check disabled
            Note right of ApplicationObserver: Skip cluster health check
        end
        
    else Job not found (jobFound = false)
        Note right of ApplicationObserver: Skip all subsequent observation steps<br/>including savepoint, checkpoint and cluster health check
    end
    
    Note over ApplicationObserver, ClusterHealthObserver: Observation flow ends
{{< /mermaid >}}

It can be seen that the key is still the observation of job status and savepoints/checkpoints. If cluster health observation is configured, cluster health check will also be performed accordingly. We have already introduced job status observer and snapshot observer in sections 5.1.1.1 and 5.1.1.2 respectively. Here we mainly focus on the implementation of cluster health observer ClusterHealthObserver.

The source code of ClusterHealthObserver's observe method is as follows:

```java
/**
 * Observe Flink cluster health status
 * 
 * This method evaluates cluster health by collecting key metrics from Flink cluster,
 * including job restart count and completed checkpoint count, to determine if cluster needs restart recovery.
 *
 * @param ctx Resource context containing Flink cluster configuration and status information
 */
public void observe(FlinkResourceContext<FlinkDeployment> ctx) {
    // Get Flink application resource object from context
    var flinkApp = ctx.getResource();
    try {
        LOG.debug("Observing cluster health");
        
        // Get deployment status and job status information
        var deploymentStatus = flinkApp.getStatus();
        var jobStatus = deploymentStatus.getJobStatus();
        var jobId = jobStatus.getJobId();
        
        // Call Flink cluster's REST API through FlinkService to get key metrics
        // Collect three important health metrics: full restart count, restart count, completed checkpoint count
        var metrics =
                ctx.getFlinkService()
                        .getMetrics(
                                ctx.getObserveConfig(),
                                jobId,
                                List.of(
                                        FULL_RESTARTS_METRIC_NAME,        // Full restart count (old Flink versions)
                                        NUM_RESTARTS_METRIC_NAME,         // Restart count (new Flink versions)
                                        NUMBER_OF_COMPLETED_CHECKPOINTS_METRIC_NAME));  // Completed checkpoint count
        
        // Create new cluster health info object to store observed health status
        ClusterHealthInfo observedClusterHealthInfo = new ClusterHealthInfo();
        
        // Prefer new version numRestarts metric, fallback to old version fullRestarts if not exists
        // This design ensures backward compatibility, supporting different Flink cluster versions
        if (metrics.containsKey(NUM_RESTARTS_METRIC_NAME)) {
            LOG.debug(NUM_RESTARTS_METRIC_NAME + " metric is used");
            // Set restart count for evaluating cluster stability
            observedClusterHealthInfo.setNumRestarts(
                    Integer.parseInt(metrics.get(NUM_RESTARTS_METRIC_NAME)));
        } else if (metrics.containsKey(FULL_RESTARTS_METRIC_NAME)) {
            LOG.debug(
                    FULL_RESTARTS_METRIC_NAME
                            + " metric is used because "
                            + NUM_RESTARTS_METRIC_NAME
                            + " is missing");
            // Use old version metric as fallback
            observedClusterHealthInfo.setNumRestarts(
                    Integer.parseInt(metrics.get(FULL_RESTARTS_METRIC_NAME)));
        } else {
            // If both restart metrics don't exist, cluster configuration has issues or version incompatible
            // Throw exception to prevent subsequent health evaluation
            throw new IllegalStateException(
                    "No job restart metric found. Either "
                            + FULL_RESTARTS_METRIC_NAME
                            + "(old and deprecated in never Flink versions) or "
                            + NUM_RESTARTS_METRIC_NAME
                            + "(new) must exist.");
        }
        
        // Set completed checkpoint count for evaluating cluster data processing capability
        // This metric is very important for judging if cluster is running healthily
        observedClusterHealthInfo.setNumCompletedCheckpoints(
                Integer.parseInt(metrics.get(NUMBER_OF_COMPLETED_CHECKPOINTS_METRIC_NAME)));
        
        // Record observed cluster health info for debugging and monitoring
        LOG.debug("Observed cluster health: {}", observedClusterHealthInfo);

        // Call cluster health evaluator for health status evaluation
        // evaluate method will:
        // 1. Compare current health info with last health info
        // 2. Evaluate if restart count exceeds threshold (within configured time window)
        // 3. Evaluate if checkpoint progress is normal (within configured time window)
        // 4. Update health status in cluster info
        clusterHealthEvaluator.evaluate(
                ctx.getObserveConfig(),                    // Observation config containing health check thresholds and window settings
                deploymentStatus.getClusterInfo(),         // Cluster info for storing and comparing health status
                observedClusterHealthInfo);                // Health info observed this time
                
    } catch (Exception e) {
        // Catch and log exception but don't throw exception
        // This is because getting metrics failure is usually treated as temporary issue, shouldn't block entire observation flow
        // System will retry on next observation, ensuring continuity of cluster health monitoring
        LOG.warn("Exception while observing cluster health: {}", e.getMessage());
        // Intentionally don't throw exception because we treat getting metrics failure as temporary issue
    }
}
```

From the code comments, it can be seen that when cluster monitoring, three important health metrics are obtained: full restart count, restart count, completed checkpoint count. It's just that Flink Operator is compatible with multiple Flink versions so it needs to be compatible with different version metric names. Collected metrics will be stored in ClusterHealthInfo object, then clusterHealthEvaluator's evaluate method is called for health evaluation.

The main steps of ClusterHealthEvaluator's evaluate method are:
1. Compare current health info with last health info
2. Evaluate if restart count exceeds threshold (within configured time window)
3. Evaluate if checkpoint progress is normal (within configured time window)
4. Update health status in cluster info

Finally, the evaluation result will be written to the clusterInfo field of FlinkDeploymentStatus.

Overall, ApplicationObserver's business-level observation mainly uses REST API to get job status, savepoints, checkpoints and cluster running metrics for observation. The final result will update corresponding fields in status.

Next, let's supplement SessionObserver's observeFlinkCluster method:

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

SessionObserver's observeFlinkCluster method mainly checks if session cluster can provide REST calls. If yes, mark as reconciled. If not, observe JobManager deployment status. It can be seen that compared to ApplicationObserver's observeFlinkCluster method, the main difference is that SessionObserver's observeFlinkCluster method mainly checks if session cluster is accessible, without caring about job status and savepoints. We will talk about FlinkSessionJob's observation method in section 5.3.3, which will check job status and savepoint status, forming a complementary relationship with SessionObserver itself.

### 5.2.3 Validation Phase

Compared to the observation and reconciliation phases, the validation phase has relatively simple logic. In Chapter 4, we already introduced the plugin mechanism of the Operator. The main logic of the validation phase is to call the validate methods of built-in and custom plugins to verify whether resources meet expectations.

In the reconcile method, the validation phase code implementation is as follows:

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {
    // ... Previous preparation phase code ...
    
    try {
        // Previous observation phase code
        // Validation phase code
        if (!validateDeployment(ctx)) {
            // If validation fails, update status and set not to repeat reconciliation
            statusRecorder.patchAndCacheStatus(flinkApp, ctx.getKubernetesClient());
            return ReconciliationUtils.toUpdateControl(
                    ctx.getOperatorConfig(), flinkApp, previousDeployment, false); // false means no reschedule reconciliation logic
        }
        // ... Subsequent reconciliation logic ...
    } catch (Exception e) {
        // ... Exception handling ...
    }
    return ReconciliationUtils.toUpdateControl(
                ctx.getOperatorConfig(), flinkApp, previousDeployment, true);
}
```

The corresponding core function `validateDeployment` source code is as follows:

```java
private boolean validateDeployment(FlinkResourceContext<FlinkDeployment> ctx) {
    var deployment = ctx.getResource();
    // Iterate through all validators and call each validation plugin's validateDeployment method
    for (FlinkResourceValidator validator : validators) {
        Optional<String> validationError = validator.validateDeployment(deployment);
        // If validation fails, exit loop, send Warning event through eventRecorder, and return false
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

Let's review Chapter 4 about plugin discovery mechanism and how to write custom validation plugins:

---

In FlinkOperator's constructor, there's logic for constructing validators plugins. The code here doesn't show any traces of ServiceLoader:

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
                        // Record discovered plugin validator
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

From the code, we can see that the main plugin inherits from `FlinkResourceValidator.class`. From the code, we can see that plugin jar packages should be placed in the folder corresponding to the FLINK_PLUGINS_DIR environment variable. When building Flink Operator images, this logic needs to be added. `PluginUtils` comes from the flink-core library. The plugin discovery mechanism used here is consistent with the Flink framework.

For custom plugins, the following code is an example provided by the official documentation:

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

---

From the above code, we can see that when implementing plugins, both validateDeployment and validateSessionJob methods need to be implemented, but when validating corresponding resources, different resources will call their corresponding methods.

The core logic of the validation phase is to iterate through all validators and call each validation plugin's validateDeployment method. If validation fails, reconciliation logic will not be processed.

In addition to custom validation plugins, FlinkOperator provides a built-in validation class, DefaultValidator class, which implements the FlinkResourceValidator interface and provides some default validation logic. For FlinkDeployment resources, the logic of its validateDeployment method is as follows:

```java
@Override
public Optional<String> validateDeployment(FlinkDeployment deployment) {
    // Get FlinkDeployment spec configuration
    FlinkDeploymentSpec spec = deployment.getSpec();
    
    // Build effective configuration: start from default configuration, get based on namespace and Flink version
    Map<String, String> effectiveConfig =
            configManager
                    .getDefaultConfig(
                            deployment.getMetadata().getNamespace(), spec.getFlinkVersion())
                    .toMap();
                    
    // If user provides custom Flink configuration, override default configuration
    // User configuration has higher priority
    if (spec.getFlinkConfiguration() != null) {
        effectiveConfig.putAll(spec.getFlinkConfiguration());
    }
    
    // Execute multiple validation checks in order, return on first error
    // firstPresent method returns first non-empty Optional result
    return firstPresent(
            // 1. Validate deployment name validity (not empty, conforms to naming conventions, etc.)
            validateDeploymentName(deployment.getMetadata().getName()),
            
            // 2. Validate Flink version compatibility and support
            validateFlinkVersion(deployment),
            
            // 3. Validate Flink deployment related configuration items
            validateFlinkDeploymentConfig(effectiveConfig),
            
            // 4. Validate Ingress configuration validity (if Ingress is enabled)
            validateIngress(
                    spec.getIngress(),
                    deployment.getMetadata().getName(),
                    deployment.getMetadata().getNamespace()),
                    
            // 5. Validate log configuration validity
            validateLogConfig(spec.getLogConfiguration()),
            
            // 6. Validate job spec configuration, including parallelism, resource configuration, etc.
            validateJobSpec(spec.getJob(), spec.getTaskManager(), effectiveConfig),
            
            // 7. Validate JobManager spec configuration, including resource limits, replica count, etc.
            validateJmSpec(spec.getJobManager(), effectiveConfig),
            
            // 8. Validate TaskManager spec configuration, including resource limits, task slot count, etc.
            validateTmSpec(spec.getTaskManager(), effectiveConfig),
            
            // 9. Validate spec change validity, check if upgrade path is legal
            validateSpecChange(deployment, effectiveConfig),
            
            // 10. Validate ServiceAccount configuration validity
            validateServiceAccount(spec.getServiceAccount()),
            
            // 11. Validate auto-scaler related Flink configuration items
            validateAutoScalerFlinkConfiguration(effectiveConfig));
}
```

From the code comments, readers can guess the functionality of many functions. Each function returns `Optional<String>` type. If it returns Optional.of value, it means validation failed, and the returned value is the error message. The corresponding firstPresent method is used to check if there are error messages. Readers can check the logic of each function. For missing validation logic, custom validation plugins need to be implemented to supplement.

### 5.2.4 Reconciliation Phase 

Finally, we enter the most core part of the reconcile method - the reconciliation phase. The code implementation is as follows:

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {
    // ... Previous preparation phase code ...
    
    try {
        // Previous observation phase code
        // Validation phase code
        // Update cached status (save modifications from observation and validation phases)
        statusRecorder.patchAndCacheStatus(flinkApp, ctx.getKubernetesClient());
        // Reconciliation logic
        reconcilerFactory.getOrCreate(flinkApp).reconcile(ctx);
    } catch (Exception e) {
        // ... Exception handling ...
    }
    return ReconciliationUtils.toUpdateControl(
                ctx.getOperatorConfig(), flinkApp, previousDeployment, true);
}
```

After completing the observation and validation phases, the code calls statusRecorder's patchAndCacheStatus method to cache the status. The reconcilerFactory here is created when constructing FlinkDeploymentController, with the purpose of returning SessionReconciler or ApplicationReconciler instances for different cluster deployment types:

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

After creating the corresponding Reconciler instance from the factory pattern, we call its corresponding reconcile method. We already explained in section 5.1.2 that AbstractFlinkResourceReconciler's reconcile method adopts the template method pattern, defining a unified reconciliation pattern with 5 steps: ready check, deployment flow, scaling processing, change processing, and other reconciliation. We will define the first two steps as cluster reconciliation phase and the last two steps as business reconciliation phase in the following narrative. For cluster scaling processing, we will focus on it when explaining FlinkService in Chapter 7. Readers can understand that in the cluster reconciliation phase, if there are spec changes and the cluster has been scaled, then the change processing step will not be entered. The change processing we mention here refers to changes that cannot be resolved through cluster scaling.

Additionally, section 5.1.2.2 provided the corresponding core flow diagram and sequence diagram of the unified reconciliation flow. Readers can refer back to review. Next, we will divide the reconciliation phase of FlinkDeployment resources into cluster reconciliation phase and business reconciliation phase, similar to the observation phase. In the cluster reconciliation phase, we will directly focus on breaking down ApplicationReconciler and SessionReconciler methods. In the business reconciliation phase, we will first focus on breaking down the template methods in AbstractJobReconciler about common lifecycle management of FlinkDeployment jobs in Application mode, then the business reconciliation logic under different deployment modes.

#### Cluster Reconciliation Phase

In the cluster reconciliation phase, the first step is the ready check, corresponding to the readyToReconcile method called in the reconcile method.

For Application cluster mode, this abstract method is implemented by AbstractJobReconciler:

```java
@Override
public boolean readyToReconcile(FlinkResourceContext<CR> ctx) {
    var status = ctx.getResource().getStatus();
    // Check if it's the first deployment
    if (status.getReconciliationStatus().isBeforeFirstDeployment()) {
        return true;
    }
    // Whether to wait for pending savepoint completion
    if (shouldWaitForPendingSavepoint(status.getJobStatus(), ctx.getObserveConfig())) {
        LOG.info("Delaying job reconciliation until pending savepoint is completed.");
        return false;
    }
    return true;
}
```

The logic of this method is relatively simple, mainly checking if it's the first deployment and whether to wait for savepoint completion. The specific method code is brief, readers can check it themselves.

For Session cluster mode, this abstract method is implemented by AbstractJobReconciler:

```java
@Override
protected boolean readyToReconcile(FlinkResourceContext<FlinkDeployment> ctx) {
    return true;
}
```

The logic of this method is simple, mainly directly returning true, indicating reconciliation can proceed.

Next, let's look at the deployment step, corresponding to the deploy method called in the reconcile method.

For Application cluster mode, this abstract method is implemented by ApplicationReconciler:

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

    // Remove last valid cluster health info from cluster health evaluator
    // This ensures each deployment starts from a clean state, avoiding using expired health status info
    ClusterHealthEvaluator.removeLastValidClusterHealthInfo(
            relatedResource.getStatus().getClusterInfo());

    if (savepoint.isPresent()) {
        // Savepoint deployment mode: if savepoint path is provided, use this path for state recovery
        deployConfig.set(SavepointConfigOptions.SAVEPOINT_PATH, savepoint.get());
    } else if (requireHaMetadata && flinkService.atLeastOneCheckpoint(deployConfig)) {
        // Last state deployment mode: requires HA metadata and at least one checkpoint in config
        // Explicitly set a dummy savepoint path to avoid accidentally recovering wrong state when HA metadata is deleted by user
        deployConfig.set(SavepointConfigOptions.SAVEPOINT_PATH, LAST_STATE_DUMMY_SP_PATH);
        status.getJobStatus().setUpgradeSavepointPath(LAST_STATE_DUMMY_SP_PATH);
        
        // Important note: LAST_STATE_DUMMY_SP_PATH is a dummy path constant with value "KUBERNETES_OPERATOR_LAST_STATE"
        // This dummy path serves to:
        // 1. Prevent accidental recovery: avoid accidentally recovering wrong state when HA metadata is deleted by user
        // 2. Mark upgrade mode: indicate this is a "last state" upgrade, not a real savepoint upgrade
        // 3. Real path setting: real savepoint path is automatically read and set by Flink from HA metadata when Flink cluster starts
        // 4. Dummy path recognition: Flink will recognize this dummy path and ignore it, using real checkpoint info from HA metadata instead
    } else {
        // Stateless deployment: remove any savepoint path configured by user
        deployConfig.removeConfig(SavepointConfigOptions.SAVEPOINT_PATH);
    }

    // Set Kubernetes resource owner reference to ensure resource lifecycle management
    // This establishes subordinate relationship between FlinkDeployment CR and Kubernetes resources
    setOwnerReference(relatedResource, deployConfig);
    
    // Set random Job result store path to avoid restarting terminated applications during JobManager failover
    // This solves FLINK-27569 issue: disable Job result cleanup, create unique store path for each deployment
    setRandomJobResultStorePath(deployConfig);

    if (status.getJobManagerDeploymentStatus() != JobManagerDeploymentStatus.MISSING) {
        // If JobManager deployment status is not MISSING, previous deployment existed
        // Check if job is in terminal state, then delete cluster deployment
        Preconditions.checkArgument(ReconciliationUtils.isJobInTerminalState(status));
        LOG.info("Deleting cluster with terminated application before new deployment");
        flinkService.deleteClusterDeployment(
                relatedResource.getMetadata(), status, deployConfig, !requireHaMetadata);
        // Update and cache status info to Kubernetes
        statusRecorder.patchAndCacheStatus(relatedResource, ctx.getKubernetesClient());
    }

    // Set Job ID based on deployment mode
    // For non-last state deployment, generate new Job ID to avoid checkpoint path conflicts
    // For last state deployment, maintain existing Job ID to ensure state recovery
    setJobIdIfNecessary(
            relatedResource, deployConfig, ctx.getKubernetesClient(), requireHaMetadata);

    // Trigger event recording, record job submission event
    // This provides operation audit and monitoring capability
    eventRecorder.triggerEvent(
            relatedResource,
            EventRecorder.Type.Normal,
            EventRecorder.Reason.Submit,
            EventRecorder.Component.JobManagerDeployment,
            MSG_SUBMIT,
            ctx.getKubernetesClient());
    
    // Submit application cluster to Flink service
    // This is the core operation for actually starting Flink cluster
    flinkService.submitApplicationCluster(spec.getJob(), deployConfig, requireHaMetadata);
    
    // Set job status to RECONCILING (reconciling)
    status.getJobStatus().setState(org.apache.flink.api.common.JobStatus.RECONCILING);
    
    // Set JobManager deployment status to DEPLOYING (deploying)
    status.setJobManagerDeploymentStatus(JobManagerDeploymentStatus.DEPLOYING);

    // Update Ingress rules, configure external access routing
    // If ingress is configured in spec, create or update corresponding Kubernetes Ingress resources
    // This allows external traffic to access Flink cluster's REST API through Ingress
    IngressUtils.updateIngressRules(
            relatedResource.getMetadata(), spec, deployConfig, ctx.getKubernetesClient());
}
```

The cluster reconciliation logic deployed in Application mode is quite complex, needing to consider job-dependent savepoint and checkpoint configurations, as well as jobId settings. The purpose of considering job-dependent savepoint and checkpoint configurations is for the business reconciliation phase. When the cluster is redeployed, the job needs to recover from savepoints and checkpoints, and this will also go through the deploy logic.

When we enter this deploy logic, we set jobStatus to RECONCILING (reconciling) and jobManagerDeploymentStatus to DEPLOYING (deploying). The most core function call is flinkService's submitApplicationCluster method, which will start Flink's Application mode cluster according to the user-configured startup mode. We mentioned this mode in Chapter 3. Specifically, there are two modes: native and standalone, corresponding to Flink controlling cluster creation and deploying Flink clusters in traditional ways respectively. We will introduce in detail how FlinkService implements these two modes in Chapter 7. Here, readers only need to understand how the entire reconciliation phase process is implemented.

Readers need to be reminded that deployConfig here runs through the entire deployment reconciliation. After the setOwnerReference call, it will add the `kubernetes.jobmanager.owner.reference` configuration. When subsequent calls to flinkService create cluster secondary resources, this configuration will be read to set the subordinate relationship between secondary and primary resources. This applies to both Session and Application modes.

For Session cluster mode, this abstract method is implemented by SessionReconciler:

```java
public void deploy(
        FlinkResourceContext<FlinkDeployment> ctx,
        FlinkDeploymentSpec spec,
        Configuration deployConfig,
        Optional<String> savepoint,
        boolean requireHaMetadata)
        throws Exception {
    var cr = ctx.getResource();
    
    // Set Kubernetes resource owner reference to ensure resource lifecycle management
    // This establishes subordinate relationship between FlinkDeployment CR and Kubernetes resources
    setOwnerReference(cr, deployConfig);
    
    // Submit session cluster to Flink service
    // This is the core operation for starting Flink session cluster, different from Application mode, Session mode doesn't need to handle job state recovery
    ctx.getFlinkService().submitSessionCluster(deployConfig);
    
    // Set JobManager deployment status to DEPLOYING (deploying)
    // Indicates session cluster is in deployment process
    cr.getStatus().setJobManagerDeploymentStatus(JobManagerDeploymentStatus.DEPLOYING);
    
    // Update Ingress rules, configure external access routing
    // If ingress is configured in spec, create or update corresponding Kubernetes Ingress resources
    // This allows external traffic to access Flink session cluster's REST API through Ingress
    IngressUtils.updateIngressRules(
            cr.getMetadata(), spec, deployConfig, ctx.getKubernetesClient());
}
```

From the code and comments, readers can clearly see that since Session mode only needs to create clusters and doesn't need to care about jobs, the logic here omits the logic for handling savepoints, checkpoints, and job states.

After understanding the cluster deployment phase, let's continue to look at the business reconciliation phase.

#### Business Reconciliation Phase

In the business reconciliation process, the first step is change processing, corresponding to the reconcileSpecChange method called in the reconcile method.

For Session cluster mode, this abstract method is implemented by SessionReconciler:

```java
@Override
protected boolean reconcileSpecChange(
        DiffType diffType,
        FlinkResourceContext<FlinkDeployment> ctx,
        Configuration deployConfig,
        FlinkDeploymentSpec lastReconciledSpec)
        throws Exception {
    var deployment = ctx.getResource();
    
    // Delete existing session cluster to prepare for new deployment
    deleteSessionCluster(ctx);

    // Before deployment, we record target spec to upgrade status
    // This ensures accuracy of status tracking even if errors occur during deployment
    ReconciliationUtils.updateStatusBeforeDeploymentAttempt(deployment, deployConfig, clock);
    
    // Synchronize status update to Kubernetes and cache locally
    // This provides status persistence and consistency guarantee
    statusRecorder.patchAndCacheStatus(deployment, ctx.getKubernetesClient());

    // Execute deployment operation, using empty savepoint and no HA metadata required
    // Session mode doesn't need to handle job state recovery, so use Optional.empty()
    deploy(ctx, deployment.getSpec(), deployConfig, Optional.empty(), false);
    
    // After deployment completion, update status info for deployed spec
    // This marks completion of upgrade process
    ReconciliationUtils.updateStatusForDeployedSpec(deployment, deployConfig, clock);
    
    return true;
}
```

Readers might feel strange here - why delete the existing session cluster? Readers can refer to section 5.1.2.2 on common reconciliation flow where there's a usage scenario for DiffType. It can be seen that most scenarios that can trigger changes involve cluster configuration changes. When cluster scaling operations can't handle this change, we need to redeploy the cluster. So you'll see the operation of first deleting the cluster, then calling deploy to redeploy the cluster. For Session cluster mode, we don't need to care about job upgrade operations, so the handling here is very simple.

For Session cluster mode, if there are no spec changes, it will enter other change processing. This abstract method reconcileOtherChanges is implemented by SessionReconciler:

```java
@Override
public boolean reconcileOtherChanges(FlinkResourceContext<FlinkDeployment> ctx)
        throws Exception {
    // If deployment recovery is needed, recover deployment
    if (shouldRecoverDeployment(ctx.getObserveConfig(), ctx.getResource())) {
        // Create Session cluster through FlinkService's submitSessionCluster method
        recoverSession(ctx);
        return true;
    }
    return false;
}
```

The logic for judging whether recovery is needed depends on checking if the user has enabled the configuration `jm-deployment-recovery.enabled`. If enabled and the JobManager's corresponding Deployment deployment indeed doesn't exist, it will enter the deployment recovery logic. This is equivalent to a compensation logic for the reconciliation phase when there are no spec changes.

After explaining the business reconciliation phase of Session cluster mode, let's explain the more complex Application cluster mode.

For Application cluster mode, this abstract method reconcileSpecChange is implemented by AbstractJobReconciler:

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

    // Get current and desired job states
    JobState currentJobState = lastReconciledSpec.getJob().getState();
    JobState desiredJobState = currentDeploySpec.getJob().getState();

    // Handle SAVEPOINT_REDEPLOY type changes: redeploy from savepoint
    if (diffType == DiffType.SAVEPOINT_REDEPLOY) {
        redeployWithSavepoint(
                ctx, deployConfig, resource, status, currentDeploySpec, desiredJobState);
        return true;
    }

    // If job is currently running, need to handle upgrade logic first
    if (currentJobState == JobState.RUNNING) {
        var jobUpgrade = getJobUpgrade(ctx, deployConfig);
        if (!jobUpgrade.isAvailable()) {
            // If job upgrade is currently unavailable (e.g., checkpoint info unavailable), check if other reconcile actions are allowed
            LOG.info(
                    "Job is not running and checkpoint information is not available for executing the upgrade, waiting for upgradeable state");
            return !jobUpgrade.allowOtherReconcileActions;
        }
        LOG.debug("Job upgrade available: {}", jobUpgrade);

        var suspendMode = jobUpgrade.getSuspendMode();
        if (suspendMode != SuspendMode.NOOP) {
            // Trigger job suspension event
            eventRecorder.triggerEvent(
                    resource,
                    EventRecorder.Type.Normal,
                    EventRecorder.Reason.Suspended,
                    EventRecorder.Component.JobManagerDeployment,
                    MSG_SUSPENDED,
                    ctx.getKubernetesClient());
        }

        // Try to cancel job, get whether it's async cancellation
        boolean async = cancelJob(ctx, suspendMode);
        if (async) {
            // Async cancellation will complete in background, so we must exit reconciliation early
            // and wait for its completion to complete upgrade
            resource.getStatus()
                    .getReconciliationStatus()
                    .setState(ReconciliationState.UPGRADING);
            // Update last reconciled spec, record upgrade mode and deployment status
            ReconciliationUtils.updateLastReconciledSpec(
                    resource,
                    (s, m) -> {
                        s.getJob().setUpgradeMode(jobUpgrade.getRestoreMode());
                        m.setFirstDeployment(false);
                    });
            return true; // Async cancellation, reconciliation ends
        }

        // Record used upgrade mode to status
        currentDeploySpec.getJob().setUpgradeMode(jobUpgrade.getRestoreMode());

        // Update status info based on desired job state
        if (desiredJobState == JobState.RUNNING) {
            // Desired running state: update status before deployment attempt
            ReconciliationUtils.updateStatusBeforeDeploymentAttempt(
                    resource, deployConfig, clock);
        } else {
            // Other states: update status for deployed spec
            ReconciliationUtils.updateStatusForDeployedSpec(resource, deployConfig, clock);
        }

        if (suspendMode == SuspendMode.NOOP) {
            // If already in cancelled state, we want to restore immediately, so modify current state
            // We don't do this when we actually executed potentially time-consuming cancellation to allow spec reconciliation
            lastReconciledSpec.getJob().setUpgradeMode(jobUpgrade.getRestoreMode());
            currentJobState = JobState.SUSPENDED;
        }
    }

    // If job is currently suspended and desired to run, execute recovery logic
    if (currentJobState == JobState.SUSPENDED && desiredJobState == JobState.RUNNING) {
        // Unless stateless upgrade is requested, we inherit upgrade mode
        if (currentDeploySpec.getJob().getUpgradeMode() != UpgradeMode.STATELESS) {
            currentDeploySpec
                    .getJob()
                    .setUpgradeMode(lastReconciledSpec.getJob().getUpgradeMode());
        }
        // Before deployment, we record target spec to upgrade status
        ReconciliationUtils.updateStatusBeforeDeploymentAttempt(resource, deployConfig, clock);
        statusRecorder.patchAndCacheStatus(resource, ctx.getKubernetesClient());

        // Restore job, decide whether to force HA based on how job was previously suspended
        restoreJob(
                ctx,
                currentDeploySpec,
                deployConfig,
                // We decide whether to force HA based on how job was previously suspended
                lastReconciledSpec.getJob().getUpgradeMode() == UpgradeMode.LAST_STATE);

        // Update status for deployed spec
        ReconciliationUtils.updateStatusForDeployedSpec(resource, deployConfig, clock);
    }
    return true;
}
```

Based on the above code, we can divide the logic into three parts:
1. Logic for handling savepoint redeployment
2. Get job upgrade logic and handle job cancellation
3. If job is currently suspended and desired to run, restore job

Readers need to note that when the second part cancels the job, if it's async cancellation, the first reconciliation will return directly. At this time, it won't enter other spec change processing steps, but wait for the job cancellation process to be observed by the observation phase, then update corresponding status. After the job has been cancelled and status has been modified correctly, it will enter the third part logic again. If the job is sync cancellation, it will proceed to restore the job.

Readers also need to note that there's a new concept here - job upgrade logic, with corresponding implementation class JobUpgrade:

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

Based on the above `JobUpgrade` class, combined with Flink Operator documentation, we provide the following table, detailing the characteristics of these three modes:

| Upgrade Mode | Stateless Upgrade | Last State Upgrade | Savepoint Upgrade |
|--------------|-------------------|-------------------|-------------------|
| **Configuration Requirements** | None | Enable checkpoints | Define checkpoint/savepoint directory |
| **Job State Requirements** | None | Job or HA metadata accessible | Job running* |
| **Suspension Mechanism** | Cancel/Delete | Cancel/Delete (retain HA metadata) | Create savepoint then cancel |
| **Recovery Mechanism** | Empty state | Use HA metadata or last checkpoint/savepoint | Restore from savepoint |
| **Production Use** | Not recommended | Recommended | Recommended |

The correspondence between the three upgrade modes and code is as follows:
- **Stateless Upgrade**: Corresponds to `JobUpgrade.stateless()` method, suitable for scenarios that don't need to retain state, but will lose all job state
- **Last State Upgrade**: Corresponds to `JobUpgrade.lastStateUsingHaMeta()` or `JobUpgrade.lastStateUsingCancel()` method, utilizes Flink's high availability mechanism to recover last checkpoint state from cluster HA metadata. If metadata doesn't exist, manual recovery is needed. `JobUpgrade.lastStateUsingCancel()` is generally used for FlinkSessionJob scenarios, while FlinkDeployment scenarios generally correspond to `JobUpgrade.lastStateUsingHaMeta()`.
- **Savepoint Upgrade**: Corresponds to `JobUpgrade.savepoint()` method, creates savepoint before upgrade to ensure no state loss. Job recovery is done through savepoint.

These three upgrade modes completely correspond to the design of the `JobUpgrade` class. `SuspendMode` determines how to suspend the job, `UpgradeMode` determines how to recover state, and the combination of both implements complete upgrade strategy.

To better understand the logic of the `getJobUpgrade` method, we draw a flow diagram to sort out the judgments of various situations:

{{< mermaid >}}
flowchart TD
    A[Start getJobUpgrade] --> B{Check upgrade mode}
    
    B -->|STATELESS| C[Stateless upgrade]
    C --> C1[Return JobUpgrade.stateless terminal]
    
    B -->|SAVEPOINT| D[Savepoint upgrade logic]
    B -->|LAST_STATE| E[Last state upgrade logic]
    
    D --> D1{Is job running}
    D1 -->|Yes| D2[Return JobUpgrade.savepoint]
    D1 -->|No| D3{Version changed or fallback enabled}
    D3 -->|Yes| D4[Fallback to LAST_STATE mode]
    D3 -->|No| D5[Return JobUpgrade.pendingUpgrade]
    
    E --> E1{Version changed}
    E1 -->|Yes| E2[Version upgrade special handling]
    E1 -->|No| E3{Is job running}
    
    E2 --> E2A{Can create savepoint}
    E2A -->|Yes| E2B[Return JobUpgrade.savepoint]
    E2A -->|No| E2C{Is job cancellable}
    E2C -->|Yes| E2D[Return JobUpgrade.lastStateUsingCancel]
    E2C -->|No| E2E[Return JobUpgrade.pendingUpgrade]
    
    E3 -->|Yes| E4[Decide upgrade mode based on job fallback time]
    E3 -->|No| E5{Allow cancellation}
    E5 -->|Yes| E6[Return JobUpgrade.lastStateUsingCancel]
    E5 -->|No| E7[Return JobUpgrade.unavailable]
    
    E4 --> E4A{Fallback time exceeds threshold}
    E4A -->|Yes| E4B[Return JobUpgrade.savepoint]
    E4A -->|No| E4C[Return JobUpgrade.lastStateUsingHaMeta]
    
    F[Pre-check job status] --> F1{Is job cancelled}
    F1 -->|Yes| F2{Has known savepoint}
    F2 -->|Yes| F3[Return JobUpgrade.savepoint]
    F2 -->|No| F4[Throw upgrade failure exception]
    
    F1 -->|No| F5{Is job cancelling}
    F5 -->|Yes| F6[Return JobUpgrade.pendingCancellation]
    
    F1 -->|No| F7[Continue normal upgrade logic]
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

In the flow diagram, there are judgments about whether the job is in terminal state or running. These state judgments all come from the job status written in the observation phase. The version change mentioned in the flow diagram refers to Flink version change, specifically the flinkVersion field in spec. There are two suspension mechanisms: one is deleting the cluster, and the other is cancelling the job. Additionally, savepoint upgrade mode will fallback to last state upgrade mode when the job is in unhealthy state. This fallback operation currently only supports FlinkDeployment resources in Application cluster mode. If you don't want this fallback operation, you can set `job.upgrade.last-state-fallback.enabled` to false. In last state upgrade mode, the so-called fallback time mainly uses the configuration `job.upgrade.last-state.max.allowed.checkpoint.age`. If the job's latest checkpoint exceeds this configuration, i.e., the checkpoint is too old, it will use savepoint upgrade mode.

The above logic is common to both FlinkDeployment and FlinkSessionJob. As mentioned in section 5.1.2.1 on basic interfaces and class hierarchy, AbstractJobReconciler abstracts the common logic for lifecycle management of jobs in Application mode FlinkDeployment and corresponding jobs in FlinkSessionJob.

For upgrade modes in Application cluster mode, ApplicationReconciler further extends the following logic based on AbstractJobReconciler's getJobUpgrade method:

```java
@Override
protected JobUpgrade getJobUpgrade(
        FlinkResourceContext<FlinkDeployment> ctx, Configuration deployConfig)
        throws Exception {

    var deployment = ctx.getResource();
    var status = deployment.getStatus();
    
    // First call parent method to get basic upgrade strategy
    var availableUpgradeMode = super.getJobUpgrade(ctx, deployConfig);

    // If upgrade strategy is available or fallback not allowed, directly return parent result
    if (availableUpgradeMode.isAvailable() || !availableUpgradeMode.isAllowFallback()) {
        return availableUpgradeMode;
    }
    
    var flinkService = ctx.getFlinkService();

    // Check if high availability mode is activated and HA metadata is available
    // If job is not running but HA metadata is available, last state restore upgrade can be performed
    if (HighAvailabilityMode.isHighAvailabilityModeActivated(deployConfig)
            && HighAvailabilityMode.isHighAvailabilityModeActivated(ctx.getObserveConfig())
            && flinkService.isHaMetadataAvailable(deployConfig)) {
        LOG.info(
                "Job is not running but HA metadata is available for last state restore, ready for upgrade");
        return JobUpgrade.lastStateUsingHaMeta();
    }

    var jmDeployStatus = status.getJobManagerDeploymentStatus();
    
    // Special handling: if JM deployment status is not MISSING, upgrade mode is not LAST_STATE, and JM Pod never started
    // This case needs to delete unstarted JM, then re-evaluate upgrade strategy
    if (jmDeployStatus != JobManagerDeploymentStatus.MISSING
            && status.getReconciliationStatus()
                            .deserializeLastReconciledSpec()
                            .getJob()
                            .getUpgradeMode()
                    != UpgradeMode.LAST_STATE
            && FlinkUtils.jmPodNeverStarted(ctx.getJosdkContext())) {
        
        // Delete JM that never started, clean up abnormal state
        deleteJmThatNeverStarted(flinkService, deployment, deployConfig);
        
        // Recursively call self method, re-evaluate upgrade strategy based on cleaned state
        // Note: This is a conditional recursion, ensuring termination through state changes
        return getJobUpgrade(ctx, deployConfig);
    }

    // Check JM deployment status: if JM is missing or error, and HA metadata unavailable
    // In this case, stateful upgrade cannot be performed, throw exception
    if ((jmDeployStatus == JobManagerDeploymentStatus.MISSING
                    || jmDeployStatus == JobManagerDeploymentStatus.ERROR)
            && !flinkService.isHaMetadataAvailable(deployConfig)) {
        throw new UpgradeFailureException(
                "JobManager deployment is missing and HA data is not available to make stateful upgrades. "
                        + "It is possible that the job has finished or terminally failed, or the configmaps have been deleted. "
                        + "Manual restore required.",
                "UpgradeFailed");
    }

    // If all above conditions are not met, return unavailable upgrade strategy
    return JobUpgrade.unavailable();
}
```

For Application cluster mode, the supplementary logic here lies in the last state upgrade mode. The two most core points are: first, supplementing AbstractJobReconciler when job upgrade mode is last state, if HA is enabled, perform job recovery according to the latest checkpoint in HA metadata; second, considering the case where JobManager's Deployment never started normally due to configuration errors, the code will delete the old Deployment and redeploy according to the latest deployment configuration, then re-evaluate the upgrade mode. Finally, if this deployment has errors, it will throw an UpgradeFailureException.

If readers understand the upgrade modes in different situations, they can have some intuitive understanding of spec change processing in Application cluster mode. Readers can understand that the core of spec change processing is to cancel and restore jobs according to upgrade modes, in other words, managing job lifecycle.

For other spec change processing, for Application cluster mode, this abstract method reconcileOtherChanges is implemented by AbstractJobReconciler and ApplicationReconciler. The code in AbstractJobReconciler is as follows:

```java
@Override
public boolean reconcileOtherChanges(FlinkResourceContext<CR> ctx) throws Exception {
    var status = ctx.getResource().getStatus();
    var jobStatus = status.getJobStatus().getState();
    
    // Check if job failed and if failed job restart is enabled
    if (jobStatus == org.apache.flink.api.common.JobStatus.FAILED
            && ctx.getObserveConfig().getBoolean(OPERATOR_JOB_RESTART_FAILED)) {
        
        LOG.info("Stopping failed Flink job...");
        
        // Clean up resources related to failed job
        cleanupAfterFailedJob(ctx);
    
        // Clear error status, prepare for resubmission
        status.setError(null);
        
        // Resubmit job, don't require HA metadata (because job failed, may not have available checkpoints)
        resubmitJob(ctx, false);
        
        return true;
    } else {
        // If job didn't fail, check if snapshot operations need to be triggered
        
        // Check if savepoint needs to be triggered
        // This is usually used for job upgrades or manual snapshot requirements
        boolean savepointTriggered = triggerSnapshotIfNeeded(ctx, SAVEPOINT);
        
        // Check if checkpoint needs to be triggered
        // This is usually used for automatic checkpoints or configured checkpoint strategies
        boolean checkpointTriggered = triggerSnapshotIfNeeded(ctx, CHECKPOINT);

        // Return whether any snapshot operation was triggered
        // If savepoint or checkpoint was triggered, return true; otherwise return false
        return savepointTriggered || checkpointTriggered;
    }
}
```

In the code, the logic for failed job restart corresponds to the configuration `job.restart.failed` which is disabled by default (corresponding to false), because if the job is configured with failure count, when the failure count is reached, the job will become failed state, and with this failure restart, the job will restart in an infinite loop, so it's not recommended to enable it. Therefore, this function generally periodically triggers savepoints or checkpoints. If triggering succeeds, it indicates that both cluster and job are normal. The internal implementation also uses FlinkService to make REST API calls. If the call succeeds, it returns true. If any trigger fails, it returns false, and the ApplicationReconciler implementation will further check cluster and job health status and perform recovery.

The code implementation in ApplicationReconciler is as follows:

```java
@Override
public boolean reconcileOtherChanges(FlinkResourceContext<FlinkDeployment> ctx)
        throws Exception {
    
    // First call parent method to handle basic changes (like failed job restart, snapshot triggering, etc.)
    // If parent method returns true, it means changes have been handled, return directly
    if (super.reconcileOtherChanges(ctx)) {
        return true;
    }

    var deployment = ctx.getResource();
    var observeConfig = ctx.getObserveConfig();
    
    // Check if job needs restart due to unhealthiness
    // This is usually based on cluster health check results
    boolean shouldRestartJobBecauseUnhealthy =
            shouldRestartJobBecauseUnhealthy(deployment, observeConfig);
    
    // Check if deployment recovery is needed
    // This usually checks if JobManager's Deployment exists and is normal
    boolean shouldRecoverDeployment = shouldRecoverDeployment(observeConfig, deployment);
    
    // If unhealthy job restart or deployment recovery is needed, execute corresponding operations
    if (shouldRestartJobBecauseUnhealthy || shouldRecoverDeployment) {
        
        // If deployment recovery is needed, trigger deployment recovery event
        if (shouldRecoverDeployment) {
            eventRecorder.triggerEvent(
                    deployment,
                    EventRecorder.Type.Warning,           // Event type: Warning
                    EventRecorder.Reason.RecoverDeployment, // Event reason: Recover deployment
                    EventRecorder.Component.Job,           // Event component: Job
                    MSG_RECOVERY,                          // Recovery message
                    ctx.getKubernetesClient());
        }

        // If unhealthy job restart is needed, trigger restart event and clean up resources
        if (shouldRestartJobBecauseUnhealthy) {
            eventRecorder.triggerEvent(
                    deployment,
                    EventRecorder.Type.Warning,                // Event type: Warning
                    EventRecorder.Reason.RestartUnhealthyJob,  // Event reason: Restart unhealthy job
                    EventRecorder.Component.Job,               // Event component: Job
                    MSG_RESTART_UNHEALTHY,                     // Restart unhealthy job message
                    ctx.getKubernetesClient());
            
            // Clean up resources related to failed job, prepare for resubmission
            cleanupAfterFailedJob(ctx);
        }

        // Resubmit job
        // Decide whether HA metadata is needed based on whether high availability mode is enabled
        resubmitJob(
                ctx,
                HighAvailabilityMode.isHighAvailabilityModeActivated(ctx.getObserveConfig()));
        
        return true; // Indicates changes have been handled
    }

    // If no restart or recovery is needed, check if expired JobManager needs cleanup
    // This is usually used to clean up JobManager resources that have terminated but not been deleted
    return cleanupTerminalJmAfterTtl(ctx.getFlinkService(), deployment, observeConfig);
}
```

The function first calls the parent class's reconcileOtherChanges method. If it returns true, it means the parent class has already restarted the job or saved savepoints or checkpoints, so there's no need to check job or cluster health status, and it exits directly. The `shouldRestartJobBecauseUnhealthy` method's judgment basis is the cluster health check performed in the business observation phase of section 5.2.3.1 ApplicationObserver observation process. Users need to configure `cluster.health-check.enabled` to enable cluster health check. The cluster health check result is clusterHealthInfo. If the cluster is not healthy and the upgrade mode is stateless upgrade, or the cluster's high availability is enabled, then the job needs to be restarted. The `shouldRecoverDeployment` method's judgment basis is whether the JobManager's corresponding Deployment deployment is normal. If not normal, deployment recovery is needed, but users need to configure `jm-deployment-recovery.enabled` to enable this logic. When the cluster is unhealthy, the code calls the `cleanupAfterFailedJob` method to clean up the cluster deployment, then calls the `resubmitJob` method to recreate the cluster and submit the job.

If the job is already in terminal state, savepoint and checkpoint operations won't be handled, so the parent method will return false. At this time, the cluster needs to be cleaned up. The code calls the `cleanupTerminalJmAfterTtl` method. When cleaning up the cluster, it corresponds to the configuration `jm-deployment.shutdown-ttl` with a default value of 1 day, meaning if the job's terminal state update time was 1 day ago, the cluster will be cleaned up.

Finally, readers will often see cluster cleanup logic in the code, i.e., FlinkService's deleteClusterDeployment method. This method has a boolean parameter deleteHaData, corresponding to whether to delete HA data. For cluster cleanup, it's generally false, corresponding to not cleaning up. Readers might be confused about when HA data is cleaned up. The answer is that it's only cleaned up when cleaning up the FlinkDeployment custom resource.

### 5.2.6 Resource Cleanup Phase

In the resource cleanup phase, FlinkDeploymentController implements the Cleaner interface of Java Operator SDK. The implementation of its cleanup method is as follows:

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

We can see that the main logic of this function first performs canary resource judgment, then also performs observation and reconciliation. During reconciliation, it calls the cleanup method. Next, let's mainly look at the implementation of this method:

```java
@Override
public DeleteControl cleanup(FlinkResourceContext<CR> ctx) {
    // Get Flink deployment resource and status information
    var deployment = ctx.getResource();
    var status = deployment.getStatus();
    var conf = ctx.getDeployConfig(ctx.getResource().getSpec());
    
    // Check if before first deployment or job is already in terminal state
    if (status.getReconciliationStatus().isBeforeFirstDeployment()
            || ReconciliationUtils.isJobInTerminalState(status)) {
        // If job was never deployed or already terminated, directly delete cluster deployment
        // deleteClusterDeployment method will:
        // 1. Delete JobManager and TaskManager deployments in Kubernetes
        // 2. Decide whether to delete HA metadata based on deleteHaData parameter
        // 3. Update deployment status to deleted
        ctx.getFlinkService()
                .deleteClusterDeployment(deployment.getMetadata(), status, conf, true);
    } else {
        // If job is running, need to gracefully stop job first
        var observeConfig = ctx.getObserveConfig();
        // Decide stop mode based on configuration:
        // SAVEPOINT: Create savepoint then stop job, retain state for recovery
        // STATELESS: Stateless stop, don't create savepoint
        var suspendMode =
                observeConfig.getBoolean(KubernetesOperatorConfigOptions.SAVEPOINT_ON_DELETION)
                        ? SuspendMode.SAVEPOINT
                        : SuspendMode.STATELESS;
        // cancelJob method will execute different stop strategies based on suspendMode:
        // - SAVEPOINT: Create savepoint then cancel job, then delete cluster
        // - STATELESS: Directly cancel job, then delete cluster
        cancelJob(ctx, suspendMode);
    }
    // Return default delete control, indicating resource can be safely deleted
    return DeleteControl.defaultDelete();
}
```

From the code comments, we can see that when cleaning up FlinkDeployment resources, HA metadata is only completely deleted when cleaning up cluster resources. However, if the job is running, it will first gracefully stop the job, then delete the cluster. When deleting the cluster, if the user has configured `job.savepoint-on-deletion` to true, it will create a savepoint when stopping the job, then not delete the cluster, waiting for the next cleanup trigger to delete the cluster. If the user has configured `job.savepoint-on-deletion` to false, it will directly delete the cluster when stopping the job and delete metadata at the same time.

The above is all the content of the business reconciliation phase. Next, we will enter the source code analysis of FlinkSessionJobController.

## 5.3 FlinkSessionJob Controller Source Code Analysis

### 5.3.1 Core Member Variables and Methods

FlinkSessionJobController is the controller responsible for managing FlinkSessionJob resources. Its structure is similar to FlinkDeploymentController, but specifically handles session job resources.

```java
@ControllerConfiguration()
public class FlinkSessionJobController
        implements Reconciler<FlinkSessionJob>,
                ErrorStatusHandler<FlinkSessionJob>,
                EventSourceInitializer<FlinkSessionJob>,
                Cleaner<FlinkSessionJob> {

    // Core member variables
    private final Set<FlinkResourceValidator> validators;                    // Resource validator collection
    private final FlinkResourceContextFactory ctxFactory;                   // Resource context factory
    private final Reconciler<FlinkSessionJob> reconciler;                   // Reconciler
    private final Observer<FlinkSessionJob> observer;                       // Observer
    private final StatusRecorder<FlinkSessionJob, FlinkSessionJobStatus> statusRecorder;  // Status recorder
    private final EventRecorder eventRecorder;                              // Event recorder
    private final CanaryResourceManager<FlinkSessionJob> canaryResourceManager;  // Canary resource manager
}
```

**Member Variable Descriptions**:
- **validators**: Validation plugins for validating FlinkSessionJob resources
- **ctxFactory**: Resource context factory, responsible for creating processing contexts for FlinkSessionJob
- **reconciler**: Reconciler, creates corresponding reconcilers based on deployment mode
- **observer**: Observer, responsible for creating and managing FlinkSessionJob observers
- **statusRecorder**: Status recorder, manages FlinkSessionJob status caching and updates
- **eventRecorder**: Event recorder, responsible for recording and triggering Kubernetes events
- **canaryResourceManager**: Canary resource manager, handles special logic for canary resources

#### Class Diagram

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

We have already explained these corresponding functions in Chapter 2. The main logic of FlinkSessionJobController is to implement the methods of these interfaces:
- Reconciler: Core interface of Java Operator SDK, defines the reconcile method for reconciliation logic
- ErrorStatusHandler: Error status handling interface, handles the updateErrorStatus method for exceptions during reconciliation
- EventSourceInitializer: Event source initialization interface, sets up event listening with prepareEventSources method
- Cleaner: Resource cleanup interface, handles resource deletion logic with cleanup method

These methods have also been mentioned in section 5.2.1, so we won't repeat them here.

### 5.3.2 Reconciliation Preparation Phase

```java
@Override
public UpdateControl<FlinkDeployment> reconcile(FlinkDeployment flinkApp, Context josdkContext)
        throws Exception {

    // 1. Canary resource handling: if it's a canary resource, return directly without update
    // Canary resources are used for testing and validation, no actual reconciliation operations needed
     if (canaryResourceManager.handleCanaryResourceReconciliation(
            flinkSessionJob, josdkContext.getClient())) {
        return UpdateControl.noUpdate();
    }

    LOG.info("Starting reconciliation");

    // 2. Status recovery: update resource status from cache, reduce possibility of status inconsistency
    // If resource is not in cache, add it to cache, ensure status consistency
    statusRecorder.updateStatusFromCache(flinkSessionJob);
    
    // 3. Resource cloning: create a copy of current resource for subsequent status comparison
    // This copy will be used to detect resource status changes and decide whether update is needed
    FlinkSessionJob previousJob = ReconciliationUtils.clone(flinkSessionJob);
    
    // 4. Context creation: create dedicated processing context for current resource
    // Context contains Kubernetes client, configuration information and all components needed during reconciliation
    var ctx = ctxFactory.getResourceContext(flinkSessionJob, josdkContext);

    // 5. Version validation: check if Flink version is supported, if not trigger event and exit
    // Ensure Operator can handle current Flink version, avoid problems caused by version incompatibility
    if (!ValidatorUtils.validateSupportedVersion(ctx, eventRecorder)) {
        return UpdateControl.noUpdate();
    }

    // 6. Observation, validation, reconciliation phase code
    // ... other code ...

    // Return update control instruction, inform JOSDK that resource needs to be updated
    return UpdateControl.update(flinkSessionJob);
}
```

**Core Steps of Reconciliation Preparation Phase**

1. Canary resource check: Prioritize handling canary resources, return directly if it's a canary resource
2. Status recovery: Recover resource status from local cache, avoid status inconsistency caused by JOSDK cache
3. Resource backup: Create a copy of current resource for subsequent status change comparison
4. Context construction: Create processing context containing Kubernetes client, configuration and other information
5. Version validation: Validate Flink version compatibility, ensure Operator can handle this version

The resource backup here just clones the object again, with no special logic. Except for version validation, other steps have been mentioned in previous sections. Readers can refer to the previous introduction by looking at the functions directly. The version compatibility relationship between FlinkOperator and Flink has been mentioned in section 5.2.2. Readers can refer back to the previous content, so we won't repeat it here.

### 5.3.3 Reconciliation Observation Phase

In FlinkSessionJobController's reconcile method, the observation phase code implementation is as follows:

```java
@Override
public UpdateControl<FlinkSessionJob> reconcile(FlinkSessionJob flinkSessionJob, Context josdkContext) {
    // ... previous preparation phase code ...
    
    // Observation phase: execute FlinkSessionJob observation logic
    observer.observe(ctx);
    
    // ... subsequent validation and reconciliation logic ...
}
```

Unlike FlinkDeploymentController, FlinkSessionJobController uses a single observer instance instead of factory pattern. This is because FlinkSessionJob has only one running mode and doesn't need to create different observers based on different modes.

**FlinkSessionJobObserver Observation Flow**

FlinkSessionJobObserver inherits from AbstractFlinkResourceObserver, and its observation logic is specifically optimized for session jobs.

```java
@Override
public final void observe(FlinkResourceContext<CR> ctx) {
    // Check if resource is ready to be observed
    if (!isResourceReadyToBeObserved(ctx)) {
        return;
    }

    // Trigger resource-specific observation logic
    observeInternal(ctx);

    // Reset snapshot triggers
    SnapshotUtils.resetSnapshotTriggers(
            ctx.getResource(), eventRecorder, ctx.getKubernetesClient());
}
```

**FlinkSessionJob-Specific Readiness Check**

FlinkSessionJobObserver overrides the `isResourceReadyToBeObserved` method, adding session job-specific checks:

```java
@Override
protected boolean isResourceReadyToBeObserved(FlinkResourceContext<FlinkSessionJob> ctx) {
    // 1. Call parent class basic checks (suspended state, upgrade state, rollback state, etc.)
    // 2. Additional check: ensure FlinkService is available (target session cluster must be accessible)
    return super.isResourceReadyToBeObserved(ctx) && ctx.getFlinkService() != null;
}
```

This additional check is important: `ctx.getFlinkService() != null` ensures the target session cluster is accessible. If the session cluster is not accessible, job status observation cannot be performed.

**Core Observation Logic (observeInternal)**

According to the source code, FlinkSessionJobObserver's observeInternal method implementation is very concise:

```java
@Override
protected void observeInternal(FlinkResourceContext<FlinkSessionJob> ctx) {
    // 1. First observe job status, return whether job was found
    var jobFound = jobStatusObserver.observe(ctx);
    
    // 2. Only perform snapshot status observation if job was found
    if (jobFound) {
        // Observe savepoint status
        savepointObserver.observeSavepointStatus(ctx);
        // Observe checkpoint status
        savepointObserver.observeCheckpointStatus(ctx);
    }
}
```

We have already mentioned jobStatusObserver and savepointObserver in sections 5.1.1.1 and 5.1.1.2. Readers can refer back to the previous content, so we won't repeat it here. In summary, FlinkSessionJobObserver and SessionObserver observation logic complement each other. SessionObserver observes Session cluster status, while FlinkSessionJobObserver observes job status and savepoint/checkpoint status.

**Key Differences from FlinkDeployment Observation**

| Comparison Item | FlinkSessionJob | FlinkDeployment |
|-----------------|-----------------|------------------|
| Observer Creation | Single observer instance | Factory pattern creates multiple observers |
| JobManager Management | Depends on existing session cluster | Needs to observe own JobManager deployment |
| Readiness Check | Additional FlinkService availability check | Check JobManager deployment status |
| Observation Content | Job status + snapshot status | Cluster deployment + job status + snapshot status + cluster health |
| Complexity | Relatively simple | More complex |

FlinkSessionJob's observation logic reflects the characteristics of session mode: **depend on existing cluster, focus on job itself**. This design makes session job observation more efficient and focused.

### 5.3.4 Reconciliation Validation Phase

FlinkSessionJob's validation phase is implemented through the `validateSessionJob` method in FlinkSessionJobController. Its complexity is higher than FlinkDeployment because it needs to validate the compatibility between session job and target session cluster.

In the reconcile method, the validation phase code implementation is as follows:

```java
@Override
public UpdateControl<FlinkSessionJob> reconcile(FlinkSessionJob flinkSessionJob, Context josdkContext) {
    // ... previous observation phase code ...
    
    // Validation phase: validate FlinkSessionJob resource configuration validity
    if (!validateSessionJob(ctx)) {
        // Validation failed: update status and stop reconciliation flow
        statusRecorder.patchAndCacheStatus(flinkSessionJob, ctx.getKubernetesClient());
        return ReconciliationUtils.toUpdateControl(
                ctx.getOperatorConfig(), flinkSessionJob, previousJob, false);
    }
    
    // ... subsequent reconciliation logic ...
}
```

**Core Validation Method (validateSessionJob)**

According to the source code, the `validateSessionJob` method implementation in FlinkSessionJobController is as follows:

```java
private boolean validateSessionJob(FlinkResourceContext<FlinkSessionJob> ctx) {
    var sessionJob = ctx.getResource();
    
    // Iterate through all validation plugins
    for (FlinkResourceValidator validator : validators) {
        Optional<String> validationError =
                validator.validateSessionJob(
                        sessionJob,
                        // Key: get target session cluster resource through JOSDK
                        // This is the core of session job validation - needs target cluster information for compatibility validation
                        ctx.getJosdkContext().getSecondaryResource(FlinkDeployment.class));
                        
        if (validationError.isPresent()) {
            // Validation failure handling
            // Apply validation error and reset spec
            ReconciliationUtils.applyValidationErrorAndResetSpec(
                    sessionJob, validationError.get(), eventRecorder, ctx.getKubernetesClient());
            return false;
        }
    }
    
    return true;
}
```

**Key Validation Points**

1. **Target Cluster Validation**: The most important validation is ensuring the target session cluster exists and is accessible
2. **Version Compatibility**: Validate Flink version compatibility between session job and target cluster
3. **Resource Configuration**: Validate job configuration, parallelism, resources, etc.
4. **Dependency Validation**: Validate external dependencies like JAR files, configuration files, etc.

The validation process is more complex than FlinkDeployment because it needs to consider the relationship with the target session cluster, not just the job itself.

The built-in DefaultValidator implements two-layer logic in validateSessionJob. When creating FlinkSessionJob resources, deploymentName needs to be specified to correspond to the Session cluster's FlinkDeployment resource. Since FlinkDeployment resources are created first, when FlinkSessionJob resources are created, FlinkDeployment resources may not exist yet, so two-layer validation is needed.

```java
@Override
public Optional<String> validateSessionJob(
        FlinkSessionJob sessionJob, Optional<FlinkDeployment> sessionOpt) {
    
    if (sessionOpt.isEmpty()) {
        // Target session cluster doesn't exist or not ready: only validate session job itself
        return validateSessionJobOnly(sessionJob);
    } else {
        // Target session cluster exists: perform complete compatibility validation
        return firstPresent(
                validateSessionJobOnly(sessionJob),           // Job independent validation
                validateSessionJobWithCluster(sessionJob, sessionOpt.get()));  // Cluster compatibility validation
    }
}
```

The first layer is responsible for session job independent validation (validateSessionJobOnly)

```java
private Optional<String> validateSessionJobOnly(FlinkSessionJob sessionJob) {
    return firstPresent(
            // 1. Deployment name validation: check if deploymentName is valid
            validateDeploymentName(sessionJob.getSpec().getDeploymentName()),
            
            // 2. Job configuration validation: check if job configuration is not empty
            validateJobNotEmpty(sessionJob),
            
            // 3. Spec change validation: check validity of spec changes
            validateSpecChange(sessionJob));
}
```

The second layer is responsible for cluster compatibility validation (validateSessionJobWithCluster)

```java
private Optional<String> validateSessionJobWithCluster(
        FlinkSessionJob sessionJob, FlinkDeployment sessionCluster) {
    
    // 1. Build effective configuration: merge default config, session cluster config, session job config
    Map<String, String> effectiveConfig =
            configManager.getDefaultConfig(
                    sessionJob.getMetadata().getNamespace(),
                    sessionCluster.getSpec().getFlinkVersion()).toMap();
                    
    // Merge session cluster's Flink configuration
    if (sessionCluster.getSpec().getFlinkConfiguration() != null) {
        effectiveConfig.putAll(sessionCluster.getSpec().getFlinkConfiguration());
    }
    
    // Merge session job's Flink configuration (highest priority)
    if (sessionJob.getSpec().getFlinkConfiguration() != null) {
        effectiveConfig.putAll(sessionJob.getSpec().getFlinkConfiguration());
    }
    
    // 2. Execute multiple compatibility checks
    return firstPresent(
            // Ensure target is not application mode cluster
            validateNotApplicationCluster(sessionCluster),
            
            // Validate session cluster ID consistency
            validateSessionClusterId(sessionJob, sessionCluster),
            
            // Validate job spec compatibility with merged configuration
            validateJobSpec(sessionJob.getSpec().getJob(), null, effectiveConfig),
            
            // Validate auto-scaler configuration
            validateAutoScalerFlinkConfiguration(effectiveConfig));
}
```

### 5.3.5 Reconciliation Deployment Phase

FlinkSessionJob's reconciliation deployment phase is the core of the entire reconcile process, responsible for actual job lifecycle management. Unlike FlinkDeployment, FlinkSessionJob doesn't need to manage cluster deployment, but focuses on job submission, updates, and management.

In the reconcile method, the reconciliation deployment phase code implementation is as follows:

```java
@Override
public UpdateControl<FlinkSessionJob> reconcile(FlinkSessionJob flinkSessionJob, Context josdkContext) {
    // ... previous observation, validation phase code ...
    
    try {
        // Update status in cache (save modifications from observation and validation phases)
        statusRecorder.patchAndCacheStatus(flinkSessionJob, ctx.getKubernetesClient());
        
        // Reconciliation phase: execute actual job lifecycle management
        reconciler.reconcile(ctx);
        
    } catch (Exception e) {
        // ... exception handling ...
    }
    
    // Final status update and return control instruction
    statusRecorder.patchAndCacheStatus(flinkSessionJob, ctx.getKubernetesClient());
    return ReconciliationUtils.toUpdateControl(
            ctx.getOperatorConfig(), flinkSessionJob, previousJob, true);
}
```

Unlike FlinkDeployment, FlinkSessionJob uses a single SessionJobReconciler instance as the reconciler, no factory pattern needed. SessionJobReconciler inherits from AbstractJobReconciler, reuses AbstractFlinkResourceReconciler's template method pattern, including 5 steps: ready to reconcile, deployment process, scaling handling, change handling, other coordination. We still follow the approach in section 5.2.5, dividing the 5 steps into two phases: cluster reconciliation phase and business reconciliation phase.

#### Cluster Reconciliation Phase

The first step of cluster reconciliation phase is readiness check, checking if the session cluster is ready. SessionJobReconciler overrides the readyToReconcile method, adding session job-specific readiness checks:

```java
@Override
public boolean readyToReconcile(FlinkResourceContext<FlinkSessionJob> ctx) {
    // 1. Check if session cluster is ready
    return sessionClusterReady(
                    ctx.getJosdkContext().getSecondaryResource(FlinkDeployment.class))
            // 2. Call parent class basic readiness check (first deployment, need to wait for savepoint, etc.)
            && super.readyToReconcile(ctx);
}
```

The `sessionClusterReady` method specifically checks the target session cluster status:

```java
public static boolean sessionClusterReady(Optional<FlinkDeployment> flinkDeploymentOpt) {
    if (flinkDeploymentOpt.isPresent()) {
        var flinkdep = flinkDeploymentOpt.get();
        var jobmanagerDeploymentStatus = flinkdep.getStatus().getJobManagerDeploymentStatus();
        
        // Only when session cluster's JobManager is in READY status can jobs be submitted
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

This check ensures that jobs are only reconciled after the target session cluster is fully ready, avoiding problems of submitting jobs to unready clusters.

The second step of cluster reconciliation phase is deployment process. SessionJobReconciler's deploy method specifically handles job submission logic, much simplified compared to FlinkDeployment's cluster deployment:

```java
@Override
public void deploy(
        FlinkResourceContext<FlinkSessionJob> ctx,
        FlinkSessionJobSpec sessionJobSpec,
        Configuration deployConfig,
        Optional<String> savepoint,
        boolean requireHaMetadata)
        throws Exception {

    // 1. Trigger job submission event recording
    eventRecorder.triggerEvent(
            ctx.getResource(),
            EventRecorder.Type.Normal,
            EventRecorder.Reason.Submit,
            EventRecorder.Component.Job,
            MSG_SUBMIT,
            ctx.getKubernetesClient());

    // 2. Generate job ID and record in status for persistence
    // This ensures job ID consistency and traceability during deployment process
    var jobId = JobID.generate();
    ctx.getResource().getStatus().getJobStatus().setJobId(jobId.toHexString());
    statusRecorder.patchAndCacheStatus(ctx.getResource(), ctx.getKubernetesClient());

    // 3. Submit job to session cluster through FlinkService
    // This is the core job submission operation, submitting job jar and configuration to existing session cluster
    ctx.getFlinkService()
            .submitJobToSessionCluster(
                    ctx.getResource().getMetadata(),
                    sessionJobSpec,
                    jobId,
                    deployConfig,
                    savepoint.orElse(null));

    // 4. Set job status to reconciling
    // Indicates job has been submitted, waiting for Flink cluster processing
    var status = ctx.getResource().getStatus();
    status.getJobStatus().setState(org.apache.flink.api.common.JobStatus.RECONCILING);
}
```

The deployment logic is relatively simple, just relying on FlinkService to call its submitJobToSessionCluster method, submitting jobs to session cluster through REST API.

#### Business Reconciliation Phase

The first step of business reconciliation phase is spec change handling. Since SessionJobReconciler inherits from AbstractJobReconciler abstract class, FlinkSessionJob's spec change handling logic is consistent with the AbstractJobReconciler's abstract method reconcileSpecChange implementation mentioned in section 5.2.5 business reconciliation phase. Readers can refer back to section 5.2.5.

The difference is that SessionJobReconciler implements specialized job cancellation logic:

```java
@Override
protected boolean cancelJob(FlinkResourceContext<FlinkSessionJob> ctx, SuspendMode suspendMode)
        throws Exception {
    // 1. Call FlinkService to cancel session job
    var result =
            ctx.getFlinkService()
                    .cancelSessionJob(ctx.getResource(), suspendMode, ctx.getObserveConfig());
    
    // 2. If savepoint was created during cancellation, record savepoint path for subsequent upgrade
    result.getSavepointPath().ifPresent(location -> setUpgradeSavepointPath(ctx, location));
    
    // 3. Return whether there are still pending cancellation operations
    return result.isPending();
}
```

The second step of business reconciliation phase is other spec change handling. Since SessionJobReconciler inherits from AbstractJobReconciler abstract class, FlinkSessionJob's other spec change handling logic is consistent with the AbstractJobReconciler's abstract method reconcileOtherChanges implementation mentioned in section 5.2.5 business reconciliation phase.

The difference is that SessionJobReconciler implements cleanupAfterFailedJob method as an empty method:

```java
@Override
protected void cleanupAfterFailedJob(FlinkResourceContext<FlinkSessionJob> ctx) {
    // For session jobs, failed jobs have already stopped, no additional cleanup needed
    // This is different from Application mode, where cluster needs to be cleaned up when failed
}
```

The reason is that when the job is already in failed state, the FlinkSessionJob resource reconciliation process doesn't need to clean up cluster deployment anymore.

### 5.3.6 Resource Cleanup Phase

In the resource cleanup phase, FlinkSessionJobController implements the Cleaner interface of Java Operator SDK, and the implementation of its cleanup method is as follows:

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

We can see that the main logic of this function first performs canary resource judgment, then also performs observation and reconciliation. During reconciliation, it calls the cleanup method. Next, let's look at the implementation of this method:

```java
@Override
public DeleteControl cleanup(FlinkResourceContext<CR> ctx) {
    autoscaler.cleanup(ResourceID.fromResource(ctx.getResource()));
    return cleanupInternal(ctx);
}
```

We'll ignore the autoscaler logic for now. When deleting FlinkSessionJob resources, SessionJobReconciler's cleanupInternal method is responsible for cleaning up the job:

```java
@Override
public DeleteControl cleanupInternal(FlinkResourceContext<FlinkSessionJob> ctx) {
    var status = ctx.getResource().getStatus();
    long delay = ctx.getOperatorConfig().getProgressCheckInterval().toMillis();
    
    // 1. If job is not deployed or has terminated, delete directly
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
    
    // Job is still running, need to cancel it
    var observeConfig = ctx.getObserveConfig();
    var suspendMode = observeConfig.getBoolean(KubernetesOperatorConfigOptions.SAVEPOINT_ON_DELETION)
            ? SuspendMode.SAVEPOINT
            : SuspendMode.STATELESS;
    
    try {
        // Cancel the job with specified suspend mode
        cancelJob(ctx, suspendMode);
        
        // Wait for job to reach terminal state
        if (waitForJobTermination(ctx, delay)) {
            return DeleteControl.defaultDelete();
        } else {
            // Job didn't terminate in time, need to wait for next cleanup
            return DeleteControl.noFinalizerRemoval();
        }
    } catch (Exception e) {
        LOG.error("Error during job cleanup", e);
        return DeleteControl.noFinalizerRemoval();
    }
}
```

The cleanup logic for FlinkSessionJob is simpler than FlinkDeployment because it only needs to cancel the job, not manage cluster deployment. The key difference is that session jobs don't need to clean up cluster resources, only the job itself.

```java
@Override
public DeleteControl cleanupInternal(FlinkResourceContext<FlinkDeployment> ctx) {
    // Get all FlinkSessionJob resources associated with current session cluster
    // getSecondaryResources method returns all FlinkSessionJob associated with current FlinkDeployment
    Set<FlinkSessionJob> sessionJobs =
            ctx.getJosdkContext().getSecondaryResources(FlinkSessionJob.class);
    var deployment = ctx.getResource();
    
    // Check if there are any undeleted session jobs
    if (!sessionJobs.isEmpty()) {
        // If session jobs still exist, cannot delete session cluster
        // Construct error message listing all session job names that need to be deleted first
        var error =
                String.format(
                        "The session jobs %s should be deleted first",
                        sessionJobs.stream()
                                .map(job -> job.getMetadata().getName())
                                .collect(Collectors.toList()));
        
        // Trigger Kubernetes event to record cleanup failure reason
        // triggerEvent method creates a Warning type event recording cleanup failure reason
        if (eventRecorder.triggerEvent(
                deployment,
                EventRecorder.Type.Warning,
                EventRecorder.Reason.CleanupFailed,
                EventRecorder.Component.Operator,
                error,
                ctx.getKubernetesClient())) {
            LOG.warn(error);
        }
        
        // Return control without removing finalizer and schedule rescheduling
        // noFinalizerRemoval(): Don't remove finalizer, keep resource from being completely deleted
        // rescheduleAfter(): Reschedule cleanup operation after specified time
        return DeleteControl.noFinalizerRemoval()
                .rescheduleAfter(ctx.getOperatorConfig().getReconcileInterval().toMillis());
    } else {
        // If no session jobs, can safely stop session cluster
        LOG.info("Stopping session cluster");
        var conf = ctx.getDeployConfig(ctx.getResource().getSpec());
        
        // Delete cluster deployment
        // deleteClusterDeployment method will:
        // 1. Delete JobManager and TaskManager deployments in Kubernetes
        // 2. Delete high availability metadata (third parameter is true)
        // 3. Update deployment status
        ctx.getFlinkService()
                .deleteClusterDeployment(
                        deployment.getMetadata(), deployment.getStatus(), conf, true);
        
        // Return default delete control, indicating resource can be safely deleted
        return DeleteControl.defaultDelete();
    }
}
```

From the code, we can see that when cleaning up FlinkDeployment resources in Session mode, as long as there are still jobs existing, the cluster will not be deleted.
