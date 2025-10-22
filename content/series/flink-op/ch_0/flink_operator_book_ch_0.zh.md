---
title: "大数据与云原生"
date: 2024-10-22T20:21:16+08:00
draft: false
description: ""
---

## 为什么大数据底座需要是云原生？

当数据产业从起步转向成熟，以Apache Hadoop体系为主的大数据平台面临着资源弹性扩展、服务自愈性、计算异构性、调度可靠性、性能可观测性的种种问题，显得捉襟见肘。

而这些问题，当大数据装上云原生的底座时，都能够迎刃而解。毫无疑问，以CNCF Kubernetes为核心的云原生架构已经是未来基础设施的事实标准。云原生架构通过容器化、微服务、自动扩缩容等特性，能够实现真正的弹性扩展，按需分配资源，避免资源浪费。

Kubernetes作为统一的资源调度平台，消除了YARN、Mesos等不同调度机制的割裂，保证了计算负载间的资源隔离，同时能够适配GPU、FPGA、RISC-V等异构平台上大数据计算负载的调度和执行。Helm的Chart形式部署使得大数据组件的部署、升级、回滚变得标准化和自动化。大数据组件集成Prometheus、Grafana等云原生监控工具，实现全链路可观测。多租户的大数据平台能够通过Namespace、RBAC等机制实现资源隔离和服务权限隔离。最后，通过自定义Operator框架的手段，能够将大数据领域高居不下的运维成本逐步自动化。

让云原生成为大数据的基础架构，这种架构演进不是简单的技术升级，而是对整个大数据生态系统的重新定义。它让大数据平台从"重资产、高门槛、难运维"的传统模式，转向"轻量化、标准化、自动化"的现代模式。

## 实时计算引擎的真实痛点

回到正题，实时计算引擎为何拥抱云原生？计算引擎如Flink，在Hadoop架构体系下数据开发过程中面临几个真实痛点：
- 资源隔离性差：不同作业间缺乏有效的资源隔离手段，一个作业资源控制异常会影响整个集群
- 版本管理困难：作业版本升级时需要停机维护，不支持滚动升级手段
- 故障恢复困难：不支持作业集群的自动恢复，需要依靠接收告警后手动运维
- 配置管理复杂：不支持声明式定义运行依赖，需要在不同环境下单独维护启动脚本，容易出错
- 集群监控困难：不支持集群和组件部署状态的监控
- 基础设施绑定：基础设施版本与计算引擎绑定，需要考虑计算引擎版本的兼容性和稳定性
- 异构计算无能：无法考虑异构计算，需要将计算过程进行拆解成多个不同子系统
- 部署成本极高：大量计算资源的弹性伸缩难实现，构建成本高且维护成本也高
- 资源利用率低：大量实时计算任务申请超量资源来应对峰值流量，闲时利用率很低

为了解决上述痛点，Flink社区其实很早就开始转向云原生社区，上述痛点也基本上都能找到解决方案。而Flink社区转向云原生架构的提案也值得好好梳理一番：

| 年份 | 版本 | FLIP | 简要内容 | 解决痛点 |
|------|------|------|---------|---------|
| 2018 | Flink v1.5 | [FLIP-6](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=65147077) | Flink部署和进程模型，支持独立模式、Yarn、Mesos、Kubernetes等 | 基础设施绑定、部署成本极高、异构计算无能、资源隔离性差 |
| 2020 | Flink v1.10 | [FLINK-9953](https://issues.apache.org/jira/browse/FLINK-9953) | Flink部署支持 Kubernetes 原生模式，由 Flink 管理 Kubernetes 资源创建 | 基础设施绑定、部署成本极高、、资源利用率低、资源隔离性差 |
| 2022 | Flink v1.12 | [FLIP-144](https://cwiki.apache.org/confluence/display/FLINK/FLIP-144%3A+Native+Kubernetes+HA+for+Flink) | Flink的原生Kubernetes高可用，使用K8s Configmap做HA信息存储 | 故障恢复困难、集群监控困难 |
| 2022 | Flink Operator v1.0 | [FLIP-212](https://cwiki.apache.org/confluence/display/FLINK/FLIP-212%3A+Introduce+Flink+Kubernetes+Operator) | 引入Flink Kubernetes Operator，推出官方Operator子项目 | 配置管理复杂、故障恢复困难 |
| 2023 | Flink Operator v1.4 | [FLIP-271](https://cwiki.apache.org/confluence/display/FLINK/FLIP-271%3A+Autoscaling) | 新增自动资源扩缩容模块，基于FLIP-291外部化声明式资源管理 | 部署成本极高、资源利用率低|
| 2023 | Flink Operator v1.7 | [FLIP-334](https://cwiki.apache.org/confluence/display/FLINK/FLIP-334+%3A+Decoupling+autoscaler+and+kubernetes+and+support+the+Standalone+Autoscaler) | 解耦autoscaler和kubernetes，支持独立运行Autoscaler | 部署成本极高、资源利用率低|
| 2024 | Flink Operator v1.10 | [FLIP-446](https://cwiki.apache.org/confluence/display/FLINK/FLIP-446%3A+Kubernetes+Operator+State+Snapshot+CRD) | Kubernetes Operator State Snapshot CRD，新增自定义资源对象Snapshot | 配置管理复杂、故障恢复困难 |
| 2025 | Flink Operator WIP| [FLIP-503](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=337677648) | Flink在Kubernetes上的蓝绿部署：第一阶段（基础） | 版本管理困难 |
| 2025 | Flink Operator WIP| [FLIP-504](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=337677650) | Flink在Kubernetes上的蓝绿部署：第二阶段（协调） | 版本管理困难 |

从上图表格可见，实时计算引擎的进展集中于Flink项目本身与Flink Operator子项目中，Flink Operator经过这几年的发展，已经逐步解决了许多Flink在传统架构中的痛点，同时最新的进展是正在支持蓝绿部署。可以预见的是，Flink Operator子项目将是未来Flink项目云原生方向上的核心，要做好云原生的实时计算引擎，Flink Operator将是必知必会的内容。



