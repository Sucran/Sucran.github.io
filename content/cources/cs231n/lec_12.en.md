---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 12: Self-Supervised Learning"
date: 2025-09-11T13:30:14+08:00
draft: true
description: ""
---

{{< katex >}}

## Video Source

https://www.youtube.com/watch?v=4howBU7THbM

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image1.png)

Last Tuesday, we discussed the uses of **Graphics Processing Units (GPUs)** and model scaling through multi-GPU training. This year, we've added an important topic to the course that reflects the growing importance of **larger-scale models** and their applications.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image2.png)
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image3.png)

The **AI models** we see today have achieved significant evolution. Previously, we covered key areas in **computer vision tasks**, including classification, semantic segmentation, object detection, and instance segmentation. We will revisit some of these topics and the achievements of models discussed today, as these tasks remain highly relevant.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image4.png)
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image5.png)

We previously discussed gaining insights into model learning processes through visualization and understanding. In earlier courses, we explored **nearest neighbor methods in pixel space** and analyzed why image classification relying solely on **pixel distance metrics** is inefficient.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image6.png)

One of the **key points** we discussed was about the application of embedding layers or feature space representations—specifically, the fully connected layers of feature maps in convolutional neural networks or other network architectures.

These layers can serve as effective representations of images. We also studied **L2 distance metrics** used for nearest neighbor classification in that feature space.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image7.png)

This indicates that these features are **highly meaningful** for current specific tasks. Specifically, when we train neural networks (such as **CNNs**, **ResNets**, or **Transformer models**) and examine learned representations in different scenarios, these representations may be termed differently, such as **latent space**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image8.png)

These learned representations or **features** can effectively capture the essence of images. By extracting these features, we can derive class labels using a simple linear model, as shown at the end.

However, the **main challenge** lies in large-scale training or building these networks. The difficulty stems from the fact that large-scale training requires massive amounts of labeled data. Networks start training from image inputs to generate class labels, and although these features are very useful for obtaining labels, the need for large amounts of labeled data remains a significant obstacle.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image9.png)

However, when scaling up, manual annotation becomes extremely labor-intensive. For tasks like segmentation, annotating every pixel of every image is particularly challenging.

The **core question** is: Can we effectively train neural networks without relying on large manually annotated datasets? The **main difficulty** is precisely these manual annotations, and our goal is to explore methods for obtaining high-quality features while bypassing these annotations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image10.png)

Today our focus is on the topic of **self-supervised learning**. Given a large dataset of unlabeled images, our **hypothesis** is that we can train neural networks by designing proxy objectives to extract meaningful features.

Subsequently, when handling smaller labeled datasets, we can transfer this pre-trained encoder to extract features for downstream tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image11.png)

Here, our goal is to define a **pretext task**—a task that is general enough to learn meaningful features from images. Subsequently, we will utilize the resulting encoder to handle **downstream tasks** or objectives, which represent actual application scenarios.

For example, we can train on large-scale natural image datasets from the internet, then apply the learned features to smaller datasets, such as industrial or medical images with limited labels. This knowledge transfer enables feature extraction and classification for target tasks.

We will explore this in detail next.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image12.png)

We aim to explore this field more comprehensively by deeply understanding its various components. As mentioned earlier, **self-supervised learning** involves defining a pretext task on unlabeled datasets.

Encoders typically learn representations, while another module in the same neural network converts these representations to output space. These outputs may be labels or other forms, generated automatically from data rather than manually annotated.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image13.png)

To achieve this goal, we need an **objective function**, a **loss function**, and a neural network trained through this loss function. Based on the definition of pretext tasks, the second part can be called a decoder, classifier, or regressor. Although this framework can take various forms, the encoder-decoder structure typically matches the autoencoder framework, which I will briefly discuss.

After completing pretext task training, the encoder and learned representations can be transferred to downstream tasks. This usually requires adding a single layer (such as a linear function or fully connected neural network) to predict labels extracted from datasets.

The **core idea** of self-supervised learning lies in its pretext task stage that can be trained without labeled data. However, designing effective pretext tasks is not always easy.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image14.png)

There are multiple methods for defining **pretext tasks**. The key is to ensure the task is general enough to generate useful features without manual annotation. Labels should be derived directly from the data itself.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image15.png)

One example is **image completion**, where we mask partial regions of images and define the task as predicting masked regions based on unmasked parts. Another example is rotating images by specific angles and training models to predict rotation angles. A third method is solving **jigsaw puzzles**, where models need to correctly order scrambled image patches. **Colorization tasks** are also common pretext tasks, where models need to predict pixel colors from grayscale input.

By solving these pretext tasks, models can learn **meaningful features**, which is our main goal. Additionally, labels for pretext tasks can be automatically generated.

When evaluating **self-supervised learning frameworks**, two key considerations are crucial: the applicability of pretext tasks and the quality of learned features. These factors help determine whether a task is suitable for self-supervised learning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image16.png)

In this context, several key aspects need to be considered. The **pretext task itself** enables us to evaluate the model's effectiveness in solving that task, since labels are generated by us. **Representation quality** is another key factor, which can be assessed by examining raw representations without fine-tuning or by identifying patterns through clustering.

Although not discussed in detail here, dimensionality reduction algorithms like t-SNE provide frameworks for 2D or 3D visualization of high-dimensional representations to reveal underlying structures. **Robustness**, generalization capability, and computational efficiency are all important considerations.

However, **downstream task performance** is the main objective, as the entire self-supervised learning process (including pretext task design) aims to improve the final effectiveness of target tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image17.png)

Let's look at specific examples of achieving this goal. One method is to rotate images and predict rotation angles as output, this **self-supervised learning** approach can complete training without relying on object labels.

In this example, we use a series of convolutional layers and fully connected neural networks for regression or classification, obtaining a **robust feature extractor**. Subsequently, components related to pretext tasks (such as fully connected layers) can be removed and replaced with one or more new layers for classifying features into object labels.

At this stage, we use object labels for prediction and train linear functions. Since high-quality features reduce the training intensity required to derive class labels, **shallow networks** are usually sufficient. This vividly demonstrates the core idea of self-supervised learning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image18.png)

Although we're discussing **computer vision** applications, the paradigm of **self-supervised learning** has given rise to large language models like GPT-4. These frameworks are primarily trained on raw data without manual annotation.

This method is not only applicable to language models but can also extend to **speech synthesis**, robotics, and reinforcement learning fields. By eliminating dependence on labeled data, we can directly utilize raw data for model training.

This explains why autonomous vehicles collecting data are everywhere in the Bay Area—model training can be completed without data annotation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image19.png)

Today's agenda will cover pretext tasks related to image transformations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image20.png)

Next, I will discuss a group of algorithms related to **contrastive representation learning**, which, although slightly different from proxy tasks based on image transformations, have shown remarkable results.

Let's start with the first part.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image21.png)

We will now analyze each task individually. Regarding **rotation prediction**, I have already discussed it in depth. Let's study whether we can rotate images by arbitrary angles and use models to predict rotation angles.

Our **hypothesis** is that only when models possess **visual common sense** about how objects should appear in undisturbed states can they determine the correct rotation direction of objects. Therefore, these models are primarily designed around the concept of this visual common sense.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image22.png)

If models can successfully capture this, it indicates their ability to summarize entire images into a set of **meaningful features**. A 2018 paper achieved this method by exploring four different rotation angles (0°, 90°, 180°, and 270°). Specifically, after rotating images by one of these angles, **convolutional neural networks** were used to predict the applied rotation angle.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image23.png)

Since they only generate four different outputs, this constitutes a classification task with four possible cases. The model doesn't predict precise rotation angles (in degrees) but **classifies** input into one of four categories: zero, one, two, or three.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image24.png)

The authors successfully learned effective representations and subsequently used these representations to train **neural networks** for downstream applications. Specifically, they fine-tuned both the encoder and classifier. In this process, the first and second layers were frozen, while the final convolutional layer and linear layer were fine-tuned. Although not the entire network was fine-tuned, the results were very encouraging.

Experiments were conducted on the **CIFAR-10 dataset** we discussed earlier. Notably, the pre-trained model achieved very high accuracy in the initial iteration stages, showing deep understanding of objects. For relatively simple tasks like CIFAR-10, fully supervised versions and pre-trained models typically converge to similar accuracy levels. However, in more challenging applications, unsupervised learning frameworks without pre-training often produce poor results.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image25.png)

They conducted experiments on the **Pascal VOC 2017 dataset**, which includes classification, detection, and segmentation tasks. For these tasks, they adopted different settings, training few fully connected layers or all layers.

When pre-training on large labeled datasets like **ImageNet**, very high accuracy can be achieved. But this method requires all ImageNet labels for pre-training. In contrast, **self-supervised pre-training**—particularly using rotation pretext tasks—shows performance superior to other methods.

The difference between random weight initialization and pre-training using **rotation pretext tasks** is very significant. Rotation pretext task performance is almost comparable to pre-training on the entire ImageNet dataset.

Additionally, the paper analyzed learned features and their interpretability.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image26.png)

Previously, I discussed evaluating **pretext tasks** in self-supervised learning frameworks by analyzing features. You can extract features from fully connected layers. We previously introduced **GradCam** and other attention-based methods for mapping features back to image space. This evaluation method projects features into image space to analyze what the model focuses on.

**Supervised models** typically produce more concentrated attention maps because they are optimized for single classification tasks. For example, if a model identifies an eye and its outline, it might ignore other regions. In contrast, **self-supervised learning models** often have broader attention maps covering more features and regions. This is because self-supervised models need more comprehensive understanding of images since downstream tasks are unknown.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image27.png)

The goal is to achieve comparable performance across multiple tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image28.png)

One task involves creating a **3x3 grid** and using networks to predict each patch's position relative to the center patch. For example, the output for this patch should be 3, since there are eight possible positions.

If there are unanswered questions, I will respond after introducing all tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image29.png)

This is a 3×3 grid structure where the **center block** serves as a reference. The task is transformed into an eight-classification problem—when the model receives any block input, it must determine its spatial orientation relative to the reference block.

Subsequent research extended this framework into a **jigsaw puzzle** paradigm. Unlike merely predicting which of eight orientations a given block belongs to, the new version requires models to directly predict the correct permutation sequence.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image30.png)

They adopted the same **3×3 grid**, extracted all image patches, randomly scrambled them, and had neural networks identify the correct arrangement order. Essentially, the network needs to predict the correct permutation.

The number of possible permutations in this setup is 9 factorial, which is quite large—approximately 300,000. However, they constructed a **lookup table** containing only 64 reasonable permutations. During scrambling, only these 64 permutation methods are considered, with output being a 64-dimensional vector.

This method cleverly simplifies the problem into a **classification task** with 64 output categories. They proved this technique can serve as an effective **pretext task**, highly consistent with previously discussed task types and supervision implementation methods.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image31.png)

Their method **outperformed** previous frameworks. It's worth noting that this achievement was published in 2016.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image32.png)

The next pretext task is **image inpainting**, whose core lies in predicting missing parts of images. This method adopts a simple masking strategy: mask partial regions of images and train models to repair these masked regions. Since complete images are known, expected output results can be clearly defined.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image33.png)

The encoder converts input into **feature space**, then processes through fully connected layers. Subsequently, the decoder reconstructs missing parts. The **loss function** compares output with ground truth, effectively learning how to repair missing pixels.

As mentioned earlier, this architecture is similar to **autoencoders**—encoding input images into latent representations then decoding. But this autoencoder uses masking strategy as training objective.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image34.png)

For example, **image inpainting evaluation** may be particularly challenging because there are multiple possible methods for reconstructing images. In this context, there's no uniquely determined output result.

Early reconstruction-based frameworks often generated blurry and overly smooth results. The paper I referenced solved this issue by introducing **additional adversarial objective functions**. However, I won't delve into specific details here, as generative models will be specifically discussed in the next lecture.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image35.png)

Typically, these frameworks operate using **reconstruction loss**, which calculates differences between original image \\(X\\) and images after encoder processing. This process involves element-wise multiplication operations. Additionally, the system applies masks to ensure loss functions are calculated only within masked regions. By element-wise multiplication with masks, final masked region reconstruction loss is obtained.

Reconstruction loss is supplemented with **adversarial learning loss functions**, which ensure generated images have realistic appearance. This combination significantly improves reconstruction quality.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image36.png)

However, specific details will be discussed in the next lecture.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image37.png)

This reconstruction framework shows additional advantages when applied to classification, detection, and segmentation tasks on the same dataset. I will revisit **reconstruction-based frameworks** and masking techniques later, as they have become one of the most widely used self-supervised tasks in pre-training today.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image38.png)

Before continuing, let me introduce another pretext task: image colorization.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image39.png)

This is a simple framework setup where we convert color images (since datasets mainly consist of color images) into their component channels, separating brightness (illumination) from color itself.

There are various **color spaces**; for example, if you've taken computer graphics or CS 131 courses, you might be familiar with them. In computer vision, **RGB** is a commonly used color space. However, to separate brightness from color, other color spaces like **Lab (L-A-B)** are used.

The Lab color space provides one brightness channel (L) and two channels for defining actual colors (a and b).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image40.png)

By combining **L**, **A**, and **B** channels, we can reconstruct color images. The pretext task here is very intuitive: given the L channel, predict A and B channels. This method requires no manual annotation, as the required information naturally exists in the data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image41.png)

This concept was extended to other frameworks. **Why limit prediction to only inferring A and B channels from L channels?** We can also operate in reverse. This led to the development of **split-brain autoencoders**—where input images are decomposed into brightness channels (L) and two color channels.

We train two neural networks to predict each other's channels. To calculate loss functions and perform backpropagation, these prediction results need to be combined to reconstruct original images, using **L2 loss functions** or other suitable distance metrics during training. More broadly, the core idea is predicting one set of channels through another set, applying the same principle to \\(x_2\\) variables.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image42.png)

Given channel sets \\(x_1\\) and \\(x_2\\), we can predict one from the other through neural networks. By measuring these channel sets, we obtain **image values**, while loss functions remain simple and clear.

This framework is universal, with applications not limited to color and illumination.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image43.png)

We can utilize data from **RGB-D sensors**, which include RGB channels and depth channels, such as Kinect and other devices common in robotics applications. Given RGB channels, we can predict depth information, and vice versa.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image44.png)

This is an extremely successful **downstream task**, widely applied across multiple fields. **Split-Brain models** proved these features can achieve quite high accuracy when predicting class labels by predicting and colorizing images.

Although numerous other frameworks were used for comparison, this method's performance still cannot match **supervised learning** because it relies entirely on concatenated features extracted from F1 and F2 and operates without labeled data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image45.png)

The image colorization pretext task is particularly interesting because it has dual utility. It can not only be used for **neural network pre-training** but also demonstrates its inherent value by colorizing images and videos that originally had no color versions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image46.png)

One of the **remarkable findings** shown in their paper was color images of Yosemite National Park and Half Dome.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image47.png)

The fascinating detail in this image lies in the consistency between actual objects (such as **Half Dome**, trees, or bridges) and their reflections in water. The model successfully learned to preserve colors in these reflections, this capability derived from training on massive datasets.

It's worth noting that these models are **pre-trained large visual models**, designed for specific tasks rather than general problem-solving. This method can extend to video scenarios, using reference frames with color information to guide colorization of subsequent frames.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image48.png)

This method is simple yet **extremely efficient**. By colorizing future frames in videos, models can implicitly learn to track pixels and objects, understanding how these trajectories should form.

The core hypothesis is: learning to colorize video frames enables models to track regions or objects without relying on **labeled data**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image49.png)

Learning to colorize videos is an interesting task because there are many correspondences involved. I suggest reviewing the details, which I will briefly discuss.

Given a **reference frame**, the process of colorizing input frames requires identifying **pointers** for specific objects or pixels. Based on these pointers, we determine colors from reference frames and apply them as target colors for corresponding pixels in output frames.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image50.png)

This process is similar to the **attention mechanisms** we discussed earlier. For each input frame (specifically reference frame and target frame), we apply **CNNs** to extract features around pixels. These features help calculate attention or distance between target pixels and all pixels in reference frames.

After defining attention of target pixels relative to reference frame pixels, we calculate average colors based on attention weights. **Attention** essentially measures similarity between the two.

Finally, we derive output colors as attention-weighted averages and calculate **loss functions** using true pixel colors. This method successfully utilizes reference frames for image colorization.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image51.png)

Observe colorization consistency. If we colorize frames individually without **temporal continuity** constraints, character clothing colors might change accordingly.

This method has given rise to some interesting applications. By calculating attention to reference frames, we can track objects and segments in videos while identifying **key points**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image52.png)

This is a good question. **Your question relates to this slide**, namely how the encoder initially acquires knowledge about data to generate effective learned representations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image53.png)

The tasks I proposed and defined aim to perform decoding, classification, or regression to generate outputs for training encoders. If original images are natural images from the internet or **ImageNet**, encoders learn to extract features from such images through pretext tasks.

When removing encoder-decoder structures and replacing with classifiers, only that part needs training, as encoders have completed pre-training through aforementioned pretext tasks.

Regarding whether labels used for encoder pre-training come from decoders, the answer is yes. This is precisely the core purpose of defining **pretext tasks**—providing labels or output objectives for supervised learning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image54.png)

Based on these output results, we train the entire network to predict correct labels, a process that simultaneously trains the encoder.

Regarding your question about whether **encoders** and **decoders** constitute a single neural network or independent components, different papers and research works have various implementation approaches.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image55.png)

In some cases, your **encoder**—not just the decoder—serves as a classifier. For example, in the rotation prediction case I showed, this is actually a basic neural network.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image56.png)

The decoder consists of these **fully connected layers (FC layers)**. They can form a complete network, subsequently replaced for downstream tasks. However, in some cases (such as autoencoder scenarios, where images are encoded then decoded to generate another image), two **neural networks** are typically trained end-to-end to fully utilize intermediate representation spaces.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image57.png)

Next, I will discuss **masked autoencoders**. There's no symmetry requirement between encoders and decoders—they can be two completely independent frameworks or neural networks, even maintaining no symmetry during task training. This is highly **dependent on specific tasks**, especially the nature of pretext tasks. They may belong to the same architecture (such as CNN or ResNet) or be completely different architectures with no symmetry.

These methods are among the earliest explorations of **self-supervised learning**, so we can't expect them to solve all problems. The core hypothesis is: if models can identify 90-degree rotated images, it means they implicitly understand correct direction and orientation. Therefore, when facing unrotated images, they should be able to identify accurately. However, this task itself still has limitations.

Regarding your question about the purpose of the number 64, let me explain specifically.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image58.png)

This is a good question, but it's also a somewhat arbitrary choice.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image59.png)

As mentioned earlier, there are many permutations here—specifically nine factorial—which is an extremely large number. Predicting all these permutations is unrealistic. **The authors solved this by selecting a subset of 64 permutations with the largest variation**, because many permutations involve only minor changes, such as swapping single image patches. The choice of 64 was to construct the problem as a classification task.

The above discussion focused on frameworks that apply transformations to images or videos.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image60.png)

This brings us to a new framework released in 2021, which has inspired numerous subsequent research. The **MAE (Masked Autoencoder)** framework has become an efficient solution for cross-task pre-training, frequently used in pre-training on raw datasets today.

Similar to the masking strategy in previous inpainting, MAE is also based on reconstruction mechanisms but with significantly increased complexity. Unlike selecting single masked regions, this framework adopts aggressive sampling rates (50% or even 75% masking ratios) to apply masking to multiple patches and positions.

Through large-scale training, models can not only reconstruct masked regions but also generate **high-quality encoders**—these encoders can refine images into semantically meaningful feature vectors. This achievement is realized by simultaneously defining encoder and decoder architectures.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image61.png)

This is an example of **asymmetric encoder and decoder**. A large portion of input image patches are masked, while unmasked parts are processed by encoders to extract features. These features are then passed through decoders to reconstruct complete images.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image62.png)

Let's delve into training details of these models.

The **encoder** part is similar to Vision Transformer (ViT) based on Transformer architecture. Like ViT, images are first divided into non-overlapping patches. These patches undergo uniform sampling, with experiments showing **75% sampling ratio** achieves optimal efficiency.

High masking ratios were adopted in training, making prediction tasks more challenging. This design constitutes an effective **proxy task** in self-supervised learning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image63.png)

This task is efficient because models must learn **robust features** to achieve reconstruction. Under high sampling rates, data can be significantly augmented—each instance masks 75% of data. This enables the same image to be reused multiple times during training, providing sufficient data for encoder training.

Therefore, they adopted large **Vision Transformers (ViT)** as encoders.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image64.png)

This encoder only processes **25%** of input image patches. These image patches are first projected into embedding space through linear transformation, then positional embeddings are added—this process is identical to methods adopted by **Vision Transformers (ViTs)**. The entire architecture consists entirely of transformer modules, with encoders being particularly large.

During decoding, embeddings of all visible image patches are utilized. For masked or missing image patches, trainable parameters similar to class tokens in ViTs are adopted. This **shared mask token** can be understood as average representation of image patches. Decoders then reconstruct complete images from these embedding vectors.

The training objective is to minimize **mean squared error (MSE loss)** between original and reconstructed images. The key point is that this loss is calculated only for masked image patches, consistent with methods discussed earlier.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image65.png)

During training, this paper showed that for downstream tasks in different application scenarios, two strategies can be adopted: **linear probing** or **full fine-tuning**.

In linear probing mode, encoders remain frozen, directly utilizing learned representations, training only a linear function for final tasks. This indicates the model is undergoing training.

In contrast, full fine-tuning updates parameters of pre-trained encoders, either fine-tuning entire models or selectively adjusting partial transformer modules.

Linear probing can serve as a measure of representation quality for evaluating feature effectiveness; while fine-tuning can fully unleash model potential, adapting to new task requirements.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image66.png)

If you're interested in this topic and plan to use this paper, I strongly recommend carefully reading this paper and its subsequent research. The paper extensively discusses various aspects such as **model selection** and **hyperparameters**. For example, research found that 75% **masking ratio** brings highest accuracy, so it was chosen. Other key parameters examined include decoder depth, decoder width, mask tokens, reconstruction objectives, data augmentation, and masking sampling methods.

Results showed **random masking** performs better than grid-type masking. I recommend reviewing provided examples to deeply understand these research findings.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image67.png)

Finally, they proved that **MAE** (Masked Autoencoder) performance significantly outperforms many other methods. Some cutting-edge methods at the time included **DINO** and **MoCo v3** (which I'll briefly introduce if time permits), but this framework even surpassed more advanced contrastive learning frameworks of the same period.

Before continuing, let me summarize key points discussed: **Pretext tasks** are crucial, with the core goal of cultivating visual common sense. However, designing effective pretext tasks is challenging, as learned representations may lack universality depending on task definitions. Tasks like image completion, rotation prediction, jigsaw solving, or colorization produce representations applicable only to specific targets.

Now I will pause to answer questions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image68.png)

They may not be applicable to general pretext tasks. The question is, in a **split-brain autoencoder**, when given an input channel (such as **L channel** or brightness channel), how does the model learn to predict another channel?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image69.png)

Your question can be answered by understanding how **encoders** learn to extract relevant features for object classification. When training models to predict object categories in images, encoders determine which features to extract through backpropagation based on losses calculated from labeled data.

The same principle applies here: we define a **network** that takes one channel as input and outputs another channel. This network is trained through backpropagation by predicting errors between output and actual output.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image70.png)

Output corresponds to another channel that already exists in the dataset. We didn't define the task as classifying object categories but as **predicting pixel colors**. Since pixel color information already exists in the dataset, we can still calculate loss functions and perform backpropagation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image71.png)

The question is how to use these outputs as decoder inputs. **This framework adopts ViT (Vision Transformer) style architecture.** Encoders convert each input into tokens representing specific input patches. But not all patches are included—some are masked.

For masked patches, encoders output a **shared mask token**, which acts like a learnable parameter, equivalent to an average token. Although its specific meaning may not be intuitively understandable, it serves as a placeholder for missing patches.

This sequence composed of encoder tokens and shared mask tokens is then processed by decoders (another Transformer framework). Decoders map these tokens back to output pixel values.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image72.png)

Perfect. We only have 15 minutes left, with much content to cover.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image73.png)

This section's goal is to help you understand **pretext tasks** and their definitions. One of the most widely applied frameworks today is **Masked Autoencoder (MAE)**, which we've already discussed in detail. Additionally, we've studied various image transformation methods.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image74.png)

We recognize that all these transformation forms, while performing differently, represent the same objects as original images. Additionally, we know datasets contain other objects with completely different appearances. By defining a task—identifying which transformations belong to the same object (same pixels) and bringing their representations close to each other in **latent space**, while maximizing distances between different object representations—we obtain frameworks called **contrastive learning** or contrastive representation learning.

This field saw numerous innovative methods emerge between 2018-2020, including **SimCLR**, **MoCo**, **CPC**, and finally **BYOL**, which integrated contrastive learning concepts but stepped outside its strict framework.

In specific implementation, we specify reference image \\(x\\), with its transformed version as **positive samples**, and other objects in datasets or batches as **negative samples**, thereby defining loss functions. The goal is to train a scoring function where similarity scores between reference image encoded features and positive samples are higher than scores between reference images and negative samples.

Scoring function \\(S\\) (consistent with previous slides) is optimized through loss functions. To achieve attraction and repulsion mechanisms, we adopt **softmax** structures with \\(\exp\\) to convert scores into probabilities. Denominators contain all negative samples in batches, while one transformed version serves as positive sample. This loss function compares positive sample pair scores with all negative sample pairs, similar in form to formulas discussed earlier.

This method aligns with **self-supervised learning** principles in computer vision, as explored in Stanford University's CS231N Deep Learning course.



This is **cross-entropy** in multi-class classification. Given \\(n\\) samples, **softmax function** aims to maximize correct class scores among 10 possible outputs while minimizing scores of remaining classes.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image75.png)

The core concept here remains consistent. Our goal is to **maximize this score** while minimizing scores between negative samples and reference samples. This echoes previously discussed multi-class classification problems but is now expressed as a contrastive learning loss function.

This specific function is called **InfoNCE** (Information Noise Contrastive Estimation loss), proposed by the referenced paper. This paper deeply explores how this objective function serves as a lower bound for mutual information.

**Mutual information** can quantify dependency relationships or shared information amounts between two images when computing them.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image76.png)

Our goal is to maximize **shared information** between \\(x\\) and \\(x^+\\), while minimizing shared information between \\(x\\) and \\(x^-\\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec12_image77.png)

This paper points out that the negative value of **InfoNCE loss function** can serve as a lower bound for mutual information between \\(x\\) and \\(x^+\\). Therefore, minimizing InfoNCE loss actually maximizes mutual information between \\(x\\) and \\(x^+\\).


