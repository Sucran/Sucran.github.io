---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 13: Generative Models 1"
date: 2025-09-11T13:30:18+08:00
draft: true
description: ""
---

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image1.png)

Welcome back to **CS231N Lecture 13**. Today we will explore **generative models**.

In the previous lecture, we introduced **self-supervised learning**, a fascinating paradigm for learning structure directly from unlabeled data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image2.png)

The typical implementation of **self-supervised learning**, as elaborated through numerous examples in the previous text, centers on utilizing large-scale unlabeled datasets—ideally containing only images. The advantage of this approach lies in the accessibility of image data.

The process first processes these images through an **encoder** to extract feature representations, then uses a **decoder** to make predictions based on these features.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image3.png)

The **core idea** of self-supervised learning lies in designing a pre-training task that requires no manual annotation or labels, enabling the entire system to train autonomously.

We explored various pre-training tasks, such as rotation prediction, which can be used to construct self-supervised learning objectives. This process typically involves two stages:

1. First, learn a self-supervised encoder-decoder structure on the pre-training task using all available data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image4.png)

Subsequently, you discard the decoder and replace it with a completely new, potentially smaller fully connected network. This network can be trained end-to-end or separately on tasks with limited labeled data. The **core idea** is that through self-supervised learning and proxy tasks, you can leverage massive amounts of unlabeled data—millions, hundreds of millions, or even billions of samples—without relying on high-quality manual annotation. During this process, the model will master general structural features of images or data that can be transferred to downstream tasks with limited labeled data.

The typical framework of self-supervised learning includes: pre-training on large-scale unlabeled images (such as billion-level samples obtained from the internet), then transferring the learned features to specific tasks containing only dozens, hundreds, or thousands of labeled samples. The **goal** is to improve the performance of these downstream tasks through general knowledge obtained from self-supervised proxy tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image5.png)

Last time we discussed several **pretext tasks**, such as rotation, rearrangement, and reconstruction. These tasks involve applying geometric perturbations to input pixels and requiring the model to recover from these disturbances.

In the **rotation** task, the model predicts the angle by which the image was rotated. The **rearrangement** task divides the image into several small blocks, and the model needs to predict their original arrangement, similar to a jigsaw puzzle. In the **reconstruction** task, parts of the input image are removed, and the model needs to fill them in completely, similar to image inpainting tasks.

These methods have proven quite effective.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image6.png)

Last class we discussed an alternative form of self-supervised learning—**contrastive learning**, which has proven very effective. Due to time constraints, some subsequent methods were not covered, so I will briefly review these at the beginning of today's lecture.

The **core idea** of contrastive learning lies in identifying similar and dissimilar data pairs. The goal is to minimize the distance between similar pairs while maximizing the distance between dissimilar pairs. In the context of self-supervised learning, this process typically starts from input images.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image7.png)

These are unlabeled images with no associated labels. For each input image, two random transformations need to be applied. For example, for a **cat image**, we cropped two local regions: the cat's face and the cat's back; for a **monkey image**, we cropped the facial region and converted it to black and white. In principle, at least two random perturbations need to be applied to each input image.

Subsequently, all perturbed input data is fed into a **feature extractor**—which can be a Vision Transformer (ViT), Convolutional Neural Network (CNN), or any neural network that can process images and output feature representations.

This method aims to achieve **contrastive learning**: two augmented versions from the same cat image should have similar feature vectors (as indicated by the green annotation). This requires computing a large similarity matrix of size \\((2N)^2 = 4N^2\\) (where \\(N\\) represents the number of original images). Since each image has two perturbed versions, the matrix dimension is \\(2N \times 2N\\), covering all augmented samples.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image8.png)

Currently, our goal is to cluster two augmented samples from the same original image together while separating augmented sample pairs from different original images. This process involves feeding all samples into a **feature extractor** and computing a scalar similarity matrix of size \\(4N^2\\) between feature vectors. The core lies in pulling similar vectors closer and pushing dissimilar vectors apart—this is the **core concept of contrastive learning**.

A few years ago, the groundbreaking paper *SimCLR* systematically integrated these concepts, successfully applying this method to self-supervised representation learning for images, which is the paper we discussed earlier. However, one limitation of the *SimCLR* framework is that it requires **large batch data** to achieve good convergence. When the number of samples is small, the network faces overly simple problems—for example, identifying similar cat images becomes too easy. To provide sufficient learning signals, large batch data must be used to ensure the model converges to meaningful features.

After achieving this goal, as mentioned in previous lectures, large-scale distributed training methods become key. Although this method is effective, it also raises questions about whether alternatives exist—that is, whether these requirements can be avoided. This has led to several other methods, which we will not delve into here.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image9.png)

I won't delve into the specific implementation principles of these methods, but rather focus on explaining their significance and overall goals. In the **MoCo (Momentum Contrast)** method of self-supervised learning, the framework is similar to **SimCLR**: data generates paired samples through augmentation, and after processing through feature encoders, the goal is to minimize the distance between similar sample pairs and maximize the distance between dissimilar sample pairs. The **key difference** is that this method doesn't need to process large batch data in each iteration.

To achieve this, the system maintains a queue containing negative samples from historical training iterations. In each iteration, the current data batch (query) is processed through the encoder network, and contrastive loss is calculated in the same way as SimCLR. Historical batches in the queue obtain feature representations through a **momentum encoder** and calculate similarity in the same way.

However, since the momentum encoder data scale is large and limited by GPU memory, the system doesn't perform backpropagation on it. The momentum encoder's weight updates don't use gradient descent but maintain an **exponential moving average** of the original encoder weights. The original encoder is still updated through conventional gradient descent, while the momentum encoder follows this moving average rule.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image10.png)

The standard process involves updating the **momentum encoder** by reducing current weights with a decay factor of 0.99 and incorporating 1% of the encoder weights. This enables the momentum encoder to maintain an exponential moving average of encoder weights. Although the exact theoretical basis for this method is not yet fully clear, **empirical evidence** strongly supports its effectiveness.

The advantage of this method is that it can learn **self-supervised representations** in each iteration without requiring extremely large batches of negative samples. This approach has proven effective, and multiple subsequent papers have further advanced this direction. Another notable method in this research line is called **DINO**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image11.png)

This concept is quite similar, adopting a **momentum encoder**—a dual standard encoder learned through gradient descent—similar to MoCo. However, the loss function is slightly different, using KL divergence loss instead of Softmax.

I mention this because you should know about the existence of **DINO v2**, even though we won't delve into its details, as it's a very efficient self-supervised feature extraction model widely used in current practice.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image12.png)

The **DINOv2** method is based on the DINOv1 framework, which has similarities to MoCo and incorporates ideas from SimCLR while introducing unique details. The **key breakthrough** of DINOv2 lies in significantly expanding the training data scale. Previous self-supervised methods typically trained only on the ImageNet dataset containing one million images, while DINOv2 successfully extended this method to a larger dataset of approximately 142 million images.

In deep learning, larger networks, more data, higher GPU utilization, and stronger computational power usually bring benefits. DINOv2 developed a **self-supervised learning method** that can effectively adapt to this large-scale dataset, generating robust self-supervised features. These features are widely used in practice for fine-tuning or supervision of downstream tasks. Although I won't delve into technical details, understanding this method is important for potential future projects.

Now let's turn to today's main topic: **generative models**. This field has made significant progress in deep learning, from limited functionality a decade ago to efficient solutions in recent years.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image13.png)

This has driven advances in technologies such as **language models**, which can be viewed as generative models. Various image and video generation models have emerged, from the low-resolution, blurry outputs I could only generate during my graduate studies to the amazing results achieved today. It's encouraging that researchers have persisted in improving and extending these technologies over the past decade, and now many models show remarkable effectiveness.

**Generative modeling** as a field in deep learning was not practically applicable when this course was first offered, so its current success is particularly exciting. However, the fundamental principles underlying generative models remain largely unchanged.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image14.png)

The fundamental mathematical principles on which data modeling methods are based have remained largely unchanged over the past decade. The **main progress** is reflected in computational power, more stable training methods, larger-scale datasets, distributed training capabilities, and scaling these components to apply to more practical scenarios.

Although there have indeed been algorithmic improvements—especially the **diffusion models** we will discuss in the next lecture—before delving into generative modeling, I want to first review the distinction between **supervised learning and unsupervised learning**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image15.png)

In the field of **deep learning**, the tasks we handle can be classified along multiple orthogonal dimensions. To clarify terminology concepts, let's first clarify these distinctions.

**Supervised learning** is the main teaching content of this semester (except for the last lecture). In this paradigm, we use datasets consisting of paired input data *X* and labels *Y*, with the goal of learning a mapping function from *X* to *Y*. We have encountered many typical application scenarios, such as:

- **Image classification**: *X* is an image, *Y* is a category label
- **Image caption generation**: *X* is an image, *Y* is a text description



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image16.png)

The output **\\(Y\\)** will be a text description of the input image. For **object detection** tasks, the input content is an image.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image17.png)

The output contains a set of bounding boxes and category labels used to describe objects present in the image. Or, it may involve **semantic segmentation**—assigning a label to each pixel in the input image. These tasks belong to the **supervised learning** category because their goal is to accurately predict what exists in the dataset. Essentially, the goal is to learn a function that can accurately map input \\(X\\) to output \\(Y\\) through training data and generalize this mapping to unseen samples.

In contrast, the definition of **unsupervised learning** is more ambiguous and difficult to define.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image18.png)

The concept of **unsupervised learning** (or self-supervised learning) involves processing unlabeled data. In this scenario, you only have samples (such as images) without any associated labels, and the goal is to discover potential structures or patterns in the data. Unlike supervised learning, unsupervised learning has no specific target task; the core lies in learning meaningful representations that can subsequently be applied to downstream tasks.

Typical examples of unsupervised learning include **k-means clustering**—the purpose of this method is to identify clustering structures in data. Even without explicit labels, we can still extract structural information from raw pixels.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image19.png)

Another method is to adopt **dimensionality reduction** techniques (such as Principal Component Analysis PCA), aiming to reveal low-dimensional subspaces or manifolds that can capture the underlying structure of data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image20.png)

This is a **concept** we aim to reveal directly from data because we lack annotations with clear expected results. Or, we can also focus on **density estimation**, trying to fit probability distributions to data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image21.png)

Our goal is to understand the **probability function** that generates observed data samples. Since we lack explicit labels or training sets, we try to reveal hidden or latent structures through the training process.

The distinction between **supervised learning and unsupervised learning** is crucial. Unsupervised learning is not necessarily probabilistic or generative—methods such as clustering or Principal Component Analysis (PCA), although often interpretable from a probabilistic perspective, represent unsupervised techniques that may not inherently involve generative or probabilistic frameworks.

I think the supervised vs. unsupervised dichotomy is more like a continuous spectrum where various methods or systems can be positioned. Another independent spectrum classifies systems or tasks as **generative models vs. discriminative models**, which are inherently probabilistic.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image22.png)

When discussing **generative** or **discriminative** models, we focus on the probabilistic structure to be revealed or learned in data. The **core difference** lies in the probabilistic relationships between the variables being modeled.

Discriminative models typically handle high-dimensional input \\(X\\) (such as images) and labels/auxiliary information \\(Y\\) (such as descriptive text or category labels). At this point, we learn the conditional probability distribution of \\(Y\\) given \\(X\\), denoted as \\(P(Y|X)\\).

To understand the probabilistic foundation, remember that probability distributions are normalized. The density function \\(P(X)\\) assigns non-negative values to each possible \\(X\\) and satisfies the constraint that the integral over all \\(X\\) equals 1. This normalization means that all \\(X\\) need to compete for fixed probability mass units. Increasing the probability of some \\(X\\) necessarily leads to a decrease in the probability of other \\(X\\), forming an inherent competition mechanism.

The structural differences of probabilistic models depend on which variables participate in the competition for probability mass. Although mathematical notation may be similar, the competition mechanism will lead to different learning objectives and model behaviors.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image23.png)

For **discriminative models**, we learn a probabilistic model of \\(Y\\) given \\(X\\). This means that for each \\(X\\), our model predicts a probability distribution over all possible labels.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image24.png)

If our labels are discrete and categorical, such as **"cat"** or **"dog"**, then the sum of the probability distribution must be 1. For each input \\(X\\), there exists an independent probability distribution over labels.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image25.png)

The **key point** is that there is no competition for probability mass between images, because each image generates its own distribution over the label space. Competition only occurs between different labels for each image. This is a **core characteristic** of discriminative modeling.

Another important characteristic of discriminative models is that they cannot reject unreasonable inputs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image26.png)

Once we define the label space (such as **cat** and **dog** in this example), when the system encounters inputs beyond this vocabulary (such as monkeys or abstract art), it lacks flexibility. It cannot determine that such inputs are unreasonable and must output a probability distribution based on predefined labels.

This limitation highlights the importance of understanding **probabilistic modeling** for diverse data types. In contrast, generative models learn the data distribution \\( p(x) \\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image27.png)

Our goal is to learn the distribution of all possible images \\(x\\). This is a **profound challenge** because it means that every conceivable image in the universe is competing for probability mass. Although the problem may seem simple at first glance, it requires us to face deep philosophical questions about the nature of reality. For example, how should we allocate probability mass between images of three-legged dogs and three-armed monkeys?

Intuitively, three-legged dogs might deserve higher probability mass allocation because this phenomenon is biologically possible, while three-armed monkeys are extremely rare unless in a science fiction context.

Under this framework, the model must **carefully consider** the underlying structure of data, which significantly complicates the problem. The **key advantage** of generative models is that they can reject unreasonable inputs by assigning low probability or zero probability mass to certain images. For example, if a model is trained to generate zoo animals, it should assign zero probability to abstract art, effectively excluding it from consideration.

Conditional generative models further introduce fine control by learning the conditional distribution of images \\(x\\) given label signals \\(y\\). This adds an additional layer of control and specificity to the generation process.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image28.png)

This means that for each possible label, we will trigger a competition among all potential images. For example, if **\\(Y\\)** is a categorical label (such as "cat" or "dog"), the model will induce competition among all possible images for each label separately.

In the upper distribution, images conditioned on the "cat" label will assign high probability to cat images, medium probability to other mammals like monkeys or dogs, and very low or zero probability to abstract artworks. When the condition changes to the "dog" label, a completely different probability distribution will be generated.

When the **conditional signal** \\(Y\\) is richer than a single categorical label (possibly text descriptions, paragraphs, or even another image with captions), the situation becomes particularly interesting. To model such a rich output space \\(X\\) and condition on a complex input space \\(Y\\), the model needs to solve a highly complex and often ill-defined problem, requiring **deep reasoning** about relevant objects.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image29.png)

Generative modeling is a fascinating topic because it seems simple but hides complexity. At first glance, it only involves the operation of **exchanging X and Y variables**, but this approach forces us to think deeply about the complexity of the visual world.

Notably, we can explicitly divide models into three types: **discriminative models**, **generative models**, and **conditional generative models**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image30.png)

All these models are interconnected through **Bayes' theorem**, one of the most remarkable relationships in probability theory. Specifically, given a discriminative model \\( P(Y|X) \\), an unconditional generative model \\( P(X) \\), and the prior distribution of labels \\( Y \\), we can construct a conditional generative model \\( P(Y|X) \\). More generally, as long as we master two of these models, Bayes' theorem can derive the third. Although this is theoretically feasible, in practice conditional generative models usually need to be trained from scratch. However, as we will discuss in diffusion models, in some cases conditional and unconditional models can be trained jointly.

This highlights the profound connections between probabilistic models. Now let's explore their application scenarios: **Discriminative models** have the most intuitive uses—they assign labels to data and facilitate feature learning. For example, in supervised learning tasks like ImageNet classification, models learn useful feature representations by predicting category labels, which can be transferred to downstream tasks. Therefore, discriminative models are mainly used for direct prediction or feature extraction.

**Unconditional generative models** are typically less practical. They can be used for anomaly detection by identifying images with low probability density, while providing feature learning capabilities without labeled data—because the process of fitting \\( P(X) \\) may produce effective representations. However, these models have not been successful in the field of self-supervised learning, where contrastive learning methods are more effective. Theoretically, such models can also generate new samples \\( X \\), but this is not their main use.



However, I think **unconditional generative models** have certain limitations in practical applications because they cannot control the content of generated samples. Although sampling from such models can produce new images, their content is completely unpredictable. Although studying such models from a mathematical perspective is quite interesting, their practical value is relatively limited.

In contrast, **conditional generative models** are much more practical and widely applicable. Such models can theoretically perform classification and reject outliers by evaluating \\( P(X|Y) \\) under all possible labels \\( Y \\)—although in practice this method of rejecting low-probability samples is rarely adopted.

The real power of conditional generative models lies in **controllable generation**. By given labels \\( Y \\) (such as text prompts), these models can generate new samples that meet specific requirements. For example, given the prompt *"a cat wearing a hot dog-flavored T-shirt on the moon"*, an image generation model can output corresponding new images \\( X \\). This capability is precisely the most exciting and valuable part of generative modeling.

Notably, the literature often mixes unconditional and conditional generative models under the general term **"generative models"**, which can easily cause confusion.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image31.png)

Many papers omit the conditional signal to simplify mathematical expressions. However, **unconditional generative modeling** is rarely used in practice; **conditional generative modeling** is usually more practical. When reading papers or discussing generative models, it's important to note that researchers often focus on conditional generative models, even if the symbolic representation doesn't explicitly reflect this.

What are the inputs and outputs of an unconditional generative model?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image32.png)

I didn't explicitly mention earlier that **parameterization** methods can vary significantly depending on the specific formulation. There are various ways to construct such models, and accordingly, the inputs and outputs of neural networks will also vary. We will explore the **classification system** of these variants in the following slides.

Now, let's discuss the **motivation** behind generative models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image33.png)

The main motivation for building **generative models** stems from the inherent ambiguity of tasks themselves. The advantage of **probabilistic models** (such as \\(P(X|Y)\\)) lies in their ability to capture uncertainty—given input \\(Y\\), there may be an entire possible output space \\(X\\).

Although some tasks involve deterministic mappings (for example, counting cats in an image will yield a unique answer), more scenarios are subtle. For example, when generating images of "dogs wearing hot dog hats", due to the inherent uncertainty in the query itself, a large number of valid outputs will be generated. Generative models excel in such scenarios by modeling the complete distribution of all possible outputs under the condition of input signals.

This capability explains why they have been widely adopted in recent years. A typical example is **language modeling**, which aims to predict output text \\(X\\) from input text \\(Y\\) (note that variable symbols are reversed here for clarity). Applications like ChatGPT fully demonstrate the powerful capability of generative models in handling ambiguous, open-ended tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image34.png)

Here's an example from ChatGPT. The input content is: "Write me a short rhyming poem about generative models." Amazingly, it actually did it—this wasn't possible when we first taught this course. I won't read it aloud, it might be a bit awkward, but you can see for yourself.

This is a **conditional generative model**. There are many possibilities for rhyming poems about generative models, and the model just chose one. The advantage of **generative models** is that they can model the entire distribution of possible outputs based on input conditions.

Another example is **text-to-image generation**, such as: "Generate an image of a person standing in front of a whiteboard teaching a generative models course."



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image35.png)

You observe an example from your own perspective, while ChatGPT provides another different example. In fact, there exists a complete space of possibilities, where images may correspond to the input text. **Generative models** allow you to represent this space and sample from it as needed.

Similarly, take **image-to-video generation** as an example. Suppose you input an image—such as me holding AirPods suspended above a cardboard box—the model can predict subsequent actions: dropping them, moving my hand, or even transforming the AirPods into different versions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image36.png)

Generative models can model and sample potential outcomes, which is precisely their **value**. When there is uncertainty in the output, generative models can provide solutions.

This field covers a wide range, including various methods and application scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image37.png)

This is an surprisingly mathematical field in **deep learning** because it involves modeling probability distributions and constructing loss functions to achieve expected results. Therefore, research papers in this field typically contain a large amount of mathematical symbols and equations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image38.png)

Understanding these equations requires careful consideration. This subfield involves more **mathematical** content, which I find quite fascinating.

There is a **classification system** for generative models. One branch consists of explicit density methods.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image39.png)

In generative modeling, our goal is to model \\(P(X)\\) or \\(P(X|Y)\\). **Explicit density methods** allow computing the \\(P(X)\\) value for any sample \\(X\\), while **implicit density methods** don't directly provide access to density values but support sampling from the underlying distribution.

The key difference is: implicit models can still implicitly learn representations of density functions even if they cannot access precise density values; conversely, explicit density methods can usually directly compute \\(P(X)\\), although sampling may be more complex in some cases.

Implicit models are particularly suitable when the core goal is to generate high-quality, diverse samples rather than precisely evaluating density.

In explicit density methods, **autoregressive models** can compute true \\(P(X)\\), while **Variational Autoencoders (VAE)** provide approximations.

In implicit methods, **Generative Adversarial Networks (GAN)** and other direct methods can sample through single network evaluation; indirect methods require iterative processes to sample from \\(P(X)\\), lacking feedforward direct sampling mechanisms.

This classification system helps categorize generative models based on density estimation and sampling methods.



To sample from the underlying density being modeled, iterative methods must be adopted. **Diffusion models** are typical representatives of this approach, which we will discuss in detail in the next lecture.

I mentioned earlier that symbolic representations are often used arbitrarily, and **Y** is frequently omitted. I specifically demonstrated this in the current slide to trigger discussion and strengthen everyone's awareness of this issue.

In fact, in this lecture, wherever **P(X)** appears on slides and subsequent pages, Y is omitted for brevity. But you should always be aware that in all cases P(X) implicitly implies conditioning on Y.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image40.png)

Thank you for your question. The question is whether **indirect methods** can be treated as black boxes and used as direct sampling methods. Theoretically yes, but in practice no, because the final samples obtained are approximations.

For example, in **diffusion models**, extracting true samples requires infinite steps. We actually approximate this process with finite steps. Other methods like **Markov chains** or **MCMC methods** are also like this—although using iterative procedures, precise sampling requires infinite steps to converge. Therefore we always approximate with finite steps.

One thing I particularly appreciate about this classification system is its symmetry. It has four terminal nodes and two branches, and today we'll explain half of it first, completing the rest next time. This forms a clear structured decomposition.

The difference between **approximate density** and direct sampling from implicit \\(P(X)\\) is: indirect but implicit methods cannot compute density values but can still perform iterative sampling; while approximate density methods can obtain density values that approximate or bound the true \\(P(X)\\).

The first type of **generative model** we will specifically discuss is **autoregressive models**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image41.png)

Autoregressive models require us to first discuss a fundamental concept in generative modeling: **maximum likelihood estimation**. This is a general method for fitting probabilistic models given a finite set of samples.

This method involves using neural networks to define an explicit function for density. The network takes data \\(X\\) and weights \\(W\\) as inputs and outputs a value representing density.

Given a sample dataset \\(\\{X_1, X_2, \dots, X_n\\}\\), we train the model by optimizing this objective function.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image42.png)

Our goal is to find **weights** that can maximize the **likelihood** of the dataset. As weights are adjusted, the network models different density distributions, and our task is to choose the density distribution that maximizes data likelihood.

Note the distinction between **likelihood** and **probability**: probability examines the variation of data points \\(X\\) under the premise of fixed density distribution, while likelihood fixes sample \\(X\\) to adjust the distribution. Understanding which are fixed and which are variable in the equation is key to grasping this distinction.

In **maximum likelihood estimation**, we maximize the probability of fixed training samples by adjusting the distribution modeled by neural networks. Here there's an implicit premise—observed data is generated by some potential true probability distribution \\(p_{\text{data}}\\). Our goal is to model this unobservable \\(p_{\text{data}}\\), and we can only infer this distribution through the learning process using finite samples drawn from \\(p_{\text{data}}\\).

The maximum likelihood objective function will choose the distribution that makes observed data most likely to appear. The standard assumption is that data satisfies **independent and identically distributed (IID)**, meaning each sample \\(X\\) comes from \\(p_{\text{data}}\\). We ultimately want to maximize the joint distribution of all observed data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image43.png)

Since samples are independent of each other, we can decompose the joint probability into the product of likelihood functions for each sample. Usually the **logarithmic transformation** technique is adopted—because logarithmic functions are monotonic, maximizing some quantity is equivalent to maximizing its logarithm. Additionally, logarithmic operations can convert products to sums, simplifying expressions.

We don't directly maximize the data likelihood function, but maximize the **log-likelihood function**, which maintains the optimization objective unchanged. After logarithmic transformation converts products to sums, the problem becomes more manageable. Here we introduce neural networks, which can directly output probability density. This provides a clear objective function for network training, thus defining a clear loss function for generative modeling tasks.

But to proceed further, more structural support is needed. **Maximum likelihood estimation** is a broad framework, and practical applications usually require additional constraints or assumptions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image44.png)

Autoregressive models themselves don't make any specific structural assumptions about data. However, to make progress, we usually need to impose some structure. **The basic assumption of such models is**: each data sample \\(x\\) can be decomposed in a canonical way into a series of sub-parts, such as \\(x_1, x_2, \ldots, x_n\\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image45.png)

When handling indices, precision must be maintained. Here **subscripts** represent sub-parts of individual samples, while **superscripts** in previous slides represent different samples (from \\(x^1\\) to \\(x^n\\)).

We adopt standard methods to decompose data samples \\(x\\) into sub-part sequences (\\(x_1\\) to \\(x_t\\)). Applying the probability chain rule, the joint probability of \\(x\\) can be expressed as:

\\(P(x) = P(x_1) \cdot P(x_2|x_1) \cdot P(x_3|x_1, x_2) \cdots P(x_t|x_1, \dots, x_{t-1})\\)

This decomposition is universally applicable to any joint distribution of random variables.

This formulation naturally leads to the construction of **objective functions**—training neural networks to predict the probability distribution of the next part of the sequence (conditioned on previous parts). This approach is reminiscent of **Recurrent Neural Networks (RNN)**, which essentially model sequence dependencies by passing hidden states over time, ensuring each state depends on the complete previous sequence.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image46.png)

A natural application of **RNN** is autoregressive modeling. The hidden state sequence can summarize information from the input sequence. Starting from each hidden state, we can predict the probability distribution of the next element in the sequence, conditioned on all previous elements.

As discussed in previous lectures, this constitutes **RNN language models**. **Transformers** also have this capability.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image47.png)

In the Transformer course, masked Transformers were discussed. By appropriately masking the attention matrix, each Transformer output can depend only on previous sequence segments, making Transformers very suitable for **autoregressive modeling**—a common application scenario.

However, autoregressive modeling requires data to be organized in sequence form, which naturally fits text data because text is inherently a **one-dimensional discrete sequence**. Modeling discrete probability distributions is relatively simple, as shown by the cross-entropy softmax loss function used throughout the semester. This loss function operates on fixed discrete category sets, assigns scores to each category, normalizes through softmax, and optimizes with cross-entropy.

**Language models** benefit from this fit because language is inherently discrete and sequential. Although tokenization brings some complexity, the overall adaptation is still natural. In contrast, images face challenges: they lack inherent one-dimensional structure and are usually continuous values. Despite this, autoregressive models have been applied to images, although early methods were naive.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image48.png)

One method for autoregressive modeling of images is to treat images as pixel sequences. Each pixel contains three discrete values, typically represented as 8-bit integers in the range 0-255 for each channel in formats like JPEG or PNG.

We can rasterize images into one-dimensional sequences where each element corresponds to a sub-pixel value. This enables us to directly apply **autoregressive modeling** to this sequence, similar to using RNN or Transformer for language modeling.

However, this method faces significant computational challenges. For example, 1024×1024 resolution images would produce sequences of 3 million sub-pixels. Although modern systems can handle sequences of this length, computational costs become prohibitive. Early attempts to directly apply autoregressive models to pixels were limited in success due to scalability issues with high-resolution images.

The latest advances we will discuss in the next lecture don't represent images as raw pixel sequences, but as higher-level **token** sequences. This approach has injected new vitality into autoregressive modeling for image generation.

This discussion outlines autoregressive models—their probabilistic formulation and applications in language and images. Next, we will study **Variational Autoencoders**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image49.png)

Variational Autoencoders are really quite fascinating.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image50.png)

In autoregressive models, we discussed the **maximum likelihood estimation** method, which maximizes likelihood probability by decomposing data into sequence parts. **Variational Autoencoders (VAE)** adopt a different approach: while still using explicit methods with computable density, this density function is difficult to solve precisely and must be approximated.

Why abandon methods that can compute density precisely? The key lies in the fact that through this trade-off, we can extract **latent vectors** with practical meaning from data. These vectors naturally form during the learning process and exhibit independent application value. The ability to obtain such latent vectors enables us to accept approximate density (i.e., lower bounds of true density) as a compromise.

The motivation for autoregressive models adopting sequence decomposition essentially stems from the need for problem decomposability.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image51.png)

Modeling each part separately can simplify the task. Taking language modeling with vocabulary size \\(V\\) as an example, to model the joint probability of two words, there are \\(V^2\\) possible sequence combinations; three words correspond to \\(V^3\\) combinations. Generally, for sequences containing \\(T\\) words, there are \\(V^T\\) possible combinations.

This **exponential growth** makes directly modeling joint distributions of sequences containing \\(T\\) elements impractical, because the required discrete probability distributions grow exponentially with sequence length.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image52.png)

As sequence length increases, modeling it becomes intractable. To solve this problem, we decompose the task through conditional prediction based on previous segments.

Regarding the **logarithmic trick** question: in practice we rarely deal with raw probability density values directly. For numerical stability considerations, models usually output log probabilities, and all calculations (including loss functions) are performed in log space.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image53.png)

The generation of probability **\\(P(X)\\)** stems from the Transformer outputting the probability distribution of the next token at each step based on all previous tokens. By multiplying these probabilities across the entire sequence, we can recover precise probability density values.

For a given input sequence, the Transformer will predict the distribution of all possible tokens at each position based on previous tokens. Subsequently we can calculate the predicted probability of the actual next token and multiply these probabilities across the entire sequence.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image54.png)

This is how we recover **precise density values** from autoregressive models, which applies equally to RNN and Transformer architectures.

In Variational Autoencoders, the situation becomes more complex.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image55.png)

We will temporarily set aside the **"V"** part and focus on autoencoders first, because this course hasn't covered this content yet.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image56.png)

In **non-variational autoencoders**, this is an unsupervised learning method for learning to extract features \\(z\\) from unlabeled input data \\(x\\). This aligns with the **self-supervised learning** concepts we recently discussed.

These features should capture meaningful information in data, such as object identity, quantity, or color in images. The feature vector \\(z\\) should encapsulate effective information about \\(x\\).

The encoder can be implemented using any **neural network architecture**—MLP, Transformer, CNN, or other architectures. It processes input data \\(x\\) and outputs vector \\(z\\). The key challenge is learning this mapping relationship without labels.

We explored several examples in the previous lecture, where the simplest method is input reconstruction.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image57.png)

Next, we will introduce the second part of the model—the **decoder**. The decoder takes latent variable \\(z\\) as input and reconstructs output \\(x\\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image58.png)

We will train the model so that its output matches the input. This seems simple because we're essentially training the model to mimic the identity function—a function we already know. Why spend computational resources learning such basic content? **The key lies in introducing bottleneck structure.**

If the model has unlimited capacity—for example, the latent vector **z** is very wide and unconstrained—neural networks can easily solve this problem. However, our goal is not to learn the identity function itself (which would be redundant), but to force the network to learn the identity function under specific constraints.

In traditional autoencoders, this constraint is achieved by limiting the capacity of representation **z**. Specifically, the latent vector **z** is designed to be much smaller than input **x**. For example, input **x** might be a high-resolution image (such as 1024x1024 pixels, represented by 3 million floating-point numbers), while **z** might be a 128-dimensional latent encoding.

This bottleneck structure forces the model to compress data through narrow intermediate representations while reconstructing input data **x**. We assume this compression will prompt the model to learn meaningful, non-trivial structures in data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image59.png)

After completing this step, we can adopt standard **self-supervised learning** methods—discard the decoder and use latent representations \\(z\\) to initialize supervised models for downstream tasks, similar to the self-supervised frameworks we discussed earlier.

But what if our goal is to use this model for **data generation**?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image60.png)

To achieve the opposite effect of self-supervised methods, our goal is to discard the encoder and instead sample latent variables \\( z \\) aligned with the data representations learned by the model. If we can sample \\( z \\) from a distribution matching the data distribution, we can input it into the trained decoder to generate new samples. **This implicit method avoids explicit density modeling but transfers the challenge to the latent space sampling stage.**

The core problem still exists: generating \\( x \\) from the dataset of \\( x \\) requires sampling \\( z \\), and this process hasn't been simplified. **Variational Autoencoders** solve this problem by imposing structural constraints on \\( z \\). Unlike traditional autoencoders (which reconstruct data without latent variable constraints), Variational Autoencoders force latent variables to follow probabilistic structures (such as Gaussian distributions). This enables sampling from known distributions during inference, thus achieving data generation through decoders. Therefore, Variational Autoencoders simplify the sampling process by probabilistically constructing latent space structures.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image61.png)

The term **"variational"** has a rich history in the literature. **Variational Autoencoders (VAEs)** introduce probabilistic methods to traditional autoencoders. They learn latent features \\(z\\) from original data while forcing the latent space to have structure, enabling generation of new samples through sampling during inference.

Specifically, we assume training data \\(x^i\\) (superscript \\(i\\) represents independent samples) is generated by latent vectors \\(z^i\\). The data generation process first generates \\(z^i\\), then generates \\(x^i\\) based on \\(z^i\\). Although these latent vectors are unobservable, all information needed to generate images is contained in \\(z\\). Here \\(x\\) represents images, while \\(z\\) encapsulates their complete latent feature representation.

The **key constraint** is that \\(z\\) must follow a known distribution (usually a unit Gaussian distribution). After training is complete, we can generate samples by sampling \\(z\\) from this distribution and feeding it into the decoder.

Since \\(z\\) is unobservable, training faces challenges. If we simultaneously have \\(x\\) and \\(z\\), we can use **maximum likelihood estimation** with logarithmic probability tricks to train the conditional generative model \\(p(x|z)\\). In the absence of \\(z\\), we consider marginalization: expressing \\(p(x)\\) through the joint distribution \\(p(x,z) = p(x|z)p(z)\\) and integrating over \\(z\\). This method enables us to indirectly achieve maximum likelihood estimation.



The meaning of the term **\\(p(x|z)\\)** is intuitive—we can compute it through the decoder neural network to be trained on the left. The prior distribution **\\(p(z)\\)** is also easy to handle because we assume it follows a unit Gaussian distribution or other simple distributions that can be computed/analyzed.

However, this integral term constitutes a major challenge. Generally speaking, integrating over the entire input space of neural networks is infeasible. The likelihood function \\(p(x|z)\\) modeled by neural networks is extremely complex, making precise analytical integration impossible.

The **core idea** of probabilistic modeling is to express various terms in probabilistic form. Some terms will be simple distributions that can be analytically described, while others are neural network components that need to be learned.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image62.png)

We assume that under the condition of given \\(z\\), the probability of \\(x\\) can be modeled by a **neural network**, which theoretically can be learned through **maximum likelihood estimation**. However, when defining the objective of learning this neural network through maximum likelihood, we face a challenge: integrating over \\(z\\) is infeasible.

Although someone might try to approximate this integral through finite sampling, due to the high-dimensional nature of the latent space \\(z\\), this method usually doesn't work well.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image63.png)

Trying to perform approximate numerical integration in training loops is not advisable. We can instead adopt fundamental tools from probability theory—**Bayes' theorem**. Through Bayes' theorem, we can express \\(P(x)\\) using the equation shown on screen.

Analyzing the components:
- \\(P(x|z)\\) can be computed through the decoder
- \\(P(z)\\) is assumed to follow a Gaussian distribution, so it can be computed without integration

But we encounter challenges when handling the **posterior probability** \\(P(z|x)\\) because it requires integration operations and cannot be directly solved.

The solution of **Variational Autoencoders** is to introduce a second neural network \\(Q\\) with parameters \\(\phi\\). This network learns to approximate the conditional distribution \\(Q(z|x)\\) to estimate the true posterior \\(P(z|x)\\). Although perfect approximation cannot be guaranteed, this method achieves likelihood computation and maximum likelihood training, constituting the core mechanism of Variational Autoencoder optimization.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image64.png)

We will jointly learn two neural networks: **decoder** and **encoder**. The decoder takes latent encoding \\(z\\) as input and outputs the distribution of data \\(x\\); the encoder takes data \\(x\\) as input and outputs the distribution of latent encoding \\(z\\). Both networks are trained independently with different weight parameters.

A natural question is: how can neural networks output probability distributions? The solution is to constrain the output to be a normal distribution and have the network predict its parameters. For the decoder, we assume the output distribution is a diagonal Gaussian distribution, where the mean is predicted by the network and the variance \\(\sigma^2\\) is fixed.

For the encoder, the network receives data samples \\(x\\) and outputs parameters of the Gaussian distribution \\(q(z|x)\\). Specifically, it predicts two vectors: the mean \\(\mu_{z|x}\\) and diagonal elements of the covariance matrix \\(\Sigma_{z|x}\\). Using diagonal structure is crucial—if modeling the complete covariance matrix, images of \\(h \times w\\) size would require \\(h^2\\) parameters. By ignoring correlations, diagonal covariance can be simplified to vectors of the same dimension as \\(z\\).

Therefore, the neural network outputs two vectors of the same dimension as \\(z\\) to parameterize the Gaussian distribution. This method achieves **maximum likelihood training** (using fixed standard deviation, equivalent to L2 loss). If modeling variance for individual pixels in the decoder would be impractical, as this both ignores pixel correlations and only allows tiny per-pixel variations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image65.png)

The degree of variation for each pixel depends on the pixel itself. Sampling from this distribution requires fixing the mean and adding independent noise scaled by per-pixel variance. However, this method is usually **not reasonable**.

For the decoder, we treat the output as a probability distribution, but in practice we never perform sampling. Instead, we always output the **mean**.

When expressed mathematically, the constant \\(\sigma^2\\) appears as the dominant term. Maximizing the log-likelihood of a Gaussian distribution with fixed diagonal variance is equivalent to minimizing the **\\(L_2\\) distance** between the mean and \\(x\\), which is a useful property.

Regarding pixel translation invariance, this is a property determined by **neural network architecture**. Invariance or equivariance can be achieved through architectural design, but this is not solved at the loss function level.

In summary, we have an **encoder** and a **decoder**: the encoder takes \\(x\\) as input and outputs a distribution over \\(z\\), while the decoder reconstructs data from \\(z\\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image66.png)

Another input is **z**, representing a distribution over **x**. What is our training objective?

This slide involves some mathematical formulas. Essentially, the core idea is to perform **maximum likelihood estimation**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image67.png)

The main goal of generative modeling is to maximize \\(\log p(x)\\). According to **Bayes' rule**, this can be equivalently expressed as \\(\log p(x) = \log \left( \frac{p(x|z)p(z)}{p(z|x)} \right)\\).

Next, we introduce the neural network \\(q(z|x)\\) to model the distribution \\(q(z|x)\\), and multiply both numerator and denominator of the Bayes' rule expression by \\(q(z|x)\\).

Using logarithmic properties, we rearrange the terms into three different components (color-coded for clarity):

1. \\(\mathbb{E}_{z \sim q(z|x)} \left[ \log p(x|z) \right]\\)
2. \\(-D_{KL}(q(z|x) \| p(z))\\)
3. \\(D_{KL}(q(z|x) \| p(z|x))\\)

This decomposition yields the **Evidence Lower Bound (ELBO)**—a core concept in variational inference. The first term represents reconstruction likelihood, the second term is the KL divergence between the approximate posterior and prior, and the third term measures the difference between the approximate posterior and true posterior.

ELBO provides an optimizable lower bound for the log-likelihood \\(\log p(x)\\), enabling efficient optimization of generative models like Variational Autoencoders.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image68.png)

Now, we make another key observation: \\(p(x)\\) doesn't depend on \\(z\\). The three terms shown here constitute an exact equivalence relationship. Although \\(z\\) appears in the expression, it will eventually cancel out, making the expression independent of \\(z\\). Therefore, we can introduce expectations about \\(z\\) for any distribution, because the inner terms are not affected by \\(z\\).

Since expectation is a linear operator, we can distribute it to each of the three terms. Although these terms may seem obscure at first glance, those familiar with probability theory will recognize them. The first term remains unchanged, while the latter two are identified as **KL divergence** terms. KL divergence is used to quantify differences between probability distributions, and these terms fully conform to its definition.

Therefore, we can rewrite the expression as the initial expectation term plus two KL divergence terms. These KL terms measure differences between the various probability distributions involved.

Analyzing term by term can reveal its interpretable structure:

1. **Data reconstruction term**: This term involves sampling \\(z\\) from the encoder-predicted distribution \\(q(z|x)\\), then computing the expectation of \\(\log p(x|z)\\). It ensures that when we encode \\(x\\) into \\(z\\) and decode it back, we can reconstruct the original data point \\(x\\).
2. **Prior term**: This KL divergence measures the difference between the encoder distribution \\(q(z|x)\\) and the prior distribution \\(p(z)\\). It encourages the latent space to conform to the specified prior distribution.

This decomposition clearly shows the objective function of Variational Autoencoders, achieving a balance between data reconstruction and latent space regularization.



Recall that \\(q(z|x)\\) represents the **encoder**, which receives input data \\(x\\) and outputs a distribution over latent space \\(z\\). This is the predicted distribution over the latent space. The term \\(p(z)\\) represents the **prior**, usually assumed to be a diagonal Gaussian distribution over the latent space. This term ensures that the predicted distribution \\(q(z|x)\\) remains consistent with the simple Gaussian prior we previously set. Essentially, it measures how well the latent space learned by the model matches the prior.

The third term \\(q(z|x)\\) brings challenges. It represents the encoder's predicted distribution of \\(z\\) given input data \\(x\\), and we want to compare it with \\(p(z|x)\\). However, computing this term is problematic because \\(p(z|x)\\) is precisely what initially prompted us to introduce \\(q\\)—we cannot directly compute \\(p(z|x)\\).

Fortunately, we can ignore this term. **KL divergence** is always non-negative, so although we usually cannot compute these distributions, we know this term must be greater than or equal to zero. By ignoring it, we get a lower bound of the true probability. Therefore, we have \\(\log p(x) \geq \text{reconstruction term} + \text{prior term}\\). This becomes the **loss function** for training Variational Autoencoders.

This lower bound is an approximation of the log true likelihood. By maximizing this lower bound, we hope to indirectly maximize the true log likelihood, although the optimization process is not precise. This constitutes the **training objective** of Variational Autoencoders.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image69.png)

We jointly train an encoder **\\(q\\)** and decoder **\\(p\\)** to maximize the variational lower bound of the true data log-likelihood, also known as the **Evidence Lower Bound (ELBO)**. This objective aims to maximize ELBO, which involves specific terms related to encoder and decoder networks.

To clearly outline the training process, we adopt a neural network encoder that receives input **\\(x\\)** and outputs a distribution over **\\(z\\)**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image70.png)

We will apply the **KL divergence term** on the predicted distribution, forcing it to approximate a unit Gaussian distribution. Specifically, this will encourage the predicted mean to approach zero and the predicted covariance matrix to approach the identity matrix.

After obtaining the predicted distribution from the encoder, we use the **reparameterization trick** for sampling to enable backpropagation. The sampled latent variable *z* is then passed through the decoder to obtain the output distribution. Finally, we apply the **reconstruction loss term** on the decoder output.

Although the mathematical form is complex, the training objective remains solvable. **Variational Autoencoders** present an interesting dynamic mechanism—these two loss terms constrain each other in meaningful ways.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image71.png)

Since we force the model to perform bottleneck compression through latent space \\(z\\), these two loss terms have conflicting objectives for the latent space. **Reconstruction loss tends toward \\(\sigma\\) being zero and \\(\mu(x)\\) being a unique vector for each data point \\(x\\)**—this way each data point can get a unique encoding vector without uncertainty, achieving perfect reconstruction. However, **prior loss requires \\(\sigma\\) to be 1 and \\(\mu\\) to be zero**, aligning the latent space with the unit Gaussian distribution.

When training **Variational Autoencoders (VAE)**, these two losses compete with each other to balance precise data reconstruction and prior distribution matching. After training is complete, we can sample \\(z\\) from the prior distribution and generate samples through the decoder.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image72.png)

Another advantage is that since the latent space follows a diagonal Gaussian distribution, different entries in latent space **z** have statistical independence.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image73.png)

You can adjust them separately, and these independent dimensions usually encode useful, interpretable, or **orthogonal features** in data. In this example, we trained a **Variational Autoencoder (VAE)** using a handwritten digit dataset. When we change two dimensions of the latent space, digits smoothly transition from one category to another, which is a common characteristic of VAEs.

In summary, we discussed the distinction between **supervised learning and unsupervised learning**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image74.png)

We explored three different approaches to generative modeling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec13_image75.png)

Next, we will discuss another branch of **generative models**, focusing on **Generative Adversarial Networks (GANs)** and **Diffusion Models**.


