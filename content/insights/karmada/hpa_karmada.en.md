---
title: "Karmada Cross-Cluster Autoscaling Scenarios and Implementation Analysis"
date: 2025-08-22T13:19:33+08:00
draft: "false"
description: ""
---

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/2ef58bb4-d8f6-4710-87b4-7d2c4f20d808.webp)

I am Jiang Xingyan from DaoCloud. Today, I will share with Jiang Wei from Huawei Cloud about Karmada cross-cluster autoscaling scenarios and implementation. This presentation will demonstrate the features of elastic HPA from the following aspects.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/553c8135-3822-4fa9-8b3d-e3d8aab0083c.webp)

Multi-cluster resource pools are the future development trend. How can Karmada help businesses achieve multi-cloud? We will explore the technical limits and limitations of single-cluster HPA, and share solutions for implementing HPA in multi-cluster and multi-cloud scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/7760d816-de63-4a13-8632-b99bda0cbe70.webp)

So, let's explore why multi-cluster resource pools are the future development trend.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/f068eee1-110c-4891-bd44-f32b5f2e8c3c.webp)

According to international research data, more than **87%** of enterprise respondents have adopted multi-cloud and multi-cluster architectures in their businesses. Among them, approximately **72%** of enterprises use hybrid cloud models, involving different cloud service providers, clusters, and versions.  

With the continuous development of cloud-native technologies, **multi-cloud architecture** will undoubtedly become the mainstream trend in the future.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/90aac557-8069-4153-81d6-e79bd07189de.webp)

Why do we need to use multiple clusters?  

First, let's look at the limitations of a single cluster. In a single-cluster environment, a **Kubernetes cluster** has the following constraints:  
- The number of nodes cannot exceed 5,000  
- The number of Pods is limited to within 100,000  
- The maximum number of containers per node is 110  

For enterprises with multiple business lines and teams, they typically achieve business isolation and team isolation through **Namespaces** in a single cluster. With multi-cloud and multi-cluster architectures, we can leverage different clusters to achieve better business isolation, allowing different departments to use dedicated cluster resources.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/c4fafb97-69a6-4d88-aa4d-d3863aed3994.webp)

As the limitations of single-cluster technology become increasingly apparent, **multi-cluster and multi-cloud architectures** have become the future development trend. However, multi-cluster deployment also faces many challenges:  

First, an increase in the number of clusters leads to more **duplicate configurations**, and each cluster may have different configuration requirements. Second, when businesses are deployed across different clusters, there are differences between cross-cluster businesses. Additionally, the API management interfaces provided by various cloud vendors differ, leading to inconsistent cluster management methods.  

As the cluster scale expands, this **fragmented scenario** will become more significant. Therefore, we need to build a unified management perspective to shield technical differences between different vendors and clusters.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/4299da66-58e7-4601-9ef1-5d11f9379244.webp)

Next, Jiang Wei from **Huawei** will introduce **Karmada** to everyone.

Hello everyone, I am Jiang Wei, an open-source engineer from Huawei Cloud's open-source team. Based on the advantages of **multi-cloud**, we need a platform to achieve unified management. Karmada was born for this purpose, and it can help you smoothly migrate single-cluster businesses to multi-cluster environments.

For example, in scenarios where local IDC and public cloud are deployed in a hybrid manner, Karmada can effectively **reduce costs** and optimize resource utilization to meet various business needs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0c038547-c83c-4d62-b77b-4a266aa68184.webp)

**Karmada** is a platform for managing multiple K8s clusters. Users can connect multiple clusters to its control plane, thereby infinitely expanding the resource pool. For example, a single cluster may only support ten thousand nodes, but through Karmada, multiple clusters can be connected to scale to hundreds of thousands or even millions of nodes. Additionally, Karmada is compatible with **Kubernetes native APIs**, allowing users to use Karmada just like operating a single cluster, with the complexity of underlying multi-clusters completely shielded.  

Karmada has **open and neutral** characteristics, avoiding vendor lock-in and supporting multi-cloud platforms such as Huawei Cloud and Alibaba Cloud. It provides rich multi-cluster scheduling capabilities out of the box, supporting scheduling strategies based on **Region** (such as Beijing, Shanghai), multiple AZs, and multiple vendors. At the same time, Karmada supports **centralized management**, enabling unified management of multiple clusters in public clouds, private clouds, and edge clouds.  

Next, we will briefly introduce Karmada's overall architecture.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/3e4f0559-edcb-49bd-9bd4-a9c3a35df4fe.webp)

Karmada is mainly divided into two parts: the control plane and member clusters. Karmada provides K8s native APIs upward, allowing users to continue using single-cluster methods, such as operating through `kubectl apply`.  

Its core components include **Scheduler** and **Execution Controller**. After users submit APIs, they can define multi-cloud policies, such as scheduling based on availability zones (AZ) or regions (Region). The Scheduler will allocate different workloads to corresponding clusters based on policies, considering factors including:  

1. Cluster available resource capacity (**prioritizing those with sufficient resources**)  
2. Geographic location preferences (if Beijing has sufficient resources, schedule to Beijing)  
3. Cost optimization (achieving cross-cloud price comparison scheduling through plugins, such as choosing Alibaba Cloud or Azure and other more cost-effective cloud services)  

This mechanism maintains the native K8s user experience while achieving cross-cluster **intelligent scheduling capabilities**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/30dbf077-e7dc-4892-b636-2a19cc4e2c23.webp)

The core issue we currently face is that in single-cluster environments, **HPA (Horizontal Pod Autoscaler)** is typically used to ensure service stability by adjusting the number of Pods to cope with traffic changes. However, in multi-cluster scenarios, autoscaling requirements are more complex.

As shown in the left figure, we need to break through the boundary limitations of a single cluster and achieve cross-cluster autoscaling. For example, when traffic surges in Cluster 1, elastic scaling can be performed simultaneously in both Cluster 1 and Cluster 2.

The **core** of this solution lies in coordinating the use of resources from multiple clusters to achieve cross-cluster autoscaling. Specific scenarios include: after local IDC resources are exhausted, seamlessly expanding to public cloud resources. This **hybrid cloud architecture** can both ensure business continuity and significantly reduce operational costs.

In short, this solution aims to meet the autoscaling needs of cross-cluster businesses through unified management of multi-cluster resources.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/acf3381a-2616-4b73-8079-215e19bc310e.webp)

Next, we will briefly discuss the limitations of **HPA**. Thank you to Jiang Xingyan for the sharing.  

First, let's look at the limitations of single-cluster HPA and briefly introduce the background and application methods of HPA. This diagram comes from the Kubernetes official website.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/5551a01d-44ea-4e90-8dc2-f04fa39b8f19.webp)

Let me briefly introduce how **HPA** works. The HPA controller will scan target objects (such as Deployment and its derived Pods) according to the HPA configuration file definition in each time period. After selecting corresponding Pods through Deployment's spec.selector, HPA will query the metrics data of these Pods.

For standard resource metrics (such as CPU and memory usage), or custom business metrics (such as **QPS**), HPA can monitor them. When business traffic surges, HPA will automatically scale up the number of Pod replicas to handle the load; when traffic decreases, it will scale down replicas to save costs. This is the basic working mechanism of HPA in single-cluster environments.

Next, we will demonstrate its usage methods in detail.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/67875cc3-aae8-49e7-bfa4-58579b5e253b.webp)

The following is an example from the **Kubernetes** official website. In this example, the YAML configuration of **HPA** is very clear. First, a **Target** is defined, clearly specifying the **Deployment** object that needs to be scaled. For example, this is a **PHP Apache** Deployment. The scaling metric is based on **CPU utilization**, with a threshold set at 50%, which means the system will maintain the average CPU utilization of this Deployment at around 50%.

We set the maximum and minimum number of replicas. Assuming there are currently 5 replicas, when business traffic surges causing CPU utilization to reach 70%-80%, the system will automatically scale the number of replicas to 8-10 to maintain the Pod's CPU utilization at the target value. When business traffic decreases, the system will automatically scale down excess Pods to save costs.

The frequency of scaling up and down can be controlled through the **Behavior** field in the YAML. You can configure strategies such as rapid scaling up and slow scaling down, adjusting the pace of scaling according to actual needs. This is a typical single-cluster **HPA** application example.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/2fe35ec9-6e62-425e-833a-25c2588b5882.webp)

In single-cluster scenarios, resource limitations are very clearly defined. As mentioned earlier, a single cluster's resources are limited, including **node count** and **Pod count**, etc. When business traffic surges, unlimited scaling cannot be achieved within a single cluster. At this point, business Pods need to be migrated to other clusters.

Additionally, there are some specific scenarios: for example, when scaling up, Pods may be allocated to high-cost cloud vendors, while the actual expectation is to schedule them to low-cost cloud vendors. However, traditional **HPA mechanisms** cannot achieve cost-based scheduling.

Another problem is that as the number of clusters increases, the number of HPA configurations also grows. Ideally, a unified approach should be used to configure and manage HPA resource limitations for each cluster, which is difficult to achieve in single-cluster environments.

Next, we introduce the **Karmada solution**. As Jiang Wei mentioned, Karmada manages multiple member clusters through a unified perspective, achieving unified resource deployment. Karmada introduces the **FederatedHPA mechanism**, which is a centralized HPA with the following characteristics:

1. Maintaining the same ease of use as single-cluster Kubernetes  
2. Being able to intelligently schedule scaled Pods to various sub-clusters according to distribution policies  
3. Supporting on-demand scheduling of Pods to low-cost cloud vendors to meet specific business needs



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/a06c13a7-8b66-4986-97bb-1ee3832ea68e.webp)

Next, let's look at the overall definition of **FederatedHPA**. It can be seen that its overall definition is basically consistent with the HPA definition in Kubernetes.  

It contains the following key parts:  
- **Target** pointing, used to specify the resource object that needs to be scaled;  
- **metrics** definition, used to determine the scaling basis;  
- **behavior** configuration, used to control the scaling rhythm, such as rapid scaling up or progressive scaling.  

The entire API definition maintains high consistency.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/25eee541-4957-464b-9866-7f37745ef4cb.webp)

It's basically consistent with a single cluster. This means that if you're already using **HPA**, you can easily migrate from single-cluster HPA to multi-cluster **FederatedHPA**. FederatedHPA is multi-cluster HPA, and its configuration is the same except for the API version (`apiVersion:autoscaling.karmada.io/v1alpha1`), which differs from Karmada. Users only need minimal modifications to complete the migration. **Core metrics** (such as target Deployment and scaling basis) do not need to be changed, as we have maximally compatible with existing HPA configurations. Users can write simple scripts to batch migrate HPA.  

The usage method remains consistent with single-cluster HPA: in a single cluster, you need to create a **Deployment** (business workload) and associated HPA; in Karmada, you need to create FederatedHPA and point it to the Deployment. Since Karmada needs to distribute the Deployment to sub-clusters, this process involves **scheduling policy** configuration (such as allocation by weight or resource utilization adjustment). For example, if member cluster Member 3 has sufficient resources and low business load, it can be prioritized for scheduling.  

The **scaling process** is implemented by Karmada's underlying FederatedHPA Controller. This component periodically queries the Metrics Adapter to aggregate Metrics Server metrics from each member cluster, then triggers Deployment scaling in the control plane. The number of scaled replicas is controlled by the scheduler (as mentioned by Jiang Wei), allocated to sub-clusters according to distribution policies. If a member cluster's resource utilization is too high, the scheduler will sense it and prioritize allocating scaled instances to other clusters (such as M1/M3), thereby avoiding single-cluster overload and ensuring business stability.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/4a73022b-7a6f-47c6-9ec4-ba418ffef83e.webp)

This is the entire workflow. It can be seen that its working method is exactly the same as single-cluster **HPA**, and the usage is also completely consistent. The only difference is that in **Karmada**, any resource distribution needs to specify how the **Deployment** is distributed to target clusters through distribution policies.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/bdde3c8f-a571-447c-bbdd-364546ea32ea.webp)

Next, let me briefly introduce **Karmada's** overall architecture. As mentioned earlier, Karmada introduces the **Karmada Metrics Adapter** adapter component. This adapter will periodically respond to metric query requests initiated by the controller, and these requests are first sent to the **Karmada API Server**. The Karmada API Server is essentially a native API Server, and its functionality is completely consistent with the API Server in single-cluster environments. In actual operation, the Karmada API Server will forward metric query requests to the Karmada Metrics Adapter for processing.

After the request arrives, the Karmada Metrics Adapter will actually collect various metrics related to Deployment defined in the **HPA**. This is similar to the HPA usage in single-cluster environments—in single-cluster scenarios, users need to install Metrics Server or custom Metrics Server components, such as components for counting HTTP requests and other business metrics. These components are usually pre-installed in member clusters. Karmada's core capability lies in being able to uniformly collect these metrics data scattered across member clusters and aggregate them to the control plane.

The overall workflow maintains high consistency with single-cluster HPA, including the **FederatedHPA Controller's** working mechanism, which is basically the same as single-cluster HPA Controller. Of course, there are some differences, mainly reflected in Karmada's unique distribution policies and scheduling policies. These policies may be implemented through scheduling plugins, making the Controller's specific behavior slightly different from single-cluster environments. But from a user experience perspective, the overall operation method is basically consistent with single-cluster environments.

Regarding the applicable scenarios of centralized HPA: since FederatedHPA maintains compatibility with single-cluster HPA, user migration costs are low, requiring only modifications to fixed configuration items such as API Server and endpoint. In scaling scenarios, when the control plane scales up the number of Deployment replicas, the newly added instances will be uniformly scheduled by the **Karmada scheduler**. This scheduler can sense the resource status of each member cluster's underlying layer and intelligently allocate new replicas to clusters with relatively sufficient resources based on resource availability.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/5a91ed18-c3f3-481a-a227-aa3aa1623414.webp)

It also has certain limitations. Since the entire workflow is located in the Karmada control plane, it will put significant pressure on the control plane.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0f46b95c-e436-4b54-a8eb-3e3b81b144f7.webp)

As can be seen from this image, all **Metrics data** are collected from underlying Metrics. Therefore, Karmada needs to maintain high communication quality with member clusters, as Metrics data changes frequently. This requires the network bandwidth between the control plane and member clusters to be large enough.  

Next, let's discuss usage scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/a1782e3b-c221-479a-9fc1-ffe3208ab220.webp)

There is another type of HPA in Karmada called distributed HPA. Below, Jiang Wei will introduce distributed HPA to everyone.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/fa0c68d6-0059-4f43-ae22-347f84e445fa.webp)

Thank you to Jiang Xingyan for the explanation. We just discussed the core advantages of centralized HPA, including high scheduling accuracy, good native experience, and extremely low migration costs, requiring only API and version adjustments.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/470c743c-bc72-4dcb-8e93-57d0a0714ab2.webp)

If the business scale is larger and bandwidth requirements are lower, it is necessary to adopt a **distributed HPA solution**. In Karmada, this solution is called HPA Coordinator, and its core advantage lies in its **distributed architecture**—all computation-related operations are not performed in the control plane, thereby supporting larger business scales, lower bandwidth requirements, and lighter control plane loads.

The overall architecture is as follows:  
Karmada's control plane contains a component called **HPA Coordinator Controller**, which provides the HPA Coordinator API upward. This API is responsible for defining the interface specifications for HPA in each cluster and distributing the HPA Controller to each member cluster. The HPA Controller in member clusters independently performs autoscaling calculations, while HPA Coordinator is mainly responsible for unified configuration management and coordination work.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/39f01577-4de1-4b7c-87cf-7be7764f331a.webp)

To achieve priority scaling, the system will disable low-priority clusters. When high-priority cluster resources are exhausted, these clusters will be re-enabled.  

This design avoids frequent interaction of **Metrics** between the control plane and member clusters. All Metrics collection, calculation, and caching are completed in member clusters, significantly reducing system load and consuming almost no additional resources.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0635b5c1-1319-4668-a567-4984831ca4fb.webp)

Next, let's analyze their core differences.  

**First, in terms of control plane load**, the centralized solution has higher load because all metric collection, calculation, and caching are completed in the control plane. The **HPA Coordinator solution** has lower load because metric collection and calculation are independently completed by member clusters, and the control plane is only responsible for coordination work.  

**Second, in terms of bandwidth requirements**, FederatedHPA requires data exchange between the control plane and member clusters. Actual measurements show that interactions with millions of metrics may generate hundreds of megabytes of traffic, and this interaction frequency is high. For enterprises that charge by traffic, this will significantly increase costs. The **Coordinator solution** has almost negligible bandwidth requirements because there is no data interaction.  

**Regarding cross-cluster scaling accuracy**, FederatedHPA can sense member cluster status in real-time and schedule scaled instances to low-load clusters, so accuracy is high. In contrast, Coordinator delegates authority downward, cannot sense each cluster's resource status, and only performs HPA start/stop operations, so accuracy is relatively lower. This is similar to delegating authority to groups for autonomous decision-making—although it reduces the central burden, overall coordination will be somewhat reduced.  

**Distributed HPA scaling scenarios** can be illustrated through two diagrams. In scaling-up scenarios, when a cluster reaches preset thresholds (such as 24 instances or 80% load), the system will start the second cluster's HPA for scaling preparation. Similarly for scaling-down scenarios, when preset thresholds are reached (such as 6 instances or 30% load), the system will prioritize scaling down operations on high-priority clusters. The overall process follows this mechanism.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/3a9f28a9-9210-485e-98e9-9be41c02653b.webp)

Next, let's look at the general process of **distributed HPA**, which is mainly divided into three steps: initial distribution, scaling down, and scaling up. After understanding these three scenarios, the overall process is relatively easy to grasp.  

Let's explain through examples. Assume that Member1 cluster's resource usage is higher than Member2 cluster, which is a common scenario in practice. For example, when using both public cloud and private cloud simultaneously, private cloud resources are usually prioritized to save costs.  

In the example, Member1 cluster's `maxReplicas` is set to 130, and Member2 cluster's `maxReplicas` is set to 120. The reason for this design is that the **HPA API** is mainly for administrators, not regular users. Administrators need fine-grained control over each cluster's resource status to avoid cluster resource exhaustion or service interruption due to autoscaling.  

Next, we set the cross-cluster scaling trigger threshold to 30, and Member2 cluster's scaling-down threshold to 1. For ease of demonstration and understanding, simplified numerical settings are used here, without complex configurations.  

After configuration is complete, the distributed HPA rules are as follows:  
- Member1 cluster: `minReplicas` is 1, `maxReplicas` is 130.  
- Member2 cluster: Both `minReplicas` and `maxReplicas` are set to 1111.  

The purpose of this design is to disable Member2 cluster's HPA functionality—by setting `minReplicas` and `maxReplicas` to the same value, it cannot trigger autoscaling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/a7c54524-fc4a-496b-9b23-cbb56011cd5e.webp)

After initial configuration distribution, as traffic grows, assuming **Member1 cluster's** current replica count rises to 30, this will trigger **Cluster 2's** scaling operation. The specific scaling mechanism is by adjusting the **max replica** parameter to 20, allowing Member2 cluster to gradually take on traffic and increase instances, thereby achieving cross-cluster autoscaling.  

After completing cross-cluster scaling, stability needs to be ensured. For example, when Cluster 2's instance count drops to 10, Cluster 1's instance scale should be prioritized to remain stable. This control is achieved by locking **min replica** in Member1 cluster's **HPA (Horizontal Pod Autoscaler)** at 30 to prevent premature scaling down.  

Regarding the scaling-down process: assuming both clusters have completed scaling (e.g., Member1 reaches 30 replicas), when Member2 cluster successfully scales down to 1 replica, Member1 cluster's scaling down will be initiated. The operation principle is similar to scaling up—set Member1's min replica to 1 to initiate scaling down, while setting Member2's max replica to 1 to avoid intermediate state scaling up. This mechanism ensures Member1 completes maximum scaling down first, then processes Member2 cluster, ultimately achieving a cost optimization solution where **public cloud resources** are released first, and **private cloud clusters** are processed subsequently.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/447918fe-1789-424c-b922-6ceac23cf86f.webp)

There is another issue related to the **threshold** mentioned earlier, which is the role of 24 or 80%. Let's illustrate with an example:  

Assume there are two clusters, one is a local IDC and the other is a public cloud. When scaling up, we hope to prioritize scaling on the public cloud. When cluster load reaches 24, according to Metrics calculations, replica count will continue to grow. When it grows to 30, the scaling threshold is triggered, and scaling will be initiated on the public cloud at this time.  

However, to save costs, public clouds usually configure **cluster autoscaler** to dynamically create on-demand nodes, which typically takes 3 to 5 minutes. During this period, businesses across multiple clusters may experience service interruption due to overload.  

Therefore, a more reasonable approach is to trigger public cloud scaling when capacity reaches 80%, preparing nodes in advance to avoid business interruption due to delayed scaling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/76560c3c-186b-492b-a482-a902de6d96af.webp)

Now let's observe the changes after setting. Assume we set multi-cloud scaling to trigger when capacity reaches **80%**, i.e., triggering **Cloud scaling**. After scaling is complete, node scaling will be triggered, which is a continuous process.  

It can be seen that both sides are continuously scaling. After node scaling succeeds, when the local IDC reaches the maximum value, node scaling has been completed. At this point, even if business traffic surges, the system can still handle it. However, if traffic grows too fast, it may take some time to fully process.  

Typically, business scale may reach one thousand or two thousand **Pods**, and in such cases, the system can usually handle it because traffic doesn't surge instantly. In summary, you can compare the situation before and after setting.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/afcb9da6-dc5f-44f1-b0db-e805cb424f67.webp)

If preset values are set reasonably, they can usually solve the problem of long-term overload in public cloud and private cloud scenarios. Finally, the applicable scope of both is summarized as follows:  

**First**, if resources are constrained, including resource limitations and scaling policies (especially cross-cluster scaling policies), such as limited bandwidth or high costs, and the scale is large, **decentralized HPA** may need to be chosen. Conversely, if bandwidth is sufficient, either centralized or distributed solutions can be chosen. The advantage of centralized solutions is extremely low learning costs, allowing direct copying of configurations; distributed solutions are slightly more complex but offer significant benefits.  

**Second**, regarding limitations of replica scaling: if priority-based scaling is needed, currently only decentralized solutions are supported; if **elastic policies** need to be used (such as cross-cluster scaling based on availability zones AZ or available resource counts), then currently only centralized HPA is supported. Specific choices depend on actual environment requirements.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/2beaf151-ff6d-4b38-a325-535ce4fe4ba3.webp)

If you're interested, you can follow **Karmada's** official website, GitHub, and the community assistant on Slack. Thank you to both speakers for the wonderful sharing. If you have any questions, please feel free to raise your hand.

I would like to ask: in the decentralized scenario mentioned earlier, local clusters and cloud clusters can set priorities, prioritizing local resources, and then scheduling to the cloud after local resources are exhausted.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cabe822e-3fdf-41c2-96a1-31e0539b78b9.webp)

However, when scaling down, you need to manually adjust the local cluster's minimum replica count first to ensure local clusters are not prioritized for scaling down. **Actually, this process has been fully automated by Karmada.** When local cluster priority is configured, the system will automatically complete related settings.  

Regarding scaling policies, currently only one priority can be specified: scaling up follows creation order, and scaling down is the opposite. Additionally, what needs to be created is an **overall HPA policy**, not a single cluster policy. For example, set the overall minimum replica count to 1 and maximum to 30 in the control plane, and specify the allocation ratio between two clusters (such as 7:3). The system will automatically calculate minimum and maximum replica counts in the two business clusters as percentages based on the set ratio and priority.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/dd60aad2-d87f-4f31-aa61-87d5f0a923bb.webp)

Not exactly. Our design philosophy is that if platform administrators only allocate resources by proportion, it may lead to unpredictable allocation results. Therefore, we recommend administrators control resource status through **fine-grained settings** of each cluster's `minReplicas` and `maxReplicas` to avoid resource over-allocation or insufficiency. The specific implementation method is to configure upper and lower limits of replica counts for each cluster in list form in the control plane.

Regarding configuration effectiveness mechanisms, current `HPACoordinator` configuration modifications are **atomic operations**. If configuration is adjusted during scaling, the system will apply new configuration after the current scaling operation is completed.

In terms of disaster recovery, taking Beijing and Shanghai dual clusters as an example: when a Beijing cluster fails, the system will detect it through **health check mechanisms** (supporting health status data retrieval through public cloud interfaces), and then automatically redeploy businesses to backup clusters. Users can pre-set backup cluster policies.

For manual scaling scenarios, the community is developing the `CHPA` (CronHPA) feature, supporting preset time points for scaling, such as handling periodic business peaks like "Double Eleven" or "618."

Regarding differences from `Karmada`: although both are based on `Kubernetes` for multi-cluster management, `HPACoordinator` focuses on **cross-cluster autoscaling** scenarios, achieving fine-grained multi-cluster resource control through unified configuration management, while `Karmada` focuses more on multi-cluster deployment and failover scenarios.



Regarding **Serverless architecture** for headless services, you mentioned the difference from Alibaba Cloud's Collective service. Actually, our HPA mechanism has similarities with Serverless architecture in underlying principles. For example, when traffic increases, the system will automatically launch **PODs**; when traffic decreases, it will automatically scale down POD counts. In terms of cluster management, Member clusters are centrally managed by Controller clusters.

Similar to **Knative service**, our architecture is also built on K8s, encapsulating Serverless businesses as K8s PODs. Knative can run in multi-cluster environments, achieving cross-cluster deployment with the help of Commander. For example, QingCloud's KS service uses a similar federation mode internal plugin **CCM**.

In terms of multi-cluster management, middleware is indeed needed to achieve connectivity between clusters. When Master main clusters manage other Member clusters, **Controller components** are needed as support. We have conducted performance stress tests on this Controller component, and related data can be found on Karmada's official website. This component is indeed one of the most important components in the entire architecture.



This component can be considered one of **the most important components**. If you have questions about performance stability, you can check the detailed stress test data on the official website, which supports scales of up to 100,000 clusters.  

QingCloud products previously integrated **KubeFeed**, and the current version has switched to **Karmada**, but performance issues occurred last month. We have used tools such as **Kube-bench** for stress testing, simulating large-scale cluster access to Karmada scenarios to verify the Controller's overall performance.  

Regarding **Karmada HPA** application scenarios, typical cases include multi-active disaster recovery deployment: when businesses need cross-region deployment (such as different clusters in Beijing and Shanghai), they can prioritize scheduling to local IDC to reduce costs, with public cloud resources as supplements. This hybrid cloud cost optimization and cross-cluster autoscaling are two core application scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/68ea4c1d-0c60-41ac-b56e-a5b15f4817aa.webp)

Due to time constraints, we suggest further offline communication. Thank you to both speakers for the sharing.
