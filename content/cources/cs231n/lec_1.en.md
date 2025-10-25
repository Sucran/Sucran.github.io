---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 1: Introduction"
date: 2025-09-03T16:01:24+08:00
draft: false
description: ""
---

Welcome to CS231N. I'm **Professor Fei-Fei Li** from the Department of Computer Science.


![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image2.png)

This semester I will be teaching alongside **Professor Ehsan Adeli**, graduate student **Zane Durante**, and our excellent team of teaching assistants (whom you'll meet shortly).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image3.png)

Let's begin.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image4.png)

This is what excites me—**artificial intelligence** has evolved into a highly interdisciplinary field. While this course is technically rigorous, its applications span across many different domains.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image5.png)

This course focuses on **computer vision** and **deep learning**, but I sincerely hope you can apply these concepts to your own fields of study and areas of passion.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image6.png)

**Artificial Intelligence (AI)** is widely discussed, but how does **computer vision** fit into this landscape? What is the scope of this course? If we consider AI as a vast territory, computer vision is its foundational building block. Vision is not just a part of intelligence—it's the cornerstone. Understanding visual intelligence is key to unlocking the mystery of intelligence itself.

The most fundamental mathematical tool driving AI development is **machine learning** (also known as statistical machine learning), which will be the core focus of this course. Over the past decade, machine learning has undergone revolutionary changes with the rise of **deep learning**. Deep learning is a set of algorithmic techniques centered around neural networks.

While this course doesn't cover all aspects of computer vision, machine learning, or deep learning, it will focus on the core intersection of these two fields. Similar to the broader AI field, computer vision is increasingly becoming interdisciplinary. The technologies and challenges we discuss often intersect with **natural language processing**, speech recognition, robotics, and other domains.

Furthermore, AI intersects and integrates with mathematics, neuroscience, computer science, psychology, physics, biology, and many other disciplines, with applications spanning healthcare, law, education, business, and many other fields.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image7.png)

In this first lecture, I will briefly introduce the development history of **computer vision** and **deep learning**. Subsequently, Professor Adeli will outline the course structure and learning requirements.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image8.png)

The history of vision doesn't begin with human birth, but rather dates back to **540 million years ago**. You might wonder why we focus on this specific evolutionary milestone. Fossil research shows that this mysterious period, known as the **Cambrian Explosion**, lasted about 10 million years—brief by evolutionary standards. During this time, animal species experienced explosive growth. Before the Cambrian Explosion, life on Earth remained relatively static, inhabiting only aquatic environments with barren land.

What triggered this dramatic change? Theories range from climate shifts to changes in ocean chemistry, but one of the most compelling theories is closely related to the **emergence of vision**. The first animals with photoreceptor cells—trilobites—had eye structures far more primitive than modern eyes, essentially just pinhole devices for collecting light.

This evolutionary milestone completely reshaped life forms. Without sensory capabilities, organisms could only engage in passive metabolism. The emergence of light-sensing ability marked a **decisive turning point**, enabling life to actively interact with the environment for the first time.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image9.png)

Through **sensory perception**, you become an integral part of the environment—an environment you might want to change or depend on for survival. Some plants and animals might become your food source, while you might become prey for other organisms.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image10.png)

The key to evolutionary forces driving intellectual development stems from the emergence of sensory capabilities, especially **vision** and tactile perception. These are among the oldest senses in the animal kingdom.

Over more than 540 million years, the evolution of vision has marched in parallel with the evolution of intelligence. As the primary sense, vision has driven the advancement of nervous systems and intelligence levels. Today, almost all known animals use vision as their core perceptual method.

Humans are highly vision-dependent creatures—over half of our cerebral cortex cells are dedicated to visual processing, supported by complex visual systems. This profound connection between vision and intelligence inspired me to enter this research field, and I hope it will inspire you as well.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image11.png)

Let's fast-forward from the **Cambrian Explosion** to human civilization. Humans continuously innovate—we not only can see, but also aspire to build machines that can "see."

This is a manuscript by **Leonardo da Vinci**, a genius forever curious about everything. He studied the principles of the camera obscura, attempting to understand how to create visual machines. Long before his time, ancient Greek and Chinese texts documented how thinkers explored projecting objects through pinhole imaging.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image12.png)

In modern life, **cameras** are ubiquitous. However, cameras alone cannot achieve vision, just as eyes alone are insufficient to see the world. These are merely tools. The essence of this course lies in understanding how **visual intelligence** operates.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image13.png)

Let's explore the historical context that led to the convergence of **deep learning** and **computer vision**. This all begins in the 1950s.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image14.png)

In the 1950s, a series of **critical experiments** were conducted in neuroscience, particularly regarding mammalian visual pathways. This includes the **groundbreaking work** by Hubel and Wiesel—they inserted electrodes into the brains of anesthetized living cats to study the receptive fields of primary visual cortex neurons.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image15.png)

To their surprise, the researchers discovered two key insights.

First, **primary visual cortex neurons** responsible for vision have independent **receptive fields**. A receptive field refers to the spatial region where each neuron responds, typically a small and localized area. Within this region, neurons can detect specific patterns—in the early stages of the visual pathway, these patterns manifest as oriented edges or moving oriented edges and other simple features. The primary visual cortex, located at the back of the head, processes these features. For example, one neuron might detect horizontal edges, while another detects vertical edges. This forms the foundation of visual computation in the brain.

The second insight is that the **visual pathway has a hierarchical structure**. Shallow neurons feed into deeper neurons, whose receptive fields become increasingly complex. For instance, simple edge detection neurons might converge onto neurons that respond to corners or even object parts. While this is a simplified description, the core idea is that neurons form computational networks through their interconnections.

Many may already realize that this hierarchical structure has profoundly influenced the modeling of neural networks for visual algorithms.

These discoveries date back to 1959, marking the early stages of visual neuroscience. Notably, about twenty years later, **Hubel and Wiesel** won the Nobel Prize in Medicine for revealing these visual processing principles.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image16.png)

Another milestone in the early history of **computer vision** was the birth of the field's first doctoral dissertation. This achievement is widely attributed to **Larry Roberts'** 1963 research, which focused on **shape analysis**.

This research characterized the world through geometric features, exploring how to understand shapes by identifying object surfaces, edges, and key features. While this seems intuitive to humans, this concept formed the foundation of an entire doctoral dissertation, marking the beginning of computer vision as an academic discipline.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image17.png)

Around 1966, an MIT professor launched a summer project on campus, recruiting several highly talented undergraduates to work on vision problems. They ambitiously planned to achieve **basic computer vision** that summer. But as is often the case in AI history—that summer's vision was not realized.

This unexpectedly gave birth to the germination of an important computer science field. Today, the annual academic conference in this field attracts over 10,000 participants. Larry Roberts' doctoral dissertation and this **groundbreaking research** are recognized as the foundational works of the computer vision discipline.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image18.png)

In the 1970s, **David Marr** wrote a groundbreaking work. This scholar unfortunately passed away young. He was dedicated to systematically studying vision and exploring **visual processing mechanisms**, drawing important inspiration from neuroscience and cognitive science.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image19.png)

He was thinking about how we process and understand input images through vision. The **first layer** resembles edges, which he called the **primal sketch**. Next is the **2.5D sketch**, used to distinguish the depth of objects in images, such as separating a ball in the foreground from the ground in the background. David Marr believed that the ultimate goal of solving visual problems was to achieve complete **3D representation**, which remains the most challenging part of the vision field.

Let me elaborate slightly. **Vision** is an ill-posed problem for all living beings. From early trilobites to modern humans, light projects onto a two-dimensional surface (now the retina), while the real world is three-dimensional. Recovering three-dimensional information from two-dimensional images is a fundamental challenge that both nature and computer vision must solve. From a mathematical perspective, this is ill-posed.

Nature's solution is to evolve multiple eyes (usually two), enabling **triangulation**. But having two eyes alone isn't enough—understanding correspondence is also crucial. Other courses will delve deeper into 3D vision, but the key point is the inherent difficulty of this problem. Nature and humans have solved it to some degree, but not through geometric precision. This highlights the complexity of the task.

Another philosophical difference between **computer vision** and language is that **language** doesn't exist in nature—it's a brain-generated, serialized, one-dimensional construct. This has profound implications for generative AI algorithms like **large language models**, which excel at modeling language. In contrast, vision is not generated—it reflects the physical world governed by physical laws and material properties.

Vision encompasses a diverse range of tasks. I hope you can understand the **fundamental differences** between language and vision and recognize how elegantly nature has solved this problem.

Let's turn our attention to the 1970s.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image20.png)

The early pioneers of **computer vision**, despite lacking data, powerful computational resources, and the mathematical advances we have today, were already beginning to tackle the field's most challenging problems. For example, Stanford University's object recognition research achieved breakthroughs through the groundbreaking work of Rodney Brooks and Tom Binford on "Generalized Cylinders."

Interestingly, Rodney Brooks is currently giving a talk at a robotics conference on campus. He later became one of the greatest **robotics experts** of our time, founding well-known robotic products like Roomba. This research took place not far from where we are in Palo Alto.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image21.png)

Researchers also developed **compositional models** for human bodies and objects. In the 1980s,



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image22.png)

Digital photography began to emerge, allowing people to **digitize** images to some extent.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image23.png)

During that period, **edge detection technology** made significant progress. However, by today's standards, these breakthroughs might seem mundane—extracting lines and edges appears effortless, and the computer vision field seemed to lack **substantive breakthroughs**. In fact, this perception wasn't entirely unfounded.

This period coincided with the eve of the **AI winter**, when enthusiasm and funding for artificial intelligence research sharply declined. Many fields including computer vision, expert systems, and robotics failed to meet their expected goals. But beneath this apparent stagnation, fundamental research in computer vision, natural language processing, and robotics continued to accumulate.

Another important research trend emerged from **cognitive and neuroscience**, which had a profound impact on the future development of computer vision.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image24.png)

What was particularly crucial for the **computer vision** field was that **cognitive neuroscience** was beginning to guide us toward the fundamental questions we should focus on.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image25.png)

For example, psychologists have discovered that perceiving natural and real-world scenes has certain special properties. A study by **Irving Biederman** confirmed this: experiments showed that subjects' recognition rates for bicycles in two images differed depending on whether the images were randomly scrambled.

From a **photon perspective**: although the two bicycles project to the same position on the retina, the surrounding image affects the observer's perception of the target object. This indicates that seeing the whole forest or broader context affects our cognition of individual objects.

Furthermore, this study highlighted the astonishing speed of **visual processing**. Another direct measurement also confirmed how quickly we recognize objects.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image26.png)

This experiment from the early 1970s showed human subjects watching a video and detecting a person in a particular frame. **Think about how extraordinary your visual system is**—you've never seen this video before, yet you can effortlessly identify the human target without prior knowledge of their appearance, location, or timing.

The video frames played at **10 Hz**, meaning each frame was presented for only 100 milliseconds. This demonstrates the extraordinary capability of our **visual perception**.

Cognitive neuroscientist **Simon Thorpe** has measured the speed of this visual processing.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image27.png)

If subjects wear an **EEG cap** and are shown numerous complex natural images, then asked to classify images containing animals versus those without animals, differentiated brain signals appear within 150 milliseconds of viewing the photos.

While this might seem slow compared to modern GPUs and chips, it's extremely fast for biological neural processing. The brain accomplishes this classification through just a few **neural transitions**, fully demonstrating the efficiency of the human visual system in object recognition and classification.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image28.png)

In fact, humans are not only good at recognizing and classifying objects, but also develop **specialized brain regions** with expert-level capabilities for recognizing faces, places, or body parts. These discoveries were made by neurophysiologists at MIT in the 1990s and early 2000s.

These studies showed that we should move beyond studying simple character shapes or image sketches and instead focus on the **fundamental problems** that drive visual intelligence. One key problem is object recognition in natural scenes.

The world contains countless objects, and understanding the mechanisms of their recognition is key to unlocking **visual intelligence**. This pursuit has become the core focus of our field.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image29.png)

We first studied methods for separating foreground objects from background objects, a process called **recognition through grouping** in the 1990s.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image30.png)

Remember, we were still in the **AI winter**, but research continued to progress. Additionally, research on **feature extraction** was ongoing.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image31.png)

Some of you might remember the SIFT feature and matching algorithm.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image32.png)

When I entered graduate school, the most exciting development was **face detection**. I remember that in my first year, there was a groundbreaking paper published on this topic.

Within just five years, the first digital camera used this algorithm to achieve automatic face focusing through **face detection technology**. This marked the beginning of such innovations transitioning to industrial applications.

Then in the early 2000s, with the rise of the **internet**, another major development emerged.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image33.png)

With the emergence of the **internet**, data began to explode. The combination of digital cameras and the internet provided the **computer vision** field with vast amounts of processable data. In the early stages, researchers studied visual recognition and object recognition problems using thousands or tens of thousands of images. Datasets like **PASCAL Visual Object Challenge** and **Caltech 101** emerged during this period.

This marked the beginning of major progress in the computer vision field. I'll pause here and return to discuss **deep learning** later.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image34.png)

While the field expanded from neurophysiology to computer vision, then to cognitive neuroscience, and finally back to computer vision, another parallel research path was gradually leading to **deep learning**. This field began with early explorations of **perceptrons** and other neural networks by scholars like Ronald J. Williams. Geoffrey E. Hinton, in his early work, deeply studied how small numbers of artificial neurons process information and achieve learning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image35.png)

You might have heard of great thinkers like **Marvin Minsky**, who worked with colleagues to study various aspects of perception. However, Minsky also pointed out that **perceptrons** cannot learn XOR or logical functions, which brought setbacks to neural network research.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image36.png)

Despite the setbacks, research continued to advance. Before the first turning point, one of the most milestone contributions was the **Neocognitron model** proposed by Kunihiko Fukushima in 1980. Fukushima manually designed a neural network through this architecture.




![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image37.png)

This network consisted of about five to six layers. He designed **unique functions** at these layers, largely inspired by the **visual pathway** I described earlier. You will learn about this in more detail.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image38.png)

Looking back at the **CAD experiment**, this experiment progressed from simple receptive fields to more complex structures. Early layers performed basic functions, while later layers handled more complex tasks. Simple functions used convolution operations, while complex functions integrated information from these convolutional layers. The **Neocognitron** was an engineering marvel, with hundreds of parameters carefully hand-designed, enabling this small-scale neural network to recognize digits or letters.

1986 brought a major breakthrough with the emergence of the **backpropagation** learning rule, which changed the landscape. This method, proposed by Raman Hart and Jeff Hinton (which we will focus on early in the course), introduced error correction objective functions to neural network architectures. By comparing network output with correct answers, error differences could be backpropagated through the network to adjust parameters. This backpropagation, following the fundamental chain rule of calculus, marked a key turning point in neural network algorithms.

Although these advances were born during the **AI winter** and didn't receive widespread attention, they were still important milestones in the research field.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image39.png)

One of the earliest neural networks to apply the **backpropagation** algorithm was the convolutional neural network developed by **Yann LeCun** at Bell Labs in the 1990s. He built a slightly larger network of about seven layers and made it capable of recognizing letters through excellent engineering implementation.

This system was actually deployed in some US post offices and banks for reading digits and letters, becoming a classic case of early neural network deployment. Subsequently, **Geoff Hinton** and Yann LeCun continued to advance neural network research.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image40.png)

Despite improvements and adjustments to these neural networks, progress essentially stagnated. Researchers compiled large datasets of digits and letters, which were relatively easy to recognize. However, when applied to complex digital images that neuroscientists used to identify cats, dogs, microwaves, chairs, and flowers, the systems failed.

A key problem was **data scarcity**—this wasn't just an operational inconvenience, but a fundamental mathematical challenge. These high-capacity algorithms require large amounts of data to learn and generalize effectively.

The principles of **generalization**, model overfitting, and the crucial role of data were often overlooked because the focus was mainly on architectural innovation. As the primary element in machine learning and deep learning, **data** didn't receive sufficient attention at the time.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image41.png)

This research was completed by my laboratory, including myself and my students, in the early 2000s. We recognized the **critical importance of data** and hypothesized that the field underestimated its significance. To this end, we collected a **massive dataset** called **ImageNet**, which ultimately contained 15 million images after cleaning 1 billion raw images.

These images were organized into 22,000 object categories, a number referenced from cognitive and psychology literature, reflecting the approximate range of categories that humans learn to recognize in early childhood.

We open-sourced this dataset and established the **ImageNet Large Scale Visual Recognition Challenge**. A curated subset of over 1 million images and 1,000 object categories was used to host international object recognition competitions for many consecutive years.

Participants' task was to develop algorithms—using any method—to accurately classify these images into the 1,000 categories. The challenge measured algorithm performance using **recognition accuracy**, with error rate as the key metric.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image42.png)

In the first year of the competition, the best-performing algorithm had an **error rate** of nearly 30%, a huge gap compared to human performance of about 3%.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image43.png)

2011 was relatively quiet in the field, but 2012 saw a **major breakthrough**. That year, Geoff Hinton and his students used **convolutional neural networks** to compete, reducing the error rate by nearly half, fully demonstrating the true potential of deep learning algorithms.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image44.png)

The algorithm that participated in the 2012 ImageNet challenge was called **AlexNet**. Interestingly, AlexNet was essentially no different from the **Neocognitron** proposed by Kunihiko Fukushima 32 years earlier.

But two major advances occurred during this period: first, **backpropagation** emerged as a mathematically rigorous learning rule, eliminating the need for manual parameter tuning, marking an important theoretical breakthrough.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image45.png)

Another breakthrough was recognizing and understanding **data-driven** high-capacity models, whose parameter counts eventually reached trillions. At the time, models with **millions of parameters** played a key role in igniting the deep learning revolution.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image46.png)

Many consider 2012 and the victory of the **AlexNet algorithm** in the ImageNet challenge as the historic moment of the birth (or rebirth) of modern artificial intelligence, marking the dawn of the **deep learning revolution**. Since then, we have entered an era of explosive growth in deep learning.

For example, at **CVPR**, the top annual research conference in computer vision, the number of published papers surged, and submissions on arXiv also increased dramatically. To participate in subsequent ImageNet challenges, numerous new algorithms were developed.

In this course, we will analyze some of these algorithms. Beyond AlexNet, many of these algorithms have greatly advanced the development of the computer vision field and its practical applications.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image47.png)

Since then, the **computer vision** field has made significant progress. We have not only achieved major breakthroughs in developing algorithms that can recognize everyday objects like cats, dogs, and chairs, but also achieved technological leaps in creating more complex algorithms shortly after the landmark **2012 ImageNet challenge**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image48.png)

Recognizing more complex images, retrieving images, performing multi-object detection, and conducting **image segmentation**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image49.png)

In this course, you will gradually become familiar with various tasks in the visual recognition field. The scope of **visual technology** extends far beyond simply recognizing cats and dogs—it encompasses many subtle and complex capabilities in visual understanding.




![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image50.png)

**Vision** extends far beyond static images, encompassing video classification and human activity recognition, among other areas.

This overview will introduce various visual tasks, including **medical imaging**. While you don't need to master all the details now, understanding the diversity of these applications is crucial.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image51.png)

Colleagues from medical fields like radiology, pathology, or other visual medical directions deeply understand its **profound impact** on scientific discovery. Even the landmark first image of a black hole relied heavily on computer vision and computational photography techniques.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image52.png)

Applications in **sustainable development** and environmental protection have also greatly benefited from **computer vision** technology.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image53.png)

We have also made significant progress in the field of **image caption generation**, a breakthrough that began at the critical turning point of 2012. This research was completed by **Andrej Karpathy** under my guidance while he was pursuing his PhD, forming the cornerstone of his thesis research.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image54.png)

We are also committed to research in **relationship understanding**. Visual intelligence is not just about perceiving pixel-level information, but about understanding the meaning beyond pixels, including the relationships between objects.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image55.png)

Additionally, **style transfer** has been an important area of research. Guest lecturer Justin Johnson will discuss his **groundbreaking work** in style transfer. In the era of **generative AI**, we can now achieve remarkable results like image generation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image56.png)

This marks the early stage of **DALL-E** image generation technology. While this is just the initial version of DALL-E, current systems like **Midjourney** have made significant progress, far beyond generating images like avocado and peach chairs.

We have undoubtedly entered the most exciting era of **artificial intelligence innovation**.




![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image57.png)

The fusion of **computation**, **algorithms**, and **data** has elevated this field to new heights, allowing us to decisively cross the AI winter.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image58.png)

We are in a period of **global AI warming**, and whether considering positive or negative factors, this trend shows no signs of slowing down. Being in Silicon Valley—especially in this building adjacent to the NVIDIA auditorium—we must acknowledge the crucial role of **hardware advancement**.

The chart showing NVIDIA GPU computing power per dollar confirms this. Before 2020, technological evolution was steady, but as deep learning drove GPU and chip development, billion-level floating-point operations capability has grown exponentially. By any standard, we are on an accelerating track of computing power and AI innovation.

Other charts reveal the surge in AI conference attendance, startups, and industry applications—not limited to computer vision, but also including **natural language processing** and other directions.

Despite these exciting achievements, the computer vision field still has much work to be done and is far from being completely solved. More importantly, powerful tools often come with significant impacts. **Computer vision** has great potential in areas like medical imaging, but also carries risks, such as perpetuating human biases.

Current AI algorithms (especially large models) are essentially data-driven. Since data reflects human activities and historical biases, these biases inevitably permeate AI systems. For example, **facial recognition algorithms** often reproduce the same biases as humans.

We must also consider the broader social impact of AI: should AI alone make hiring or financial decisions? These are complex questions without clear answers. This is why I'm excited to see students from diverse backgrounds like law, education, and business joining the course—not all AI challenges are technical; many involve human and social dimensions that require interdisciplinary solutions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image59.png)

I'm particularly excited about **AI applications in healthcare**, a topic I deeply care about.

Professor Adeli and Professor Zane Durante (who are also co-instructors of this course) and I are working together on **AI research for aging populations**. We plan to use **computer vision** technology to provide care services for patients, which represents a meaningful application direction for this technology.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image60.png)

Even from a technical perspective, **human vision** is extraordinary. By the end of this course, I hope you will appreciate that despite the powerful capabilities of **computer vision**, human vision still far surpasses it in subtlety, sophistication, richness, complexity, and emotional depth.

Look at these children—they are exploring anything that sparks curiosity, or the humorous moments captured in this photo. These are still areas that computer vision cannot reach. I hope this will inspire you to continue studying computer vision.

Now, I will hand the podium over to Professor Adeli to complete the rest of the course. Thank you.




Excellent. Thank you, Fei-Fei. **This semester is off to a great start.** I hope my microphone is working properly now. Great, I can see someone nodding. Good.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image61.png)

I'm very happy to be here with all of you. I hope you'll find this course both enjoyable and challenging, as we have an **outstanding team** of co-instructors and excellent teaching assistants.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image62.png)

In this course, we will cover a wide range of topics in **computer vision** and **deep learning**. These can be divided into four core sections.

The course will start with the fundamentals of deep learning. First, let's explore a fundamental question: **What is computer vision?** Its essence is enabling machines to parse and understand visual data.

The most basic task in this field is **image classification**. For example, given an image of a cat, the model needs to correctly identify and label it as "cat." This is the essence of this task.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image63.png)

This seemingly simple task is the **foundation** for many complex applications from autonomous driving to medical diagnosis. How do we teach machines to accomplish this task?

**Linear classification** is one of the simplest methods, as shown in this slide. Imagine that each image in the dataset is represented as a point in feature space, with each coordinate axis corresponding to a feature extracted from the image. For simplicity, we're showing a two-dimensional space.

The goal of a **linear classifier** is to find a hyperplane or linear function to separate categories, such as cats and dogs. However, linear models have limitations—when data cannot be linearly separated, they struggle.

This naturally leads to the question: what's next? We will explore how to model more complex patterns and address challenges like **overfitting** and **underfitting**, topics that will be covered in the early lectures of this course.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image64.png)

To achieve the right balance, we use techniques like **regularization** to control model complexity and **optimization** to find optimal parameters. These are core elements of deep learning that enable us to build models that not only fit the data but also generalize to unseen data.

Now let's explore **neural networks**. Unlike linear classifiers, neural networks model nonlinear functions by stacking multiple layers of operations to solve tasks like image classification. These models power applications from Google Photos to ChatGPT's vision models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image65.png)

In this course, we will delve deeply into how **deep learning models** work, how to train them, and techniques for debugging and optimization. After mastering the fundamentals of deep learning, we will focus on the complex process of perceiving and understanding the visual world—which involves parsing vast amounts of visual information. To this end, we first need to define **tasks** that represent specific challenges, such as object detection and motion understanding.

To solve these tasks, we use various computational and theoretical models to simulate or explain how the human visual system operates. **Neural networks** are a typical example of such models. By aligning models with tasks, we can build systems capable of environmental perception and parsing.

Returning to the topic of **image classification** (predicting a single label for an entire image), we find that real-world computer vision tasks are much more complex. Let's learn about several advanced tasks that go beyond classification:

1. **Semantic segmentation**: Instead of labeling the entire image, assign labels to each pixel (such as grass, cat, trees, or sky), but don't distinguish between individual objects of the same class
2. **Object detection**: Not only identify objects in the image, but also locate them with bounding boxes and associate specific labels
3. **Instance segmentation**: This is the most refined task, combining detection and segmentation techniques to generate independent masks for each object instance, achieving precise recognition and contour delineation

This course will provide systematic and in-depth coverage of these topics.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image66.png)

These tasks require deeper, more specialized understanding of images, pushing models beyond simple **category recognition**. Their complexity extends not only to static images but also to the temporal dimension.

For example, **video classification** involves understanding activities like running, jumping, or dancing, as Fei-Fei discussed. Another area is **multimodal video understanding**, which integrates visual, audio, and other modalities.

For instance, to understand a scene where someone is playing a vibraphone, we must combine visual and audio features.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image67.png)

Finally, we will explore the topic of **visualization and understanding** in this course, focusing on parsing what models have learned and understanding which parts the model focuses on when correctly classifying by observing attention maps.

Additionally, we will study models that go beyond basic tasks. We will first learn about **Convolutional Neural Networks (CNNs)**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image68.png)

This process involves multiple computational steps. Starting from an image, we will perform **convolution**, downsampling, and fully connected operations to generate output results.

Beyond **Convolutional Neural Networks**, we will also explore **Recurrent Neural Networks** suitable for sequential data, as well as emerging architectures like **Transformers** and attention-based mechanisms.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image69.png)

Next, we will cover the **large-scale distributed training** topic added this quarter. You should have heard of **large language models** and **large vision models**—we will briefly discuss the training methods for these models.

As dataset sizes expand and model volumes grow, strategies like **data parallelism** and **model parallelism** become crucial, all of which will be covered in this course. Additionally, we will discuss challenging topics like synchronization between models and worker nodes in one of this quarter's lectures.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image70.png)

We will also discuss some **trends** in training these large models. After completing this topic, we will begin with self-supervised learning to deeply study **generative** and interactive visual intelligence.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image71.png)

**Self-supervised learning** is a branch of machine learning where models learn to understand and represent data by extracting training signals from the data itself. This method can leverage vast amounts of unlabeled data to train large-scale models, playing a **key role** in recent breakthrough advances in computer vision.

We will also explore **generative models**, which are not limited to recognition but can also create new content. For example, we can re-render photos of the Stanford campus in the style of Van Gogh's "Starry Night."



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image72.png)

This is called **style transfer**, a classic application of neural generative modeling techniques.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image73.png)

Generative models can now convert language to images based on given prompts. **Models like DALL-E 2** can generate completely novel images, demonstrating how generative visual models combine understanding, creativity, and control in their output.

You may have heard frequent discussions about **diffusion models** recently.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image74.png)

Another topic we will explore this semester is learning how to reverse the process of gradually adding noise to generate images. In **Assignment 3**, you will implement a **generative model** that can remove noise from pure noise based on text input (such as prompts like "face wearing a cowboy hat") to generate emojis.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image75.png)

Vision-language models are a hot topic we'll explore next. These models can establish associations between text and images within a **shared representation space**. As shown in the example, given a description or an image, the model can retrieve or generate its corresponding content.

This field has made significant progress, and we will focus on analyzing several typical cases. **Vision-language models** play a key role in cross-modal retrieval, semantic understanding, and visual question-answering tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image76.png)

We will cover this topic in the course. Beyond the **two-dimensional** domain, models can now reconstruct and generate **three-dimensional representations** from images. Here, you can observe voxel-based reconstruction, shape completion, and **three-dimensional object detection** from single-view images.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image77.png)

**Three-dimensional vision** enables more realistic understanding, which is crucial for robotics, artificial intelligence, augmented reality, and virtual reality applications. Additionally, **visual capabilities** enable embodied agents to act in the physical world. These models must have the ability to perceive, plan, and execute tasks, whether it's cleaning a messy room or learning from human demonstrations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image78.png)

We will cover various topics related to **generative** and **interactive** visual intelligence.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image79.png)

Finally, we will explore some **human-centered** applications and impacts, which are very eloquently described. In recent years, computer vision and **artificial intelligence** have had profound impacts, so understanding their human-centered dimensions and applications is crucial.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image80.png)

The awards received by researchers in this field confirm some of these impacts. The 2018 Turing Award—the **most prestigious technical recognition**—was awarded to Geoffrey Hinton, Yoshua Bengio, and Yann LeCun for their conceptual breakthroughs and lasting contributions in establishing **deep neural networks** as a key component of computation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec1_image81.png)

Additionally, in 2024, **Geoffrey Hinton** and **John Hopfield** jointly won the Nobel Prize in Physics for their fundamental contributions to neural networks.

The learning objectives of this course include:
- Formalizing computer vision applications as specific tasks
- Developing and training visual models that can process images, videos, and other visual data
- Understanding the current state and future directions of the field

This year, in addition to the fundamentals, we will also cover new topics.

The first few weeks will focus on **fundamental concepts**, which are essential for building models from scratch. Then we will explore more cutting-edge and exciting topics in the computer vision field. The course will conclude with a comprehensive lecture on **human-centered artificial intelligence** and computer vision.

Next class, we will begin covering the topics listed today.


This will cover **image classification** and **linear classifiers**, taking us into the world of CS231N. Thank you.
