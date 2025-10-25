---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 10: Video Understanding"
date: 2025-09-10T17:48:36+08:00
draft: true
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image1.png)

At the beginning of the course, we announced that we would invite several **guest lecturers**—teachers who have previously taught this course—to give specialized lectures on their areas of expertise.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image2.png)

I'm pleased to announce that today we will begin the first lecture in this series. Allow me to introduce **Dr. Rohan Gaur**, who is an assistant professor in the Department of Computer Science at the University of Maryland, College Park, and leads the **Multisensory Machine Intelligence Laboratory**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image3.png)

He served as a **CS231N** course instructor from 2022 to 2023 and completed his postdoctoral research under the guidance of **Fei-Fei Li**, **Jia Jun Wu**, and **Silvio Savarese**.

Without further ado, let's welcome **Rohan** to deliver today's presentation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image4.png)

Hello everyone. It's great to be back in **CS231N**. As mentioned earlier, I'm **Rohan**. My research focuses on **multimodal methods**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image5.png)

In the visual domain, and when utilizing other sensory modalities such as **audio** and **haptic**, our goal is to perceive, understand, and interact with this multisensory world like humans.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image6.png)

However, **vision** remains the most critical modality, which is why we offer this course—Deep Learning for Computer Vision.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image7.png)

By now, I believe you are quite familiar with **2D image classification**. This task aims to assign a label (such as dog, cat, truck, or airplane) to an input image for classification.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image8.png)

This is a **2D image-based classification method**. From the previous lecture, you've learned about other tasks that can be performed on images. Beyond determining whether there's a cat or dog in the image through a single label, you can also perform **semantic segmentation**, dividing the image into semantically meaningful different regions, such as identifying grass, cats, or trees.

Additionally, you can place **bounding boxes** around detected objects for localization, such as determining the position of dogs or cats. Furthermore, **instance segmentation** not only identifies categories but also generates segmentation masks for individual instances within each category—such as distinguishing between two different dogs.

These are some of the classification and recognition tasks that can be accomplished using 2D images, but the capabilities of computer vision systems extend far beyond this.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image9.png)

Our world is not static. If you look carefully at this image, you may now have mastered various tools for training models that can detect and classify objects. For example, this is clearly a **living room**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image10.png)

You've also learned to use **bounding box** tools to identify the positions of dogs and babies. Additionally, you can apply **segmentation mask** techniques to precisely locate these detected objects in the image.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image11.png)

Today, we will focus on **video understanding**. Formally, videos can be conceptualized as 2D images extended by a temporal dimension. This introduces an additional dimension, transforming the representation from 3D to 4D.

The dimensions here are defined as \\(H \times W \times 3 \times T\\), where \\(H\\) and \\(W\\) represent spatial dimensions, and \\(T\\) represents the temporal dimension. Therefore, we can view videos as **volumes composed of continuous frames**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image12.png)

A typical task is **video classification**, which is similar to image classification. Given a video input (such as a person running), the goal is to train deep learning models to classify actions based on the temporal sequence of video frames—whether it's swimming, running, jumping, or other activities.

Through previous courses, you've learned about **loss functions** (such as cross-entropy loss) used to train image classifiers. The same tools can be used to train video classifiers by extracting features and applying these loss functions.

The challenge in video understanding lies in how to obtain meaningful video features that can work with the loss functions you've already learned.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image13.png)

Another key difference between **image classification** and **video understanding** lies in the nature of the tasks. In image classification, the main focus is usually on identifying and classifying objects. However, video understanding covers a broader range of goals, extending far beyond simple object recognition.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image14.png)

For videos, the core task is usually **action classification**—identifying the behavioral activities of people or animals in the scene, which is the central focus of video understanding. The nature of recognition tasks may differ slightly.

Another key consideration is the massive volume of video data. Unlike images represented as \\(3 \times H \times W\\), videos have higher spatial and temporal resolution. For example, standard definition video occupies approximately 1.5GB of storage per minute, while high-definition video (such as 1920×1080 resolution) requires about 10GB per minute. Due to the enormous storage requirements for input data, weight parameters, activation values, and **convolutional neural network** parameters, directly storing and processing such data on GPUs is not practical.

To address this issue, the most direct solution is to reduce video scale in both temporal and spatial dimensions. For example, a 3.2-second video can be downsampled by extracting only five frames per second, fully utilizing the inherent redundancy characteristics of video frames. Simultaneously, spatial resolution is reduced to 112×112, ultimately obtaining a more manageable file size (approximately 588KB in this example). Depending on computational resources, higher resolution schemes remain feasible, similar to image processing principles.

Another challenge lies in how to efficiently train long video models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image15.png)

In the previous slides, I showed that we use **3.2-second clips** to train video classifiers. However, videos can range from minutes to hours in length. To solve this problem, the conventional approach is to train on short video clips. Specifically, we train models to classify these clips at lower frame rates (**FPS**).

During training, we use **sliding window techniques** to sample numerous clips as training data. During inference, we sample multiple clips from long videos (e.g., 10 clips) and average the model's predictions on these clips to obtain the final classification result for the entire video.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image16.png)

What simple video classification model can we use? As mentioned earlier, videos are essentially sequences composed of a series of images (specifically video frames). Based on this, we can treat them as independent images for processing.

This approach leverages existing tools: since we already have the capability to train image classifiers, we can apply **single-frame convolutional neural networks (CNNs)**. By running our image classifier on video frames and treating them as images, we can obtain relatively accurate predictions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image17.png)

For this type of video, you can observe minimal changes between frames. When a person is running, there are subtle differences in body movements, but the overall appearance remains consistent.

If you run an **image action classifier** on each frame, it's likely that all frames will be classified as running actions. By averaging the predictions of each frame, you can predict the action of the entire video.

This method typically serves as a **strong baseline** for simple image classifiers, especially suitable for videos with limited changes. When designing video classifiers, it's recommended to first adopt this approach because it can achieve quite good results with minimal complexity.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image18.png)

The question is whether we're processing single-frame images or a group of frame images.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image19.png)

For simple single-frame processing methods, suppose there's a 30-frame video. You can extract some frames (e.g., 10 frames) from it, apply an **image classifier** to each sampled frame, treating it as an independent image for processing. The final result is obtained by averaging the classifier outputs of all sampled frames. This method is called **frame-by-frame method**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image20.png)

You raised a key question about **frame sampling**. This is crucial because we need to choose which frames to process. Therefore, the choice of frame extraction method becomes particularly important.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image21.png)

This is still an active research area. **Basic methods** adopt random sampling strategies. For example, when processing an unanalyzed one-hour video, we can extract one frame per minute, apply image classifiers for processing, and finally average the results.

Although this method can achieve reasonable results, it may not be the **optimal sampling scheme**. Other research focuses on developing more intelligent sampling techniques, such as guiding subsequent sampling point selection through initial frame analysis.

More cases will be demonstrated in subsequent course slides. What's demonstrated here is a **direct video classification method**, which essentially applies CNN classifiers to single-frame images.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image22.png)

To further improve our approach, compared to simply running single-frame CNNs and averaging predictions, we can use single-frame CNNs for **feature fusion**. This method is commonly called **late fusion**.

The specific process includes the following steps:
1. First, input \\(T\\) frame images.
2. Apply 2D CNN to each frame to extract feature vectors, obtaining feature maps with dimensions \\(B \times H' \times W'\\).
3. Since there are \\(T\\) frames in total, we finally obtain \\(T\\) feature maps.
4. Flatten these feature maps into vectors and concatenate them, forming a composite feature vector containing all frame-level features.
5. Subsequently, use a **fully connected network (FC layer)** to process this vector: specifically, train an MLP to map the concatenated feature vector to a low-dimensional space.
6. Finally, train a classifier at the top layer to generate class scores \\(C\\).

It's called "late fusion" because feature extraction and initial processing are performed independently for each frame, and fusion is only achieved in the later stage by concatenating feature vectors and applying fully connected layers for classification.

However, this method has significant drawbacks—the **excessive parameter count** of fully connected layers leads to inefficiency. When \\(T\\) values are high, the concatenated feature vector may become extremely large, making the transformation to low-dimensional space computationally expensive, and this inefficiency limits the scalability of the solution.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image23.png)

Another alternative is to avoid concatenation operations and instead adopt **pooling** methods. Unlike using large feature vectors followed by fully connected layers to map class scores, we can perform temporal aggregation through pooling. This method doesn't increase the length of feature vectors.

For example, suppose the single-frame feature dimension is \\(D\\), and after pooling \\(T\\) frames, the clip feature dimension remains \\(D\\). Subsequently, map \\(D\\) to class score dimension \\(C\\) through a linear layer and apply cross-entropy loss. This is also a form of **late fusion**, but implemented using pooling. Its advantage lies in reducing dependence on large fully connected layers, though pooling may lose potentially important information.

The term **"late fusion"** emphasizes temporal characteristics—by the later stage, some information may have been lost during single-frame 2D CNN processing. For example, the man's foot movement (highlighted in red circle) is crucial for identifying actions (such as running). But if each frame is processed independently as a 2D image, the subsequently generated feature maps may no longer retain such motion information. Therefore, effective cues like foot movement may disappear from feature maps.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image24.png)

Intuitively, extracting features from early network layers can obtain representations closer to original video frames, thereby improving the possibility of capturing **low-level motion information**. By concatenating or pooling these features across the temporal dimension, we can analyze motion patterns across time periods. However, after multiple layers of convolution and pooling processing, deep network layers tend to extract high-level semantic information rather than low-level motion cues, which also explains why such information is often lost in late fusion methods.

To address this limitation, **early fusion** strategies can be adopted. This method reshapes input video frames into a 3T×H×W tensor, directly aggregating temporal information from the beginning. Subsequently, the initial 2D convolutional layer maps the channel dimension from 3T to D, achieving temporal information processing in the first layer. This enables convolutional neural networks to process video frame data from the initial stage.

The remaining part of the network operates using standard 2D architecture, with the key difference being that temporal information is compressed into a single representation in the first layer. Subsequent processing follows the same flow as image classification, using standard cross-entropy loss. Each frame generates a D-dimensional feature vector, providing frame-level representations for classification tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image25.png)

Suppose you have a variable \\(T\\), and this feature vector is \\(D\\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image26.png)

For **pooling** operations, we aggregate features. Specifically, we can perform **average pooling** to average features, or perform **max pooling** to select maximum values. The final obtained features maintain dimension D unchanged. This operation pools features, not frames.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image27.png)

The disadvantage of **early fusion** is that although we explicitly attempt to process motion information from early layers, our approach may be overly ambitious.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image28.png)

Our goal is to capture all information within a single layer by concatenating frame sequences and using a **single convolutional network** to compress temporal data. However, this method may not achieve the expected effect.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image29.png)

Another solution is to perform feature fusion at an intermediate stage rather than early or late. This method is called slow fusion, which is the core principle of **3D convolutional neural networks**. The design idea is to gradually fuse information in the network through 3D convolution and pooling operations. Unlike early or late fusion, we obtain 3D feature maps by progressively reducing temporal and spatial dimensions.

The core idea of 3D convolutional neural networks lies in adopting **3D convolution** and **3D pooling** operations. If you're familiar with 2D convolution, the concept can naturally extend to three-dimensional space.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image30.png)

For **2D convolution**, consider a \\(32 \times 32 \times 3\\) image. When using 2D convolution, each convolution kernel is equivalent to a filter. For example, a \\(5 \times 5 \times 3\\) convolution kernel uses the **sliding window method** to traverse in spatial and depth dimensions.

Each computation corresponds to a single value in the final activation map, generating a \\(28 \times 28 \times 1\\) activation map. This process covers all spatial positions and maps the channel dimension, reducing depth from three dimensions to one dimension in this example.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image31.png)

This text describes **2D convolution**. The key difference from **3D convolution** lies in adding an additional dimension. Here, the input data dimension is C × T × H × W, where **T** represents the temporal dimension. Due to visualization limitations in 3D space, the channel dimension C is not shown in this diagram. Each grid point in the feature map contains C features.

For 3D convolution using a 6×6×6 convolution kernel (adding one dimension compared to 2D), the operation not only needs to slide the convolution kernel in spatial dimensions (H and W) but also needs to slide across the entire temporal-spatial cube (dimension T×H×W). This sliding operation proceeds simultaneously along spatial and temporal dimensions and throughout the channel dimension.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image32.png)

The initial stage of this process is similar to **2D convolution**, but adds an additional dimension, forming a **3D convolution** with size \\(6 \times 6 \times 6\\), followed by another layer of \\(5 \times 5\\) convolution operation. After processing through these 3D convolution operations, feature vectors are flattened and mapped to class scores through fully connected layers. This summarizes the core idea of 3D convolution.

To better understand the differences between **early fusion**, **late fusion**, and 3D convolutional neural networks, we illustrate through a simplified example. Although actual applications involve larger and more complex network structures, this simplified model can clearly demonstrate key concepts such as feature map sizes and receptive fields.

In late fusion, the initial input dimension might be \\(3 \times 20 \times 64 \times 64\\), where 20 represents the temporal dimension, and \\(64 \times 64\\) is the spatial dimension. When applying 2D convolution, the temporal dimension of 20 remains unchanged while building receptive fields in spatial dimensions. For example, a **Conv2D layer** might map the channel dimension from 3 to 12 while keeping the temporal dimension at 20. Subsequent pooling layers further expand spatial receptive fields without changing the temporal dimension. Then another Conv2D layer might generate feature maps with size \\(24 \times 20 \times 16 \times 16\\), continuously increasing spatial receptive fields while the temporal dimension always remains unchanged.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image33.png)

Finally, by applying **global average pooling**, we perform pooling operations on feature maps with size \\(20 \times 16 \times 16\\), compressing temporal and spatial dimensions into a single \\(1 \times 1 \times 1\\) feature point. This process effectively builds **temporal receptive fields** within a single layer, and this method is called **late fusion**.

In contrast, **early fusion** adopts a different processing approach. Its input remains \\(3 \times 20 \times 64 \times 64\\), but we treat the temporal dimension as part of the channel dimension. Through a single **2D convolutional layer**, we map and compress all temporal information from the initial stage. This makes the temporal receptive field range of the first layer cover frames 1 to 20, while spatial receptive fields are gradually built through pooling and 2D convolution (similar to late fusion). Subsequently, global average pooling is applied only to spatial dimensions.

**3D convolutional networks** adopt a synchronous progressive approach, simultaneously building spatial and temporal receptive fields.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image34.png)

This is why we call it slow fusion. The input dimension remains \\(3 \times 20 \times 64 \times 64\\), but now we use **3D convolution**. In the first layer, we map the input from 3 channels to 12 channels while preserving the temporal dimension. This approach can gradually build spatiotemporal receptive fields.

Subsequently, through \\(4 \times 4 \times 4\\) pooling layers, temporal and spatial features are reduced. Then, another layer of 3D convolution further expands spatiotemporal receptive fields. Finally, global average pooling is applied to \\(4 \times 16 \times 16\\) feature maps to enhance receptive fields in both dimensions.

This method demonstrates progressive construction of spatiotemporal dimensions, forming a sharp contrast with early fusion and late fusion. It's worth noting that both early fusion and 3D convolutional networks develop receptive fields over time.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image35.png)

But what's the actual difference?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image36.png)

Let's analyze this more carefully. You can think of it as a **feature vector** for each spatial grid point. The convolution filter applies **2D convolution**. For this grid point, it will cover all temporal dimensions, where \\(T = 16\\).

This operation is spatially local but fully unfolded in the temporal dimension, similar to filters in 2D convolutional neural networks. However, what's the problem here?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image37.png)

Think about it: What problems would arise if we directly apply **2D convolution** in the temporal dimension? The limitation lies in the lack of **temporal translation invariance**. Since the convolution kernel covers the entire temporal dimension, it cannot capture global changes occurring at different time steps.

For example, in video data, color transitions from blue to orange might appear in frames 4 and 15. If using convolution kernels that span the entire temporal dimension, different kernels would be needed to learn these same but temporally different changes, leading to inefficiency.

This is similar to **spatial invariance** in image classification—regardless of where a cat appears in the frame, we can identify it. Similarly, for temporal patterns (such as motion or color transitions), we hope to detect them regardless of when the changes occur.

This is exactly the advantage of **3D convolutional neural networks**. Unlike early fusion where the temporal dimension \\(t=16\\) is fully covered, 3D CNN uses \\(t=3\\) convolution kernels sliding in local temporal windows. This sliding mechanism achieves temporal translation invariance, enabling the same convolution kernel to identify blue-orange transitions occurring at any time point.

Therefore, by reusing convolution kernels across the temporal dimension, we achieve higher representation efficiency without needing independent kernels for each time step. This is the essential difference between early fusion's 2D convolution and 3D CNN.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image38.png)

In the previous class, you saw example tools for visualizing features learned by **2D convolutional neural networks**. Similarly, we can present filters in **3D convolutional networks** as video clips. Filters learned from 3D CNN will span both spatial and temporal dimensions simultaneously.

Some filters are similar to those observed in image classifiers, presenting **color patterns** and edge features. Others exhibit **temporal changes**, such as color gradients or edge pattern changes. Some filters can capture motion features in different directions, while others focus on static image patterns.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image39.png)

To understand these convolution kernels, we can perform the following visualization. The main differences are reflected in two aspects: first is the concept of **slow fusion**. In terms of convolution operations, **3D convolution** differs fundamentally from 2D convolution, with the key being the introduction of temporal dimensions in convolution operations.

When actually applying 3D convolutional neural networks, receptive fields gradually build in both spatial and temporal dimensions. We have previously discussed these tools—specifically 3D convolutional networks and their architectures.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image40.png)

To train a video classifier, we need datasets similar to **ImageNet**. One example is the **Sports-1M** dataset launched in 2014, which supports fine-grained sports category classification.

The visualization interface here marks ground truth labels in blue, with the top five predictions displayed below. Correct predictions are marked in green, while incorrect predictions are highlighted in red.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image41.png)

The action categories in this dataset are **highly fine-grained**, containing 487 different types of sports. For example, it includes multiple categories such as marathon and ultramarathon, fully demonstrating the dataset's precision in sports classification.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image42.png)

Below are the training results of different classifiers we discussed on the **Sports-1M dataset**. A surprising finding is that **single-frame models** (treating each frame as an independent image) show strong performance with 77.7% top-5 accuracy.

Early fusion methods perform slightly worse, while late fusion shows moderate improvement. **3D convolutional neural networks** brought 2-3% performance improvement on this dataset.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image43.png)

The key takeaway is that you should try experimenting with single-frame models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image44.png)

**3D convolutional neural networks** typically perform quite well. The **3D CNN architecture** shown here dates back to 2014, but significant improvements have been made over the past decade, which I will discuss in detail in subsequent slides.

In training and testing phases, **single-frame processing** essentially treats videos as images to train image classifiers. However, this method processes multiple frames of each video rather than just single frames.

Due to the massive volume of video data, this dataset is particularly substantial. Unlike **ImageNet**, directly sharing video datasets is not practical—this dataset contains approximately 1 million videos. Initially, it was distributed only as a **YouTube link list**. But many videos may have been modified or deleted, leading to data stability concerns, and half of the original links may have already failed.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image45.png)

Another type of architecture, as mentioned earlier, is **3D convolutional networks**, which have been gradually improving since around 2014. An early popular version of such networks was the **C3D model**. Essentially, it's very simple, very similar to the **VGG architecture** used for 2D image classification, but adapted to three-dimensional space. For example, it uses \\(3 \times 3 \times 3\\) convolution and \\(2 \times 2 \times 2\\) pooling, with some modifications in the first layer.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image46.png)

Our architecture is very similar to the **VGG architecture**, but adds one dimension. Therefore it's called **VGG in 3D CNN**.

This model was trained on the **Sports-1M dataset** I mentioned earlier. This dataset was launched in 2014, and training such models at that time required massive computational resources because access to multi-GPUs was still limited.

This model was trained at **Facebook**, and its pre-trained weights became crucial. Many researchers who couldn't train video models themselves began using this **3D model** as a feature extractor. They extracted features from videos through pre-trained 3D models and then trained other linear classifiers. This widespread application promoted its popularity.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image47.png)

This question involves how many frames should be used as input for feature extraction in video classification. For the models we discussed, we assume using predefined clip lengths, such as **16 or 32 frames**. Each model uniformly processes clips of this fixed length.

Subsequently, we will explore techniques for aggregating prediction results at the clip level. The current focus is on **clip-level feature extraction**. But it's worth noting that **3D convolutional neural networks** have significant drawbacks of high computational costs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image48.png)

To extend VGG-style architectures from 2D to 3D, we adopted a direct approach. The term **"GFLOP"** represents billions of floating-point operations, used to measure the computational cost of a single forward pass, reflecting network efficiency.

For example, AlexNet requires 0.7 GFLOPs, while VGG-16 requires 13.6 GFLOPs. But when transitioning to C3D that maps 2D to 3D, computational costs rise to 39.5 GFLOPs—**2.9 times** that of VGG-16, highlighting its inefficiency.

In terms of performance on the Sports-1M dataset, this 3D adaptation brought only a **4%** top-5 accuracy improvement.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image49.png)

This is just one example of **3D convolutional networks** we can implement. Of course, there are other methods. Many **2D image classification** techniques we discussed can be adjusted—such as residual connections similar to those in ResNet. By introducing residual connections or other methods, these techniques can be extended to 3D convolution.

Additionally, extensive research focuses on improving various **3D video architectures**, with numerous papers exploring these optimization schemes.

Furthermore, we need to consider whether we should process **spatial and temporal information** separately. These represent fundamentally different dimensions—spatial structure and motion dynamics. Perhaps we should explicitly model temporal features (such as motion) to better capture video understanding.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image50.png)

Humans excel at action processing. Let's think about what behaviors are depicted in this simple video. Even with only a few key points, we can accurately identify ongoing activities—whether it's one person or two people's actions. **Notably**, this recognition is accomplished entirely without appearance information, relying solely on motion data. This demonstrates our extraordinary ability to understand activities from minimal visual cues.

This observation suggests that our processing of appearance and motion information may involve **different mechanisms**. Therefore, using independent networks to process these different types of visual data might be more effective. This insight became the theoretical foundation for research work proposed in 2014.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image51.png)

They proposed a **two-stream network** to separately process appearance and motion information. Among these, **optical flow** is a method for explicitly measuring motion. The core of this technique lies in calculating pixel motion changes between adjacent frames, specifically manifested by predicting the position of points in subsequent frames through calculating their velocity within frames.

For example, between frames \\(T\\) and \\(T+1\\), the optical flow field has two dimensions, representing the displacement amount of each pixel. The mathematical relationship can be expressed as:
\\(I_{T+1}(x + dx, y + dy) = I_T(x, y)\\)
where \\((dx, dy)\\) represents the displacement vector.

This method provides quantitative indicators for pixel motion. Extensive research focuses on improving the accuracy of optical flow calculation between frame pairs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image52.png)

There are multiple methods for constructing different types of assumptions. For example, some research assumes that **optical flow** remains constant when objects move, then proposes techniques for calculating this optical flow. Once optical flow is obtained, motion information between adjacent frames can be captured.

Since optical flow operates in 2D space—simultaneously recording pixel displacement in horizontal and vertical directions—it can be visualized separately. Horizontal optical flow (\\(D_x\\)) and vertical optical flow (\\(D_y\\)) can clearly characterize their respective motion components.

These low-level motion cues are then applied to **two-stream networks**, separately training motion and appearance classifiers.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image53.png)

This is a famous **two-stream network** for action recognition. It consists of a single-frame model and an independent temporal stream: the single-frame model is responsible for classifying through appearance features to identify actions, while the temporal stream processes multi-frame optical flow information.

For each pair of adjacent frames, the network separately calculates horizontal and vertical motion components, generating **optical flow maps** and stacking them. Subsequently, the temporal stream processes this data through convolutional neural networks and makes predictions.

Finally, the prediction results of motion and appearance streams are fused to generate final recognition results. This two-stream network performs excellently on the **UCF-101 dataset**, particularly demonstrating strong performance advantages.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image54.png)

This dataset contains **101 action categories**. A surprising finding is that using only **motion information** can achieve very excellent performance.

Specifically, we can compare the performance of 3D CNN, spatial-only (appearance stream), and temporal-only (motion stream). The motion stream significantly outperforms the spatial-only stream.

My hypothesis is: the motion stream is less prone to **overfitting** because it contains key motion cues, while the appearance stream may contain background information unrelated to action classification. This characteristic enables the motion stream to achieve better results on this dataset.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image55.png)

So far, we've discussed short-term structures in videos. There was a previous question about how many frames are needed for classification. **Modeling long-term temporal structures is crucial for identifying events that are temporally distant.**

We already have tools for processing sequences, such as **recurrent neural networks**, which process word sequences to complete tasks like caption generation and prediction. Similarly, we can use **convolutional networks**—whether single-frame 2D CNNs or 3D CNNs processing clips—to extract feature vectors. For longer videos, we can adopt **RNNs or LSTMs**, modeling long-term temporal structures by processing local features and making final predictions at the last time step.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image56.png)

Our goal is to achieve **single video-level classification**, which involves many-to-one mapping to generate a single output at the end of the video. Alternatively, we can also adopt **one-to-one mapping** to make predictions for each frame. Such predictions can be implemented through architectures like **LSTM** or recurrent neural networks.

This concept was first proposed in 2011, before the advent of **AlexNet** in 2012, but gained widespread attention through a 2015 paper. To train such recurrent architectures for modeling long-term temporal structures, backpropagation through RNNs is typically required. Additionally, **CNNs** can be pre-trained on image classification tasks before fusion.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image57.png)

Otherwise, you would have a large network containing both recurrent and convolutional structures, making end-to-end training difficult. Instead, you can use **C3D** as a feature extractor and train recurrent neural networks separately.

We've discussed two methods for modeling temporal structures. Now, consider combining these two methods—convolutional neural networks and recurrent neural networks—each with their own advantages. By integrating them into a unified architecture, we can better handle video data.

This idea draws inspiration from the **multi-layer recurrent neural networks** we discussed earlier.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image58.png)

At each time step, the model receives the **previous hidden state** from the same layer and the output from the previous layer at the same time step. This is the **core principle** of multi-layer RNNs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image59.png)

Similarly, we can apply this method to video processing. Here we introduce **recurrent convolutional neural networks**, whose core idea is very similar—we construct a feature grid composed of three-dimensional vectors, each containing two spatial dimensions and one channel dimension.

Each feature vector in this grid (dimension \\(C \times H \times W\\)) depends on two input vectors: specifically, each feature map depends on both the feature map from the same layer at the previous time step and the feature map from the previous layer at the current time step.

In standard **2D convolutional networks**, we map input feature maps to output feature maps. In recurrent convolutional networks, the input consists of two 3D tensors: one from the previous layer at the same time step, and another from the same layer at the previous time step. This structure forms a recurrent network with hidden layer feature maps (denoted as \\(H_{t-1}\\)).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image60.png)

It processes the input at the current timestamp through a function with parameter \\(w\\), generating a new state feature vector \\(H_t\\). This is the **core concept of recurrent neural networks**. By replacing matrix multiplication in recurrent neural networks with 2D convolution, we obtain **recurrent convolutional networks**.

Feature maps undergo 2D convolution rather than matrix multiplication operations, generating another feature map. Similarly, features from the previous layer at the same timestamp are processed in the same way. After completing 2D convolution, results are merged and passed through a tanh activation layer, finally obtaining the current hidden layer's feature map. This summarizes the **basic idea of recurrent convolutional networks**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image61.png)

We combine **convolutional operations** with **recurrent operations**, and this combination can be applied to any recurrent neural network variant (such as GRU and LSTM you may have learned in previous courses). This method successfully achieves dual advantages of spatial and temporal fusion in recurrent convolutional neural networks.

However, since recurrent neural networks have a significant drawback—they are inherently serial computations—this model hasn't been widely adopted. Processing non-sequential data (such as usually very long videos) requires parallel computation, but recurrent neural networks are difficult to parallelize.

As discussed in previous courses, the alternative is to adopt **self-attention operations**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image62.png)

When processing videos, **self-attention mechanisms** involve queries (key queries), keys, and values. You can treat self-attention as an independent operation for processing images, and here we apply it to videos.

A major advantage of self-attention is its **high parallelizability**. All input alignment and attention score calculations can be executed completely in parallel.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image63.png)

In fact, researchers are applying **self-attention mechanisms** to video data. This method extends self-attention to 3D space by processing feature maps with dimensions \\(C \times T \times H \times W\\) obtained from 3D convolution.

First, use \\(1 \times 1 \times 1\\) 3D convolution to transform the channel dimension, generating **query feature maps** with size \\(C' \times T \times H \times W\\). Similarly, key and value feature maps are generated.

**Attention weights** are calculated by performing transposed matrix multiplication between query feature maps and key feature maps, obtaining attention scores for each query-key pair. These scores are then used to modulate value feature maps.

Finally, another \\(1 \times 1 \times 1\\) convolution maps the output back to the original dimension \\(C\\), enabling concatenation with the initial input. The entire process constitutes an independent module, whose structure is highly similar to standard self-attention operations but adapted to 3D data characteristics.

This architecture is called **Non-local Neural Networks**, first published in the paper "Non-local Neural Networks" (Wang et al., CVPR 2018).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image64.png)

It introduces a module called **non-local blocks**, which can serve as basic building units for processing videos in video understanding tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image65.png)

For example, you can integrate **non-local modules** into existing **3D convolutional neural network architectures**. Each non-local module can effectively fuse information from spatial and temporal dimensions, thereby enhancing model capabilities. This alternating structure of 3D convolutional layers and non-local modules can significantly improve performance.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image66.png)

Finally, you can perform this classification.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image67.png)

One topic we haven't discussed yet is the concept of **3D convolutional neural networks**. A key question emerges here: How should we proceed with research?

In the past, there was an interesting idea of adjusting the successful **2D convolutional neural network architectures** we previously learned to make them suitable for 3D scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image68.png)

We can obtain **3D convolutional neural networks** by inflating these 2D networks. This method is called **i3D architecture**.

The core idea is: select a 2D CNN architecture, replace each 2D convolution or pooling layer originally with dimensions \\(K_H \times K_W\\) with a 3D version with dimensions \\(K_T \times K_H \times K_W\\). Essentially, 2D layers are inflated into 3D layers.

This improvement was applied to inception blocks, forming architectures that can directly process videos while reusing existing 2D structures. Additionally, this method can transfer excellent 2D architectures to the 3D domain.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image69.png)

Furthermore, researchers not only explored architecture transfer but also delved into **weight transfer**. Since we've already pre-trained numerous models on image datasets, we can leverage these learned weights, which may contain valuable prior information.

One method is to initialize inflated **3D CNNs** with weights trained on images. For example, starting from a **2D convolution kernel**, it can be copied \\(KT\\) times and then divided by \\(KT\\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image70.png)

Originally, this model took a single image as input. Now, it processes a video with dimensions \\(KT \times H \times W\\) as input because we've already divided it by \\(KT\\). If using this expanded version and copying weights \\(KT\\) times, whether inputting single frames or constant frames, the same output will be obtained.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image71.png)

Now we can reuse existing **2D image-based architectures** and weights obtained from 2D image understanding. This method performs quite effectively.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image72.png)

In performance evaluation, **inflated models** outperform two-stream convolutional networks. This inflation technique can not only be applied to appearance frames but also to motion streams, bringing further performance improvements. Essentially, this is a reusable technique that operates independently of 3D convolutional networks and can be deployed in local modules.

The core insight is: we have numerous proven efficient **2D convolutional networks**. Research shows that their weights can be directly copied and transferred for video operations. After this initialization, video data can still be fine-tuned based on pre-trained image weights, providing excellent initialization schemes for video model training.

**I3D networks** are typical representatives of this method—by copying weights and applying inflation operations. This case is a noteworthy example in the field of video understanding models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image73.png)

Additionally, many other **video Transformer models** have been proposed for video understanding. For example, some research focuses on factorized attention mechanisms across spatial and temporal dimensions, while other methods focus on improving computational efficiency within Transformer architectures, or using masked autoencoders for scalable video-level pre-training to enhance video understanding capabilities.

Although this course won't delve deeply into these topics, I encourage interested students to consult related papers, as significant progress has been made in developing better video understanding models.

As background reference, model performance has evolved from the baseline of single-frame models scoring 62.2 on the **Kinetics 400 dataset**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image74.png)

This is a large video dataset. For **VideoMAE encoders**, accuracy has reached 90%. Additionally, several new **transformer models** have been proposed.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image75.png)

We perform excellently in the field of **video classification**, which is similar to image classification. In the previous class, we explored using similar techniques to visualize video models.

Taking **two-stream networks** as an example, we can randomly initialize appearance images and optical flow images, perform forward propagation and calculate scores. Then, perform backpropagation on scores for specific categories, maximizing classification scores through gradient ascent—this is completely consistent with the processing method of image-based models.

This method enables us to intuitively understand and interpret the features learned by models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image76.png)

The left image is optimized for **appearance streams**, making it quite challenging to infer video content. The right image is optimized for **optical flow streams**, introducing temporal constraints to prevent rapid changes in temporal streams. This method can simultaneously capture slow and fast motion, aiding action recognition. In this case, the action can be clearly identified.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image77.png)

This is a weightlifting scene. The **person in the middle** is performing barbell jerks, while the person on the right is performing overhead presses. These actions indicate that **video models** and **action recognition models** are effectively learning from these motions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image78.png)

Good. So far, I've been discussing how to classify these short video clips.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image79.png)

Swimming and running are important, but another **key element** lies in **temporal action localization**. This involves more than just clip-level classification.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image80.png)

Sometimes our goal is to perform **object detection** to locate where actions occur in videos. For example, a person might be running or jumping.

Another related task is **temporal action localization**. Similar to Faster R-CNN, you can generate temporal proposal boxes and then classify them.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image81.png)

Additionally, you can perform both tasks simultaneously. This involves **spatiotemporal detection**, whose goal is not only to spatially locate actions but also to temporally determine where and when actions occur. This task is also called spatiotemporal detection.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image82.png)

So far, I've discussed **temporal streams** and architectures available for **3D convolutional neural networks** and **two-stream neural networks**, including spatiotemporal self-attention mechanisms. We've introduced some tools for this.

In the final 10 minutes, let's revisit the example mentioned at the beginning of today. I hope to finish on time.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image83.png)

I showed you a video, but that might not show the full picture.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image84.png)

We're studying **video understanding**. So far, we haven't addressed a key dimension: **sound and audio**, which represent additional modalities in videos. Ignoring this element would greatly diminish the experience.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image85.png)

By combining **visual** and motion data, we can perceive emotions and interactive behaviors. With audio and visual dual-modal data streams, researchers have proposed numerous interesting video understanding tasks.

For example, videos often contain multiple objects and speakers. One task I personally explored is **guided audio source separation**, which requires simultaneous processing of visual and auditory information.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image86.png)

Visual information can be used to guide audio source separation. The goal is to separate individual sound components from mixed sounds by utilizing **visual cues**. This technique is called **visually guided audio source separation**.

For example, in a mixed scene containing multiple people's speech, the goal is to separate each speaker's voice. By synchronously processing visual and audio streams, we can achieve speaker voice separation. This method is not limited to speech separation but can also be applied to other sound source (such as musical instruments) separation scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image87.png)

Here's another example. We can achieve **musical instrument separation** tasks by analyzing actions, object-centered information, and audio streams. This provides another example for this process.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image88.png)

Additionally, with the introduction of audio as a new modality, it can provide **important cues** for video understanding and classification. In the field of audio-visual video understanding, multiple studies have proposed Transformer-based models that not only map images and videos to patches but also convert audio spectrograms to patches, using Transformer architectures for classification.

Another method adopts **masked autoencoder-style techniques**, enhancing video understanding by predicting patches of images and spectrograms. Furthermore, researchers are exploring efficient video understanding methods.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image89.png)

In this course, we mainly focus on **clip-level classification**—how to classify individual video clips. After classifying multiple clips, we aggregate this information to obtain **video-level predictions**, which is crucial for action recognition in long videos.


![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image90.png)

To achieve efficient video understanding, the challenge lies in video length making frame-by-frame processing impractical. For this, researchers have explored multiple solution paths.

**One direction** is to improve single-clip processing efficiency, such as **X3D models** achieving performance breakthroughs by optimizing 3D convolutional networks.

Another approach focuses on **clip sampling** techniques, where methods like **SCSampler** can automatically identify the most informative clips, enabling classifiers to process only these key segments.

Additionally, **adaptive multimodal learning** techniques can dynamically select optimal modality combinations (such as video, audio, or other sensor data) to improve classification effectiveness. For example, audio can serve as a pre-screening mechanism to locate important moments in videos.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image91.png)

We use this as a guiding framework to process video clips and aggregate results. **This method** is part of the broader research field of efficient video understanding.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image92.png)

Today, there's growing interest in VR (Virtual Reality) and AR (Augmented Reality), especially in the field of smart glasses. In the future, we expect **first-person perspective video streams** to grow significantly, providing another dimension for video understanding.

Beyond first-person perspective videos, there are also **multi-microphone arrays** and **multi-channel audio** technologies. How to enhance video understanding capabilities through these multimodal first-person data streams is becoming an emerging research hotspot.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image93.png)

We can use **video streams**, **multi-channel audio**, and **visual information** to predict interactions between speakers and listeners.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image94.png)

Imagine a future where you wear **smart glasses** to assist in understanding various social interactions. This is the concept of **egocentric video understanding**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image95.png)

In my final slide, I will discuss Large Language Models (LLMs). Currently, there's extensive research focused on developing video-level foundation models.

The core challenge lies in connecting video understanding with Large Language Models. Some methods involve tokenizing videos and mapping them to LLM embedding spaces. This enables us to answer queries such as identifying person locations or behaviors in videos by prompting video foundation models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec10_image96.png)

The output content includes text descriptions of videos. Currently, many studies are exploring connections between **video understanding** and Large Language Models (LLMs), making this a prominent research topic.
