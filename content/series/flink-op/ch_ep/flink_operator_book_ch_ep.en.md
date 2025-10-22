---
title: "In the AI Era, Where Are Flink's Opportunities?"
date: 2025-07-22T21:59:26+08:00
draft: false
description: ""
---

## Does Real-time Have a Future?

The future of big data is real-time, and real-time computing is even more critical. The author participated in Flink Forward Asia 2024 conference, where beyond daily discussions about the latest developments in real-time computing and real-time lakehouse, conversations inevitably turned to the impact of generative artificial intelligence. Most discussions were quite uncertain, such as whether Flink could become a data pathway for RAG, whether Paimon-Python could become an entry point for AI domains into lakehouse integration, etc. To put it humorously, it's like a waiter watching a neighboring restaurant's booming business with anxiety, silently lowering his head and asking himself, "Does real-time have a future?"

### The Intelligence Loop

In the era of booming generative artificial intelligence, people often overlook computational workloads beyond deep learning. Neural network algorithms centered on deep learning have a common problem: network weights limit the form of inputs and outputs, and a common characteristic: non-streaming stateless computation. Each algorithm is defined by trained network weights, and the result of limiting input and output forms prevents algorithms from having plasticity like brain regions (such as a blind person's visual cortex being activated by auditory and tactile stimuli), making them more like neural pathways. Nowadays, these impressive algorithms are equivalent to only simulating the pathway function between brain regions A and B, but the data transmission and feedback adjustment loops are equally important yet overlooked. The overwhelming hype and praise inevitably pull algorithm competitions and innovation into a dilemma of constantly proving capability metrics. If we shift our focus from model algorithm innovation to deeply think about these "loops," isn't that also a way out? In the process of real-time data transmission, there is integration and enhancement of data, which real-time computing engines have already done well; in the feedback adjustment process, how to define state and how state is calculated and activates algorithm adjustments is a new challenge for real-time computing. At the time when reinforcement learning-based post-training techniques are just beginning to sprint, I predict that cloud-native-based real-time computing engines will serve as the "data transmission and feedback adjustment loops" and become an indispensable part of the "cloud brain." Of course, this is just a prediction. Perhaps in the future, AI domains will have real-time computing-like frameworks, or directly build new frameworks based on Flink, all possibilities. However, such technological innovations ultimately showcase algorithm innovations on stage, while those working on framework innovation remain unsung heroes, but they are also the moat of "true intelligence."

### Flink Agent Deserves Attention

Flink Agent is a brand new sub-project of Apache Flink, corresponding to the proposal [FLIP-531](https://cwiki.apache.org/confluence/display/FLINK/FLIP-531%3A+Initiate+Flink+Agents+as+a+new+Sub-Project). Here's a quote from the proposal with translation, as the original text writes very ambitiously about why this Agent is needed:

> Motivation
>
> While model quality continues to improve, the real challenge in deploying agentic systems is infrastructure. Agents require access to live data, toolchains, and other agents. They must operate continuously, share outputs asynchronously, and integrate with multiple systems. These needs aren't met by static prompt chains or batch-based pipelines.
>
> Flink is uniquely suited to meet these requirements. It offers a mature foundation for building long-running, autonomous systems that act on continuous streams of machine-generated data with low latency and high reliability.

This project was proposed at Flink Forward 2025 conference. At the time of writing, the code in the repository is at a very early stage. I suggest readers focus on two points: the project's scope of application and the project's extensibility.

First, the project's scope of application lies in the fact that readers face requirements for real-time data processing pipelines generating continuous synthetic data streams. It's important to note that the focus here is on real-time and continuous. If the requirements can accept delays and batch processing, then there are simpler data synthesis frameworks, like Dataflow or EasyDatasets.

Second, the project's extensibility. Since the overall project is still in its early stages, foreseeable extensibility includes adding support for LLM and MCP, while the underlying layer is Flink, supporting common sources and sinks of the latest Flink version (corresponding to 2.x versions).

Why mention this project? The reason is clear: this project has strong potential in integrating and replacing those currently emerging data synthesis frameworks, such as DataFlow and EasyDataset, and achieving "real-time data synthesis" through Flink's distributed and real-time capabilities. Meanwhile, "real-time data synthesis" and "context engineering" actually have some strong correlations. The core competitiveness of so-called "context engineering" is to provide better decision support for models, and only when core decision support is near real-time does the decision become more valuable. So how to provide near real-time decision data? It requires a framework to integrate LLM, MCP, and real-time data streams to complete real-time data synthesis and serve as context for model inference.

The author is also continuously following the progress of this project. Everyone is welcome to provide PRs to this project. I have also contributed some effort, helping the project improve uv support. For details, see [[ci][python][build] Modernize Python dependency management with uv](https://github.com/apache/flink-agents/pull/50)

### Lance File Format: Opportunities and Challenges

Paimon is Flink's sibling team. As a rising star in lake formats, its AI direction strategy and movements are also worth paying attention to.

Paimon also proposed Lance file format compatibility at Flink Forward 2025. Lance file format is a new columnar data format proposed by Lance company, a new file format aimed at replacing Parquet and ORC.

The Lance project is very new, built with Rust language, mainly implementing two core functions:
- As a file format (using .lance extension), it provides columnar storage solutions that support both fast scanning and efficient random access capabilities, similar to Parquet.
- As a table format, it can organize multiple Lance files into dataset structures, including ACID-compliant metadata, and can build secondary indexes on Lance files.

Lance as a file format is also a disk format, with Apache Arrow as the core memory interface framework, which is also similar to Parquet; supported ecosystem frameworks include Pandas, Polars, DuckDB, PyTorch, Spark; it also supports conversion from other column formats to Lance datasets.

For more details about LanceDB and Lance, you can check my other article [Lance CEO Interview Details](TODO)

The opportunity for Paimon to support Lance lies in the fact that for unstructured large files such as audio, video, high-resolution images contained in multimodal datasets, they are generally stored in data tables in BLOB format. Compared to Parquet format, Lance has made many optimizations and improvements for OLAP retrieval, vector retrieval, and I/O reading of these BLOB formats. When we build or synthesize multimodal datasets, Paimon as a lake storage has typical scenarios in retrieving and updating these unstructured files, and Lance file format support can well support multimodal dataset scenarios.

At the time of writing, multimodal large models are the next AI trend, and they can also truly unlock the application potential of models. I believe that Lance file format being integrated by Paimon is both an opportunity and a challenge. Not all companies can hire enough experienced people to build multimodal data lakes, and not all companies can do well in data processing pipelines for datasets.

In conclusion, real-time computing has a future, but it's full of opportunities and challenges. The requirements for talent are still increasing. In the future, those who can truly stand out will inevitably be composite talents with backgrounds in big data, artificial intelligence, and cloud-native technologies, which has been continuously proven by Silicon Valley startups. For a company, consideration should be given to how to cultivate more composite talents from existing technical soil and trends, rather than blindly chasing trends and going overseas to compete for funding to find specialists. Composite talents will always be the core competitiveness of future companies.
