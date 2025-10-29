---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 7: Recurrent Neural Networks"
date: 2025-09-09T17:28:06+08:00
draft: false
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image1.png)
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image2.png)

Welcome to Lecture 7. First, I'd like to make some clarifications about the content from the previous lecture. In the last class, there were two **Ed forum posts** worth reviewing. For students who missed this content, I'll provide a brief overview.

There was some confusion when discussing **Dropout** and how to adjust probabilities during the testing phase. There was a subtle inconsistency in the slides. In each forward propagation, Dropout involves a hyperparameter \\(p\\), which depending on the specific implementation, might represent the proportion of neurons being discarded or the proportion being retained.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image3.png)

Typically, **dropout rate** corresponds to the proportion of units being deactivated. In most libraries, this parameter is represented by \\( p \\).  

The core principle is to maintain consistent expected output values between training and testing phases. Therefore, if 25% of activation values are discarded during training, remaining activation values should be scaled by 0.75 during testing.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image4.png)

Expected output remains unchanged. Since this slide implementation uses \\(p\\) to represent the probability of keeping unit activations, it caused some confusion, leading to subtle deviations in expression. To clarify this...

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image5.png)

In the previous lecture, someone raised a question about the utility of **normalization** in solving problems caused by improper weight initialization. In our simplified example, we considered a two-layer neural network with **ReLU activation functions** that processes two-dimensional input and outputs quadrant functions. Output depends on which quadrant the input point lies in, potentially producing values like one, two, three, or four.

We compared training and test losses under two scenarios: **good initialization** using Kaiming initialization versus **poor initialization** with excessive standard deviation. Blue curves show loss conditions under poor initialization, while green curves show results after adding layer normalization. Experimental results indicate that **layer normalization** can effectively alleviate most problems caused by improper initialization.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image6.png)

For optimal performance, **proper weight initialization** remains crucial, as reflected in the subsequent two lines of code. **Layer normalization effects** vary by specific problems.  

In the first quadrant, when precise two-dimensional coordinates for each point aren't needed, layer normalization can play a positive role. However, for functions requiring precise positional information to generate correct outputs, layer normalization may blur spatial details through mean subtraction and standard deviation division, actually reducing model performance.  

Overall, although normalization can solve some problems, core challenges of weight initialization persist. Additionally, its applicability depends on specific modeling objectives.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image7.png)

Reviewing previous content, we mainly discussed standard non-recurrent neural networks (Vanilla Standard Non-Recurrent Neural Networks). These networks use fixed-size inputs and outputs, with construction processes including selecting **activation functions**, preprocessing image channels with fixed means and standard deviations, and applying **weight initialization and normalization techniques**.  

We also utilized **transfer learning**—pre-training on large internet datasets like ImageNet and initializing networks based on these pre-trained model weights, typically achieving better results.  

Additionally, we explored **training dynamics**: monitoring learning progress by selecting appropriate learning rates, adjusting hyperparameters based on validation set performance and optimization. We also introduced **test-time data augmentation** as a method to improve model performance.  

Throughout these processes, one efficient tool I frequently use is **Weights and Biases**, which I recommend you try.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image8.png)

This method provides an effective way to compare results from multiple runs under different **hyperparameter** configurations. Here shows a column containing various dropout rate values, with color coding intuitively indicating that lower dropout rates typically bring higher accuracy.  

You can visualize these hyperparameters based on validation set performance and determine optimal parameter combinations through multiple experiments. I believe this method is highly practical, especially when computational resources allow repeated experiments to optimize performance.  

Although tools like **TensorBoard** exist, this visualization approach remains my preferred solution.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image9.png)

In the remaining part of today's lecture, we'll focus on **sequence modeling**. This contrasts sharply with models with fixed-size inputs. How to handle variable-length input sequences? We'll examine simple neural networks used before the Transformer era, mainly Recurrent Neural Networks (RNNs) and their variants. Additionally, I'll use a slide to explain how RNNs share commonalities with and provide inspiration for modern state-space models in language modeling (like Mamba, which we'll discuss later). RNN core concepts remain relevant today, even showing unique advantages over Transformers in certain aspects.  

To formalize sequence modeling, first review basic neural networks with fixed-size input-output covered in this course so far. In contrast, sequence modeling tasks can be divided into three categories:  

1. **One-to-many**: Fixed-size input (like images) generates variable-length output sequences. Typical examples include image caption generation—input is an image, output is description text of varying lengths (using words or characters as units depending on language models).  

2. **Many-to-one**: Input sequences (like video frames) produce single outputs (e.g., category labels for video classification). This essentially extends image classification paradigms to sequential input data.  

3. **Many-to-many**: Scenarios involving both sequence input and output, which we'll explore in detail during the course.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image10.png)

The number of inputs and outputs in sequences need not match. For example, input might contain **variable numbers of frames**, while output might be variable-length description text. Although they don't necessarily need alignment, they can be aligned. You can generate one output for each input.  

When discussing Recurrent Neural Networks (RNNs), we'll mainly focus on the scenario shown in the rightmost diagram. Although problems can be reformulated as other scenarios through fine-tuning, this is the most direct approach: each input corresponds to one output.  

We'll use this framework at the beginning of the course to explain how RNNs work. A typical example is video classification, where each frame is classified individually.  

So, what is an RNN?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image11.png)

Basic concepts involve an input sequence \\(X\\) and an output sequence \\(Y\\). The core feature of Recurrent Neural Networks (RNNs) lies in their recurrent nature, typically represented by feedback arrows pointing to modules in structural diagrams, with this symbol representing a recurrent layer.

**RNN** maintains an internal state called **hidden state**, which continuously updates during sequence processing. Each time the model receives new input, it recalculates the hidden state.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image12.png)

There exists a **hidden state** that updates based on new input and previous internal or hidden state. When considering gradient computation and operation order, this diagram might be confusing.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image13.png)

People commonly use unfolded **RNN diagrams** to explain this concept. The basic principle here remains consistent with before, but we clearly show that current hidden state computation depends on both input at this timestep and previous RNN state.

This approach can more clearly model the precise computational conditions required for each output when traversing computational graphs in reverse.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image14.png)

Now let's express this process with mathematical formulas. The basic idea is to process vector sequences \\(x\\) by applying recursive formulas at each timestep. New hidden state is a function of old hidden state and current timestep input vector, including activation functions and parameters \\(W\\).

This is similar to neural network layers we initially studied, both involving weight matrix multiplication followed by activation function application. The **key difference** lies in recursiveness here: we use the same weights \\(W\\) and same activation function to compute each hidden state.

To obtain output, we introduce a function with independent parameters. This function transforms hidden state to output dimensions. Specifically, weight matrix \\(W_{hy}\\) multiplies with hidden state to generate output. This achieves two purposes: adjusting dimensions from hidden state size to output size, and applying learned transformations.

In summary, recursive formulas update hidden states, while \\(W_{hy}\\) maps them to required output dimensions.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image15.png)

It not only performs dimensional transformation but also applies conversion to hidden state. **This mechanism** transforms hidden state into output, which is exactly what \\(W_{hy}\\) does.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image16.png)

The previous slide showed methods for computing new hidden states. This process has **recursive nature**, using the same set of parameters. Specifically, one set of parameters and corresponding functions compute hidden states, while another set of parameters and functions generate outputs based on tasks and **RNN modeling methods**. Weights remain shared across timesteps.

There are two different operations:
1. Computing new hidden state, representing RNN's internal state.
2. Converting that hidden state to output, as shown in the slide.

This will become clearer through specific example analysis.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image17.png)

Looking at this unfolded diagram, we find that **hidden state** needs to be initialized to specific values. This initial state is usually represented as \\(h_0\\), which theoretically can be initialized to any value. In practice, it's typically implemented as a learnable input vector.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image18.png)

Now, we'll analyze each step of the unfolded Recurrent Neural Network (RNN) in detail and demonstrate the forward propagation process through specific examples.

It's important to note that we process input vector sequences \\(x\\) by applying recursive formulas at each timestep. When computing hidden states, each timestep uses the same function and parameter set. Similarly, when predicting outputs from hidden states, each timestep always applies specific functions and parameter sets.

Regarding whether previous output values \\(y\\) can influence new hidden states, the answer is yes under certain model architectures. We'll explain this mechanism through specific examples later.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image19.png)

Recurrent Neural Networks (**RNN**) are most commonly used for tasks like language modeling or autoregressive modeling, where the goal is to predict the next value based on previous values. In this case, previous values are used as input.

Explicit mathematical expression involves determining how current hidden state \\(h_t\\) affects next hidden state \\(h_{t+1}\\). The difference between initial hidden state \\(h_0\\) and first timestep input \\(x_0\\) lies in applied **weights**. Specifically, weights used by \\(h_0\\) persist across all timesteps for updating hidden states, while \\(x_0\\) is processed through different weights.

In summary, the key difference is that initial hidden state and input apply different weights.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image20.png)

When referring to vanilla RNN, it typically means this specific model architecture. Its hidden state \\(h_t\\) uses hyperbolic tangent function (\\(\\tanh\\)) as activation function, which has multiple advantages: \\(\\tanh\\) function output range is limited between \\(-1\\) and \\(1\\), ensuring stability during repeated operations by keeping values within this interval; meanwhile this function is zero-centered symmetric, effectively representing positive and negative values.

In the simplest implementation, output \\(y_t\\) can be computed as linear transformation of hidden state (manifested as matrix multiplication), constituting the most basic implementation form of recurrent neural networks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image21.png)

In today's lecture, we'll manually construct a **Recurrent Neural Network** as a specific case. Unlike using gradient descent or other learning methods, I'll demonstrate how to manually build such a network. This will help you understand **forward propagation processes**, roles of each weight matrix, and how outputs are computed.

In this simplified example, we'll process sequences composed of 0s and 1s. The task requires outputting 1 when two consecutive 1s appear in the sequence, otherwise output 0. For example, given input sequence: 0, 1, 0, 1. Initially no repeated 1s appear, but when two 1s appear consecutively, output should be 1. This is a typical example of **many-to-many sequence modeling tasks**, where each input corresponds to one output.

Now let's discuss high-level design. To build an RNN for this task, what information should **hidden state** capture? Specifically, what information must the model's internal state store to effectively execute this task? One key piece of information is the input value from the previous timestep.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image22.png)

If our output depends only on **hidden state**, what additional information is needed? This hidden state must capture both previous input and current \\(X\\) value (which might be 0 or 1).  

To achieve this, I define hidden state at timestep \\(T\\) as a three-dimensional vector. Three dimensions are chosen for convenience in output stage computation, although two-dimensional vectors would suffice. This method simplifies mathematical expressions in today's lecture.  

**Hidden state** will track two key pieces of information: current value (0 or 1) and previous value (0 or 1). We set initial hidden state \\(H_0\\) to \\([0, 0, 1]\\), indicating the model has observed two consecutive zeros before this timestep.  

Hidden state initialization can use various strategies or even be learned, but this demonstration will use the specified initialization method above.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image23.png)

Now, let's analyze this code step by step. To simplify mathematical operations, we set the activation function to **ReLU**. ReLU function definition is taking the larger of zero or input value. Since this example only involves values of 0 and 1, this makes the analysis process very intuitive.

Although this could be built as a structure suitable for 10H, this example aims to demonstrate execution flow. For simplicity, we choose to use ReLU function.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image24.png)

Theoretically, you could create a model capable of implementing this functionality using **10H**. We use **ReLU activation function** and two specific weight matrices. The first weight matrix transforms previous hidden state to compute next state. The second weight matrix converts input \\(x\\) to match hidden state dimensions while applying a transformation.

Current hidden state \\(h_t\\) is a function of previous hidden state \\(h_{t-1}\\) and current timestep input \\(x_t\\). To compute \\(h_t\\) at timestep \\(t\\), we first compute current value with \\(x_t\\). We set the weight matrix as a \\(3 \\times 1\\) column vector with values \\((1, 0, 0)^T\\), so when \\(x_t=0\\), matrix multiplication yields a zero vector; when \\(x_t=1\\), it produces \\((1, 0, 0)^T\\). This term determines whether the top value in \\(h_t\\) is \\(0\\) or \\(1\\).

For hidden state transformation, we zero out the top row of the weight matrix, making the top value depend only on current input. This ensures the top value of \\(h_t\\) is determined only by the right term. The next row is set to \\((1, 0, 0)\\), which copies the current value from previous timestep \\(h_{t-1}\\) to the "previous" value in \\(h_t\\).

Essentially, the transformation process is as follows:  
- Top value of \\(h_t\\) tracks current input.  
- Middle value of \\(h_t\\) stores current value from previous timestep.  
- Bottom value of \\(h_t\\) remains \\(1\\) throughout all computations.  

In summary, zero values in the weight matrix ensure current input determines the top value, while the \\((1, 0, 0)\\) row passes down the current value from the previous timestep. Output is obtained by tracking these values and applying the aforementioned weight matrix.

Let \\(w\\), \\(h\\), and \\(x\\) represent our weight matrix dimensions. To convert hidden state to output dimensions, we need a \\(1 \\times 3\\) weight matrix. This matrix generates a single output value using hidden dimensions as input, essentially computing **dot product** between these values.

This computation corresponds to current value plus previous value minus one, where minus one comes from multiplication operations in the current step. This demonstrates the utility of **number one** in current and previous associations.

For example, if the sum of current and previous values is two, after subtracting one, the left term of **ReLU function** becomes: \\(\\max(1, 0) = 1\\). If both values are zero, the result after subtraction is zero. Similarly, one plus zero still yields zero.

This explains the construction principle of weight matrices. Before continuing, I'd like to address any questions about these computations, as this is the only instance in the course where we explicitly perform all matrix and vector multiplications.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image25.png)

Remaining content will provide higher-level explanations of how these layers are typically combined. Before continuing, I'd like to address questions about matrix and vector tracking, multiplication operations, and updates.

This raises a key question: **How are weight matrices constructed?** This is an excellent question, which I've included in slides for clear explanation. This process follows the standard method of this course—we use **gradient descent**. We'll specifically discuss gradient descent application across multiple timesteps, especially when each timestep requires loss computation. This topic will be explored in detail later.

This example demonstrates weight matrix multiplication operations. Using these weights for initialization and training other tasks is similar to pre-initializing weights in **transfer learning**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image26.png)

Actually, due to **small hidden state dimensions**, this method's performance won't be very good, while typically we'd use larger hidden states. For demonstration purposes, I deliberately kept hidden states small to fit slide space.

Let's revisit the second row computation. When treating \\(h_{t-1}\\) as a column vector, the left matrix multiplication involves rotating these values and computing dot products. In the second row computation, this entry will equal the top value of the vector. This step demonstrates how current state transitions to previous state.

Through this **matrix multiplication** operation, we can ensure the second value corresponds to the current value from time \\(t-1\\). Both operations generate vectors of hidden state dimensions, then summation is performed. The left operation handles previous state transmission, while the right operation handles current input.

This mechanism applies not only to this simple example but also to general Recurrent Neural Networks (RNNs)—where one weight matrix multiplies current input, another multiplies previous hidden state. These weight matrices can track broader patterns than the current specific problem.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image27.png)

To compute gradients, let's examine the computational graph.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image28.png)

To be more explicit, we have inputs \\(x_1\\), \\(x_2\\), and a series of \\(x\\). At each timestep, we use the same weight matrix \\(W\\) for computation to obtain hidden states. **This must be considered when computing gradients.**

Let's analyze **many-to-many scenarios**—where each input has corresponding output. In this case, loss values can typically be computed for each output to measure correctness. Total loss is the sum of all timestep losses, representing loss for the entire input sequence.

During backpropagation, final loss can be decomposed into timestep losses based on specific forms. These losses can be handled independently or combined into overall loss. Gradients for each \\(W\\) can be computed separately for each timestep then accumulated.

Conceptually, although each step uses the same weight matrix, for gradient computation it can be treated as different \\(W\\). Due to weight sharing, gradients from all timesteps must ultimately be summed. **This method properly handles weight matrix sharing characteristics while maintaining computational efficiency.**

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image29.png)

In **many-to-one** scenarios, a single loss value is computed. Depending on specific problem settings, only the final hidden state might be used to compute this value. For example, in video classification tasks, since video information is distributed across the entire time dimension, utilizing hidden states from each timestep is reasonable. Then operations like average pooling or max pooling can be applied to compute output \\(y\\).  

For **one-to-many** mappings (like image caption generation), questions arise about how to integrate previous output \\(y\\). Function \\(f_w\\) needs two independent weight matrices: one for input vector \\(x\\), another for previous timestep hidden state. Various handling methods can be adopted, such as zero initialization or using previous output.  

From a macro perspective, **backpropagation** operates as described earlier. But within this conceptual framework exist practical challenges, especially GPU memory limitation issues. These constraints often become major bottlenecks in neural network training, causing problems like gradient vanishing during training processes.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image30.png)

When computing loss for each timestep in extremely long input sequences, activation values and gradients must be stored in memory and summed. However, as sequence length increases, this becomes **computationally intensive**. To solve this problem, we adopt **truncated backpropagation through time**.

This method fixes time windows and treats them as complete training contexts. Starting from initial hidden state \\(H_0\\), we compute current hidden state \\(H_1\\) based on first timestep input and previous hidden state. This process repeats for each sample, computing outputs and losses.

By treating each window as an **independent training segment**, we initialize hidden state with the last step's output from the previous window, effectively batch-processing computational graphs. This limits gradient propagation within local neighborhoods of current timesteps, alleviating memory issues with long sequences.

For final single-output scenarios, although gradients are still computed for each timestep, loss depends only on final output rather than intermediate steps. After computing gradients for final hidden state, transformation matrix \\(W_{HH}\\) is iteratively updated to minimize loss.

This method efficiently adjusts \\(W_{HH}\\) using **upstream gradients**, ensuring stable training even when processing extremely long sequences.

You're just observing how **hidden state** affects subsequent hidden states and their contribution to loss. Please refer to the final example here, which shows how modifying hidden state affects loss.  

Additionally, you can analyze how previous hidden states affect current hidden states through their changes, as shown by the **\\(W_{HH}\\) matrix**. If different \\(W\\) matrices are used at each timestep, it means you're no longer modeling the system as a recursive relationship.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image31.png)

You can conceptualize this as each potential timestep corresponding to an independent layer. However, this approach may lead to performance degradation because you're no longer modeling sequences recursively. Consider training a neural network that receives a series of inputs with independent weights. **This method is suitable for non-sequential problems**, such as classifying a set of known fixed-length items. But for variable-length sequences, this method doesn't work because it essentially trains independent neural networks for each timestep, which isn't an optimal solution.  

Now let's discuss chunk processing. At the red marked point, we can compute gradients of loss with respect to final hidden state. From there, since final hidden state depends on previous state through weight matrix \\(W\\), we can derive gradients of loss with respect to the second-to-last hidden state. This process can be iterated. **The key lies in only saving gradients of initial hidden state with respect to loss in truncated batches**, which will be used during backpropagation to compute gradients for all previous timesteps.  

The entire process focuses on how hidden states generate new hidden states through transformation—this is the only value being updated. Meanwhile we consider input effects on hidden states, analyzing both their impact on current hidden state and their influence on subsequent hidden states. **Learning process spans all batches**, computing loss for each parameter in \\(W\\). When computing gradients for previous timesteps, we retain gradients of initial hidden state. This enables us to determine how changes in initial hidden state affect loss, then derive how original hidden state and current timestep affect this variable.  

When switching to the next chunk, focus shifts to how hidden state at boundaries affects hidden states in subsequent chunks. This mechanism ensures efficient gradient propagation throughout the sequence.

The **key variable** to track is gradients of hidden state after chunk processing. This enables us to compute gradients of current hidden state, which depends on both input **X** and previous timestep state. Multiple mathematical expressions exist for this process.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image32.png)

However, you can imagine we simply apply updates to all weights and reset memory. **The only tracked element** is this gradient. Therefore, you can continue with updates.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image33.png)

You can execute a **gradient update step**, where all gradients are applied to weight parameters according to learning rate and optimizer settings, then continue computing the next batch of data. This method isn't completely precise because gradients are computed independently rather than synchronously, resulting in three independent updates rather than one integrated update. However, gradient computation for each step itself remains correct.

**Hidden state** of the first batch element remains in memory to determine how it should be updated in loss computation, while other states are discarded. Weight parameters always reside in memory, enabling gradient updates to be applied after multiplying with learning rate.

Similar processes also occur in **distributed learning**—gradients computed independently on each GPU are applied to the same set of weight parameters. This will be explained in detail in subsequent lectures on distributed learning. The key similarity is: gradients aren't tracked simultaneously in shared memory but applied sequentially to weights.

Ideally, it would be more efficient if all computations could be loaded into memory at once.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image34.png)

This concept is essentially the same, but in the current context, the way **information** is explicitly lost becomes clearer. Here, only a subset of outputs is considered at any given time, making it obvious that not all losses are incorporated into computation because loss occurs at each timestep. Therefore, in this case information is lost, while in another case it isn't.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image35.png)

A practical case that vividly illustrates this concept is **character-level language models**, which showed remarkable effectiveness a decade ago. This method reveals how contemporary language models gradually developed from RNN-based character prediction foundational ideas.

In such models, input characters typically use **one-hot encoding** representation—each character corresponds to a vector containing only a single "1" with all other positions zero, essentially serving as an index role. These encoded inputs are processed through hidden layers, with each layer's output depending on both current input and previous hidden state. The final output layer generates predictions for the next character in the sequence.

For example, if target output is "E", the model generates scores (**logits**) through softmax function, such as contrasting values of 2.2 versus 4.1, reflecting the model's confidence in each possible character. This process essentially transforms language modeling into temporal classification problems, with models performing sequence classification based on softmax output at each step.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image36.png)

During testing, the **core principle** lies in sampling character by character and feeding them back to the model. This enables the model to reference its previous output at each timestep.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image37.png)

We can build Recurrent Neural Networks (RNNs) to perform basic character-level language modeling tasks with quite excellent effectiveness. Note that we don't input **one-hot encoded vectors** into the model's input layer.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image38.png)

Instead, we use an **embedding layer**, which is essentially a large matrix of dimensions \\(D \\times D\\), where \\(D\\) represents the number of different categories in model input. This can be intuitively understood as matrix multiplication operations—selecting corresponding row vectors from embedding matrix based on input samples.  

Note there's an error in the slide: probability values should be higher. Interestingly, this oversight went unnoticed for years.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image39.png)

In this case, the target character is **E**. The model's prediction is incorrect, so we'll apply a significant penalty. This implementation is **very intuitive**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image40.png)

This model requires only **112 lines of Python code** to train for multiple tasks, demonstrating capabilities of the **pre-large language model era**, such as training Shakespearean sonnets.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image41.png)

As mentioned earlier, former course instructor Andre Karpathy explored in a **2015 blog post** the remarkable effectiveness Recurrent Neural Networks (RNNs) showed in text generation.

Why use **embedding layers**?

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image42.png)

The basic concept of **embedding layers** lies in vectors typically being more suitable as model inputs. These embedding layers can also be learned.  

During learning, we typically prefer **distributed weights**. You can initialize embedding layers with small values close to zero, such as the **Kaiming initialization** method previously discussed.  

Input data is processed row by row in vector form, rather than as single numerical input.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image43.png)

To represent this, you'd use a **one-hot vector** (with zeros in other positions). Empirically, **embedding vectors** perform better during optimization.

Only 112 lines of Python code are needed to implement this functionality. This model can be trained on Shakespearean sonnets and generate credible text. We'll look at some examples.

Notably, as training progresses, the model's output becomes increasingly coherent.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image44.png)

Initially, due to the model's lack of correct weight learning for **W**, output results appeared meaningless. As training continued, results began approaching English, with recognizable words appearing in the third stage. Further training brought significantly improved performance, foreshadowing extraordinary advances in the upcoming **AI era**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image45.png)

This model learns **stylistic elements**, such as how to incorporate names and generate reasonable text. However, as generated content increases, coherence gradually diminishes. Notably, it can also be trained on **code**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image46.png)

In this example, this model was trained on Linux kernel source code.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image47.png)

They trained a **character-level RNN** capable of generating C code. Although the compilability of generated code remains uncertain, its appearance looks quite reasonable. This method has gained tremendous attention in recent years.

Many of you, especially those in computer science or programming fields, may have noticed the proliferation of programming tools based on **language models**. These models train on existing codebases to predict the next token (a group of characters) rather than single characters.

Different models define tokens differently, but core concepts remain similar: autoregressive prediction of character sequences. This field has significantly expanded, with numerous tools currently available.

Regarding how the model processes input, it handles token sequences extracted from training data.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image48.png)

You can start with a random character as initial input, but typically, language models use **predefined start tokens** at sequence beginnings. Similar methods can also be applied to Recurrent Neural Networks (RNNs), though it's unclear what specific approach they adopted in such scenarios—perhaps they only used single characters.

This question involves how **annotation functions** operate in language models. Pure language models' advantage lies in only needing to predict the next token without relying on annotated data. Instead, they train on massive text, which is why they perform excellently—they utilize almost all available text resources on the internet.

Another question follows: if we choose **maximum probability output** at each timestep, will the model produce repetitive output? The answer is yes. For example, if probability calculations are accurate and maximum probability items are consistently selected, identical inputs will always generate identical outputs.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image49.png)

In practice, people don't use **greedy decoding** that always chooses maximum probability, but sample based on probability distributions of softmax outputs. For example, you might select an output with probability 0.84 or 0.13, rather than always picking the highest probability item. This process repeats at each sequence step.

Multiple implementation methods exist, such as **beam search**—exploring multiple candidate paths to find sequences with highest overall probability. How to effectively sample from models is currently a key research area. **Core point** is: you don't need to always choose the highest probability output.

Regarding many-to-one output questions, the answer is yes—each timestep produces output results.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image50.png)

In practice, to **optimize computational efficiency**, generating outputs that will never be used is typically avoided. However, generating one output at each timestep is also feasible.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image51.png)

Based on your question, observing whether outputs **converge** during training might be meaningful. Although this analysis is usually omitted to save computational resources, it can provide valuable insights about model behavior, such as identifying specific triggers that lead to correct predictions.

We previously discussed Recurrent Neural Networks (RNNs) and their effectiveness in character generation, comparing them with modern coding tools.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image52.png)

A **notable feature** of RNNs is the ability to examine activation values, which can help us understand what information the model is tracking.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image53.png)

In our example model, we analyzed **output activation values**, which reflect current and previous values. This is exactly what **RNN state** or units track. Additionally, you can also input a sequence to the model.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image54.png)

In models shown in these slides, hyperbolic tangent activation function (tanh activation function) is used. Activation values range between -1 and 1, with -1 visualized in red and values close to 1 displayed in blue, forming a color spectrum.  

For each input character, the figure shows activation states of neurons at each timestep through color coding. While some diagrams may appear random or difficult to interpret, others show **interesting patterns** that can be tracked.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image55.png)

For example, this is a **quote detector**. It activates when quotes begin and deactivates when quotes end.

This functionality is managed by Recurrent Neural Networks (RNN), which can track whether quotes need to be closed and determine their positions. The model learns to identify appropriate timing for inserting closing quotes.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image56.png)

Another notable feature is the line length tracking unit.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image57.png)

Values start high, then significantly decrease as the model approaches its predicted **newline character**. This provides profound perspective for analyzing output. These are single activations of a certain layer in the model for each character mapping, making the entire process highly interpretable.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image58.png)

They adopted a **conditional statement unit** capable of tracking all conditions within it—this functionality is particularly useful.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image59.png)

Additionally, tasks like detecting quotes or comments require the model to identify when to output **comment terminators**. This requires tracking these elements. Thus, you obtain an **interpretable unit**.

Finally, there's the **code depth unit**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image60.png)

As code nesting levels deepen, **activation values** gradually increase at each indentation level. This phenomenon is quite remarkable—you can directly observe these activation values without complex techniques and map them to corresponding inputs.

The interpretability of these hidden states in RNNs is astonishing, extremely similar to the manual assignment process we discussed. In fact, RNNs internally perform very similar operations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image61.png)

Now, let's discuss situations where using Recurrent Neural Networks (RNNs) would be more advantageous, and the trade-offs to consider.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image62.png)

A key advantage of **RNN** lies in its ability to handle inputs of arbitrary length. Unlike modern language models based on Transformers (which have fixed context windows), RNNs theoretically can process infinitely long sequences as long as the model continues running. It has no predefined context length limitations.

In timestep **T** computation, as long as information is preserved in hidden state, information from multiple previous timesteps can be utilized. If the model effectively captures dynamic characteristics of input sequences in its hidden state, theoretically it can even utilize information from arbitrarily distant timesteps.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image63.png)

In practice, this method may bring some challenges, which we'll explore in detail. Additionally, **model size** doesn't change with input length. For example, consider another architecture—setting independent layers for each input timestep, which would avoid the above problems.

**Key advantage** lies in consistent application of weights across all timesteps. Output computation follows the same update rules in each iteration, forming symmetric structure. Conceptually, this unified treatment of each timestep is both elegant and beneficial for implementation.

However, **significant disadvantages** also exist. Each hidden state depends on the previous state, requiring serialized computation. This dependency may cause serious processing delays because each step requires evaluating recursive relationships. Although Transformers also have similar situations during inference (each output token depends on previous tokens), RNN's serialized nature is particularly time-consuming.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image64.png)

However, during training, batch processing these operations is challenging because loss computation requires access to previous hidden states. This leads to **scalability issues**, especially more apparent on large-scale datasets. Additionally, since fixed-size hidden states must compress all historical information, retrieving information from distant timesteps becomes difficult. Therefore, as sequence length increases, information loss inevitably occurs.

Now let's explore specific successful applications of **Recurrent Neural Networks** in computer vision. Image caption generation mentioned earlier is a typical case.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image65.png)

Basic concepts involve a **start token** or character to initiate sequences, with sequences terminating when encountering **end tokens**. In this example, these tokens appear to be at word level, enabling construction of such models.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image66.png)

The most basic method involves using **CNN** or similar visual encoders to process images. This encoded representation is then input to Recurrent Neural Networks (RNNs) along with previously generated text.

Essentially, this process contains two stages. To illustrate how CNN and RNN combine: suppose there's an input test image. This image is processed by CNN, with its output serving as RNN input.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image67.png)

This model adopts a top-down progression approach, starting from the top initial layer and sequentially processing through subsequent layers. This architecture is typically trained on datasets like **ImageNet**. Although we won't use category labels, we'll adopt the second-to-last layer—this is a common strategy in **transfer learning** for obtaining robust visual representations of images. This layer's output then serves as input to hidden state, while hidden state is also influenced by **WIH parameters**. Therefore, hidden state captures not only temporal information but also integrates visual components.

This method demonstrates how **RNN** and **CNN** were historically combined: utilizing CNNs pre-trained on ImageNet and integrating their features into hidden states. Sampling processes (whether greedy sampling or other variants) generate tokens at each timestep until end tokens are sampled. Such models achieved significant success in their era, showing excellent performance in **image caption generation** tasks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image68.png)

Here, you can observe numerous instances where models can generate highly reasonable descriptions based on input images. However, this model also faces **significant challenges** in various scenarios.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image69.png)

Many such problems stem from characteristics of **image distribution** in training data. For example, a person holding an object with both hands might appear to be holding a mouse, but flat objects and upward-facing palms clearly show this is a phone.

Another example is mistaking a woman's fur clothing for a cat. Similarly, the presence of beach scenes often leads models to misjudge the existence of surfboards.

Such **hallucination phenomena** remain very common in current vision-language models—models infer objects commonly associated with scenes but actually missing. Other cases include birds perched on trees, or mistaking catching actions for throwing.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image70.png)

These problems stem from biases in datasets. Models learn during training that certain objects or actions have extremely high probability of appearing in specific scenes, even when they don't actually appear in images. This **dataset shows strong co-occurrence**—these actions or objects are highly associated with specific scenes, causing models to establish incorrect associations without decoupled learning.  

For example, in the current scene we can determine the "throwing" action doesn't exist because gloves are here and the ball is entering them, rather than being held by another hand. However, existing **training methods** only focus on generating descriptive text without providing explanations for these associations. This limitation exacerbates manifestation of co-occurrence problems.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image71.png)

In Visual Question Answering (VQA) tasks, Recurrent Neural Networks (RNNs) were widely adopted. This task mainly has two implementation approaches.

The first method uses **image caption generation models** to evaluate their question-answering capabilities. The model takes questions as input, generates text output, then computes overall probability for each answer sequence by multiplying probabilities of individual characters or tokens. This demonstrates one application paradigm of RNN-like models in question-answering fields.

A more common approach is feeding questions and multiple candidate answers as independent inputs into the model. The model then outputs probability distributions for answer options, essentially equivalent to a **multi-class classifier**. For example, the system might classify four alternative answers and assign probability values to each option.

**Visual Question Answering** as a fundamental computer vision task combining language processing has characteristics that make sequence modeling techniques show unique advantages.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image72.png)

**Visual dialogue** was once considered an independent task. Today, single models can handle almost all such tasks. In recent years, capabilities for discussing around images have made significant progress, with model performance achieving substantial improvements over the past two years.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image73.png)

Another common application of **RNN** is visual navigation tasks. Given a series of input images, the model outputs a set of navigation instructions for moving in two-dimensional plane maps and reaching target positions. This demonstrates another practical application case of such architectures in **sequence modeling**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image74.png)

One key point requiring special attention is that similar to multi-layer CNNs or fully connected layers, we can also build **multi-layer RNNs**. In fact, most RNNs I demonstrated are multi-layer architectures. **Core difference** lies in independent processing of each layer—first layer's hidden state depends only on that layer's own previous hidden state in the time dimension.

In the depth dimension, each layer only processes its own previous timestep's hidden state. Regarding **time window** processing, the first layer receives raw input \\(X\\), while subsequent layers use predecessor layer's output \\(Y\\) as input. This structure forms stacked grids, with layers interacting vertically through input-output flow, but each layer internally maintains independent horizontal state transitions.

To compute **final output** (value in upper right corner), all intermediate hidden states in the entire computational graph must be evaluated sequentially.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image75.png)

As training progresses, the entire process becomes highly complex and inefficient.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image76.png)

I'll discuss a **key variant** of RNN, this structure was proposed in the 1990s and achieved significant success before Transformers appeared: **LSTM**. Although you don't need to understand specific operational details of LSTM, I hope you recognize that their design purpose was to solve certain inherent defects of RNNs. Many modern state-based models also aim to tackle these same RNN challenges.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image77.png)

We discussed **tanh activation function** typically used as default choice. **WHH matrix** transforms previous hidden state to new hidden state and adds results with **WXH matrix** (converting current timestep input vector \\(X_T\\) to hidden state dimensions). This operation can also be expressed as diagonal arrangement of weights, where WHH and WXH matrices would be merged into a single weight matrix \\(W\\) with shorthand notation. Although merged \\(W\\) contains many zero values (because WHH doesn't interact with \\(X_T\\)), this notation can simplify mathematical expressions.

This notation has three common variants, with the most explicit version highlighting non-zero values in weight matrices. By stacking vectors then multiplying with \\(W\\), then applying tanh function, output \\(H_T\\) can be obtained and passed to next RNN layer. Output \\(Y_T\\) can be generated directly or obtained through additional layers (applying weight matrix and activation function to \\(H_T\\)).

Discussion about **multi-layer RNNs** was also raised, with such structures also applicable to current scenarios.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image78.png)

In multi-layer RNNs, **weights** are shared across layers. All hidden state updates use the same weights, while each vertically stacked layer has independent weight sets.  

When performing **backpropagation**, if loss isn't defined for each timestep *y*, loss must be computed based only on final output \\(H_T\\). This process involves multiplication with \\(W\\) and computation of \\(\\tanh\\) derivatives, both potentially challenging.  

From a mathematical perspective, **gradient** computation requires analyzing how changes in components of hidden state \\(H_{T-1}\\) affect \\(H_T\\). This requires taking derivatives of \\(\\tanh\\) (activation function) and \\(W_{hh}\\) (weight matrix converting previous hidden state to next state).  

Since \\(W_{hh}\\) needs to be repeatedly multiplied combined with \\(\\tanh\\) derivatives, such gradient computation may trigger **numerical problems**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image79.png)

When computing loss for each timestep, total loss is the sum of partial losses about reused weight matrix \\(W\\). To compute loss \\(L_T\\) corresponding to final hidden state \\(H_T\\), we need to consider all intermediate hidden states and their effects on \\(W\\) through chain rule.

Focusing on specific details (especially how current hidden state changes affect next state), we can observe that derivatives contain products of \\(\\tanh'\\) and \\(W_{hh}\\). This brings challenges: since \\(\\tanh\\) derivative's maximum value is only 1, its output is often less than 1, potentially causing gradient vanishing problems. Even without using nonlinear functions or switching to other activation functions, weight matrix \\(W_{hh}\\) itself causes new problems—depending on its singular value sizes, this matrix may stretch or compress input vectors. Larger singular values cause gradient explosion, while smaller values still trigger gradient vanishing.

Although gradient explosion can be alleviated through gradient clipping or scaling, gradient vanishing remains a major obstacle. This is exactly why basic recurrent neural networks (vanilla RNN) are rarely used for long sequences in practice. \\(\\tanh\\) function limitations combined with weight matrix characteristics jointly drove development of advanced recurrent neural network architectures like LSTM and GRU, which effectively solve the above problems.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image80.png)

This method involves construction of Long Short-Term Memory networks (LSTM). Its high-level concept is quite complex, revolving around four independent gates responsible for tracking different values.

Unlike simple hidden states, multiple precomputed values determine how to update hidden state and what information to pass through another path. Therefore, the system contains both conventional hidden state paths and an independent path designed for efficient information flow.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image81.png)

This is the **core concept**. In high-level architecture, they call it gating mechanisms for deciding which information will be written to cell unit's hidden state.  

**Input gate** determines whether to write information to cell unit, **forget gate** controls how much information to retain from previous timestep, while **output gate** decides what proportion of hidden state to actually output.  

This involves numerous design decisions, ultimately integrated into a relatively complex structural diagram. **Core idea** remains similar—we perform weighted multiplication operations, but now need to compute four independent values rather than just \\(H_t\\).

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image82.png)

We use **input gate** and **forget gate** to decide how much information to write here, output will be passed to next hidden state.  

The top structure acts like a highway, aiming to bypass activation functions (especially \\(\\tanh\\)), which previously caused **gradient vanishing problems**. Only forget gate is applied here.  

As long as all information isn't discarded at each timestep, information can propagate more effectively. This is a high-level principle explanation.  

(Note: Technical terms like "input gate/输入门", "forget gate/遗忘门", "gradient vanishing issues/梯度消失问题" are handled according to machine learning field standard translations, mathematical symbols \\(\\tanh\\) retain original format)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image83.png)

More importantly, in practice, this method has proven **extremely effective**. Although this course won't actually implement it, this architecture remains a commonly used benchmark method in many deep learning papers, so understanding its principles is valuable.

This architecture aims to solve limitations of Recurrent Neural Networks (RNNs), particularly gradient vanishing and insufficient information capture. Its core challenge lies in difficulty maintaining long-term dependencies when compressing all information into single hidden states. For this purpose, researchers specifically designed independent paths for passing long-term information through top layers.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image84.png)

Do LSTMs completely solve **gradient vanishing problems**? Although not guaranteed to completely solve, they significantly improve this situation.  

**LSTM architecture** through its special path design makes recurrent neural networks easier to retain information across multiple timesteps. This contrasts sharply with ordinary RNNs—which struggle to learn recurrent weight matrices capable of maintaining hidden state information across all timesteps.  

Ordinary RNN limitations stem from repeatedly applying identical operations yet unable to directly pass information through activation functions. Empirical evidence shows LSTMs exhibit superior performance in learning long-term dependencies.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image85.png)

People typically don't frequently train **RNNs** (Recurrent Neural Networks), preferring **LSTMs** (Long Short-Term Memory networks) when performing recurrent modeling. Although these methods are now largely unpopular, they reveal how researchers attempted to solve inherent challenges in RNN design.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image86.png)

Another interesting concept related to previous course content is directly bypassing certain activation functions or layers to stack outputs. This closely relates to **skip connections in Residual Networks (ResNets)**—within residual blocks, values are copied and directly added in subsequent stages. ResNets achieve deep architectures by stacking multiple convolutional layers, while skip connections allow direct value stacking at specific nodes.

Similar principles are also reflected in Long Short-Term Memory networks (LSTMs), improving model performance by bypassing certain layers. ResNets solve gradient problems in deep models, while LSTMs handle modeling of long timestep sequences. Their commonality lies in this bypass mechanism, though application scenarios differ—former targets network depth, latter addresses temporal length.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image87.png)

The final slide of today's lecture emphasizes the recent revival of Recurrent Neural Networks (RNNs), which is somewhat surprising. If this course had been offered one or two years earlier, I might have advocated completely abandoning RNNs.

However, they have significant advantages, especially **unlimited context length**. In contrast, **Transformer models** are limited by context length, and as researchers continuously push boundaries of model capabilities, this problem becomes increasingly prominent.

Various workarounds based on Transformer frameworks have currently been proposed to solve this limitation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image88.png)

To extend context length, the industry has adopted various techniques like **RoPE**, but this remains a significant limitation of models.

Another consideration is that for **RNN**, whether during inference or training phases, computational requirements grow linearly with sequence length. As sequence length increases, identical computational operations must be repeatedly re-executed, and unlike Transformers, they cannot simultaneously examine entire input sequences. These characteristics precisely reflect significant advantages of other methods.

Several research achievements exist in this field, including **RWKV models** (available through ArchiveLink) and **Mamba**, which prove feasibility of implementing linear-time sequence modeling. When input sequences grow, computational requirements of these methods only increase linearly rather than Transformer's quadratic growth, making them particularly suitable for long-context scenarios with computational efficiency and other key advantages.

Current research focuses on combining Transformer performance with RNN's scaling properties. Today's lecture concludes here.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec7_image89.png)

We explored various architectural designs of Recurrent Neural Networks (RNN). **Basic RNN** structures are simple but perform poorly, leading researchers to propose more complex variants for selective information flow.  

**Gradient flow** in RNNs may explode or vanish, depending on activation function and weight matrix characteristics, typically requiring gradient computation through **backpropagation through time** algorithms.  

These advanced architectures and new paradigms for sequence inference are currently hot research topics.  

This lecture concludes here. Next class we'll explain **attention mechanisms** and **Transformer models**.  

(Note: Professional terminology handling:
1. "Vanilla RNNs" translated as "基础RNN" rather than literal translation, conforming to Chinese technical literature conventions
2. "gradient flow" retains professional expression "梯度流动", with technical meaning clarified through context
3. "attention" and "transformers" adopt Chinese community standard translations
4. Passive voice converted to Chinese active sentence patterns, such as "are currently a hot research topic" handled as "是当前的研究热点领域")



