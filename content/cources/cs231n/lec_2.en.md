---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 2: Image Classification with Linear Classifiers"
date: 2025-09-04T16:10:02+08:00
draft: false
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image1.png)

Today, we will continue from the previous lecture and delve deeper into the topic of **image classification**. We will explore the foundational concepts that lead us toward **neural networks**, ultimately guiding us to convolutional neural networks and beyond.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image2.png)

We will begin with **linear classifiers**. Looking back at the syllabus we discussed in the previous lecture, we outlined three main thematic categories:

1. **Fundamentals of Deep Learning**  
2. Perceiving and Understanding the Visual World  
3. Reconstructing and Interacting with the Visual World  

Each category contains several subtopics. Today we will focus on the first three key points: **data-driven approaches**, **linear classification**, and the **k-nearest neighbor algorithm**.  

Similar to the previous lecture, we will start with the fundamental task of computer vision—**image classification**—as our core topic. This task serves as an excellent benchmark for algorithm performance, and we will repeatedly use it throughout this semester to illustrate how algorithms work.  

Today we will define the image classification task and introduce two data-driven approaches for this task.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image3.png)

One is your neighbor, and the other is the linear classifier.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image4.png)

The supplementary slides list other methods that you can review after class. However, **the focus of this course** will be on the methods outlined here.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image5.png)

Image classification is the task of assigning a corresponding label from a predefined set of categories (such as **dog**, **cat**, **truck**, or **airplane**) to a given image. While humans can easily accomplish this task with their innate holistic visual information processing abilities, it poses significant challenges for artificial intelligence systems.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image6.png)

However, when it comes to encoding and understanding how computers parse this image, the challenge becomes entirely different. **Our focus** is on exploring how machines understand this type of data.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image7.png)

Images are typically represented as data matrices, or more broadly, as **tensors**. Each pixel value is usually between 0 and 255, corresponding to an **8-bit data structure**.

For a color RGB image with 800×600 pixel resolution, the data forms a three-dimensional tensor of size 800×600×3, representing the red, green, and blue channels respectively, as shown in the slide.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image8.png)

As you might have inferred, this represents the **semantic gap** between human perception of images and machine interpretation. To better understand why this poses significant challenges, let's explore some inherent variation factors in imaging data.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image9.png)

For example, consider the case of moving the camera. When the camera moves around while the cat remains completely still, every pixel value in the **800×600×3 image** changes. From a human perspective, the object itself hasn't changed, but from a computer's viewpoint, this constitutes an entirely new data point.

This example illustrates **one of the challenges in computer vision**, though there are many other difficulties.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image10.png)

For instance, **lighting** is a major challenge. In courses on graphics, computer vision, or digital image processing for engineering applications, you'll learn that each pixel's **RGB values** depend on surface material, color, and light sources.  

Therefore, the same object (such as a cat) may exhibit numerical differences under different lighting conditions. Whether the cat is in a dark room or under sunlight, it remains the same cat, but this variation makes machine perception difficult.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image11.png)

Besides the lighting and viewpoint changes I mentioned, can you identify other challenges that might alter pixel values and hinder object recognition? **Background clutter** and **object occlusion** are indeed important factors, which we'll discuss in the next slide.  

(Note: Translating "objects" as "object occlusion" to more accurately convey the meaning of objects mutually occluding each other in technical contexts)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image12.png)

Background clutter presents another challenge. Additionally, the **scale** of objects in images (affected by zoom operations) is also an important factor.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image13.png)

Image resolution constitutes a major challenge.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image14.png)

However, in **machine learning models** or any system designed to recognize objects or actions in images, since we standardize image sizes, resolution may not be a critical factor unless objects exhibit scaling effects. **Occlusion** remains one of the primary challenges.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image15.png)

As humans, we can easily recognize objects like **cats**. Even in the most challenging situations—such as the rightmost image where only a tail and a small part of a paw are visible—we can infer that this is likely a cat. **Contextual cues** (such as the living room environment) support this judgment. However, beyond this, challenges like deformation make the recognition task more complex.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image16.png)

Cats exhibit remarkable deformation capabilities.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image17.png)

These variations pose **significant challenges** for algorithms used to detect and recognize objects. Specifically, **deformation** constitutes a major obstacle for step-by-step object detection systems.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image18.png)

Beyond this, **intra-class variation** presents another major challenge. Cats may vary in size, fur color, patterns, and breed, but they are all classified as cats. However, machines struggle to recognize these intra-class variations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image19.png)

A significant challenge lies in **context**. If an algorithm only analyzes the right portion of an image while ignoring the broader background, it might misclassify it as a tiger or other animal. However, by considering contextual elements like shadows, classification can be performed more accurately.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image20.png)

Modern classifiers excel in image classification and object recognition, largely thanks to initiatives like **ImageNet** and subsequent work that established large-scale benchmarks for training larger models.

In this course, our goal is to develop models capable of recognizing objects and other elements in images.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image21.png)

In the subsequent parts of this course, we will systematically develop the **fundamental components** needed to build these large-scale algorithms.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image22.png)

Before proceeding, we must first examine the **fundamental building blocks** of image classification.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image23.png)

Implementing such functionality presents unique challenges. In traditional computer science or engineering courses, algorithms like **sorting** are built through clear frameworks containing if-then-else rules and loops, forming explicit step-by-step flowcharts. However, this approach cannot be effectively transferred to the field of image understanding and visual world parsing.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image24.png)

There is currently no method to **hard-code** the steps for image classification, although there have been some attempts in this field previously.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image25.png)

Researchers attempted to develop object recognition algorithms through systematic steps. One approach first uses **edge detection** techniques to identify edge contours in images. Subsequently, the algorithm analyzes important feature patterns like corner points, extracts features around corners or counts specific types of corner points, and finally maps these features to output categories.

Although this method achieved some success on images with limited variation, it still faced major challenges: first, such algorithms are difficult to scale because different rules need to be customized for each object category; second, deriving the **underlying logic** for each object requires extensive manual labor.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image26.png)

Due to these challenges, algorithms based on creating logic and programs for object detection or image classification did not achieve significant success. However, **machine learning** provides a data-driven approach.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image27.png)

With this **new paradigm** and data-driven approach, we establish a three-step process.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image28.png)

The first step is to collect a dataset of images and their corresponding labels. To recognize specific types of objects, we can gather data from various sources (such as online datasets or individual data points). In the past, this required using **search engines** and image search tools to compile such datasets. Today, ready-made datasets are available for direct use.

The second step involves using machine learning algorithms to **train a classifier**. This requires building a function that processes training images and their labels, thereby establishing a model that can associate images with correct labels.

The final step is to evaluate the classifier on new images. This requires implementing a **prediction function** that takes the trained model and test images (images not included in the training set) and outputs predicted labels.

This process represents a **data-driven approach** rather than a logic-based approach. We will discuss two commonly used classifiers, one of which is the **nearest neighbor classifier**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image29.png)

This represents the simplest form of classification.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image30.png)

We will focus on this topic to better understand the concepts involved in building **classifiers**, as this helps illustrate **key details**. Subsequently, we will transition to the topic of linear classification.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image31.png)

To build a **nearest neighbor classifier**, we need to implement training and prediction functions. The training function simply memorizes all data and their corresponding labels, essentially storing this information in memory without additional processing. The prediction function finds the training image most similar to the query image by comparing the query image with the stored dataset. This process involves creating a **lookup table** of images and their labels, and during prediction, the function retrieves the label of the most matching image.

For example, suppose there is a training dataset containing five images. Given a query image, the goal is to determine which training image is most similar to it. This requires a **distance function** that evaluates the similarity between the query image and each training image by calculating similarity metrics. There are various methods to define this distance function.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image32.png)

One of the most widely used distance metrics is the **L1 distance**, defined as the sum of absolute differences between corresponding pixels of two images \\(I_1\\) and \\(I_2\\).

For example, to calculate the distance between a test image and a training image, we perform pixel-wise subtraction, take the absolute value of the differences, and then sum them. This sum represents the L1 distance between the images.

Although this is a basic distance function, it proves highly effective in numerous applications.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image33.png)

In this course, you will frequently revisit **L1 distance** and its variants.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image34.png)

Based on this simple definition, we aim to explore its implementation.  

The first step requires **memorizing** the training data. The training function stores data in memory, while the prediction function uses Python libraries like **NumPy** to calculate the distance between each test sample and the training data.  

Subsequently, it finds the minimum distance for each test sample and outputs the label corresponding to the nearest neighbor. The entire process can be implemented in just four lines of code.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image35.png)

**Pixel values**, in their simplest form, constitute a tensor of 800×600×3 dimensions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image36.png)

An image consists of three channels representing the **RGB values** of each pixel. Pixel values are typically between 0 and 255. This convention originates from the **24-bit RGB format**, which is the most widely used standard for storing images.

In this format, the red, green, and blue color channels are each allocated eight bits, allowing each channel to represent 256 values. Although other frameworks exist, this remains the mainstream standard.

Now, let's return to the code and continue with the next question.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image37.png)

Many students here have an **engineering background** and some exposure to computer science knowledge.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image38.png)

However, our goal is to evaluate **training speed** and prediction speed when the training dataset contains \\(n\\) samples.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image39.png)

I hope you are familiar with **Big O notation**, which we typically use to represent computational complexity, sometimes including space complexity.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image40.png)

When analyzing algorithms, we need to focus on **training data**. The training function needs to handle the prediction step. In terms of the training process, its time complexity is \\(O(1)\\)—because no computational operations need to be performed, only storing a copy of the data in memory.

For the prediction phase, each test sample needs to calculate its distance to all training samples. If there are \\(n\\) training samples, at least \\(O(n)\\) operations are required.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image41.png)

This approach is not optimal because the training process is inefficient.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image42.png)

However, in the testing and prediction process, **significant time** is spent comparing each data point with training samples.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image43.png)

This is similar to querying a **GPT model**: each question prompts the system to evaluate and compare potential answers with massive internet data—a process that might take years to return a response. Even for simple questions, this approach is extremely unrealistic in terms of scalability. We used to employ these methods in the past.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image44.png)

Therefore, it is usually necessary to build **classifiers** that are efficient in the prediction phase.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image45.png)

They perform tasks much faster, but even if the **training process** takes longer, it is acceptable because this process can be conducted offline.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image46.png)

Considering this, although people have invested significant effort in accelerating **nearest neighbor algorithms** using GPUs, these advances are beyond the scope of this course. If interested, you can explore this further on your own.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image47.png)

Let's understand how this algorithm works through some visualization charts. Given a space containing five categories (**red**, **blue**, **green**, **purple**, and **yellow**), each point represents a training sample of the corresponding category. After dividing the space point by point, five (in this case six) distinct regions can be observed. The color of each region identifies the nearest neighbor category for any test sample within that region, demonstrating how the **single nearest neighbor algorithm** divides the space.  

But note the problem in this example: the yellow point is completely surrounded by green points, indicating it might be an **outlier** or noise. This situation is common in many problems we handle. The large yellow area in the center region is formed by this single point, which is exactly the result of relying solely on a single nearest neighbor.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image48.png)

To enhance **robustness**, we can increase the number of nearest neighbors considered, transforming the nearest neighbor algorithm into a **k-nearest neighbor** method. Usually we select multiple points or samples and determine the label for a given test image through a majority voting mechanism.  

But the appearance of white regions presents a challenge. These regions represent decision uncertainty because they contain equal numbers of samples from three different categories among neighboring samples.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image49.png)

The label for examples in white regions cannot be determined. If you create such blank regions in your own problems, these areas represent parts that **require additional data collection** because it's currently unclear.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image50.png)

This method can effectively identify regions that **require** additional data collection.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image51.png)

The value of **k** is a key parameter in the K-nearest neighbor algorithm, and increasing this value may affect the model's performance.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image52.png)

Remember, we also have another decision point in choosing the **distance function**. We discussed **L1 distance**, which is the sum of absolute differences between pixels. In some contexts, this is called **Manhattan distance**. By visualizing L1 distance, all points on the square boundary in this space maintain equal distance from the origin, which helps understand how this distance function works.

Another commonly used one is **L2 distance**, which calculates the square root of the sum of squared differences. This creates a circular visualization where all points on the circumference are equidistant from the center. These visualizations can intuitively show the core differences between L1 and L2 distances—they are among the most fundamental distance functions.

The value of these visualizations becomes apparent when dealing with **feature rotation**. Here X and Y represent features (such as pixel values). Rotating these features (or using alternative features) changes the L1 distance framework, but L2 distance remains unchanged. This distinction is particularly important—especially when features are highly specific and meaningful. In such cases, L1 is usually preferred because its geometric properties can better maintain and strengthen distance relationships based on original features.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image53.png)

However, if these features are more arbitrary, **L2 distance** becomes more meaningful. To calculate this distance, all points on this shape maintain the same distance from the origin.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image54.png)

If using **L1 (Manhattan) distance**, points on this shape have the same distance to the origin. For **L2 (Euclidean) distance**, points on the circle are equidistant from the center.  

The key difference lies in their behavior under rotation: when feature axes are rotated, L1 distance changes completely, while L2 distance remains unchanged. This is because L1 is highly sensitive to feature values, while L2 is not.  

When choosing different features in the same space, the behavior of distance functions also changes accordingly. For example, choosing different feature directions changes the orientation of decision boundaries.  

In **k=1 nearest neighbor classification**, these geometric properties directly affect how the algorithm divides the feature space. When choosing between L1 and L2 distance, consider whether feature preservation (L1) or rotation invariance (L2) is more important for the task.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image55.png)

When using **L1** and **L2** distance metrics, the space division is as follows.  

A significant observation is that **L1 distance functions** generate decision boundaries that are often parallel to feature axes (x1 and x2), making them extremely sensitive to changes in individual features.  

In contrast, **L2 distance** creates smoother boundary separations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image56.png)

The lab website provides an online tool for experimenting with different **distance functions** and **k values** in **K-nearest neighbor algorithms**. This allows you to explore various parameter combinations.

We use the **K-nearest neighbor method** primarily for two considerations: first, it is the simplest data-driven solution and serves as an ideal starting point; more importantly, this method provides an excellent example for discussing **hyperparameters**—these key variables that must be determined before the algorithm runs.

In this framework, the **k value** (number of nearest neighbors) serves as a core hyperparameter, and changes in its value will directly affect the output results. The choice of distance function is another key hyperparameter decision, and these choices usually need to be determined comprehensively based on specific datasets and problems to be solved.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image57.png)

To optimize performance for each problem, we need a method to identify and adjust hyperparameters, a process known as **hyperparameter tuning** in machine learning and deep learning algorithms.

There are several common methods for setting hyperparameters. One is to select the hyperparameters that perform best based on training data, such as minimizing training loss. But this method has flaws, especially in **k-nearest neighbor algorithms**, where when \\(k=1\\), the model achieves 100% accuracy by memorizing training data, which is clearly not an ideal solution.

Another method is to select hyperparameters based on a reserved test set. Although this is an improvement over the first method, it causes serious problems: this is essentially cheating because hyperparameters are optimized for test data. This leads to questions about the model's generalization ability on unseen data outside the test set.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image58.png)

This method is not advisable because we cannot predict how the model will generalize. As mentioned earlier, this is essentially a form of **cheating**.  

A more robust approach is to partition the training data and create an independent **validation set**. Train the model only on the training set portion, then use the validation set to optimize hyperparameters. After determining the optimal hyperparameters, apply them to the test set for final evaluation and prediction.  

Although this method is superior, it also has its own problems—validation sets are usually small and may not adequately represent the complete data distribution.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image59.png)

A more effective method is to use **cross-validation** to set hyperparameters. Specifically, divide the training data into multiple partitions, such as five folds. Each fold is used as a validation set in turn, and this process is repeated iteratively for five cross-validations.  

For each hyperparameter value, calculate its accuracy on the validation set and take the average of five iterations. Repeat this process to determine the **optimal hyperparameter configuration**, then apply this configuration to the test set.  

Although this method is more reliable and can achieve better results, its practical application is relatively limited due to **computational challenges** in repeatedly performing this process on massive datasets in large-scale deep learning.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image60.png)

We often rely on intuition to set **hyperparameters**, sometimes using the single validation set method. However, this practice is usually not recommended in fields other than **computer vision** and large-scale datasets.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image61.png)

Research papers usually require **cross-validation** and statistical frameworks to ensure reproducible results on test sets. There are various methods for this purpose.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image62.png)

Let's summarize the discussion about **nearest neighbors** and look at some examples and results.

Now I will introduce the **CIFAR-10 dataset**, which you will frequently use in assignments. This dataset contains 10 categories, each with numerous training and test images. Here are examples of some categories.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image63.png)

When using the **K-nearest neighbor algorithm**, we can visualize the top 10 nearest neighbor samples for each test image. The **key problem** to solve is how to determine the optimal value of K—how many nearest neighbors should be considered?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image64.png)

Let's look at a quick experiment using **5-fold cross-validation**. Each data point represents the result of one fold under different K values. As shown, **K=7** achieved the best accuracy of about 28-29%. Although this performance is better than random guessing (random guessing accuracy is 10% in this 10-class problem), there is still much room for improvement.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image65.png)

When revisiting these examples, many errors become obvious, especially the closest matches. For example, in the fourth row, the image shows a frog, but the first example is misclassified as a dog. This difference stems from distance metrics being performed at the pixel level. These images have similar color distributions on most pixels, resulting in small calculated distance values.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image66.png)

This example, along with many other cases, shows that distance metrics based on pixel values are **not optimal**. We don't use this method in practical applications because subsequent lectures will introduce **better solutions**.

As a summary of this topic, let's look at another example. The original image differs significantly from three modified versions in terms of color, occlusion, or pixel shifts (for example, the third image from the left is shifted only one pixel to the right). From a human visual perspective, these differences are negligible, but **pixel-based distance metrics** treat them as equally different from the original image.

Now pause for questions. In summary, the **core problem** is how to make decisions in such situations. The usual solution is to randomly select one of the top-ranked candidates.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image67.png)

If you are collecting more data—for example, when solving problems in **genetics** or **medical imaging** fields—

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image68.png)

When visualizing samples or features in nearest neighbor space, you might encounter regions with **insufficient samples** or ambiguity. In such cases, it's recommended to look for additional samples that occupy the same region in that space.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image69.png)

In the summary of the discussion about **K-nearest neighbor algorithms**, we focused on understanding this data-based fundamental method and explored hyperparameter tuning, particularly emphasizing the key role of **distance metrics** and **K value** selection.  

Now we will turn to the next topic: **linear classifiers**. We have 25 minutes left in this lecture, and I will use all the remaining time to explain this important content.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image70.png)

This is the most **fundamental building block** in deep learning. We must understand how this method differs.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image71.png)

First, let's see how this differs from the nearest neighbor method. **This is a parametric method**—we need to learn a set of parameters (denoted as weights \\(w\\)) that map input images to output class scores. Function \\(f\\) converts input to output, typically represented as membership scores for each of the 10 output classes.  

In this framework, the **linear classifier** uses parameters \\(w\\) to map input \\(x\\) to output \\(y\\). The process is very intuitive: an image represented as a \\(32 \times 32 \times 3\\) array (3,072 numbers total) defines our input vector \\(x\\) with dimension \\(3,072 \times 1\\). Since there are 10 output classes, we need 10 independent scores, so the output vector is \\(10 \times 1\\).  

To achieve this mapping, we define a **weight matrix** \\(w\\) with dimension \\(10 \times 3,072\\). Additionally, we introduce a **bias term**—a value independent of input that serves to offset class scores to improve class separation. This characteristic will be further explored in subsequent geometric visualizations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image72.png)

As mentioned earlier, these **linear functions** are the building blocks for constructing neural networks. By combining these linear classifiers and functions sequentially, we can build large-scale neural networks. Although other components are still needed, this remains one of the most critical elements.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image73.png)

If we examine popular **neural network architectures**, we find that **linear functions** are ubiquitous in their structure.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image74.png)

To better understand the mapping relationship and function operation, let's revisit the training and test samples in the **CIFAR-10** example. For simplicity, we won't analyze large 32x32 images, but examine a 2x2 input image composed of 4 pixels. This converts the input image into a vector.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image75.png)

As shown, we need to determine the **weight matrix** \\(W\\) and **bias term** \\(B\\) to map the input image to output scores. This represents a linear function from an algebraic perspective.

The output scores correspond to three classes: cat, dog, and chip. This function converts the image vector into these scores.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image76.png)

Now, let's examine the linear classifier from both algebraic and visual perspectives. Each image corresponds to a row in matrix \\(W\\), which serves as a **template for a specific class**. For example, when we multiply the image by \\(W\\) and \\(B\\), we can visualize the templates corresponding to the three classes: cat, dog, and chip.

After training a model on the **CIFAR dataset**, the learned templates for the ten classes exhibit interesting feature patterns. Taking the car class as an example, despite being a simple linear classifier, its template still clearly shows the contour features of a car's front. This demonstrates the model's ability to capture key visual features.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image77.png)

**Linear classifiers** can be understood from both visual and geometric perspectives. In two-dimensional space, linear classifiers distinguish different classes by identifying boundaries, as represented by different colored lines (red, blue, and green) in the figure.  

In higher-dimensional spaces, these boundaries become **hyperplanes**, as shown in the left example.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image78.png)

The **bias term** is crucial here. Without it, all lines would be forced to pass through the origin, which is clearly impractical. The presence of bias allows us to build more reliable functions and decision boundaries.

**Linear functions** (especially linear classifiers) are extremely valuable in numerous application scenarios—they are not only fundamental tools but also core components that constitute more complex neural networks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image79.png)

However, this method itself also has challenges because it cannot classify many independent data instances. For example, if **class 1** corresponds to the first and third quadrants, and **class 2** corresponds to the second and fourth quadrants, linear separation cannot be achieved.

Another case is when class 1 is defined as points within 1 to 2 units distance from the origin, and class 2 contains all other points; similarly, if class 1 in the data is distributed in three discontinuous regions while class 2 occupies the remaining space, achieving separation in these cases is extremely challenging.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image80.png)

We previously discussed **linear classifiers** and their ability to map input images to output labels. The remaining challenge is choosing appropriate weight values \\( w \\) to convert each image into class-specific scores. For this, we need to define a **loss function** (or objective function) that quantifies model performance by measuring the difference between model scores and training data scores.  

Once a loss function is established, we need to adjust \\( w \\) through an optimization process to minimize this loss, which will be detailed in the next lecture. For ease of understanding, assume a simplified example: containing three classes (cat, car, and frog) and a linear function. We need a loss function to evaluate the classifier's performance, parameterized by input image \\( X_i \\) and its corresponding label \\( Y_i \\). This function measures the difference between predicted scores \\( f(X_i, W) \\) and true values \\( Y_i \\), usually normalized by the number of samples.  

The **Softmax classifier** is a typical example. Suppose an image has scores of 3.2, 5.1, and -1.7, we convert these unbounded values to probabilities through the softmax function. First, we take the exponential of scores to ensure positive values, then normalize by summation to generate a valid probability distribution. This method can generate well-defined probabilities for each class \\( k \\) given input \\( X_i \\).

This is a probability distribution function where the sum of all probabilities equals 1. The interpretation of these values is very intuitive: the current parameter set **\\(W\\)** determines that the probability of this image being a cat is 13%. Clearly, the prediction in this example is incorrect, indicating that \\(W\\) has not yet reached optimal configuration and needs optimization.

These probabilities correspond to **unnormalized log probabilities**, commonly known as logits. If you've studied machine learning courses or logistic regression in other fields, you'll recognize this as identical to the framework you're familiar with.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image81.png)

This framework is identical to logistic regression. Since there are multiple classes, it constitutes **multinomial logistic regression**.  

The definition of function \\(L\\) can vary, but our goal is to maximize the probability that a sample belongs to the correct class—specifically the value 0.13 in this example. However, since other values in the set might be larger, we need to convert this maximization problem into a minimization problem, achieved by taking the negative of the log value, thus converting maximization to minimization.  

Additionally, we take the logarithm of the value to improve **numerical computational tractability**. Therefore, the negative logarithm of this value defines the objective function, or **loss function**, for this problem.  

This concise formula serves as the loss function for both softmax and logistic regression. As described in courses like CS229, this method is also called **maximum likelihood estimation**, representing the same algorithm.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image82.png)

Based on this idea, the **objective function** (or **loss function**) is defined as the negative log probability of the correct class. Although this setting is intuitive, there are other ways to interpret this framework.  

One approach is to reconstruct the loss function from the perspective of matching estimated probabilities with true probability distributions. This can be achieved by minimizing the **Kullback-Leibler divergence (KL divergence)**, providing an information-theoretic perspective for the loss function. In this context, KL divergence simplifies to the initially defined negative log function.  

Additionally, this formula is equivalent to the **cross-entropy function**. After decomposing cross-entropy into the entropy of the true distribution and KL divergence, we still get the negative log function. When using one-hot encoding to represent class labels, the entropy term becomes zero, so this function is called cross-entropy or **binary cross-entropy (BCE)**.  

In the field of deep learning, especially in neural network frameworks, BCE is widely adopted as a common loss function, and the above discussion aligns with this standard formula.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image83.png)

We first adopt a simple approach, focusing on comparing similarities and differences between methods. The **loss function** is defined as the negative logarithm of probability, where probability is calculated through the softmax function discussed earlier. Optimizing this loss function (which will be the focus of the next lecture) can yield the correct weights \\( W \\).

Before concluding, let's explore a few questions about this definition. What are the mean and maximum values of loss function \\( L_i \\)? The maximum is infinity because the negative logarithm of zero approaches infinity, but the negative sign ensures loss values remain positive. This conclusion is correct.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image84.png)

But we must also consider this point.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image85.png)

Let me answer the second question. When we initialize all weights \\(W\\) to random values, the probability for each class tends to be equal.

For the **softmax loss function** under \\(C\\) classes (especially when \\(C=10\\)), since probabilities are equal, each class has a probability of approximately \\(\\frac{1}{C}\\), and the loss value is \\(\\log C\\).

When the number of classes is 10, \\(\\ln 10 \\approx 2.3\\), which is exactly the theoretical expected value.



