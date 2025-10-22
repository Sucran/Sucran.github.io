---
title: "Big Data and Cloud Native"
date: 2024-10-22T20:21:16+08:00
draft: false
description: ""
---

## Why Does Big Data Infrastructure Need to Be Cloud Native?

When the data industry transitions from startup to maturity, big data platforms primarily based on the Apache Hadoop ecosystem face various challenges including elastic resource scaling, service self-healing, computational heterogeneity, scheduling reliability, and performance observability, making them appear inadequate.

However, these problems can all be resolved well when big data is built on cloud-native infrastructure. Undoubtedly, cloud-native architecture centered around CNCF Kubernetes has become the de facto standard for future infrastructure. Cloud-native architecture, through containerization, microservices, auto-scaling, and other features, can achieve true elastic scaling, on-demand resource allocation, and avoid resource waste.

Kubernetes, as a unified resource scheduling platform, eliminates the fragmentation of different scheduling mechanisms like YARN and Mesos, ensures resource isolation between computational workloads, and can adapt to big data computational workloads on heterogeneous platforms such as GPU, FPGA, and RISC-V. Helm's Chart-based deployment makes the deployment, upgrade, and rollback of big data components standardized and automated. Big data components integrate with cloud-native monitoring tools like Prometheus and Grafana to achieve end-to-end observability. Multi-tenant big data platforms can achieve resource isolation and service permission isolation through mechanisms like Namespace and RBAC. Finally, through custom Operator frameworks, the high operational costs of big data domains can be gradually automated.

Making cloud-native the foundation of big data is not a simple technical upgrade but a redefinition of the entire big data ecosystem. It transforms big data platforms from the traditional model of "heavy assets, high barriers, difficult operations" to the modern model of "lightweight, standardized, automated."

## Real Pain Points of Real-time Computing Engines

### Does Real-time Have a Future?

The future of big data is real-time, and real-time computing is even more critical. The author participated in Flink Forward Asia 2024 conference, where beyond daily discussions about the latest developments in real-time computing and real-time lakehouse, conversations inevitably turned to the impact of generative artificial intelligence. Most discussions were quite uncertain, such as whether Flink could become a data pathway for RAG, whether Paimon-Python could become an entry point for AI domains into lakehouse integration, etc. As a joke, it's like a waiter watching a neighboring restaurant's booming business with anxiety, silently lowering his head and asking himself, "Does real-time have a future?"

In the era of booming generative artificial intelligence, people often overlook computational workloads beyond deep learning. Neural network algorithms centered on deep learning have a common problem: network weights limit the form of inputs and outputs, and a common characteristic: non-streaming stateless computation. Each algorithm is defined by trained network weights, and the result of limiting input and output forms prevents algorithms from having plasticity like brain regions (such as a blind person's visual cortex being activated by auditory and tactile stimuli), making them more like neural pathways. Nowadays, these impressive algorithms are equivalent to only simulating the pathway function between brain regions A and B, but the data transmission and feedback adjustment loops are equally important yet overlooked. The overwhelming hype and praise inevitably pull algorithm competitions and innovation into a dilemma of constantly proving capability metrics. If we shift our focus from model algorithm innovation to deeply think about these "loops," isn't that also a way out? In the process of real-time data transmission, there is integration and enhancement of data, which real-time computing engines have already done well; in the feedback adjustment process, how to define state and how state is calculated and activates algorithm adjustments is a new challenge for real-time computing. When reinforcement learning-based post-training techniques are just beginning to sprint, I predict that cloud-native-based real-time computing engines will serve as the "data transmission and feedback adjustment loops" and become an indispensable part of the "cloud brain." Of course, this is just a prediction. Perhaps in the future, AI domains will have real-time compution frameworks, or directly build new frameworks based on Flink. However, such technological innovations ultimately showcase algorithm innovations on stage, while framework innovation pioneers are the unsung heroes, but they are also the moat of "true intelligence."

### Why Do Real-time Computing Engines Embrace Cloud Native?

Back to the topic, why do real-time computing engines embrace cloud-native? Computing engines like Flink face several real pain points in the data development process under the Hadoop architecture:

- Poor resource isolation: Lack of effective resource isolation between different jobs, where resource control anomalies in one job can affect the entire cluster
- Difficult version management: Job version upgrades require downtime maintenance, with no support for rolling upgrade methods
- Difficult fault recovery: No support for automatic recovery of job clusters, requiring manual operations after receiving alerts
- Complex configuration management: No support for declarative definition of runtime dependencies, requiring separate maintenance of startup scripts in different environments, prone to errors
- Difficult cluster monitoring: No support for monitoring cluster and component deployment status
- Infrastructure binding: Infrastructure versions are bound to computing engines, requiring consideration of computing engine version compatibility and stability
- Inability for heterogeneous computing: Cannot consider heterogeneous computing, requiring decomposition of computational processes into multiple different subsystems
- Extremely high deployment costs: Difficult to achieve elastic scaling of large amounts of computational resources, high construction costs and high maintenance costs
- Low resource utilization: Large amounts of real-time computing tasks apply for excessive resources to handle peak traffic, with very low utilization during idle periods

To address these pain points, the Flink community has long started transitioning to the cloud-native community, and solutions can basically be found for all the above pain points. The Flink community's proposals for transitioning to cloud-native architecture are worth carefully organizing:

| Year | Version | FLIP | Brief Content | Pain Points Solved |
|------|---------|------|---------------|-------------------|
| 2018 | Flink v1.5 | [FLIP-6](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=65147077) | Flink deployment and process model, supporting standalone mode, Yarn, Mesos, Kubernetes, etc. | Infrastructure binding, extremely high deployment costs, inability for heterogeneous computing, poor resource isolation |
| 2020 | Flink v1.10 | [FLINK-9953](https://issues.apache.org/jira/browse/FLINK-9953) | Flink deployment supports Kubernetes native mode, with Flink managing Kubernetes resource creation | Infrastructure binding, extremely high deployment costs, low resource utilization, poor resource isolation |
| 2022 | Flink v1.12 | [FLIP-144](https://cwiki.apache.org/confluence/display/FLINK/FLIP-144%3A+Native+Kubernetes+HA+for+Flink) | Flink's native Kubernetes high availability, using K8s Configmap for HA information storage | Difficult fault recovery, difficult cluster monitoring |
| 2022 | Flink Operator v1.0 | [FLIP-212](https://cwiki.apache.org/confluence/display/FLINK/FLIP-212%3A+Introduce+Flink+Kubernetes+Operator) | Introduce Flink Kubernetes Operator, launch official Operator subproject | Complex configuration management, difficult fault recovery |
| 2023 | Flink Operator v1.4 | [FLIP-271](https://cwiki.apache.org/confluence/display/FLINK/FLIP-271%3A+Autoscaling) | Add automatic resource scaling module, based on FLIP-291 externalized declarative resource management | Extremely high deployment costs, low resource utilization |
| 2023 | Flink Operator v1.7 | [FLIP-334](https://cwiki.apache.org/confluence/display/FLINK/FLIP-334+%3A+Decoupling+autoscaler+and+kubernetes+and+support+the+Standalone+Autoscaler) | Decouple autoscaler and kubernetes, support standalone Autoscaler operation | Extremely high deployment costs, low resource utilization |
| 2024 | Flink Operator v1.10 | [FLIP-446](https://cwiki.apache.org/confluence/display/FLINK/FLIP-446%3A+Kubernetes+Operator+State+Snapshot+CRD) | Kubernetes Operator State Snapshot CRD, add custom resource object Snapshot | Complex configuration management, difficult fault recovery |
| 2025 | Flink Operator WIP | [FLIP-503](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=337677648) | Blue/Green deployments for Flink on Kubernetes: Phase 1 (basic) | Difficult version management |
| 2025 | Flink Operator WIP | [FLIP-504](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=337677650) | Blue/Green deployments for Flink on Kubernetes: Phase 2 (coordination) | Difficult version management |

From the above table, it can be seen that the progress of real-time computing engines is concentrated in the Flink project itself and the Flink Operator subproject. After several years of development, Flink Operator has gradually solved many pain points of Flink in traditional architecture, while the latest progress is supporting blue/green deployment. It can be foreseen that the Flink Operator subproject will be the core of the Flink project's cloud-native direction in the future. To build a good cloud-native real-time computing engine, Flink Operator will be essential knowledge.
