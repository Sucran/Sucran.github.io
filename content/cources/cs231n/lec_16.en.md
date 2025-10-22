---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 16: Vision and Language"
date: 2025-09-11T13:30:30+08:00
draft: true
description: ""
---

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image1.png)

Thank you for your participation. Today, we are honored to have **Ranjay Krishna** as our guest lecturer.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image2.png)

**Ranjay Krishna** is an Assistant Professor in the Computer Science Department at the University of Washington and co-director of **Raven Labs**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image3.png)

He previously taught **CS231N** in 2020 and 2021, and his research focuses on the intersection of **computer vision**, **natural language processing**, robotics, and human-computer interaction.

In today's lecture, he will discuss **multimodal foundation models**. Ranjay, please begin your presentation.



Thank you. It's great to be back teaching. When I first taught this course at **Stanford University** in 2020, we had to transition all teaching materials to online mode within three weeks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image4.png)

Teaching gets better year by year. It's wonderful to be back here.

Today we will explore **multimodal foundation models**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image5.png)

Many lectures in this course focus on building independent models for specific tasks. These models typically follow the following repetitive sequence of steps:

1. **Collect datasets**, usually containing training and test sets.
2. Train **specialized models** for tasks—such as image classification or image captioning models (similar to those used in assignments).
3. Finally evaluate model performance on the test set.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image6.png)

In recent years, the field has undergone a major shift from individual models to the development of **foundation models**. Foundation models are characterized by their pre-training for diverse skills and tasks, enabling subsequent adaptation to specific needs.

Taking **GPT** as an example, such models can be fine-tuned for different application scenarios such as mathematical problem solving, symbolic reasoning, or knowledge question answering through extensive training on internet Common Crawl data.

The advantage of foundation models lies in their ability to adapt to new tasks with minimal additional data, thereby reducing dependence on large-scale training datasets.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image7.png)

**Foundation models** typically require very little training data, sometimes even none at all. These models can be divided into multiple types. While **language models** like ELMO, BERT, GPT, and T5 have triggered a major revolution, this course focuses on **multimodal models**. Specifically, we will explore how to build foundation models for **image classification**, analyze examples such as CLIP and COCA, and discuss how to combine existing language models with **visual foundation models** to create general-purpose multimodal models capable of handling diverse tasks.

In addition to text generation, such models can also generate masks or images. We will also introduce the concept of **chained composition**—achieving new functionality by concatenating multiple foundation models. Although there may be controversy over the definition standards, the core characteristics of foundation models lie in their robustness and adaptability across tasks. Such models typically have massive parameters, large datasets, and **self-supervised training objectives**.

Today's discussion will focus on key content related to image classification. Building such foundation models requires the use of **self-supervised learning** and other techniques, which have been covered in previous courses.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image8.png)

In **self-supervised learning**, a famous method is **SimCLR**, which uses contrastive objectives to distinguish different images while bringing representations of the same image after various transformations closer together. This method aims to align similar concepts—for example, different augmented versions of cats should produce similar representations, while pushing representations of different categories (such as dogs) away.

The purpose of training through such self-supervised objectives is to develop sufficiently general representations. This ensures that novel inputs (such as sketches of cats or dogs) can still be embedded into this space, thereby facilitating accurate classification of these concepts.

Extending this idea to **multimodal learning**, we can apply the same principles and objectives to incorporate text into the representation space. For example, embedding the text "a fluffy cute cat" into a position close to the visual representation of cats can achieve seamless querying across images and text. Similarly, positioning the representation of the phrase "my favorite dog is a golden retriever" closer to golden retrievers rather than other dog breeds.

This demonstrates how to adjust self-supervised learning objectives to integrate text and other multimodal inputs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image9.png)

In **SimCLR**, the main objective is to cluster different transformed versions of the same image together. For example, the image of a **cat** should be closest to its augmented version (as shown by the green arrow), while maintaining distance from augmented versions of other images (such as dogs or monkeys). This same principle can also be applied to training **CLIP** models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image10.png)

**CLIP** retains the same image encoder on the left while introducing a **text encoder** on the right. This text encoder is responsible for embedding description information of individual images. For example, an image of a dog should learn to align closely with text representations like "my favorite dog is a golden retriever" while staying away from other representations.

The **training objective** of this model adopts the same mathematical form as **SimCLR**. By collecting large amounts of image-text pairs and inputting them into the model in small batches, we use similar contrastive objectives to SimCLR, but extend them to apply between cross-modal images and text.

In the numerator term, we bring representations of similar items closer; in the denominator term, we push representations of dissimilar items apart. Specifically, we require each image to be closest to its corresponding text while staying away from all other texts. Conversely, each text should also be closest to its corresponding image and stay away from all other images.

This produces a **complementary symmetric loss function** that operates between images and text modalities in the learning objective.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image11.png)

A key advantage of **CLIP-style models** is that they can be trained solely through image-text associations. The internet provides vast amounts of paired image and text data, making large-scale training possible. **OpenAI's** CLIP model released in 2021 fully demonstrates this.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image12.png)

They collected massive amounts of data and used contrastive learning objectives to train this **model**, fully utilizing all available image-text paired data obtained from the internet.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image13.png)

After training is complete, you will follow the same two-step process as **self-supervised learning** object categories.

First, perform **pre-training**. Subsequently, you can adapt the pre-trained image encoder to new tasks: by obtaining encoder weights and adding linear layers, it can be adjusted for **image classification** or **object detection**; or connect decoders to generate **semantic segmentation maps**.

This method supports a wide range of downstream tasks by initializing models from pre-training objectives.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image14.png)

This paper was particularly exciting when published because simply adding a simple **linear classifier** on top of the CLIP encoder brought significant performance improvements.

This chart shows the average performance across multiple image classification datasets, where the **CLIP model** (highlighted in red) achieved the highest scores. The trend line clearly shows that performance continues to improve as models are trained on larger-scale datasets.

This finding is promising, meaning we have found an effective **pre-training objective**. Given the massive amount of image-text data available on the internet, these models can also achieve better performance through scaling. However, this is just the beginning of the story.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image15.png)

Ideally, our goal is to directly utilize these features without adapting to new tasks. Taking **language models** as an example, models are typically trained through auto-completion tasks. For example, given the phrase "I like," the model predicts subsequent words like "cake." This pre-training objective enables the model to adapt to new tasks in the second stage without retraining.

Since all tasks in language models are essentially language-based, they can all be considered auto-completion processes. However, for **CLIP** models, there is no similar auto-completion mechanism. Although this model is trained through contrastive objectives, adapting to new tasks still requires training data and additional linear layers.

Therefore, researchers explored methods for applying models out-of-the-box. One innovative solution is to use the **text encoder** to guide the model to generalize to any downstream classification task.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image16.png)

The workflow works as follows. Suppose you want to use the **CLIP model** to classify images without retraining or adapting to downstream tasks. You can use the text encoder, input words to generate text vectors, then apply nearest neighbor algorithms to determine the correct classification.

For example, if the dataset contains images of airplanes, dogs, and birds, you can embed each category name in the text space to obtain its corresponding vector. When a new image is input, its embedding vector is generated through the image encoder, and the closest neighbor vector is found. In this example, this image should have the highest similarity with the "dog" vector, thereby completing correct classification.

The entire process essentially implements a **single nearest neighbor algorithm**. By generating embedding vectors in the text space as category labels, then using nearest neighbor matching to classify new images.

But single words may not generate optimal word vectors. In contrast, using phrases can improve performance because network data is usually composed of phrases rather than isolated words. CLIP models are trained on such phrases, so choosing appropriate phrases can improve representation quality.

For example, instead of embedding "airplane," "dog," or "bird," it's better to embed "a photo of an airplane" or "a photo of a dog." This small adjustment can significantly improve performance, such as achieving a 1.3% accuracy improvement on **ImageNet**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image17.png)

Choosing appropriate phrases is challenging in itself. Usually, practitioners don't rely on **single phrases**, but generate multiple variants, such as "a photo of a dog," "a sketch of a dog," or other conceptually similar phrases.

This method requires creating numerous **vector representations** for each potential phrase. Finally, the average vector representation of all phrases for each category is calculated, thereby obtaining average dog vectors, average airplane vectors, and average bird vectors.

Once these **average vectors** are established, standard one-nearest neighbor algorithms can be applied, likely utilizing models trained on ImageNet.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image18.png)

This demonstrates the model's **adaptability** to new tasks. I will show more examples involving datasets the model hasn't been trained on to illustrate its generalization ability.

The output is a single vector, depending on the architecture adopted. For **ResNet**, the final vector representation is used. If the text encoder is a **Vision Transformer (ViT)** or other Transformer variant, the **CLS token** is usually selected.

This concludes the discussion on CLIP.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image19.png)

This method can be applied to **diverse** new image classification tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image20.png)

Regarding your question, although the model's performance on ImageNet may not be surprising, it's worth noting that it still achieved strong results on this dataset. More interestingly, when evaluating datasets collected after CLIP's release—such as **ObjectNet** (which contains objects photographed in non-traditional scenarios, such as bananas placed on the ground or objects in highly decomposed states)—the model showed strong performance.

In contrast, models trained only on ImageNet perform poorly on such datasets because ImageNet mainly captures the most typical forms of objects. **CLIP's ability to generalize** to novel, out-of-distribution datasets is particularly exciting. This generalization ability stems from two key factors:

1. **Rich text supervision**: Text data scraped from the internet provides far more than simple category labels. It contains structural information, shape details, colors, and other attributes, enriching the model's representations. This enables the model to adapt to changes in object appearance or distribution shifts.

2. **Data scale**: ImageNet contains about 1.3 million images, while the internet provides billions of image-text pairs. The massive amount of training data enables CLIP to learn more robust and adaptable representations, thereby promoting better generalization.

These factors together explain why CLIP's performance exceeds models trained only on ImageNet.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image21.png)

Researchers conducted experiments across a wide range of generalization tasks, and results showed that these models not only perform excellently on natural images but also demonstrate outstanding performance on sketches and adversarial datasets. Experimental results consistently show that these models exhibit strong robustness and versatility across different application scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image22.png)

Here, I will explain the difference between **Zero-Shot CLIP** and **Linear Probe**. Obviously, Linear Probe (marked in green) by adding and fine-tuning additional linear classifiers improves performance on most datasets. But this rule is not absolute—in some cases, Zero-Shot CLIP without any modification performs excellently.

This indicates that we have unlocked the ability to adapt image encoders to diverse downstream tasks. Therefore, many researchers consider **CLIP** the first foundation model in the image domain.

Now let's explore the core factors that make CLIP efficient. Notably, CLIP doesn't rely on traditional labeling systems but utilizes any text information associated with images.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image23.png)

The key reason **CLIP** is so efficient lies in its scale and architectural design. This model was initially trained through massive parameters, then not only expanded in scale but also upgraded its architecture from ResNet to **Vision Transformer (ViT)**.

This transformer architecture with 307 million parameters laid a solid foundation for model training.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image24.png)

The second key factor lies in **data scale**. Unlike ImageNet's 1.2 million images, they used about 400 million image-text paired data downloaded from the internet for training. The dual improvement of model scale and dataset size significantly improved performance.

After CLIP's release, researchers began trying this approach and derived multiple variants. Among them, **COCA** proposed in 2022 is particularly noteworthy.

COCA extends the CLIP framework, retaining the core objective: separately encoding images and text and applying contrastive loss to them. But COCA adds a new component—processing image features from the encoder through a decoder, using cross-attention mechanisms to generate image descriptions. This description generation process forces the model to capture more detailed visual information, thereby strengthening the learning effect.

The core logic is that being able to distinguish between cat and dog images is far from enough. Describing images in words requires deeper understanding, making this task a more **powerful learning objective**. Empirical results show that this mechanism indeed enables models to learn better feature representations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image25.png)

When comparing **CoCa** with **CLIP**, its performance shows significant improvements across all ImageNet variants, achieving a **10% performance improvement** overall across all datasets.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image26.png)

This marks the first time **foundation models** comprehensively surpassed all models trained through supervised learning. Over time, various models have been continuously submitted to online leaderboards, with performance trends showing continuous improvement. This phenomenon has **turning point significance**—researchers began abandoning supervised learning objectives for image encoders, instead focusing on pre-training objectives using internet data for self-supervised learning.

Let's explore several advantages of **CLIP**: This model has rich practical application scenarios, its simple contrastive learning objective makes the training process efficient and direct, and inference speed is extremely fast. By embedding entire datasets into the representation space, classification tasks can be transformed into retrieval operations within this space, making CLIP highly valuable in classification and search tasks. Additionally, CLIP's **open vocabulary capability** enables it to handle arbitrary text descriptions and retrieve corresponding images, greatly expanding cross-domain applicability.

CLIP also performs excellently in integration with other models, a concept that has attracted widespread attention. Despite significant advantages, the model still has limitations, which we will discuss later.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image27.png)

The **CLIP** model cannot distinguish between these two images, which is indeed regrettable. One image shows a **cup on grass**, while the other shows **grass in a cup**. CLIP cannot recognize the difference between these two scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image28.png)

The root cause of the model's poor learning lies in **CLIP's learning objective**, which is highly dependent on batch size. When batch size is insufficient, other elements in the batch cannot provide effective supervision signals. For example, continuously comparing cats with trucks cannot help the model establish meaningful cat representations, but may instead cause the model to learn only superficial high-level understanding.

Increasing batch size can improve the probability of encountering similar animals (such as other cats), enabling the model to learn more detailed representations. For example, when training across multiple GPUs with a **batch size of 32,000**, the model can distinguish Welsh Corgis from other Corgi breeds. This discrimination ability can only be achieved through extremely large batches because the **hard negative samples** they provide force the model to optimize the learning process.

But it's worth noting that even with great effort, simply increasing batch size doesn't guarantee optimal representation learning results. The final result is still influenced by the randomness of training data. Although larger batches help improve fine-grained concept recognition ability, practical applications are often limited by hardware conditions—for most research laboratories, training costs of 32,000 samples per batch are too expensive.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image29.png)

Researchers found this error across different benchmarks and recognized that **CLIP lacks compositional concepts**. For example, the difference between "mug on grass" and "grass in mug" involves the combination of different concepts and their relationships, but CLIP's representation method cannot effectively combine these independent elements. Many benchmarks (such as Winoground, CREPE, or ARO—many of which originate from my laboratory) consistently highlight CLIP's limitations and its inability in certain tasks.

In response, the academic community quickly adopted **hand-crafted batch** strategies to include hard negative samples. For example, including multiple Corgi breeds in batches can force the model to learn better representations. This method was popular for about a year until our subsequent paper revealed that training with hard negative samples unexpectedly leads to loss of **semantic understanding ability**. Although this phenomenon hasn't been theoretically explained, it indeed causes significant decline in the model's generalization ability across different environments and datasets.

Therefore, there's still much work needed in **dataset construction**, batch selection, and training signal optimization. Despite these challenges, the academic community remains enthusiastic about CLIP because it provides foundational supervision capabilities.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image30.png)

Of course, image-level descriptions alone are far from sufficient. Ideally, we pursue more detailed annotations—not only identifying that **pedestrians** are crossing the street, but also accurately locating pedestrians, **vehicles**, and **streets**. Such basic information is completely missing in CLIP-style models. Therefore, datasets must contain such fine-grained annotations, and models need corresponding reasoning capabilities.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image31.png)

A significant limitation of **CLIP** models is that no matter how large the dataset—even massive scales exceeding 5 billion images—it's still insufficient to cover all relevant concepts. Therefore, much research focuses on data filtering techniques aimed at selecting the most suitable training data for CLIP models from internet resources. Although I won't specifically expand on these methods today, they currently represent a **key research frontier** in this field.

This concludes the discussion on the first branch of foundation models (i.e., extending classification capabilities across diverse tasks). Now we will turn to **vision and language models**, which are a new generation of foundation models that have risen in the past two to three years, commonly referred to as multimodal language models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image32.png)

I will use **LLaVA** as the starting point for discussion, which can be said to be the first multimodal language model to gain widespread attention. Its development motivation stems from a key discovery: language models that only predict the next word (essentially an auto-completion process) can demonstrate extremely strong task adaptation capabilities. This naturally raises a question: can we apply similar methods to image models? More specifically, can we enable image models to achieve reasoning capabilities similar to this autoregressive process? This exploration path gave birth to the development of **vision-language models** (i.e., multimodal models).

But it should be noted that this concept is not a new idea that emerged in 2022. As early as 2019, **ViLBERT** proposed similar solutions in a paper, achieving cross-task generalization by combining image models with language models. However, these early models belonged to the pre-Transformer era, mainly relying on LSTM architectures. Now this idea has been revived in LLaVA—the model adopts more advanced architectures and training objectives, no longer limited to single-task training, but based on pre-training objectives built on internet-scale data, forming foundational capabilities for diverse tasks.

To understand LLaVA, it's necessary to review the core mechanism of **Transformer models**—self-attention. Language models operate by attending to historical context: for example, given the sequence "cats are really," the model focuses on this context to predict subsequent words (such as "cute"). This process can also be viewed as attending to historical tokens to generate coherent subsequent content.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image33.png)

Input text is received from the bottom, and the model predicts word by word, which is intuitive. In the context of **vision and language models**, the conventional approach is to enrich dialogue content by associating images of interest. Specific implementation requires tokenizing images in some way and inputting these tokens together with historical context (such as "cats are really") into the language model to auto-complete the remaining description.

The **core principle** of models like LLaMA is: input image tokens together with already generated text, continuously producing more descriptions related to images. This naturally raises a key question: how should these tokens be initially defined? What should they represent? In the LLaVA model, the adopted solution is to introduce a **CLIP image encoder** to achieve this goal.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image34.png)

They use the **CLIP model** and its image encoder to extract tokens from the encoder.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image35.png)

The initial method might involve using **CLS tokens**. Images are input and divided into multiple patches, each patch converted to representations and input into CLIP's Transformer architecture. After multi-layer processing, the system generates different tokens for each patch while producing representations for CLS tokens.

So far, classification tasks have only considered CLS tokens. However, other tokens remain unsupervised—although CLS tokens are supervised through text contrastive objectives, the remaining tokens have no specific purpose and may lack effective information. Empirical studies show these features have limited value.

Notably, features from **CLIP encoder's second-to-last layer** are extremely practical. These features both participate in generating the final CLIP embeddings and retain key spatial information about object positions in images, so they're often used to integrate CLIP encoders with Transformer-based **large language models (LLMs)**.

This is the overall architecture of the **LAVA system**.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image36.png)

You input images into the pre-trained **CLIP encoder** to extract a set of features. These features are then passed through a trainable linear layer that learns to convert CLIP representations into formats that **large language models (LLMs)** can understand.

Once these tokens are obtained, they're input into the language model, enabling it to generate dialogue content about images.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image37.png)

**LAVA** was one of the earliest popular models in this field. Subsequently, Google quickly released **Flamingo**, which basically followed LAVA's framework of combining visual encoder features with large language models.

Flamingo's **core innovation** lies in its feature fusion mechanism. LAVA processes visual features through linear layers and treats them as part of the input, while Flamingo adopts a new approach—feeding visual encoder output features into every layer of the LLM.

This requires architectural modifications to the LLM itself, which they achieved through these changes.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image38.png)

Here are training data examples for the **Flamingo** model. Images (such as dogs and cats) are encoded to form embedding vectors, which are input into every layer of the **large language model (LLM)**. The text data below describes each image sequentially as input to the LLM. The model's task is to auto-complete descriptions of the last image. For example, given an image of a dog and its description, the model needs to learn to generate descriptions of subsequent images.

To achieve this goal, the authors made two **key improvements** to the model: first, they added **gated cross-attention modules** to every layer of the LLM; second, they added **perceptual samplers** to downsample image representations, ensuring each layer generates a fixed number of tokens and reducing dimensions.

The overall architecture remains largely frozen, with only perceptual samplers and cross-attention layers being trainable. Language model weights and visual model components remain unchanged.

Now let's analyze the structure of the **cross-attention module** in detail. Here's a close-up view of this module.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image39.png)

Before each **LLM layer**, there's a **cross-attention component** for processing image features. This component determines which parts of image features are relevant to what the language model needs to retain.

The architecture includes a layer that performs cross-attention processing on image features, followed by a \\(\tanh\\) nonlinear activation function. This activation function selectively retains or discards parts of image features. Features are then further adapted through fully connected layers, followed by another \\(\tanh\\) nonlinear function to optimize selection. Both components include **residual connections**. Processed features are input into standard language models for word generation.

These new layers enable the language model to integrate and attend to visual features at every layer. Code modifications are minimal, requiring only a few lines of code to implement cross-attention layers and \\(\tanh\\) nonlinear functions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image40.png)

From a code perspective, changes are minimal. But for the **model**, this means major changes—it can now selectively attend to different regions of images at each processing layer. This mechanism gives the model higher flexibility, enabling it to autonomously decide when and how to focus on visual features.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image41.png)

Training **Flamingo** models is extremely challenging and innovative. The model's training method involves concatenating multiple images and their corresponding descriptions into a single sequence. For example, input might start with descriptions like *"Here are some cute photos of my pets"*, followed by an image and its description, then another image and its description, and so on. This forms an **interleaved sequence** of image-text pairs.

To ensure the model focuses only on relevant images when generating descriptions, researchers adopted **masking mechanisms**. This mechanism limits the model's attention to current image features, ignoring contextual information from other images in the sequence.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image42.png)

When generating the description **"my puppy sitting on grass"**, the model only attends to features corresponding to the puppy when outputting these specific words. Similarly, for cat descriptions, it only focuses on cat images.

This distinction is achieved through **hand-designed masking mechanisms**, ensuring descriptions always remain consistent with their corresponding images. However, during training, the model still processes the complete context of all generated content.

This method proves beneficial for maintaining focus while fully utilizing the advantages of broader **contextual understanding**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image43.png)

Why is this entire process beneficial for integrating all these components? Its advantage lies in enabling the implementation of **such applications**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image44.png)

Flamingo demonstrates three different application scenarios, all centered around handling multi-turn conversations or multiple images.

In the first example, the system inputs an image, and the **Flamingo model** describes it as *"a photo of two teddy bears on the moon"*. Users can continue asking for details, such as *"what are they doing?"*. Relying on its **large language model** pre-training foundation, Flamingo inherits reasoning capabilities and responds *"the teddy bears are talking"*. Further asking *"what items are they using?"* yields answers like *"looks like a computer"*. This multi-turn conversation capability benefits from two key steps: pre-training language models and integrating them into the Flamingo architecture, while exposing the model to diverse images and conversation turns during training.

The model can also analyze multiple images and identify commonalities, such as determining that all images contain flamingos. Additionally, Flamingo supports **contextual learning** mechanisms, further expanding application boundaries.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image45.png)

You might have encountered this situation in language models, such as using **GPT** for contextual learning, where you provide an example and ask for similar output. **Flamingo** operates similarly. By inputting an image and its description, or a series of images with corresponding questions and answers, Flamingo can generate descriptions or answers for new images based on provided examples. This method doesn't involve training but achieves generalization through demonstrating expected behavior.

Flamingo can also perform **classification tasks**. For example, you can label an image as "underground" or "congress," then have it identify similar images. Additionally, it can learn **optical character recognition (OCR)** and mathematical tasks. By showing an image labeled "2 + 1 = 3," Flamingo can subsequently extract and calculate expressions like \\(3 \times 6\\) through reasoning. This demonstrates **few-shot learning**, where models generalize through few examples to handle new queries.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image46.png)

If we discard all **contextual examples**, this would constitute **zero-shot learning**, because we haven't concatenated them.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image47.png)

Technically, we would pass **image tokens** through perceptual resamplers to every layer of the large language model. Only text would be concatenated as input fed into the Flamingo model, which can dynamically attend to relevant image regions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image48.png)

When users first input, web interfaces cache the model, predicting users' subsequent interaction behaviors. This enables the model to remain active, ready to process additional tokens at any time. Without caching mechanisms, the system would have to reprocess the entire conversation history as input.

The excellence of the **Flamingo** model lies in its comprehensive research results, which are presented in detailed tables in the paper.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image49.png)

What's truly remarkable is the ability to adapt **CLIP** for performing various high-difficulty tasks. The **Flamingo** model achieves this goal through zero-shot or few-shot learning, showing significant improvements across numerous benchmarks.

This marks a shift in the field's research focus from few classification benchmarks to understanding tasks that can be constructed as question-answer processes. This method has spawned benchmark systems for diverse skills and has become the standard paradigm in computer vision over the past two years.

This reflects the field's development status as of last year.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image50.png)

After observing **LLaVA's** success, many companies began heavily investing in such models. This led to the emergence of various API models, such as **GPT-4O**, **GPT-4V**, **Gemini 1.5 Pro**, and **Gemini 1.5 Flash**. Anthropic also entered this field with **Claude 3 Opus**, then released Claude 4 Opus. These models show significant performance improvements across multiple benchmarks.

The chart shows average performance across 11 mainstream visual understanding benchmarks. There's a clear performance gap: the open-source model LLaVA discussed earlier has about 43% accuracy, while **GPT** and other models perform significantly better, with accuracy between 70% and 80% in the high range.

After recognizing this gap, researchers quickly began distilling GPT and Gemini into smaller variants and released these distilled models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image51.png)

Alibaba, a Chinese company, released models named **Qwen**, as well as InternVL, Phi, and other models. These models are all distilled from **GPT** or **Gemini**. This led to a major problem in the field and became the core focus of my research: the research community lacks knowledge systems for independently building high-performance vision and language models. Currently, only OpenAI teams and Google Gemini teams master the technology needed to build such models.

The open-source community remains far behind in this regard. Although there are impressive open-source models, they're not truly open because they rely on distillation techniques. Without GPT, we cannot reproduce or create such models.

Over the past few years, my research has been dedicated to bridging this gap, with the goal of developing methodologies for building high-performance vision and language models without relying on proprietary systems.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image52.png)

How can we develop high-quality **multimodal language models** and share this understanding with the broader community?

Over the past six months to a year, we developed a new class of models called **Momo**. Momo's performance metrics are shown at the top of the screen.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image53.png)

What distinguishes **Momo** from other models is its complete openness. It's open-weight, allowing users to download the model; it's open-data, providing access to training and evaluation sets; and it's open-code, so users can train their own Momo models at home as long as they have sufficient GPU resources. Users can also evaluate models, add new evaluation metrics, and adapt applications according to different scenario needs.

Although academic benchmarks are important, we're more concerned about whether people would prefer to use these models over alternatives like **GPT**. For this purpose, we conducted comprehensive user studies, directly comparing Momo's output with other models and released a public evaluation platform.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image54.png)

Our model achieved the same **ELO score** as GPT, ranking second by just one point, second only to GPT-4V.

This chart has been rotated for clearer display of some examples.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image55.png)

This is a large-scale evaluation involving about **870 users**. We showed participants these model output results and conducted about **325,000 pairwise comparisons**. Users needed to indicate their preferences for different model output results.

Our **Momo model** ranked second, with users' preferences for GPT and our model almost evenly split.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image56.png)

However, it has surpassed **Gemini 1.5 Pro** and **Claude 3.5**. The most significant difference is that as a small research laboratory, we not only surpassed Google's billions of dollars invested in Gemini and Anthropic's massive funding support, but also achieved performance comparable to **GPT-4o**. This progress is particularly exciting for us.

Additionally, we developed a **7 billion parameter model** that closely follows these large models. This 7 billion parameter model is particularly promising because it can run on a single GPU, requiring only basic hardware to handle diverse visual tasks. This ease of use enables it to be widely applied across various scenarios and optimized for specific needs.

We released this model on September 25th, immediately triggering great enthusiasm in the research community.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image57.png)

This was the first release of a high-performance multimodal vision and language model, triggering widespread discussion about its potential applications and numerous articles. A recurring theme is the idea of using this model for **robotics applications**.

Although I won't delve into robotics today—that will be next lecture's content—I want to highlight some cases that have sparked heated discussion in this field. Notably, even **NVIDIA** experts emphasize that regardless of how far proprietary models develop, **open-source innovation** has lasting impact.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image58.png)

Eventually, the open-source community will catch up, and we had already made progress at that time. After our model's release, **Meta quickly responded** by launching their Llama-32-11B model. We conducted extensive evaluations comparing **Molmo-7B-D** with Meta's Llama-32-11B, and I'm happy to report: our model outperformed Llama.

Now let me explain **why Molmo stands out in these comparisons**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image59.png)

The key to optimizing these models lies in **anchoring their decision-making process in pixel data itself**. Typically, when a model is asked "count how many ships," it might generate a random number, often producing hallucinatory results. However, our model distinguishes itself by clearly locating and pointing to each object it counts—generating visual markers for all ships before outputting the final count.

This **pixel-based anchoring method** enabled us to train an efficient model with only 700,000 image-text pairs, compared to Meta's LAMA model requiring about 6 billion such data pairs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image60.png)

The **key difference** is that we manually curated 700,000 image-text pairs. This practice fundamentally distinguishes our method from approaches adopted by commercial models.

Currently, many researchers attempt to directly obtain image-text pairs from the internet, which has become the standard practice for training vision-language models. However, web data has significant limitations—accompanying text often reflects subjective impressions or personal reactions rather than objective descriptions of image content.

In contrast, our dataset was carefully designed to specifically address this problem.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image61.png)

For individual images, we obtain **dense descriptions** of their content, including details rarely discussed on the internet. There's a vast amount of **tacit knowledge** in the visual world—for example, we rarely explicitly state that an object is to the left of another object because such spatial relationships are self-evident.

To enhance model performance, we began guiding people to provide **fine-grained descriptions**, capturing attributes such as size (like "large"), shape (like "rectangular"), material (like "polished," "textured"), and spatial orientation (like "spanning horizontally across the image"). Such **granular information** can significantly improve model performance.

Here's another example from the dataset.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image62.png)

This is a simple diagram of a tablet device screen. Information displayed on the screen includes current time and battery level, details often ignored in online discussions. **However, this information is crucial for users to effectively operate such device models.** Unfortunately, such information is rarely discussed on the internet. For this purpose, we specifically designed a series of targeted questions to collect this key data.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image63.png)

We conducted two years of heuristic research to determine what information is missing on the internet and the most effective collection methods. One key aspect was having annotators provide information through verbal descriptions rather than typing.

This method helps break stereotypes of Gricean conversational maxims, enabling people to express thoughts that wouldn't typically be conveyed through typing. The model's architecture remains similar to LLaMA, still using the same CLIP visual encoder and code input configuration.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image64.png)

This architecture includes a **linear layer connector** and a **large language model** for processing input tokens to generate desired output. Although this model is similar to existing frameworks, the **key difference** lies in the data—its quality and density.

This **image-based decision-making capability** (i.e., the model's grounding ability) achieves unique functionality that other models cannot achieve.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image65.png)

For example, you can instruct it to point to the **menu**, and it will mark the location of that menu item. Or, you can ask it to show where to set your **search options**, and it will guide you to the corresponding section. Similarly, requesting it to point to **medium-scale datasets** will guide you to relevant options.

As previously shown, it can also perform more detailed tasks, such as identifying **route numbers** on buses.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image66.png)

**Momo** doesn't just provide an answer; it identifies specific regions in the image—such as regions containing **bus numbers**—then returns that number to you.

You can also ask it to analyze vehicle distribution, comparing the quantity difference between left and right sides.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image67.png)

You can instruct it to analyze **depth images**, top views, or even complex scenes like crowded areas and sports venues.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image68.png)

Particularly exciting is what we'll discuss later—the recurring **chaining** theme in contemporary multimodal models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image69.png)

The concept of **chaining MoMo models** with other models refers to using their output as input to another model (such as **SAM2**). For example, you can instruct MoMo to identify a cricket bat, then pass that output to SAM2 for segmentation.

This achieves **temporal segmentation** of cricket bats, thereby unlocking various novel application scenarios. Here are cases we experimented with in our office.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image70.png)

You'll learn more about this in the **next robotics lecture**.

We instructed **Momo** to locate the water bottle position, then guided the robot there through basic motion planning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image71.png)

Next, we instructed it to move the **water bottle** to the dirty dishes area. It pointed to the sink, moved the robot there, then we guided it to identify available space in the sink and place the bottle in that location.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image72.png)

By integrating these functions, we can **chain them together**, thereby achieving automation for various robotics applications.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image73.png)

Currently, my research team is working on adapting **vision and language models** to enhance their generalization capabilities in the physical domain. The **core question** is: can these models maintain performance when image resolution is dynamically adjusted to fixed resolution?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image74.png)

Currently, these models can adapt to arbitrary resolutions. **Mechanisms like FlexiViT** support variable-sized image inputs, enabling models to operate in this new space. Position embeddings are dynamically adjusted according to image size, and models typically show strong generalization capabilities.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image75.png)

This concludes the discussion on integrating vision and multimodal models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image76.png)

In the remaining 20 minutes, I will discuss how to extend the application scope of these **foundation models** from image classification and text to generalization across various output spaces. A notable model in this field is the **Segment Anything Model**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image77.png)

The **Segment Anything Model (SAM)** aims to develop a segmentation foundation model capable of handling various segmentation tasks. Its main goal is to enable users to identify objects of interest in images and generate corresponding masks.

Unlike traditional models limited to fixed category sets, **SAM** can generalize to any category users might specify, generating precise masks that meet their needs. These two core goals—generalization capability across diverse categories and user-customized mask generation—define SAM's core functionality.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image78.png)

Both challenges involve how to collect large datasets covering diverse categories and design architectures capable of accurately identifying user priorities. **Let's first address the second problem**, because defining masks for objects itself may be ambiguous.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image79.png)

Consider a scenario: there are two cats in an image, but the user only requests segmentation of "that cat" without specifying which one. Ideally, with **MoMo's pointing functionality**, users can indicate the target cat, and the system can generate corresponding masks. Current masks may lack precision, but our goal is to achieve **high-quality segmentation** to support diverse downstream applications like image editing.

To enable users to precisely specify target objects, we must break through the limitations of **pure text input**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image80.png)

The **SAM architecture** consists of three core components: an image encoder (which can be a **CLIP encoder**), a dedicated **prompt encoder**, and a lightweight **mask decoder**.

The prompt encoder is specifically designed to handle various input types, such as text, points, or bounding boxes, enabling users to specify regions of interest. These encoded inputs are then passed through the decoder, which generates corresponding masks.

The decoder's structure is very similar to segmentation decoders discussed earlier in this course. This is the overall design overview of the model.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image81.png)

Given an image, we use the **image encoder** to encode it. Various prompts interact with these image encodings through the decoder, ultimately generating masks. This constitutes the overall architectural design.

However, there are **major challenges** in segmentation tasks. For example, when users select specific locations and request generation of segmentation masks for those points, ambiguity still exists. Even with precise coordinate points provided, the reference target may remain unclear because the point might be associated with the entire object.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image82.png)

"Scissors" might refer to the entire tool or just the handheld part. This ambiguity is difficult to eliminate, and we don't want to penalize the model for choosing wrong interpretations.

The **SAM architecture** solves this problem by outputting three segmentation masks of different granularity levels. Then the mask closest to ground truth annotations is selected to calculate loss values, avoiding penalties on other output results. In the long run, this method encourages the model to generate diverse masks, allowing users to choose the most suitable version according to specific needs.

To achieve this functionality, you only need to combine these components.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image83.png)

**Data** is crucial. To make this model feasible, large amounts of data covering diverse categories are needed. Before this model was released in 2023—about one and a half to two years ago—most segmentation datasets were extremely limited.

The authors of this paper solved this problem by expanding available segmentation datasets, increasing the number of images by about 6 times and segmentation masks by nearly 400 times. **This large-scale expansion** and mask collection are crucial for optimizing model performance.

The **core conclusion** aligns with insights from Flamingo and MOMO: high-quality data is a necessary condition for achieving optimal model performance. For many visual tasks, the required data is lacking on the internet, so active data collection must be conducted to ensure these models operate effectively.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image84.png)

To generate this dataset, they adopted an **iterative process**. First, they annotated part of the data to create an initial training set; then they trained the model and used it to annotate more data. Through this **human-machine collaborative loop mechanism**, they continuously optimized model-generated segments with the assistance of human annotators—first the model proposes annotation suggestions, then humans correct them.

Here's an example image from their dataset, where each individual contains rich and diverse category labels.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image85.png)

Each vegetable is annotated with its own mask, making the data collection process quite expensive. **This annotation** work was performed on millions of images. Here's another example.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image86.png)

All individual **umbrellas** have been annotated. This is another example featuring underwater scenes, which also includes **paintings**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image87.png)

They have **segmentation data** for paintings. All these elements together form the foundation for creating this segmentation model.

This concludes the discussion on **Segment Anything**. Next, I will use the remaining time to discuss other topics.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image88.png)

Today, we will focus on **chaining**—the final component of multimodal language models. The core concept of chaining lies in integrating different models to achieve functionality that single models cannot accomplish independently.

Let's do a brief exercise. I'll show four images and four categories, where some categories might be unfamiliar to you or even CLIP models, causing them to fail correct classification. For example, can anyone recognize which image is a **marimba**? That's right, the second one is a marimba. Similarly, identifying **viaducts** is simple for most people. But distinguishing between dog and bird images might be challenging.

Now note: if I provide text descriptions for these images, the classification task becomes much easier. This is the core value of chaining—even if CLIP has never seen these specific images, related concepts have likely been discussed on the internet. Therefore, GPT can generate descriptive text for these concepts, thereby achieving image classification.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image89.png)

These descriptions can serve as effective means for achieving precise category classification. The concept of **chaining** can fully leverage the advantages of one model and combine them with another model's capabilities, thereby unlocking new functionality that was previously impossible.

This method utilizes **CLIP** models' extensive learning of diverse descriptive corpora to complete massive category classification without training data. Therefore, CLIP can generate accurate classification results for these categories.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image90.png)

For **flowers**, cars, space, and even different types of pets, we observed performance improvements across various datasets focusing on fine-grained professional categories. This capability stems from GPT's ability to describe such objects. The concept of **generalizing** new skills gained tremendous attention last year.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image91.png)

This concept remains very popular this year. Its core idea is to answer various questions through **model chaining**.

For example, if asked "are there three people on the boat?", one method is to use multimodal language models. Another solution is to utilize specialized vision models developed over the past few decades. As the course explains, **object detection models** can identify these three people. By counting detection results, we can conclude "there are three people on the boat."

This idea of chaining model outputs to expand new capabilities is demonstrated here with another example:



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image92.png)

How many people are there on these two boats? The answer is **six people**. Similarly, you can write a program to perform **object detection** on image one and image two, then add the number of detected components. This is the **basic principle**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image93.png)

What we now call the **chaining** concept originated from the *VisProg* paper that won the best paper award last year. This paper on *visual programming* has the core idea of: receiving arbitrary images or questions and generating programs. The program would first analyze one image, then another, and finally merge results to arrive at the final answer.

For example, you can write a **Python script** containing independent functions that call other models we've encountered in training. This method is particularly practical when verifying the validity of specific statements.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image94.png)

There are **six people** and **two boats** in the left and right images. You can instruct GPT to generate a program that attempts to answer this question, then extract the answer from its output. Additionally, you can directly query GPT for the answer.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image95.png)

To achieve **contextual examples**, you need to provide program instances that can be generated through other functions. This demonstrates the system's ability to generalize to new types of questions while utilizing all available functionality.

But you must provide the **functions** themselves, because the system needs explicit instructions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image96.png)

You can **leverage capabilities of other models**, such as using object detectors for target localization or face detectors for face recognition. These diverse capabilities developed in different models can be chained together to perform different tasks.

There are two specific implementation methods:
- **Static method**: provide as diverse a set of examples as possible, then process directly.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image97.png)

To ensure generalization capability, one method is to dynamically select the most relevant contextual examples for given problems. This can be viewed as a **retrieval process**—generating programs by identifying optimal examples, usually achieving better performance. But this method requires powerful retrieval systems and substantial computational resources.

Computational costs mainly come from two aspects: GPT's API calls, and the need to sequentially load and run multiple models in memory. Therefore, this solution is costly. Current research in 2025 focuses on **distilling these capabilities into single models** to reduce costs, while exploring efficient methods for chaining models.

This framework can be abstracted as **agent-based systems**: agents decide which models should be called for specific problems and integrate their outputs to achieve new functionality. Here's another case scenario applicable to this solution.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image98.png)

To achieve image editing tasks such as replacing deserts with lush green grass, current models are still in early stages. An alternative solution is to use **segmentation models** to identify desert regions and selectively replace these pixels with grass. Subsequently, these elements can be synthesized to generate new images.

This summarizes the key steps involved.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image99.png)

I will discuss various capabilities related to **foundation models**. These models, although trained for single tasks, can generalize to multiple downstream application scenarios. In classification tasks, we have studied how to build such models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image100.png)

By training on massive amounts of image-text paired data on the internet, these models can perform multiple tasks and **generalize** to new datasets that may not exist in the real world or lack annotations. Additionally, they can be combined with language models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image101.png)

These models can be trained to perform **contextual tasks**, such as image annotation, counting, or **optical character recognition (OCR)**. These capabilities support multiple application scenarios. Note that their output is not limited to language content.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image102.png)

Categories can also be represented as **segmentation masks**, whose specific form varies with user input. This method can be further generalized by combining multiple foundation models or smaller models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image103.png)

Through various projects, we continue to explore new possibilities. However, **hallucination problems** remain a universal challenge across all application domains. This is what we're showing.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec16_image104.png)

**Pointing mechanisms** seem to significantly reduce hallucinations by requiring generated content to provide evidence support. But there's no guarantee that models always point to correct evidence. Currently, there are various solutions, including collecting more task-relevant training data and implementing **verification methods** that evaluate output reliability based on evidence.

Many mainstream models and enterprises adopt **verification pipeline** mechanisms, where initial outputs must undergo additional verification procedures before being presented to users, effectively mitigating related problems. Reducing hallucinations while improving model accuracy remains an active research direction.

Regarding whether models can develop new tools: preliminary experiments show that models can build specific functional systems through instructions. These systems can automatically collect training data and create tools for specific use cases. Although this research direction is still in early stages, it has attracted high attention in the field.
