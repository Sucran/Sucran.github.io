---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 3: Regularization and Optimization"
date: 2025-09-05T16:11:47+08:00
draft: false
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image1.png)
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image2.png)

Today's lecture will cover **regularization** and **optimization**, two fundamental concepts in deep learning and machine learning, with particular emphasis on their applications in computer vision.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image3.png)

We will begin with a **review** of last week's content and recap the topics we previously covered.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image4.png)

We focused on **image classification**, a core task in computer vision. This task aims to map input images to labels from predefined categories.  

For example, given five labels—cat, dog, bird, deer, and truck—the goal is to correctly assign the corresponding label to the input image. The **model** or function we develop takes an image as input and outputs the corresponding classification label.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image5.png)

We also explored numerous challenges in classification. **One major challenge** (as shown in the top-left image) lies in the **semantic gap** between human perception (such as recognizing a cat) and the computer's representation of images as grids of pixel values. This grid is actually a multidimensional array or **tensor**, where each pixel has discrete numerical values.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image6.png)

This differs significantly from how humans recognize images as cats. The core challenge lies in how to map this complex numerical representation into a form understandable by humans.

Images themselves present multiple challenges. For example, scene lighting variations affect pixel intensity based on illumination conditions, and parts of objects may be in shadows and difficult to identify. **Felines** have highly deformable properties and can contort their bodies in various ways, leading to shape inconsistencies that make object detection algorithm design difficult.

**Occlusion problems** constitute another challenge—a cat hiding under sofa cushions may only show its tail, but humans can still identify it through behavioral characteristics and partially visible parts. **Background interference** makes the situation more complex, as objects may blend with their surrounding environment. Additionally, **intra-class variation** means objects of the same class may appear drastically different yet still need to be classified as the same category.

These complexities indicate that recognition is not a trivial problem that can be solved with simple if-else rules or basic logic.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image7.png)

If we cannot create rules through logic, how do we build classifiers? This is where **data-driven approaches** come into play. The simplest machine learning model is the **k-nearest neighbor (kNN) model**, whose core idea is to find the existing data point closest to the new data point in the training set.  

For a **1-NN classifier**, the classification result is directly determined by the class label of the nearest neighbor data point. If multiple neighbors are used (such as 5-NN), the decision is made by counting the most common class label among the nearest neighbors.  

Ideally, the dataset should be divided into **training set**, **validation set**, and **test set**. The validation set is used to select hyperparameters (such as the *k* value in kNN), and the optimal *k* value with the highest accuracy can be selected by plotting accuracy curves for different *k* values on the validation set. The test set is specifically used to evaluate the model's performance on unseen data.  

Posts on Ed provide detailed explanations of **distance metrics** and can answer related questions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image8.png)

We discussed two commonly used distance metrics in machine learning: **L1 (Manhattan) distance** and **L2 (Euclidean) distance**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image9.png)

**L2 Euclidean distance** corresponds to straight-line distance, which aligns with our everyday geometric understanding of distance. In contrast, **L1 Manhattan distance** restricts movement to horizontal and vertical directions in the figure, prohibiting diagonal movement.  

For example, consider the point (0.5, 0.5). Under the L1 norm, the distance from this point to the origin is 1, because we must move up 0.5 units and right 0.5 units, totaling 1 unit. Under this metric, all points on the line \\(x + y = 1\\) are equidistant from the origin.  

Conversely, under the L2 norm, points equidistant from the origin lie on a circle, because we can move along any direct path. This illustrates the fundamental differences between these two distance metrics.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image10.png)

The last topic we discussed was the concept of **linear classifiers**. In the basic setup, we have a 32x32 pixel image, where each spatial position contains three pixel values representing red, green, and blue intensities. This data is flattened into a 3072-dimensional vector.  

This vector is multiplied by a **weight matrix W** of dimension 10x3072. Each row of W, when multiplied by the input sample X, generates 10 class scores. Usually we also add a **bias term**, represented as a 10-dimensional vector.  

We explored three perspectives for understanding such linear models:  

1. **Algebraic perspective**: Each row of W independently represents a class. The input vector X is multiplied by each row and added to the bias, ultimately yielding class scores.  
2. **Visual perspective**: Provides a geometric-level explanation for the classification process.  
3. **Geometric perspective**: Decision boundaries appear as hyperplanes in feature space.  

Each perspective provides unique insights into the behavior and interpretation of linear classifiers.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image11.png)

The learned class weights can be interpreted as **templates**. By reshaping the weight vectors back to the original image dimensions, we can visualize the intensity patterns representing each class template, as shown in this visualization.

Alternatively, we can adopt a **geometric perspective**, where each row of the weight matrix corresponds to a hyperplane in input space. Decision boundaries occur where the linear equation equals zero. Points above this boundary produce positive class scores, while those below produce negative scores.

These three perspectives—template-based, algebraic, and geometric—all describe the same linear model behavior. The geometric perspective is particularly illuminating for visualizing data separation. For example, when classifying blue versus red points, it immediately becomes apparent whether linear decision boundaries can perfectly separate the classes, providing valuable intuition for understanding model capabilities.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image12.png)

The above is a highly condensed summary of our previous discussions. Now, I will delve into the **new content** for today's lecture. Before proceeding, if anyone has questions about the content from last time or the beginning of today's lecture, please feel free to ask.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image13.png)

A question from online viewers: Is this visualization method equivalent to running the **K-nearest neighbor algorithm** (where one neighbor might be used for comparison)? These methods are not mathematically equivalent, because templates are derived from decision boundaries rather than specific data points. However, templates can still be computed to characterize the overall direction of a class, as shown in the figure—the line points toward that class direction.  

Regarding the **number 3072**, it comes from the image dimensions: height 32 pixels, width 32 pixels, and three color channels (red, green, blue). Multiplying these together (32×32×3) gives 3072, which is the total number of values needed to describe this image.  

Looking at this specific example of the linear model. When input \\( X \\) is multiplied by the weight matrix \\( W \\), we obtain scores for each class. In the first example, the model performs poorly for the "cat" class because "car" receives a higher score. Ideally, the highest score should correspond to the correct class. The second example performs well, but the third ("frog") is misclassified, with its score being the lowest among the three.  

Intuitively, these scores are not ideal. To quantify classifier performance, we use a **loss function** for mathematical modeling. Given a dataset indexed by \\( i \\) (where \\( X_i \\) represents training samples and \\( Y_i \\) are labels), after evaluating each sample through the model \\( f(X_i, W) \\), we compare predicted labels with true labels \\( Y_i \\), and finally calculate the average loss across the entire dataset.  

As mentioned in previous lectures, **softmax loss** (or cross-entropy loss) is the most commonly used loss function for classification tasks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image14.png)

I won't delve deeply into this topic here, but essentially, **loss** becomes significantly high when the probability of correct class prediction is low, and decreases substantially when predicting the correct class with high probability.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image15.png)

The concept I just explained is what we call **data loss**. This metric quantifies how well the model predictions match the training data. We naturally want to minimize this value. Lower data loss indicates that our model can effectively fit the training data.  

But there's a second component to consider, which is what I'm going to talk about today: the **regularization term** in the loss function. This term is designed to prevent the model from overfitting to the training data. Although it may reduce the model's performance on the training set, its fundamental purpose is to improve the model's generalization ability to new data or unseen test data.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image16.png)

Performing slightly worse on the training set but better on the test set is exactly **what regularization is about**. We will explore the principles behind this concept in the following slides. The main goal is to improve the model's generalization performance on unseen data, even if this means slightly sacrificing training accuracy.

When computing the loss function, we evaluate each training sample \\((x_i, y_i)\\). Here \\(L_i\\) represents the loss value for the \\(i\\)-th training sample. While we could omit the subscript \\(i\\), we keep it here for clarity. Typically, the loss function form remains consistent across all training samples.

To illustrate regularization with a simple example: suppose we try to fit data points with input \\(x\\) and output \\(y\\) using functions. We have two candidate models \\(f_1\\) and \\(f_2\\): \\(f_1\\) perfectly interpolates all training points with minimal training loss; while \\(f_2\\) doesn't precisely fit each data point but often performs better on unseen test data. This reveals the **fundamental principle of regularization**—by preferring simpler models (which may fit training data slightly worse) with stronger generalization ability, we can effectively avoid overfitting.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image17.png)

When evaluating these models' performance on new data from the same distribution, we observe that \\(f_2\\) demonstrates excellent modeling capabilities, especially on unseen data. This example well illustrates **Occam's Razor principle**—a philosophical and scientific discovery principle that advocates choosing simpler models when multiple competing hypotheses exist. Researchers should first consider the simplest hypothesis and only explore more complex alternatives when simple hypotheses don't apply. This principle provides a theoretical foundation for understanding the utility of regularization.

Regarding the **lambda parameter** in the equation, it represents regularization strength and is another hyperparameter. We can determine the optimal value of lambda through training and validation sets. Essentially, lambda ranges from zero to infinity, where zero indicates no regularization, and increasing values correspond to progressively stronger regularization effects.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image18.png)

**Regularization** is a tunable parameter used to control the degree of preventing model overfitting to training data. Let's look at some simple regularization examples.  

First consider **L2 regularization**. This method requires taking the weight matrix, squaring each element, summing the results, multiplying by the lambda coefficient, and adding to the total loss function. Its mathematical expression is:  

\(R(W) = \sum_k \sum_l W_{k,l}^2\)  

**L1 regularization** is similar but takes absolute values instead of squaring elements:  

\(R(W) = \sum_k \sum_l |W_{k,l}|\)  

Elastic net (L1 + L2) combines both regularization methods:  

\(R(W) = \sum_k \sum_l \beta W_{k,l}^2 + |W_{k,l}|\)  

In actual training, these regularization methods produce different effects. L2 regularization's handling of smaller values (such as 0.001 squared becoming 0.000001) can keep weight values in ranges close to zero, making L2 regularization particularly effective at maintaining smaller weight values.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image19.png)

When values are small, **L2 regularization** imposes significantly lower penalties because it squares the values. In contrast, **L1 regularization** doesn't square values, so penalties remain linearly proportional to baseline values. This leads to a key practical difference: L1 regularization tends to generate weight matrices with many zero or near-zero values, while L2 regularization produces more uniformly distributed, smaller but non-zero weight values due to the decay effect of penalties.  

The reason L2 prefers uniformly distributed small weights is obvious, but why does L1 tend toward sparse vectors? An intuitive explanation is: if a weight can be zero with little impact on performance, L1 will push it toward zero. In L2, due to the squaring effect, weights may become very small but remain non-zero.  

This raises a question: what exactly does "pushing toward zero" mean? Essentially, we aim to minimize the comprehensive loss term that includes both regularization and data loss. If data loss remains relatively unchanged while the regularization term decreases, the optimization process will prioritize reducing the regularization term, resulting in a more optimized model.  

This trade-off requires balancing between regularization and data loss terms to improve performance on test data—even if it means slightly sacrificing performance on training data. In subsequent lectures, we will explore more complex forms of regularization, all following this fundamental principle.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image20.png)

Some regularization techniques can even modify the model's layer structure, making them quite complex. This remains an active research area with new papers published each year. In this course, we will only cover a small portion of these techniques.

In summary, **regularization** serves multiple purposes. First, it allows us to express preferences for weights. For example, if we believe the solution should be distributed or sparse—meaning many values in the weight matrix are zero—we might prefer **L1 regularization** over **L2**. Additionally, regularization can simplify models and improve their performance on test data. For example, applying strong regularization to high-order polynomial terms can yield more streamlined models.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image21.png)

For example, in the context of **L2 regularization** (though we won't delve deeply), it can optimize the training process. Treating the squared term as a parabola, such as \\(y = x^2\\), this is a convex function. This convexity brings good optimization properties, including the existence of a **global minimum**. Although this topic is beyond the scope of this course, it's worth noting that regularization can accelerate model training under certain optimization methods.

Now, I have a question. Please use one finger to represent **W1** and two fingers to represent **W2**. Given input \\(x\\), the dot product with either weight vector yields the same score of 1, meaning the data loss is identical. Which weight vector would L2 regularization prefer, W1 or W2?

[Most audience members respond with two fingers.]

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image22.png)

The **regularization term** is smaller in W2 because the weights are more distributed. When squaring each term, one-quarter becomes one-sixteenth. After summing these terms, the total regularization term is one-quarter. In contrast, squaring each term in W1 results in regularization loss four times higher.  

The **intuitive understanding** is that more distributed weights are preferred. Now think about which case L1 regularization would prefer. You can choose weight one or weight two.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image23.png)

This question is somewhat of a trap.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image24.png)

**L1 regularization** involves summing the terms. In practical applications, you might observe this phenomenon, which is attributed to **sparsity properties**.  

From the perspective of the loss function, these two weights are equivalent under L1 regularization because one is four summations of 0.25, while the other is directly 1. Both sums equal 1, thus producing the same regularization term.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image25.png)

Under what circumstances would you choose **L1 regularization** over **L2 regularization**? For example, when the coefficient is 0.9?  

L1 regularization is typically used when you need to create sparse models, meaning it will compress certain feature coefficients directly to zero. This is particularly useful in feature selection, especially when dealing with high-dimensional data where many features may be irrelevant.  

For example, if the coefficient is 0.9, with sufficiently strong penalty, L1 regularization might compress it to zero, completely removing that feature from the model. In contrast, L2 regularization would only slightly shrink the coefficient, retaining the feature but reducing its influence.  

**Core conclusion**: Choose L1 regularization when you need simpler, more interpretable models with fewer features; while L2 is more suitable for regular scenarios, avoiding overfitting without completely removing features.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image26.png)

In summary, we have a dataset of \\((X, Y)\\) pairs and a method for computing scores for each class using a **linear model** through matrix multiplication. As previously mentioned, the loss calculation for each training sample in the **Softmax loss function** includes: taking the exponential of scores to ensure positive values, then normalizing through summation to obtain a probability distribution.

The final numerical sum equals 1, with each class assigned a score. The loss for a single sample is the negative log probability of the correct label. The total loss is calculated by summing these individual losses for all training samples and adding a **regularization term** that depends on the model weights.

Softmax is particularly useful because it can convert any set of floating-point numbers into a valid probability distribution with output sum equal to 1.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image27.png)

**Score values** determine the relative probability of that result. For example, when some positive score is high while other negative scores are low, **softmax probability** will make the high-score result approach 1 while other results approach 0. This property allows softmax to convert any list of floating-point numbers into a probability distribution based on their values.

Regarding **regularization**, L1 and L2 methods control model complexity by penalizing weight magnitudes. **L1 regularization** promotes sparsity, thereby generating simpler linear models with fewer non-zero coefficients. But regularization doesn't universally guarantee simpler models—its effects depend on specific application scenarios. For example, in the initial chart, L1 or L2 regularization might impose harsher penalties on high-order polynomial terms.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image28.png)

In this context, it's obviously possible to design **regularization** to bias toward simpler models. However, this isn't always the case. The core idea is to improve test performance at the cost of training performance, but this doesn't necessarily lead to simpler models. For example, techniques like **dropout** introduce additional complexity while improving test performance.  

Since we've discussed how to evaluate the quality of a given weight matrix \\(W\\) based on training data and regularization terms, the next question is how to find the optimal \\(W\\). This leads to **optimization**, which is the focus of the second half of today's lecture.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image29.png)

When discussing optimization problems, the concept of **loss landscape** is often used. This can be visualized as a three-dimensional terrain map, where the vertical Z-axis represents the loss value we need to minimize. In this example, the model has two parameters, corresponding to X and Y coordinates on the terrain map. The **optimization process** is similar to navigating through this terrain to find the lowest point.

But this analogy has limitations. Humans can intuitively identify the lowest point in a valley, while optimization algorithms lack this immediate spatial perception ability.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image30.png)

This analogy is quite accurate. Imagine a person with blindfolded eyes who cannot rely on visual cues and can only judge the terrain slope at their current position through the feeling under their feet.  

From this perspective, this analogy **accurately maps** our process of seeking the optimal model. We explore forward in the complex loss value terrain determined by model parameters—these parameters correspond to individual positions in the terrain. The real challenge lies in how to find the best position in this terrain.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image31.png)

We can adopt a simple and direct method (though not mathematically rigorous), which is to randomly sample a thousand different sets of values for the weight matrix **\\(W\\)** and select the best-performing set. Although this method is somewhat simple, its effectiveness would still be better than a random baseline.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image32.png)

If there's no other choice, this method might not be completely unreasonable, achieving about **15.5% accuracy** on the **CIFAR-10 dataset**—the dataset I mentioned earlier that contains images of objects from 10 categories like frogs and cars.  

But its performance is far from optimal. Through modern deep learning techniques, the **state-of-the-art** results on this dataset have reached **99.7% accuracy**. While 15.5% isn't bad, it's clearly not impressive.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image33.png)

The core of strategy two lies in following the **gradient**. Imagine you're blindfolded in a terrain, judging the direction of slopes by sensing the ground under your feet.  

This concept is crucial when training models in this course and throughout the entire field of deep learning. You need to evaluate your current position and move in the downhill direction accordingly.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image34.png)

This provides an intuitive explanation. Next we will delve into **mathematical details**, but please always keep this visualization concept in mind. How do we move along the slope?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image35.png)

In one-dimensional space, the concept of **derivatives** is well-known. In calculus, it can be defined as the limit of the difference quotient: add a small increment \\( h \\) to the current position, calculate the function value at the new position, subtract the current value, and divide by the step size. When \\( h \\) approaches zero, this limit is the derivative at that point.

In multidimensional space, we need to use **gradients**—applying the above limit definition to each variable separately, resulting in a vector composed of partial derivatives that represents slopes in each dimension. The steepest descent direction is given by the negative gradient, because the gradient points in the ascending direction while its opposite points in the descending direction, making this direction optimal for minimizing the loss function terrain.

When computing derivatives, we can use the limit definition method with small \\( h \\) values (such as \\( 0.0001 \\)). By taking function values at \\( w + h \\) and \\( w \\), the difference quotient can approximate the derivative. But this method is slow, imprecise, and susceptible to floating-point errors, making it unsuitable for large-scale scenarios.

The **loss function** depends on weights \\( w \\), input data \\( x_i \\), and labels \\( y_i \\), and includes regularization terms. When keeping \\( x_i \\) and \\( y_i \\) constant, the gradient of the loss function with respect to weights is denoted as \\( \\nabla_w L \\). This gradient is crucial for optimization algorithms like stochastic gradient descent, momentum, AdaGrad, and Adam. For more details, see Stanford CS231N Lecture 3 "Regularization and Optimization".

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image36.png)

For this, we can use **calculus**, utilizing the chain rule and various differentiation techniques to handle equations that may contain logarithms, exponentials, and other components.  

This will be an exercise in the homework, so I won't detail the step-by-step process here. However, this method is conceptually straightforward: treat *x* and *y* as constants and compute the derivative with respect to *w*.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image37.png)

Now, we have a method for computing \\(w\\), more accurately, computing the gradient \\(dw\\) of the loss function relative to data, current \\(w\\) values, and quantified error.  

Summary as follows:  
- **Numerical gradient**: Simple to implement—just add a small quantity \\(h\\), compute the difference, and divide by \\(h\\). But this method is slow and approximate.  
- **Analytical gradient**: Provides precise and fast computation, but if you need to derive new gradients from scratch, errors may occur.  

Best practice is usually to perform gradient checking by comparing numerical gradients (using small \\(h\\)) with analytical gradients to ensure correctness. In homework, you will verify the accuracy of your written code by implementing gradient checking.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image38.png)

The question is: Why do we usually prefer **differentiable loss functions**? The answer lies in being able to compute **gradients**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image39.png)

If we have a better **loss function** but cannot compute gradients analytically, we can use numerical methods. However, constructing a non-differentiable loss function is usually challenging.

If the optimal loss function for your case is non-differentiable, this method might be effective, but if the loss function is completely non-differentiable (such as a set of discrete isolated points), this method would encounter difficulties.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image40.png)

Moving along the **steepest descent** direction may not find the optimal solution, especially when the terrain structure is disconnected. While this method might work, if the **loss function** is non-differentiable over most of its domain, these methods would likely fail because they might not locate the global minimum.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image41.png)

In summary, **gradient descent** or **steepest descent** performs excellently on convex functions. However, for non-differentiable and non-convex functions, this method may not yield optimal results because the stepping direction might be incorrect.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image42.png)

If your code is correct, it's not necessarily error-prone. However, if there are errors in the code, they might be difficult to detect immediately.

The **limit definition of h** is simple to implement—just set h to a very small value, evaluate the function, then add a small increment. As long as the implementation runs as expected, this method is **less error-prone** in practice.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image43.png)

Now, I will discuss a fundamental optimization algorithm called **gradient descent**. Its core idea aligns with our previous explanation: compute the slope at each point on the loss function surface and take a step toward the minimum along the descending direction.

Specifically, we use the loss function, data, and current weight values to compute the **gradient** of weights, which indicates how much each weight should be adjusted to move along the slope downward. The **step size** determines the magnitude of movement along the negative gradient direction.

The mathematical expression is:  
\(w_{t+1} = w_t - \eta \nabla L(w_t)\)  
where \\(\\eta\\) represents the **learning rate** and \\(\\nabla L(w_t)\\) is the gradient of the loss function with respect to weights.

Essentially, gradient descent is the process of iteratively computing gradients and moving along the steepest descent direction.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image44.png)

Consider a specific example. We usually don't directly visualize **three-dimensional loss surfaces**, but present them in a top-down view where purple represents the highest points and red indicates valleys.

Starting from the initial weight matrix \\(W\\), we compute the loss value and determine the **negative gradient direction**. The arrow represents the fixed step size discussed earlier, indicating movement in that direction.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image45.png)

Yes, you can observe that the step size is fixed. However, as the gradient gradually decreases, we still multiply it by this fixed step size. Therefore, the **effective step size** decreases because gradients are smaller near flat regions of the loss function. This behavior occurs as we continue moving along the steepest descent direction.

A naturally arising question is: How do we determine when to stop during the descent process? Under the current setup, this process would loop infinitely without termination. This method is **not optimal**. Usually, you can either preset the number of optimization iterations or monitor changes in the loss function and stop when it falls below a certain fixed threshold.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image46.png)

Loss continues to decrease, but when the reduction becomes negligible (such as \\(1 \\times 10^{-5}\\) or \\(1 \\times 10^{-9}\\) magnitude), training can be stopped because further improvements are minimal. **Termination conditions** can be determined by fixed iteration counts or stopping criteria based on improvement rates.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image47.png)

Now, I will discuss the most popular variant of gradient descent—**Stochastic Gradient Descent (SGD)**. The gradient descent method we introduced earlier requires computing the loss of weight parameters on the entire training set, i.e., summing the losses \\(L_i\\) corresponding to each \\(i\\) in the dataset. But this method has high computational costs on large datasets.

**SGD's improvement** lies in processing only a subset of data in each iteration, called a mini-batch or batch. For example, in the code, we sample 256 data points from the dataset, where the batch size is 256. We then compute the gradient for this subset and update parameters according to the original steps.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image48.png)

The term "stochastic gradient descent" comes from the algorithm using random subsamples of the dataset in each iteration. In practice, it's not completely random sampling but ensures all data points are used once in random order, constituting one training epoch.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image49.png)

**Gradient descent** and **stochastic gradient descent** have several problems. This visualization chart is similar to the colored version I showed earlier, presenting the loss function landscape from a top-down view. The curves in the figure are contour lines representing points with the same loss values.

Typical problems often occur in narrow valley regions: steep gradients on both sides but gentle in the center. Gradient descent performs poorly in such scenarios. The primary problem is **oscillation due to excessive step size**: if the learning rate is set too high, the algorithm may jump back and forth on both sides of the valley or even deviate from the valley bottom. This is because fixed step sizes in steep gradient directions cause outward bouncing updates.

Even with moderate learning rates, another problem emerges: the algorithm produces violent jittering in steep directions but struggles to effectively advance toward the center region. This inefficiency stems from significant imbalance in gradient magnitudes across different dimensions.

From a mathematical perspective, this phenomenon corresponds to the high **condition number** of the loss function—the ratio of the largest to smallest singular values of the Hessian matrix. The second-order derivatives of the Hessian matrix have extremely large values in steep directions but very small values in gentle directions, exacerbating optimization difficulty.

Another challenge for SGD is the existence of **local minima** or **saddle points**. For example, when the loss function becomes flat at a certain point, vanishing gradients cause optimization to stagnate. The algorithm may oscillate around such points for extended periods, unable to escape due to lack of effective gradient signals.

These problems reveal the limitations of basic SGD and drive the need for more advanced optimization techniques.

In this context, the algorithm might get stuck in **local minima** because the gradient at that point is zero. But if we move slightly, we might achieve significant descent. This raises a thought: Could adjusting the **step size** optimize the entire process?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image50.png)

Perhaps we could use the **Hessian matrix** to determine the optimization direction. Although we'll have a slide briefly discussing Hessian-based methods later, these methods are not commonly used in deep learning. However, we'll soon explore several alternatives to solve this problem.  

Based on experience, **saddle points** become increasingly common in high-dimensional models. As weight matrix sizes increase, the probability of encountering saddle points also rises. This phenomenon is documented in detail in a paper studying their frequency.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image51.png)

**Saddle points** are named for their resemblance to horse saddles. At the center of this point, gradients in all directions are zero, while exhibiting local minimum and maximum curvature properties. Whether along the X-axis or Y-axis direction, gradients vanish, and even though lower loss regions exist nearby, this can still cause the optimization process to stagnate.

This phenomenon is particularly common in stochastic gradient descent (SGD), especially when moving to higher-dimensional spaces or models with more parameters.  

Taking the function \\(f(x,y) = x^2 - y^2\\) as an example, it exhibits typical saddle point characteristics at the origin. Such configurations are common challenges in optimization problems.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image52.png)

This presents a major challenge.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image53.png)

The final problem with stochastic gradient descent (SGD) is: we only sample a subset of data each time rather than examining the entire dataset. This means our updates are based on local observations of the overall loss function, resulting in gradient steps with noise. Although we generally move toward local minima, due to this subsampling, each step may have slight deviations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image54.png)

In summary, these are the core problems, and there's an **effective technique** among them—introducing **momentum**. This can be analogized to the process of a small ball rolling down a hill continuously accumulating momentum, similar to modeling in physical systems.  

This analogy helps build intuitive understanding. For example, momentum can help escape **local minima** because sufficient speed allows the ball to overcome such obstacles.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image55.png)

If the model encounters **saddle points** or flat regions, it won't get trapped because it has already completed the descent process of the entire hill. Additionally, poor conditioning may cause some oscillation, but the model will accumulate speed by continuously moving in the correct direction, thus converging toward the center faster.  

**Momentum** also mitigates gradient noise by utilizing common directions pointing toward minima. During momentum computation, it strengthens this direction, accelerating convergence by considering the common directional components of noise.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image56.png)

Let me demonstrate this process. This illustrates the fundamental principle behind **momentum**. Here we're using **Stochastic Gradient Descent (SGD)**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image57.png)

We have mini-batch data \\(X\\) and compute gradient \\(DX\\). By using learning rate (step size) \\(\\alpha\\), we update parameters by multiplying and negating the gradient to achieve descent. This defines **Stochastic Gradient Descent (SGD)**.

After introducing momentum, we add a **velocity term** to the update. Updates no longer depend solely on the current gradient but utilize this velocity term. The velocity at each time step is a weighted combination of the previous step's velocity and the current gradient, with momentum coefficient \\(\\rho\\) controlling the weight. Higher \\(\\rho\\) values make the system more dependent on historical velocity, creating a moving average effect. The momentum term balances contributions from historical and current gradients.

The update rule remains simple: compute velocity as a function of current velocity and gradient, then apply step size \\(\\alpha\\).

This method solves previously discussed problems through smooth updates and reduced oscillation. I'll pause here to see if there are questions—this concludes the explanation of momentum.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image58.png)

When introducing **momentum** based on historical gradient steps, optimization trajectories tend to maintain inertia in the current direction. High momentum values can escape local minima by crossing large gradients. Momentum is particularly effective when traversing **saddle points** because it can maintain previous forward directions for extended periods.

Under ill-conditioned circumstances, if gradients consistently point rightward at each step, momentum will continuously accumulate in that direction. Conversely, violent oscillations will cause weakened movement because opposite gradient directions will cancel out velocity.

In practice, we need to consider cases where optimization paths happen to align along saddle points, but such situations are extremely unlikely in practice.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image59.png)

In this case, you might get stuck in **saddle point** dilemmas, mainly caused by unfavorable initial conditions. While such situations are relatively rare, practitioners typically mitigate this problem by running model training multiple times with different random seeds. Stochastic gradient descent (SGD) itself introduces noise, which helps escape saddle points. This problem is not unique to SGD—other gradient-based optimization methods lacking additional mechanisms face the same challenges.  

Regarding **momentum methods**, while they may slow convergence due to overshooting phenomena, they generally help find better minima points. Empirical evidence shows their effectiveness in neural network training, but the best choice depends on specific models. Practitioners usually try multiple methods to determine the optimal solution. Due to practical benefits, momentum methods are widely adopted, but in some cases, alternatives like plain SGD may perform better.  

This concludes our discussion of saddle points and momentum methods. We continue forward.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image60.png)

Another point to note is that these equations can be expressed in different forms. Although different implementation approaches lead to formula differences, they are **mathematically equivalent**. For brevity, I won't delve into equivalence proofs, but you can verify this by consulting the slides.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image61.png)

Next, I will introduce another optimizer. Previously we discussed **Momentum**, now we'll explore **RMSProp**. Although RMSProp is an older method proposed by Geoffrey Hinton's team in 2012, it remains practical today. Its core idea is to perform element-wise scaling of gradients rather than relying solely on the "running velocity" captured by momentum methods.  

The specific implementation introduces **gradient squared terms**, where the **decay rate** serves similarly to the momentum term discussed earlier, but here applied to squared gradients. We maintain a moving average by combining previous gradient squared terms with current gradient squared terms weighted by the decay rate. This makes larger values more prominent while further weakening smaller values. If certain dimensions consistently show large gradients, this moving average mechanism will amplify them over time.  

In the parameter update step, we divide by the square root of this moving average. This method adjusts the stepping direction, responding to the previous question about "how to modify stepping direction." Specifically, for parameters with large gradient squares (i.e., steep derivatives), step sizes are reduced by dividing by larger values; conversely, in flat regions, dividing by smaller terms allows larger step sizes.  

RMSProp's intuitive idea is to dynamically adjust step sizes based on gradient terrain. It directly addresses the question "how to change stepping direction." Although the **learning rate** itself remains constant, it's scaled by the square root of accumulated squared gradients. This ensures larger step sizes in flat regions of the loss function and smaller step sizes in steep regions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image62.png)

Can someone explain what this line of code specifically does?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image63.png)

What happens to our **gradient step direction**? How does it change?

We divide by a value that depends on both current and historical gradients. These are vector operations involving element-wise division of one set of derivatives by another set of squared gradient values.

When these values are large, the denominator becomes significant, effectively reducing step size in that direction. Conversely, when these values are small, step sizes increase accordingly because gradient squared terms in the denominator decrease.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image64.png)

In this specific example, we encounter a narrow valley terrain where the goal is to move more in the gentler direction. This raises a question: **In this context, what does small gradient mean**? How does it reduce movement along steep directions and promote movement along flat directions?

This visualization effectively compares three different methods.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image65.png)

When using **momentum**, you can observe that it initially overshoots as discussed earlier, but then corrects its trajectory. **Stochastic Gradient Descent (SGD)** progresses slowly because it always moves in fixed directions. The **RMSProp** we just introduced operates by adjusting step sizes based on gradient squares.

Since the gradient in the direction my mouse points is large, the squared term increases, causing step size in that direction to shrink. Therefore, RMSProp quickly redirects to the gentler center region of the terrain, prioritizing movement along directions with smaller gradients.

This mechanism dynamically changes the optimization path by favoring gentle directions over steep directions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image66.png)

Here are the three main optimizers. Additionally, we will discuss **Adam**—the most widely used optimizer in modern deep learning today. Adam combines the advantages of **stochastic gradient descent** momentum methods with RMSprop algorithm characteristics.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image67.png)

This is essentially the **Adam optimizer**—the most widely applied optimizer in the field of deep learning. Now you have all the prerequisite knowledge needed to understand it.

The first term highlighted in red represents the **momentum** we discussed earlier, where \\(\\beta_1\\) serves as the momentum term, and we continuously perform moving average processing on velocity.

The second moment corresponds to the **gradient squared term** in RMSprop. Here we multiply the learning rate with velocity (rather than step size) while still taking the square root of the second moment.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image68.png)

The inspiration for using **first-order and second-order moments** comes from concepts in physics and mechanics. Essentially, Adam combines the two ideas we discussed earlier: accelerating movement in flat directions while suppressing movement in steep directions. It also incorporates the concept of **momentum and velocity**, allowing speed to gradually accumulate when continuously moving in the same direction.

However, the current formula may have problems during the first iteration. Hyperparameters \\(\\beta_1\\) and \\(\\beta_2\\) are usually initialized close to 1 (such as 0.9 and 0.999), while moment estimates are initialized to zero. If Adam is applied directly in this form, it might lead to undesirable behavior, mainly stemming from **second moment computation**.

The core problem occurs when computing the second moment and using it for subsequent steps—specifically, the denominator becomes zero, interfering with the optimization process.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image69.png)

This process starts from **zero**, so this term is zero. When **beta** values are large, this term becomes very small. If gradients in initial steps aren't significant enough, the entire term will remain close to zero. Dividing by a value close to zero causes initial step sizes to be too large, despite small gradient magnitudes. This result is undesirable.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image70.png)

**Adam's** final characteristic is introducing bias correction terms aimed at solving dependency on training time steps. This concept will be further explored in homework.

Adam's intuition is to alleviate the problem of excessive initial step sizes in naive implementations. As training progresses and time steps increase, the influence of these bias terms gradually diminishes.

In practice, here are the default parameters commonly used when training models with Adam. While they work well as starting points, their effectiveness may vary by situation. More details can be found in the remaining slides.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image71.png)

We will explore how to determine if your **learning rate** is appropriate and how to verify the correctness of other parameters. To save time, I'll speed up the explanation slightly.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image72.png)

The basic concept is that all these different optimizers will eventually converge.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image73.png)

They each have unique properties. **Notably**, Adam combines characteristics of RMSProp and stochastic gradient descent (SGD) with momentum, which is visually obvious and aligns with our intuitive understanding.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image74.png)

The final topic about **Adam** is the interaction between regularization and optimizers. For example, when using L2 regularization, its impact on optimizer behavior isn't intuitive and can be implemented in different ways.

In the default **Adam optimizer**, L2 regularization is integrated into the gradient computation process. Gradients include both data loss and regularization loss. However, **AdamW** only considers data loss during momentum computation and adds the regularization term separately at the end.

This highlights the flexibility of integrating regularization into optimizers. **Weight decay** typically requires adding regularization terms at the end without incorporating them into the optimizer's velocity and momentum calculations. In many cases, AdamW performs slightly better, as evidenced by Meta's **Lama series** models.

The key difference is whether regularization is mixed into a single function (Adam) or kept separate (AdamW). The latter ensures that velocity and momentum depend only on loss values, not on weights themselves.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image75.png)

When traversing loss function surfaces independently of weight values, it's best to separate **regularization terms** to avoid interfering with momentum calculations. This method has been empirically validated—both approaches should be tested to determine optimal performance.

Now let's discuss the **learning rate** problem.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image76.png)

There are various methods for choosing learning rates. **Excessive learning rates** cause loss values to rise dramatically because the model oscillates violently in loss space, as mentioned earlier. Conversely, **learning rates that are too low** slow convergence. Moderately high learning rates may cause the model to oscillate near local minima without further optimization, hindering convergence.

The **optimal learning rate** should achieve rapid loss reduction in early training while maintaining gradual improvement during continuous training. In practice, learning rate appropriateness depends on specific scenarios and training phases. Modern deep learning models typically adopt **dynamic learning rate adjustment strategies** rather than fixed values, and this approach has proven effective in cutting-edge model implementations.

Today's lecture content concludes here.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image77.png)

A simple method is to reduce the **learning rate** by ten times after a fixed number of iterations. When learning rates are too high to achieve further convergence, this method effectively helps models explore the loss function landscape more deeply. This technique is commonly used in training **Residual Networks (ResNets)**—popular convolutional neural network architectures we'll introduce later in the course.

Another widely adopted method is **cosine learning rate decay**. This method makes learning rates follow a half-cosine wave curve, gradually decaying from maximum values to zero. Although we won't delve into formula details, the **key point** is that different schedulers produce significantly different loss curve patterns during training. For example, cosine decay typically brings stable improvement in mid-training, while step decay (like tenfold learning rate reduction) produces entirely different patterns.

**Linear learning rate decay** is another option, where learning rates decrease linearly over time. Other variants include **square root inverse decay** and many other methods. Scheduler choice depends on model characteristics and actual performance, requiring experimentation to determine optimal solutions.

The current popular strategy is to set a **linear warmup phase** before applying the main scheduler: models don't start directly from maximum learning rates but gradually increase to target values over a fixed number of iterations. For example, combining linear warmup with cosine decay or square root inverse decay is a common configuration.

Finally, the **linear scaling rule** states that when batch size or the number of training samples per update increases by \\(N\\) times, the learning rate should also be proportionally increased by \\(N\\) times. This empirical rule maintains stability during large-batch training.

The mathematical foundation of this concept is complex, mainly based on **empirical observations**. Although research has attempted to prove its effectiveness mathematically—considering gradient changes, batch sizes, and the number of gradients computed per batch—its practical utility has been widely validated through experiments across various problems. As a **practical guideline**, if you have a successful configuration and want to increase batch size, you should proportionally increase the learning rate.  

In short, I should also mention **second-order optimization methods**, which utilize the Hessian matrix (this topic was mentioned in previous questions). Although the course won't delve deeply, it's worth knowing they exist. The core idea is to fit a quadratic polynomial to the function through derivatives or the Hessian matrix at a point, then locate the minimum point.  

Although this optimization method performs excellently in some scenarios, it's rarely used in deep learning, mainly facing two major challenges: first, it requires **Taylor series expansion**, while existing methods typically rely only on first-order derivatives; second, for large-scale neural networks with millions or billions of parameters, computing mixed derivatives for all parameters brings unbearable computational burden.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image78.png)

In practice, we avoid using this method because the involved **matrices** become too large. Therefore, especially when trying to run on GPU memory, it leads to memory exhaustion.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image79.png)

When training smaller models or willing to invest more time for better convergence, this method can be very effective depending on the specific problem. For **small models**, it performs quite well. However, for **large neural networks**, due to memory limitations and high computational costs of computing Hessian matrices, we usually avoid this method, instead choosing to process more training data to improve efficiency.  

Regarding practical advice: when starting projects in new domains, **Adam or AdamW** are excellent default choices. Even with constant learning rates, they perform well, though many practitioners combine them with linear warmup and cosine decay—this combination is both popular and efficient. Although **SGD with momentum** might sometimes surpass Adam, it requires more complex hyperparameter tuning (especially learning rates and scheduler values) because it lacks the adaptive scaling capabilities provided by RMSprop.  

Adam has been validated as robust across multiple domains due to its adaptability to loss function landscapes. But if using **full batch updates** (where each batch contains the entire training set), exploring second-order or higher-order optimization methods might be more advantageous, especially for smaller datasets or models.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image80.png)

You can benefit from **nonlinear update steps** and more complex strategies to find minima.  

This concludes today's lecture content. I'll provide some slides about future topics, such as optimizing functions more complex than **linear models**, which is also the focus of this lecture.  

In the next lecture, we will explore **neural networks**, a very fascinating topic. Specifically, we will discuss **two-layer neural networks**, which involve two weight matrices—one for each layer—and apply a nonlinear function between them, such as the **ReLU function**. You will learn about these in more detail.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image81.png)

The **core concept** is that we now have two weight matrices and apply an additional nonlinear function between their computations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_3_image82.png)

If we try to build a **linear classifier** for this type of data, we encounter the problem that blue and red points are inseparable. However, through multi-layer model transformation, we can ultimately map data to a **linearly separable** space, which corresponds to the final layer of our model.

