---
title: "Flink on Karmada: Building Resilient Data Pipelines on Multi-Cluster K8s"
date: "2025-08-22T13:12:21+08:00"
draft: "false"
description: ""
---



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/af755d72-0586-425c-a954-5e947f2cd9d0.webp)




Hello everyone, and welcome to our talk. Thank you for joining us.  


Today, we will discuss "Flink on Karmada: Building Resilient Data Pipelines on Multi-Cluster Kubernetes." We will walk you through our journey to enable **stateful application failover** support on Apache Flink, as well as the collaboration between the Karmada community and the Bloomberg Streaming Analytics team to implement this feature.  


By the end of this session, we hope you will have gained valuable insights into this topic.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/73e0851a-50aa-47ba-a5ad-e24bddb98eb7.webp)


I have been introduced to the **Karmada** project and learned the fundamentals of enhancing data pipeline resiliency.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/7297b398-a262-4b72-a480-458689ca2b6b.webp)



Starting with introductions, my name is Michas Szacillo. I am a **Senior Software Engineer** and **Tech Lead** at Bloomberg. My name is Li Wang, and I am also a **Software Engineer** at Bloomberg. Together, we work on the **Streaming Platform Team**, which provides **Apache Flink** to various users within Bloomberg.  


For today's agenda, we will begin with a condensed overview of Apache Flink for those who may not be familiar, as it is the central focus of our discussion.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/95eff8fa-08ee-4aee-bd66-2fdb72ffa94e.webp)




Specifically, we will discuss the importance of **application state** and the recovery mechanisms provided by Apache Flink. With this context, we will examine the challenges of managing Flink applications in a **multi-cluster environment** while ensuring resiliency, and how we leveraged **Karmada** to enable automated and stateful cluster failover.  


Finally, we will explore the benefits of Karmada, its outcomes, limitations, and ongoing collaborative improvements with the Karmada community.  


At Bloomberg, we operate a **large-scale streaming platform** that supports critical financial data processing.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/425409da-2264-4647-82e1-048b0fb8fe28.webp)





We currently operate approximately 1,000 unique **Apache Flink** jobs across multiple Kubernetes clusters distributed across various tiers. These Flink jobs support diverse use cases, including data ETL, real-time analytics, and event processing.  


To illustrate its significance, this system is integral to Bloomberg's core financial products, delivering real-time market insights to traders, analysts, and financial professionals worldwide. The image displayed here features Bloomberg's terminal, where processed data is visualized, enabling users to make informed decisions in real-time.  


Given this scale, ensuring **reliability and efficiency** is our highest priority. This is where Apache Flink and **Karmada** play a critical role.  


So, what exactly is Apache Flink?






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/eea3b234-a64f-4a27-9275-5b313efd7cec.webp)


**Apache Flink** is a widely-used open-source data streaming framework. It offers **low latency**, flexibility, and high scalability for processing large-scale data. Additionally, it provides **exactly-once guarantees** to ensure data integrity. Furthermore, it includes built-in fault tolerance and state management systems to maintain reliability in distributed environments.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/818e1c6d-319a-4886-85dd-ca54df818210.webp)



Flink jobs often run continuously. However, failures can occur. To ensure **reliability**, Flink employs **state snapshots**, such as checkpoints and savepoints. In the event of a failure, Flink can automatically restore from the latest state, minimizing data loss and downtime.  


For example, events are ingested from an event log into a Flink application. Internally, the application periodically writes checkpoints to persistent storage. If a failure occurs, Flink restores from the latest checkpoint to ensure seamless recovery.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/c4040ba9-dc78-4535-92f5-88ec15409a31.webp)




Now that we understand **Apache Flink's** state management, let's discuss job deployment on **Kubernetes**. Apache Flink natively supports Kubernetes, enabling scalable and manageable deployments. The **Flink Operator** automates job lifecycle management, including deployments, upgrades, and auto-recovery.  


Here is the workflow:  


1. The user submits a job YAML file to Kubernetes.  
2. The Kubernetes API server processes the request.  
3. The Flink Operator deploys, upgrades, and monitors Flink jobs within the cluster.  
4. The result is a fully managed Flink job running on Kubernetes.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/903209f8-0bec-4b05-a177-aa95502d5220.webp)




In a distributed environment, failures are inevitable. However, **Flink** is designed to recover gracefully. With **high availability (HA)** settings, Flink can recover from cluster-internal failures such as hardware issues, pod crashes, or transient network issues.  


In the diagram, the left side illustrates normal job execution. The user code interacts with the **local state backend**, and the state is persisted as a **savepoint** in a distributed file system (DFS). If a failure occurs and the job crashes, the persistent savepoint remains intact.  


On the right side, when the job restarts, it reloads the savepoint, restores its state, and continues execution seamlessly.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/019c4b0c-2ef3-4b20-ac20-51a55bfa1cd2.webp)





As previously mentioned, the streaming platform team manages numerous **Apache Flink** applications. With the platform's growth, we encountered scalability challenges. Notably, control planes are currently bound to a single cluster. Given our multi-tier platform with numerous user-deployed jobs, this setup becomes increasingly cumbersome. Users must track deployment clusters, ensure sufficient resources, and manage multiple kube configs for their CD pipelines.  


Once deployed, these jobs are expected to run long-term while actively processing data. However, long-running jobs inevitably face failures. **Apache Flink** offers robust high availability support for intermittent failures, but this assumes recovery within the same cluster. For instance, in Kubernetes high availability, Flink writes metadata to the config map, referencing the latest state published by the application. If the config map is deleted and the job fails, the Flink operator cannot reconcile the latest state, requiring manual job reapplication.  


Currently, cluster failover is a manual process. If a cluster fails, tenants must either maintain their own high availability setup—such as running parallel pipelines in different data centers—or manually redeploy to a healthy cluster. This becomes error-prone as job volume increases. Additionally, cluster maintenance windows are costly and require coordination. With Kubernetes releasing quarterly updates, frequent migrations are necessary.  


Given these limitations, what should our ideal control plane look like?






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/11aa7e22-1f38-4bf9-9c18-4285e908cf64.webp)




We aimed to create a **unified control plane** that would allow users to manage their jobs with a single **kubeconfig**, submitting them to a centralized location.  


Once resources were applied, the control plane would intelligently schedule these applications to an appropriate cluster within the federation, considering factors such as available resources and node requirements.  


Additionally, the system would monitor the health of both the Kubernetes clusters and the scheduled applications. If the control plane detected prolonged issues with a cluster or application, it would automatically reschedule the application to another healthy cluster.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/4958312d-dc48-4b2f-b061-42f0d0ab5bb8.webp)





As we solidified our vision for a **central control plane**, we explored potential solutions under development. This led us to the **Karmada project**—an open-source Kubernetes management system designed to manage cloud-native applications across multiple Kubernetes clusters.  


Karmada offers customizable features tailored to specific use cases, enabling platform owners to efficiently manage groups of clusters from a single interface, thereby reducing operational overhead.  


**Key capabilities** include defining application deployment strategies across federated clusters with advanced features such as resource-aware scheduling and cluster affinity rules. Additionally, Karmada provides unified authentication and management endpoints for resource visibility and application control.  


Most notably, it supports **automated cross-cluster failover**, a critical feature we will discuss further.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/a40e3d20-27ad-4cf4-b164-72e8895825b3.webp)




To understand **automated failover** in Karmada, let's examine how it tracks two key aspects.  


For **cluster health**, Karmada utilizes existing Kubernetes health endpoints. If a cluster is deemed unhealthy after a grace period, it performs taint-based eviction and reschedules applications to healthier clusters.  


**Application health** monitoring is more granular, with Karmada providing a framework for users to define custom resource interpretation rules to determine application health status.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0c676d1a-bcf7-4ac3-8baa-3188fe324816.webp)




This diagram illustrates the initial version of our approach to managing and deploying **Flink** using **Karmada**. Users submit their namespace jobs to the Karmada API server endpoint, and we automatically generate the required propagation policy for their namespace.  


For context, a **propagation policy** is a custom resource in Karmada that defines how applications within its scope should be scheduled. In our implementation, we configured spread constraints for the Flink deployment to ensure it is scheduled exclusively to a single cluster, with all replicas co-located. This was achieved by setting the maximum cluster allocation to one.  


Upon successful scheduling, the Flink operator processes the deployment and initiates the job. The complete status is then reflected in the Karmada API.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/3a353660-76be-4ec3-9f51-38840321fddb.webp)





Now, let's discuss the initial limitations we encountered when integrating with **Karmada**.  


First, for application failover to function correctly, Karmada must interpret resource health status. However, with default settings, Karmada lacks awareness of **Flink state**, posing challenges during rescheduling.  


Second, when a Flink job is rescheduled to a new cluster, it must resume from its previous state. Unfortunately, the state is not preserved during failover, forcing the deployment to restart from scratch—an undesirable scenario for long-running streaming jobs.  


These limitations drove us to seek improved solutions for **state management** and failover.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/620f53fe-1669-440e-bcf2-f9b4306357bd.webp)





To achieve a better solution for failover, understanding job health is crucial. Flink maintains an internal job state machine, as illustrated in the simplified diagram on the right.  


A job is considered healthy if it is in a **RUNNING** state (indicated by green) or any of the terminated states (indicated by gray), such as **FAILED**, **FINISHED**, **CANCELED**, or **SUSPENDED**. However, if the job is in one of the ephemeral blue states—**RECONCILING**, **INITIALIZING**, or **CREATED**—we must exercise caution. If the issue stems from a user error, such as an incorrect image path, we classify the job as healthy and avoid triggering a failover. Conversely, if the job remains stuck in these states without a clear error, we deem it unhealthy.  


Additionally, the yellow-colored short-lived states—**RESTARTING**, **FAILING**, and **CANCELING**—are part of normal transitions and quickly lead to a terminal state. Therefore, we also classify these as healthy.  


Let’s now examine what constitutes a healthy state transition.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/c602ca34-6a5e-40a2-95bd-81347fbe3e51.webp)



Typically, a healthy **Flink job** begins in a reconciling state, where the **JobManager** has not yet been scheduled or reported its status. Subsequently, it transitions to initializing as the Flink components start up.  


Once the cluster is ready but not yet processing data, the job reaches the created state. Finally, it enters the running state, where the job becomes fully operational and begins processing data.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/fd92a7db-ebbb-4be6-af19-a8985d77ed50.webp)


Here is another example of an unhealthy state transition. As previously observed, the job is in a **running state** and processing data, with everything appearing normal. However, it suddenly reverts to the **created state**. This typically indicates an issue, such as a TaskManager crash or internal cluster problems.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/592fbcd8-fb67-4de5-9b78-0f51cfb00d20.webp)



By examining the job state, we can typically determine whether a job is healthy. However, certain **edge cases** require additional scrutiny beyond the internal job state.  


It is also necessary to inspect the **error field** within the state for deployment issues, which may arise from misconfigurations like incorrect container images or malformed YAML files. Runtime problems, such as application-level errors or faulty upgrades, can also contribute to these issues.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/2eef3437-c47f-4baf-a40a-3966c795a34e.webp)



This is what **Michał Szaciłło** previously demonstrated regarding running Apache Flink on Karmada. In addition to the existing PropagationPolicy, we introduced a **failover field** in the YAML configuration.  


With this modification, when a FlinkDeployment becomes unhealthy, Karmada will wait for the configured threshold duration before immediately initiating rescheduling.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/15608c13-88e4-4c50-9dfc-4ce3e89897ac.webp)




Was that a successful failover? Not exactly. Although **Karmada** detected the job failure and rescheduled the job, it always started anew, resulting in the loss of the running state.  


In **Apache Flink**, to gracefully resume after a failure, the latest checkpoint is required. Additionally, preserving the job ID across clusters is necessary to achieve this.  


As **Wang Li** described, while Karmada correctly detected application and cluster health, the failover process was not yet complete.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/1c567970-e9ea-4a26-9f73-7f55d55ce25b.webp)





We needed a method to preserve information from the previous job so the new job could reference where to start. Collaborating with the community, we developed a **state preservation enhancement**, extending the existing failover API.  


This is configured directly in the Karmada propagation policy and includes two fields:  
- A JSON path expression to identify the specific data to preserve in the status.  
- An alias label name for the label.  


As shown in the propagation policy on the right, this new API selects the `jobStatusjobId` field and injects it as a label into the newly failed-over Flink deployment.  


One final step remains.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/1b9e0256-1189-40de-8aae-9efedc805075.webp)





Although the **metadata** is injected as a label into the Flink deployment, we still need to convert it into a format that the Flink deployment can consume.  


We were already using **Kyverno webhooks** for validation and mutation. For those unfamiliar, Kyverno is a policy management tool that enables declarative definition of policies to validate and mutate watched resources.  


We decided to reuse it by implementing a mutating webhook to inject the necessary initial **savepoint path**, pointing to the latest state from the previously failed job.  


Here is the finalized diagram of our failover implementation.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/21ac4419-f75a-4ee3-ac19-3eae4ee2264e.webp)



Let's assume a job was successfully running on **Cluster B**. At some point, the application transitions to a reconciling state, indicating either a job manager crash or an operator issue preventing status retrieval. **Karmada** will treat this application as unhealthy (assuming no published errors) and begin counting down the toleration seconds defined in the resource propagation policy. Once the toleration period expires, failover will initiate.  


Karmada will extract the **job ID** from the published job status, delete the resource on Cluster B, then inject a state preservation label into the scheduled resource referencing the previous Flink cluster's ID. The **Coverno webhook** will intercept this request, retrieve the job ID, and set the initial savepoint path, enabling the Flink operator to recognize this as a stateful restart.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/6aede9ce-2349-4edf-b74a-ac49267b3418.webp)






There are several significant benefits to this approach. The **primary challenge** for many users was the need to manage and monitor multiple Kubernetes clusters. With a unified control plane, users can now apply, update, and manage their jobs from a single interface, which includes built-in authentication and intelligent scheduling. Another major advantage is the automation of **cross-cluster failover**, a critical feature for ensuring data pipeline resiliency.  


It is important to emphasize that cross-cluster failover should be a rare event. Apache Flink's high availability feature typically handles job failures within the same cluster, allowing applications to self-recover. This functionality is specifically designed for exceptional scenarios, such as partial or complete cluster failures. In such cases, it significantly reduces the time required for platform owners to intervene and enables applications to automatically recover in a healthier cluster without user involvement.  


**Failover requirements** can vary among users, so the flexibility and configurability of these definitions are highly beneficial. Some users may prioritize rapid failover, while others may prefer a more conservative approach. Overall, automated failover has substantially reduced the operational burden associated with daily platform management.  


Additionally, **maintenance windows** no longer demand extensive coordination. Applications can be seamlessly evicted from one cluster and restarted in another. This system also includes built-in disaster recovery (DR) testing capabilities.  


For those interested in exploring this feature, the process is straightforward and designed for ease of adoption.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0e1bfbb9-f7a7-4415-a42a-f2818d88762d.webp)





Fortunately, Karmada already supports resource interpretation for most native Kubernetes resources like **deployments** and **stateful sets**. However, if you're using a **custom resource definition (CRD)**, you may need to define your own interpreter. This process is straightforward—simply implement the custom interpreter interface with methods relevant to your use case.  


For instance, you could define the `getReplicas` method to specify the number of replicas your CRD schedules, along with resource requirements. Alternatively, you could implement the `interpretHealth` method to help Karmada assess the health status of your CRD.  


Next, you'll need to configure **failover behavior**. This includes determining Karmada's sensitivity in detecting issues and triggering failover, as well as the speed at which applications should be purged from the cluster. You can choose immediate deletion or opt for a grace period. Additionally, consider whether any state needs to be preserved during failover.  


Finally, once the state is injected into your resource, you must ensure member clusters can consume it. In our implementation, we used a **webhook** to inject the initial save point path into the Flink deployment specification.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/ca2027bd-29b1-4286-8b2e-64629b00a00d.webp)






There are existing limitations and pending improvements regarding the features discussed today. **Application failover** remains a developing feature, and the Karmada community is actively gathering more use cases to identify gaps in the current implementation.  


**State preservation**, specifically introduced in Karmada v1.12.0, is a recent addition. We encourage users to test this feature to evaluate its suitability for their needs.  


For failover, two key considerations exist. First, the **failover toleration seconds** must be carefully configured. This parameter activates immediately after resource scheduling to a cluster. Setting it too low may cause Karmada to repeatedly reschedule applications that never reach a healthy state. Therefore, the toleration seconds must exceed the application's initialization time. The community is exploring modifications, such as only considering toleration seconds after the application's first healthy transition.  


Additionally, the **health interpreter** provides an estimate of application health status. In most cases, applications in a reconciling or created state are assumed inactive in data processing. Absent errors, cluster issues may be the underlying cause.  


**Cluster failover** itself is currently being enhanced, and state preservation support for this feature is forthcoming. Stay tuned for updates.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/38088bf2-67c2-42a4-9c15-06723f13d4e5.webp)



Lastly, for the **Karmada community**, we would like to highlight that we are a very active community. If you are interested in contributing, please reach out to us on **Slack** or **GitHub**.  


Additionally, we will be presenting further at **KubeCon**, with two more talks scheduled for tomorrow.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0e7e52ce-035d-4561-a527-111450506d75.webp)


I encourage you to attend these sessions. If you'd like to engage with the community in person, visit our desk at the **Projection Pavilion**, **Kiosk Number 4B**, during the morning shift.






