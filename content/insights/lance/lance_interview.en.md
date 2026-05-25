---
title: "Lance：A Modern Columnar Data Format"
date: "2025-10-31T12:54:09+08:00"
draft: "false"
description: ""
---




![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/165b7d23-1679-431b-8d1d-5efef9f1be95.webp)




The **Databases for Machine Learning and Machine Learning for Databases Seminar Series** at Carnegie Mellon University is recorded in front of a live studio audience.  


Funding for this program is provided by **Google** and contributions from viewers like you. Thank you.  


Welcome back to another seminar at Carnegie Mellon University.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/abc3fda4-d305-4b13-98e1-132a0e05186b.webp)






We are pleased to have **Chang She** with us today. He is the co-founder and **CEO of Lance**, a company developing a new file format and query execution engine designed to replace Parquet and ORC. This **innovative work** is highly relevant, which is why we invited him to share his insights.  


As always, if you have questions for Cheng during his talk, please unmute yourself, introduce who you are, and ask your question. You are welcome to do this at any time. If you cannot unmute, post your question in the chat, and we will interrupt to relay it. We encourage this interaction to ensure Cheng is not speaking alone for an hour on Zoom.  


**Cheng**, thank you for joining us remotely from MIT. The floor is yours.  


Thank you, Andy. I appreciate the opportunity and everyone's attendance. Please feel free to interrupt me with questions, as I have **ScreenShare** in full screen and won’t see the chat.  


Today, I will discuss a project we’ve been working on for the past year: a new **columnar data format** called Lance. First, a brief introduction about myself.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/a86ec0c6-0c37-4c2c-974b-035363f8aa97.webp)




My name is Chang She, CEO and Co-founder of LanceDB. As Andy mentioned, I have been developing **data science** and **machine learning** tooling for nearly two decades. I was one of the original contributors to the **Pandas** library approximately 13 years ago. Subsequently, I served as CTO of DataPad alongside Wes McKinney, the creator of Pandas.  


My career then led me to Cloudera. Later, I became VP of Engineering at TubiTV, a streaming company, where I specialized in **recommendation systems**, **MLOps** for recommendation systems, and experimentation.  


This background naturally leads to the question: why are we pursuing this endeavor?






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/799c3130-f1f4-4307-8d50-ad8fded2a510.webp)






When Andy invited me to the seminar, I was genuinely excited. Since the **Pandas** era, I've been deeply interested in the intersection of data and **machine learning** or **data science**. My experience at 2B, where I observed numerous recommendation systems handling both structured and unstructured data, was particularly enlightening. It demonstrated how effectively integrated data systems and machine learning can transform a company's operations, yielding superior tools and more efficient management.


At 2B, I witnessed firsthand the transformative impact of a robust machine learning experimentation platform. Initially, we conducted perhaps one experiment every two months. Over two years of refining the integration between analytics data systems and machine learning, we scaled to running 30 to 50 concurrent experiments company-wide. This dramatically accelerated progress and iteration.


However, this integration demands extensive "couples counseling"—both technical and non-technical. The challenges are magnified with **unstructured data**, where scale has skyrocketed, data types have grown increasingly complex, and workloads are more intricate than ever. **Vector databases**, for instance, seem to have regressed to early 2010s standards, which I'll elaborate on shortly.


Consider the contrast between tabular data and unstructured data. A floating-point number might occupy four or eight bytes, whereas the MLDB seminar logo, at 145 kilobytes, is orders of magnitude larger. Even with modest row counts, petabyte-scale datasets are now commonplace. Startups working with unstructured and multimodal data often grapple with multi-terabyte datasets, which are challenging for small teams. Some **generative AI** applications, managed by teams of around 20 people, already handle several petabytes of data.


Consequently, **object storage** must be central to any modern data system, along with addressing the associated consistency and performance challenges. Beyond traditional tabular data types, we now deal with vector embeddings, images, audio, video, and point clouds—none of which integrate seamlessly into conventional databases. While various plugins exist for systems like Postgres, none offer truly native-level functionality.












Most of these issues arise because traditional databases and formats are not optimized for large **BLOB storage**. Additionally, they lack essential **semantic types**, which are crucial for building effective tools on top of them. For instance, if a BI or analytics tool cannot distinguish between a binary column containing images and one containing audio, it necessitates extensive type checking or leads to inefficient queries.  


Beyond semantic types, these systems also lack common transformations. For images, operations like shuffling, rotations, and noise addition are often needed, and it would be beneficial to have native support for these at the database level. Consequently, workloads become more complex. Traditional **row-key (RK)** approaches are insufficient for such tasks.  


In **ML exploratory data analysis (EDA)** and debugging, fast random access is essential. For example, applying a filter might select 10 random images from a dataset, which then need to be loaded quickly for exploration or identifying problematic cases. Similarly, training requires fast shuffling, especially as models grow larger. Within-batch shuffling may no longer suffice, necessitating global shuffling, which also demands fast random access.  


While **TFRecords** and similar tensor-optimized formats are adequate for training, they fall short in supporting fast **OLAP operations** for filtering and analytics, which are critical for selecting the right dataset to feed into GPUs.  


Reproducibility and version tracking are even more vital in ML workflows. Checkpointing models or introducing new data can lead to unexpected changes in model performance, requiring a flexible table format to track these variations. However, connecting **PyTorch** directly to a **Hive metastore** for dataset access is often impractical.  


Lastly, the proliferation of **vector databases**—now numbering around 20—highlights the growing need for specialized solutions in this space.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/6decbc8c-66e7-4a31-8437-95d856430fff.webp)






However, upon closer examination, I find **vector databases** somewhat retro. They resemble index wrappers more than fully-fledged databases. Most lack comprehensive data management capabilities or integrated storage around the index, similar to a SAS B-tree index.  


After obtaining vector search results, you cannot directly serve vectors to users—you must retrieve the actual documents or images from another source. This exemplifies why they don’t function as complete databases.  


**Deployment** feels reminiscent of the early 2010s, requiring capacity planning for Hadoop clusters, instance type selection, and manual scaling. A misconfigured index often necessitates complete re-indexing. Additionally, the absence of compute-storage separation becomes costly at scale.  


Initially in generative AI, scaling seemed unnecessary with modest vector counts (e.g., 10,000–50,000). However, as applications mature, embedding volumes grow significantly—whether through large single datasets or numerous smaller ones aggregating substantial vectors.  


For validation, consider **Andy's perspective** on this matter.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/68a4c2a3-b29d-45dd-a7f3-3f00c5edb08c.webp)



This chart is sourced from a recent paper co-authored by Andy and West, titled *An Empirical Evaluation of Columnar Storage Formats*. When examining the timings for **vector index search** using Parquet and ORC—a common requirement in machine learning workloads due to the need for fast random access—the performance is notably suboptimal.  


Interestingly, the comparison between Parquet and ORC yields contrasting results on **SSD** versus **S3**, which presents an intriguing observation.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/3d00f8ad-cb23-4140-9383-0c9d8f79b264.webp)






To address these challenges, we initiated the **Lance project** in mid-last year, initially developed in C++. At the beginning of this year, we rewrote it in Rust. The current version is less than a year old.  


Lance serves two primary purposes:  


1. It is a **file format** (with `.lance` extension) that provides columnar storage, supporting both fast scans and efficient random access. This makes it analogous to Parquet.  


2. It functions as a **table format**, allowing multiple Lance files to be grouped into what we term Lance datasets. These datasets include metadata that enables ACID transactions and supports secondary indices on Lance files. In this capacity, Lance serves as a lightweight alternative to Iceberg, specifically tailored for machine learning workflows.  


This outlines Lance's position within the technology stack.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/6d12c4d4-2828-4846-a88a-39717e2ccb3f.webp)




Lance is a **disk format**, analogous to Parquet. Our primary interface is Apache Arrow, an open standard for in-memory representations. This integration simplifies ecosystem compatibility.  


Initially a two-person team, we have grown to just over 10 members, with approximately half focused on the format. Given **resource constraints**, Arrow facilitated seamless tooling integration and simplified migration. Converting to Lance datasets from other columnar formats now requires minimal code.  


Today, Lance is utilized across diverse applications.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/024f2557-a48b-44ea-a71a-7a3c04645b70.webp)




We initially worked with autonomous vehicle companies that store petabyte-scale data in Lance for large-scale data mining. For instance, following an accident involving a Tesla on the Bay Bridge in San Francisco—where the algorithm incorrectly applied the brakes, resulting in a fatality—our **autonomous vehicle clients** urgently needed to scan petabytes of data to identify all similar instances. Lance enabled them to efficiently run **OLAP-style data mining queries** on deeply nested vehicle sensor data.


Next, some users adopted Lance as their **data lake** for generative AI training, particularly for multimodal applications like image generation. This involves managing a petabyte of images for training, analytics, debugging, and serving vector search.


Finally, Lance supports **semantic search** for both LLMs and traditional recommender systems. We serve billions of embeddings per model version, achieving low-latency performance on a single node with a fast NVMe drive. I will demonstrate this shortly.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/fe2c401e-0389-477a-b44d-faedeb1e6d51.webp)



All right. Here are a couple of benchmarks. This is a **high-level benchmark** using the Oxford Pets dataset, which contains approximately 8,000 images of cats and dogs. We ran computer vision workloads, including computing the label distribution (value counts by class) and the histogram of bounding box areas. Additionally, we retrieved inline images based on filters and row selections.  


The first two tasks involve scans over **tabular data**, where performance is comparable to Parquet. The raw column represents the original dataset, consisting of images, XML, and text annotations. The final task involves retrieving filtered images across the entire dataset, where performance is approximately two orders of magnitude faster than Parquet.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/6effe3dd-ae4f-4ba4-b68a-3476c697989b.webp)




We replicated the benchmarks from Andy and Wes's paper and included **Lance** in the comparison. For both **SSD** and **S3** scenarios, Lance is at least one order of magnitude faster than the faster of the two options.  


The data fetch time is approximately two milliseconds on SSD and around a few hundred milliseconds on S3. This performance was measured on a subset of 100 million rows from the **LAION-5B** dataset.  


We are highly satisfied with Lance's performance, but there are still many new opportunities for improvement.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/ffbc2bf7-e563-4343-87ec-96eb3f1b0fdc.webp)



Are you going to discuss the **root causes** for the significant performance improvement?  


We will now examine the reasons behind the performance difference observed in the previous slide and how these techniques contribute to it. However, the explanation may not be as straightforward as anticipated.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/b2bcac78-543a-4587-ac91-a4468467fb16.webp)


This is an excellent question. There are several **key considerations**. First, the encoding and data layout are crucial, particularly for **Parquet**, which inherently limits fast random access. Additionally, the I/O plan for Lance differs significantly from typical scanners for Parquet and ORC, primarily due to the need to support large **BLOB** data.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/e9ba4353-dc94-4c62-aebf-2dba4b3ef117.webp)




The dataset **layout indices** are not relevant to this particular problem, but they offer useful features for machine learning, as we will discuss later.  


Before delving into details, are there any other questions?  


To proceed, as previously mentioned, **Lance** is designed to excel in both large scans and random point queries. It also supports storing large blobs. There are some counterintuitive aspects when comparing Lance to traditional **OLAP** and columnar store designs.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/83a1ff0e-b766-4353-98b1-90e0238a3b5a.webp)




The key design principles are to ensure we do not scan more data than **Parquet** or **ORC**, while delivering constant-time lookup for individual rows and amortizing metadata overhead across multiple lookups.  


Parquet was designed in 2011, and storage technologies have evolved significantly since then. We aimed to revise assumptions around concurrency, threading, block sizes, and other factors to establish more reasonable defaults.  


The simplest starting point is our plain encoder.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/9c27fc74-7626-44b0-a3a8-5befa260e044.webp)



This applies to fixed-size data types, numeric types, as well as embedding vectors and tensors. The **implementation is straightforward**, enabling constant direct access with offset computation during runtime. It efficiently supports both fast scans and random access.  


A **key feature** is the support for various tensor layouts, eliminating the need for in-memory transposition before feeding data into the GPU.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/4e71f433-c574-4f5a-930d-a94033c7dbd5.webp)



Currently, one of the missing features in the dataset is **null support** for the plain encoder. The plan is to add a validity bitmap within each block, ensuring it does not negatively impact our NVMe access performance.  


This implementation for the plain encoder is straightforward.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/96f21bc1-b3fc-4ca1-8894-1c4f4abd86d1.webp)





Next is the **binary encoder** for variable-length strings and bytes, which stores data such as images and point clouds. This is one of the **key differences** between Lance and Parquet.  


In Parquet's layout, offset data is interleaved, requiring the entire row group to be read to locate a single row. This explains Parquet's **poor performance** in random access and fetching specific images across the dataset, especially when record sizes are large. For example, vector embeddings like OpenAI's are medium-sized, while images and point clouds can be dozens of megabytes, making it impractical to read thousands of them.  


A suggestion was made to include a prefix or sketch in the offset array for strings, enabling partial filtering without decompression. While this approach works for strings, it is less applicable to images, which require full inspection.  


Initially, the focus on **computer vision** led to designing a general encoder for various data types. In Lance, offsets and data are stored together, allowing direct access without extensive filtering. **Metadata matching** is typically used to locate specific images, followed by offset-based retrieval.







For a given block, you read the **offsets** all at once. Once you have the offsets, you achieve **constant-time access**. The offsets must be held in memory to amortize the read time.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/90128054-2691-47f0-83c3-c1a7b6468697.webp)


We have not yet implemented **advanced encodings**, but they are on our roadmap. These include **run-length encoding (RLE)** for compressing repeated data while maintaining fast lookups, as well as variable encodings where each chunk can have its own encoding.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/5bece8ad-0525-4c30-ae97-f8aa5937d54a.webp)


Right. We aim to implement these **encodings** to support more compressed data while maintaining fast lookups. These features are currently on our **roadmap** and are expected to be available by early next year.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/e8468374-606c-469d-b0af-022ed5f1205b.webp)





Let me pause here and turn the question to the audience. We've discussed how a different data layout enables both fast scans and fast point queries. **What is the trade-off involved?**


The primary trade-off is in compression. Implementing compression becomes more challenging because we cannot apply file-level compression methods like Snappy. For datasets dominated by large **BLOB data types**, such as images, the dataset size is primarily determined by these columns. For instance, storing JPEG bytes—already compressed at the record level—means the final dataset size in LanceDB is not significantly larger than compressed Parquet. However, for purely tabular data, compressed Parquet will be noticeably smaller.


The additional storage cost is manageable, especially when not using high-performance storage like **NVMe**. Over time, this gap may narrow as we incorporate more advanced encodings, though it is unlikely to disappear entirely.


Now, let’s move to the next topic: **IO execution**. For large blobs, late materialization is essential. Additionally, modern storage systems benefit from flattening the I/O tree to achieve faster performance.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0580ebd4-954b-4a92-be7e-4ec80d8350a9.webp)

若您仔细查看右上角所示的查询语句——`SELECT id, timestamp, lidar_cloud FROM dataset WHERE velocity > 10 AND tag = 'error' LIMIT 10 OFFSET 100`——这是自动驾驶开发等领域常见的查询模式。





If you examine a query such as the one shown in the top right—`SELECT id, timestamp, lidar_cloud FROM dataset WHERE velocity > 10 AND tag = 'error' LIMIT 10 OFFSET 100`—this is a common query pattern in domains like autonomous vehicle development.  


The typical OLAP execution plan for this query begins by scanning all predicate and projection columns, applying the filter conditions on `velocity` and `tag`, then applying the `LIMIT` and `OFFSET`, and finally projecting only the selected columns. However, a significant inefficiency arises because **LIDAR point clouds** can be extremely large. Scanning the `lidar_cloud` column early in the process may result in reading 10 to 100 times more data than necessary, depending on filter selectivity.  


To address this, LanceDB implements **late materialization**: we first scan only the predicate columns (`velocity` and `tag`), deferring the projection of `lidar_cloud` until the final step. This optimization relies on the data format supporting fast random access, as the `TAKE` operation at the end requires accessing random row IDs across the dataset.  


This approach provides a substantial performance advantage over traditional columnar formats like **Parquet** or **ORC**, which lack support for late materialization—a limitation rooted in their decades-old column-store design. Not all systems implement this optimization, but it is a key reason for LanceDB's efficiency in handling large blobs and analytical workloads.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/965d27d7-4a6f-48bc-9762-5d4a70f9e1d9.webp)




The second aspect is that nowadays, data is typically stored on modern **NVMe drives** or **object storage systems**. NVMe drives feature deep I/O queues, while object storage supports high levels of parallelism.  


Our goal is to flatten the I/O tree, minimizing dependencies between I/O calls and issuing a large number of parallel I/O requests. This approach optimizes end-to-end performance for operations such as **vector search**.  


These two elements are key to achieving high performance in **LanceDB**.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cf7f1322-c01c-4089-9ae2-a6e29cb22647.webp)


And now, I would like to discuss two **key features** that make LanceDB more interesting and useful. The first is its **data layout**.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/b6e9e9d0-6d1d-42ce-8203-8d75b143a874.webp)




The **Lance directory** is structured as follows. The directory serves as the table format, containing Lance files within the data subdirectory. These files represent all partitions in your dataset.  


A `latest.manifest` file points to the most recent version, while all previous versions are stored in these manifests. Additionally, there is a **deletion file** to support soft deletes and similar operations.  


For each version, a **manifest file** can reference index files and multiple logical fragments. Each fragment may consist of one or more actual data files, accompanied by its own deletion file.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/8f20119f-848b-4b80-8b38-1a9c68189b6e.webp)


This enables functionalities similar to **Iceberg**, such as appending to columnar data and schema evolution. These features are stored directly with the table.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/0463c0cd-9c7e-41d5-b418-f25cdd4a8116.webp)




This also enables **fast time travel**, which is crucial for machine learning. It allows appending data and adding or removing columns without copying the original dataset, while retaining the ability to revert to previous versions. Given the popularity of **Iceberg**, this feature is important even for tabular data, but it is even more valuable for machine learning due to the size of datasets.  


For instance, with a petabyte of images, copying the entire dataset to add a column or roll back changes would be impractical.  


In **Lance format**, this capability also supports row-level deletes and updates. A feature currently on the roadmap for implementation in the second half of next year is a **write-ahead log**, which will facilitate real-time updates for both data and indices.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/2c8dbedc-1a10-4cbc-8d37-97546aef83bc.webp)




This is a simplified visualization of schema evolution. On the bottom right, you see **V1**, where columns **C1** and **C2** were written into the dataset in the first version, split into three fragments: **F1**, **F2**, and **F3**.  


In the second version, column **C3** is added, represented by the orange or yellow files. Only the new column needs to be written, and the new manifest version will reference both the new and old files.  


The same applies to version three, where a column is added and another is dropped. **Notably**, the old data never needs to be copied. If a rollback is required, the dropped column C3 remains intact.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/55b0b430-249b-4ff6-a73c-eca8b0b5eb7a.webp)





Before moving on to the final section on indices, let me check if there are any quick questions. It seems we're good to proceed.  


**Parquet had mechanisms to extend support for indices**, but these didn't gain much traction. Initially, we attempted to build secondary indices with Parquet, but due to its limitations, the performance gains didn't justify the effort. This was a **key reason behind our design approach for Lance**. By integrating indices directly into the file format, we achieved significantly better results.  


In machine learning, the **first index we developed for users was the ANN search index**, which is extensible to other index types. Currently, we're working on scalar indices to enable fast filtering, complementing the ANN search functionality. This extensibility is one of the interesting aspects of our approach.  


You've likely already encountered the fundamentals of vector search.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/133a2f3e-210f-48f2-a80f-08ad459126ba.webp)






The **key difference** with Lance is its index structure. As shown in the bottom right diagram, which represents our vector space index, the index contains pointers to actual row IDs in the dataset. This enables flexible column selection when performing searches.  


Lance's **vector index** is disk-backed, addressing current limitations in vector databases where indices are typically memory-resident. This disk-backed approach also facilitates separation of compute and storage. While Lance implements similar vector algorithms, it optimizes them for disk rather than memory.  


This architecture supports not only vector search but also integrates **full-text search**, **SQL queries**, and scalar indices. For NVMe storage implementation, careful consideration was given to data layout and contiguous storage to maintain performance comparable to memory-backed indices. Parallel I/O and optimized data access patterns were crucial, though the core algorithms like IVF and PQ remained unchanged.  


**HNSW implementation** proved challenging for disk-backed systems, though we've developed a disk-based graph index called disk NN as an alternative.  


Building upon this foundation, we're developing what we term <strong>"NCB"</strong> for free AI retrieval, expanding beyond conventional vector database capabilities.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/8705ed9c-fdc4-4abc-9a12-c10654b055ad.webp)





This approach differs slightly as it runs in-process, eliminating the need to manage servers. Installation is straightforward with `pip install`, similar to SQLite or DuckDB. It is **lightweight** yet powerful, capable of searching a billion vectors in milliseconds on a laptop, provided there is sufficient hard drive space. Consequently, scaling costs are at least an order of magnitude lower. The **columnar format** backing also enhances flexibility, enabling vector search, keyword search, and OLAP queries.  


Regarding performance, the system operates at disk speed, not relying on in-memory vectors. A **caching mechanism** exists where parts of the index, such as certain partitions, are cached and evicted based on memory pressure rules, keeping memory usage low during searches.  


Partitions refer to divisions in vector space, not physical dataset partitions like in Parquet. The index is stored with an index block for each cluster in the vector space, without requiring data rewriting in the Lance format.  


To summarize, this system offers a **cost-effective**, high-performance solution for large-scale vector search with minimal operational overhead.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/69d5fbe0-9e2a-43a2-950e-42f39fe7f601.webp)



Hopefully, the font size is readable for everyone. Let's assume I have installed **LanceDB** and connected to a local file directory as my database. I have a table containing 1 billion vectors.  


If I perform a search by generating a random vector in a loop and request the top 10 most similar vectors, the execution time is approximately **three milliseconds** per search over the billion vectors, with minimal standard deviation. In this scenario, the data likely remained in the file system cache without accessing the disk.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/fcf8e4b7-c7e6-4c26-b464-7b72fe041c50.webp)


What do you mean in the test you just ran?






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/562d8dba-7064-462b-aedb-92e1eff62adc.webp)




At that time, the data is likely being served from the **OS cache layer**. We can perform a single query. There is some caching involved. For instance, if we measure the time, it typically executes once.  


The initial read involves loading the **core index** and **centroids** from memory. This scenario represents a **cold start**. However, the amount of data that needs to be cached in memory is relatively small.  


When running the query for the first time, it accesses the disk to read the index and certain partitions.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/b25ff2f0-9a12-4a20-ba27-f7544b037795.webp)




The first time, the **cold start** is substantially slower, but subsequently, it becomes much faster. This issue also relates to the cold start problem of caching data in memory.  


Thank you.  


Alright.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/44d94e40-d5a9-42c1-b215-d9352bbbdf8a.webp)







Regarding the roadmap for the data format, we are currently focusing on **partition pruning** and **statistics-based pruning**. Currently, you can use DuckDB with Lance or the Lance data format with DuckDB. However, some predicate evaluations remain slower compared to Parquet or Delta due to pushdown limitations.  


With these improvements, we expect significantly faster predicate evaluation performance across the board. We will also enhance **null support**, which is currently available for the binary encoder but not yet for the fixed-width encoder. **Advanced encodings**, such as RLE and variable encoders, are under consideration, along with time-series use cases leveraging Delta-Delta or Gorilla compression.  


We are actively developing **scalar indices** and exploring future enhancements like **data compression techniques** such as FSST, which can both compress data and support fast lookups. **Deeper ecosystem integration** is another priority, including native Spark data sources and improved compatibility with Arrow, Pandas, and DuckDB for seamless Lance dataset interaction.  


Lastly, Lance is a team effort. Special thanks to Lei Xu, my co-founder and primary designer of the Lance format, as well as Will Jones, Weston Pace, Rok Mihevc, and Rob Meng for their invaluable contributions over the past quarter. We also appreciate the many community contributors—without them, the Lance format would not be possible.  


That concludes the talk.






![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/defd029a-a1b7-4082-bf7b-3b1411199eb9.webp)








I hope you found this session interesting and that it covered topics you haven't already explored. We would appreciate your feedback on the format. You can find us on **GitHub** at github.com/lancedb/lance. If you're interested in the **vector database**, it's open source at github.com/lancedb/lancedb. We've also compiled a repository of examples called vectordb-recipes, where you can build applications like chatbots, multimodal search, and document search.  


To connect with us, follow LanceDB on Twitter and LinkedIn, or join our **Discord** for live support as you experiment with Lance.  


Now, let’s open the floor for questions.  

**Q:** You've targeted both SQL and vector databases. Do you see application scenarios that challenge both simultaneously? What are the main pain points you've observed?

**A (Chang She):** Great question. When we talk about “pain points,” the biggest one is toolchain complexity. For example, frameworks like LlamaIndex and LangChain now combine multiple retrieval methods—vector search, full-text search, and SQL—often querying multiple data stores, handling routing, and result synchronization. This is quite involved.

The advantage of LanceDB is that we unify all retrieval into a single store. You don’t have to distinguish or manage multiple connections, or parse different query types. Just send the query to LanceDB, and everything is handled in one place, greatly simplifying the process.

Having data and metadata co-located with vectors or indices also makes subsequent access and serving much easier—these are the key challenges and solutions.

---

**Q:** Iterating on a dataset often involves branching and merging, as in modern tools. Does Lance support this?

**A (Chang She):** Our versioning system makes branching straightforward—it's already supported. Merging is less common, but branching and version management are available in Lance.

---

**Q:** In the chat, someone asked: what motivated the rewrite in Rust, and how did it go?

**A (Chang She):** The primary motivation was improved productivity. Originally, Lance was written in C++. During a hackathon project to demo query capabilities, we switched and rewrote about 10% of the read path in Rust, which turned out much faster and more efficient. Rust also improved our confidence in shipping quickly and safely—unlike in C++, where we were more worried about security.

---

**Q:** What encoding scheme do you use for metadata? ORC uses Thrift, Parquet uses Protobuf. Any differences?

**A (Chang She):** We use **Protobuf**.

For initial simplicity and to support schema evolution, our approach makes it easy to iterate on dataset formats without breaking backwards compatibility.

---

**Q:** How about supporting image sketches—like low-resolution versions for quick filtering?

**A (Chang She):** Currently, that’s not supported, but it’s planned after we add **semantic type support** to the Lance format.

---

**Q:** For fixed-length data, how do you handle summarization/statistics?

**A (Chang She):** We generate zone maps—such as min/max summaries—for columns. This is ongoing work, and will be stored at the page level within fragments. Fragment and column metadata can be stored externally, which is especially beneficial for efficient scans in object storage scenarios.

---

**Q:** Why store vector indices together with the data?

**A (Chang She):** The key reason is versioning consistency. If a dataset is overwritten, its index is invalidated, but it can always be regenerated—this way, data and index can roll back together to a consistent state. From an engineering viewpoint, keeping everything in one directory makes things simpler.


Bringing together data and indices streamlines use for query engines and users. Many ML engineers struggle with indexes separated from data, creating sync issues and pipeline fragility. Unifying them enhances ease of use and reliability.

---

**Q:** Finally, what’s the big vision for Lance in five years?

**A (Chang She):** I hope Lance becomes a vital standard for managing **multimodal data**—images, point clouds, videos, or combinations of tabular, vector, and AI datasets. I want users to naturally reach for Lance because it’s easy, tightly integrated, and seamless. Ideally, Lance will be an **open-source standard**—possibly replacing Parquet and ORC—especially as data becomes more than just tables.

For the business, we’re developing a hosted cloud vector DB service. There are also commercial opportunities in computation, training, and visualization tools built on this foundation.

