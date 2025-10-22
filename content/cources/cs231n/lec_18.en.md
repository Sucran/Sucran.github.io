---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 18: Human-Centered AI"
date: 2025-09-11T13:30:38+08:00
draft: true
description: ""
---



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image1.png)

Welcome to the final lecture of **CS231N** for this quarter. It's wonderful to see you all both at the beginning and end of this course.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image2.png)

This lecture differs slightly from our usual format. **My goal is not to introduce new algorithmic content**, but to provide students with a broader perspective on the long-term evolution of research and an important dimension in contemporary artificial intelligence: the human perspective.

Although there may be some overlap with other parts of the course for completeness, this discussion will provide a more comprehensive understanding.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image3.png)

The title of this lecture is "What We See and What We Value: Artificial Intelligence from a Human-Centered Perspective."



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image4.png)

Some of you may already know that this marks the **origin of vision**, both in evolutionary and technological development terms. We discussed instances of vision first appearing in the animal world approximately 540 million years ago.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image5.png)

At that time, animals—especially **trilobites**—evolved photoreceptor cells to perceive the external world.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image6.png)

According to research by zoologists like **Andrew Parker**, the emergence of vision triggered an evolutionary arms race, forcing animals to either adapt or perish.

This arms race led to rapid **diversification** of animal species, a phenomenon now called the **Cambrian Explosion** or **Evolutionary Big Bang** by zoologists.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image7.png)

It's unsurprising that **vision** serves as the primary perceptual system for intelligence in many animals. While not all species rely on vision, it dominates in humans, undertaking critical functions such as survival, work, entertainment, social interaction, and cognitive development. This summarizes the **evolutionary significance** of vision.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image8.png)

We also briefly discussed how **computer vision** originated from the "Summer Vision Project" in the 1960s—an initiative aimed at involving undergraduates in building important components of vision systems.

This echoes the macro development history of **artificial intelligence**: we often have clear visions of goals but underestimate the time needed to achieve them. Although this phenomenon persists today, the field has made significant progress.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image9.png)

From enabling **autonomous vehicles** to understanding image content, to leading the **generative AI revolution**, computer vision has always played an important and often dominant role.

Now is the time to examine this field from both historical and future perspectives—understanding both the progress we've made and anticipating the path ahead. This exploration is crucial because past development trajectories will inevitably shape future breakthrough directions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image10.png)

This presentation is divided into three parts.

First, we'll explore **building AI that can perceive what humans see**, inspired by human capabilities and aimed at creating machines with similar perceptual abilities.

Next, we'll delve into how to build AI that can perceive what humans cannot see.

Finally, we'll conclude with building AI that can perceive what humans desire to see.

Now let's start with the first topic: building AI that can perceive what humans see.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image11.png)

In short, humans have exceptional abilities in **visual perception**. This conclusion stems from an experiment from half a century ago: even when watching videos played at 10 Hz frequency (each frame displayed for only 100 milliseconds), viewers could still identify content they had never seen before.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image12.png)

Even without prior knowledge of target individuals (here referring to people), human eyes can effortlessly detect targets in complex scenes. **This highlights the extraordinary capabilities of human visual understanding**, especially in object-centered perception.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image13.png)

We briefly mentioned that around the turn of the century, neurophysiologists measured **human visual speed** by analyzing brain signals (specifically electrical signals recorded through EEG caps).

Research found that distinguishing or categorizing animals is a complex task, but humans can complete this process within **150 milliseconds** after stimulus appearance. This astonishing speed highlights the efficiency of our neural processing systems.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image14.png)

Neurophysiologists have confirmed that **object recognition** is a key function of human visual intelligence. This importance is reflected in specific neural associations in brain regions dedicated to understanding objects, such as face-selective areas, scene-selective areas, and body part-selective areas.

Evolution has specifically optimized these visual intelligence skills for object recognition. Therefore, object recognition became a fundamental component of computer vision decades ago, laying the foundation for the development of machine visual intelligence.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image15.png)

To solve this problem, we formulated the task (at least its original definition) as: enabling computers to recognize objects in images. While this is effortless for humans, it constitutes a **fundamental challenge** for the computer vision field. From a mathematical perspective, due to infinite combinations of factors like lighting, texture, background, occlusion, viewpoint, and scaling, object recognition requires handling nearly infinite possibilities of variation.

The exploration journey of this problem before the deep learning era is particularly fascinating. Early attempts to achieve **generalized object recognition** were deeply inspired by psychology—humans often perceive objects as combinations of geometric components through introspection (sometimes excessively). This insight gave birth to the first wave of object recognition models from the 1970s to 1990s, which relied on predefined components or shapes configured in specific ways. Although these methods were mathematically elegant, they ultimately proved ineffective.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image16.png)

The second wave of object recognition before the **deep learning era** marked an important period in the AI field, representing the dawn of **statistical machine learning**. This stage connected computer programming with statistical modeling, revealing the complexity of the world.

Whether handling visual intelligence, language intelligence, or other forms, generalization capabilities need to be achieved through learning parameters. Hand-tuned models proved unable to learn effectively, highlighting the necessity of **data**—though the specific quantity was unclear at the time.

Additionally, designing statistical models capable of learning through diverse rules became crucial. Therefore, this era witnessed the widespread emergence of models like **random fields**, **Bayesian networks**, and **support vector machines**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image17.png)

In the first decade of the 21st century, the **object recognition** field achieved **significant progress**, including establishing international benchmark datasets containing limited numbers of object categories to facilitate algorithm comparison.

As we know, the ultimate breakthrough in object recognition can be traced back to contributions from **cognitive science**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image18.png)

This psychologist **Irving Biederman** long theorized that humans can recognize vast numbers of objects. While this aligns with common intuition, he quantified it.

I call this the **Biederman Number**: he estimated that by age six or seven, children can recognize approximately 30,000 to 100,000 different visual categories.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image19.png)

He arrived at this number by analyzing dictionaries, counting nouns, and studying how children recognize objects. **This number is both daunting and thought-provoking for the computer vision field.** Until the mid-2000s, we were still dealing with very limited numbers of object categories and images, dwarfed by human experience.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image20.png)

This marked the birth of the **ImageNet project**, which rigorously responded to **Biederman's theoretical framework** by constructing a dataset consistent with psychologist Irv Biederman's conjecture—covering approximately 22,000 object categories and 15 million images.

The large-scale data provided by ImageNet enabled powerful algorithms (initially convolutional neural networks, later Transformers) to fully demonstrate their potential. This foundational work highlighted the crucial role of **big data** in advancing machine learning development.

Given that those present are already familiar with this background, I'll skip the details and continue.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image21.png)

The rapid development of the **object recognition** field began with the launch of **ImageNet** and the subsequent application of **convolutional neural networks**. This breakthrough greatly expanded the possibilities of this field.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image22.png)

Today, we have **algorithms** capable of analyzing any image to identify objects, regardless of their size or orientation. While not 100% solved—long-tail problems still exist—the field has significantly matured in industrial applications.

This progress can be traced back to the pivotal moment in 2012 when the **ImageNet Challenge** provided datasets for **convolutional neural networks**. Using just two GPUs, the fusion of data, algorithms, and hardware marked the birth of **deep learning**.

In this course, we explored architectures like **ResNet**, which emerged from ImageNet challenges over the past decade, laying the foundation for the deep learning revolution.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image23.png)

In pursuing visual intelligence, our goals extend far beyond simply annotating objects in scenes. Consider these two scenarios: if only annotated, both merely show an alpaca and a person. However, the second scenario, while containing the same objects, tells a **completely different story**, highlighting the importance of relationships between objects.

Cognitive scientists recognized before computer scientists that the scope of **visual intelligence** extends far beyond object naming or classification. The renowned psychologist Jeremy Wolfe emphasized in his groundbreaking paper that understanding complex natural scenes requires encoding relationships between objects. Inspired by this, the computer vision field began exploring methods to understand these relationships.

Early research in this direction included Randy's doctoral thesis—you may have learned about this in last week's course. His research adopted **scene graphs** as representations, where entity nodes represent objects and edges define their relationships or attributes. Even seemingly simple scenes (like one person feeding cake to another) can generate dense scene graphs due to the richness of visual interactions.

This marked a shift from the **object recognition era**, giving rise to achievements like the Visual Genome dataset. This dataset advances our deepening understanding of visual scene cognition by integrating object relationships, attributes, and narrative descriptions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image24.png)

One particularly fascinating study focused on **zero-shot learning** applications on unconventional object relationships. While common scenarios like people riding horses or wearing hats appear frequently, encountering situations like horses wearing hats is extremely rare. In the context of **big data training**, due to the scarcity of samples for such unconventional relationships, obtaining sufficient training instances is challenging.

By employing **compositional scene graph representations**, our method learns from more common relationships and derives inference capabilities for unconventional relationships. This perfectly exemplifies the core of zero-shot learning—when common relationships like "people sitting on chairs" or "fire hydrants standing on lawns" have sufficient data representation, rare combinations like "people sitting on fire hydrants" lack sufficient training samples.

The comparison chart in the paper shows that our method achieved **state-of-the-art recognition rates** at the time, outperforming numerous alternatives. However, focusing solely on relationship learning itself also has limitations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image25.png)

The ability to construct richer narratives using **natural language** marked the next important milestone in this field. Around 2014, we began addressing this challenge, only two years after the pivotal **AlexNet breakthrough moment**. The rapid development of this field is remarkable.

We gained inspiration by combining **convolutional neural networks** with language models called **LSTMs**. Andrej Karpathy's paper first demonstrated applications like image captioning, story generation, and dense annotation, with Justin Johnson making important contributions to this work. Between 2015 and 2018, substantial progress was made in solving this problem. Today's **multimodal large language models** push these solutions to higher levels, but this period laid the foundation for this research trajectory.

As a **computer vision scientist** who entered this field around the turn of the century, I was amazed by how fast research progressed when sufficient data and neural network algorithms emerged. But handling dynamic scenes is an even more complex challenge.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image26.png)

In dynamic scenes, we observe more complex relationships and motion patterns. **Camera movement** and agents in scenes may exhibit diverse behavioral characteristics.

We collaborated with Stanford University and multiple students in our laboratory to develop a framework called **Multi-Object Multi-Agent Activity Understanding (MOMA)**. This latest research, published several years ago, is dedicated to capturing intricate associations between agents and their activities in dynamic environments.

This remains a **significant unsolved problem** with far-reaching implications, especially in Silicon Valley where robotics enthusiasm is surging. For example, if we expect everyday robots to work collaboratively with humans, these robots must overcome this challenge—they need to understand scene complexity, identify human behaviors, distinguish individual roles, and predict subsequent activities. This marks a crucial unsolved problem in this field.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image27.png)

Beyond topics covered in this course, we also introduced related **computer vision** problems. But due to time constraints, we couldn't delve deeply into areas like **3D computer vision**, **human pose estimation**, and **generative AI models**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image28.png)

This demonstrates how rapidly the **computer vision** field has developed since the modern AI renaissance.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image29.png)

There are two key points in this section. First, data, computational power, and neural network algorithms converged approximately 10 to 13 years ago, marking the beginning of modern artificial intelligence and the deep learning revolution. Second, much work in this field has been inspired by **cognitive science**, psychology, and neuroscience.

This cross-disciplinary inspiration will persist because we're still exploring how the brain works and using AI to advance brain science research. Therefore, contemporary artificial intelligence has deep connections with fields like cognitive science, neuroscience, and brain science.

This concludes the first section. Here, I also want to thank numerous students and collaborators for their contributions to this material.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image30.png)

Now, let's explore how to advance **artificial intelligence** beyond human perception. This involves elevating AI capabilities beyond human levels, what's called **superhuman performance**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image31.png)

For example, most people cannot identify many dinosaurs, though they may recognize a few. **Some children** can name quite a few dinosaurs.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image32.png)

Consider that there are thousands of species in categories like birds or cars alone. This is what I call the field of **fine-grained object classification**. Humans are not particularly good at this task, and frankly, it remains an unsolved problem.

In today's era dominated by **multimodal large models** and generative AI, this problem has been somewhat overlooked or is no longer considered mainstream. However, it will continue to play an important role.

In our early research on fine-grained bird recognition, we once constructed a dataset containing 4,000 bird species samples.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image33.png)

As we ascend the species classification hierarchy to broader categories, error rates gradually decrease. But this precisely indicates that at the **fine-grained recognition level**, our algorithms still have significant defects.

Our laboratory once conducted fascinating research: training a fine-grained car classifier to distinguish brands, models, and years. After the 1970s, there were thousands of different configuration combinations in the automotive field. We used **Google Street View** image data covering about 100 major US cities, analyzing urban vehicle distribution through car detection systems. This data provided entirely new perspectives for studying social patterns, revealing strong correlations between car models and factors like education levels, income, voting behavior, and environmental impact.

This demonstrates how **computer vision** can discover social insights beyond human observation capabilities. To illustrate human perceptual limitations, let's conduct several tests below.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image34.png)

I discussed the commendable aspects of human visual capabilities, but we also have limitations. A **well-known visual illusion** is the Stroop test. While you can easily read these words, quickly identifying the colors of these words—from left to right, top to bottom—is quite challenging.

For example, try reading: red, yellow, green, purple, blue, black, orange. This demonstrates **conflict between visual attention and word recognition**.

Here's another example.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image35.png)

There are two alternately displayed images in the picture, with a significant change between them. Can you spot the difference? **The engine has changed.** Detecting this change takes time. This is a famous psychological experiment called **change blindness**. While experiments like the Stroop test are quite entertaining, this phenomenon isn't just for amusement.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image36.png)

Human attention is limited, and in certain professional and personal situations, this limitation can have serious consequences. **For example**, medical errors are the third leading cause of death in the US healthcare system. While leaving surgical instruments inside patients is a stark example, medical errors encompass a wide range of issues including medication errors, operational mistakes, documentation errors, and diagnostic misjudgments.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image37.png)

We must be very careful.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image38.png)

For example, in surgery, while **scissors** are rarely left inside the body, smaller items like **suture needles** or gauze are frequently left behind. Currently, tracking such items still relies mainly on manual work.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image39.png)

In **operating rooms**, we use checklists to track equipment. If an item is missing, surgery must be paused, typically taking nearly an hour. This delay poses **significant risks** to patients, including increased bacterial infection rates and prolonged bleeding time, all stemming from time spent searching for missing items.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image40.png)

If **artificial intelligence** could assist our doctors and surgeons in tracking items, it would have enormous potential. Currently, this is just a demonstration, not a deployed system, because we haven't reached the required **accuracy** level.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image41.png)

This demonstration shows how to use **artificial intelligence** to count gauze and similar items.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image42.png)

This demonstrates how to use **artificial intelligence** to discover insights beyond human perception. Here's another fascinating example.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image43.png)

This is one of my favorite visual illusions. If you observe squares **A** and **B** on the top chessboard, it's hard to believe they have the same gray level or brightness. However, the bottom image clearly proves they indeed do. Even with this evidence, the top image still creates the illusion.

Why? **Evolution** has made us naturally inclined to interpret the world through common physical phenomena (object shapes, light sources, shadow formation, etc.). This deep mechanism rooted in evolution and visual development makes it difficult for us to perceive things differently.

The key is that **cognitive biases** exist in human visual systems. These biases may stem from evolutionary construction, social experience, or data we're exposed to. Some biases may be harmful, especially when leading to unfair treatment of specific groups.

For example, early facial recognition algorithms performed poorly on certain skin tones and genders, causing real-world impacts. Consider applications like autonomous vehicles or medical diagnosis—we must remain vigilant about these biases.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image44.png)

I believe **AI bias** has always been a long-standing problem. A few years ago, this issue was so novel that many people ignored it. But by 2025, while the problem remains unsolved, the widespread attention from academia and industry to this issue encourages me greatly.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image45.png)

Another form of "seeing without seeing" presents an intriguing challenge. In some cases, **deliberately not observing** is precisely what we need to protect privacy. This raises a fundamental question: how do we develop AI systems that can enhance visual capabilities while respecting individual privacy choices? This is both a deep **technical challenge** and a human-centered ethical dilemma.

From a technical perspective, the machine learning field has various methods for protecting privacy. Specifically in visual applications, our laboratory published research several years ago on using smart cameras in healthcare scenarios. Even in these beneficial applications, we must carefully consider privacy issues arising from **facial recognition**, full-body imaging, and home environments. Potential technical solutions include image blurring and masking techniques.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image46.png)

You can adopt **dimensionality reduction** techniques or explore other alternatives, such as **federated learning**, to avoid transmitting all data to servers, or use encryption and other methods.

Although I won't delve deeply into this, I want to highlight particularly remarkable work—though not from my hand—that I personally find very compelling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image47.png)

This research focuses on analyzing personal videos to identify their behavior while protecting their privacy. **The key is how to effectively achieve this balance.**



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image48.png)

For example, when filming videos of children moving in scenes, traditional methods like blurring or defocusing can protect privacy but often result in losing **key information** about people's movements.

In many application scenarios, understanding the subject's behavior is the core goal. In this work led by Juan Carlos and his students, they developed a **hardware-software integrated solution** by designing specialized lenses that filter visual data in specific ways.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image49.png)

The lenses shown in the top row demonstrate **significant privacy protection effects** by blurring faces and bodies. This special lens integrates with specific software, enabling extraction of human motion and behavioral data while ensuring facial anonymity.

This **innovative hardware-software hybrid solution** addresses key application scenarios that balance monitoring needs with privacy protection. I highly appreciate the technical approach of this work and the philosophy it embodies.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image50.png)

In this part of the lecture, I discussed several **key considerations** for building AI systems that can perceive what humans cannot perceive. AI has **superhuman capabilities**, such as fine-grained bird recognition beyond human levels. But we also recognize human limitations—our biases and attention deficits—which are precisely areas where AI can provide valuable assistance. Additionally, certain scenarios involving privacy concerns require careful AI deployment to avoid infringement.

AI is a **powerful and versatile tool** that can both assist and enhance human capabilities. However, if we ourselves have biases or other defects, AI may amplify these problems. Therefore, when developing AI, we must not only adopt a technical perspective but also uphold **human-centered principles**. We must commit to researching, predicting, and guiding AI to ensure it aligns with human values and minimizes negative social impacts.

This is the second **key point**. I also want to thank collaborators and students who participated in this research for their contributions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image51.png)

Now, let's explore how to build **artificial intelligence** to understand what humans want to see. Actually, we'll expand our exploration beyond vision.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image52.png)

We'll explore the connection between **perception** and **action**. In today's society, one of the main concerns about **artificial intelligence** is its impact on the workforce.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image53.png)

Headlines often claim that the **workforce** is threatened by robots replacing jobs. However, the reality is more complex. Denying the impact of job displacement is wrong—every major technological transformation in human history has changed labor markets, sometimes even causing serious consequences including social unrest. But such transformations are often inevitable.

A notable change in recent years is **generative artificial intelligence's** impact on white-collar jobs, especially software engineering and analytical positions, rather than manual labor. While labor market transformation is undeniable, it's equally important to recognize the potential benefits AI may bring.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image54.png)

We fundamentally face **labor shortages** in many industries, especially in elderly care and healthcare. With advances in modern medicine extending life expectancy, social aging inevitably results—this was originally positive development. However, this exacerbates labor shortage conditions.

Young people must work to maintain economic vitality, but who will care for the elderly and chronically ill? Even in US hospitals, the loss of medical staff, especially nurses leaving, leaves us without sufficient personnel, listeners, and observers to help patients.

Rather than focusing on replacing human labor, we should think about how to enhance human workforce through **artificial intelligence**, as demonstrated by my operating room example.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image55.png)

Indeed, there are many areas in healthcare with insufficient human supervision. These are what I call **medical dark zones**, covering operating rooms, wards, pharmaceutical environments, and home care. The ensuing question is: how can **artificial intelligence** help address these challenges?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image56.png)

This is an area where **Isang** and **Zing** jointly led important research. We've been exploring the concept of **ambient intelligence** in healthcare, combining smart sensors with machine learning algorithms to obtain health-critical insights from clinical environments.

This technology can promptly alert patients, families, or doctors to enable rapid intervention. Detailed discussion can be found in our paper published several years ago. Let me give a few specific examples below.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image57.png)

One example is the **hand hygiene project**, which was launched well before the COVID-19 pandemic. **Hand hygiene** is crucial for reducing hospital-acquired infections, which are one of the leading causes of patient death in US hospitals. These infections claim more than three times as many lives annually as traffic deaths nationwide and are difficult to control. Most pathogens spread between wards and multiply there.

Hospitals initially tried using human supervisors, but this approach wasn't practical due to nursing staff shortages and human limitations (like fatigue and inattention). **Technical solutions** were also explored, such as RFID badges. When wearers approach handwashing stations or hand sanitizer dispensers, these badges trigger prompts, suggesting hand hygiene compliance. However, this method lacks precision—proximity doesn't equal actual behavior, especially in confined spaces like wards and corridors.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image58.png)

Several years ago, we conducted a project involving **smart sensors**, designed to protect privacy by collecting only depth information, similar to the blue screen technology demonstrated in the accompanying video.

Subsequently, we used **computer vision algorithms** to classify behaviors, such as determining whether a person is washing their hands.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image59.png)

Research results showed that when comparing algorithm output with manual detection results, **algorithms significantly outperformed humans in accuracy and consistency**. To achieve performance levels comparable to AI, four human observers needed to watch the same video simultaneously. With only a single observer, detection results were significantly sparse.

This is just one application scenario. We also explored the intensive care unit (ICU) field. ICUs are critical places where patients battle life-threatening conditions, accounting for 1% of total US healthcare spending. Improving ICU efficiency and safety is crucial, with one core goal being ensuring patients can safely transition to downgraded care units or return home.

Research shows that standardized patient movement called **activity therapy** plays an important role in recovery. But this process involves complex factors like nurse assistance, medical order execution, precise timing control, and movement assessment, making activity therapy difficult to implement effectively.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image60.png)

We collaborated with **Stanford University** and Intermountain Healthcare in Utah to deploy these smart sensors in intensive care units.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image61.png)

Artificial intelligence can assist doctors in monitoring patient movements, specifically including **four behaviors**: getting in and out of bed and getting up from chairs. These movements are crucial for intensive care patients, though they may seem trivial to ordinary people.

AI's ability to identify and predict such movements is extremely valuable, especially during **labor shortages**. Another key application is supporting **aging in place**, helping elderly people achieve autonomous healthy aging at home.

The COVID-19 pandemic exposed the vulnerability of the aging population, with many deaths directly related to healthcare system overload.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image62.png)

Ensuring safety and health of elderly people at home is crucial. **Smart sensors** can assist with early infection detection through technologies like thermal imaging cameras, while monitoring mobility (similar to ICU applications), sleep patterns, and dietary routines. These areas are where **artificial intelligence** and smart sensors show enormous potential.

However, smart sensors alone cannot solve labor shortage problems. While they excel at information collection, they cannot provide physical care like turning patients, bringing water, or delivering medication. This leads to the final technical topic: **embodied intelligence**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image63.png)

A significant part of **embodied artificial intelligence** is robotics, which particularly excites me because it forms a closed loop between perception and action.

Think of the **Cambrian Explosion** in evolutionary history: the emergence of eyes coincided with animals beginning to move. Robotics enables us to connect vision and action in similar ways.

However, this field still faces major challenges. Despite our enthusiasm for robots, they remain slow, clumsy, and difficult to adapt to generalized scenarios.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image64.png)

In today's robotics research field, the discipline has made **significant progress**. Stanford University is undoubtedly one of the leading research centers in robot learning. However, most of this research is still limited to experimental setups, mainly focusing on short-term tasks like pick-and-place. Additionally, they often rely on case-by-case experimental configurations, lacking **standardized benchmarks**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image65.png)

Let me share several projects from our laboratory. Several years ago, we explored how to deploy robots in unstructured environments. Pre-specifying task sets proved limiting. In contrast, today's large language models (LLMs) can operate in completely open contexts. My student Wenlong Huang and colleagues are dedicated to bridging this gap.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image66.png)

The **core idea** is how to provide open-ended instructions to robots without pre-training for all possible scenarios in constrained environments.

For example, if the training set includes opening specific types of doors, how can robots generalize this skill to various different door configurations in the real world?

The **goal** is to achieve strong generalization capabilities in unstructured environments.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image67.png)

Here are the overall algorithm results.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image68.png)

The goal is to guide the robotic arm to open a drawer by planning a motion trajectory that avoids the **vase**. Notably, these instructions are not pre-trained.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image69.png)

We leverage the latest advances in large language models (LLMs) and vision-language models (VLMs). This method generates instruction sets through LLMs and VLMs, where vision-language models assist in environmental recognition and understanding, then convert this into motion planning graphs for robotic arm execution.

By combining the dual advantages of LLMs and VLMs, we can achieve more generalized performance in real scenarios without training robots in closed environments.

For example, when receiving the instruction "open the top drawer," the large language model converts it into executable code. Based on keywords like "drawer" or "handle," this information is passed to the vision-language model, which detects these objects in the scene.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image70.png)

Therefore, it updates its information and **subsequently** adjusts the motion map.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image71.png)

This process is visualized through **heat maps**, marking areas the robotic arm should focus on and should avoid.

Subsequently, you give another instruction, such as "be careful of the vase." This process cycles: the large language model (LLM) generates code, then the vision-language model (VLM) processes it.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image72.png)

The **VLM model** detects objects and updates the motion planning map. In this scenario, the update is negative rather than positive, because the goal is to avoid detected objects.

By integrating with prior maps, **heat maps** are generated to mark areas to avoid and navigable areas. This process is then applied to motion planning maps, adjusting rotation angles and gripper speeds.

Here are the final output results. Let me demonstrate this process.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image73.png)

This is the **actual operation result** of the robot. We repeated this process for many different tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image74.png)

We were able to achieve **articulated object manipulation** in various scenarios, such as handling napkins, sweeping floors, setting tables, or dealing with network interference. This fully demonstrates the **versatility** of this method.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image75.png)

Another work I want to highlight is the current state of **robotics research**, which still lacks robust benchmarking. While experiments are conducted in controlled laboratory environments, the real world presents far more complex unpredictability and variability.

Additionally, real-world scenarios are highly interactive, social, and involve numerous multi-tasking challenges.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image76.png)

We recognize that both **natural language processing** and **computer vision** fields have greatly benefited from establishing large-scale datasets for training and benchmarking.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image77.png)

In our laboratory, we've been developing an **ecological robot learning environment**. This project aims to encourage researchers to benchmark against large numbers of diverse activities. Specifically, we focus on **behavioral benchmarking**, which evaluates daily household tasks in virtual, interactive, and ecological scenarios.

Given this lecture's emphasis on human values, a key question emerges: **who decides which tasks robots should perform?** While many robotics graduate students prioritize laundry and dishwashing, we must consider broader application scenarios beyond academic environments. What tasks should robots ultimately undertake for society?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image78.png)

We didn't compile task lists ourselves but conducted **human-centered research**, directly asking people what tasks they want robots to help with. For example: Would you like robots to clean kitchen floors? Most respondents gave positive answers.

Other tasks included shoveling snow, folding clothes, and making breakfast—though for the last one, people's answers were divided.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image79.png)

Regarding unwrapping Christmas gifts, people's preferences varied. While robots might excel at this task, it's not what we desire. For example, one task we once considered was **buying engagement rings**—can you imagine?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image80.png)

Our approach aims to respect **human preferences**. We aggregated government survey data from the US Bureau of Labor Statistics and EU Statistics Office, compiling thousands of daily activity tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image81.png)

We conducted an online survey to recruit participants, striving for **maximum diversity**, though there's still room for improvement. A total of 1,400 people participated in completing tasks and indicated which tasks they want robots to help with. We then ranked these responses.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image82.png)

You can observe that, similar to students, people want robots to help with cleaning tasks—**deep cleaning**, including toilets and floors. However, tasks like playing squash, buying engagement rings, or preparing baby cereal have lower priority.

Many tasks have **emotional or social significance** for humans. Our goal is to establish a principled approach, selecting one thousand tasks for training robots from tasks humans are more inclined to receive assistance with.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image83.png)

With this in mind, we must construct **virtual environments**. We scanned and collected 3D data from 50 different real-world scenarios, covering various venues like restaurants, apartments, grocery stores, and offices.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image84.png)

We obtained over **10,000 3D object assets**, each with multiple attributes including joint mobility and deformability. Subsequently, we developed a simulation environment to adapt these assets.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image85.png)

Many researchers have developed various simulation environments. **Our specific project** collaborates with NVIDIA's Omniverse team, aiming to create a simulation environment with high physical, perceptual, and interactive fidelity. This environment needs to consider effects like **thermal transparency** and deformability.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image86.png)

We also conducted human user studies to compare and evaluate the **BEHAVIOR** environment with other environments from a perceptual realism perspective.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image87.png)

Here are some examples of physical interactions, such as **fabric** or **liquids**. This work incorporates **significant nuances**. Please allow me to continue.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image88.png)

Here are some **benchmarks** we conducted compared with other research. I'll go through them quickly.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image89.png)

This is ongoing work in our laboratory. We're using the **BEHAVIOR** platform to advance robot learning, collect more comprehensive data, and apply it to cognitive research. Please allow me to continue explaining.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image90.png)

It's important to note that **existing algorithms** still cannot effectively execute behavioral tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image91.png)

In all these roles, the **core goal** is to have robots execute tasks without any privileged information. They must be placed in environments and complete these tasks autonomously.

We benchmarked three BEHAVIOR tasks using current robot algorithms, with minimal performance results. However, when introducing additional privileged information or simplified assumptions—such as magic motion or perfect memory—performance improves.

If focusing only on the top result row, the current state of robotics might be discouraging. But as a **graduate student**, I hope you can find inspiration from this, because it marks enormous room for growth and progress.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image92.png)

These are various papers from our laboratory. Since this topic has been sufficiently discussed, I'll quickly advance the explanation. Additionally, we're developing **digital twin** technology for simulating behaviors in digital environments and the real world.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image93.png)

This provides an excellent method for testing **real-to-simulation transfer**, which remains an unsolved challenge requiring significant progress.

In this demonstration, the robot attempts to clean the room at its current slow speed. Despite its efforts, it still exhibits several **errors**: failing to successfully pick up bottles and earlier navigation mistakes, placing items in wrong positions. These errors highlight ongoing challenges in this field.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image94.png)

Let me fast-forward. We're also using this environment to study **visually impaired patients**. This is an **effective method** for observing patients in safe environments.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image95.png)

The final demonstration I want to share is particularly impressive. This showcases our latest collaboration with psychologists and medical professionals—exploring **brainwave-controlled robotics**.

In this demonstration, a graduate student wears an **EEG cap** to transmit instructions. Amazingly, the robotic arm can prepare Japanese cuisine through thought commands alone, without any invasive brain-computer interface throughout the process. The entire system operates solely on electrical signals.

To achieve this, we pre-trained the robotic arm to recognize specific thought patterns corresponding to actions like lifting, placing, or putting down objects.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image96.png)

Once achieved, this would represent a meal prepared entirely through **wave-based technology**, a concept almost science fiction.

This breakthrough occurred last year, and I'm particularly excited about integrating **vision**, **perception**, and **robotics** to assist individuals in clinical environments.

The future potential of this technology lies in its ability to help severely paralyzed patients.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image97.png)

The **BEHAVIOR** project aims to enhance human capabilities. It serves as a large-scale, diverse benchmarking platform with realistic and ecologically valid physical simulation and perceptual systems.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec18_image98.png)

The **key point** is that our goal in building artificial intelligence is not merely to execute tasks or perceive the world, but to help humans. Crucially, AI should serve as an **augmentation tool** to enhance human capabilities rather than replace us.
