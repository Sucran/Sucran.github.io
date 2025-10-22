---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 5: Image Classification with Convolutional Neural Networks"
date: 2025-09-07T16:17:11+08:00
draft: false
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image1.png)
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image2.png)

Today, we will discuss **image classification** using Convolutional Neural Networks (CNNs). You might be curious about me as your new instructor.  

I am **Justin Johnson**, who pursued my Ph.D. at Stanford University from 2012 to 2018, working with **Professor Fei-Fei Li** on deep learning and computer vision research, covering multiple tasks in this field.  

During my time at Stanford, I had the privilege of co-founding the **CS231N course** with Andrej Karpathy and Fei-Fei Li, and taught this course multiple times from 2015 to 2019.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image3.png)

After Stanford, I joined **Facebook AI Research**, focusing on **deep learning** and **computer vision**. Later I took a faculty position at the University of Michigan, where I taught this course multiple times.

Although it's been some time since I last taught here, I recently co-founded a startup called **World Labs** with Fei-Fei Li.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image4.png)

That concludes my brief introduction. Regarding the current progress of this course, we are at an **interesting juncture**.  

The course is divided into several parts, and we have just completed the first part, covering **fundamentals of deep learning**. This part is particularly exciting because the content covered in the first four lectures contains all the core concepts of deep learning.  

Now you have mastered the essential elements needed to build deep learning systems.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image5.png)
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image6.png)

At this turning point, it's necessary to review the main topics covered in the initial part of the course.

The first topic is **image classification based on linear classifiers**, which serves as an example problem demonstrating how deep learning is applied. The first step in solving deep learning problems is usually to formalize the problem by defining inputs as numerical grids or **tensors** and outputting tensors, thereby framing the problem as tensor transformations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image7.png)

In the **image classification** task, our goal is to categorize images into predefined human-understandable categories. Input data consists of grids of pixel values organized as three-dimensional tensors, while the output represents classification scores indicating the likelihood of the image belonging to each category.

We predefine a set of categories and train **neural networks** to predict high scores for correct categories and low scores for incorrect categories. To achieve this goal, we can model the problem using **weight matrices**—matrices that, when multiplied with image pixels, generate these classification scores.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image8.png)

We observed multiple perspectives on linear classifier interpretation, establishing a functional form for predicting image scores based on weight matrix \\(W\\). The **core problem** then arises: how to choose the optimal \\(W\\)? This leads us to the concept of **loss functions**, which are used to evaluate the performance of given weight matrices on specific datasets.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image9.png)

Specifically, we studied several **loss functions** commonly used for classification problems, including **softmax loss** and **SVM loss**.  

After establishing the image classification framework for linear classifiers and defining evaluation metrics through loss functions, we now face the **critical task** of finding optimal solutions in this parameter space.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image10.png)

Optimization plays a **key role** here. Imagine defining an optimization space where the **x-axis** represents all possible configurations of weight matrices, and the **loss function** corresponds to the height of this surface. High loss values should be avoided, so the goal is to minimize them.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image11.png)

The purpose of optimization is to traverse this space, descend along the manifold, and find the point with minimum loss. Each point in this space corresponds to a **weight matrix**, and by navigating through this space, our goal is to find an **optimal weight matrix** that can effectively solve the task.

We discussed several commonly used optimization algorithms in the deep learning pipeline, including **Stochastic Gradient Descent** (usually with momentum), **RMSprop**, and **Adam**. Notably, the Adam optimizer recently received the "Test of Time Award" at ICLR 2025 (International Conference on Learning Representations). This recognition highlights the lasting impact of the Adam paper—originally published at ICLR in 2015. Academic conferences often use such awards to honor influential work from a decade ago, and this honor confirms the importance of the Adam optimizer in the machine learning field.

Now that we have established linear classifiers, defined loss functions, and explored optimization techniques, we are almost ready to move forward.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image12.png)

However, we encountered a limitation with **linear classifiers**—they lack sufficient expressive power. This deficiency is mainly reflected in two key perspectives:  

From a **visual perspective**, the weight matrix of linear classifiers can be viewed as image templates, where each row represents a template learned for a specific category. This approach forces the classifier to compress all knowledge about a category into a single template, which is clearly insufficient. For example, a car template might appear as a red patch, but cars can actually be blue, purple, green, or various other colors. Linear classifiers cannot effectively capture such appearance variations within categories.  

From a **geometric perspective**, linear classifiers divide high-dimensional space through hyperplanes. While this works for linearly separable categories, real data often lacks this property, making this approach overly limited.  

These limitations in image classification drove the development of **neural networks**. Neural networks generalize linear classifiers by stacking multiple weight matrices with nonlinear layers.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image13.png)

This provides us with a more powerful mechanism for predicting scores from input data. The problem essence remains unchanged: input pixels are processed through computation to output scores, but we now choose a different functional form for the **scoring function**.

The mathematical derivation is very intuitive—by introducing additional weight matrix \\(W_2\\) and intermediate nonlinear transformations in \\(F = WX\\)—but the classifier's performance is significantly improved.

However, when it comes to **optimization**, complexity emerges. Given a loss function and model, we need to find weight matrix values that minimize the loss, which requires us to compute gradients.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image14.png)

To optimize the model, we must compute **gradients** of the loss function with respect to all model parameters. This concept is presented through computational graphs.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image15.png)

**Computational graphs** serve as a data structure for organizing the computational process of neural networks. Each node in the graph represents a **basic computational unit**, such as matrix multiplication, **ReLU activation functions**, or similar operations. Data starts from inputs and weights on the left, flows through intermediate nodes in the graph from left to right, and finally generates the **loss function** on the right.

After computing the loss value, the system traverses this graph from right to left, computing gradients of the loss with respect to all nodes in the network. The power of this method lies in: it allows us to define arbitrarily complex neural networks and expressions for computing outputs from inputs, while providing algorithms for automatically computing gradients of these networks. This process is implemented through the **backpropagation** mechanism.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image16.png)

**Backpropagation** is the fundamental algorithm of deep learning. It transforms the global challenge of computing loss through computational graphs into local problems.

Each node in the graph operates independently without needing to understand broader context. In the **forward propagation** phase, nodes compute outputs based on inputs; in the **backpropagation** phase, they receive upstream gradients.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image17.png)

This system doesn't need to consider the source or cause of these gradients, only to compute **downstream gradients** for their inputs based on given upstream gradients.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image18.png)

This mechanism is powerful because it allows us to define various types of nodes that all follow a **local API** for computing outputs and gradients. As long as all nodes follow this API, we can assemble them into complex computational graphs capable of performing arbitrary computations. When applying the **backpropagation algorithm**, gradients are automatically derived.

The slides you viewed earlier showed backpropagation for scalar values, but this method can also be generalized to computations involving vector, matrix, or tensor values.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image19.png)

The **fundamental concept** to remember is: both inputs and outputs are tensors. **Upstream gradients** (i.e., gradients of the loss function with respect to outputs) always have the same shape as output tensors. Since the loss function is scalar, gradients of the loss with respect to tensors represent how much the loss value changes when each element of the tensor undergoes small perturbations, which defines gradients as sensitivity of the loss to independent elements of tensors.

**Downstream gradients** (gradients with respect to inputs) also match the shape of input tensors. The backpropagation algorithm essentially applies the chain rule, computing downstream gradients through upstream gradients and operation functions.  

In subsequent assignments, you will practice deriving gradient expressions for various operators in neural networks. This framework provides systematic solutions for most problems in deep learning.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image20.png)

This concept was designed for much more than image classification, linear classifiers, or fully connected networks—it has broader universality. For any problem to be solved, you only need to follow these steps:  
- Encode it in **tensor** form,  
- Define a computational graph that transforms input tensors to output tensors,  
- Collect datasets of input-output tensor pairs,  
- Specify a **loss function** for the problem,  
- Optimize this loss function through **gradient descent** and backpropagation.  

This powerful framework supports almost all deep learning applications, from image classification and generation to large language models. Almost all neural network-based solutions use this method or its slight variants for training.  

This leads us into the second part of the course: "Perceiving and Understanding the Visual World." Here we will more specifically explore how to apply this general deep learning framework to computer vision problems—that is, processing images and performing meaningful tasks. Today we will take an important step in this direction by delving into **convolutional networks**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image21.png)

Convolutional networks are a moderate extension of the computational framework we previously established. In this **computational graph** paradigm, we have discussed various operators that can be integrated. Although we have a powerful framework, we have only explored limited node types so far. These types include **fully connected layers** that perform matrix multiplication, activation functions such as ReLU, and loss functions.  

To transition from our current understanding to convolutional networks, we need to introduce several additional node types in computational graphs. Specifically, there are two key operators that will enable us to build more powerful networks: **convolutional layers** (which will be the main focus of today's lecture) and **pooling layers** (which are typically applied in image processing tasks).  

This is the agenda overview for today's discussion.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image22.png)

I will first outline the overall concept of **convolutional networks**, then focus on two specific **computational primitives** used when building such networks in computational graphs. This topic we have already explored.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image23.png)

Let's step back and reconsider the **image classification** problem. As previously discussed, image classification is a fundamental problem in computer vision.

This task requires receiving an input image and predicting which category it belongs to from a set of **K possible labels**. In this example, the image clearly shows a cat, so the classifier should predict the "cat" label.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image24.png)

We have to some extent solved this problem by building linear classifiers and fully connected multilayer perceptron neural networks. However, these networks operate directly in pixel space. **It's worth noting that the first step in solving deep learning problems is to express the problem in terms of input-output tensors.** In this example, our input tensor consists of raw pixel values of the image. When we express the function \\(f(x) = Wx\\), input \\(x\\) represents the actual numerical values of all pixels, which are then converted to class scores.

Before neural networks were widely adopted (roughly from the early 2000s to around 2010), the mainstream approach was **feature representation**. The core idea was to explicitly define the input to neural networks—instead of directly inputting raw pixel values, we designed feature extraction functions that convert pixel values into high-level representations that capture important image features. This representation incorporates human intuitive understanding of the task.

For image classification based on feature representation, the first step is to define a **feature extraction function** that converts raw pixels to higher-level representations. This representation is then used as input \\(x\\) for linear classifiers. Major research work in computer vision from the 2000s to early 2010s used this feature representation concept to accomplish various tasks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image25.png)

Delving into details of these specific feature representations isn't of much practical significance, as they became obsolete about a decade ago. However, understanding their general form is still enlightening.

For example, one commonly used feature representation is **color histograms**. The core idea is to divide the color space, assuming that the distribution of colors in images might provide valuable information for classifiers.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image26.png)

When developing fruit detectors, such as **apple ripeness classifiers**, distinguishing red apples from green apples might require the network to recognize color information. To capture this feature, we can construct feature representations by discretizing the color space into several intervals. Each pixel in the image is mapped to the corresponding color interval, and the final feature representation is the count of pixels within each color interval.

This method is called **color histograms**, and its unique feature is abandoning spatial structure and focusing solely on color distribution. For example, an image with red pixels concentrated in one corner and another image with red pixels scattered everywhere would have identical features under color histogram representation—despite significant differences in their raw pixel values. Therefore, color histograms, as a basic feature extractor, can exclusively parse color information while ignoring spatial correlations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image27.png)

Another type of feature representation historically studied is Histogram of Oriented Gradients (HoG). Although computational details aren't critical, the core idea is to abandon color information and focus on structural features. Specifically, this method analyzes local orientations of edges within image regions.

Taking this frog as an example, diagonal features correspond to leaf structures, while circular patterns around the frog's eyes are also captured. Although we don't need to delve into specific computational processes, it's worth understanding that such **hand-designed features** were very common in image analysis over a decade ago. These features were often combined in complex ways for various scenarios.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image28.png)

A common question is determining the **optimal feature representation**. Standard methods include extracting multiple feature representations from images and concatenating them into a single feature vector. This composite vector then serves as the feature representation of the image. Subsequently, any classifier can be applied to this representation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image29.png)

Comparing these two systems is quite interesting. **System A** consists of a feature extractor and a learned linear classifier, while **System B** is an end-to-end neural network.  

From a broader perspective, these two systems are not fundamentally different. They both take raw pixel values as input and output classification scores or predictions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image30.png)

The **key difference** lies in which components of the system are hand-designed and which are learned through gradient descent. In the feature extraction plus linear classifier paradigm, the feature extraction component is manually designed—possibly implemented through complex C or MATLAB code—while only the classifier part is learned from training data through gradient descent.  

In contrast, the core philosophy of the **neural network** approach is that gradient descent might surpass manual programming, and massive data often brings deeper understanding of problems. Neural network classifiers maintain the same input-output structure (from raw pixels to classification scores), but the key point is that every component between these endpoints is optimized through training data using gradient descent.  

This **end-to-end learning** paradigm addresses potential limitations of hand-designed feature extractors, where imperfect intuition or implementation challenges might create bottlenecks. The success of convolutional networks and broader deep learning proves that data-driven optimization often surpasses human design capabilities—a trend that has been validated in countless applications over the past fifteen years.  

Specifically for **image processing**, the design challenge lies in constructing appropriate network architectures rather than fixed feature extractors. Unlike fully connected networks (which aren't practical for this design), we construct computational graphs composed of sequences of operations. The key point is that these architectures define function spaces rather than specific functions, because network weights are still learnable parameters. The role of human designers is to determine the optimal sequence and structure of these operations in computational graphs.

At each stage of the processing, what are the dimensions of all matrices involved?

Even in the **deep learning** era, human input remains crucial for designing certain aspects of problems. However, the nature of this design work has changed.

This is where we begin to recognize limitations of current tools in addressing this challenge.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image31.png)

So far, we have explored linear layers and fully connected networks. The only neural network architecture we have studied involves flattening image pixels into vectors, performing matrix multiplication, applying **ReLU activation functions**, and repeating this process. However, this approach has **significant flaws**: it ignores the spatial structure of images.

Images are inherently two-dimensional, and this structural organization is crucial to their content. By flattening pixels into vectors for linear classification, we ignore this fundamental characteristic of input data in neural network design. Therefore, when developing neural network architectures for images, we must consider alternative design approaches that can preserve and utilize their **spatial characteristics**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image32.png)

What computational primitives can we integrate into computational graphs to better follow the two-dimensional structure of images? This leads to the concept of **convolutional networks**.

Convolutional networks are a class of neural network architectures composed of linear layers, nonlinear activation functions, convolutional layers, and pooling layers, sometimes including other components. These architectures directly process raw pixel values and ultimately output predictions or scores for images.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image33.png)

The general structure of such networks typically consists of two parts: **prefix** and **body**. The body part contains alternating stacked convolutional layers, pooling layers, and nonlinear layers, which can be viewed as a process of extracting effective feature representations from images. On top of this, one or more fully connected layers are usually stacked, serving as multilayer perceptron or fully connected network classifiers. These classifiers are responsible for processing features extracted by the convolutional part of the network.

The key point is that the entire system is trained in an **end-to-end** manner through gradient descent, optimized by minimizing the loss function on the training dataset. Such networks have a long development history. The specific convolutional architecture shown on screen originates from a 1998 paper by Yann LeCun, Léon Bottou, and others. At that time, they were working on developing convolutional neural networks for digit recognition, achieving remarkable success under extremely limited computational resources. In an era without GPUs or TPUs, training was costly, but the core algorithms and network architectures remained highly similar to structures widely used in the 2010s.

The next major breakthrough came in 2012 with the introduction of the **AlexNet** architecture.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image34.png)

This marked a **major breakthrough** in the deep learning field, especially achieving tremendous leaps in computer vision. As discussed in previous lectures, the **AlexNet** architecture is not fundamentally different from the **LeNet** architecture proposed by Yann LeCun in 1998—both consist of convolutional layers and fully connected layers. But AlexNet is larger, has more layers, and denser units, yet can still be trained end-to-end through backpropagation to minimize relatively simple loss functions.

AlexNet can be considered the **turning point** when deep learning truly began to flourish. This progress benefited from the popularization of GPU training resources, expansion of internet resources, and the birth of datasets like **ImageNet**. From 2012 to around 2020, convolutional neural networks almost dominated all problems in computer vision.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image35.png)

In that era, for almost all problems involving image processing, the most effective solution was using Convolutional Neural Networks (ConvNets). This includes tasks like detection—not only classifying images but also drawing bounding boxes around objects and labeling category tags.  

Segmentation tasks require labeling at the pixel level rather than image or box level. We will delve into architectural design for these tasks in subsequent lectures, but it's obvious that convolutional neural networks provide extremely efficient solutions.  

Additionally, **Convolutional Neural Networks** were also applied to various language-related problem domains.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image36.png)

The core of **image captioning** tasks is predicting natural language descriptions from images. The earliest methods to achieve widespread success in this field were built on **convolutional networks**. This technical route also applies to more cutting-edge tasks in generative modeling.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image37.png)

Text-to-image generation is the reverse problem of image captioning. While captioning tasks generate natural language descriptions from input images, **text-to-image generation** requires creating new images from scratch based on text descriptions. Some of the earliest successful implementations of this method were built through **convolutional networks**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image38.png)

This chart originates from the **Stable Diffusion** paper published in 2021. This technology has made significant progress in recent years, which we will explore in detail in subsequent lectures.

Notably, the first effective version of this technology was also based on **convolutional networks**. Given its key position in computer vision history, the first version of this course in 2015 was named "Convolutional Neural Networks for Visual Recognition."

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image39.png)

At that time, **convolutional networks** were almost synonymous with computer vision, which was the main application field of deep learning. Therefore, when designing deep learning courses, it was logical to focus entirely on convolutional networks related to image processing. This decision marked the birth of this course a decade ago.

However, the field has undergone significant evolution since then. Convolutional networks have been largely replaced, and today's **visual recognition** covers a broader range of interesting topics. Correspondingly, the course name has been updated to no longer be limited to the single perspective of convolutional networks.

This transformation corresponds to the development process from 2012 to 2020. Besides the impact of the 2020 COVID-19 pandemic, the decline of convolutional networks mainly stems from the rise of **Transformer models**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image40.png)

**Transformer** models represent an alternative neural network architecture that we will explore in detail in subsequent lectures. This architecture was initially proposed in 2017, mainly for **natural language processing** tasks, such as document and text string analysis.

In the years following the paper's publication, its application scope was mainly limited to text processing. However, **a key paper in 2021** proved that this architecture could be successfully applied to image processing by adopting mechanisms almost identical to text processing.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image41.png)

Since then, researchers have found that for many problems previously solved using **convolutional networks**, replacing CNNs with **Transformers** while keeping other components unchanged often yields better performance.

Transformers show better scalability as data and computational resources increase. Therefore, they are increasingly becoming the preferred solution for more and more computer vision tasks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image42.png)

We will discuss **Transformer models** in more detail in Lecture 8. Although Convolutional Neural Networks (ConvNets) are not as widely used today as they were five years ago, they remain very important for the following reasons:

1. They form the foundation of many modern computer vision systems.
2. These algorithms are still frequently used in practice.
3. They help develop intuition for image processing.
4. They are not obsolete—many modern systems adopt hybrid architectures combining convolutions and Transformers. Understanding convolutional neural networks remains crucial.

Today we will focus on convolutional neural networks. As mentioned earlier, convolutional neural networks are computational graphs composed of several basic building blocks for image processing. We have already introduced **fully connected layers** and **activation functions**, and now we will study **convolutional layers** and **pooling layers**.

Let's briefly review fully connected layers—we discussed them in the context of linear classifiers. The input is a three-dimensional tensor representing an image, with dimensions 32 (height) × 32 (width) × 3 (RGB channels). This tensor is flattened into a vector of 3,072 elements (32×32×3). A weight matrix of 3,072×10 dimensions (corresponding to 10 output classes) is multiplied with this vector to produce a 10-dimensional output vector (class scores).

To generalize from fully connected layers to convolutional layers, consider the structure of fully connected layers: each output element is the result of computing the inner product of a row of the weight matrix with the input vector. This inner product is equivalent to **template matching**—high values indicate alignment between input and template, zero values indicate orthogonality. Therefore, fully connected layers can be understood as performing template matching operations.

Each template has the same size as the input. The output represents template matching scores between each template and the entire input.

This perspective enables us to generalize the concept of **fully connected layers** to **convolutional layers**. The core idea is to preserve the concepts of template matching and filter bank learning, but there's a key difference: these filters no longer need to have the same shape as the input.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image43.png)

Now, our filters will only detect a small portion of the input. Specifically, instead of flattening the image into a vector of 3,072 numbers, we preserve its **three-dimensional spatial structure**—that is, a tensor with three channels (also called depth), width 32 pixels, and height 32 pixels.

Each filter is a **sub-image** that matches the number of input channels (here a 5×5 pixel block). The spatial size of filters is smaller than the input image, but the number of channels remains consistent. We will then compute dot products between these filters and the input.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image44.png)

We can view **small filters** as templates for local regions of images. By sliding this filter across the entire image, we evaluate how well each sub-region of the image matches the template learned by the convolutional filter.

When we place the convolutional filter at a certain region of the image, this \\(5 \\times 5 \\times 3\\) filter aligns with the corresponding \\(5 \\times 5 \\times 3\\) block of the image at that spatial position. We then compute the **dot product** between them, obtaining a scalar value that reflects the alignment between the image block and template.

As the template slides across the image, this process repeats continuously. At each position, the **template matching score** quantifies the alignment between the image block and template. When the filter traverses the input image, these scores are collected into a two-dimensional plane, where each point corresponds to the alignment score between the corresponding image block and filter.

In **deep learning**, computational power is crucial. To enhance this, we use multiple filters. For example, after applying the initial \\(5 \\times 5 \\times 3\\) blue filter, we introduce a second \\(5 \\times 5 \\times 3\\) green filter. We repeat the same sliding process for the green filter, compute template matching scores and collect them into a second plane. This plane reflects each image block's response to the green filter.

Through this iterative process, we can introduce any number of filters, each participating in the **feature extraction** process.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image45.png)

In this example, we draw six filters with dimensions \\(3 \\times 5 \\times 5\\). These filters can be combined into a four-dimensional tensor, where the first dimension of six represents the **number of filters**, and the remaining \\(3 \\times 5 \\times 5\\) dimensions define the learned template.

The convolutional layer receives three-dimensional image input and four-dimensional filter banks, generating response planes by sliding each filter. When these response planes are stacked along the third dimension, the output dimensions are \\(6 \\times 28 \\times 28\\)—where \\(28 \\times 28\\) represents **spatial dimensions** and six represents the channel dimension.

Similar to linear layers, we often add learnable bias vectors to convolutional layers. The bias for linear layers is one scalar per row, while convolutional layers typically have one scalar bias value per filter, forming a six-dimensional bias vector in this example.

The question about RGB three channels is correct. Filters are obtained through **gradient descent** and backpropagation. Although we define operators using input images and filter banks, these filters are not manually specified but randomly initialized and learned through gradient descent based on the problem being solved. This is the **key capability**: although this layer is computationally expensive, it can be optimized through training data and computation.

Filter size (such as \\(5 \\times 5\\)) is a **hyperparameter**, which was discussed in previous lectures about hyperparameter tuning and cross-validation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image46.png)

These architectural **hyperparameters** are usually set through cross-validation. Regarding the question about using different filter sizes, as we will discuss in upcoming CNN architecture lectures (especially Inception networks), this approach is sometimes adopted. However, this brings an interesting API design challenge when determining computational graph primitives and emergent structures.

Traditionally, for computational efficiency and GPU kernel optimization considerations, we define **convolutional layers** with fixed filter sizes. But you can effectively implement multiple filter sizes by combining convolutional layers with different filter dimensions in network architectures.

We must clearly distinguish **parameters** from hyperparameters. Hyperparameters (such as the number and size of filters) are preset before training to define tensor shapes; while parameters are numerical values optimized during gradient descent. Although hyperparameters like filter count and size are set in the initial stage, the filter values themselves are randomly initialized and adjusted through optimization. The gradients we compute are precisely for updating these parameters during training.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image47.png)

When performing **backpropagation**, we compute gradients of the loss function with respect to internal parameters of the network. Specifically for convolutional networks, we need to compute gradients of the loss function with respect to each scalar weight in convolutional filters. This gradient value reflects how much the loss function changes when we fine-tune each scalar in the filter.

There's a key question about **bias terms**. Bias is added to each inner product result during computation—specifically, we first compute the inner product of the filter with a region of the image, then add the corresponding scalar value from the bias vector. The bias vector has the same number of elements as the number of filters, and each bias element is broadcast across the entire spatial dimension of the output but is only associated with one filter.

Conceptually, each filter generates a two-dimensional activation plane when sliding over input data, called an **activation map**. Multiple filters produce independent activation maps, which are eventually stacked to form the output of the convolutional layer.

During training, **gradient descent** iteratively updates filter parameters. The training loop includes the following steps:  
1. Get a batch of data  
2. Perform network forward propagation  
3. Compute loss value  
4. Compute gradients through backpropagation  
5. Update parameters using optimizer  

This process repeats until convergence.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image48.png)

This process always includes **data input**, forward propagation, **loss computation**, backpropagation, and **parameter updates**. Each parameter update modifies filter parameters.

We have already discussed convolutional layers previously.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image49.png)

In **convolutional layers**, batch processing mode is typically used for operations. We don't process single input images but batches of input images. This approach generates a four-dimensional input tensor for representing a group of input images.

Similarly, **filters** are also organized as four-dimensional tensors, where each filter is a three-dimensional data block of images. The output is also a four-dimensional tensor containing a group of outputs—one output per image. Each image's output is a three-dimensional tensor representing stacked feature planes.

Processing multi-dimensional data is a key aspect when building **neural networks**, and this process is often fascinating.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image50.png)

The general form of **convolutional layers** involves a four-dimensional input tensor with shape \\(n \\times c_n \\times h \\times w\\), representing a batch of \\(n\\) images. Each image has \\(c_n\\) channels—RGB images typically have three channels, but this value may vary. The spatial dimensions of the input are \\(h \\times w\\).

Convolutional filters are also four-dimensional with shape \\(c_{out} \\times c_n \\times k_w \\times k_h\\), where \\(c_{out}\\) is the number of output channels (filters), and \\(k_w \\times k_h\\) defines the size of the convolution kernel. Each filter is a three-dimensional tensor with shape \\(c_n \\times k_w \\times k_h\\), and \\(c_{out}\\) such filters are combined into a four-dimensional tensor.

The output is another four-dimensional tensor with shape \\(n \\times c_{out} \\times h' \\times w'\\), where \\(h' \\times w'\\) are the spatial dimensions of the output feature map. Each image in the batch generates an output with \\(c_{out}\\) feature planes, with each filter corresponding to one feature plane.

**Convolutional networks** are computational graphs composed of multiple such convolutional layers.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image51.png)

In practice, we typically stack multiple **convolutional operators** sequentially to form a **convolutional network**. This is a simple convolutional neural network architecture: starting from a 3×32×32 input image, the first convolutional layer uses 6 filters of size 5×5×3. The convolution operation generates new three-dimensional activation sets for the image—due to convolution's effect on size, the output contains 6 channels corresponding to the number of filters, while spatial dimensions become 28×28.  

The subsequent convolutional layer uses 10 filters of size 5×5×6. Here, 10 determines the output dimension of the next layer, while 6 ensures alignment of input channel dimensions. Through stacking such convolutional layers, large-scale computation can be achieved. But this specific network architecture has a **key problem**.  

Convolution is a **local operation** (this is another issue that can be discussed later), but the current core problem lies in **linearity**. Since convolution operations involve dot products (linear operations), the combination of two linear operators is still linear. Therefore, directly stacking two convolutional layers is equivalent in representational power to a single convolutional layer, which is determined by the linear nature of operations.

(Note: Technical terms like "convolutional operators/network", "filters", "dot products" are all translated according to computer vision field conventions, preserving accuracy of professional expressions; by splitting long sentences and adding connecting words (such as "due to", "therefore"), Chinese expressions are more consistent with technical document coherence; "activation set" is translated as "激活集合" rather than literal translation, balancing terminology standards with readability)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image52.png)

There's a simple solution to this problem: add **activation functions**. This is the same problem we encountered in multilayer neural networks, requiring the same solution. By inserting nonlinear activation functions between convolutional layers, we introduce nonlinearity to the problem and network architecture, thereby enhancing the network's representational capability.

Typically, **convolutional neural networks** consist of stacked convolutional layers, nonlinear layers, and other layer types in computational graphs. Regarding the question about convolutional filter learning content mentioned earlier...

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image53.png)

This can be understood through analogy with linear classifiers. In linear classifiers, each row of the learned weight matrix serves as a **template** for matching the shape of input images. Similarly, **convolutional filters** also operate as templates, but instead of covering the entire image, they only act on a small spatial region.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image54.png)

We can visualize the first layer **convolutional filters** of trained neural networks. These filters learned by the AlexNet architecture on ImageNet image classification tasks are essentially small RGB image blocks. In AlexNet's first layer, these local image templates perform convolution operations with input images.

Notably, regardless of whether the network is AlexNet, trained on ImageNet, or used for classification tasks, as long as the task setup is reasonable, most **convolutional neural networks** learn similar filters across different problems, datasets, and tasks.

These filters can typically be divided into two categories:

1. **Color-sensitive filters**, especially those detecting complementary colors. For example, one filter might detect green-red contrast, while others identify colored patches (such as pink-green combinations).
2. **Spatial structure detectors**, used to identify oriented edges in local image regions, such as vertical, horizontal, or diagonal edges.

Although we can directly visualize first-layer convolutional filters as images, visualization of higher-layer networks is more complex. This chart doesn't include detailed explanations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image55.png)

Higher layers of networks tend to learn **larger-scale spatial structures** from input images. In this visualization:

- Each row represents a filter in the learned network  
- Each column shows input image patches that strongly activate that filter  

The difference between this visualization and the previous slide is: it shows **local image blocks** that can trigger strong filter responses.

The sixth convolutional layer shows interesting patterns:  
- One filter seems to respond to **eye-like features**  
- Another reacts to **text components**  
- A third activates for **circular structures** or wheel-like features  

These patterns emerge spontaneously through **gradient descent** during training on large-scale datasets, without manual filter design. Visualization of higher-layer filters remains challenging and requires careful interpretation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image56.png)

The key question is whether we can reconstruct original images from filter responses. In fact, this can be achieved through **gradient descent**—this powerful technique we will explore in detail in subsequent lectures.

Another related question involves how filters achieve differentiation. This process relies on **random initialization**. At the beginning of training, each filter must be initialized with different random values. If symmetric initialization is used (i.e., all filters have identical initial states), identical gradients would be produced during backpropagation, preventing filters from learning diverse features. By breaking this symmetry through random initialization, filters can gradually evolve the ability to capture different patterns in data.

Ultimately, network designers need to determine both operator sequences and **channel architectures**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image57.png)

Questions about **neural network architecture design** will be further discussed in the next lecture. Specifically, we will explore why deeper network layers present larger-scale structural features.

This phenomenon is related to the concept of **receptive fields**, which will be explained in subsequent slides. As the course progresses, we will answer these core questions one by one.  

(Note: Retaining "receptive fields" professional terminology as direct translation, conforming to computer vision field common translation; "deeper layers visualize larger structures" uses paraphrasing, accurately conveying the original meaning through "呈现更大尺度的结构特征"; the entire paragraph achieves academic colloquialization through Chinese idiomatic expressions like "该内容", "逐一解答")

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image58.png)

An important consideration is how to view the **spatial dimensions** of these convolutional operations. Let's explore more deeply how spatial dimensions are calculated in convolution. In this example, we have a convolution image rotated 90 degrees, with channel dimensions omitted.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image59.png)

Now, we're dealing with channel dimensions, where spatial dimensions are 7×7. Here we examine an input with spatial size 7×7 and a 3×3 convolution kernel. The question is: what will be the output size? Through position calculation, we can find that since the filter can slide and fit 5 different positions, the output size will be **5×5**.

We can generalize this: if input width is \\(w\\) and convolutional filter width is \\(k\\), then output size is \\(w - k + 1\\). Through careful reasoning, you can verify the correctness of this formula.

But there's a **significant problem**: as convolution proceeds, the spatial size of feature maps gradually shrinks. Although some neural network architectures handle this problem, it may seem cumbersome. Usually, to simplify operations, we prefer to maintain consistency in spatial dimensions. For this purpose, we use a technique called padding.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image60.png)

To solve the problem of shrinking feature map sizes, padding is usually added to input data before applying convolutional operators—that is, padding zeros around the data. For example, when using padding \\(p=1\\), we add a ring of zero pixels around the input data, increasing output size by \\(2p\\).

Specifically, when \\(p=1\\), \\(3 \\times 3\\) convolution can maintain feature map dimensions unchanged. Although this method may introduce artifacts from a signal processing perspective, for simplicity of discussion, we focus here on **tensor dimension** issues.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image61.png)

However, we need to think about why we should **perform zero padding**. Does this cause problems? Indeed, it may introduce problems at boundaries, but in practice it usually works well.

A common configuration is to set **padding size** \\(p\\) to make **convolution kernel size** \\(k\\) odd, i.e., \\(p = \\frac{k - 1}{2}\\). This ensures that spatial dimensions remain unchanged after convolution.

Next, we will explore the concept of **receptive fields**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image62.png)

Someone asked why deeper networks can learn larger-scale structural features. This actually stems from the inherent design principles of convolution operations.

Each output of a single convolution can only detect local regions of input data. Therefore, outputs of the first convolutional layer can only perceive image regions matching the convolution kernel size.

But by stacking multiple convolutional layers, the network's receptive field expands in a cascading manner.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image63.png)

In this scenario, we study a network containing three convolutional layers. The activation values of the last layer depend on local regions of the previous layer, which in turn depend on local regions of the layer before that. **This dependency chain** means that although each convolution operation only acts on local neighborhoods, stacking multiple convolutional layers causes **effective receptive fields** (i.e., original input regions affecting downstream activations) to continuously expand.

Effective receptive fields grow linearly with the number of convolutional layers. However, since classification decisions at the network output require **global image information**, this brings a challenge: we must stack many convolutional layers to meet requirements. To solve this problem, we can accelerate the expansion of effective receptive fields by introducing techniques like **strided convolution**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image64.png)

Here we discuss the concept of strided convolution, where filters don't operate at every position of the image but skip certain positions. Instead of moving the receptive field one pixel each time, we slide with stride two.  

For example, assuming input is a \\(7 \\times 7\\) matrix, using a \\(3 \\times 3\\) convolution kernel with stride two, the output size will become \\(3 \\times 3\\).  

In general, given input width \\(W\\), filter size \\(K\\), padding \\(P\\), and stride \\(S\\), output size can be calculated by the following formula:  
\(\1\)  
Where \\(W - K\\) represents reduction due to convolution kernel size, \\(2P\\) is padding compensation, dividing by \\(S\\) reflects the **downsampling effect** brought by stride, and the final "+1" ensures correct boundary handling.  

The special value of strided convolution lies in its ability to implement image downsampling within neural networks. Each strided convolutional layer typically halves the spatial dimensions of feature maps. When multiple such structures are stacked, **effective receptive fields** grow exponentially with network depth.  

For example, stacking multiple stride-two convolutional layers (each halving feature map size) will cause receptive fields to expand exponentially. This property is crucial for implementing **hierarchical feature extraction** in deep convolutional networks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image65.png)

This means that with relatively few layers, we can build a **huge effective receptive field** sufficient to handle the entire input image.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image66.png)

Let's ensure clear understanding of convolution operations through an example. Suppose the input data volume has dimensions \\(3 \\times 32 \\times 32\\). We apply a **convolutional layer** containing 10 filters, each with size \\(5 \\times 5\\), stride 1, and padding 2. The output data volume dimensions will be \\(10 \\times 32 \\times 32\\).

**10** corresponds to the number of output channels, consistent with the number of filters. Spatial size is calculated through the aforementioned formula: after padding 2, the input spatial size maintains output spatial size at 32. This is consistent with previously observed patterns: for odd-sized convolution kernels (5 in this example), padding \\(k\\) (when kernel size is \\(2k + 1\\)) can maintain spatial dimensions unchanged.

The **learnable parameter count** for this layer is 760. Each filter contains \\(3 \\times 5 \\times 5\\) weights and 1 bias term, totaling 76 parameters. 10 filters total 760 parameters.

For **computational load** estimation: considering output data volume size \\(10 \\times 32 \\times 32\\) (about 10,000 elements). Each output element requires dot product operations between \\(3 \\times 5 \\times 5\\) filters and corresponding input regions, involving 75 multiply-add operations. Therefore, total computational load is approximately 768,000 floating-point operations.

In summary, convolution operations are implemented by applying filters to input data volumes, maintaining spatial dimensions through appropriate padding, with computational load proportional to output size and filter dimensions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image67.png)

I won't elaborate in detail at this moment; this section is prepared for your future reference. This subsection summarizes all **hyperparameters** and formulas related to convolutional layers. These concepts are all implemented in **PyTorch**—a widely used deep learning framework.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image68.png)

**Convolutional layers** include various hyperparameters we discussed. Additionally, there are other noteworthy hyperparameters, such as groups and dilation. Although dilation is rarely used today, groups still have occasional application scenarios. We might explore these topics in subsequent lectures. Additionally, there are other types of convolution operations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image69.png)

We discussed **two-dimensional convolution**, but this concept is not limited to two-dimensional images. We can also perform **one-dimensional convolution**, using filters with one degree of freedom to convolve one-dimensional signals. Similarly, **three-dimensional convolution** convolves three-dimensional signals with three-dimensional filters and performs sliding calculations in three-dimensional space.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image70.png)

This concludes our discussion of **convolution**. The final topic is the relatively simple **pooling**. Pooling layers are another method of downsampling in neural networks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image71.png)

**Strided convolution** is one method of downsampling in neural networks, and as networks deepen, it can more efficiently build receptive fields. However, convolution operations still have high computational costs, occupying most floating-point operations in convolutional networks. **Pooling layers** provide a computationally cheaper downsampling alternative.

In pooling layers, given a three-dimensional tensor (e.g., 64×112×112), we view it as a feature volume with spatial size 112×112 and 64 activation channels. Each channel is a 112×112 image. The processing flow includes: extracting each feature plane from the input tensor, performing downsampling independently, then restacking to generate output with the same number of channels but reduced spatial dimensions.

For example, a 64×224×224 input would be processed by extracting each 224×224 plane, performing downsampling and restacking, thereby maintaining channel count while changing spatial size. The specific method of downsampling is a **hyperparameter**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image72.png)

There are multiple implementation mechanisms for downsampling, among which max pooling is one of the most commonly used methods. In max pooling, we take a single depth slice and divide it into non-overlapping regions. For example, we can use \\(2 \\times 2\\) kernel size with stride 2 to divide input into non-overlapping \\(2 \\times 2\\) squares. Within each square, we select the maximum value (such as 6, 8, 3, or 4) to achieve spatial compression.

Adjustable **hyperparameters** include kernel size, stride, and downsampling function. Although max pooling is widely used, other methods like average pooling and anti-aliased downpooling are also adopted.

Pooling layers typically don't use padding.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image73.png)

Mathematically, it's not prohibited to use padding in pooling layers. However, for max pooling, when combined with ReLU activation functions, it appears redundant because both functions are similar. Usually pooling layers don't use padding, though I'm not sure if PyTorch provides padding parameter flags for pooling operations.

Stride is another architectural hyperparameter but is rarely deeply tuned. The most common pooling operations use two-fold downsampling, typically implemented through \\(2 \\times 2\\) windows with stride 2. Occasionally \\(4 \\times 4\\) windows with stride 2 are used, but precise two-fold downsampling remains the standard practice.

A **key consideration** is consistency of input image sizes. In the framework currently discussed, input images must maintain uniform sizes to avoid computational problems. Common solutions include: scaling images to the same size before batch processing, padding with zero or other values, or processing images with different aspect ratios separately.

In more advanced training configurations, aspect ratio bucketing techniques are sometimes adopted. This method groups training images by aspect ratio, ensuring that each forward-backward propagation batch has consistent resolution and aspect ratio. Different iterations may process images with different resolutions or aspect ratios, and this technique is common in large-scale production systems.

Pooling layers typically alternate with convolutional layers in CNN architectures, and this arrangement pattern has become a conventional paradigm in network design.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image74.png)

For example, you would observe a sequence of convolution, pooling, convolution, pooling operations, followed by fully connected layers. This represents a **typical convolutional network architecture**.

Regarding whether pooling introduces nonlinearity, the answer depends on specific pooling operations. **Max pooling** is inherently nonlinear, so in some networks, if max pooling is adopted, ReLU activation functions might not be needed after convolution. Conversely, **average pooling** is a linear operation, so using ReLU activation functions is still beneficial in such cases.

Here's a concise summary of pooling operations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image75.png)

**Hyperparameters** are essentially the same as those in convolution, with the addition of a pooling function as a downsampling mechanism.

Finally, I want to discuss the concept of **translation equivariance**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image76.png)

At the beginning of the lecture, I mentioned that we need **operators** that can **respect the spatial structure of images**. Flattening images into vectors cannot preserve this spatial structure. Both **convolution** and **pooling** have an interesting property that can formalize this concept—**translation equivariance**.  

Consider two different operation orders. First way: first perform convolution or pooling on the image, then translate the generated feature map; second way: first translate the image, then perform convolution or pooling. Notably, the results of these two operation orders are equivalent (ignoring boundary conditions), meaning that translating first then convolving has the same effect as convolving first then translating.  

This property is particularly evident in infinitely large images ignoring minor technical constraints. The interchangeability of spatial translation operations with downsampling or convolution operations reveals the core idea of image processing: extracted features should depend only on image content, not on their absolute spatial position.  

For example, whether objects appear on the left or right side of the image, they should be treated equally. This principle ensures consistency in pattern recognition (such as identifying people or benches), regardless of the specific position of objects in the frame.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image77.png)

This concept highlights a **key intuition** and structural property of images and the two-dimensional data we process. **Translation equivariance** mathematically captures how this structure is inherently embedded in these operators. Fascinatingly, as mentioned earlier, we can incorporate intuition about image processing through operator design rather than feature extraction methods.

A natural question is: why would we perform translation? Actually, we wouldn't. This is mainly a mathematical observation. It should be clarified that this operation is typically not implemented in neural networks. Although noting its effectiveness is interesting, it's not a practical component in network design.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image78.png)

For mathematicians, this is called a **commutative diagram**, which is a tool they particularly love.  

To summarize today's course content, we explored **convolutional networks** and their significance.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image79.png)

We discussed two new operators: **convolution** and **pooling**. In the next lecture, we will explore how to integrate them into **CNN architectures**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_5_image80.png)

See you next time.

