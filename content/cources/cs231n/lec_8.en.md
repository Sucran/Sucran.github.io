---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 8: Attention Mechanisms and Transformer Models"
date: 2025-09-10T17:45:37+08:00
draft: false
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image1.png)

Welcome back to Lecture 8. Today we will explore **Attention Mechanisms and Transformer Models**, which promises to be a fascinating topic.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image2.png)

To review, in the previous lecture we discussed Recurrent Neural Networks (RNNs)—a new type of architecture specifically designed for processing sequential data. Compared to convolutional networks, RNNs enable us to solve a broader range of problems.

Traditionally, we mainly focused on one-to-one tasks (like image classification), where a single input corresponds to a single output. But through sequential data processing, we can now solve diverse problems, such as **one-to-many tasks** (like image caption generation, producing a sequence of words from images) and **many-to-one tasks** (like classifying sequences of video frames).

These advanced architectures not only bring structural innovations but also expand the range of solvable problems beyond traditional feedforward networks. Today, we will introduce two new topics building upon this foundation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image3.png)

The first topic is **attention mechanisms**, a completely new fundamental building block for neural networks that operates on sets of vectors.

Next, we will explore **Transformers**, a unique neural network architecture centered around self-attention. As a preview, Transformers have become the mainstream architecture for almost all contemporary deep learning problems.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image4.png)

The most widely applied domains today—whether image classification, image generation, text generation, text classification, or audio processing—primarily rely on **cutting-edge neural networks** trained and deployed by large companies on massive datasets. These models are almost all built on **Transformer architectures**. It's exciting to guide you through the latest developments in these frontier architectures.  

Although Transformers have now become the dominant architecture across domains, their development journey was relatively long. Interestingly, when Transformers first emerged, people didn't immediately realize this was a revolutionary moment. While the Transformer architecture itself was novel, its core concepts—such as **self-attention mechanisms** and attention mechanisms—had been explored in related fields for years. These ideas originally stemmed from research on **Recurrent Neural Networks**.  

To understand the design rationale behind Transformers, we'll start from their historical development trajectory and explore along the evolution of these concepts.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image5.png)

To introduce **Transformers**, we first review the Recurrent Neural Network (RNN) concepts discussed in the previous lecture. Taking a typical example—the sequence-to-sequence problem of machine translation: input is a sequence of English words, and the expected output is a corresponding sequence in another language (like Italian).  

The challenge of this task lies in the absence of direct correspondence between vocabularies of the two languages. Vocabulary count and order may differ significantly, making sequential processing architectures like RNNs ideal choices. As early as 2014 and earlier, RNNs were used for sequence-to-sequence problems, with sequential processing research spanning decades.  

Standard sequence-to-sequence architectures adopt an **encoder-decoder framework**. The encoder is an RNN that processes input sequences, recursively applying functions at each timestep: receiving current input \\(x_t\\) and previous hidden state \\(h_{t-1}\\), outputting next hidden state \\(h_t\\), thereby achieving processing of variable-length sequences.  

In this example, the encoder processes English sentences word by word (like "we see the sky"). Its goal is to summarize the entire input sequence into a single vector—the **context vector**—which captures input semantic content for target language translation. RNN-based architectures have multiple methods for generating context vectors.

These details aren't particularly interesting. You can view the **context vector** as the final hidden state of the encoder recurrent neural network. Due to the recurrent structure of these networks, the last hidden state effectively encapsulates information from the entire input sequence.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image6.png)

The last hidden state can be viewed as a summary or encoding of all information in the input sequence. **This single vector encapsulates the entire input sequence** for subsequent processing. In this example, the goal is to translate the input sequence into an output sequence in another language.  

To achieve this goal, we adopt a second **Recurrent Neural Network**—the decoder. This decoder typically has the same architecture as the encoder but may have different weight matrices and learning parameters. The decoder GU is another recurrent neural network with learnable weights U while maintaining the same basic structure.  

At each timestep, the recurrent neural network unit receives three inputs:  
- \\(Y_{t-1}\\): token from the previous timestep in the output sequence;  
- \\(S_{t-1}\\): hidden state from the previous timestep in the output sequence;  
- \\(C\\): **context vector** summarizing the entire input sequence.  

The output sequence will be generated step by step as described in the previous lecture. For example, the input sequence might correspond to Italian translation "we see the sky" (specific pronunciation omitted here).  

But this method has a potential problem: there exists a **communication bottleneck** between input and output sequences. The only interaction pathway between them is through the fixed-length context vector \\(C\\), whose dimension is determined when configuring the recurrent neural network. While this might suffice for short sequences (like processing "we see the sky" with 1024-dimensional vectors), when input consists of paragraphs, books, or large corpora, compressing continuously growing input sequences into a single fixed-length vector becomes increasingly infeasible.

The root cause lies in **bottleneck limitations** imposed on networks through fixed-length vectors. To solve this problem, we improved the structure of recurrent neural networks.  

The **core idea** is to avoid forcing bottlenecks between input and output sequences. Instead, when models process output sequences, they should have the ability to reference the entire input sequence. This method eliminates bottleneck effects, enabling models to handle longer sequences and improve performance.  

This **fundamental insight** gave birth to attention mechanisms and Transformer architectures, which were initially proposed precisely to solve bottleneck problems in recurrent neural networks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image7.png)

To realize this intuitive concept and enable our recurrent neural networks to reference input sequences at each timestep, we first adopt the same neural network structure as the encoder (this structure remains unchanged) and initialize decoder state \\(S_0\\) for the output sequence.

After establishing decoder hidden state, we compute **alignment scores** by comparing \\(S_0\\) with each token in the input sequence. For an input sequence containing four tokens, we compute four scalar alignment scores, each representing similarity between \\(S_0\\) and corresponding input tokens.

A direct method for computing these scores is using a **linear layer** (denoted as \\(F_{ATT}\\)). This layer concatenates decoder hidden state \\(S\\) with encoder hidden state \\(H\\), generates scalar values through linear transformation, and integrates this operation into computational graphs for joint learning through gradient descent.

Generated scalar alignment scores are unbounded real values. To endow them with structural properties, we apply **softmax function** to convert these scores into probability distributions. Softmax ensures each value lies between 0 and 1 with sum equal to 1, forming discrete probability distributions over alignment scores. This method enables models to focus on relevant parts of input sequences during decoding.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image8.png)

At this stage, after processing alignment scores through **softmax function**, we have effectively predicted probability distributions over input tokens based on decoder's hidden state.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image9.png)

To summarize information in the encoder, we utilize **attention scores** (denoted as \\(A_{11}, A_{12}, A_{13}, A_{14}\\))—values between 0 and 1 that sum to 1.  

We generate a **context vector** \\(C_1\\) through weighted linear combination of encoder hidden states \\(H_1, H_2, H_3, H_4\\) using these attention scores. This vector encapsulates encoder sequence information modulated by attention weights.  

Therefore, \\(C_1\\) represents a linear combination of input encoder states \\(H_1\\) to \\(H_4\\).

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image10.png)

This structure remains largely consistent with the case without attention mechanisms. We still retain the **context vector**, which will be concatenated with the first token \\(Y_0\\) of the output sequence, then input to recurrent units to obtain the next hidden state and first output token of decoder recurrent neural network (**RNN**). The decoder RNN architecture remains unchanged, with the only improvement being computing context vectors through attention-based linear combination mechanisms.  

The core idea is: context vectors will dynamically focus on different parts of input sequences based on decoder's current focus. For example, when generating Italian words corresponding to "we see", the network should prioritize relevant input tokens ("we" and "see") while ignoring irrelevant content like "the sky". This mechanism enables networks to selectively focus on key parts of input sequences during prediction.  

The key point is that this process is completely **differentiable**. Networks train through gradient descent on end-to-end differentiable computational graphs, autonomously learning how to attend to input sequences without explicit supervision. Loss functions still use cross-entropy softmax objective functions, with networks learning alignment relationships between input and output sequences while predicting output tokens, thereby avoiding unrealistic manual alignment supervision requirements.  

Regarding initialization, decoder weights typically use random initialization and optimization through gradient descent, consistent with standard neural network training conventions. **"Initialization"** here refers to both initial values of decoder RNN hidden states and initial settings of their weight parameters.

Initialization has a second concept: setting initial hidden state when networks begin processing output sequences. This requires rules or mechanisms to determine decoder's initial hidden state. Multiple implementation approaches exist: **one common method** initializes decoder with encoder's last hidden state; or maps encoder's final state to decoder's first state through a learnable linear transformation; or directly initializes decoder's first hidden state as zero vector. As long as networks are trained to adapt to such inputs, the above methods all work.  

Regarding **negation logic and XOR operations**, this might pose challenges as they constitute complex problems. Solving this problem may require massive data and computational resources for networks to learn to deconstruct these relationships.  

In the decoder, recurrent units receive three inputs: previous decoder hidden state, current context vector, and current token in output sequence. Based on these inputs, it generates the next hidden state, then used to predict subsequent output tokens. This architecture remains consistent with the case without attention mechanisms.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image11.png)

There seems to be an implicit connection from \\(S_0\\) to \\(S_1\\) not shown in the diagram. **An additional arrow from \\(S_0\\) pointing to \\(S_1\\) should have been drawn**, for which I apologize for this oversight.

This network can autonomously determine which parts of input sequences are relevant to current tasks. **This mechanism is considered reasonable** because in language tasks, input and output words typically have correspondence relationships. The network's design enables it to identify and focus on relevant parts of input when generating each output segment.

However, this process isn't directly supervised; networks aren't explicitly guided on how to use attention scores. **Its underlying logic indicates** that under existing mechanisms, this is a reasonable strategy networks might adopt.

This is only one step in the output generation process, which will be executed iteratively.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image12.png)

We repeat this complete process for each timestep of decoder RNN. **The core problem we solve is the bottleneck caused by passing information through a single vector**. Instead, we compute new context vectors at each decoder timestep, enabling it to re-examine the complete input sequence.

Given the first decoder hidden state **S1**, we use the same linear projection (FATT) as the first timestep to compute similarity scores between S1 and all encoder hidden states. These alignment scores are normalized through Softmax, generating new attention distributions over input sequences for the second decoder step. Then based on this distribution, we compute weighted linear combinations of encoder hidden states, producing new context vector **C2**, thereby providing different summaries of input sequences.

This process iterates continuously: each time we obtain a new context vector, we advance the decoder RNN one timestep. The computation at this point includes the previously missing connection. Using the updated context vector, next output token, and decoder's S1 state, we compute the next decoder state **S2** and generate subsequent output tokens.

In this example, the network generates word "ill" which might correspond to a specific input word. We expect relevant input words to receive higher attention weights while other positions have lower weights—though this is entirely learned autonomously through gradient descent without explicit supervision. This attention mechanism operates autonomously at each decoder RNN timestep.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image13.png)

This mechanism effectively solves our problem by eliminating the bottleneck of compressing input sequences into single fixed-length vectors. Instead, at each decoder timestep, networks re-examine the entire input sequence, dynamically re-summarizing it to generate new **context vectors**, and utilize these vectors to generate outputs.

This innovative method is called **"attention mechanism"** because networks selectively focus on different parts of input sequences at each output step. Attention weights are autonomously learned by networks based on training data and tasks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image14.png)

Another notable feature of **attention mechanisms** is their ability to provide interpretability for network decision processes.

We never explicitly specified alignment relationships between input and output sequences, but by observing predicted attention weights during task execution, we can gain insights into which parts of input networks focus on. This provides an **effective method** for understanding neural network processing behavior.

Specifically, by analyzing attention weights generated when processing given sequences, we can understand network focus when executing tasks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image15.png)

We can visualize this content in a two-dimensional grid. Here's an example of **English to French translation**, with input sequence displayed at the top.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image16.png)

**The European Economic Area Agreement** was signed in August 1992. The output sequence is displayed row by row as French. Through **attention mechanisms**, networks predict probability distributions over entire input sequences for each word generated in output sequences. This is visualized in the first row of the matrix, showing distribution over English sentences when predicting the first French word "le". At this point, most probability weights are assigned to English word "the", with remaining parts negligible.

When predicting the second word in output sequences, networks recompute new distributions over input, represented by the second row of the matrix. In this case, significant probability weights are assigned to "agreement", with remaining weights minimal. This indicates networks effectively learn alignment relationships between input and output words during translation.

Several interesting phenomena emerge from this process.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image17.png)

Diagonal structures in attention matrices indicate **one-to-one correspondence** between words in input and output sequences. Specifically, the first four words of input sequences align with the first four words of output sequences, confirmed by diagonal patterns in attention matrices. Similarly, words at sequence ends also show this correspondence, such as "August 1992" matching final words in French sequences.

In the middle of sequences, we observe that when input phrase "European Economic Area" appears, French output presents similar words in slightly different word order. This naturally raises a question: **How does the model infer grammar?** This embodies the mystery of deep learning. Networks are never explicitly taught grammar rules but trained on massive input-output pairs. Given English input sequences and corresponding French outputs, models learn to adjust weights through **gradient descent** to produce correct translations. Despite no explicit grammatical guidance, models can implicitly capture language patterns, confirming our intuition that certain words should have correspondences across languages.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image18.png)

We introduced a **mechanism** aimed at assisting in solving this problem. This network autonomously decides how to utilize this mechanism to complete target tasks through end-to-end training. Notably, this method has proven effective.  

In this case, networks independently inferred grammatical-level features. For example, **attention matrices** show non-diagonal patterns indicating networks recognize word order differences between English and French. Additionally, a small 2x2 grid in matrices suggests non-one-to-one correspondence between English and French words—possibly involving two-word combinations that aren't fully decoupled in both languages.  

Networks derive these patterns through extensive training on large-scale **datasets** and massive computational resources. This marks the first application of attention mechanisms in machine learning.  

(Note: Technical terminology handling:  
1. "mechanism" retains professional context translation as "机制"  
2. "attention matrix" adopts industry standard translation "注意力矩阵"  
3. "datasets" translated as "数据集" conforming to computer field conventions  
4. Long complex sentences restructured according to Chinese expression habits, such as front-loading "through end-to-end training")

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image19.png)

This concept originated from challenges in machine translation. A **groundbreaking 2015 paper** "Neural Machine Translation by Jointly Learning to Align and Translate" recently won second place for the "Test of Time Award" at ICLR 2025, demonstrating its lasting impact.

This mechanism was initially developed to solve limitations of Recurrent Neural Networks (RNNs), but its underlying principles reveal a more fundamental and powerful computational approach. This enables **attention concepts** to be extracted from RNN frameworks, establishing them as independent and efficient computational primitives in neural networks.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image20.png)

We can remove **Recurrent Neural Network** components, retaining only attention mechanisms as core fundamental units in architectures. This is exactly our current research direction. The current goal is to generalize attention concepts from recurrent neural networks, developing them into operators capable of independent operation.

Let's analyze how **attention mechanisms** work. This mechanism essentially operates on a set of query vectors. For easier understanding, perhaps explaining components in reverse order would be more intuitive. First are **data vectors**, which carry information we need to summarize, corresponding to encoder RNN hidden states. Input sequences are compressed into vector sequences, encapsulating data relevant to current problems.

When using this data, we generate a series of outputs. Each output is associated with a **query vector** used to generate specific outputs. In this scenario, query vectors are decoder RNN hidden states. For each query vector, the mechanism re-examines data vectors and summarizes their information into **context vectors**.

The output of attention operators is exactly these context vectors, which are then fed into RNNs. In short, this operator receives query vectors, processes data vectors, and generates output vectors by customizing data summarization for each query.

Due to complexity of terminology systems and concept transformations, this might seem obscure. Let's restate: data vectors are encoder hidden states, while query vectors represent targets for which we need to generate outputs. For each query vector, attention mechanisms synthesize data vectors to produce output vectors, which will serve as context for subsequent RNN steps.

In visual presentation, query vectors are highlighted in green. For each query vector, the mechanism aggregates data vectors and generates new output vectors, ultimately integrated into networks.

This is a complex task because our goal is to separate **attention components** from RNN architectures. We'll re-examine this process, focusing only on attention operators themselves.

First, we'll consider a single **query vector**, which corresponds to some state in our RNN.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image21.png)

We also have a set of **data vectors** corresponding to encoder hidden states in RNNs. The computation process first requires computing similarity between **query vectors** and all data vectors. This step is identical to what we previously discussed, just expressed differently. We use **FATT function** to compute similarity scores between each data vector and single query vector.

After obtaining these similarities, we apply **softmax function** to derive attention weights. These weights form a dynamically computed distribution over data vectors for given query vectors. Then, output vectors are generated through linear combinations of data vectors weighted by attention scores. This output vector represents the result of attention layers.

In broader contexts of RNNs, attention layer outputs serve as inputs for decoder RNN next steps. But since we're departing from RNN frameworks, we'll focus only on attention mechanisms themselves.

Core operations of attention layers include: repeatedly obtaining query vectors, computing similarity scores, deriving attention weights, and generating output vectors. The source of each new query vector isn't important to attention operators. This process generates new output vectors through continuous summarization of data vectors, thereby encapsulating basic operational principles of attention mechanisms.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image22.png)

Now, let's generalize this concept to create more powerful computational primitives. In principle, function **FATT** can be any operation receiving two vectors and outputting scalars. But in practice, we'll simplify it in subsequent slides.

The first generalization direction is making similarity functions simpler. Although theoretically any function mapping two vectors to similarity scores is feasible, we'll adopt the simplest choice: **dot product**. This choice ensures both simplicity and generalization capability.

Notably, dot product as similarity measure has proven sufficiently effective in this scenario. However, interaction between dot product and **softmax function** triggers a subtle problem—specifically how this behavior changes with vector dimension variations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image23.png)

This example vividly illustrates how vector dimension scaling affects **softmax computation**. Consider a constant vector with all elements equal to 1 and dimension 10, compared with another vector of dimension 100. For higher-dimensional vectors, softmax internal summation results are larger, causing probability scores to be compressed more smoothly.  

As discussed in the previous lecture, this situation may cause **gradient vanishing**, hindering learning processes.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image24.png)

To prevent **gradient vanishing** and ensure architectures scale effectively across different vector dimensions, we adjust computation by scaling dot products by the square root of vector dimensions. This improvement enhances gradient flow in softmax functions, with effects becoming more significant as network dimensions increase.  

Larger vectors provide stronger computational capabilities, making **scalability** a key consideration in architecture design. **Scaled dot product** is crucial for maintaining gradient stability.  

Initially, we require query vectors and data vectors to share the same dimension \\(d_q\\) for dot product operations. But our first generalization introduces scaled dot product similarity as similarity measure. The next step will extend this scheme to handle multiple query vectors.  

Dimension relationships of components are: query vector dimension \\(d_q\\), data vector dimension \\(n_x \\times d_q\\), maintaining dot product operation compatibility. Subsequent generalizations will support processing multiple query vectors.  

(Note: Mathematical symbols \\(d_q\\)/\\(n_x\\) etc. retain professional notation untranslated, technical terms like "softmax", "scaled dot product" adopt computer field standard translations)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image25.png)

Perhaps we don't want to process only single query vectors each time, but hope to process entire query vector sets simultaneously. This situation is particularly common in Recurrent Neural Networks (RNNs) because such networks often generate multiple query vectors. The advantage of attention mechanisms lies not only in processing query vectors one by one but also in parallel processing entire query vector sets, executing identical operations synchronously on all vectors.

At this point, we generalize architectures to include \\(n_q\\) query vectors. Where \\(\\mathbf{Q}\\) is an \\(n_q \\times d_q\\) dimensional matrix, each \\(n_q\\) query vector has \\(d_q\\) dimensions. Data vectors are represented as \\(n_x \\times d_q\\) dimensional matrix \\(\\mathbf{X}\\).

Since we now need to compute **alignment scores** (specifically scaled dot products) between all input data vectors and query vector pairs, the computation process changes slightly. Each similarity score is a dot product operation.

The most efficient natural way to compute dot products between two vector sets is through **matrix multiplication**. Notably, in matrix multiplication, each element of output matrices corresponds to inner products between column vectors of one matrix and row vectors of another matrix.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image26.png)

Each item in matrix multiplication output represents **dot product** between row and column vectors. By computing matrix multiplication between query vectors \\(q\\) and data vectors \\(x\\) (with appropriate transpose operations to align rows and columns), we can efficiently compute similarities between all data vectors and query vectors in a single operation.

Next, we compute **attention weights**. For each query vector, we generate probability distributions over data vectors. Similarity scores form a matrix, and applying softmax function along one axis yields these distributions. This is consistent with previous computation logic but now executed in parallel for multiple query vectors.

To compute output vectors, we perform weighted combinations of data vectors using softmax values as weights. **Matrix multiplication** essentially performs this operation: it executes weighted linear combinations of columns in one matrix using values from another matrix. Through subscript derivation, we can verify that matrix multiplication between attention matrix \\(A\\) and data vectors \\(X\\) (with appropriate transpose) can simultaneously generate all required linear combinations.

This method efficiently implements generalized computation for multiple query vectors through only a few matrix multiplications. Notably, in this formula, data vectors \\(X\\) appear in two different positions.

Data vectors \\(X\\) are initially used to compute similarities with query vectors through inner products, essentially measuring alignment between data vectors and various query vectors. Subsequently, these data vectors are reused to compute output vectors—linear combinations of data vectors weighted by attention weights.  

However, reusing the same set of data vectors in two different scenarios may seem unconventional. For this purpose, we attempt to separate these two uses, enabling networks to autonomously decide how to utilize data vectors in each scenario. This introduces **key vectors and query vectors** mechanisms.  

Specific implementation is as follows: each data vector is projected into two vectors—**key vectors** and **value vectors**. Key vectors are compared with query vectors to compute alignment scores, while value vectors are used to compute linear combinations of this layer's outputs.  

To implement this mechanism, we introduce two learnable weight matrices: **key matrix** and **value matrix**. They linearly project data vectors into key vectors and value vectors respectively.  

Given \\(n\\) data vectors of dimension \\(d_x\\), key matrix projects vectors from \\(d_x\\) to \\(d_q\\) (same dimension as query vectors) through operation \\(k = XW_k\\); value matrix projects vectors from \\(d_x\\) to \\(d_v\\) (value vector dimension, which can differ from \\(d_q\\)) through \\(v = XW_v\\).  

This separation's intuitive analogy is search engine scenarios. For example, when you query Google or ChatGPT *"What is the best school in the world?"*, the query statement itself differs from the expected answer (value). Queries interact with backend key vectors, while returned data (values) are independent—thereby achieving decoupling between queries and response requirements.

Queries must match various strings on the internet. The ideal output for this query is **"Stanford"**, which differs from input queries. This explains the core idea behind separating keys, queries, and values.  

**Queries** represent what we're looking for, while **keys** correspond to backend data records stored in data vectors. When querying, our goal is to match a subset of data vectors. **Values** are specific information we retrieve from data vectors.  

This separation divides data vector uses into different roles of keys and values. We can further understand this concept through visualization.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image27.png)

Now, we finally bid farewell to Recurrent Neural Networks (RNNs) and study **attention mechanisms** as independent operators. Let's review this operation process step by step.

Inputs include **query vectors** and **data vectors**. First, each data vector is projected into keys and values, then each key is compared with each query for similarity scoring.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image28.png)

This scalar matrix represents similarity between each key and each query. After obtaining this **similarity matrix**, we compute probability distributions over data vectors for each query by applying Softmax function to each row of alignment score matrices.

Next, we reweight value vectors using attention scores obtained from Softmax. Specifically, each column should represent a probability distribution because we need to generate distributions over keys for each query. This means we need to apply Softmax to columns for correct alignment.

For the first query, we predict distributions over all keys through this computation, then take linear combinations of value vectors using these **attention weights** as coefficients, thereby generating the first output vector \\(Y_1\\). The same process applies to the second query: compare it with all keys, compute distributions of alignment scores, and generate the second output vector through linear combinations of value vectors.

At this point, this **attention operator** operates independently of recurrent neural networks. The key question is how to divide data vectors into keys and values. Its elegance lies in not needing to pre-specify this division method, but providing independent projection mechanisms for keys and values, endowing neural networks with autonomous data segmentation capabilities without specifying specific methods.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image29.png)

**Key matrices** and **value matrices** are learnable parameters of models, optimized together with other components through gradient descent. Just as models autonomously learn to align English and French sentences through gradient descent, they also decide how to project inputs into keys and values in ways beneficial for solving target problems.  

Conceptually, keys and values serve as filters. Although data vectors may contain massive information, current tasks may require filtering this data in specific ways—matching queries with relevant subsets and retrieving only key information. Therefore, these matrices effectively filter data vectors through dual pathways.  

This **attention operator** operates as an independent neural network layer, different from recurrent architectures. It processes two inputs: query vectors and data vectors. This layer contains two sets of learnable parameters—key matrices and value matrices—and transforms input sequences into output sequences. Therefore, it's a self-contained neural network component that can be integrated into broader architectures.  

When processing two different input sources, this implementation is called **cross-attention**. This mechanism enables queries to summarize information from data vectors that may differ or have different sizes. Another more common variant is **self-attention**—the same set of vectors serves as both queries and data sources.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image30.png)

In this scenario, we only need to process a single input vector sequence without distinguishing data vectors from query vectors. **Self-attention layers** receive these input vectors and generate the same number of output vectors. Their mechanism is similar to previously discussed attention mechanisms, but with one key adjustment: instead of separately projecting data vectors into keys and queries, each input vector is simultaneously projected into three components—**query vectors**, **key vectors**, and **value vectors**.  

Related formulas are slightly adjusted, but overall computation logic remains unchanged. We derive queries, keys, and values from input vectors through independent linear projections. The computation process is identical to before, with the only difference being that keys, queries, and values all originate from the same set of input vectors.  

Regarding dimensions \\(d_{\\text{in}}\\) and \\(d_{\\text{out}}\\), they are architectural **hyperparameters** of this layer, similar to hyperparameters in learnable linear layers. Although theoretically they can differ, in practice they are almost always consistent. This notation provides generality, though we needn't delve too deeply here.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image31.png)

A key detail is that we separately project input vectors into queries, keys, and values through three learnable weight matrices—Query matrix, Key matrix, and Value matrix.  

In practice, computing these projections simultaneously through single large matrix multiplication is more efficient than executing three small matrix operations. Common optimization schemes concatenate these three weight matrices along dimensions, generating keys, queries, and values for all input vectors through single operations.  

This method is particularly important in **decoder-only attention architectures**, with certain Transformer implementations adopting this design.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image32.png)

This corresponds to decoder usage in our initial **RNN** example at the beginning of the course. However, this mechanism represents the most commonly used form of **attention** today—specifically, decoder-only attention.  

We're now gradually departing from RNN frameworks because this specific attention variant doesn't fit RNN architectures we previously studied.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image33.png)

At the beginning of the course, we introduced an architecture initially designed for **RNNs**, specifically for sequence-to-sequence tasks like machine translation. But now we've generalized it into independent operators. In this generalization, **self-attention mechanisms** can no longer be used for RNN decoders but have become fundamental building blocks widely applied in other scenarios.  

The question arises: what's the difference between self-attention and **cross-attention**? What are their respective applicable scenarios? The answer depends on data characteristics. Certain scenarios require comparing two different types of data—for example, in machine translation, input and output sentences naturally constitute two sets of elements requiring alignment; in image caption generation tasks, input image regions need comparison with generated text tokens.  

But other problems involve only single data types. Taking image classification as an example, input only contains images themselves, naturally requiring no cross-attention mechanisms across data types.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image34.png)

When processing images, we compare different parts of images with themselves, which is exactly where **self-attention layers** come into play. This layer can be applied to different types of problems, but the **key advantage** lies in reusing the same computational mechanisms and basic operations across different application scenarios, which has significant advantages.

Regarding **attention mechanisms**, an interesting phenomenon worth exploring is the impact of input sequence permutation.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image35.png)

We have a set of input vectors. If we shuffle them and process them in different orders, several interesting phenomena occur. **Keys, queries, and values remain unchanged** because they're computed through linear projections of inputs, just presented in the same shuffled order as inputs.  

Since similarity scores are computed through dot products, they also remain the same, only reordered according to input permutations. Softmax operations are insensitive to input order, so they process the same but shuffled vectors. Therefore, each column of our attention weight matrices remains unchanged, only undergoing permutation changes.  

Linear combinations also apply, meaning output \\(y\\) will be identical to original output, just shuffled in order. This demonstrates a property called **permutation equivariance**. We observed this through convolution in previous lectures. Now, we see another equivariance in self-attention layers: shuffling inputs yields identical outputs, just correspondingly rearranged.  

This indicates **self-attention inherently doesn't depend on input order**. Changing input order produces identical outputs, only in different order. This layer's computation is independent of input sequence order. Therefore, we can conceptualize self-attention as not operating on ordered vector sequences but on vector sets that happen to be arranged as matrices.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image36.png)

However, we conceptualize it as operating on unordered vector sets because output results are independent of vector arrangement order in input matrices. This represents a **unique neural network primitive** whose essence is processing vector sets rather than sequences.  

However, this may bring challenges. In certain scenarios, conveying input entry order information to neural networks is beneficial. As a direct solution, we typically add **positional embeddings** to each input vector. This embedding serves as metadata to identify each vector's position (e.g., index 1, index 2, etc.). Multiple implementation methods exist.  

A key question arises: will training processes yield identical results? Here we're not discussing training processes themselves but computational behavior of this layer under fixed weight matrices. If inputs are shuffled, outputs will correspondingly mirror this shuffling. Therefore, although specific output vectors are independent of input order, their sequences will reflect input arrangement methods.  

**Self-attention mechanisms** provide more technical means. For example, in standard self-attention layers, all input elements can attend to each other. But certain problems may require constrained attention patterns, where specific inputs can only attend to designated other inputs. This is achieved through **masked self-attention**.  

After computing alignment scores \\(E\\), we overwrite selected scores as \\(-\\infty\\) to block attention. In subsequent softmax operations, these \\(-\\infty\\) values produce zero weights, ensuring corresponding output \\(y\\) won't depend on value vectors at that index. This mechanism precisely controls input interactions during computation.  

This method is particularly important for **language modeling** because it generalizes operators to degrees that don't require recurrent neural networks (RNNs).

We can apply this to the same problems previously solved by Recurrent Neural Networks (RNNs). Now, we can process word sequences (e.g., "attention is very") and generate outputs like "is very cool". Here we're executing the same language modeling task discussed with RNNs in previous lectures, but now natively implementable through **self-attention modules**.

In this scenario, we ensure the first output depends only on the first word, while the second output ("very") depends only on the first two words. This prevents networks from peeking ahead at sequence content for unfair advantages, which is why **masking mechanisms** are adopted.

Additionally, we sometimes use **multi-head self-attention mechanisms**—running multiple independent self-attention copies in parallel, specifically *h* independent instances.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image37.png)

The motivation for this method lies in **enhancing computational capabilities**, increasing floating-point operations (FLOPS), and expanding parameter scales—these are **key goals** in deep learning fields because scale expansion typically brings performance improvements. This method can make network layers more powerful through scaling.

This process routes input \\(x\\) to \\(h\\) independent self-attention layers, each generating its own output \\(y\\). These outputs are stacked and fused through linear projections in the final stage. This architecture is called **multi-head self-attention mechanisms**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image38.png)

This is the standard format commonly used in practice. Modern **self-attention mechanism** implementations almost all adopt multi-head versions. From a computational perspective, this can be efficiently executed through matrix multiplication without using iterative loops.

Through **batch matrix operations** with appropriate implementation, all *h* self-attention instances can be processed in parallel.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image39.png)

In fact, the entire **self-attention operator**, though seemingly complex, essentially consists of only four matrix multiplications.  

First, we project input vectors into queries, keys, and values through matrix multiplication. Then we compute similarities between each query and all keys, which is another large-scale **batch matrix multiplication**, particularly significant in multi-head attention scenarios.  

The third step performs **value weighting** operations, achieved through linear combinations of value vectors weighted by softmax entries, also requiring one batch matrix multiplication. Finally, output projections mix information from different heads in self-attention mechanisms.  

Despite involving numerous equations and vector operations, self-attention operators ultimately boil down to these four large batch matrix multiplications. This structure has significant advantages because matrix multiplication, as a highly **scalable** powerful primitive, can improve efficiency and performance through optimization, distribution, and parallelization.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image40.png)

The question is that \\(X_1\\), \\(X_2\\), and \\(X_3\\) are essentially identical, but we'll use independent copies of self-attention layers with randomly initialized weights. These weights differ during initialization, enabling each attention head to process inputs in slightly different ways. **This method enhances this layer's expressive capability.** The only difference between attention heads lies in weights—architecture and computation processes are completely identical.

At this point, we've explored three different sequential processing methods in this course.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image41.png)

**Recurrent Neural Networks** process one-dimensional ordered sequences. Although powerful, their sequential nature makes them inherently non-parallelizable because each hidden state depends on the previous state. This limitation hinders their scalability.

**Convolutional operations** act on multi-dimensional grids, mixing information locally. Since convolution kernel positions can be computed independently, they excel in parallelization. However, to build large receptive fields, either oversized convolution kernels or stacking numerous layers is needed, introducing sequential processing requirements for handling large-scale data.

**Self-attention mechanisms** act on vector sets, naturally suitable for processing long sequences without creating bottlenecks. Unlike recurrent networks, they don't require multi-layer structures to achieve global interactions—each vector can attend to all other vectors within a single layer. This method is highly parallelizable, involving only four matrix multiplications, very suitable for GPU acceleration and distributed computing.

The main disadvantage of self-attention is high computational cost, with computation and memory consumption growing quadratically with sequence length.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image42.png)

When your \\(n\\) value reaches levels of 100,000, millions, or even tens of millions, \\(n^2\\) complexity computational costs become extremely expensive. However, this problem can be alleviated through GPU resource scaling.

Therefore, attention mechanisms have become efficient fundamental building blocks for processing diverse data structures. You might wonder which approach to adopt in practical applications.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image43.png)

**Attention is all you need.** Among these three methods, significant progress can be achieved using attention mechanisms alone. The key question is: what are the advantages of this approach?

**Main advantages** stem from historical challenges in improving processor speeds. We've encountered fundamental hardware limitations making it increasingly difficult to improve single processor performance. However, by utilizing multiple processors, we can easily achieve scaling.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image44.png)

Over the past two decades, we've improved computational capabilities by developing **algorithms** that don't rely on single fast processors. Instead, we design algorithms capable of utilizing multiple processors working collaboratively—whether 10, 100, 1000, or even millions of processors. Imagine filling the entire Stanford campus with processors working together on large-scale computational tasks. **Parallelizable algorithms** enable us to achieve scaling without waiting for single processor speed improvements (which may never happen).  

Regarding trade-offs with \\(n^2\\) complexity, this seems counterintuitive. In computer science, higher-order terms are typically viewed as disadvantages, but in **neural networks**, increasing computation may bring benefits. Stronger computational power enables networks to process information more thoroughly, potentially achieving better results. Although this makes processes more expensive, performance improvements justify this trade-off.  

**Transformer architectures** centered on self-attention mechanisms perfectly exemplify this principle.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image45.png)

Our input consists of a set of vectors \\(x\\). These vectors will be processed through **self-attention mechanisms**, a powerful mechanism enabling interactions between vectors.

Subsequently, we'll incorporate this self-attention mechanism into residual connections following the same principles as residual networks discussed in previous lectures.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image46.png)

Next, we'll process **residual connection** outputs through layer normalization. As observed in Residual Networks (ResNets) and Convolutional Neural Networks (CNNs), introducing normalization operations in architectures effectively improves training stability.

**Self-attention mechanisms** perform pairwise comparisons of all vectors, which is a powerful and practical fundamental operation. But we also need networks to have independent vector processing capabilities. For this purpose, Transformer architectures introduce a second fundamental module: Multi-Layer Perceptrons (MLPs), also called Feed-Forward Networks (FFNs). This two-layer neural network performs independent operations on each vector.

Self-attention and MLPs work synergistically—the former enables interactive comparisons between vectors, while the latter performs independent computations on each vector. MLPs are also wrapped in residual connection and layer normalization structures. This entire structure is encapsulated as a neural network module.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image47.png)

This is our **Transformer module**, and a Transformer consists of a series of such Transformer modules.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image48.png)

These models have grown significantly in scale over time. Since their emergence in 2017, **Transformer** core architectures have remained largely unchanged.  

The original Transformer model proposed by Vaswani et al. in *"Attention Is All You Need"* contained approximately 12 modules and 200 million parameters. Today, we see Transformer models with hundreds of modules and trillions of parameters.  

This demonstrates **exceptional scalability** of Transformer architectures—over the past eight years, their computational requirements, model scales, and parameter counts have grown across multiple orders of magnitude.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image49.png)

They can be applied to language modeling, as we previously discussed.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image50.png)

They can also be applied to image processing. This process is very intuitive: given an input image, we divide it into **several patches**, map each patch to a **vector**, then pass these vectors as inputs to transformer models. Subsequently, transformers generate corresponding outputs for each input patch.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image51.png)

To perform **classification tasks**, transformer output vectors can be pooled and predicted through linear layers for class scores.

This **transformer architecture** has universality, applicable to languages, images, and other domains. Although there have been some minor adjustments since transformers emerged, due to time constraints, we won't delve deeply.

More details can be understood through further reading.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image52.png)

At the end of this lecture, we covered two key points as initially promised.

First, we introduced **attention mechanisms**—a new fundamental building block capable of operating on vector sets. This mechanism is highly parallelizable, scalable, and flexible, primarily composed of matrix multiplications, making it suitable for various scenarios.

Second, we explored **Transformers**, a neural network architecture using self-attention mechanisms as core computational units. Transformers have become the dominant architecture in contemporary deep learning applications. Despite being around for eight years, Transformers maintain enormous influence with no signs of diminishing importance.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec8_image53.png)

Today's lecture concludes here. Next time we'll discuss new tasks such as **detection**, **segmentation**, and **visualization**, and explore how to apply these architectures to achieve innovative results.

