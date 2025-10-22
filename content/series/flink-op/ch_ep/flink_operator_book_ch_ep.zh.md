---
title: "人工智能时代, Flink的机会在哪里?"
date: 2025-07-22T21:59:26+08:00
draft: false
description: ""
---

## 实时有未来吗？

大数据的未来是实时，实时计算更是重中之重。笔者曾参与过Flink Forward Asia 2024年大会，除了日常讨论一些实时计算、实时湖仓的最新进展，总会不可避免地聊到生成式人工智能的影响。大多数的讨论都比较迷茫，比如Flink能不能成为RAG的数据通路，Paimon-Python能不能成为AI领域切入湖仓一体的入口等等？开个玩笑就是，像极了看着对门饭店生意火爆而倍感不安的伙计，只能默默地低下头问自己一句，实时还有未来吗？

### 智能的环路

在生成式人工智能时代火热朝天的时候，人们往往会忽视除了深度学习以外的计算负载。以深度学习为核心的神经网络算法，有一个共性问题，即网络权重限制了输入和输出的形式，同时有一个共性特征，即非流式的无状态计算。每个算法被训练好的网络权重所定义，被限制输入和输出形式的结果使算法无法像大脑的脑区一样具有可塑性（比如盲人的视觉区可以被成听觉和触觉激活），而更像是神经通路。现如今这些牛逼哄哄的算法，相当于仅仅是把大脑中A-B两区的通路功能模拟了，但是传输数据和反馈调整的环路同样也很重要，却被忽略了。铺天盖地的炒作和吹捧，不可避免地将算法竞赛和创新拉入一个不断自证能力指标的困局。如果将眼光从模型算法创新挪开，去深刻思考这些“环路”，又何尝不是一种出路。实时传输数据的过程中，带有对数据的整合和增强，这点实时计算引擎已经做的很好；在反馈调整的过程中，如何定义状态以及状态如何计算并激活算法的调整，则是实时计算的一个新的考验。在强化学习为主的后训练技术刚刚发起冲刺的时间点，我预测，云原生为底座的实时计算引擎，将作为“传输数据和反馈调整的环路”，成为“云上大脑”不可或缺的一部分。当然这还只是预测，兴许未来AI领域会有类实时计算的框架的出现，或者直接基于Flink进行构建新的框架，都有可能。只是这样的技术创新，最后摆到台面上的还是算法创新，那些致力于框架创新的人，都是默默无闻的支持者，但他们也是“真正智能”的护城河。

### Flink Agent 值得关注

Flink Agent是Apache Flink的一个全新的子项目，这个项目对应的提案是[FLIP-531](https://cwiki.apache.org/confluence/display/FLINK/FLIP-531%3A+Initiate+Flink+Agents+as+a+new+Sub-Project), 这里贴一段提案中的原文和翻译，原文对为什么需要有这个Agent写的非常野心勃勃：

> Motivation 动机
>
> While model quality continues to improve, the real challenge in deploying agentic systems is infrastructure. Agents require access to live data, toolchains, and other agents. They must operate continuously, share outputs asynchronously, and integrate with multiple systems. These needs aren't met by static prompt chains or batch-based pipelines.
>
> 虽然模型质量持续提升，但在部署智能体系统时，真正的挑战在于基础设施。智能体需要访问实时数据、工具链和其他智能体。它们必须持续运行，异步共享输出，并与多个系统集成。这些需求无法通过静态提示链或基于批次的管道满足。
>
> Flink is uniquely suited to meet these requirements. It offers a mature foundation for building long-running, autonomous systems that act on continuous streams of machine-generated data with low latency and high reliability.
>
> Flink 特别适合满足这些要求。它提供了一个成熟的平台，用于构建长时间运行、自主的系统，这些系统能够以低延迟和高可靠性处理连续的机器生成数据流。

这个项目是 Flink Forward 2025 大会上提出的，在笔者书写的时间点，目前代码仓库的代码还在完善，处于一个非常初级的阶段。我建议读者们关注两个点，一个是项目的适用范围，一个是项目的可扩展性。

首先，项目的适用范围在于，读者所面临的需求是实时数据处理管道生成连续的合成数据流。需要注意的是，这里的重点在于实时和连续，如果需求能接受延迟和分批次，那么有更简单的数据合成框架。

其次，项目的可扩展性，由于目前整体项目还处于初级阶段，可以预见的可扩展性是增加了LLM和MCP的支持，同时底层是Flink，支持Flink最新版本（对应2.x版本）的常见source和sink。

为什么提这个项目？理由很明确，这个项目有很强的潜力，在于整合和替代当前正在崛起的那些数据合成的框架，比如DataFlow和EasyDataset，并通过Flink的分布式和实时能力来实现“实时数据合成”。同时，“实时数据合成”和“上下文工程”其实有一些强关联，所谓的“上下文工程”的核心竞争力是为模型提供更好的决策支持，而只有核心决策支持是近实时的，这时候决策才更具有价值。而如何提供近实时的决策数据呢？需要依赖一个框架来整合llm、mcp、实时数据流来完成实时数据合成，并作为上下文，提供给模型做推理。

笔者也在持续关注这个项目的进展，欢迎大家给这个项目提供pr，我也有出一些微博之力，帮这个项目改造了一下uv的支持，详情见[[ci][python][build] Modernize Python dependency management with uv](https://github.com/apache/flink-agents/pull/50)

### Lance 文件格式 机遇与挑战

Paimon 是 Flink 的兄弟团队，作为一颗冉冉升起的湖格式的新星，AI方向上的策略和动向也非常值得关注。

Paimon 也是在 Flink Forward 2025 提出关于Lance文件格式的兼容，Lance文件格式是Lance公司提出的一种新型的列式数据格式，一种旨在取代Parquet和ORC的新型文件格式。

Lance 项目很新，使用 Rust 语言构建，主要实现两大核心功能：
- 作为文件格式（使用 .lance 扩展名），提供列式存储方案，既支持快速扫描也具备高效随机访问能力，与 Parquet 类似。
- 作为表格式，能将多个Lance文件组织成数据集的结构，这些数据集包括支持 ACID 的元数据，并可以在 Lance 文件上建立二级索引。

Lance 作为文件格式，也是一种磁盘格式，核心内存接口框架是 Apache Arrow，这个也和 Parquet 类似；支持的生态框架包括Pandas、Polars、DuckDB、PyTorch、Spark；同时也支持从其他列格式转换到 Lance 数据集。

关于 LanceDB 和 Lance 的更多细节，可以查看我的另一篇文章[Lance CEO访谈细节整理](TODO)

Paimon 支持 Lance 的机遇在于，对于多模态数据集中包含的音频、视频、高分辨率图片等非结构化的大型文件，一般是以BLOB格式存储到数据表，这些 BLOB 格式的 OLAP 检索、向量检索、I/O 读取相对于 Parquet 格式，Lance都做了非常多的优化和提升。当我们构建或者合成多模态数据集时，Paimon作为湖存储，很典型的场景在于检索和更新这些非结构化的文件，而 Lance 文件格式的支持，能够很好地支持多模态数据集的场景。

笔者写作的时间点来说，多模态大模型是下一个AI的风口，同时也能真正的打开模型的应用潜力。我认为 Lance 文件格式被 Paimon 集成，既是一种机遇，也是一种挑战。并非所有公司都能够招聘到足够有经验的人来构建多模态数据湖，另外是并非所有公司都能够做好数据集的数据处理管道。

综上所述，实时计算是有未来的，但充满着机遇和挑战。对于人才的要求还在提升，未来真正能崭露头角的人，必然是同时具备大数据、人工智能、云原生技术背景的复合人才，这一点也被硅谷的创业公司不断证实。对于一家公司，应该考虑的是，如何从现有的技术土壤和风向中培养起更多复合型的人才，而不是一味地追逐风口、出海争夺融资来找专才，复合型人才始终是未来公司的核心竞争力。
