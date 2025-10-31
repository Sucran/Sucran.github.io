---
title: "Karmada跨集群弹性伸缩场景与实现剖析"
date: 2025-08-22T13:19:33+08:00
draft: "false"
description: ""
---

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/2ef58bb4-d8f6-4710-87b4-7d2c4f20d808.webp)

我是来自DaoCloud道客的蒋兴彦。本次将与华为云的姜伟共同为大家分享Karmada跨集群弹性伸缩的场景与实现。本次分享将从以下几个方面展示弹性HPA的特点。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/553c8135-3822-4fa9-8b3d-e3d8aab0083c.webp)

多集群资源池是未来的发展趋势。Karmada如何助力业务实现多云化？我们将探讨单集群HPA的技术极限及其局限性，并分享在多集群多云场景下实现HPA的解决方案。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/7760d816-de63-4a13-8632-b99bda0cbe70.webp)

那么，我们来探讨一下为何多集群资源池是未来的发展趋势。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/f068eee1-110c-4891-bd44-f32b5f2e8c3c.webp)

根据国外调研数据显示，超过**87%**的企业受访者已在其业务中采用多云多集群架构。其中，约**72%**的企业采用混合云模式，涉及不同云服务商、集群及版本。  

随着云原生技术的持续发展，**多云架构**无疑将成为未来主流趋势。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/90aac557-8069-4153-81d6-e79bd07189de.webp)

为什么需要使用多集群？  

首先，我们来看单集群存在哪些限制。在单集群环境中，一个**Kubernetes集群**存在以下约束：  
- 节点数量不能超过5000个  
- Pod数量限制在10万个以内  
- 每个节点的容器数量上限为110个  

对于拥有多个业务线和团队的企业而言，在单集群中通常通过**Namespace**实现业务隔离和团队隔离。而采用多云和多集群架构后，我们可以利用不同集群来实现更完善的业务隔离，让不同部门使用专属的集群资源。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/c4fafb97-69a6-4d88-aa4d-d3863aed3994.webp)

随着单集群技术的局限性日益显现，**多集群、多云架构**已成为未来发展趋势。然而，多集群部署也面临诸多挑战：  

首先，集群数量增加会导致**重复配置**增多，同时各集群可能存在差异化配置需求。其次，业务分散部署在不同集群时，跨集群业务间存在差异性。此外，各云厂商提供的API管理接口存在差异，导致集群管理方式不统一。  

随着集群规模扩大，这种**碎片化场景**将愈发显著。因此，我们需要构建统一的管理视角，以屏蔽不同厂商和集群间的技术差异。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/4299da66-58e7-4601-9ef1-5d11f9379244.webp)

接下来，由来自**华为**的姜伟为大家介绍**Karmada**。

大家好，我是华为云开源团队的开源工程师姜伟。基于**多云**的优势，我们需要一个平台来实现统一管理。Karmada正是为此而生，它能够帮助您将单集群业务平滑迁移至多集群环境。

例如，在本地IDC与公有云混合部署的场景下，Karmada可以有效**降低成本**并优化资源利用率，满足各类业务需求。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0c038547-c83c-4d62-b77b-4a266aa68184.webp)

**Karmada**是一个用于管理多个K8s集群的平台，用户可以将多个集群接入其控制平面，从而无限扩展资源池。例如，单个集群可能仅支持一万个节点，但通过Karmada可以连接多个集群，扩展到十万甚至百万节点。此外，Karmada兼容**Kubernetes原生API**，用户可像操作单集群一样使用Karmada，底层多集群的复杂性被完全屏蔽。  

Karmada具有**开放中立**的特性，避免厂商锁定，支持多云平台如华为云、阿里云等。它提供开箱即用的丰富多集群调度功能，支持基于**Region**（如北京、上海）、多AZ、多供应商等多种调度策略。同时，Karmada支持**集中式管理**，能够统一管理公有云、私有云及边缘云的多个集群。  

接下来，我们将简要介绍Karmada的总体架构。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/3e4f0559-edcb-49bd-9bd4-a9c3a35df4fe.webp)

Karmada主要分为两部分：控制面和成员集群。Karmada向上提供K8s原生API，用户可沿用单集群的使用方式，如通过`kubectl apply`进行操作。  

其核心组件包括**Scheduler**和**Execution Controller**。用户提交API后，可定义多云策略，例如基于可用区（AZ）或区域（Region）进行调度。Scheduler会根据策略将不同Workload分配到相应集群，考虑因素包括：  

1. 集群可用资源量（**资源充足者优先**）  
2. 地理位置偏好（如北京资源充足则调度至北京）  
3. 成本优化（通过插件实现跨云比价调度，例如选择阿里云或Azure等更具成本效益的云服务）  

这种机制既保持了原生K8s的使用体验，又实现了跨集群的**智能调度能力**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/30dbf077-e7dc-4892-b636-2a19cc4e2c23.webp)

当前面临的核心问题是，在单集群环境中，通常使用**HPA（Horizontal Pod Autoscaler）**来保障服务的稳定性，即通过调整Pod数量来应对流量变化。然而，在多集群场景下，弹性伸缩的需求更为复杂。

如左图所示，我们需要突破单一集群的边界限制，实现跨集群的弹性伸缩。例如，当Cluster 1的流量激增时，可以同时在Cluster 1和Cluster 2中进行弹性扩展。

这一方案的**核心**在于统筹利用多个集群的资源，实现跨集群弹性伸缩。具体场景包括：当本地IDC资源耗尽后，可无缝扩展至公共云资源。这种**混合云架构**既能确保业务连续性，又能显著降低运营成本。

简而言之，该方案旨在通过统一管理多集群资源，满足跨集群业务的弹性伸缩需求。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/acf3381a-2616-4b73-8079-215e19bc310e.webp)

接下来，我们将简要探讨**HPA**的局限性。感谢蒋兴彦同学的分享。  

首先，我们来看单集群HPA的局限性，并简要介绍HPA的背景及其应用方式。这张图来自Kubernetes官网。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/5551a01d-44ea-4e90-8dc2-f04fa39b8f19.webp)

首先简要介绍**HPA**的工作原理。HPA控制器会在每个时间周期内，根据HPA配置文件的定义，扫描目标对象（如Deployment及其派生的Pod）。通过Deployment的spec.selector选择对应的Pod后，HPA会查询这些Pod的指标数据。

对于标准资源指标（如CPU、内存使用率），或自定义的业务指标（如**QPS**），HPA都能进行监控。当业务流量激增时，HPA会自动扩展Pod副本数以应对负载；流量回落时则缩减副本以节约成本。这就是单集群环境下HPA的基本工作机制。

接下来我们将具体演示其使用方法。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/67875cc3-aae8-49e7-bfa4-58579b5e253b.webp)

以下是一个来自 **Kubernetes** 官网的示例。在此示例中，**HPA** 的 YAML 配置非常清晰。首先定义了一个 **Target**，明确指定了需要扩展的 **Deployment** 对象。例如，这里是一个 **PHP Apache** 的 Deployment。扩容指标基于 **CPU 利用率**，设定阈值为 50%，这意味着系统会维持该 Deployment 的平均 CPU 利用率在 50% 左右。

我们设置了最大和最小副本数。假设当前有 5 个副本，当业务流量突增导致 CPU 利用率达到 70%-80% 时，系统会自动将副本数扩展到 8-10 个，以维持 Pod 的 CPU 利用率在目标值。当业务流量下降后，系统会自动缩减多余的 Pod 以节约成本。

扩容和缩容的频率可以通过 YAML 中的 **Behavior** 字段进行控制。您可以配置快速扩容、缓慢缩容等策略，根据实际需求调整扩缩容的节奏。这是一个典型的单集群 **HPA** 应用示例。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/2fe35ec9-6e62-425e-833a-25c2588b5882.webp)

在单集群场景中，资源限制的定义非常明确。正如前文所述，单个集群的资源是有限的，包括**节点数量**和**Pod数量**等。当业务流量激增时，无法在单一集群内无限扩容。此时，需要将业务Pod迁移至其他集群。

此外，还存在一些特定场景：例如扩容时，Pod可能被分配到高成本云厂商，而实际期望是将其调度至低成本云厂商。然而，传统**HPA机制**无法实现基于成本的调度。

另一个问题是，随着集群数量增加，HPA配置数量也随之增长。理想情况下，应采用统一方式配置和管理各集群的HPA资源限制，这在单集群环境中难以实现。

接下来介绍**Karmada解决方案**。正如姜伟所述，Karmada通过统一视角管理多个成员集群，实现资源的统一部署。Karmada引入了**FederatedHPA机制**，这种集中式HPA具有以下特点：

1. 保持与单集群Kubernetes相同的易用性  
2. 能够根据分发策略，将扩容Pod智能调度到各子集群  
3. 支持按需将Pod调度至低成本云厂商，满足特定业务需求



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/a06c13a7-8b66-4986-97bb-1ee3832ea68e.webp)

接下来我们整体看一下**FederatedHPA**的定义。可以看到其整体定义与Kubernetes中的HPA定义基本一致。  

它包含以下关键部分：  
- **Target**指向，用于指定需要扩容的资源对象；  
- **metrics**指标定义，用于确定扩容依据；  
- **behavior**配置，用于控制扩缩容节奏，例如快速扩容或渐进式扩容。  

整个API定义保持了高度的一致性。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/25eee541-4957-464b-9866-7f37745ef4cb.webp)

基本上与单集群一致。这意味着，若已使用**HPA**，则可轻松从单集群HPA迁移至多集群**FederatedHPA**。FederatedHPA即多集群HPA，其配置除API版本（`apiVersion:autoscaling.karmada.io/v1alpha1`）与Karmada差异外，其余均相同。用户仅需极低成本修改即可完成迁移。**核心指标**（如目标Deployment及扩缩容依据）无需变更，因我们已最大限度兼容现有HPA配置。用户可通过编写简易脚本批量迁移HPA。  

使用方式与单集群HPA保持一致：在单集群中需创建**Deployment**（业务负载）及关联的HPA；在Karmada中则需创建FederatedHPA并指向Deployment。由于Karmada需将Deployment分发至子集群，此过程涉及**调度策略**配置（如按权重分配或资源利用率调整）。例如，若成员集群Member 3资源充裕且业务负载较低，可优先调度至该集群。  

**扩缩容流程**由Karmada底层的FederatedHPA Controller实现。该组件周期性查询Metrics Adapter以聚合各成员集群的Metrics Server指标，随后在控制面触发Deployment扩缩容。扩容副本数受调度器控制（如姜伟所述），按分发策略分配至子集群。若某成员集群资源利用率过高，调度器将感知并优先将扩容实例分配至其他集群（如M1/M3），从而避免单集群过载，保障业务稳定性。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/4a73022b-7a6f-47c6-9ec4-ba418ffef83e.webp)

这是整个工作流程。可以看到，其工作方式与单集群**HPA**完全相同，使用方式也完全一致。唯一的区别在于，**Karmada**中任何资源的下发都需要通过分发策略来指定**Deployment**如何分发到目标集群。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/bdde3c8f-a571-447c-bbdd-364546ea32ea.webp)

接下来简要介绍**Karmada**的整体架构。如前所述，Karmada引入了**Karmada Metrics Adapter**这一适配器组件。该适配器会周期性地响应控制器发起的指标查询请求，这些请求首先会发送至**Karmada API Server**。Karmada API Server本质上是一个原生API Server，其功能与单集群环境中的API Server完全一致。在实际运行中，Karmada API Server会将指标查询请求转发至Karmada Metrics Adapter进行处理。

当请求到达后，Karmada Metrics Adapter会实际收集**HPA**定义中与Deployment相关的各项指标。这与单集群环境中的HPA使用方式类似——在单集群场景下，用户需要安装Metrics Server或自定义的Metrics Server组件，例如用于统计HTTP请求等业务指标的组件。这些组件通常已预装在成员集群中。Karmada的核心能力在于能够将这些分散在各成员集群的指标数据统一收集，并聚合到控制平面。

整体工作流程与单集群HPA保持高度一致，包括**FederatedHPA Controller**的工作机制也与单集群HPA Controller基本相同。当然也存在一些差异，主要体现在Karmada特有的分发策略和调度策略上，这些策略可能通过调度插件实现，使得Controller的具体行为与单集群环境略有不同。但从用户体验角度来看，整体操作方式与单集群环境基本一致。

关于集中式HPA的适用场景：由于FederatedHPA与单集群HPA保持兼容，用户迁移成本较低，仅需修改API Server和endpoint等固定配置项。在扩缩容场景下，当控制面对Deployment副本数进行扩容时，新增的实例数量将由**Karmada调度器**统一调度。该调度器能够感知各成员集群底层的资源状况，根据资源余量情况，将新增副本智能地分配到资源相对充裕的集群中。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/5a91ed18-c3f3-481a-a227-aa3aa1623414.webp)

它也存在一定的局限性。由于整个工作流都位于Karmada控制面，因此会对控制面造成较大压力。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0f46b95c-e436-4b54-a8eb-3e3b81b144f7.webp)

从这张图片可以看出，整个**Metrics数据**都是从底层的Metrics收集而来。因此，Karmada需要与成员集群保持较高的通信质量，因为Metrics数据变化较为频繁。这就要求控制面与成员集群之间的网络带宽需要足够大。  

接下来讨论使用场景。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/a1782e3b-c221-479a-9fc1-ffe3208ab220.webp)

在Karmada中还存在另一种HPA，称为分布式HPA。下面请姜伟同学为大家介绍分布式HPA。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/fa0c68d6-0059-4f43-ae22-347f84e445fa.webp)

感谢欣燕同学的讲解。我们刚刚探讨了中心式HPA的核心优势，包括调度精度高、原生体验良好，以及迁移成本极低，仅需调整API和版本即可。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/470c743c-bc72-4dcb-8e93-57d0a0714ab2.webp)

如果业务规模更大且带宽要求更低，则需采用**分布式HPA方案**。在Karmada中，该方案称为HPA Coordinator，其核心优势在于**分布式架构**——所有计算相关操作均不在控制平面进行，从而支持更大业务规模、更低带宽需求以及更轻量级的控制面负载。

整体架构如下：  
Karmada控制平面包含名为**HPA Coordinator Controller**的组件，向上提供HPA Coordinator API。该API负责定义各集群HPA的接口规范，并将HPA Controller下发至各成员集群。成员集群的HPA Controller独立执行弹性伸缩计算，而HPA Coordinator主要负责统一配置管理与协调工作。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/39f01577-4de1-4b7c-87cf-7be7764f331a.webp)

为实现优先级扩容，系统会禁用低优先级集群。当高优先级集群资源耗尽时，再重新启用这些集群。  

这种设计避免了**Matrix**在控制面和成员集群间的频繁交互。所有Matrix的采集、计算和缓存都在成员集群完成，从而显著降低了系统负载，几乎不消耗额外资源。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0635b5c1-1319-4668-a567-4984831ca4fb.webp)

接下来，我们分析其核心差异。  

**首先，控制面负载方面**，中心化方案负载较高，因为所有指标的采集、计算和缓存都在控制面完成。而**HPACoordinator方案**负载较低，因为指标采集和计算由成员集群自主完成，控制面仅负责协调工作。  

**其次，在带宽要求方面**，FederatedHPA需要在控制面与成员集群之间进行数据交换。实测显示，百万级指标的交互可能产生数百兆流量，且这种交互频率较高。对于按流量计费的企业，这将显著增加成本。而**Coordinator方案**由于没有数据交互，带宽需求几乎可以忽略不计。  

**关于跨集群弹性精度**，FederatedHPA能够实时感知成员集群状态，将扩容实例调度到低负载集群，因此精度较高。相比之下，Coordinator将权限下放，无法感知各集群资源状态，仅执行HPA启停操作，精度相对较低。这类似于将权限下放给各组自主决策，虽然减轻了中央负担，但整体协调性会有所降低。  

**分布式HPA的伸缩场景**可通过两个图示说明。扩容场景中，当集群达到预设阈值（如24个实例或80%负载）时，系统会启动第二个集群的HPA进行扩容准备。缩容场景同理，当达到预设阈值（如6个实例或30%负载）时，系统会优先对高优先级集群执行缩容操作。整体流程遵循这一机制。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/3a9f28a9-9210-485e-98e9-9be41c02653b.webp)

接下来，我们整体看一下**分布式HPA**的大致流程，主要分为三个步骤：初始下发、缩容和扩容。理解这三个场景后，整体流程就比较容易掌握。  

我们以示例的形式进行讲解。假设Member1集群的资源使用量高于Member2集群，这种场景在实际中很常见。例如，当同时使用公有云和私有云时，通常会优先使用私有云资源以节省成本。  

在示例中，Member1集群的`maxReplicas`设置为130，Member2集群的`maxReplicas`设置为120。这样设计的原因是，**HPA API**主要面向管理员，而非普通用户。管理员需要精细控制每个集群的资源状态，避免因弹性伸缩导致集群资源耗尽或服务中断。  

接下来，我们设定跨集群扩容的触发阈值为30，而Member2集群的缩容阈值为1。为了便于演示和理解，这里简化了数值设定，未采用复杂的配置。  

配置完成后，下发的HPA规则如下：  
- Member1集群：`minReplicas`为1，`maxReplicas`为130。  
- Member2集群：`minReplicas`和`maxReplicas`均设置为1111。  

这种设计的目的在于禁用Member2集群的HPA功能——通过将`minReplicas`和`maxReplicas`设为相同值，使其无法触发弹性伸缩。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/a7c54524-fc4a-496b-9b23-cbb56011cd5e.webp)

初始配置下发后，随着流量增长，假设**Member1集群**的当前副本数（current replica）上升至30，此时将触发**集群2**的扩容操作。具体扩容机制是通过将**max replica**参数调整为20，使Member2集群逐步承接流量并增加实例，从而实现跨集群弹性伸缩。  

完成跨集群扩容后，需确保稳定性。例如当集群2实例数降至10时，应优先保持集群1的实例规模。这一控制通过将Member1集群的**HPA（Horizontal Pod Autoscaler）**中**min replica**锁定为30来实现，防止其过早缩容。  

关于缩容流程：假设两个集群已完成扩容（如Member1达30个副本），当Member2集群成功缩容至1个副本时，即启动Member1集群的缩容。操作原理与扩容类似——将Member1的min replica设为1以启动缩容，同时将Member2的max replica设为1以避免中间态扩容。这种机制确保Member1优先完成极限缩容后，再处理Member2集群，最终实现**公有云资源**优先释放、**私有云集群**后续处理的成本优化方案。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/447918fe-1789-424c-b922-6ceac23cf86f.webp)

还有一个问题涉及前面提到的**阈值**，即24或80%的作用。我们可以举例说明：  

假设有两个集群，一个是本地IDC，另一个是公有云。扩容时，我们希望优先在公有云上进行。当集群负载达到24时，根据Matrix计算，replica数量会持续增长。当增长到30时，触发扩容阈值，此时会在公有云上启动扩容。  

然而，为了节省成本，公有云通常配置了**cluster autoscaler**来动态创建按需节点，这一过程通常需要3到5分钟。在这段时间内，多个集群的业务可能因过载而中断服务。  

因此，更合理的做法是在容量达到80%时就触发公有云扩容，提前准备好节点，避免因延迟扩容导致的业务中断。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/76560c3c-186b-492b-a482-a902de6d96af.webp)

现在我们来观察设置后的变化。假设我们设定当容量达到**80%**时触发多云扩容，即触发**Cloud扩容**。扩容完成后，将触发节点扩容，这是一个持续的过程。  

可以看到两侧都在持续扩容。节点扩容成功后，本地IDC达到最大值时，节点已经完成扩容。此时即使业务流量激增，系统仍能处理。但如果流量增长过快，可能需要等待一段时间才能完全处理。  

通常情况下，业务规模可能达到一千或两千个**Pod**，这种情况下系统通常能够应对，因为流量不会瞬间激增。综上所述，大家可以对比设置前后的情况。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/afcb9da6-dc5f-44f1-b0db-e805cb424f67.webp)

如果预设值设置合理，通常可以解决公有云和私有云场景下长时间过载的问题。最后总结两者的适用范围如下：  

**第一**，若资源受限，包括资源限制和扩缩策略（尤其是跨集群扩缩策略），例如带宽有限或成本较高，且规模较大时，可能需要选择**去中心化HPA**。反之，若带宽充足，则可选择集中式或分布式方案。集中式的优势在于学习成本极低，可直接复制配置；分布式方案稍复杂，但收益显著。  

**第二**，关于副本数扩缩的局限性：若需按优先级扩缩，目前仅支持去中心化方案；若需使用**弹性策略**（如基于可用区AZ或可用资源数的跨集群扩缩），则当前仅支持集中式HPA。具体选择取决于实际环境需求。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/2beaf151-ff6d-4b38-a325-535ce4fe4ba3.webp)

如果有兴趣，可以关注 **Karmada** 官网、GitHub 以及 Slack 上的社区小助手。感谢两位老师的精彩分享。大家若有问题，欢迎举手提问。  

我想请教一下，刚才提到的去中心化场景中，本地集群和云上集群可以设置优先级，即优先利用本地资源，待本地资源耗尽后再调度至云端。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cabe822e-3fdf-41c2-96a1-31e0539b78b9.webp)

但在缩容时，需要先手动调整本地集群的最小副本数，以确保不会优先缩减本地集群。**实际上，这一过程已由Karmada实现全自动化。**当配置了本地集群的优先级后，系统会自动完成相关设置。  

关于扩缩容策略，目前仅支持指定一个优先级：扩容按创建顺序进行，缩容则相反。此外，需要创建的是**整体HPA策略**，而非单个集群策略。例如，在控制面设置整体最小副本数为1，最大为30，并指定两个集群的分配比例（如7:3）。系统会根据设定的比例和优先级，在两个业务集群中按百分比自动计算最小和最大副本数。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/dd60aad2-d87f-4f31-aa61-87d5f0a923bb.webp)

并非如此。我们的设计初衷是，平台管理员若仅按比例分配资源，可能导致分配结果不可预期。因此，我们建议管理员通过**细粒度设置**每个集群的`minReplicas`和`maxReplicas`来控制资源状态，以避免资源超配或不足。具体实现方式为：在控制面通过列表形式分别配置各集群的副本数上下限。

关于配置生效机制，当前`HPACoordinator`的配置修改属于**原子操作**。若在伸缩过程中调整配置，系统将在当前伸缩操作完成后生效新配置。

在容灾方面，以北京和上海双集群为例：当北京集群发生故障时，系统会通过**健康检查机制**（支持通过公有云接口获取健康状态数据）进行检测，随后自动将业务重新部署至备用集群。用户可预先设置备份集群策略。

针对手动扩容场景，社区正在研发`CHPA`（CronHPA）功能，支持预设时间节点进行扩容，例如应对"双十一"或"618"等周期性业务高峰。

关于与`Karmada`的差异：虽然二者均基于`Kubernetes`实现多集群管理，但`HPACoordinator`专注于**跨集群弹性伸缩**场景，通过统一配置管理实现细粒度的多集群资源调控，而`Karmada`更侧重于多集群部署和故障迁移等场景。



关于无头服务的**Serverless架构**，您提到与阿里云的Collective服务的区别。实际上，我们的HPA机制与Serverless架构在底层原理上有相似之处。例如，当流量增加时，系统会自动拉起**POD**；流量减少时，则会自动缩减POD数量。在集群管理方面，Member集群由Controller集群进行集中管理。

与**Kinative服务**类似，我们的架构也是基于K8s构建的，将Serverless业务封装为K8s POD。Kinative可以在多集群环境中运行，借助Commander实现跨集群部署。例如青云的KS服务就采用了类似联邦模式的内部插件**CCM**。

在多集群纳管方面，确实需要中间件来实现集群间的联通性。通过Master主集群对其他Member集群进行管理时，需要**Controller组件**作为支撑。我们已对该Controller组件进行过性能压测，相关数据可在Karmada官网查阅。这个组件确实是整个架构中最重要的组件之一。



该组件堪称**最重要的组件**之一。若对性能稳定性有疑问，可查阅官网详细压测数据，其支持规模达10万集群级别。  

青云产品此前集成**KubeFeed**，现版本已切换为**Karmada**，但上月出现性能问题。我们已使用**Kube-bench**等工具进行压测，模拟大规模集群接入Karmada的场景，验证Controller整体性能表现。  

关于**Karmada HPA**的应用场景，典型案例如多活容灾部署：当业务需跨地域部署时（如北京、上海不同集群），可优先调度至本地IDC以降低成本，公有云资源作为补充。这种混合云成本优化与跨集群弹性伸缩是两大核心应用场景。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/68ea4c1d-0c60-41ac-b56e-a5b15f4817aa.webp)

由于时间限制，建议线下进一步沟通。感谢两位讲师的分享。