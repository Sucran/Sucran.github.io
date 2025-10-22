---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 4: Neural Networks and Backpropagation"
date: 2025-09-06T16:12:26+08:00
draft: false
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image1.png)

As shown in the slides, today's lecture will cover **neural networks** and **backpropagation**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image2.png)

In my early learning years, I often referred to **backpropagation** as the magical process by which neural networks learn from their mistakes—similar to humans but more structured and built on mathematical foundations.  

Let's delve into this topic, which forms the foundation for the rest of this quarter's content. I expect this to be quite engaging.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image3.png)

Every algorithm we'll discuss in the future will use **backpropagation** in some form. This is why understanding this lecture and its subject matter is crucial.  

As usual, we first review what we've learned. Everyone should remember our previous discussions about building **objective functions** (also called loss functions) and topics related to regularization.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image4.png)

For this, we use input-output pairs \\((X, Y)\\) and a **scoring function** to construct the problem. In this example, we used a linear scoring function as shown in the figure. Additionally, we defined a **loss function**. The chart on the right illustrates the entire learning process.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image5.png)

In previous lectures, some students raised questions about the exclusive use of the **softmax function**. I'd like to clarify that while we primarily discuss softmax, it's not the only loss function available or actually used in our framework.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image6.png)

**Backpropagation** is one of the most widely applied techniques in deep learning, especially in classification tasks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image7.png)

However, for various tasks including classification, there are numerous **alternatives**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image8.png)

Additionally, if you've reviewed the course materials shared on the website, you'll find that the **hinge loss function** (also called SVM loss function) is listed in the reading materials for Lecture 2. The materials provide relevant examples and detailed topic content.  

As one of the loss functions widely adopted in the early stages of neural networks, the hinge loss function differs fundamentally from the **Softmax scoring function**: it doesn't convert scores to probability values. It's worth noting that converting scores to probabilities isn't the only viable approach, and other alternatives also have practical value.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image9.png)

This function aims to elevate the score of the **correct item** (denoted as \\(s_{y_i}\\)) above all other items' scores. If this condition is met, the function outputs zero; otherwise, it ensures the correct item's score exceeds all other items by at least a **margin value** (represented by the numerical value 1 in the equation).

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image10.png)

If this condition is violated, the **loss** increases proportionally from the margin, as shown in the function's visualization.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image11.png)

This promotes **correct scoring** by penalizing cases where irrelevant items have excessively high scores. For examples and deeper understanding, please refer to the reading assignments in Lecture 2.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image12.png)

Next, we discussed **general optimization methods** for finding optimal parameters \\(W\\) in neural networks. We visualized the **geometric form of the loss function** as a massive valley, where each point represents a different set of weight parameters. Our goal is to find parameters \\(W\\) that can minimize this loss landscape.  

The **core idea** lies in computing the gradient of the loss function \\(L\\) with respect to \\(W\\), which enables us to optimize step by step through the **gradient descent algorithm**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image13.png)

**Weights** are updated by moving along the negative direction of the gradient with a predetermined step size, thus descending toward the minimum on the loss surface. This process is called **gradient descent**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image14.png)

For optimization, we discussed two methods: **numerical gradients** and **analytical gradients**, each with its own advantages and disadvantages. In practice, we usually derive analytical gradients, but if implementation or mathematical derivation is difficult, we verify our implementation through numerical gradients.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image15.png)

One of the challenges we discussed involves computing the **loss function** and its gradients over the entire dataset. For large datasets, this process becomes computationally expensive.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image16.png)

This is why we discussed the concept of **mini-batches**, which involves sampling a subset from the dataset—typically 32, 64, 128, or 256 samples.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image17.png)

**Subsampled data** is used to compute gradients, then gradually advance toward the minimum.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image18.png)

Besides stochastic gradient descent (SGD), we also discussed several optimization methods, including SGD with momentum, **RMSProp**, and **Adam**. Detailed explanations can be found in Lecture 3.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image19.png)

One of the **key issues** we discussed is the importance of **learning rates** and their scheduling strategies.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image20.png)

In many optimizers, the common practice is to start with a higher **learning rate** and then apply various decay strategies to reduce its value by specified proportions. This approach is typical in traditional optimizers.

However, in newer variants like **Adam**, manual or explicit learning rate scheduling is usually unnecessary because this functionality is built into the optimizer's design.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image21.png)

Now let's delve into the topic of **neural networks** and study how to build them to solve more complex and challenging problems. So far, we've discussed linear functions \\(w \\cdot x\\), which represent the simplest form of neural networks—single-layer architecture. We will further extend the concept of **layers**.

The key dimensions to focus on are \\(d\\) and \\(c\\), where \\(d\\) represents the dimension of input data \\(x\\) (or number of features), and \\(c\\) represents the number of required classes, outputs, or neurons. To introduce a second layer in neural networks, we define a new set of weights, denoted as \\(w_2\\), and apply it to the output of the first layer \\(w_1 \\cdot x\\).

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image22.png)

Note the **dimensions** here, where \\(c\\) represents the number of outputs and \\(d\\) represents the number of input features.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image23.png)

We also define \\(h\\), which determines the number of neurons in the hidden layer.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image24.png)

The second point involves the **max function**, which we'll revisit later regarding its purpose and importance. The max operation here introduces **nonlinearity** between the linear transformations performed by \\(w_1\\) and \\(w_2\\), which is a **key component** of this process.

Before briefly discussing nonlinearity, let me clarify the final point. In practice, we include \\(w\\) and \\(x\\) (as described in Lectures 1 and 2), but we also introduce **bias terms** to ensure framework completeness.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image25.png)

In practice, we usually include **bias terms** as well, but they're omitted here for simplicity. The max operation introduces **nonlinear characteristics**, which is crucial. As discussed in previous lectures about linear classifiers, many problems cannot be solved by simply dividing samples with a single line.

Neural networks break through this limitation by applying nonlinear transformations that map inputs to a new space, making division possible. For example, after converting Cartesian coordinates \\((x, y)\\) to polar coordinates \\((r, \\theta)\\), linear division can be achieved in the new space. This is just one example of such transformations.

Returning to our definition of **two-layer neural networks**, architectures composed of weights, input layers, and layers containing only multiplication operations are commonly called **fully connected networks** or multilayer perceptrons (MLPs). By stacking more layers, we can build network structures with progressively increasing complexity and capabilities.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image26.png)

In this case, we must consider the **dimensions** of hidden layers and ensure they align sequentially. Returning to the visualization of neural network operation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image27.png)

We discussed how **linear representations** often lead networks to learn certain templates through their weights. As mentioned last week, these templates are learned representations of images shaped by training data.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image28.png)

These templates, as discussed last week, are generated by applying the **weight matrix** \\(W\\) to input neurons. With multi-layer structures, we can now create more complex templates.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image29.png)

Now we have an **intermediate layer** that can generate 100 templates, while the **linear classifier** can only produce 10, while retaining the original 10 templates. From a high-level perspective, this is the basic concept.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image30.png)

When we introduce **100 neurons** in the hidden layer, the network can generate feature templates for object components rather than entire objects.  

For example, the categories currently shown—birds, cats, deer, dogs, frogs, and horses—all have eye structures. Therefore, one of these 100 templates might correspond to **common features** shared by multiple categories.  

From a higher level, these templates implement **feature extraction** functionality. This concept will be further analyzed when we discuss neural network visualization and interpretability later.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image31.png)

Returning to the **max function**, we previously discussed this nonlinearity. In neural network terminology, this is called an **activation function**, which plays a key role in model construction.

Consider a question: What happens if we try to build a neural network without activation functions (like the max function)? Without it, the function simplifies to \\(W_2 \\times W_1 \\times X\\). As you correctly pointed out, the product \\(W_2 \\times W_1\\) can be replaced by a single matrix \\(W_3\\), thus simplifying the entire function to a single linear transformation. This illustrates how activation functions prevent multi-layer networks from collapsing into a single linear operation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image32.png)

To solve the **nonlinearity** problem, we need to introduce nonlinear factors in intermediate layers to provide necessary computational capabilities.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image33.png)

The function we discussed is **ReLU** (Rectified Linear Unit), a widely used activation function in neural networks. Although many variants have been tested in various architectures (including modern ones), ReLU has a significant drawback: it sets all non-positive inputs to zero, which may cause neurons to "die." To address this issue, alternatives like **Leaky ReLU** and **ELU** (Exponential Linear Unit) have been introduced. ELU has advantages due to its zero-centered properties.

Newer variants include **GELU** (Gaussian Error Linear Unit), commonly used in Transformer architectures. Another option is **SiLU** (Sigmoid Linear Unit), also called SWISH, applied in modern CNN architectures (like Google's EfficientNet).

Additionally, traditional activation functions like **sigmoid** and **tanh** are still in use, but they have limitations. These functions compress values into narrow ranges, potentially causing gradient vanishing problems. Therefore, they're typically avoided in intermediate layers of neural networks and reserved for final stages requiring binary outputs.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image34.png)

As mentioned earlier, **ReLU** is usually a good default choice and is widely used in various architectures. We've discussed multiple variants of this function.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image35.png)

I'll summarize the key points of our discussion and answer any questions. We covered various **neural network architectures**, including layer addition.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image36.png)

Activation functions typically operate within layers. Additionally, we have **weight matrices** W that define mappings between consecutive layers.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image37.png)

These are fully connected neural networks with straightforward implementation. The **key requirement** is the ability to define an activation function.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image38.png)

In this example, the **sigmoid function** is defined as the activation function. Values for the first and second hidden layers are computed by calculating \\(W_1 \\cdot X\\) plus bias terms, then applying the activation function. The computation process for \\(H_2\\) is the same.

The output layer is simply the dot product of \\(W_3\\) with the last hidden layer. Before continuing, I'll pause to answer any questions.

This is a very good question.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image39.png)

The question is how to choose appropriate activation functions for new problems. **In short, the choice is primarily empirical.** Usually, we start with **ReLU** or other standard activation functions commonly used for specific architectures.  

As mentioned earlier, certain activation functions are frequently used in architectures like CNNs or Transformers. Therefore, we often rely on those that have been validated. Ultimately, this choice is largely empirical.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image40.png)

When designing networks for new problems, choosing **activation functions** is as crucial a decision as other hyperparameters. The common core characteristic of all activation functions is the ability to introduce **nonlinearity**—we deliberately avoid using linear functions as activation functions, and this nonlinearity is the foundation for neural networks learning complex patterns.

There are many variants of activation functions, stemming from various considerations: solving **gradient vanishing** problems, ensuring differentiability (a necessary condition for neural network training), achieving zero-centered outputs, maintaining smoothness, etc. These properties collectively promote faster network convergence.

Although layers typically use the same activation function, there are exceptions. For example, output layers often use **sigmoid** or **tanh** functions. However, the industry practice is to maintain consistency of activation functions throughout the network architecture.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image41.png)

When continuing to discuss neural network model implementation, building a **two-layer neural network** in Python requires less than 20 lines of code. This process includes defining the network architecture, where \\(n\\) represents the number of samples, \\(d_{in}\\) represents the input dimension, \\(d_{out}\\) represents the output dimension, and \\(h\\) is the number of neurons in the hidden layer.  

We randomly initialize input \\(x\\) and output \\(y\\), as well as weights \\(w_1\\) and \\(w_2\\). **Forward propagation** applies these weights layer by layer to generate predicted output \\(\\hat{y}\\). Subsequently, we evaluate prediction accuracy by computing the loss function.  

The optimization process involves computing analytical gradients and using **gradient descent** to iteratively adjust \\(w_1\\) and \\(w_2\\), thus approaching the optimal network configuration. The core problem we'll focus on in subsequent courses is how to efficiently compute these gradients and achieve scalable applications in different scenarios.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image42.png)

After completing neural network training and construction, the number of nodes in the **hidden layer** affects the separation patterns between two types of data. Increasing the number of neurons can enhance the network's ability to learn complex functions and improve separation of data points.

This phenomenon is similar to the **k-nearest neighbor algorithm** patterns discussed in Lecture 2 (especially when k=1). Similar to the k-nearest neighbor case, providing excessive capacity to the network may lead to **overfitting**, hindering the model's generalization ability to unseen data.

However, there are currently multiple solutions to this problem.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image43.png)

As a **rule of thumb**, I want to emphasize that neural network size should not be used as a regularization method. Although we try different network sizes and related hyperparameters, we typically don't treat network size as a hyperparameter requiring fine-tuning. Instead, we often choose network structures slightly larger than actual needs.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image44.png)

We use **regularizers**, especially **regularization hyperparameters**, to evaluate different configurations. Usually, we directly adjust regularization and its hyperparameters rather than directly changing network size.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image45.png)

This is the essence of **neural networks**. Although neural networks draw some inspiration from biology, the focus here is on their computational characteristics.  

Regarding your question about increasing **lambda** values causing underfitting: lambda controls the contribution of regularization terms to the overall loss function.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image46.png)

The greater the contribution to **regularization terms**, the stronger the constraints on weights \\( W \\). These constraints limit the degrees of freedom of weight values, thus forming more generalizable decision boundaries rather than highly detailed ones. Even with regularization, over-constraining the model may still lead to suboptimal decision boundaries.

Appropriate regularizers effectively prevent **overfitting** by balancing the two components of the loss function: the first part ensures accurate prediction of correct outputs, while the second part focuses solely on regulating weight values (independent of outputs). Overemphasizing the latter reduces classifier performance.

Moderate application of regularization leverages its advantages, but excessive use diminishes its benefits.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image47.png)

There are multiple reasons for adjusting **regularization** rather than network size. One key factor is the network's own volume—when building networks, it may take days to obtain results.  

The conventional practice is to gradually increase the number of network parameters until signs of **overfitting** appear. This indicates the network has begun recognizing data patterns and possesses memory capabilities, at which point we introduce regularization to suppress overfitting. Therefore, regularization plays a key role in this process.  

Excessively increasing parameter count or network complexity causes problems. For new problems, we typically start with smaller networks and gradually expand while using regularization to maintain balance.  

Regarding the number of **neurons** needed for specific problems, this depends on the specific task and often requires determination through experimentation and validation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image48.png)

This method is based on **empirical research** and analysis of similar networks. There's no universal solution that works everywhere; we must examine corresponding models trained on comparable data and start from that range.  

Usually, multiple experiments are needed, adjusting by balancing, increasing, or decreasing network complexity.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image49.png)

The question is whether there's **theoretical and fundamental research** to determine which activation functions to use and how many layers of networks are needed. Numerous research papers analyze these aspects and propose methods for optimizing neural network meta-parameters or hyperparameters.  

However, we won't delve into these details because this largely depends on the **specific dataset** and problem being handled. Although some related research exists, the assumptions made in these studies may not apply to your specific application scenario or problem.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image50.png)

Although there's some biological inspiration, these connections are quite loose. If there are neuroscientists present or watching online, please don't take the examples I provide as absolute truth.

Generally speaking, in neurons—as shown in the figure—there's a **cell body** that aggregates neural impulses transmitted through **dendrites**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image51.png)

Subsequently, these impulses are transmitted through axons to other neurons.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image52.png)

This process is very similar to operations in **neural networks**. Usually, some function aggregates signals and activation values from previous layers.  

In the cell body, this function processes inputs, generates activation values, and transmits them to the next neuron. The **activation function** here is crucial, as it can regulate these values, either amplifying or attenuating them.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image53.png)

**Biological neurons** differ significantly from the neural networks we build, as biological neurons may be much more complex. However, there are also commonalities.  

The neural networks we build typically use **regular patterns** for organization to improve actual computational efficiency. Although research has attempted to create complex neural networks by optimizing connection methods, their performance remains comparable to commonly used regular neural networks—this will also be the focus of this course.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image54.png)

I must repeatedly emphasize being cautious about **brain analogies** and their potential explanations. There are many differences between them, which I won't elaborate on here, but if you're interested in exploring neuroscience-level issues, I'd be happy to discuss further.  

After integrating all elements, we get a **scoring function**—it converts inputs to score values through weight vectors or matrices. The **loss functions** commonly used in neural networks (whether using hinge loss, softmax, or other variants) often utilize these score values. Additionally, we define regularization terms that, together with data loss, constitute the total loss function.  

To optimize \\(W_1\\) and \\(W_2\\), we need to compute partial derivatives of \\(L\\) with respect to \\(W_1\\) and \\(W_2\\), i.e., \\(\\frac{\\partial L}{\\partial W_1}\\) and \\(\\frac{\\partial L}{\\partial W_2}\\).  

This involves numerous details: constructing these functions and computing their derivatives is usually tedious and time-consuming, requiring substantial foundational work in matrix operations to implement neural networks. Another challenge is that if you want to fine-tune the loss function, you must recalculate all derivatives from scratch.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image55.png)

In such cases, we must re-execute the entire process. When dealing with complex loss functions, this process becomes **unmanageable** and often infeasible. As function complexity increases, challenges intensify further. However, more efficient methods in practice involve using **computational graphs** and backpropagation techniques.  

Computational graphs integrate all operations in neural networks, systematically constructing the entire process step by step. Starting from input data and necessary parameters, we ultimately arrive at the loss function as the output layer. The **loss function** here can be softmax or hinge loss, combined with regularization terms \\(R(W)\\) (where \\(W\\) serves as input). The sum of these components constitutes the overall loss value.  

Before computing loss, we usually aggregate \\(X\\) and \\(W\\) to generate scores (i.e., multiplication operations). This framework is extremely valuable because most neural networks can be represented as graphs. Even complex functions like **Neural Turing Machines** designed for sequential and temporal data can be presented in this structure.  

Computational graphs start from input images or data, pass through network weights, and ultimately reach the loss function. This method is crucial for managing complex neural architectures.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image56.png)

Manually expanding this machine would be **unmanageable** and infeasible. Therefore, when constructing computational graphs, the solution is **backpropagation**.  

Let's start with a simple example. Consider the function \\(f(x, y, z) = (x + y) \\times z\\). This function's computational graph consists of addition operations between \\(x\\) and \\(y\\).

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image57.png)

We then compute the product of the sum of \\(x\\) and \\(y\\) with \\(z\\). Given input values \\(x = -2\\), \\(y = 5\\), and \\(z = -4\\).

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image58.png)

Now, we can execute all computational steps of **neural network** forward propagation. The first step is adding **x** and **y** to get three. For clarity, we denote this operation as **q = x + y**. Since the formula is clear, computing partial derivatives of q with respect to x and y is very intuitive: \\(\\partial q/\\partial x = 1\\) and \\(\\partial q/\\partial y = 1\\). This simple setup is well-known, and we can remember it first.

The second operation is **f = q × z**. Based on this function, partial derivatives are easily derived: \\(\\partial f/\\partial q = z\\) and \\(\\partial f/\\partial z = q\\). This essentially exchanges the roles of z and q. I assume everyone is familiar with these concepts through **linear algebra**. If not yet mastered, be sure to review them promptly, as they are the foundation for the rest of this quarter's content.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image59.png)

To complete this backpropagation example, we need to compute partial derivatives of function \\( f \\) with respect to \\( x \\), \\( y \\), and \\( z \\). **Backpropagation starts from the end of the network, recursively propagating gradients backward.**

The derivative of function \\( f \\) with respect to itself is always 1. The most direct derivative is with respect to \\( z \\). Here, \\( \\frac{\\partial f}{\\partial z} = q \\), so the gradient value equals \\( q \\).

Next, we compute \\( \\frac{\\partial f}{\\partial q} \\), which equals \\( z \\). For \\( y \\), since \\( y \\) precedes \\( q \\) and \\( y \\) and \\( f \\) are not directly connected, we need to use the chain rule. Therefore, \\( \\frac{\\partial f}{\\partial y} = \\frac{\\partial f}{\\partial q} \\cdot \\frac{\\partial q}{\\partial y} = z \\cdot 1 = z \\), yielding a gradient value of \\(-4\\).

We introduce two key terms: **upstream gradient**, which flows from the end of the network to the current node; and **local gradient**, which is the derivative of the node's output with respect to its input.

For \\( x \\), we similarly apply the chain rule: \\( \\frac{\\partial f}{\\partial x} = \\frac{\\partial f}{\\partial q} \\cdot \\frac{\\partial q}{\\partial x} = z \\cdot 1 = z \\), yielding a gradient value of \\(-4\\) as well. Since \\( \\frac{\\partial q}{\\partial x} \\) and \\( \\frac{\\partial q}{\\partial y} \\) are both 1, \\( x \\) and \\( y \\) receive the same gradient values.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image60.png)

In this computational setup and computational graph framework, modularizing our operations becomes intuitive. For each node in neural networks, when inputs like **x** and **y** produce output **z**, we first compute local gradients.  

Given function **f** dependent on x and y, gradients of each node's output with respect to input can be easily obtained. To perform backpropagation, we need **upstream gradients**. The backpropagation process enables us to gradually obtain this upstream gradient.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image61.png)

At this node, we've already obtained the **upstream gradient** computed by subsequent nodes. Multiplying the upstream gradient with the local gradient yields what we currently call the **downstream gradient**. These downstream gradients become upstream gradients for predecessor layers.

The same process applies to *y*. This entire mechanism enables us to compute all gradients in place and gradually propagate them backward to previous nodes, ensuring the computational process continues recursively.  

(Note: Technical terminology handling explanation:
1. "upstream/downstream gradients" uses the standard translation "上游/下游梯度", conforming to deep learning literature conventions
2. "local gradient" is translated as "局部梯度" rather than the literal "本地梯度", more accurately expressing the local differentiation concept in computational graphs
3. "propagate them backward" is translated as "反向传播" rather than the literal "向后传播", adopting the neural network field's terminology system)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image62.png)

This operation is **one of the most fundamental operations** in neural networks and numerous optimization processes involving multi-layer structures.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image63.png)

If I understand the question correctly, you're asking how to intuitively understand the role of **gradients**. Let's review the core objective: we need to compute gradients of the loss function with respect to weights (\\(w_1\\), \\(w_2\\), etc.) to iteratively adjust weights along the opposite direction of these gradients.

This process enables us to minimize **loss** and converge to optimal values. For this, we need gradients of the loss function \\(\\mathcal{L}\\) with respect to all parameters.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image64.png)

We compute gradients of the loss function \\( L \\) with respect to all variables in the network and propagate them backward to each layer. **This method avoids the tedious manual derivation of the entire network function**, even for networks with 100 layers. Through the backpropagation process, we obtain the values needed to optimize each weight in the network.

For further illustration, please refer to the following example.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image65.png)

This is a more complex function involving weights and \\(x\\), defined as \\(\\frac{1}{1 + e^{(w \\cdot x)}}\\). It involves multiple operations: multiplication, addition, negation, exponential function, and finally the reciprocal function.

Given specific values for \\(w_0\\), \\(x_0\\), \\(w_1\\), \\(x_1\\), and \\(w_2\\), we can perform **forward propagation** to compute each intermediate value.

Reviewing some basic derivatives:
- The derivative of \\(e^x\\) with respect to \\(x\\) is \\(e^x\\).
- The derivative of constant multiplication is the constant itself.
- The derivative of \\(\\frac{1}{x}\\) is \\(-\\frac{1}{x^2}\\).
- The derivative of constant addition is \\(1\\).

At the output layer, the derivative of **loss** \\(L\\) with respect to itself is always \\(1\\). Starting from here, we apply the chain rule.

1. The derivative of \\(\\frac{1}{x}\\) produces local gradient \\(-\\frac{1}{x^2}\\). Given input values, this results in downstream gradient \\(-0.53\\).
2. The next operation is constant addition with local gradient \\(1\\). Therefore, the upstream gradient remains \\(-0.53\\).
3. Next is the exponential function with local gradient \\(e^x\\) evaluated at input \\(-1\\), producing \\(-0.2\\).
4. The constant multiplication step's local gradient equals that constant, correspondingly updating downstream gradients.
5. Addition operations combine two inputs. Since \\(x + y\\)'s derivative with respect to \\(x\\) or \\(y\\) is \\(1\\), both inputs receive the same upstream gradient \\(0.2\\).
6. For multiplication operations, \\(a \\cdot x\\)'s derivative with respect to \\(x\\) is \\(a\\). Therefore, gradients for the first and second inputs are \\(-1\\) and \\(2\\), respectively.

This process demonstrates how **gradients** propagate backward through the network.

Another variable's value enables us to compute all necessary quantities, including those related to \\(w_1\\) and \\(x_1\\). These computations help determine how much \\(w\\) should be adjusted to move toward the optimum in neural networks.

This provides another example. **Computational graphs** can be constructed in various ways; what I explained isn't the only possibility. For example, we can combine all operations into a single function, like the sigmoid function. Since this is essentially a sigmoid transformation of a linear function, the linear part can be placed here, while other operations are defined as the sigmoid function.

The **Sigmoid function** is particularly interesting and practical because its local gradient depends on the sigmoid function itself. Specifically, the sigmoid function's local gradient with respect to \\(x\\) simplifies to \\((1 - \\sigma(x)) \\cdot \\sigma(x)\\). This makes it a highly practical framework.

To compute downstream gradients, recall that the upstream gradient is 1. By computing the local gradient—evaluating the function at input value 1—we get \\(0.2\\), which matches the result from previous step-by-step calculations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image66.png)

In summary, there are several key patterns in the data that nodes can memorize. **Addition gates** act as gradient distributors due to addition operation properties, preserving gradients of input data. **Multiplication gates** perform exchange functions—\\(x \\cdot y\\)'s gradient with respect to \\(x\\) is \\(y\\), and with respect to \\(y\\) is \\(x\\). **Copy gates** perform addition operations on input nodes or gate data. **Max gates**, most commonly used, select maximum input values and propagate gradients along that direction.

With these components, neural network implementation becomes intuitive. The forward propagation phase completes all step computations, while the backpropagation phase solves gradients step by step. The **loss function**'s gradient with respect to itself is always 1. Starting from the network's end, we sequentially compute gradients for each component: first through the sigmoid function, then through multiple addition gates and two multiplication gates, which together provide the required implementation solution.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image67.png)

Through this formal expression, we can modularize each functional component in neural networks and implement **forward and backward APIs** for each required function. In this case, multiplication gates need access to input data during backpropagation. Usually, we save these input values, compute forward propagation results first, then perform gradient calculations during the backpropagation phase.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image68.png)

This means we can **encapsulate** our functions, including forward propagation and backpropagation, which is exactly how PyTorch operators currently work.  

For example, taking the **sigmoid layer** as an example: while forward propagation isn't implemented in this specific function (it's located in other parts of PyTorch's C++ or C code), backpropagation computes the same function we discussed earlier.  

At this point, we've handled most expected examples with scalar values.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image69.png)

All current examples involve **scalar values**, but these operations can also be implemented in vector or matrix form.  

In scalar scenarios, for any scalar inputs \\(x\\) and \\(y\\), derivatives are also scalars, representing how much \\(y\\) changes when \\(x\\) undergoes small perturbations.  

In vectorized cases, if \\(x\\) is an \\(n\\)-dimensional vector while \\(y\\) remains scalar, derivatives become a **vector**. Each element of this vector represents how much \\(y\\) changes when the corresponding element of \\(x\\) is perturbed, while \\(y\\) itself remains single-valued.  

For **vector-to-vector frameworks** (where \\(x\\) is an \\(n\\)-dimensional vector and \\(y\\) is an \\(m\\)-dimensional vector), derivatives constitute matrix structures called **Jacobian matrices**. Each element of the Jacobian matrix represents how much the corresponding element of \\(y\\) changes when a specific element of \\(x\\) is perturbed. Note that different Jacobian matrix elements may have different subscript meanings, each carrying unique mathematical significance.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image70.png)

To understand and visualize **backpropagation** in vector form, consider vectors \\( x \\), \\( y \\), and \\( z \\) with dimensions \\( d_x \\), \\( d_y \\), and \\( d_z \\), respectively. The loss function \\( L \\) is always scalar because it represents a single value to be minimized. **Upstream gradient** computation generates a vector \\( dz \\) with the same dimension as \\( z \\).  

Before discussing **downstream gradients**, we first examine **local gradients**, particularly gradients of \\( z \\) with respect to \\( x \\) and \\( y \\). At this point, gradients become Jacobian matrices with dimensions determined by the product of input and output dimensions. Downstream gradients are obtained by multiplying upstream gradients with local gradients, ultimately generating a vector with the same dimension as input \\( x \\).  

This indicates that gradients of variables with respect to the loss function \\( L \\) always match the dimensions of the original variables, as shown in this slide.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image71.png)

**Vector backpropagation** is a typical example. Consider a function defined as the maximum of 0 and \\(x\\), operating element-wise. For non-negative inputs, the function preserves original values; otherwise, it outputs 0. Given **upstream gradients**, we construct **Jacobian matrices**. Since this is element-wise operation, Jacobian matrices are sparse, with non-zero entries only on the main diagonal. These entries have values of 0 or 1, depending on whether inputs are preserved or replaced with 0. Multiplying Jacobian matrices with upstream gradients yields **downstream gradients**.  

In practice, we don't explicitly compute this sparse Jacobian matrix during backpropagation but use **rule-based gradient computation** to handle the max function. This method avoids storing or computing complete matrices, leveraging our understanding of function behavior. This method naturally extends to matrices and tensors, where gradients maintain the same dimensions as corresponding variables. Upstream and downstream derivative computations follow the same principles as vectors.  

For **local gradients** involving matrix operations, Jacobian matrices become extremely large. For example, consider matrix multiplication operations with inputs \\(X\\) and \\(W\\), outputting \\(Y\\). The derivative \\(\\frac{dL}{dY}\\) involves Jacobian matrices. When mini-batch size is 64 and matrix dimensions are 4096, Jacobian matrices exceed 256GB. To solve this problem, we analyze how changes in individual elements of \\(X\\) affect specific rows of \\(Y\\), enabling efficient gradient computation without constructing complete Jacobian matrices.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image72.png)

We can optimize matrix multiplication's backpropagation function for efficiency.

For this question: **How do X and D affect the values of Y and M?** Specifically, we need to determine gradients of Y and M with respect to X and D. This involves computing partial derivatives to quantify the impact of X and D on Y and M.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image73.png)

To clarify, this is a multiplication operation. In the context of **multiplication gates**, this operation should include exchange operations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image74.png)

Values in matrix **\\(W\\)** are determined by multiplication gates, involving exchange operations. **\\(X\\)**'s impact on **\\(Y\\)** depends on elements in \\(W\\) located at the intersection of rows indexed by \\(X\\) and columns indexed by \\(Y\\). This exchange operation is consistent, but we now need to locate specific elements in large matrices.

By replacing the entire process with matrix multiplication operations, the gradient of **\\(L\\)** with respect to \\(X\\) can be expressed as direct matrix operations. Similarly, the gradient of \\(L\\) with respect to \\(W\\) is also defined by simple multiplication. For \\(X\\), we consider the entire \\(W\\) matrix; for \\(W\\), we consider the entire \\(X\\) matrix and perform necessary multiplication operations.

These formulas simplify implementation of more complex operations during backpropagation. At this point, we've completed this section.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_4_image75.png)

In summary, today we discussed **fully connected neural networks**, covering all steps of **backpropagation**, including forward propagation and backpropagation.  

Next class, we will explore **convolutional neural networks**.  

Thank you.

