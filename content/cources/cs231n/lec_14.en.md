---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 14: Generative Models 2"
date: 2025-09-11T13:30:22+08:00
draft: true
description: ""
---

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image1.png)

Last time we discussed **generative models**, first outlining the distinction between generative and discriminative models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image2.png)

It's important to clarify that these probabilistic models belong to different types based on three key distinguishing dimensions: prediction targets, conditional basis, and **most crucially**, normalization objects.

**Discriminative models** predict labels \(y\) based on data \(x\). **Generative models** learn the probability distribution of data \(x\). **Conditional generative models** model data \(x\) under the condition of user input or labels \(y\).

The **essential difference** lies in the normalization process. Probability distributions have normalization constraint properties, which means different components need to compete for limited probability mass.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image3.png)

Last time, we reviewed the **classification system** of different categories of generative models. This field has been extensively researched for a long time, and people have developed various methods to address different problem variants.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image4.png)

We previously explored the **family tree of generative models**, focusing on **explicit density models**. These models output a quantity \(P(x)\), which for **tractable density models** is the precisely predicted \(P(x)\); while for **approximate density models**, it's an approximate version of \(P(x)\).

In tractable density models, **autoregressive models** are one category, while **Variational Autoencoders (VAEs)** are an instance of approximate density models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image5.png)

When reviewing **autoregressive models**, we decompose images (or more broadly, any data type) into a sequence. For image data, this sequence typically consists of pixel or sub-pixel values, which are treated as discrete 8-bit integers in the range 0 to 255. Subsequently, these values are arranged into a long sequence and modeled using **discrete autoregressive sequence models** (such as RNN or transformer).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image6.png)

We also discussed **Variational Autoencoders**, which are another type of explicit density model. Unlike precise density models, they compute approximations to density, specifically a lower bound. This involves jointly training two networks: an **encoder network** that maps input data \(X\) to a distribution over latent codes \(Z\); and a **decoder network** that reconstructs data \(X\) from latent codes \(Z\).

The training objective is to maximize the **Evidence Lower Bound (ELBO)** of our likelihood function. This aligns with the fundamental principle of generative modeling, where maximizing the likelihood of observed data from the true distribution is the key training objective.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image7.png)

Today, we will continue discussing **generative models** and explore another branch of this family tree: **implicit density models**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image8.png)

In **implicit density models**, we can no longer access explicit density values \(P(X)\). Instead, these models represent probability distributions implicitly. Although we cannot compute \(P(X)\) for any given data point \(X\), we can sample from the underlying distribution learned by these models.

The first such model we will explore is **Generative Adversarial Networks**, commonly abbreviated as **GAN**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image9.png)

It would be helpful to compare **GANs** with the Variational Autoencoders and autoregressive models we've discussed so far.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image10.png)

**Autoregressive models** are likelihood-based methods whose training objective is maximum likelihood estimation. We define a parameterized function \(P(X)\) (where \(X\) represents data points) and maximize it on observed data. **Variational Autoencoders** adopt a similar approach by approximating \(P(X)\) and maximizing this approximation.

However, **Generative Adversarial Networks** take a completely different path. They abandon direct modeling of \(P(X)\) and instead provide a method for sampling from the underlying distribution fitted by the model.

This framework involves finite data samples \(X_i\), which are assumed to be drawn from the true data distribution \(P_{\text{data}}\). Our goal is to sample from \(P_{\text{data}}\)—this distribution represents the universe's true distribution shaped by physical laws, historical processes, and socio-political constraints.

We attempt to model an approximate distribution as close as possible to \(P_{\text{data}}\), thereby generating new samples similar to the original data. This goal is achieved by introducing **latent variables** \(Z\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image11.png)

**Latent variables** \(Z\) are similar to what we encountered in Variational Autoencoders, where \(Z\) follows a predefined prior distribution \(P(Z)\). Typically, this is a unit Gaussian distribution or uniform distribution—unit Gaussian distributions are more common due to their simplicity and analytical tractability.

This framework involves a data generation process modeled by networks: we sample \(Z\) from \(P(Z)\), input it into a **generator network** \(G(Z)\), and thus obtain samples \(X\) from the generator distribution \(P_G\). By adjusting the generator's parameters, architecture, or training methods, we can shape \(P_G\) to approximate the true data distribution \(P_{\text{data}}\) as closely as possible. If successful, data generated by sampling \(Z\) and passing it through \(G\) will approximate samples from \(P_{\text{data}}\).

This process can be intuitively described as: sample \(Z\) from \(P(Z)\), generate images through \(G\). The generator's role is to transform samples of \(Z\) into samples close to the data distribution.

The core challenge lies in ensuring that \(P_G\) matches \(P_{\text{data}}\). **Generative Adversarial Networks (GANs)** solve this problem by introducing a second neural network—the **discriminator** \(D\). Unlike traditional methods that rely on explicit objective functions (such as Variational Autoencoders or autoregressive models), GANs delegate this task to the discriminator.

The discriminator \(D\) is responsible for classifying inputs as real or fake. The generator \(G\) attempts to fool \(D\), while \(D\) strives to accurately distinguish between real and generated data. Through this adversarial process, \(D\) continuously improves its ability to identify features of real data, ideally pushing \(P_G\) to continuously approximate \(P_{\text{data}}\).



Once the **discriminator** becomes extremely efficient, the generator must generate samples increasingly similar to real data to fool the discriminator into classifying them as real.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image12.png)

The core idea behind **Generative Adversarial Networks** is that the generator network receives feedback from the discriminator about classification accuracy. This feedback composed of **gradients** is crucial for the effective operation of the entire process.

Since both the generator and discriminator are neural networks, we can compute gradients through them. Gradients flow from the discriminator, backpropagate through the generated images back to the generator, enabling the generator to learn from the discriminator's feedback.

To formalize this idea, we need to derive specific mathematical equations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image13.png)

We will jointly train the generator \(G\) and discriminator \(D\) through this minimax game. Although this equation may seem complex at first glance, we will systematically analyze each term.

For clarity, we will color-code different components: the generator in blue and the discriminator in red. **The discriminator \(D\) is a function that receives input data samples \(X\) and outputs the probability that \(X\) is real data.** Specifically:
- \(D(X) = 0\) means the discriminator classifies \(X\) as a fake sample
- \(D(X) = 1\) means the discriminator classifies \(X\) as a real sample
In practice, the discriminator outputs probability values between these two extremes.

Now consider the scenario where the generator \(G\) is fixed. From the discriminator's perspective, there are two key terms:

1. **The first term represents the discriminator maximizing \(D(X) = 1\) for real data**, achieved by:
   - Sampling data \(X\) from the real data distribution \(P_{data}\)
   - Inputting these samples into the discriminator
   - Maximizing \(\log D(X)\), because \(\log\) is a monotonic function and using log space in probability calculations is standard practice

2. The second term involves:
   - Sampling latent variables \(Z\) from the prior distribution \(P(Z)\)
   - Generating samples \(G(Z)\)
   - Inputting these samples into the discriminator
   - Maximizing \(\log(1 - D(G(Z)))\), because the discriminator needs to classify generated samples as fake (\(D(X) = 0\))

In summary, the discriminator's goal is to:
- Maximize \(\log D(X)\) for real data
- Maximize \(\log(1 - D(G(Z)))\) for generated data

This constitutes a classification task where the discriminator needs to distinguish between real samples from the dataset and generated samples from \(G\).

From the generator's perspective...



Consider fixing the **discriminator** and examining the setup only from the generator's perspective with a fixed discriminator. In this context, the first term is irrelevant to the generator, as this term only involves the discriminator's correct classification of real data samples. Therefore, the generator only needs to focus on the right-hand term.

Intuitively, the **generator's** goal is to trick the discriminator into misclassifying its generated samples as real data. This means the generator hopes that for generated data \(D(X) = 1\). The process remains consistent: sample \(Z\) from \(P(Z)\), obtain generated samples through the generator, then get prediction probabilities through the discriminator.

Note that the generator expects \(D(X) = 1\). Unlike the discriminator trying to maximize this term, the generator's goal is to minimize this value. This dynamic relationship constitutes the **minimax game**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image14.png)

We can abstract the mathematical modeling by expressing it as a scalar function \(V(G, D)\). The **discriminator's** goal is to maximize \(V\), while the **generator** attempts to minimize it, thus forming an adversarial dynamic. The optimization process proceeds through alternating gradient descent cycles:

1. Update discriminator parameters by performing gradient ascent on \(V\) with respect to \(D\) (because the discriminator wants to maximize \(V\)).
2. Update generator parameters by performing gradient descent on \(V\) with respect to \(G\) (because the generator wants to minimize \(V\)).

This alternating optimization scheme constitutes the training process of **Generative Adversarial Networks (GANs)**. The key point is that \(V\) represents the value function of our minimax game, not a loss function in the traditional sense. The absolute value of \(V\) cannot directly reflect model performance or the alignment between the generator distribution \(P_G\) and the true data distribution.

The challenge stems from \(V\) depending simultaneously on the relative performance of both networks:
- A weak discriminator will give the generator an inflated \(V\) value
- A strong discriminator requires an equally strong generator

Different \((D, G)\) configurations may produce the same \(V\) value yet correspond to vastly different solution qualities.

Unlike traditional neural network training where loss decrease indicates improvement, GAN training lacks such clear indicators. Although we can monitor the "loss" of both generator and discriminator, these metrics are often unreliable. This fundamental difference makes GAN training and evaluation particularly challenging.



This objective is inherently unstable because it requires **maximization** and **minimization** operations on the same quantity with respect to different network parameter sets. This naturally forms a challenging optimization problem.

More problematic is the lack of clear indicators to assess progress toward good solutions. Although **Generative Adversarial Networks (GANs)** are remarkably effective, their training, hyperparameter tuning, and optimization difficulties are well-known.

A practical tip when training GANs is to carefully consider the training dynamics.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image15.png)

In the early stages of training, both the **generator** and **discriminator** are randomly initialized. At this point, the generator produces completely random noise, which is easily distinguishable from real images. Therefore, the discriminator only needs a few iterations to quickly learn to classify real and fake images with high accuracy.

Analyzing from the generator's perspective, consider the term \(D(G(z))\)—it represents the discriminator's output for generated samples, and this term is the generator's loss function. In early training, the discriminator can effectively classify generated samples as fake, causing the loss function in the generator's operating region to be nearly flat. This flatness makes it difficult for the generator to learn effectively when using the original GAN objective function.

This raises a question: How do you build a dataset for generating images of non-existent entities like unicorns? The key depends on the choice of \(P_{\text{data}}\), which defines the true data distribution that the model attempts to approximate.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image16.png)

The dataset constructed from the training set defines the probability distribution \(P_{\text{data}}\) you're trying to model. Generally, generating samples that bear no resemblance to training data is impossible—new samples can only be generated when there are somewhat similar samples in the training set. Like all generative models and neural networks, these networks exhibit some generalization ability. For example, even if you've never seen a realistic photo of a unicorn wearing a Santa hat, you might have seen realistic horse photos, Santa hat images, or unicorn paintings. **We hope the model can generalize from these related samples to create novel content.**

From the discriminator's perspective, suppose a realistic unicorn image wearing a Santa hat is generated. If the texture, lighting, shadows, and details are all flawless, there might be no obvious evidence to determine it's fake. **A highly intelligent discriminator might realize that unicorns don't exist, so realistic images are extremely unlikely, but this belongs to tricky semantic problems.** In practice, discriminators rarely reach this level of sophistication.

A common question is: Why not track two curves—one reflecting discriminator performance and another reflecting generator performance? Plotting these curves often lacks informativeness. Hundreds of research papers have attempted to improve curve interpretability by modifying GAN objective functions (such as avoiding logarithmic operations, introducing Wasserstein metrics, and other innovations). **Despite years of effort and countless papers, no definitive solution has emerged.** Many people still use the original formula, and even with deep analysis, the curves remain difficult to interpret.

Another question is whether the discriminator's early training behavior matters. The answer is no, because due to the non-stationary distribution properties, this problem is fundamentally different from standard classification tasks.



When training image classifiers on datasets like **ImageNet** or **CIFAR**, the dataset is fixed, and the model's goal is to effectively classify this static data. However, in **GAN training**, the dataset that the discriminator attempts to fit evolves continuously throughout the training process. Initially generated images may be of poor quality, making the task relatively simple, but as the generator improves, the discriminator's target distribution also changes. This leads to a **non-stationary problem** with complex learning dynamics.

Regarding the **local minima** problem, hundreds of papers have explored various heuristic methods, but no universally effective solution has been found. The training process must remain end-to-end, with discriminator gradients backpropagating to the generator. Specifically, gradients flow through the right-hand term, meaning generator parameters are only updated through discriminator feedback.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image17.png)

Unless there are **regularization terms**, the generator lacks any auxiliary terms to guide its behavior beyond gradients propagated through the discriminator. This leads to instability issues in the learning process. Throughout the training process, the \(p_{\text{data}}\) distribution remains fixed.

The **key issue** is that the generator receives weak gradients during training. A practical solution is to minimize \(-\log D(G(z))\) rather than maximize \(\log(1 - D(G(z)))\). These two forms are roughly equivalent, but the improved method provides stronger gradients for the generator in early training. This adjustment is **crucial** when training GANs from scratch using logarithmic objectives.

Therefore, the generator and discriminator compute different objective functions (\(v\)), which are not identical.

Another question to consider is: Why might this objective function be effective?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image18.png)

I previously had slides detailing this proof process, but due to time constraints, I'll provide an overview and recommend additional resources for further study.

The **key insight** is that this objective is effective because the **optimal discriminator** can be derived analytically. This involves a nested optimization problem: the inner problem maximizes the discriminator \(D\), while the outer problem minimizes the generator \(G\). Through mathematical analysis, the inner maximization problem can be solved, thus expressing the optimal discriminator for a given generator \(G\).

However, although the optimal discriminator can be expressed in analytical form, it cannot be computed in practice because it depends on the **true data distribution** \(P_{\text{data}}\). If we could directly access \(P_{\text{data}}\), the problem would already be solved. Therefore, the optimal discriminator is always a theoretical construct.

When the inner objective is maximized by deriving the optimal discriminator, it can be proven that the outer objective is minimized if and only if the generator's distribution \(P_G(x)\) matches \(P_{\text{data}}(x)\). This **theoretical optimal solution** uniquely occurs when \(P_G = P_{\text{data}}\), providing a solid theoretical foundation for **Generative Adversarial Networks (GANs)**.

But this conclusion has important limitations. It assumes both generator and discriminator have infinite capacity, which is clearly unrealistic, as neural networks have fixed architectures and limited capacity. Furthermore, the theory doesn't guarantee that gradient-based optimization will converge to this optimal solution with finite data.

In practice, GANs typically parameterize the generator \(G\) and discriminator \(D\) as neural networks (traditionally using **Convolutional Neural Networks (CNNs)**). Although the theoretical framework provides some basis, actual training remains challenging and lacks strong guarantees.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image19.png)

Before ViTs (Vision Transformers) became popular, GANs (Generative Adversarial Networks) had already fallen out of favor, but they could likely also work synergistically with ViTs. The first GAN to produce **substantial results** was DCGAN, which used a five-layer convolutional architecture and generated impressive samples at the time.

I mention DCGAN because its first author **Alec Radford** achieved what would be considered a career highlight for most researchers. However, for Radford, DCGAN was just a stepping stone—his subsequent project was GPT. After DCGAN, he successively developed GPT-1 and GPT-2, and completed other groundbreaking work at OpenAI.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image20.png)

Among researchers working on **generative modeling** for images, there's an interesting phenomenon: after turning to generative modeling of discrete text data, they made significant contributions in that field.

Another **GAN** paper I'll highlight is **StyleGAN**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image21.png)

I won't delve into the specific details of this architecture, but I recommend studying it as an exemplar of **GAN best practices**. Although it adopts more complex structures, it achieved remarkable results. A significant advantage of **GANs** is the ability to learn smooth representations in latent space.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image22.png)

If we have two latent vectors **\(Z_0\)** and **\(Z_1\)** and interpolate between them—that is, sample \(Z_0\) and \(Z_1\) from a Gaussian distribution, then interpolate along the curve connecting them—we can use the generator to generate samples at each point on the curve. This process yields **smooth interpolation results** in latent space, which is a remarkable characteristic of Generative Adversarial Networks (GANs).

Examples from the StyleGAN3 paper demonstrate **latent space interpolation**: by adjusting latent variables \(Z\) and inputting them into the generator, generated samples exhibit smooth transitions. The final images show animals gradually morphing into each other, indicating that the model has encoded meaningful structure into the latent space.

The mathematical formulation of **Generative Adversarial Networks** is relatively simple, which is one of their advantages.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image23.png)

When properly tuned (as shown by StyleGAN3), **Generative Adversarial Networks (GANs)** can generate high-quality, high-resolution images. However, they have significant drawbacks. GAN training is inherently unstable, lacking clear loss curves for diagnosis. Common problems include **mode collapse**, numerical instability (NaN or INF values), and anomalous behavior of generators and discriminators. Generators may produce random noise, and the absence of reliable loss metrics makes troubleshooting more difficult. Despite careful tuning of normalization and sampling parameters, scaling GANs to large models and datasets remains challenging.

From 2016 to 2020-2021, GANs dominated the generative modeling field, with thousands of papers exploring various architectures, loss functions, and application scenarios. During this period, they remained the standard framework for generative tasks.

A key question arises: Should we expect smooth latent representations? The answer is not necessarily. The generator might simply mechanically memorize a fixed number of training samples, completely ignoring latent variables \(Z\). For example, it might memorize 10 training samples rather than learning meaningful latent space mappings.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image24.png)

Regardless of the input \(Z\), the generator might only output one of 10 training samples without generating new content. In this case, if the generator outputs samples identical to real data, the discriminator might be fooled. At this point, the generator would concentrate probability mass around limited samples, forming a **density distribution similar to Dirac delta functions** (with zero probability in other regions). While this is an effective solution, it's a bad convergence case, demonstrating GANs' ability to converge to counterintuitive results.

A core characteristic of GANs is the **unidirectional mapping** from latent space \(Z\) to data space \(X\). Unlike VAEs, GANs have no explicit inverse mapping from \(X\) to \(Z\). Although reverse derivation can be attempted through numerical or analytical methods, there's no forced association between \(X\) and \(Z\). The discriminator forces alignment between generated and real data distributions through implicit supervision. Although some GAN variants explore bidirectional mappings, these methods haven't become mainstream.

Compared to VAEs, GANs sacrifice interpretable latent vectors but gain superior sample quality. VAEs often generate blurry outputs, while GANs can produce **sharp, high-quality samples** at the cost of increased system tuning complexity. The inference stage only requires using the generator: sample \(Z\) from the prior distribution and transform to data space, a highly efficient process. Before new methods emerged, GANs dominated the generative modeling field for about five to six years.



The models that replaced them belong to a unique category called **diffusion models**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image25.png)

Now, I must first mention a few caveats. The literature on **diffusion models** is quite complex, and these papers typically unfold several pages of mathematical derivations before explaining core concepts.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image26.png)

Mathematically, there are three distinctly different formalization methods that can derive **diffusion models**, with significant differences in notation, terminology, and mathematical structure. This subfield is particularly complex.

It must be emphasized that I won't comprehensively cover all variants of diffusion models and their complete mathematical formalizations. Instead, my goal is to provide an intuitive overview of diffusion models and establish geometric understanding of the currently most popular **rectified flow models**.

Although one could spend many class hours discussing the mathematical details of these variants, the limited time of this course doesn't allow us to conduct such in-depth discussions.

With this premise stated, the core intuition behind diffusion models is actually relatively simple and straightforward.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image27.png)

For all generative models, our goal is sampling. Similar to **Generative Adversarial Networks (GANs)**, we aim to transform samples from noise distribution \(Z\) into data distribution \(P_X\). However, diffusion models take a very different approach. GANs directly map \(Z\) to \(X\) by learning a deterministic mapping (through the generator), while **diffusion models** adopt a more implicit and indirect approach.

The first constraint of diffusion models is that the noise distribution \(Z\) must always match the shape of the data. For example, if the data is an image of size \(H \times W \times 3\), then the noise distribution must also be \(H \times W \times 3\).

Next, we consider versions of data with gradually added noise.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image28.png)

Here we have a data sample, such as this cat image. The parameter **\(T\)** represents the noise level, ranging from 0 to 1. When \(T = 0\), the sample is clean with no noise. When \(T = 0.3\), a small amount of noise **\(Z\)** is mixed into the data **\(X\)**. When \(T = 1\), the sample consists entirely of noise, directly sampled from the noise distribution. The parameter \(T\) achieves a smooth transition between the data distribution and noise distribution (usually Gaussian—a simple and easily understood distribution).

We train a **neural network** to perform progressive denoising. The network receives images with intermediate noise and learns to remove small amounts of noise. The training goal is for the network to input a noisy image and output a slightly cleaner version.

In the inference stage, we follow this iterative process:
1. Sample a noise sample from the noise distribution \(P_Z\).
2. Repeatedly apply the neural network to gradually remove noise.

Initially, the network processes completely noisy samples and must "imagine" the most basic structure. With each iteration, the sample's noise gradually decreases. If configured correctly, this process will eventually generate a completely noise-free sample.

This is the core idea of **diffusion models**.

Regarding the number of steps: it can be a fixed hyperparameter or vary depending on implementation. Details such as how noise interference is specifically applied are intentionally kept abstract in this discussion.



What does removing a small amount of noise mean? How is this step iteratively applied during inference?

As mentioned earlier, **diffusion models** have multiple formalization expressions and variants, with vastly different interpretations of these concepts in different scenarios. This slide only provides a macro-level overview of the diffusion process, while specific diffusion model implementations will make different practical choices based on precise definitions of these terms.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image29.png)

Is this high-level overview of diffusion models clear? Now let's transition from general diffusion models to a specific category—**rectified flow models**. Although some might debate whether rectified flow belongs to the diffusion model category or constitutes an independent method, this distinction is not the focus of our discussion here.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image30.png)

**Rectified Flow** can be viewed as a variant of diffusion models. Its core idea can be intuitively understood as: we have noise distribution \(p_{\text{noise}}\) and data distribution \(p_{\text{data}}\). For ease of understanding, we visualize geometrically in two-dimensional space, but in practice these distributions often exist in high-dimensional spaces (such as images and Gaussian distributions). It's important to note that low-dimensional intuitions often fail in high-dimensional scenarios, so caution is needed.

In the **Rectified Flow** framework, we set two distributions: \(p_{\text{noise}}\) is a simple distribution that's easy to sample from, and \(p_{\text{data}}\) is a complex distribution representing real data (such as images). During training, we sample \(z\) from \(p_{\text{noise}}\), sample \(x\) from \(p_{\text{data}}\), and simultaneously sample noise level \(t\) uniformly from the interval \([0,1]\) (where \(t=0\) represents no noise, \(t=1\) represents complete noise).

We then define vector \(v\) pointing from \(x\) to \(z\), which characterizes the velocity of the flow field. The noisy sample \(x_t\) is the linear interpolation of \(x\) and \(z\): \(x_t = (1-t)x + tz\).

The training objective is very straightforward: predict the velocity vector \(v\) through neural network \(f_\theta\) based on noisy sample \(x_t\) and noise level \(t\). Although research papers often describe this process as complex and obscure, the underlying code implementation is exceptionally simple.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image31.png)

Frustratingly, many presentations don't emphasize this point. **The training loop of Rectified Flow is actually very simple**: in each iteration, first sample \(Z\) from a unit Gaussian distribution of the same dimension as \(X\), then uniformly select noise level \(T\) from interval \([0,1]\), then compute the linear interpolation \(X_T\) of \(X\) and \(Z\). The model takes \(X_T\) and \(T\) as inputs, and the loss function is simply the mean squared error between the true value \(V\) and the model's predicted value—this constitutes the complete training objective of rectified flow models.

In contrast, **GAN training is full of uncertainty**. Including rectified flow, diffusion models have loss functions that provide clear indicators for training. Loss decrease means model improvement, which is refreshing for researchers who have experienced GAN training challenges. The smooth exponential decay of loss curves in diffusion models contrasts sharply with the ambiguous charts common in GAN training, providing a sense of security.

The inference stage is simpler for GANs: sample \(Z\) and obtain data samples through the generator. But **diffusion models and rectified flow models introduce additional complexity**—the model's output \(X_T\) and \(V\) lack intuitive interpretability. During inference, a fixed number of steps \(T\) must first be selected, which determines the resolution of generated samples, creating a trade-off between computational cost and sample quality.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image32.png)

For **rectified flow models**, \(T=50\) is typically used as a good initial value, occasionally \(T=30\) is sufficient. This process first directly samples \(X\) from the noise distribution, ensuring it's pure noise.

Then iterate backwards from \(T=1\) to \(T=0\), achieving a linear transition from full noise state (\(T=1\)) to clean samples (\(T=0\)). In each iteration, we input current \(X_T\) (initially full noise) and noise level \(T\) into the network, obtaining predicted \(V_T\).

In **Rectified Flow**, \(V\) represents the vector pointing from data samples to noise samples. Geometrically, we take a small step along this predicted \(V\) vector. Since rectified flow models don't directly map to clean samples, this step initiates the denoising trajectory.

By updating \(X\) along the \(V\) direction, we obtain a partially denoised data version \(X_2\). This process cycles: pass \(X_2\) back to the model to get new \(V\), take another step along \(V\) to get \(X_1\), until we finally obtain clean sample \(X_0\).

Although this inference process is more complex than **GANs**, it has advantages of stable training, higher sample quality, and scalability to large datasets and models. Its implementation is very intuitive:
1. Sample random noise
2. Iterate backwards from \(T=1\) to \(T=0\)
3. Predict \(V\) based on \(X_T\) and \(T\) in each step
4. Update \(X\) along \(V\) direction
5. Loop until convergence

**Diffusion models**, despite their initially high understanding threshold, are both practical and efficient.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image33.png)

With just a few lines of code on a single slide, you can implement the complete training and sampling process of **rectified flow models**, which is quite elegant.

This method works effectively—if you use this code with appropriate model architectures, it can generate reasonable results in most cases.

This solves the **core challenge** in generative modeling: how to establish connections between sampleable prior distributions \(Z\) and target data distributions \(X\) we wish to generate. Different generative modeling paradigms handle this connection in vastly different ways.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image34.png)

In **Variational Autoencoders (VAE)**, the model first predicts a latent variable \(Z\), then generates \(X\), and attempts to constrain \(Z\) to known sampling distributions, although this method has limitations. The generator learns the mapping relationship from \(Z\) to \(X\) through a feedforward process, guided by the **distribution matching objective** provided by the discriminator.

**Diffusion models** integrate these curves and rely on various mathematical formalization methods to prove why such objectives can effectively match probability distributions. The **core challenge** lies in the lack of predefined pairing relationships between samples \(Z\) in the prior distribution and samples \(X\) in the data distribution. If this pairing relationship were known and we could sample from the prior distribution, the problem would be solved. **Generative modeling methods**, including diffusion models, aim to circumvent this problem by learning associations between \(Z\) and \(X\) during training (without explicit pairing).

Although **unconditional generative modeling** is usually impractical, **conditional generative modeling** is much more practical. **Rectified Flow** can easily adapt to conditional generation. For example, consider a data distribution containing categorical sub-parts (such as squares and triangles): where \(p_{\text{data}}\) represents the overall distribution, while \(p_{\text{data}}(X|Y=\text{square})\) and \(p_{\text{data}}(X|Y=\text{triangle})\) represent sub-distributions. This framework illustrates the core idea of conditional generative modeling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image35.png)

For **Rectified Flow**, this adjustment is very intuitive. Your dataset now consists of pairs like (x, y), and the model incorporates y as additional auxiliary input. During sampling, when the model predicts velocity vector v, it receives this additional input y.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image36.png)

The **key difference** is that now \(y\) represents a user-controllable conditional signal. This can be a text prompt, input image, or any user input expected during inference, making these models both **controllable** and practical.

An important question arises: Can we adjust the model's attention to conditional signals? When these models are not optimally trained, they typically don't strictly follow conditional signals as expected. To solve this problem, a technique called **Classifier-Free Guidance (CFG)** fine-tunes the diffusion training loop.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image37.png)

We will train a **conditional diffusion model** that accepts inputs \(x_t\) and \(y\). In each training iteration, we flip a coin to decide (with 50% probability, this value can be adjusted as a hyperparameter, but 50% is commonly used in practice) whether to delete the conditional information by setting it to null or zero.

This method forces the model to learn two different types of **velocity vectors**. When conditional information \(y\) is empty, the model behaves as an unconditional generative model, predicting velocity vector \(v\) pointing to data distribution \(P_{data}(x)\); when \(y\) is provided, the model predicts conditional velocity vector pointing to conditional data distribution \(P_{data}(x|y)\).

The **core idea** is to linearly combine these two vectors, biasing the result toward the conditional distribution. Specifically, we introduce scalar hyperparameter \(w\) and compute:
\(v_{CFG} = (1 + w) \cdot v_y - w \cdot v_{null}\)
This vector \(v_{CFG}\) emphasizes the conditional distribution more than the unconditional distribution. During the sampling stage, we use \(v_{CFG}\) rather than the original model prediction.

When \(w = 0\), we recover the standard conditional model; increasing \(w\) enhances the influence of conditional signals. This method is simple to implement and requires minimal changes to inference code.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image38.png)

Now, you evaluate the model twice in each iteration to obtain **\(v_y\)** and **\(v_0\)**, then take their linear combination and proceed accordingly. This method is called **"classifier-free"** for a fairly simple reason.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image39.png)

An earlier paper proposed **classifier guidance** techniques, but subsequent work removed the classifier. Although the two papers were only nine months apart, and the second was published four years ago, the term **"Classifier-Free Guidance" (CFG)** is still widely used.

This technique is crucial in practice for diffusion models to generate high-quality outputs, although it doubles sampling costs by requiring two model evaluations per iteration. The topic of optimal prediction will not be discussed as it's less relevant.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image40.png)

This is quite interesting, but we're running out of time. Occasionally, one thing we need to do is adjust this **T distribution**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image41.png)

We particularly observe that in the original rectified flow model, we sample \(T\) according to a uniform distribution. This method applies equal weight to all noise levels. **Intuitively, when in a completely noisy state, the problem becomes trivial—the model's optimal prediction only needs to point to the mean of the data distribution.** Similarly, in zero noise state, the optimal prediction points to the mean of the noise distribution. These extreme cases are relatively easy for the model to handle because it only needs to learn the mean of the corresponding distribution.

However, intermediate noise levels present significantly greater challenges. When sampling \(X_T\) in intermediate ranges, there may be multiple \((X, Z)\) pairs that generate the same \(X_T\). At this point, the network needs to solve an expectation problem, determining the optimal direction after integrating over all \((X, Z)\) pairs that pass through \(X_T\). **Intuitively, these intermediate points are harder for the network to resolve.**

Using uniform sampling of \(T\) from 0 to 1 means giving equal importance to all noise levels, which contradicts the above intuition. In practice, alternative noise scheduling schemes are often adopted. **One popular method is logit normal sampling, which is similar to Gaussian distribution, giving minimal weight near 0 and 1 while concentrating more weight in intermediate regions.** Another scheme is to use offset noise scheduling, an asymmetric scheme that biases toward one end.

These adjustments become crucial when handling high-resolution data. **High-resolution images have strong pixel correlations, while low-resolution images have weaker correlations.** Therefore, different noise levels may be needed to effectively destroy information depending on data correlation strength. This inability to directly adapt to different resolutions presents major challenges for diffusion models—although their theoretical framework is elegant, without fine-tuning parameters, it's difficult to achieve optimal performance on high-resolution data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image42.png)

This leads to the topic of **diffusion models**, which are currently the most mainstream form of generative models. To be precise, the most widely applied variant is **Latent Diffusion Models**, which have become ubiquitous in practice.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image43.png)

This process involves multi-stage operations. First, train **encoder networks** and **decoder networks**: the encoder maps images to the latent space marked in purple, achieving \(D\)-fold spatial downsampling and converting three channels to \(C\) channels. Typical configurations achieve 8-fold spatial compression and expand to 16 channels. Such encoder-decoder architectures typically use CNNs with attention mechanisms, but recent research has also begun exploring applications of **Vision Transformers (ViT)**.

Subsequently, **diffusion models** are trained on the latent space generated by the encoder (rather than original pixel space): sample images → encode to latent representations → add noise → train diffusion models for denoising. The key point is that the encoder is frozen during this stage to prevent gradient backpropagation, and diffusion models are only trained on the latent space learned by the encoder.

After training is complete in the inference stage, randomly sample latent representations and iteratively denoise through diffusion models to obtain clean latent samples, finally generating images through the decoder. This scheme represents the mainstream implementation approach of modern diffusion models.

A natural question arises: How to train encoder-decoders? In practice, **Variational Autoencoders (VAE)** are commonly used, but their blurry outputs constrain diffusion model image quality. To address this, enhancement components can be introduced after the decoder to improve VAE output clarity.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image44.png)

This system includes the following components: an **encoder** (converting images to latent space), a **decoder** (reconstructing images from latent space), a **discriminator network** (distinguishing real images from generated images), and a **diffusion model** running in latent space for sample generation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image45.png)

To understand the process of modern generative modeling, the key lies in exploring the various forms of **diffusion models** and other generative methods. Current state-of-the-art generative modeling techniques integrate multiple methods: **Variational Autoencoders (VAEs)**, **Generative Adversarial Networks (GANs)**, and diffusion models.

You might be curious about the neural network architectures behind them. Fortunately, this complex field has gradually become clear in recent years.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image46.png)

It turns out that relatively simple **Transformer architectures** can be effectively applied to diffusion models, which are typically called **Diffusion Transformers (DiTs)**. These models basically use standard Transformer modules directly without major modifications. Their main architectural challenge lies in how to inject conditional information into the model.

Diffusion models require three inputs: noisy images, time step *t*, and conditional signals (such as text). There are several mechanisms to integrate these conditional signals into Transformer modules:

First, intermediate activations in diffusion modules can be modulated by predicting scaling and offset parameters. This method is commonly used to inject time step information. Another way is that since Transformers themselves model sequences, all inputs (including time steps and text) can be concatenated into sequences, which can be achieved through **cross-attention** or joint attention mechanisms.

In modern DiTs, time steps are typically injected through scaling-offset mechanisms, while text or other conditional signals are integrated through sequence concatenation, commonly using cross-attention or joint attention mechanisms.

This framework can be adapted to various tasks, such as the currently popular **text-to-image application** field.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image47.png)

Here, we input a text prompt: *"A professional documentary-style photo showing a monkey and tiger shaking hands in front of the Eiffel Tower. The monkey wears a hat made of bananas, while the tiger stands upright on two legs wearing a suit."* This is a real case demonstrating the **exceptional generative capabilities** of current models.

This process first inputs the text prompt into a pre-trained text encoder (typically using **T5** or **CLIP**) to generate text embedding vectors, with the text encoder usually kept frozen at this stage. These embedding vectors are input together with noisy latent variables into a **Diffusion Transformer**, which simultaneously incorporates diffusion time step information. Through iterative operations, the transformer outputs clean latent variables, which are finally processed by a **VAE decoder** to generate images.

Taking **Flux1Dev**, a powerful open-source model as an example: it uses T5 and CLIP encoders with 8-fold downsampling, training a transformer with 12 billion parameters. This model adds additional downsampling layers on top of VAE, forming a sequence length of 1024 image tokens.

Another important application is **text-to-video generation** technology, generating corresponding video frame sequences through text prompts.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image48.png)

The overall process remains largely unchanged. Users input text through pre-trained text encoders, obtaining noisy latent representations. The **key difference** is that these latent representations now have an additional dimension to represent time. In addition to the original two spatial dimensions (height H and width W), the latent space also introduces a temporal dimension, finally outputting clean latent representations. The decoder (usually a spatiotemporal autoencoder) performs downsampling in both spatial and temporal dimensions, then upsamples latent representations to pixels to generate final videos.

This example comes from videos generated by Meta's *Movie Gen* paper published last year. The **main challenge** of video generation models lies in high computational costs, stemming from sequence length issues. To generate high-frame-rate, high-resolution videos, massive amounts of tokens need to be processed. Current state-of-the-art text-to-image diffusion models (such as Transformers) handle image token sequence lengths of 1,024, while text-to-video diffusion models must handle longer sequences—up to 76,000 video tokens—to generate high-resolution multi-frame videos. This surge in sequence length is the main source of computational costs for video diffusion models.

The past year has witnessed the rise of video diffusion models, with new technological breakthroughs emerging almost weekly.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image49.png)

These models include a mix of **open-source models** and **pure industrial models**—the former publish detailed technical reports explaining architectures and training processes, while the latter don't disclose technical details at all but allow users to generate samples. Although I won't analyze each model individually, it's clear that research activity in this field has been exceptionally active over the past 18 months.

A **key turning point** occurred in March 2024: OpenAI published a milestone blog about **Sora**. Although not the first video diffusion model, Sora achieved unprecedented results by scaling diffusion transformers with modern architectures (possibly combining rectified flow techniques). This breakthrough became a watershed moment in video diffusion model development, prompting other tech giants to accelerate related R&D.

The field is progressing rapidly, with new **state-of-the-art video diffusion models** emerging almost weekly. Just this morning at 11 AM, Google just released **Veo 3**, currently the most powerful generative video model, with core features including:
- Generating high-quality videos through text prompts
- Joint modeling of audio and video
- Stunning samples demonstrating precise text-to-video capabilities

But diffusion models still have significant drawbacks: sampling speed during generation remains a bottleneck.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image50.png)

We discussed that **sampling** is an iterative process, and these models can be extremely large, having hundreds of billions of parameters and processing sequences of tens of thousands or even longer. This makes the inference process quite slow, because even using rectified flow techniques, dozens of model iterations are needed to complete.

To solve this problem, there's a class of algorithms called **distillation**. Although I won't delve into details here, I'll list some references for you to understand these techniques. Distillation algorithms can improve diffusion models to obtain good samples with fewer inference steps (even potentially achieving single-step sampling), although this usually involves some compromise in sample quality. The **key challenge** lies in how to maintain generation quality while reducing inference steps.

This remains an active research area, with the latest papers from 2024 to 2025 exploring how to improve distillation techniques to make diffusion models more efficient during inference.

Additionally, as mentioned earlier, the diffusion process involves quite esoteric complex mathematical concepts.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image51.png)

We intentionally avoided rigorous mathematical proofs and instead provided intuitive geometric understanding of **rectified flow models**. Although we won't delve into formalization details, let's briefly restate the objective function of rectified flow.

**Training stage:**
1. Sample \(x\) from data distribution, sample \(z\) from noise distribution
2. Sample \(t\) from selected distribution \(p_t\) (uniform/log-normal/offset distribution)
3. Compute linear interpolation \(x_t\) of \(x\) and \(z\)

In this framework:
- **True velocity field** \(v_{gt} = z - x\)
- Network predicts \(v\) based on \(x_t\) and \(t\)
- Minimize L2 loss between \(v_{gt}\) and predicted \(v\)

The core differences between different **diffusion model variants** lie in:
1. Distribution form of \(p_t\) (noise distribution usually remains Gaussian)
2. How \(x_t\) is computed (usually weighted linear combination of \(x\) and \(z\) with respect to \(t\))
3. True target values (always linear combinations of \(x\) and \(z\), weight functions may depend on \(t\))

After the model receives \(x_t\) and \(t\), it predicts \(y\), usually computing L2 loss. The core differences between variants lie in the choice of function forms for the above key points—rectified flow adopts the minimalist form where \(c_t\) and \(d_t\) are constants, while **variance-preserving models** use other function constructions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image52.png)

In this method, we merge these two parameters into a single scalar hyperparameter \(\sigma(t)\). By constructing these linear combinations in specific ways, we ensure that when \(x\) and \(z\) are independent and have unit variance, the output also maintains unit variance. **This actually simplifies two functional hyperparameters into a single noise schedule**, but careful selection is still needed.

Additionally, beyond variance-preserving methods, there are **variance-exploding methods**, where we set \(a_t = 1\), \(b_t = \sigma(t)\). The choice of \(\sigma(t)\) remains a key decision, and various objective functions are commonly used in practice.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image53.png)

In **diffusion models**, the network's task might be to predict original data, added noise, or linear combinations of both. For **Rectified Flow**, the prediction focus is on the velocity vector from data to noise. However, these objectives vary across different variants of diffusion models.

The **key challenge** lies in the choice of hyperparameters, which are usually functions of time *t*. This complexity requires mathematical guidance rather than intuitive selection. There are three main mathematical frameworks that provide theoretical foundations for diffusion model training, though this article won't delve into their specific implementations.

First, diffusion processes can be conceptualized as **latent variable models**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image54.png)

We have clean sample data **\(x_0\)**, but each clean sample corresponds to a series of corrupted or noisy samples associated with it. These corrupted samples are unobservable and unknown, yet we must infer them.

This structure is similar to **latent variable models**, sharing similarities with Variational Autoencoders (VAE). In VAEs, we have latent variables **\(z\)** and observed variables **\(x\)**, where \(z\) is unobserved and needs to be learned. By maximizing the variational lower bound of data likelihood, similar mathematical methods can be applied here, thus obtaining a latent variable model interpretation of the diffusion process.

Another interpretation is that diffusion processes can be viewed as modeling **score functions**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image55.png)

Given a distribution \(p_{\text{data}}(x)\), the **score function** of this distribution is defined as the gradient of log probability with respect to \(x\), i.e., \(\nabla_x \log p_{\text{data}}(x)\). Intuitively, the score function represents a vector field pointing toward high probability density regions. For any point in data space, this vector indicates the direction of increasing data density.

Another interpretation of **diffusion models** is that they learn the score function of data distributions. More precisely, they learn a series of score functions corresponding to data distributions with different noise levels applied. This framework treats diffusion as estimating a set of score functions for versions of true data distributions with gradually added noise, where noise increases systematically in known ways. Although the mathematical form differs, this approach produces algorithms structurally similar to traditional diffusion methods.

The latest research perspective treats diffusion as solving **stochastic differential equations**, providing another theoretical foundation for these models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image56.png)

I must admit that I haven't fully understood this myself, so please don't ask too many questions. **The core concept is constructing a differential equation that describes an infinitesimal method for transforming samples from noise distribution into samples from data distribution.** During inference, neural networks essentially learn numerical integrators for this **Stochastic Differential Equation (SDE)**. This approach provides a novel perspective because it opens up a unique class of methods for sampling during the inference stage.

From this perspective, the gradient descent method observed in rectified flow is equivalent to applying a forward Euler integrator to the SDE. This interpretation allows us to explore more complex integrators to better handle score functions. These topics are quite esoteric, with detailed papers discussing them. Sander Dieleman's blog post "Multiple Perspectives on Diffusion Models" is particularly insightful, proposing eight different perspectives on diffusion models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image57.png)

This is an excellent article, and I strongly recommend all his works on **diffusion models**. His blog posts are indeed insightful.

**Autoregressive models** are equally applicable—we can achieve the same approach by integrating autoregressive models on Kero decoders.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image58.png)

In summary, besides **diffusion models**, another mainstream method in current generative modeling is training **autoregressive models** on **discrete latent variables** extracted by discrete Variational Autoencoders.

This theoretical foundation supports our explanation of the four major **generative models**: **Generative Adversarial Networks**, **Variational Autoencoders**, autoregressive models, and diffusion models, which together constitute core components of modern machine learning workflows.

In conclusion, this lesson quickly organized two different generative model systems.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec14_image59.png)

We delved into **Generative Adversarial Networks** and **diffusion models**, observing how they are integrated into modern technological processes through examples like **Latent Diffusion Models**. This provides an appropriate conclusion to the generative modeling chapter—all the models we studied ultimately converge to form these contemporary frameworks.

Next, we will turn to exploration in the field of vision and language.
