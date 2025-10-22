---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 11: Large-Scale Distributed Training"
date: 2025-09-10T17:50:34+08:00
draft: true
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image1.png)
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image2.png)

Welcome back to **CS231N** Lecture 11. Today we will explore the exciting topic of **large-scale distributed training**, which underpins the training practices of modern neural networks in startups, industry, and academia.

Compared to when this course was first offered a decade ago, large-scale training has become the new standard in deep learning, and this transformation is significant.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image3.png)

A decade ago, training models on a single **GPU** was common practice. However, the current standard practice is to train in parallel on dozens, hundreds, or even thousands of devices. This transformation has given rise to the need for new **algorithms** and methodologies.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image4.png)

In today's class, we will use **Llama3-405B** as a case study throughout. It's not chosen because it's the best or most interesting model, but because as a model close to the cutting edge, it publicly shares implementation details such as training processes and architectural design.

In recent years, organizations like Google, OpenAI, and Anthropic have developed many powerful models, but most no longer disclose technical details. A landmark turning point was the **GPT-4 technical report** released in 2023, where OpenAI explicitly stated:

> "Given both the competitive landscape and the safety implications of large-scale models like GPT-4, this report contains no details about the architecture (including model size), hardware, compute budget, dataset construction, training method, or similar."

This has become the norm for technical disclosure of large-scale models after GPT-4.

The unique value of **Llama3** lies in its openness. This large language model trained by Meta was open-sourced in April 2024, with its paper detailing the model training and system infrastructure (though with less information about datasets), providing a precious window into understanding how contemporary large language models are trained.

In April 2025, Meta released the slightly improved **Llama4**, but no technical paper has been published yet. I look forward to learning about the training secrets of the new generation Llama through subsequent papers.

Today's class will mainly revolve around Llama3-405B, focusing on two major themes:



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image5.png)

This lecture covers two major themes: **GPU hardware** and **large-scale distributed training**. First, we will explore the underlying hardware architecture that executes these computations, then explain the algorithms needed for training across multiple GPUs.

The course begins with an overview of **GPU hardware**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image6.png)

**GPUs** (Graphics Processing Units) were originally developed as specialized coprocessors for computer graphics. It turns out that these units are extremely efficient as general-purpose parallel processors. It's particularly fitting to give this lecture in the Jensen Huang Auditorium—named after **Jensen Huang**, CEO and founder of NVIDIA. Over the past few decades, NVIDIA has been the leading company in GPU production for gaming and machine learning.

Although initially designed for graphics processing, GPUs excel at parallel computation. Computer graphics requires massive parallel processing to generate countless pixels and handle basic geometric shapes. Researchers in the early 2000s discovered that these graphics cards could be repurposed for general parallel computation. By the late 2000s to early 2010s, NVIDIA improved and promoted GPUs as general-purpose parallel processors, foreseeing their broader application prospects.

NVIDIA recognized the potential of **deep learning** early on and invested heavily in optimizing hardware architecture. For over a decade, GPUs have remained the primary tool for large-scale deep learning training. Although alternatives are emerging, NVIDIA chips still dominate.

The most advanced **NVIDIA H100 GPU** for current deep learning training is configured with 80GB of high-bandwidth memory (**HBM**) around its compute cores. Data is transferred between memory and cores through internal buses for efficient processing. Although newer generation GPUs have been released, they haven't been widely adopted yet.



It achieves this at approximately **three terabytes per second**, demonstrating extremely high data transfer rates.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image7.png)

Now, let's examine the **GPU cores** more closely. We can see a smaller memory component at the core—about 50MB of L2 cache. Although much smaller than the 80GB HBM memory, this cache is closer to the compute units and enables faster access.

The GPU core consists of 132 streaming multiprocessors (SMs), which are equivalent to independent parallel cores. In some aspects (especially parallel processing capability), these SMs are more powerful than ordinary CPU cores, but weaker in others, such as slower clock speeds and limited instruction and branch prediction capabilities. While direct comparison between GPU and CPU cores is difficult, we can roughly consider one SM as equivalent to one CPU core.

You might notice that the diagram shows 144 units rather than the mentioned 132. This difference stems from the **binning mechanism** in GPU manufacturing. Given the complexity and transistor density of chips, perfect yield cannot be achieved. Manufacturers design chips with 144 units reserved, expecting at least 132 to function properly. This strategy allows manufacturers to sell a higher proportion of output chips by only guaranteeing 132 active units.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image8.png)

Let's examine the internal structure of streaming multiprocessors in more detail to gain deeper understanding of GPU architecture. This specific unit represents one of the 132 active streaming multiprocessors in the NVIDIA H100 GPU. Several **key components** are worth noting:

First, we see 256KB of L1 data cache and shared memory, as well as register files. This highlights the **core role** of memory hierarchy in GPU architecture. Although this course focuses on deep learning, it's worth noting that computer architecture fundamentals are equally important.

Memory hierarchy is particularly crucial for deep learning and high-performance computing applications. Its **basic principle** follows a consistent pattern: high-capacity memory is farther from compute cores, while smaller and faster memory is closer to compute units.

For engineers developing low-level algorithms, understanding this memory hierarchy is **crucial**. Efficient data transfer between different memory levels will significantly affect performance optimization results.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image9.png)

When writing performance-optimized GPU kernels, developers need to invest significant effort in optimization. Taking **H100** as an example, its memory architecture is divided into three levels: 256 KB L1 cache, 50 MB L2 cache, and 80 GB high-bandwidth memory (HBM).

The chip is also equipped with **128 FP32 cores**, each capable of executing general-purpose floating-point operations. Specifically, a single core can complete \\(AX + B\\) operations (where \\(A\\), \\(X\\), and \\(B\\) are scalars) in each clock cycle. With the parallel capability of 128 cores, each streaming multiprocessor (SM) can complete **256 floating-point operations** per clock cycle.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image10.png)

We've highlighted in red where the **true computational power** lies. Beyond FP32 cores, there are four tensor cores—though the name is somewhat misleading, they are essentially matrix operation units. Each tensor core contains specialized circuits dedicated to matrix multiplication.

Specifically, in NVIDIA H100, each tensor core can execute one matrix operation per clock cycle, such as multiplying a 16x4 matrix \\(A\\) with a 4x8 matrix \\(X\\) and adding a 16x8 bias matrix \\(B\\), essentially computing \\(AX + B\\) for fixed-size matrix blocks.

This operation involves **1024 floating-point operations** per tensor core per clock cycle (each multiply-add counts as one operation). Each SM (streaming multiprocessor) is equipped with four tensor cores, achieving a total throughput of **4096 floating-point operations** per SM per clock cycle, far exceeding the 256 operations capability of FP32 cores.

**Tensor cores** are the primary source of device computational throughput. To fully unleash GPU potential, code must be optimized to utilize these tensor cores.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image11.png)

Tensor cores use mixed-precision computation rather than traditional 32-bit floating-point calculation. They typically use **16-bit input data** (though there are various 16-bit formats, we won't delve into them today). Multiplication operations are executed at lower 16-bit precision, while accumulation operations are completed at higher 32-bit precision. These core processors receive 16-bit input, perform intermediate calculations, and finally output 32-bit results.

This distinction is **crucial**—because in the PyTorch framework, if models are not converted to 16-bit precision, the system will default to calling floating-point cores for computation, causing a 20x performance drop. Although seemingly a subtle technical difference, when PyTorch code has improper data type management, it will have significant practical impact.

Over the past decade, GPU performance has achieved astonishing leaps, with computational speed showing exponential growth.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image12.png)

When I started my PhD and began researching **deep learning**, the cutting-edge GPU we used was the K40 released in 2013. This device's FP32 computational capability for the entire GPU was only five trillion floating-point operations per second.

The chart clearly shows this evolution. The horizontal axis represents the time span from 2013 to the present; the vertical axis indicates peak computational power per device in trillions of floating-point operations per second per device. Although the growth curve is extremely steep, the **key turning point** occurred in the transition from K40 to P100, and the revolutionary V100 that emerged at the end of my PhD career in 2016-2017.

**V100** was the first GPU equipped with **tensor cores**. Subsequent devices continued to advance this innovation by integrating more and larger tensor cores, continuously increasing the proportion of such specialized compute units in GPU chip area. Over the past 10 to 15 years, this architectural evolution has driven astonishing computational growth.

The newly released **B200** is gradually being deployed. Theoretically, its FP32 computational performance can reach approximately 83.3 trillion floating-point operations per second, while tensor core mixed-precision computational capability reaches 5,000 trillion per second.

Looking at the big picture, single-device computational power has achieved **thousand-fold growth** over the past 12 years. This exponential increase in computational resources is one of the core driving forces behind the rapid advancement of artificial intelligence over the past decade.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image13.png)

When a technology achieves thousand-fold improvement, it deserves attention because this progress will profoundly change our technological capabilities. **This thousand-fold leap** is the core driving force behind breakthroughs in deep learning over the past decade.

Taking computational capability as an example: modern GPUs don't have 5,000 tensor cores, but achieve 5,000 trillion floating-point operations capability on tensor cores. We must clearly distinguish between the computational differences of tensor cores and FP32 cores.

**This scale of progress** is astonishing. Today's palm-sized devices—with volume and weight equivalent to the K40 from 12 years ago—can provide thousand-fold performance compared to that era.

But the story is far from over. Training models on single GPUs was the norm in 2013, while today's models require thousands, tens of thousands, or even hundreds of thousands of GPUs working together. This combination of **distributed training capability** with thousand-fold single-device throughput improvement demonstrates the extraordinary progress achieved over the past decade.

We've delved into the internal architecture of GPUs to understand the essence of these technological advances.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image14.png)

Now, let's zoom out and place **GPUs** in a broader context—from single devices to modern GPU cluster architectures integrating multiple components.

Previously, we analyzed a single NVIDIA H100 GPU, which can be viewed as another level of memory hierarchy. Within H100, we observed a three-layer memory architecture with different bandwidths varying with distance from compute units: the farther from compute units, the lower the **memory bandwidth** (the device's ability to transfer data between system components). This pattern holds true in complete configurations at the data center level.

A single H100 GPU can achieve approximately 3TB/second memory bandwidth, enabling efficient data transfer between its high-bandwidth memory (HBM) and compute units. But in practice, these GPUs are typically deployed within larger GPU server infrastructure.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image15.png)

Most GPU servers adopt single-machine eight-card configurations, enabling interconnection between devices. The typical **communication bandwidth** between any two GPU cards within a server is about 900GB/second, reduced by two-thirds compared to single-card internal communication bandwidth. In this context, we introduce **Llama 3** for illustration.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image16.png)

Major industry players typically don't reveal detailed specifications of their training clusters. However, the **Llama 3 Technical Report** provides comprehensive disclosure of its infrastructure information. Although specific configurations of different clusters may vary, the following details apply to the Llama 3 training cluster:

Each **GPU chassis** contains 8 GPUs. Two such chassis are installed in a server rack, with rack height about six feet—for easy visualization, comparable to human height. This configuration gives each rack 16 GPUs. Multiple racks connected together form a **GPU compute pod**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image17.png)

The **Llama 3 cluster** consists of multiple GPU pods, each containing 192 racks, totaling 3,072 GPUs. These pods use **high-bandwidth interconnect technology** to connect racks, enabling communication speeds of approximately 50 GB/second between any two GPUs within the same pod.

Compared to communication within a single server, this achieves a **20x reduction in memory traffic**. Although 3,072 GPUs provide powerful computational capability, it's still insufficient. Therefore, these GPU pods are further integrated into a complete GPU cluster.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image18.png)

This is the complete **GPU cluster** system Meta built for training Llama 3 models. This architecture integrates eight GPU compute pods, totaling 24,576 GPU chips.

Although specific **memory bandwidth** parameters haven't been disclosed, transfer rates between components must be lower than 50GB/second. Notably, this is far from the world's largest GPU cluster—it's only the largest deployment case among currently disclosed technical parameters.

Globally deployed similar systems can reach configurations of 50,000 to 100,000 GPUs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image19.png)

These models do exist, and people train them using scalable methods. This system achieves natural horizontal scaling by clustering more compute pod groups into larger clusters, or by introducing higher-level super-pod interconnect architectures.

Regarding training duration for such GPU clusters, although I can't remember the specific training cycle for Llama 3 models, the **rule of thumb** over the past decade is: the most time-consuming training typically lasts several months. This duration is more constrained by practical limitations of project planning and team collaboration rather than technical limitations. Current state-of-the-art ultra-large models (such as GPT-4.5 or GPT-5) may require nearly a year of training, though most large-scale training still maintains around two months.

The practice of organizing servers into racks rather than pods stems from physical limitations. Racks have been standard configurations in data centers for decades. Since GPUs are larger and consume more power, data centers cannot be redesigned overnight, so racks remain standard units, maintaining unified hardware dimensions and layout specifications.

A single server rack is about six to eight feet (1.8-2.4 meters) tall, equivalent to podium size, similar to my height. A standard compute pod typically contains 192 such racks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image20.png)

Imagine 200 such cabinets. Now multiply this number by eight—this is still slightly underestimated, as they're usually arranged in rows with aisles left. Besides computer racks storing **GPU servers**, additional network hardware racks are needed to enable data transfer between devices. Dedicated storage racks are also essential for preserving training data.

These clusters occupy enormous space. In terms of performance, small compute units within large clusters can still maintain high throughput. **This is the core design challenge**: utilize fast communication when possible, while gracefully handling slow communication in large-scale scenarios.

Thermal management is another **key factor**. A single high-end gaming GPU (like 4090 or 5090) can noticeably raise room temperature. When scaling to tens of thousands of GPUs in data centers, advanced cooling solutions far beyond ordinary desktop air or water cooling are needed.

The transition to large GPU clusters shifts focus from individual devices to overall infrastructure. These GPUs are carefully assembled physical hardware components in data centers—not just abstract entities in the cloud.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image21.png)

I envision the entire data center as a single giant computer. This system contains **24,000 GPUs**, 1.8 petabytes of HBM memory, 415 million FP32 cores, and 13 million tensor cores. Its comprehensive computational capability reaches **24 exaflops per second**, equivalent to \\(24 \times 10^{18}\\) operations. Although this represents considerable computational power today, it will likely seem insignificant in five years—this development speed is even more astonishing.

Our goal is to treat this cluster of 24,000 GPUs as a **unified supercomputer**. The core challenge lies in training a single giant neural network continuously for months, enabling it to process massive data and achieve unprecedented performance. This approach reflects the **paradigm shift** in current deep learning.

In terms of hardware, although I mainly mention **NVIDIA GPUs** (due to their current dominance in training architectures), alternatives are emerging. Google's training hardware is currently NVIDIA's most important competitor.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image22.png)

Google developed specialized hardware called Tensor Processing Units (TPUs), currently iterated to the sixth generation. The currently rentable TPU v5p through Google Cloud has performance metrics in the same order of magnitude as the H100 we discussed earlier. TPU architecture adopts many innovations fundamentally different from GPUs, though we don't have time to delve into these details today.

In terms of physical scale, TPUs are deployed in **Pods**, similar to GPUs. TPU v5p supports Pod configurations with up to 8,960 chips. For reference, this image shows a TPU v2 Pod containing 256 chips, composed of four server racks slightly taller than human height. The new generation Pods accommodating nearly 9,000 chips represent significant scale improvement. Google's **Gemini models** were almost certainly trained on these TPU systems.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image23.png)

Of course, they won't disclose this information, but I would be very surprised if Google's large-scale models weren't trained on **TPUs**, because TPUs are extremely excellent hardware. These models show strong competitiveness, precisely proving TPU training efficiency.

The key difference from **NVIDIA** lies in accessibility—TPUs are only available to Google employees or through Google Cloud rental. Although TPUs are widely used, they currently have slightly lower popularity than NVIDIA GPUs.

Many companies have realized the importance of training hardware and are developing competitive alternatives. Currently, NVIDIA and TPUs dominate in usability, performance, and market share, while **AMD** as the second-largest GPU manufacturer is also a competitor not to be ignored.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image24.png)

They also launched a training accelerator called **AMD MI325X**. On paper, its specifications are quite competitive with H100, but it hasn't reached the same level of market penetration yet.

AWS developed its own training chip **Trainium2**. Although I haven't used it personally, I know Anthropic uses it for some training tasks, though the actual usage ratio compared to GPUs remains unclear.

Currently **NVIDIA GPUs** dominate the market, while Google TPUs perform excellently but have relatively limited application scope.

The above is the first part about GPUs and their cluster configurations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image25.png)

To illustrate the scale of machines we build and train, the **second question** explores how we design algorithms that can fully utilize the massive computational resources composed of tens of thousands of **GPU clusters**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image26.png)

Developing new algorithms and innovative computational methods is crucial. We must rethink how to parallelize and partition neural networks. The **core strategy** lies in splitting computational tasks across large-scale parallel devices. These systems contain numerous GPU and CPU cores, with all compute units running independently and maintaining only limited interconnection.

From a macro perspective, computers mainly perform two functions: **computation** (processing input bits to generate output bits) and **communication** (transferring data between storage locations). The key challenge lies in how to effectively utilize the entire cluster's memory hierarchy, allocating workloads while achieving overlapping execution of communication and computation.

The **ultimate goal** is to achieve parallel computation where, during large neural network training, all available resources—potentially involving tens of thousands of GPUs and millions of compute units—can continuously maintain efficient operation. This requires coordinating their parallel operations while facilitating necessary communication to collaboratively train ultra-large-scale neural networks.

Currently, five parallel strategies are mainly adopted in large-scale neural network training (especially Transformer architectures). **Transformer models** consist of L layers, with each layer processing three-dimensional tensors where one dimension represents mini-batch sample size.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image27.png)

Transformer models process three-dimensional tensors composed of sequences in mini-batch data, where each token is represented as a vector with specific dimensions. These tensors are processed through a series of layers, providing four parallelization axes:

1. Pipeline Parallel (PP): Parallelization along the layer axis.
2. Data Parallel (DP): Parallelization along the batch dimension.
3. Context Parallel (CP): Parallelization along the sequence dimension.
4. Tensor Parallel (TP): Parallelization along the feature dimension.

Each method represents different strategies for distributing computation along these axes in Transformer architectures. We will explore each method in detail, as they involve sophisticated mechanisms in large-scale distributed training.

First, let's discuss Data Parallel (DP). Its core concept is very intuitive: during neural network training, we process mini-batch sample data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image28.png)

In typical neural network training, we process a mini-batch of elements and calculate loss for each entry based on training objectives. Gradients are usually the average of individual gradients for each element in the mini-batch. Since loss and gradient calculations are independent between mini-batch elements, this process is **inherently parallelizable**.

The core concept is: if a single GPU can handle a mini-batch of size \\(n\\), and we have \\(m\\) GPUs, we can train with a larger batch of \\(m \times n\\) samples. This macro-batch is divided into \\(m\\) smaller batches of size \\(n\\), processed on independent GPUs.

From a mathematical perspective, this method is effective because gradients have linear properties. Assuming scalar loss \\(L\\) is the average of individual losses calculated from all elements \\(X_{i,j}\\) in the macro-batch, \\(W\\) represents the network's weight matrix. Due to the **linear nature of gradients**, the gradient of loss with respect to weights can be decomposed, allowing us to rearrange operation order (summation, gradient calculation, and averaging).

The specific calculation process can be expressed as:
1. The inner term represents standard forward-backward propagation for \\(n\\) elements, which can be computed in parallel on different GPUs;
2. The outer summation term represents averaging gradients across all \\(m\\) devices.

This mathematical formulation is equivalent to training on a single large GPU, because we're just rearranging operation order without introducing any approximation. From the GPU's perspective, this is equivalent to distributing workload across \\(m\\) GPUs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image29.png)

Due to slide space limitations, we use \\(m=3\\) as an example here, but in practice this value is usually much larger. Each **GPU** maintains independent copies of neural network weights, optimizer states, and gradients.

Each GPU loads different **mini-batch** data in parallel. In this example, each GPU processes a mini-batch containing 3 elements. It's essential to ensure different GPUs load different mini-batch data.

A common coding error—which has occurred in both my own and students' implementations—is accidentally letting all GPUs load identical mini-batches. This error destroys the advantages of **distributed training** and must be avoided. Ensuring each GPU processes unique mini-batch data is crucial for achieving efficient parallel processing.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image30.png)

Each GPU independently executes forward propagation on its own mini-batch data to calculate local loss. This process runs completely independently without any inter-GPU communication. Subsequently, each network performs backward propagation, calculating gradients of local loss with respect to model weights. Since each GPU maintains independent copies of **model weights**, these operations can proceed in parallel without synchronization.

However, after backward propagation, synchronization becomes necessary. To calculate the **average gradient** of all participating devices, an all-reduce operation must be performed. In this step, each GPU sends its gradients to all other GPUs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image31.png)

Two processes occur simultaneously here. **First**, each GPU must broadcast its own gradients to all other GPUs. **Second**, each GPU must collect gradients from all GPUs participating in the training process. This constitutes an all-reduce operation, whose completion time is typically proportional to the logarithm of the number of GPUs.

When the all-reduce operation completes, each GPU possesses the averaged version of gradients from all devices. At this point, communication ends, and each GPU holds a completely identical copy of all-reduced gradients.

Initially, each GPU held an independent copy of model weights. Now, each GPU maintains gradients calculated on the entire macro-batch—these gradient copies, though independently stored, are completely identical in content.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image32.png)

At this stage, each GPU can independently update its local weight copy. Since they start from identical weights and apply identical gradients, under deterministic arithmetic, locally updated weights will remain synchronized.

**The key point** is that steps four and five can be executed in parallel. There are two concurrent processes here:
1. Backward propagation process: each GPU calculates gradients through its own backward propagation
2. Gradient communication across GPUs

In practice, these operations typically overlap. Each model starts backward propagation from the last layer, immediately processing the second-to-last layer after calculating local gradients. When GPUs are calculating backward propagation for layer L, they simultaneously execute **all-reduce operations** for gradients of layer L+1. This pipeline design ensures that when backward propagation completes, gradients have been aggregated on all devices, enabling delay-free weight updates.

This optimization is **crucial** because communication overhead is very significant. The core challenge lies in masking communication costs through overlapping computation and communication. Whether step four or five becomes the bottleneck depends entirely on hardware specifications: device speed, model size, mini-batch dimensions, and interconnect bandwidth. In large-scale distributed training, performance is highly dependent on specific environments and requires empirical benchmarking.

Regarding **asynchronous methods**: early asynchronous SGD algorithms once implemented each replica executing M independent gradient steps. This method, adopted by organizations like Google in pre-TPU era networks (early 2010s), required multiple replicas to execute independent steps followed by periodic averaging. But practice proved this method had poor stability, difficulty in debugging/reproduction, and overall inferior performance compared to synchronous methods.



Synchronous gradient updates have advantages in debugging and understanding algorithms, as their implementation is usually more intuitive. However, asynchronous stochastic gradient descent (SGD) methods may resurge in the future due to their compatibility with large-scale distributed training systems. In distributed environments, there's no central coordinator, with each device running independently without global schedulers.

Regarding overlapping communication and computation, this must be explicitly handled by software, as hardware lacks intelligence for automatic management of such scheduling. Fortunately, frameworks like **PyTorch** provide built-in solutions (such as the `DistributedDataParallel` class), simplifying this process for common use cases.

There's an interesting asymmetry between device-level parallelism and cluster-level parallelism. On a single GPU, asynchronous data transfer is usually automatically managed by hardware (especially when using NVIDIA's GPU programming language **CUDA**); while cluster-level parallelism usually requires explicit software coordination.

These systems are heterogeneous, with different components written in various programming languages. Low-level GPU kernels are typically implemented in CUDA, while higher-level C++ and Python wrappers (such as interfaces in PyTorch) provide developers with more user-friendly ways to interact with kernels. This layered design ensures both efficient GPU execution and developer usability.



In this diagram, each **GPU** independently calculates its own gradients (shown in black), while gradients highlighted in red are calculated through parallel all-reduce operations across all GPUs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image33.png)

**Backward propagation** depends on gradients from previous layers at lower levels. However, each GPU independently executes backward propagation calculations on its local mini-batch data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image34.png)

At each layer, two gradient variants need to be considered. **Local gradients** represent derivatives of mini-batch loss with respect to network weights, while **global gradients** are derivatives of macro-batch loss with respect to weights.

Each GPU only uses its local upstream gradients to calculate backward propagation, but determining global upstream gradients requires communication.

This method is called **data parallel**, an early approach for parallelizing GPU computation in neural network training. However, it quickly encountered limitations in model scale.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image35.png)

What needs to be remembered here is that each GPU maintains independent copies of model parameters, which creates a **bottleneck** when scaling to ultra-large-scale models. Specifically, each weight in neural networks needs to track four values: the weight itself, its gradient, and optimizer states. When using Adam optimizer, \\(\beta_1\\) and \\(\beta_2\\) are usually recorded for each parameter, sometimes including exponential moving averages of model parameters. Therefore, each weight in the network typically needs to track four to five scalar values.

When using current mainstream 16-bit precision training, each value occupies 2 bytes. This means storing necessary information requires 8 bytes of GPU memory per scalar. By this calculation, 1 billion model parameters would consume approximately 8GB of GPU memory. Taking H100 GPU with 80GB memory as an example, the maximum model scale trainable under this limitation would be about 10 billion parameters.

But this capacity still cannot meet demand. Our goal is to break through GPU memory limitations and train larger models. The **solution** is clear: model weights must be split across multiple GPUs. Besides distributed processing of data batches, model weights will also be distributed, and this variant of data parallel is called fully sharded mode.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image36.png)

Fully Sharded Data Parallel (FSDP) is conceptually straightforward. Each weight parameter \\(W_i\\) in the network is assigned to one of the \\(M\\) GPUs used for training. This master GPU is responsible for managing global gradients and optimizer states for its assigned weights. Typically, weights are partitioned by neural network layers (rather than individual scalars), where \\(W\\) represents the weight matrix of an entire neural network layer.

In the example, a four-layer network is distributed across two GPUs: weights \\(W_1\\) and \\(W_2\\) are held by GPU1, \\(W_3\\) and \\(W_4\\) are held by GPU2. At the beginning of each training batch, model weights are distributed among GPUs in this manner. Despite this distribution, the **core principle of data parallel** still applies: each GPU processes independent data batches, calculates local gradients through forward and backward propagation, then aggregates gradients to execute gradient updates.

But sharded weights introduce additional communication complexity. At the beginning of forward propagation, the GPU holding the first layer weight matrix (such as GPU1 holding \\(W_1\\)) broadcasts it to all other GPUs. When all GPUs obtain copies of \\(W_1\\), they execute forward computation for the first layer. Subsequently, non-master GPUs delete their local \\(W_1\\) copies to save memory. This process repeats for subsequent layers—when computation proceeds, the master GPU broadcasts the next layer weights (such as \\(W_2\\)).

**The key optimization point** lies in overlapping computation and communication. When executing forward propagation for layer \\(i\\), GPUs can prefetch weights for layer \\(i+1\\), enabling actual parallel execution. This method maintains efficiency while adapting to FSDP's distributed characteristics.



During FSDP operation, while we compute the **second layer**, we simultaneously fetch weights for the **third layer**. When computation reaches the third layer, **GPU 1** owning these weights broadcasts them to all training GPUs. This process continues repeating until the network's final layer.

At the network's end, each model completes full forward propagation, calculates **local loss** based on its mini-batch data, and retains activation values for all layers in memory for backward propagation use. The backward propagation process adopts a similar reverse flow: the holder of the last layer weights broadcasts them to all devices, initiating backward computation.

A practical optimization is to let all GPUs retain the last layer weights in memory, as these parameters are immediately reused in backward propagation. This avoids redundant overhead from repeatedly deleting and reloading last layer parameters.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image37.png)

During backward propagation, three key operations must be performed. First, after each GPU completes backward propagation calculation for its assigned layer, it obtains weight copies. At this point, each GPU has calculated **local gradients** of the loss function with respect to its assigned layer weights.

Next, these gradients need to be communicated back. The GPU responsible for specific weight matrices also manages corresponding gradients. Unlike all-reduce for all gradients in data parallel, here the GPU owning weight matrices collects and aggregates local gradients from all devices. For example, GPU 1 sends its last layer gradients to GPU 2, which then calculates the **complete gradient** \\(\frac{dL}{dW_4}\\) of the entire macro-batch with respect to last layer weights.

Finally, these operations must be executed in parallel to minimize downtime. Backward propagation includes three main tasks: calculating local gradients, gradient communication, and gradient aggregation for **weight updates**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image38.png)

The **weight** owner for a given layer must broadcast these weights to all GPUs. After GPUs receive weights, they calculate backward propagation for that layer. When each GPU completes backward propagation, it sends gradient results corresponding to weights back to the weight owner GPU. The owner then aggregates these gradients and executes weight updates. Notably, updated weight matrices don't need immediate re-communication, as they will be redistributed during the next forward propagation. This differs from Data Parallel (DP) methods.

These operations can occur in parallel. For each layer in the network, the following three steps are repeated:
1. Obtain weights for that layer
2. Calculate backward propagation
3. Aggregate gradients and update weights

In deep networks, these steps overlap between consecutive layers. For example, when calculating backward propagation for layer \\(L\\), gradients for layer \\(L+1\\) are being aggregated and its weights updated, while weights for layer \\(L-1\\) are being prefetched. This **parallelization** mechanism ensures efficient resource utilization.

Ideally, communication and computation should completely overlap. When backward propagation completes, all gradients have been communicated and all weight updates applied. Additionally, **data loaders** typically running asynchronously on CPU cores should have prepared the next batch of data. This maximizes GPU utilization, keeping tensor cores continuously fully loaded.

This process is a typical example of **large-scale distributed training**, achieving performance optimization through parallelization within GPUs and across GPUs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image39.png)

This prepares us for our next batch of tasks. **Fully Sharded Data Parallel** is very efficient, but there's an even more advanced variant called **Hybrid Sharded Data Parallel**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image40.png)

Data parallel, or Hybrid Sharded Data Parallel (HSDP), has the core concept of dividing GPUs into a two-dimensional grid. In previous examples, we used N GPUs and applied parallelization strategies along a single axis for all variants of data parallel.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image41.png)

When implementing Hybrid Sharded Data Parallel, we introduce two parallel dimensions. The first dimension adopts standard Fully Sharded Data Parallel (FSDP) within groups of K GPUs. Within each group, model weights are distributed across K GPUs, continuously exchanging weights and gradients during forward and backward propagation.

We scale by setting up M parallel replicas of such K GPU groups. For example, consider two groups with four GPUs each. Weights are partitioned across four GPUs within each group, while the entire configuration is replicated in the second group.

This method achieves typical **data parallel** between groups. During training, each group independently executes forward and backward propagation, calculating local gradients. After backward propagation completes, groups synchronize.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image42.png)

Each group must perform **all-reduce operations** on cross-group gradients to obtain complete macro-batch gradients. Subsequently, groups can independently update their gradients after receiving complete macro-batch gradients. This method is called **multi-dimensional parallel**, as it simultaneously adopts two different strategies to parallelize computation.

The practicality of this method stems from these parallelization strategies having different characteristics for communication requirements. In Fully Sharded Data Parallel (FSDP), forward propagation requires copying network weights to all participants, requiring one complete communication of weights. During backward propagation, weights must be re-communicated while gradients must also be transmitted. Therefore, a single forward-backward propagation within FSDP groups requires completing three cross-group communications of network weights.

In contrast, standard data parallel maintains independent weight copies for each group, requiring only all-reduce operations on gradients. This means communication across multiple data parallel groups requires transmitting network weights only once per forward-backward propagation.

This design philosophy aligns with GPU cluster hierarchy. For example, servers equipped with 8 GPUs and high-speed interconnects might constitute FSDP groups due to higher communication requirements within groups. Simultaneously, multiple such servers (each holding complete model weight copies) can operate in parallel in another dimension. Inter-server communication is inherently slower than intra-server communication, highlighting the importance of designing algorithms utilizing known network topology.

The core challenge lies in parameter tuning, as it's difficult to determine optimal configurations beforehand. Only after establishing data parallel can we further explore optimization space.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image43.png)

Once **Data Parallel (DP)**, **Fully Sharded Data Parallel (FSDP)**, and **Hierarchical Sharded Data Parallel (HSDP)** are implemented, this method can significantly scale model size. For example, a model with 100 billion parameters requires 800GB memory for storage. But if distributed across 80 GPUs, each GPU's memory requirement drops to only 10GB, enabling FSDP training of large models.

Current challenges still exist with model activation values consuming memory. Taking **LAMA 3405B** as an example, this Transformer with 126 layers, model dimension 16,000, and sequence length 4,096, storing hidden states during forward propagation alone consumes massive GPU memory, causing memory shortage issues as model and sequence sizes increase.

To address this issue, **activation checkpointing techniques** can be adopted. This technique no longer stores all activation values in memory, but recomputes them during backward propagation, optimizing memory usage.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image44.png)

To understand how it works, let's conceptualize **neural networks** differently: each layer performs two operations—calculating next layer activation values through **forward propagation**, while using upstream gradients and activation values to calculate current gradients through **backward propagation**.

In standard forward-backward propagation, assuming constant computation and memory, forward propagation requires four steps (storing activation values), and backward propagation also requires four steps. For an \\(N\\)-layer network, this typically requires \\(O(N)\\) computation and \\(O(N)\\) memory. But this method can cause memory exhaustion for large networks.

An alternative is to **recompute activation values** during backward propagation, with the following process:
1. Run first layer forward propagation then immediately discard activation values
2. Repeat this process for all layers, retaining only last layer activation values
3. Calculate backward propagation for the last layer
4. Since intermediate activation values have been discarded, recompute them on-demand during subsequent backward propagation

This method makes \\(N\\)-layer network computation reach \\(O(N^2)\\), but memory only requires \\(O(1)\\), because the sum of recomputation times grows quadratically (\\(N + (N-1) + (N-2) + \dots + 1\\)).

To reduce computational costs, **checkpointing** techniques can be introduced: save activation values every \\(C\\) layers, limiting recomputation to small blocks of the network. This reduces computation to \\(O(N^2/C)\\) and controls memory to \\(O(C)\\). Usually set \\(C = \sqrt{N}\\), making computation \\(O(N\sqrt{N})\\) and memory \\(O(\sqrt{N})\\). This trade-off solution enables efficient training of larger models.

After completing activation checkpointing setup, **FSTP** and **HSTP** optimization strategies can be further implemented.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image45.png)

We can achieve **significant progress** in this field. It enables us to efficiently train large-scale models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image46.png)

The scaling approach can be summarized as follows: Initially adopt **original data parallel** strategy, suitable for models with parameter scales around one billion and scalable to about 128 GPUs. It's usually recommended to maximize local batch size per GPU to fully utilize available memory.

When model scale exceeds one billion parameters, GPU memory becomes a limiting factor due to increased model memory usage. At this point, transition from data parallel to **Fully Sharded Data Parallel (FSDP)**. FSDP enables significant scaling but introduces activation memory bottlenecks, which can be alleviated through activation checkpointing techniques. Although activation checkpointing reduces training speed, it supports training larger models and can scale to hundreds of GPUs.

When GPU count exceeds specific thresholds (usually 256 to 512 GPUs, depending on cluster topology), FSDP computational overhead becomes excessive. At this point, **Hybrid Sharded Data Parallel (HSDP)** should be adopted. This method supports training models with parameter scales reaching hundreds of billions on clusters with up to thousands of GPUs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image47.png)

For models with sequence lengths exceeding 10,000 or parameter counts breaking **50 billion**, advanced parallel strategies such as context parallel, pipeline parallel, or tensor parallel must be adopted.

When optimizing such large-scale distributed training systems, a common challenge is the existence of numerous parameters to tune—including global batch size, local batch size, **HSDP dimensions**, **FSDP dimensions**, and recomputation strategies.

The key to handling complexity lies in focusing on optimizing **Model FLOPs Utilization (MFU)**. When lost in the maze of GPU parallelization details, MFU can serve as a guiding indicator to streamline training processes. Prioritizing MFU improvement can effectively guide optimization direction.

Before continuing deeper...



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image48.png)

To model **FLOPs utilization**, we first need to discuss hardware FLOPs utilization. Theoretically, a single H100 chip's Tensor Core can achieve 989.4 TFLOP/second computational capability. But the practical question is: what percentage of theoretical peak performance can actually be achieved?

This is quantified through **Hardware FLOPs Utilization (HFU)**, which represents the degree of actual computational performance relative to theoretical peak. This metric's implementation is very straightforward—requiring only a few lines of PyTorch code to complete measurement.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image49.png)

This benchmark test was conducted on **H100 GPU**. The horizontal axis represents dense matrix multiplication operations in loops, measuring time consumed for each operation, from which **Floating-Point Operations (FLOPs)** executed can be calculated. Matrix sizes range from 512 to 32,000. The vertical axis shows **Hardware Floating-point Utilization (HFU)**, measuring the proportion of these operations reaching the device's theoretical maximum throughput.

Using simple PyTorch loops, H100 can achieve about 80% HFU in large matrix multiplications (such as 8,000×8,000). But HFU doesn't account for other tasks GPU executes, such as activation recomputation, running auxiliary models, data loading, or data augmentation.

For this, we introduce **Model FLOPs Utilization (MFU)**, measuring the proportion of GPU theoretical peak FLOPs used for model forward and backward propagation. When calculating MFU, first determine FLOPs required for complete forward-backward propagation based on model architecture and micro-batch size, then compare with device theoretical peak throughput—the ratio of these two is the theoretical minimum propagation time.

Subsequently, measure actual time consumed for forward-backward propagation (including additional tasks like data loading, augmentation, communication, and activation checkpointing), and the ratio of theoretical minimum time to actual time is MFU. This value ranges from 0 to 1, reflecting training loop efficiency.

As shown in the example, this can be benchmarked through relatively simple PyTorch code (running forward and backward propagation).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image50.png)

On a shallow multi-layer perceptron using ReLU nonlinearity, by using extremely wide MLP layers and large-batch training on a single H100 GPU, we achieved about 50% **Model FLOPs Utilization (MFU)**.

When adjusting distributed training parameters, the primary goal is to maximize MFU, as this is the **core metric** for optimizing training throughput. Currently, achieving high MFU is a crucial research direction in large-scale training scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image51.png)

Generally, achieving **30%** or above is considered good performance. If this percentage is far below 30%, there are likely major bottlenecks or issues. Exceeding **40%** is considered excellent, representing **industry-leading level**.

Below are some benchmark data from recent research papers.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image52.png)

Particularly noteworthy is that the **Llama3-405B paper** we discussed shows that during their final training phase, they simultaneously used 8,000 to 16,000 GPUs. Under these configurations, their **Model FLOPs Utilization (MFU)** reached the high range of 35%-42%, which is quite excellent.

Achieving significantly higher MFU on **H100** is quite challenging. Paradoxically, newer generation devices sometimes show lower MFU performance. For example, the previous generation **A100** could even exceed 50% MFU.

This difference stems from GPU computational speed improvement outpacing communication bandwidth advancement. From A100 to H100 iteration, theoretical computational throughput increased about 3x, but theoretical memory bandwidth only improved 2x. The increasingly widening gap between computational speed and communication scalability may cause MFU metrics to decline in newer generation devices.

I deliberately focused the discussion on this phenomenon.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image53.png)

Let's focus on these key points because they're what you're most likely to use in practice. I suspect none of you in the audience have experience with **ten-thousand GPU clusters**—if you do, please definitely connect with me after class; I'd love to establish contact.

These methods scale to hundreds of GPUs, which is what you'll encounter in actual work. The slides also cover other technical solutions I find quite enlightening.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image54.png)

For complete details, you can review offline. **Context Parallel** refers to partitioning along the sequence dimension, which is how Transformer models process sequence data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image55.png)

The core concept lies in distributing different segments of long sequences across multiple GPUs. In the context of **Transformer modules**, this method is particularly effective for many components, because operations such as **layer normalization**, **feed-forward networks (MLPs)**, and residual connections are inherently independent along the sequence.

Partitioning computation along the sequence dimension is relatively simple, but implementation within MLPs becomes more complex, where some challenges arise.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image56.png)

Since **weights** are involved, you must perform all-reduce operations on gradients, similar to what we did in data parallel.

**Attention mechanisms** are where sequence parallel becomes complex. Recall that in attention mechanisms, we need to calculate...



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image57.png)

Pairwise interactions between elements in the sequence. **QKB projection** implementation is relatively straightforward, as it can be easily parallelized across sequences. However, **core attention matrix** parallelization faces major challenges, especially in initial implementation stages.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image58.png)

One developed method is called **Ring Attention**, which partitions the complete attention matrix into multiple blocks. These blocks are processed independently in parallel across multiple GPUs while ensuring appropriate synchronization mechanisms. For more details, please refer to the original paper.

The second method is conceptually simpler.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image59.png)

This method is called **Ulysses attention**, which implements parallel computation across attention heads. In Transformer models, multi-head attention mechanisms are typically adopted, computing multiple attention matrices in parallel. Ulysses attention parallelizes the computation process of these core attention operators across heads, while other Transformer components are parallelized along the sequence dimension.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image60.png)

**Context parallel** becomes crucial when extending sequence lengths to extremely large values. Taking Llama3 pre-training as an example, this model training is divided into two phases.

The first phase uses sequence length 8,000 without any context parallel. The second phase increases sequence length to 130,000 and adopts **16-way context parallel**—meaning each 130,000-length sequence is processed by 16 GPUs in parallel for a single sequence.

Conceptually, this is equivalent to reducing batch size to 1/16, because each GPU now processes fewer than one batch element. This embodies the core principle of context parallel.

**Pipeline parallel** adopts a different strategy, achieving parallelization by partitioning models into different stages.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image61.png)

Intuitively, what measures should be taken along the layer dimension?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image62.png)

Consider a multi-layer network distributed across multiple GPUs. Although this method seems intuitive, it introduces **sequential dependency** problems. Each GPU needs activation values from the previous GPU to execute forward propagation, while during backward propagation, computation depends on upstream layer gradients.

We can visualize this process with a diagram: the vertical axis represents GPUs 1 to 4, the horizontal axis represents timeline. GPU 1 executes forward propagation then passes activation values to GPU 2, GPU 2 continues to GPU 3, then to GPU 4. GPU 4 can simultaneously execute forward and backward propagation, then pass gradients back to GPU 3, 2, and 1 in sequence.

This scheme is extremely inefficient because GPUs spend significant time idle. When using \\(n\\) GPUs, actual effective utilization is only \\(\frac{1}{n}\\). For example, 8-way **pipeline parallel** maximum MFU (Model FLOPs Utilization) is about 12%, which is clearly not ideal. This efficiency loss is commonly called **"bubbles"**—time periods when GPUs are idle waiting for communication.

The key to optimizing pipeline parallel lies in minimizing this bubble. An effective strategy is to process multiple **micro-batches** simultaneously. Instead of letting a single batch pass sequentially through all GPUs, we can interleave multiple batches, enabling different GPUs to execute operations in parallel. Although there are various implementation patterns, one relatively simple method is particularly effective.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image63.png)

In this configuration, we implement **4-way pipeline parallel** with four GPUs running simultaneously. Four batches of data are processed in parallel and distinguished through color coding.

GPU 1 sequentially executes forward propagation for blue, yellow, green, and red batches. When GPU 1 processes the yellow batch, activation values generated by the blue batch are transmitted to GPU 2, enabling it to begin forward computation for the blue batch.

This **cascading pattern** continues across all GPUs, achieving parallel execution. A similar interleaving pattern exists during backward propagation, with different micro-batches achieving efficient processing through GPU pipelines.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image64.png)

In this scenario using **4-way pipeline parallel** and four micro-batches, the theoretical maximum **MFU (Model FLOPs Utilization)** corresponds to the proportion of non-white areas in the diagram. This proportion increases to 57%, which is quite ideal.

Theoretically, increasing micro-batch count in pipeline parallel can improve MFU by enhancing parallel processing capability. But more micro-batches require storing all activation values in memory, necessitating **activation checkpointing** techniques.

This introduces multiple trade-offs for system tuning:
- Adjusting pipeline parallel stages
- Balancing micro-batch count
- Determining activation checkpointing aggressiveness
- Possibly layering **data parallel** strategies

The final optimization challenge lies in: achieving MFU maximization through fine-tuning these parameters in the training pipeline.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image65.png)

Tensor Parallel (TP) refers to partitioning models along specific dimensions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image66.png)

Along the model dimension, we have numerous **weight matrices**, which repeatedly compute \\(xW = y\\) in Transformers. The core of this method lies in splitting each weight matrix across multiple GPUs—this differs from FSTP because we can distribute single weight matrices without communication.

Each GPU executes **blocked matrix multiplication**, computing one slice of matrix operations on complete input data. Specifically, weight matrices are partitioned into \\(W_1\\), \\(W_2\\), \\(W_3\\), and \\(W_4\\), with each GPU calculating local results of matrix multiplication to generate corresponding parts of output.

After **forward propagation**, a challenge arises: activation values must be collected across all GPUs for subsequent forward propagation use. There's a small optimization point here—



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image67.png)

When implementing two layers sequentially, intermediate communication between them can be avoided. By partitioning the **first weight matrix** into column blocks and the **second weight matrix** into row blocks, due to blocked matrix multiplication properties, the computation process can elegantly align. The final output can be viewed as an inner-product-like structure formed by multiplying block matrices Y and U. This method achieves two-layer matrix multiplication across multiple GPUs, requiring communication only after every two layers.

This technique is particularly effective for **Transformer models**, as their feed-forward networks (FFN) inherently have two-layer MLP structure. Therefore, this two-layer tensor parallel technique is commonly used in large-scale Transformer models to optimize MLP computation.

Among numerous cross-GPU computation allocation schemes, this method stands out for its efficiency demonstrated on Transformer architectures.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image68.png)

The correct approach is to **utilize** all available means. In practice, we adopt **ND parallel** techniques, as demonstrated in previous examples.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image69.png)

In practice, current state-of-the-art **HSTP** two-dimensional parallel techniques have evolved into four-dimensional parallel. Taking **LLaMA** as an example, its largest-scale training task utilized 16,000 GPUs. This configuration simultaneously adopted 8-way tensor parallel, 16-way context parallel, 16-way pipeline parallel, and 8-way data parallel.

These parallel mechanisms each have different communication requirements. By strategically arranging these different parallel dimensions in clusters, we can fully utilize different communication speeds at various system levels to optimize performance. This provides a concise overview of large-scale distributed training.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec11_image70.png)

Today's key takeaways are: **Single GPUs** operate as general-purpose parallel computing devices, while **GPU clusters** are ultra-large-scale parallel machines composed of tens of thousands or even hundreds of thousands of GPUs, which we program as unified systems.

We explored multiple methods for parallelizing computation on large clusters, as well as memory-saving **activation checkpointing** techniques. When designing these pipelines, the primary optimization core metric is **Model FLOPs Utilization (MFU)**.

When you next train models on tens of thousands of GPUs, remember these principles. Let me know—maybe I can borrow your GPU resources.
