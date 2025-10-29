---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 6: CNN Architectures"
date: 2025-09-08T17:26:01+08:00
draft: false
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image1.png)
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image2.png)

Hello everyone. I am **Zane Durante**, one of the co-instructors for this course. Currently a fourth-year Ph.D. student at Stanford University, jointly advised by Professor Ehsan and Professor Fei-Fei Li.

Today, in **Lecture 6** of Stanford CS231N course "Deep Learning for Computer Vision", we will explore training methods for Convolutional Neural Networks and CNN architecture design.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image3.png)

This lecture is divided into two main parts. **Part One** focuses on how to integrate the basic modules we have covered—such as convolutional layers, linear layers, and fully connected layers—to build **CNN architectures**, with illustrative examples. Part Two will explore the **training process** and its related steps.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image4.png)

As mentioned earlier, we will cover two major topics. Part One focuses on **building convolutional neural networks**, specifically involving the definition of training architectures. Part Two then addresses the **training process** for convolutional neural networks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image5.png)

Starting with the first set of topics, we will explore the hierarchical structure in convolutional neural networks. As discussed in the previous lecture, the **core layers** in such models are **convolutional layers**. These layers operate through predefined filters, with each layer having a specific number of filters—six in this example—that match the depth of input data.  

For example, consider a 32×32 RGB image with three depth channels. Each filter slides across the image, computing scores for each position by calculating the dot product of filter values with corresponding image values. This process includes numerical multiplication, summation, and adding a **bias term**. The final result is an **output activation map**, with each filter producing one map.  

Typically, a nonlinear function such as **ReLU activation function** is applied at the end. While input depth corresponds to the number of channels (e.g., three for RGB images), the output depth here is six. Therefore, subsequent convolutional layers need filters that can cover all six activation maps, making the next layer's depth also six.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image6.png)

The second layer we discuss is the **pooling layer**, which is simpler than convolutional layers. A filter (typically 2×2 size with stride 2) slides across the image and skips certain positions.

In **max pooling**, the maximum value within each region is selected. **Average pooling** can also be used. Both methods are common, and the specific choice depends on network architecture. When designing new architectures, both methods should be tested to determine which performs better.

The main purpose of pooling is to reduce the height and width dimensions of images.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image7.png)

At this stage of the course, we have covered the **basic components** in the top row: convolutional layers, pooling layers, and fully connected layers. These were initially introduced in neural network courses and essentially involve matrix multiplication followed by an activation function.  

In this lecture, I will discuss remaining layers commonly used in CNNs, including **normalization layers** and **regularization techniques** like dropout as part of model architecture. Finally, we will revisit activation functions, focusing on those most widely used historically and in contemporary deep learning.  

Starting with normalization layers, their **core concept** is to compute statistics of input data (such as mean and standard deviation), then use these statistics to normalize the data, enabling the model to learn the optimal data distribution during training.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image8.png)

Specifically, we scale and shift input data using learned mean and standard deviation parameters. All normalization layers follow two steps: first normalize input data to unit Gaussian distribution (zero mean, unit standard deviation), then apply learned scaling and shifting operations. Although various normalization layers follow this high-level process, their core difference lies in how statistics are computed—particularly how mean and standard deviation are calculated, and which data dimensions these statistics are applied to.

**Layer Normalization**, as the most widely used normalization technique in current deep learning (especially in Transformer architectures), when processing input data X with batch size N and dimension D, independently computes mean and standard deviation along dimension D for each sample. The model learns scaling and shifting parameters through gradient descent, which are applied to standardized data after each sample undergoes mean subtraction and standard deviation division.

The **core idea** remains consistent across different normalization layers—they all perform similar computational processes, with the main difference being the specific way mean and standard deviation statistics are computed.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image9.png)

This visualization chart from the paper **"Group Normalization"** provides insightful comparison of various normalization methods. Although this technique is not widely adopted today, it clearly demonstrates differences between these network layers.  

Regarding Layer Normalization, I previously described a simple scenario involving vector normalization. But in convolutional neural networks, we must consider both channel dimensions (depth) and spatial dimensions (height and width) of images.  

Layer normalization processes each sample independently by computing mean and standard deviation across all channels and spatial dimensions. As shown in the figure, this means computing a single mean and standard deviation across all these values.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image10.png)

For each input data point, we compute a single **mean** and **standard deviation** across all channel, height, and width dimensions. This is what layer normalization performs.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image11.png)

However, these statistics can be computed differently. In **Batch Normalization**, each channel uses a single mean and standard deviation for computation, then this result is only applied to the corresponding channel.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image12.png)

In **Batch Normalization**, you average across all data in the batch. **Instance Normalization** has finer granularity, followed by **Group Normalization**. These layers essentially perform the same function: normalize data and incorporate learnable scaling and shifting parameters. But they compute statistics differently because they use different subsets of input data.

For **Layer Normalization**, we compute one mean and one standard deviation separately for each image or input data. In contrast, batch normalization computes mean and standard deviation for each channel based on all data within mini-batches during gradient descent. This figure effectively demonstrates differences between different normalization layers. If unclear after the lecture, you can review the chart to understand blue highlighted values—these are the values used to compute and apply statistics.

Finally, a clarification: "**channels**" here refers to depth dimensions, not layer numbers.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image13.png)

The number of values at each spatial position varies. We have already discussed **normalization layers**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image14.png)

**Core concepts** include computing these statistics, applying them to input data, then learning scaling and shifting parameters for subsequent use.  

The next layer type to discuss is **dropout**, a regularization technique in convolutional neural networks. Mastering this final layer will enable us to explore various CNN architectures developed over the years.  

(Note: Professional terminology handling:  
1. "dropout" uses industry-standard translation "随机失活", with English original retained in parentheses on first occurrence  
2. "CNNs" retains English abbreviation form, as Chinese technical literature commonly uses "CNN" directly  
3. "scale and shift parameters" translated as "缩放和移位参数", accurately conveying linear transformation meaning in image processing)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image15.png)

**Dropout** introduces randomness during training and removes it during testing. Its purpose is to increase the difficulty for models to learn training data, thereby improving **generalization ability**, which is a **regularization** method.

Specifically, during forward propagation of each layer, we randomly zero out some outputs or activation values. The main parameter of dropout layers is **dropout probability**, which is a fixed hyperparameter. Common values are 0.5 or 0.25, representing the proportion of values to be zeroed.

These zeroed values then propagate to the next layer, eliminating related computations. **Masking techniques** can be used to optimize this process—since any number multiplied by zero equals zero.

Dropout's effectiveness is mainly based on experimental validation rather than perfect theoretical support.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image16.png)

Understanding dropout's mechanism can be achieved by analyzing its impact on network behavior, which intuitively demonstrates its value. **Dropout essentially forces networks to develop redundant feature representations**. Suppose a layer (e.g., before the model output layer) is learning a set of features, which in CNNs might include detecting ears, tails, fur, or paws in images, ultimately contributing to the probability score for identifying cats.

**Dropout's core advantage** lies in preventing models from over-relying on specific features during training. By randomly discarding certain feature values, models are forced to establish broader associations between features and output categories. For example, models cannot classify images as cats based solely on the presence of ears and fur—even if these features are highly correlated with cats in training data. This mechanism promotes better generalization when models face new data, because these correlations may not hold in new data.

Dropout achieves this by ensuring models don't consistently encounter certain feature combinations during training, thereby reducing dependence on specific co-occurrence relationships. This principle applies not only to cat classification tasks but also to recognition of other categories (like trees), where feature dropping logic follows similar mechanisms.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image17.png)

The dropout process is entirely random, involving no manual selection.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image18.png)

In this case, **50% of features** are randomly discarded and zeroed at each step. This eliminates the need for manual feature selection, which is an **advantage**. However, this process is entirely random.

Models must adapt to situations where only partial features are visible, such as **tails and paws** in this example. Therefore, since models can only access partial feature sets during training, their performance on training data may decrease.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image19.png)

Although omitting certain information may reduce model performance during training, the **key concept** is that it ultimately improves performance during testing. This is because dropout techniques are not applied during the testing phase.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image20.png)

The final component to discuss is the concept of **test-time behavior** in dropout. During training, we introduce randomness by randomly discarding certain activation values, but this operation is not performed during testing. At test time, all activation values are retained, and dropout functionality is completely disabled.

This mechanism raises an important question: if 50% of activation values are discarded during training, then each layer's input during testing would actually have 50% more values. If not handled, this difference would cause problems. To maintain consistent numerical magnitude between training and testing phases, activation values must be scaled by **dropout probability**. For example, when dropout rate is 50%, remaining activation values should be multiplied by 0.5 to maintain expected input scale. If this operation is ignored, input magnitude during testing would significantly increase, leading to unstable behavior.

For **backpropagation** processes, this scaling principle must also be applied to ensure gradient consistency.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image21.png)

During **backpropagation**, when certain values are zeroed, it's equivalent to not traversing that path in the directed graph. This behavior is similar to **ReLU activation functions**—when values are zero, gradients are also zero, so nodes further back in the computational graph won't compute gradients. When **dropout** is applied, weights related to discarded activation values won't be updated during gradient descent.

The testing phase uses all output activation values without random dropout. But each activation value must be scaled by multiplying by dropout probability \\( p \\) to compensate for increased input quantity each node receives during training. This scaling operation ensures stable magnitude and variance of input signals.

Regarding adding noise to images, this is indeed a viable solution, with specific methods to be explained in subsequent slides.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image22.png)

This is a specific piece of code. We have already discussed this, so I won't elaborate further. Essentially, it randomly discards a certain proportion **\\(p\\)** of activation values during training, then performs corresponding scaling during testing.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image23.png)

The next topic is **activation functions**. By now, you have learned all key layers in convolutional neural networks, and next we will explore these activation functions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image24.png)

The main purpose of **activation functions** is to introduce nonlinearity to models. Currently, convolution operations (i.e., kernels sliding across images) and fully connected layers, if lacking activation functions, all operations remain linear because they only involve multiplication and addition. **Activation functions** are crucial for introducing nonlinearity.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image25.png)

Historically, **sigmoid functions** were widely used as activation functions. However, they have a key flaw that explains their gradual obsolescence in modern applications. Graphically, sigmoid functions follow the equation shown in the upper right corner of the slide.

The main problem manifests in empirical research: after multiple layers of sigmoid activation, **gradients** significantly decay during backpropagation. Although gradients at the final layer initially have large values, as backpropagation progresses toward shallower layers, gradient values become increasingly smaller.

This phenomenon is particularly evident in regions where sigmoid function gradients are extremely small—specifically when input values are extremely large positive or negative values. This **vanishing gradient** problem is the main flaw of sigmoid activation functions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image26.png)

As shown in the figure, gradients are almost flat. **Derivatives** are very small, meaning that in most of the input space—from negative infinity to positive infinity—gradients remain at extremely small values.

Only in narrow central intervals do gradients deviate from zero. Therefore, at extreme values on both ends, gradients rapidly approach zero.

This indicates that if values input to **sigmoid functions** are very large or very small, the resulting gradients will also be extremely tiny.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image27.png)

The main reason Rectified Linear Units (ReLU) are widely adopted lies in their behavior in positive regions—where derivatives are constant at one. However, in negative regions, gradients are zero, forming flat parts. This makes gradients one in half the input domain and zero in the other half, which is superior to activation functions where gradients are almost zero except in small central ranges.  

Additionally, **ReLU** is computationally efficient because taking the maximum of input values and zero is simpler than computing sigmoid functions. Despite these advantages, ReLU still has the problem of zero gradients for negative inputs. To address this flaw, recent new activation functions alleviate this limitation by introducing non-flat segments near zero points.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image28.png)

This is **ReLU** (Rectified Linear Unit), and there's another variant I'll show on the slide but won't delve into its formula. They look very similar. The core idea is to smooth ReLU's sharp transition from zero to one derivative at the origin. ReLU is a sharp and non-smooth function, while **GELU** (Gaussian Error Linear Unit) provides non-zero gradients in this region. When \\(x\\) approaches positive or negative infinity, GELU converges to ReLU, but exhibits smoother behavior in intermediate ranges.  

Specifically, GELU computes **Gaussian Error Linear Unit**, based on the cumulative distribution function of standard normal distribution. Function \\(\\phi(x)\\) represents the area under the Gaussian curve at any point \\(x\\). For extremely negative values, \\(\\phi(x)\\) approaches zero, making GELU behavior converge to ReLU in this region; for larger positive values, \\(\\phi(x)\\) approaches one, making GELU converge to \\(x\\).  

GELU combines these excellent properties, converging to ReLU at extreme values while maintaining smoothness in intermediate regions. It is currently the **primary activation function** in Transformer models.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image29.png)

Upon careful examination, these activation functions mostly have similar properties. Their **core idea** lies in containing a relatively flat region that asymptotically approaches the identity function \\(f(x) = x\\) in extreme cases, thus essentially exhibiting linear characteristics.

SiLU (Sigmoid Linear Unit) is defined as \\(x \\cdot \\sigma(x)\\), where \\(\\sigma\\) represents the sigmoid function. This formula exhibits properties of approaching zero for strongly negative inputs and approaching 1 for strongly positive values. Notably, this behavior is similar to the cumulative distribution function \\(\\Phi(x)\\) of standard Gaussian distribution, which explains their visual similarity in shape.

A naturally arising question is: where are these activation functions typically applied in **convolutional neural network architectures**?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image30.png)

The common practice is to place **activation functions** after linear operators. This principle applies to feedforward layers, linear layers, and fully connected layers—these terms actually all refer to the same type of layer.

Specifically, activation functions are located after **matrix multiplication** operations. Similarly, in convolutional layers, activation functions are also arranged after linear operations.

Therefore, whether processing convolutional layers or fully connected layers, activation functions are applied after these linear transformations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image31.png)

You now understand all components of Convolutional Neural Networks (CNNs). Next, I will explain through examples how to integrate these components to build **state-of-the-art** convolutional neural network architectures.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image32.png)

This slide clearly presents two key metrics. **Blue bar charts** show error rate trends over time for different models trained on ImageNet dataset, while **orange triangles** mark the corresponding layer counts for each model. Notably, when error rates significantly decreased (marking the first milestone surpassing human performance), we can observe substantial increases in model depth.

Today's lecture will analyze how this breakthrough was achieved, focusing on design challenges and objectives. From a historical perspective, **AlexNet** first successfully applied CNN architectures to ImageNet and fully utilized GPU acceleration advantages. Although we have previously discussed AlexNet's historical significance, I will now compare it with **VGG**, the standard architecture widely adopted in the 2010s.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image33.png)

I will draw these two CNN architectures side by side. In the **artificial intelligence** field, we typically use block diagrams to present model architectures, where each block corresponds to an independent layer or stacked layer group. This visualization method allows immediate identification of **key differences**.

Orange blocks represent 3×3 convolutional layers with stride 1 and padding 1, ensuring complete coverage without dimension reduction during image processing. These convolutional layers alternate with max pooling layers. After each pooling layer, two fully connected layers are visible: the first with dimension 4096, the second with 1000. The final layer dimension matches the 1000 class outputs required for ImageNet classification.

This architecture is like an enhanced version of **AlexNet**, with more layers added. Notably, it uses three consecutive convolutional layers before each pooling operation, rather than single or double layer structures in earlier architectures. Remarkably, these models achieve excellent performance using only three basic layer types.

A natural question arises here: why choose 3×3 convolutions? This choice was carefully considered. This architecture specifically adopts designs with three (sometimes four) such convolutional layers arranged consecutively.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image34.png)

Let me pose a question: what constitutes an **effective receptive field**? We previously explored the concept of receptive fields, which refers to regions in input images that can affect specific values in activation maps. Specifically, it determines which input values contribute to final activation maps after passing through multiple model layers.

Suppose there are three consecutive layers, each using \\(3 \\times 3\\) convolution with stride 1. What is the effective receptive field for each value in activation map \\(A_3\\) after the third layer?

For any value in \\(A_3\\), its computation involves a \\(3 \\times 3\\) numerical grid in \\(A_2\\). Similarly, each value in \\(A_2\\) originates from a \\(3 \\times 3\\) grid in \\(A_1\\), while values in \\(A_1\\) depend on a \\(3 \\times 3\\) region in the input.

Looking specifically at this expansion process:
- At \\(A_1\\) layer, each value corresponds to a \\(3 \\times 3\\) region in input  
- At \\(A_2\\) layer, receptive field expands to \\(5 \\times 5\\)  
- At \\(A_3\\) layer, receptive field further grows to \\(7 \\times 7\\)  

This expansion occurs because \\(3 \\times 3\\) convolution with stride 1 increases receptive field by one pixel in each direction (i.e., total expansion of two units) at each layer. Therefore, stacking multiple such layers systematically expands receptive fields at a rate of two pixels per layer.

By visualizing this process, we can clearly see the cumulative effect of consecutive convolution operations on receptive field size.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image35.png)

We have proven that stacking three **stride-one 3×3 convolutional layers** has the same effective receptive field as a single 7×7 convolutional layer.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image36.png)

The question is to what extent these findings are **post-hoc rationalization** versus intuition that truly guides experimental design. This may vary by architecture. For example, the next architecture we'll discuss—**ResNet**—originated from empirical observations of an inspired thought experiment. In ResNet's case, there was clear intuition driving exploration of effective design.

For the current architecture, since authors haven't publicly discussed it, I cannot assert whether design choices were based on empirical findings or post-hoc reasoning. But ResNet's development was **hypothesis-driven**.

Here's an interesting property: three stacked 3×3 convolutional layers have the same **effective receptive field** as a single 7×7 layer, yet use fewer parameters. Assuming constant channel dimension \\(C\\), each 3×3 filter contains \\(3 \\times 3 \\times C\\) parameters. Each layer has \\(C\\) such filters, so single layer parameter count is \\(3^2 \\times C^2\\). Total parameter count for three stacked layers is still less than a single 7×7 layer, while being able to model more complex nonlinear relationships.

Therefore, advantages of stacking 3×3 layers include: fewer parameters and ability to model more complex relationships in input data, making it superior to using single large-size filters.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image37.png)

Now, let's discuss Residual Networks (ResNets). This topic relates to thought experiments mentioned in recent questions. An empirical finding significantly influenced ResNet's design—specifically, when we continuously stack deeper layers and expand networks on ordinary **CNN architectures** (such as VGG), an interesting phenomenon occurs.

Research shows that 20-layer models actually have lower test errors than 56-layer models. People might think this difference stems from overfitting, but that's not the case. 20-layer models also have lower training errors, indicating superior performance on both training and test metrics.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image38.png)

Why do **56-layer models** perform worse than 20-layer models? This seems counterintuitive. As mentioned earlier, the problem isn't overfitting. Deeper models have stronger representational capacity and theoretically should be able to cover all mapping relationships achievable by shallower networks. The potential mapping set of larger networks is a superset of smaller networks.

For example, deeper models can simulate shallower models by setting certain layers as **identity functions**, making these layers essentially ineffective. Therefore, the challenge isn't representational capacity but **optimization difficulty**, because deeper networks have broader solution spaces.

Taking two-layer models versus single-layer models as an example. If a certain layer in the two-layer model is configured as an identity matrix (or identity function), its performance should at least match the shallow model. The key is embedding this intuition into model architecture so it can match or surpass shallow model performance during optimization.

This goal is achieved through **residual mapping**. Instead of directly learning target mappings, models learn residual functions. Input \\(X\\) bypasses convolutional layers through shortcut connections, so residual function \\(F(X)\\) only needs to learn zero values (close to zero in practice). Output becomes \\(X + F(X)\\), where \\(F(X)\\) represents the difference between expected output \\(H(X)\\) and input \\(X\\).

This method simplifies optimization by allowing models to bypass unnecessary layers, thereby promoting learning of identity mappings.

This is called **residual blocks** or **residual connections**, whose principle is copying and adding values from earlier layers to later layers in the model. This design stems from observed phenomena: due to optimization difficulties, larger networks often produce worse training and test errors. The goal is designing models that can at least match shallower network performance, and introducing residual connections achieves this—it allows values to be easily copied and added, embedding this functionality directly into architecture rather than relying on convolutional layers to learn identity mappings. Empirically, this approach is extremely effective.

Residual blocks operate as follows: input \\(X\\) passes through two convolutional layers to get output \\(F(X)\\), then original input \\(X\\) is added to this output, resulting in \\(F(X) + X\\). Here \\(X\\) represents the previous layer's output, or input image in the first layer case.

A potential concern might be: if data is insufficient, would lack of residual blocks hinder training? But actually, residual blocks significantly improve models' ability to learn from large datasets by solving optimization difficulties. **Transformer** architectures also adopt residual blocks for similar reasons—they promote modeling of more complex functions and improve data utilization efficiency. Residual blocks enhance models' ability to represent broader functions, making them particularly important in deep learning architectures.

Regarding "whether extending training time could make large network performance converge to small network levels": although large models naturally require longer training times, residual connections alleviate some optimization difficulties, thereby simultaneously improving efficiency and performance.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image39.png)

The answer is no; regardless of training duration, these models failed to reach smaller model performance levels. **The reason is they got stuck in local optima.**

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image40.png)

When you introduce these **residual connections**, certain problems can be alleviated. The exact mechanism remains a frontier area of current research. We find it difficult to fully understand why these models can avoid local minima rather than converge to optimal solutions, or what specific factors prevent them from discovering better solutions.

This finding is mainly based on empirical observations, although there is partial theoretical intuition support. Specifically, the intuition at the time was to ensure deeper models could at least achieve performance comparable to shallower models—which had been proven to achieve better results at the time.

This limitation cannot be overcome by simply extending training duration; deeper architectures inherently cannot match shallower model performance.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image41.png)

The overall **ResNet** architecture consists of multiple stacked residual blocks. Each residual block contains a \\(3 \\times 3\\) convolutional layer with ReLU activation function, followed by another \\(3 \\times 3\\) convolutional layer. Input \\(x\\) is added to the output of these convolution operations, then passes through a final ReLU activation function.

This **skip connection** (represented by straight lines bypassing modules) allows original input to be added to transformed output, which is the hallmark feature of residual blocks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image42.png)

**ResNet's** notable feature is building a family of models with varying depths, covering architectures from smaller to larger. As layer count increases, performance improves, but gains from larger models gradually diminish, indicating possible performance bottlenecks on given datasets.

**Early models** show significant improvements, while performance differences between ResNet-101 and ResNet-152 are minimal, with only about 1% variation. The theoretical basis for choosing 152 layers remains unclear, possibly an experimental choice to explore optimal depth.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image43.png)

When experimenting with different layer counts in models, the common practice is to first train the **smallest model** and evaluate its performance. Then gradually add more layers to determine if performance improves. This iterative approach likely explains why **ResNet architecture** stops at 152 layers—because continuing to add layers didn't bring significant performance improvements. Additionally, **GPU memory limitations** impose practical constraints on model scale, as larger models require more parameters to fit available memory.

From a hardware perspective, due to these memory limitations, training increasingly larger models becomes more difficult. Each model configuration (e.g., 18 or 34 layers) must be trained separately.

Regarding design principles of **CNN modules** with residual connections, the core lies in these connections enabling networks to learn **increments** (i.e., differences between original input and expected high-level features) rather than directly learning features themselves. This method can still achieve hierarchical feature abstraction because each module continuously refines feature representations while preserving original information. Its operation mechanism is building more complex features step by step through learning these residual mappings.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image44.png)

You learn a function **\\(f(x)\\)** and add it to previous input, essentially learning residual \\(\\Delta\\). The question then arises: does this addition operation require tensors to have the same size? **The answer is yes.**

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image45.png)

This property is particularly advantageous because all these layers use **stride 1, padding 1 \\(3 \\times 3\\) convolutions**, thereby maintaining spatial dimension consistency between subsequent layers.  

For example, after pooling layers, direct addition becomes infeasible due to tensor size mismatches. Therefore, in standard implementations, such operations are typically performed before pooling.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image46.png)

A potential solution is to distribute each value across multiple values. Here are **key insights** about ResNets.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image47.png)

Another notable technique they adopted is periodically **doubling filter counts** and downsampling spatial dimensions after certain numbers of residual blocks. Initially, when flat input images propagate through neural networks, activation values cause spatial dimensions to shrink while depth increases. Eventually these activation values compress into vectors used for classification. This conceptualization process helps intuitively understand transformation processes of values and their shapes in networks.

A **distinctive feature** of ResNet (though other architectures also possess it) is adding a relatively large convolutional layer before residual blocks. Empirical research shows this design improves model performance, which is entirely based on experimental observations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image48.png)

To highlight its importance, these larger models perform extremely well. This was the first time researchers successfully trained models exceeding 100 layers, marking an **important milestone**.

Subsequently, Residual Networks (ResNets) were widely applied to various computer vision tasks due to their excellent performance, mainly attributed to their residual connection structure.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image49.png)

We explored various **CNN architectures**, with **ResNet** and **VGG** as main cases. We analyzed advantages of small-size convolution kernels and benefits brought by multi-layer stacking.  

The final topic before building CNNs and preparing for training is discussion about **weight value initialization** for each layer.  

(Note: Technical terminology handling:  
1. "CNN architectures" retains English abbreviation + Chinese "架构" hybrid translation, conforming to Chinese technical literature conventions  
2. "ResNet/VGG" keeps English original names untranslated, as they are proprietary model names  
3. "filter sizes" translated as "卷积核尺寸" rather than literal "过滤器", reflecting computer vision field terminology standards  
4. "weight values initialization" uses standard translation "权重值初始化", consistent with domestic machine learning textbook expressions)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image50.png)

**Initialization value** selection is crucial because choosing values that are too small or too large causes serious problems during model training. Here we use a six-layer fully connected network with feature dimension 4096. Weights are initialized using unit Gaussian random distribution, multiplied by scaling factor 0.01 to ensure values are close to zero. Each layer also includes **ReLU activation functions**.  

When plotting this model's forward propagation process, due to ReLU activation functions ensuring all means are positive, initial layers exhibit high means and standard deviations. However, as signals propagate layer by layer, means and standard deviations gradually decrease due to small weight initialization. Ideally, we want these statistics to remain consistent across all layers, which simplifies **optimization problems**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image51.png)

If we use **0.05** instead of 0.01, what problems might occur when this value is set too large?

When this value is too small, it approaches zero. Conversely, if this value is too large, activation values at each layer will increase layer by layer.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image52.png)

If data is plotted here, we can observe that **significant means and standard deviations** will eventually appear. Training a 152-layer Residual Network (ResNet) would quickly amplify this problem. How to solve this?

In this case, the **optimal value** might be around 0.022, but how to determine this? More broadly, how to apply this method to arbitrary layers?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image53.png)

There are multiple methods for weight initialization. Today in class we will focus on discussing the **most commonly used one**, while also mentioning the existence of other methods.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image54.png)

These values are usually functions of **dimensions**. For example, a fully connected layer with 4096 dimensions compared to one with 2048 dimensions would have different values.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image55.png)

The specific method we will discuss is called **Kaiming initialization**, proposed by Kaiming He, who is also the creator of **ResNet**. As a highly prestigious researcher in computer vision, he is one of the most cited computer scientists in the past 10 to 15 years, enjoying great reputation in this field.

He proposed the idea of initializing parameters to \\(\\sqrt{\\frac{2}{D_{\\text{in}}}}\\) (where \\(D_{\\text{in}}\\) represents input dimension size). Although we won't delve into derivation details, this initialization method ensures relatively stable standard deviations and means across layers when using **ReLU activation functions**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image56.png)

Plotting this chart intuitively demonstrates its effects. You can view it as a **magic formula**—once applied, ideal properties are obtained.  

For readers interested in derivation processes, we have attached relevant paper links. Although we won't explore details here, this method indeed achieves the expected effect of maintaining **constant means and standard deviations**.  

Additionally, you can also determine optimal parameter values for specific configurations through experimental means.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image57.png)

Okay.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image58.png)

We have discussed **weight initialization**, ways different layers combine to form CNN architectures, commonly used **activation functions**, and various layer types in CNNs.

Since the content is quite rich, I will pause briefly to answer questions. Part Two of the lecture will be lighter than Part One.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image59.png)

We will focus on practical techniques for training these methods. **The question is how to perform weight initialization for CNNs.** You still use the same initialization method, but dimensions need to correspond to convolution kernel sizes. For a 3×3 convolution kernel with 6 channels, its dimension should be \\(3 \\times 3 \\times 6\\).

**Core concepts remain unchanged**, but dimension calculations vary with network layer types. This can be understood as the number of parameters involved in each operation—specific values depend on network layer types. Although some layers use different weight initialization methods, this text discusses specific application scenarios of timing initialization in CNNs.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image60.png)

The question is why **activation values explode** when initial values are too large. Imagine you initialize every layer in the network with random initial values. If these values are too large, subsequent **ReLU activation functions** won't limit layer outputs, causing them to grow to infinity.

When all weights are initialized to the same set of large random values, each layer multiplies large numbers with another set of large numbers, making outputs continuously increase with each iteration. This can be viewed as a **recursive relationship**—values are multiplied at each step. Ideally, multiplication factors should be 1, but since we're multiplying vectors with matrices, average output depends on vector dimensions and ReLU activation functions.

ReLU activation functions eliminate negative values, retaining only positive outputs. If initial values are very large, **standard deviations** of activation values will also be large. After removing the negative half, means continuously shift toward positive direction.

**Normalization** can solve activation value explosion problems, but optimization processes may still be challenging. More details can be found in this paper, which is quite accessible.

Now, let's discuss specific steps for training models.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image61.png)

One advantage of data preprocessing lies in its simplicity for images.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image62.png)

For large image datasets, standard practice is to separately compute **means** and **standard deviations** of pixels for red, green, and blue channels. Then normalize input images by subtracting means and dividing by standard deviations, constituting basic image data standardization.

Although statistics for each channel need to be precomputed, the industry typically reuses **ImageNet means** and standard deviations, even when training on non-ImageNet data. Choice of normalization parameters depends on specific datasets, and different models may adopt different values, but ImageNet statistics remain the most widely used default values.

This standardization operation is performed before all input images are processed by models.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image63.png)

Regarding **data augmentation**, the suggestion of adding noise to images was raised earlier in class. This is an excellent idea because it helps with **regularization** and prevents overfitting.

Next we will discuss various methods of introducing noise into images.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image64.png)

This is a common pattern in **regularization**, introducing randomness during training, then eliminating it through averaging during testing.  

For example, in **dropout** techniques, 50% of activation values are randomly discarded during training, while all activation values are used during testing, scaled by dropout probability \\(P\\).  

This pattern also applies to **data augmentation** techniques.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image65.png)

You can imagine this cylinder as your dataset. First, load an image and its corresponding label—for example, an image of a cat and its label. In modern deep learning, before inputting such data into models, standard practice is applying **data augmentation** techniques for training computer vision models.  

The core idea is changing image appearance through various transformations while maintaining its recognizable category. These augmented images are then input into models to compute loss.  

A **key advantage** of this method lies in effectively expanding datasets, because each original image will be presented in multiple transformation forms, all retaining the same category label.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image66.png)

By increasing data volume, models' **generalization ability** can be improved. However, since models encounter diverse samples rather than repeatedly memorizing identical instances, this causes training loss values to increase.

This leads to a key question: how should we determine the best **weight initialization** scheme?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image67.png)

In this case, **means and standard deviations** remain relatively constant across network layers, indicating system stability. We don't observe any **pattern collapse** to zero phenomena.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image68.png)

In this scenario, as layer count increases, values diverge to infinity. To prevent this, we can use **specific formulas** to ensure correct initialization. This is standard practice in practice.  

But if you're designing **novel layers** with unique operations, you may need to try multiple weight initialization schemes to determine optimal solutions. For standard linear layers or convolutional layers, **Xavier initialization formulas** are recommended.  

Returning to data augmentation topics.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image69.png)

Specific augmentation methods include **horizontal flipping**, depending on problem types.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image70.png)

If you need a model that can read text, **horizontal flipping** would be a poor data augmentation choice because mirrored text becomes unreadable. However, due to symmetry of everyday objects, this technique is usually effective for them.

For special scenarios like microscope images or aerial images, **vertical flipping** might be appropriate. But for common objects like cats, vertical flipping usually makes no sense because they are typically observed in standard orientations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image71.png)

However, if your dataset contains cat images from various angles, applying transformations like **flipping** or **rotation** might be helpful.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image72.png)

Another data augmentation method involves resizing and cropping operations. Models like **ResNet** and various deep learning architectures typically perform random cropping on images and scale them to target sizes, sometimes even performing multiple crops.

Standard processing flow is: first determine the length of the image's shorter side. For example, if input size is 224×224 pixels, then select a value larger than this size and determine cropping regions containing this larger scale \\(L\\).

For example, given an 800×600 image, when \\(L=256\\), scale the shorter side (600) to 256 while proportionally adjusting the longer side's (800) size. This maintains relative resolution while adapting to \\(L\\) scale. Then randomly crop 224×224 local regions from the scaled image.

This method called **random scale cropping** has been widely adopted by most algorithm libraries.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image73.png)

This technique is widely applied to most problems due to its effectiveness in maintaining **relative resolution** of images.

Another practical technique is **test-time data augmentation**, which can significantly improve model performance. For best results, multiple cropped and resized versions of input images can be generated, processed through models, then predictions averaged.

For **ResNet** models, practitioners typically try different scaling ratios, cropping positions, and even horizontal flipping. Although returns may diminish, this method can still bring 1-2% performance improvements. If pursuing ultimate accuracy, test-time data augmentation is almost a valuable technique applicable to all computer vision problems.

Finally, **color jittering** is another augmentation method worth attention.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image74.png)

Here, we deliberately randomize contrast and brightness and adjust image proportions accordingly. This may make colors appear softer or brighter. These all fall within the scope of **traditional image processing techniques**.

Usually, we try different augmentation parameter values to ensure images remain within expected distribution ranges and appear natural to human observers. This method helps determine appropriate values for **color jittering**, brightness changes, and other parameters.

When tackling new problems, I test multiple augmentation methods, filtering out those that can change data while maintaining recognizability. Through this process, ultimately obtaining a robust augmentation scheme suitable for practical scenarios.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image75.png)

The final technical means involves cropping partial regions of images and replacing them with black or gray squares. Although used less frequently, this method demonstrates **flexibility of data augmentation** for specific problems.  

For example, in scenarios where objects might be partially occluded (such as when camera view is blocked), this technique can effectively improve model robustness to such occlusions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image76.png)

Under given settings, consider which **data augmentation** methods are appropriate. Determine how to transform input data so it remains recognizable to human observers while increasing difficulty for models to memorize training samples.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image77.png)

The final set of topics we will explore are highly practical. Whether you're working on course projects or training models in any **computer vision** field, techniques discussed in upcoming slides can be directly applied.  

In practice, we often face situations with **limited data**. For example, the original ImageNet dataset contains one million images, but unless you're in large teams, most people cannot access such massive data.  

This raises a question: can you effectively train Convolutional Neural Networks (CNNs) with limited data? The answer is yes, but requires careful and strategic implementation.  

(Note: Professional terminology handling:
1. "computer vision" retains professional field standard translation "计算机视觉"
2. "CNNs" uses "卷积神经网络(CNNs)" translation on first occurrence, with English abbreviation retained in parentheses for technical document precision
3. "ImageNet" as proper noun not translated
4. "strategic implementation" translated as "策略性地实施" to maintain technical document rigor)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image78.png)

In previous lectures, we showed how different filters in Convolutional Neural Networks (CNNs) extract various features. This relates to the hierarchical feature structure of CNNs. Initially, networks detect **edges**, patterns, or small shapes.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image79.png)

At the highest level, when images are processed through Convolutional Neural Networks (CNNs), the final vector obtained before classification layers can be compared with other images in the dataset. Similar images have extremely close vector values. This is similar to nearest neighbor methods, but instead of using raw pixels, we use vectors generated by CNN's second-to-last layer (such as 4096-dimensional or 2048-dimensional layers).  

By computing **L2 distances** between these vectors, we can observe that images of the same category have extremely small differences in feature space. This indicates these features are extremely effective for classification. Linear classifiers or k-nearest neighbor classifiers built on these features can achieve excellent performance.  

In practice, this technique can be applied through **transfer learning**: one method is training models on large datasets like ImageNet or using pre-trained models. Freeze existing layers to preserve original weights while replacing final classification layers to match target dataset class counts. Only newly added layers are updated during training.  

This method forms sharp contrast with traditional computer vision paradigms—which rely on predefined feature extractors like color histograms. Modern CNNs can automatically learn these features, providing superior performance and flexibility.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image80.png)

You can view **frozen models** as fixed, unchanging predefined feature extractors. We use them to compute features, then train upper-layer models based on these features. Under given paradigms, this method is very similar because no training process is involved here.

For larger-scale datasets, the most effective approach is initializing entire models with **pre-trained weights** (e.g., from ImageNet or other large-scale datasets) and performing complete training. In most of my work, since I usually have millions of training samples, I adopt this third approach: first use models trained on billions of samples (far exceeding my computational resource capabilities), then fine-tune on my small-scale dataset. This approach works better than training models from scratch because pre-trained models have already mastered superior feature extraction capabilities. **Fine-tuning** ensures models maintain characteristics specific to my particular problem.

For example, suppose training models on ImageNet. We replace the last layer to output our dataset's class count rather than the original 1000 classes. This new layer uses random initialization methods previously discussed, while other layers retain pre-trained weights. During **gradient descent**, these weights remain frozen.

The specific process is inputting images into models, where each image generates a 4096-dimensional vector. This is similar to training linear classifiers: using this vector as input, mapping to target class counts. Only this final mapping relationship is trained.

This raises a question: will models have **bias** due to ImageNet training? The answer is yes. Models trained this way perform best on datasets similar to ImageNet (such as images containing everyday objects like laptops, classrooms, or people), but perform poorly on data that differs significantly (like Mars photos). This bias stems from pre-trained models' training data distribution, so models must be used within similar object or scene distribution ranges to be effective.

The question is: what do you do when your dataset is **out of distribution**? I have a slide specifically discussing this problem.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image81.png)

This is a good question. If you have highly similar but limited datasets, you can adopt the **linear classifier strategy** previously discussed. For similar datasets with sufficient data, fine-tuning all network layers achieves best performance—this corresponds to the second and third strategies I mentioned on the slide.  

However, what if datasets differ significantly? With sufficient data, training from scratch might be more appropriate, though initializing with pre-trained weights may still improve performance—this requires empirical testing because effects cannot be guaranteed. For datasets with extremely limited data or excessive differences, recommend finding **models pre-trained in related domains**. Researchers have explored specific techniques for out-of-domain generalization, but this remains an active research area with no universal solutions.  

For example, **language models** show strong generalization capabilities across different domains. The most challenging situation is handling data-scarce entirely new problems, making model training particularly difficult.  

Regarding compromise methods between fine-tuning single layers and all layers, researchers have extensively explored training partial network layer schemes, which is a relatively mature research area in practical applications.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image82.png)

There's also a technique called **LoRa** that might be covered in Transformer courses. Its core idea is fine-tuning all layers by learning low-rank differences between layers rather than directly modifying layer parameters. This method is similar to how **ResNet** learns residual differences, but LoRa can achieve this goal with fewer parameters.

This raises a question: how are network layer counts determined? Specifically, why use two convolutional layers for each size rather than one? This design is similar to early **VGG** paradigms—three \\(3 \\times 3\\) convolutions can achieve the same receptive field as a single \\(7 \\times 7\\) convolution, while multiple activation functions can model more complex nonlinear relationships. Therefore, using more small-size filters has stronger expressive power than few large-size filters.

We continue advancing.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image83.png)

To effectively use **transfer learning**, first find a large-scale dataset containing similar data, obtain models pre-trained on that dataset, then fine-tune that model for your specific dataset.

Practical resources include **PyTorch Image Models** (providing numerous models trained on datasets like ImageNet) and PyTorch Vision's GitHub codebase.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image84.png)

I will briefly discuss hyperparameter selection at the end.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image85.png)

If encountering difficulties during model training with performance below expectations, the recommended initial debugging strategy is **overfitting on small samples**. Specifically, use a single data point to verify whether training loss can converge to zero. If models cannot remember one training sample, there may be code errors or inappropriate model selection. This method also helps determine appropriate learning rate ranges, providing general direction for subsequent parameter tuning.  

After model validation, **coarse-grained grid search for hyperparameters** can be performed. First test different learning rates and observe training loss trends. If a learning rate can make loss continuously decrease within one training epoch, it can serve as a reasonable starting point (though extending training time may be better). After determining effective learning rates, explore other hyperparameters.  

Monitor both training and validation accuracy curves simultaneously. If both continue improving synchronously, continue training; but if training loss increases while validation loss decreases, **overfitting** is indicated. At this point, strengthen regularization or obtain more data.  

When training and validation accuracy gaps are small, continue training until validation accuracy stagnates or diverges from training accuracy. This iterative process can be repeated to optimize model performance.  

During hyperparameter search phases, multiple hyperparameters usually need joint optimization simultaneously.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image86.png)

Should we exhaustively enumerate all hyperparameter combinations, or are there more efficient methods? In practice, **random search** in hyperparameter space performs better than **grid search**—which requires exhaustive evaluation of preset combinations.  

The key lies in distinguishing **important** from secondary hyperparameters. For secondary parameters, their values have minimal impact on model performance. Random sampling can more fully explore important parameter spaces, while grid search inefficiently repeats checking different values of secondary parameters, wasting computational resources.  

Therefore, recommend setting target ranges and randomly sampling hyperparameters within boundaries.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image87.png)

The **optimal method** is to continue training until obtaining the best model.

This lecture covered **layers** and **convolutional neural networks**, activation functions, CNN architectures, and weight initialization.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec6_image88.png)

To effectively build and train these models, we explored several **key aspects**: preprocessing data for model input, data augmentation techniques, and applying **transfer learning** to improve performance.

Additionally, we studied methods for selecting optimal **hyperparameters**.

This lecture covered extensive topic content. Thank you for your attention.



