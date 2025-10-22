---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 17: Robot Learning"
date: 2025-09-11T13:30:35+08:00
draft: true
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image1.png)

We're delighted to bring you the final guest lecture of this course. Today, we welcome **Dr. Yunzhu Li**—Assistant Professor of Computer Science at Columbia University, who also leads the **Robot Perception, Interaction, and Learning Laboratory**.

Dr. Li previously served as a lecturer for Stanford's CS231N course, conducting postdoctoral research under the guidance of Professor Fei-Fei Li and Professor Jiajun Wu at Stanford University during his 2023 teaching tenure. His research focuses on the intersection of **robotics**, **computer vision**, and **machine learning**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image2.png)

Specifically, his research focuses on the field of **robot learning**, aiming to significantly enhance robots' perception and physical interaction capabilities. In today's lecture, he will delve deeply into this topic.

Now please welcome Yunzhu Li to present today's lecture content.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image3.png)

Thank you for the warm introduction. I'm Yunzhu Li, very happy to be here. **The last time I taught here was in 2023**, which was two years ago. Recently I've been revisiting much of the course content.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image4.png)

Today, I will discuss some of my recent research work, which constitutes a coherent component of **deep learning** in the broader landscape of computer vision. Specifically, I will focus on **robot learning**, exploring the unique considerations involved in enabling robots to better perceive and interact with the physical world.

I will also highlight how these considerations differ from typical computer vision tasks and methods.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image5.png)

First, you already have a fairly deep understanding of **supervised learning**. Supervised learning scenarios and settings involve data \\(x\\) and \\(y\\), where \\(x\\) is the input and \\(y\\) is the label. The goal is to learn the mapping relationship from input \\(x\\) to output \\(y\\). Examples you've encountered include classification, regression, object detection, etc.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image6.png)

You've also learned about **self-supervised learning**, which doesn't rely on labels but directly uses unlabeled data. The goal is to design auxiliary loss functions and develop learning algorithms that can extract or identify the latent hidden structure of data.

Typical examples include **autoencoders** and many other methods in unsupervised or self-supervised learning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image7.png)

Given the massive amount of available unlabeled data, **robot learning** brings unique challenges. Unlike traditional learning tasks, robots must physically interact with the real world. This goes beyond simple input-output mapping or latent representations, requiring direct interaction with the environment.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image8.png)

It revolves around the impact of **environmental evolution**. Regardless of what actions are taken in the real world, the environment will change accordingly, providing new observations or rewards to indicate how it evolves and how efficiently tasks are executed. The goal is to design a sequence of actions based on environmental feedback to maximize rewards or minimize costs.

**Robot learning**, especially in recent years, has attracted widespread attention in both academia and industry. Numerous startups including Physical Intelligence, Tesla Bots, and Figure have emerged, showcasing impressive demonstrations of robots performing complex tasks such as folding shirts, manipulating coffee beans, and executing human-like actions in the physical world. This field has attracted substantial investment and widespread attention.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image9.png)

Here are **robot learning** startups that have recently received substantial investment, dedicated to developing **general-purpose robots** capable of physical interaction with environments.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image10.png)

Not only startups, but many established companies are also heavily investing in robotics development programs aimed at developing **general-purpose robots** capable of high-performance physical interaction with environments. In today's lecture, I will outline the **key technologies** driving success and development in the current robot learning field.

We'll start with **problem modeling**: how to specifically define the challenges to be solved and formally establish models of robot-environment interaction. Then I'll discuss **perception technologies**, focusing on analyzing how robot environmental perception differs from traditional computer vision methods and the special characteristics of robot perception.

The course will then cover **reinforcement learning**, **model learning**, **model-based planning**, **imitation learning**, and the latest advances in robot foundation models. Finally, we'll examine the remaining challenges in this field. Now let's start with problem modeling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image11.png)

This is a general graphical illustration of the problem. At the center is an **agent** endowed with a **task objective**, which may come from human language instructions or an objective function measuring the agent's performance in completing specific tasks. The agent receives **state** information from the physical world or environment and decides what action \\(a_t\\) to execute. After this action is executed in the physical world, the state updates to \\(s_{t+1}\\). The agent also receives a **reward** \\(r_t\\) to evaluate its task execution effectiveness.

This framework contains four core elements: **objectives**, states, actions, and rewards, which together constitute the problem definition for robot learning scenarios. This contrasts sharply with the computer vision field—where the focus is on learning environmental representations from high-dimensional input data. Robotics needs to solve optimization problems under physical world constraints, with **objective functions** defined according to task objectives, and agents seeking action sequences that maximize or minimize this function. This difference highlights the fundamental distinction between robot learning and traditional computer vision methods.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image12.png)

Specific instances of this problem include the **inverted pendulum problem**, where the goal is to balance an upright pole on a movable cart.

The environment's state describes the system's physical state, including angle, angular velocity, position, and horizontal velocity. Actions consist of horizontal forces applied to the cart.

Each time step is assigned a reward to indicate whether the pole remains upright.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image13.png)

Another example is **robot locomotion**, where the goal is to make the robot move forward. The state might include angles, positions, and velocities of all robot joints. Actions might involve torques applied to each joint.

The **reward function** might assign a reward value for each time step when the robot takes a step forward while maintaining an upright posture.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image14.png)

An interesting example is **Atari games**, where the goal is to achieve the highest possible score. Game states are represented by raw pixel input from the screen, while actions correspond to game control commands like up, down, left, right. Rewards for each step are determined by score changes in the current time step.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image15.png)

Some well-known examples, like **AlphaGo**, exemplify this concept well. The goal can be similarly defined as winning the game, where states represent the current piece distribution on the board, and actions involve placing a piece. Rewards are allocated at the final step: 1 point for winning, 0 for losing.

This framework also applies to domains beyond games. For example, in **large language models**, sequence generation tasks can be handled using similar methods. Here, the goal is to predict the next word, states represent the currently generated sentence, and actions determine the choice of the next word. Correct predictions receive rewards, while incorrect predictions get zero points.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image16.png)

Similarly, you may have had extensive interactions with various chatbots. You can define an objective question, which is to act as an **ideal companion** for human users. The state can be the current conversation content, and the action generated by the chatbot is the next reply provided to the user. Based on human evaluation, rewards can be defined as follows: if the user is satisfied, the reward is 1; if the attitude is neutral or dissatisfied, the reward value is adjusted accordingly.

More specifically, in the **robotics domain**, tasks might involve operations like folding clothes.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image17.png)

Our goal is to have clothes neatly folded. The current observations the robot receives from the environment might include multi-view RGB or RGBD information. The robot then needs to decide its actions, such as how to move the end effector—whether to open or close the gripper to manipulate the fabric. Based on human evaluation criteria, if the clothes are correctly folded, the robot will receive a **1-point reward**, otherwise zero points.

This scenario demonstrates the **specific implementation path of robot learning**: agents interact with the environment, consider the impact of actions, and solve sequential decision problems. This contrasts sharply with traditional computer vision tasks, which only focus on predicting output results.

When solving problems in this field, we must comprehensively consider **objectives, states, actions, rewards, and objective functions**. This framework constitutes the core elements of robot learning problem modeling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image18.png)

This problem involves how precisely the reward function needs to be designed.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image19.png)

In many tasks, **reward functions** can be set in different ways. For example, in autonomous driving scenarios, rewards might focus on vehicle speed or passenger comfort; in clothing folding tasks, user preferences determine reward criteria—whether to minimize total folded area or maximize flatness.

Although I discuss in general terms (such as whether folded clothes are neat and beautiful), **reward design** requires careful consideration to meet the special needs of specific application scenarios.

I will continue to expand on this.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image20.png)

This is our approach to solving robot learning problems, aimed at enabling agents to interact with the physical world.

Now, I will discuss **robot perception**, focusing on analyzing how perception in robot learning differs from traditional computer vision.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image21.png)

You'll see this image repeatedly throughout today's lecture.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image22.png)

This fundamentally addresses how we handle information obtained from the **physical world**. The physical world provides high-dimensional RGB or RGBD observation data and may also contain other sensory information, such as tactile feedback.

The **core challenge** lies in how robot perception extracts structured knowledge from these high-dimensional inputs to support downstream robot decision-making.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image23.png)

The core challenge we're committed to solving is interpreting this highly complex unstructured real world. **Environmental observation data received by robots** is often incomplete in understanding objects and surrounding environments due to factors like occlusion or sensor errors. **Imperfect execution actions** may cause mistakes—for example, robotic arm grasping objects may not always succeed, and accidental drops may cause unpredictable changes in the environment.

Our **perception systems** must adapt to such scenarios, not only considering rigid objects but also dynamic environments composed of deformable objects like clothes, ropes, and particles. Additionally, interactions between other agents like humans, animals, or children with the environment further increase complexity. This perception system must have robust capabilities to handle all these variables.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image24.png)

In robotics, researchers typically don't rely solely on camera data. As long as sensors can provide useful information, they integrate as many types of sensors as possible into robots, including **tactile sensing**, audio data, depth information, etc.

The real challenge lies in designing systems that can effectively fuse these sensors to make their functions complementary. For example, **audio data** can reflect physical environmental characteristics, tactile feedback can show grasping stability, while **visual data** provides high-level information about the overall environmental state.

How to combine and coordinate these sensors is crucial for developing robot systems that can operate efficiently in the real world.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image25.png)

Beyond differences in the number of perception modalities, the core distinction between **robot vision** and **computer vision** lies in understanding action impact and environmental complexity. The left side shows typical computer vision tasks: instance segmentation. Given a 2D image, the goal is to segment different instances by outlining pixel boundaries.

However, in robotics, the scenario is completely different. For example, as shown on the right, a robot might encounter an object that appears singular but is actually composed of multiple stacked components. The robot must determine which actions can optimize its perception of the environment—whether this object is an independent entity or a composite structure. For this purpose, the robot might perturb or actively interact with the environment to improve its understanding of object states.

This reveals why robot vision is **embodied**, **active**, and **contextual**:

- **Embodied**: Robots have physical forms that directly interact with the world, and their actions dynamically affect sensory feedback
- **Active**: Robots are active perceivers, capable of autonomously deciding what to perceive, how to perceive, and when and where to act. For example, by adjusting their own posture to observe objects behind tables, this contrasts sharply with computer vision that relies on passively collected datasets
- **Contextual**: Robots operate in the real world, handling immediate specific interactions rather than abstract descriptions. Their perception and action loops are tightly coupled, requiring real-time understanding of environmental states



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image26.png)

Robots perceive the world, understand their goals, and take actions based on these perceptions. In some cases, robots don't need to fully understand environmental information. For example, when buttoning shirts, they only need to focus on the local area near **buttons**.

Therefore, **perception systems** must be tightly coupled and co-designed with tasks and downstream decision systems. This ensures robots focus their attention on task-relevant areas in the environment, forming closed-loop perception-action circuits.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image27.png)

This lecture focuses on the specific differences between **robot perception** and traditional computer vision. I will introduce algorithms that enable robots not only to perceive environments but also to interact with them.

We'll start with **reinforcement learning**. Please recall the image we analyzed earlier.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image28.png)

**Robots** must act in their environment and receive corresponding rewards based on their behavior. Common methods for solving this optimization problem require robots to engage in extensive interaction with the external world.

Through trial-and-error collection of **experience data**, robots learn which actions bring higher returns and which lead to lower gains. This process enables us to guide agent behavior toward actions that maximize rewards.

These principles constitute the foundational framework of **reinforcement learning**—agents continuously interact with the environment, optimizing action strategies through repeated trial and error to achieve optimal results.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image29.png)

Let me elaborate on the differences between **reinforcement learning** and **supervised learning**.

In reinforcement learning, the framework typically includes an environment that provides states to the agent. After the agent generates actions, the environment provides feedback in the form of rewards and transitions to a new state at time *t+1*. This forms a time series where the agent must make continuous decisions throughout this process.

In contrast, supervised learning follows a different paradigm. The dataset provides input *X* to the model, the model generates prediction *Y*, and loss is calculated by comparing prediction results with true labels in the dataset.

There are several key differences between these two methods:

1. **Environmental randomness**: The environment in reinforcement learning may be stochastic. The same action may produce different results due to environmental uncertainty. For example, when pushing a box, the same applied force may cause different rotation angles due to different support force distributions. This contrasts with the determinism of supervised learning.

2. **Credit assignment**: Supervised learning provides immediate feedback through direct loss calculation, clearly indicating prediction errors. Reinforcement learning often faces delayed reward problems. Taking game scenarios as an example, final win/loss results only appear at the end of rounds, but this result may stem from an action in the early sequence. How to correctly attribute credit in sequential decisions becomes an important challenge.

3. **Differentiability**: Supervised learning has the advantage of end-to-end differentiability—input is processed by the model to produce output, and loss can be directly calculated and backpropagated. Reinforcement learning may not always maintain this characteristic when handling complex dynamic systems.

These fundamental differences explain why reinforcement learning requires adopting methods and algorithms that are completely different from supervised learning.



You can directly calculate the gradient of the loss function relative to model parameters. However, in **reinforcement learning** this is usually not feasible because environments are often non-differentiable. Therefore, estimating gradients of rewards relative to actions becomes extremely challenging. In such cases, practitioners typically need to rely on extensive sampling for zero-order gradient approximation to achieve effective learning.

Another **key difference** lies in the non-stationary nature of these scenarios. In reinforcement learning, environmental state evolution is directly affected by actions you take. In contrast, predictions in supervised learning don't affect subsequent data points in the dataset. This dynamic interaction makes sequential decision problems in reinforcement learning more complex and subtle than supervised learning.

Here are some specific examples to illustrate these differences.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image30.png)

For example, taking the previously mentioned **Atari games** as an example. The goal is to achieve the highest score. **States** are raw pixel inputs from the screen, **actions** correspond to keyboard inputs like up, down, left, right. **Rewards** are determined by score changes in each time step.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image31.png)

Typical algorithms in this field include **Q-learning** and **policy iteration**. For example, Q-functions measure the discounted expected value of future cumulative rewards when executing action \\(A\\) in state \\(S\\). These Q-functions are obtained through interaction with game environments. Once learning is complete, you can evaluate Q-values corresponding to different actions (like left, right, up, down) and execute the action with the highest Q-value, thereby achieving effective decision-making.

Given the breadth of today's course content, we won't delve deeply into reinforcement learning. But it's worth noting **state-of-the-art algorithms** like Soft Actor-Critic (SAC) and Proximal Policy Optimization (PPO), with many open-source implementations and tutorials available online.

To demonstrate the potential of reinforcement learning, take Google DeepMind's Q-learning research as an example. They trained agents playing the Atari game Breakout, initially struggling to even hit the ball after 10 minutes of training. But after two hours, it could reliably control the paddle, consistently catch the ball and maximize rewards. After four hours, the agent developed an **innovative strategy**: creating a tunnel on the left side of the wall through precise rebounds.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image32.png)

The agent would push the ball along the upper wall to efficiently reduce the number of bricks. This **strategy** can be discovered through **reinforcement learning**, which enables extensive exploration and interaction with the environment. As demonstrated in games like Go, reinforcement learning agents can develop strategies that surpass top human players.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image33.png)

When **AlphaGo** emerged in January 2016, I was at a stage of determining my research direction. Previously, my research focus was **deep learning** in computer vision. But AlphaGo's emergence prompted me to turn my attention to **decision problems**.

This opened my exploration of **reinforcement learning** and **imitation learning**, ultimately leading me to the field of **robot learning**—enabling robots to have actual interactions with physical environments. I wasn't satisfied with working only on passively collected datasets but hoped to develop agents capable of actively interacting with environments.

The core question is: *How exactly does this **Q-function** work?*



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image34.png)

The **Q-function** takes state \\(s\\) and action as input, where \\(\theta\\) represents the parameters of this Q-function, specifically implemented as a neural network. Here, the state consists of raw pixel input from game screens, specifically, four consecutive frames are input to the Q-function.

For image-based input, one direct implementation of Q-functions is using **Convolutional Neural Networks** (as shown by the orange modules in the figure). These convolutional layers are followed by fully connected layers for computing Q-values.

Since there are four discrete actions (such as up, down, left, right), the network outputs independent Q-value estimates for each action. These estimates are used to guide selection of the most effective action that maximizes Q-values.

This method became widely known through **AlphaGo**, which became an important milestone in AI development history. Subsequent improvements gave birth to **AlphaGo Zero**—this simplified version eliminated the imitation learning initialization step and defeated top human players like Ke Jie. This evolution confirmed Rich Sutton's **"bitter lesson"**: simplicity and scalability often bring better performance.

Thereafter, **AlphaZero** extended the same algorithm to games beyond Go (such as chess and shogi). Further optimization produced **MootZero**, which achieved superior performance by introducing latent space dynamic models for planning. These advances profoundly influenced the design of reinforcement learning agents with higher sample efficiency and stronger scalability in game applications.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image35.png)

In November 2019, **Lee Sedol**, who had lost to AlphaGo, announced his retirement, admitting that no human player could surpass the strength of the most advanced **AI agents** at that time.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image36.png)

Since then, more complex games like **StarCraft** and **Dota** have proven that with sufficient computational resources, well-designed algorithms, and powerful reinforcement learning infrastructure, excellent performance can be achieved even in games much more complex than Go. This indicates that with sufficient resources, extremely capable game agents can be developed.

Beyond the gaming domain, reinforcement learning algorithms and agents have been applied to real-world physical scenarios. A typical case is research from **ETH Zurich** published in Science Robotics in 2020, which changed perceptions of reinforcement learning's practicality in physical robots. Previously, reinforcement learning was mainly limited to infinitely replicable game environments, but this paper proved that the gap between simulation and reality might be smaller than assumed. Agents trained in simulation environments still showed robust performance in real-world conditions like icy and slippery roads.

**Unitree's** latest cases demonstrate advanced motion control capabilities, enabling robots to perform dynamic behaviors in complex terrain. This means reinforcement learning has almost conquered robot motion control challenges.

In robot manipulation, **OpenAI's** 2019 Rubik's cube dexterous manipulation system achieved simulation-to-reality transfer. But extremely low success rates and limited trials in the research raised questions about its reliability. Despite impressive visual effects, practical applications still have obvious limitations.



Since then, researchers have expanded **dexterous manipulation** capabilities, enabling robots to grasp and reorient various objects to different target poses, mainly benefiting from advances in reinforcement learning. However, current cases in locomotion and hand manipulation are still limited to single domains and don't cover broader tasks like folding clothes or household laundry.

These limitations highlight **key challenges** facing existing **model-free reinforcement learning**—this method heavily relies on trial-and-error mechanisms in constrained environments and requires extensive interaction with the world. For example, AlphaGo Zero condensed three thousand years of accumulated human knowledge into 40 days of computation, but for agents to learn effectively, such methods still require computational resources equivalent to several years.

Significant bottlenecks occur in domains with huge **symmetry differences**, where reinforcement learning in real physical worlds is inefficient. Additionally, learning directly in real environments raises safety concerns. For example, when humanoid robots learn to walk forward, agents exhibit unstable behavior before success. Deploying such agents on physical robots could lead to catastrophic failures.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image37.png)

Additionally, it has limited interpretability, making it difficult to correct when errors occur.

An interesting observation is the contrast between how humans learn to interact with environments and **pure reinforcement learning**. Humans have intuitive understanding of their surroundings and can predict environmental changes caused by specific actions.

This **predictive ability** enables humans to effectively plan behaviors to achieve goals. More importantly, this ability is acquired through physical interaction and daily experience in the real world.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image38.png)

Beyond reinforcement learning, the next topic I'll discuss is how to enable robots to have the ability to **imagine the consequences of their actions** and execute model-based planning. For this purpose, we use simulation systems like **ISAC-GIM** or **ISAC-SIM** developed by NVIDIA. These simulations mainly involve rigid body dynamics, where robots interact with polygonal surfaces like floors but don't simulate elements like bushes or snow.

To enhance robustness, researchers extensively randomize simulation environments by changing **friction**, **geometry**, and other physical parameters. The basic assumption is that any real scenario is just a data point in the distribution of randomized simulation environments. If a strategy can robustly control robots within this distribution range, it should effectively generalize to real conditions. Empirical evidence supports this assumption, showing strategies have reliable and robust performance in physical environments.

A common question involves actual commands sent to robots. In many existing demonstrations, **human operators** provide high-level instructions to guide robot behavior.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image39.png)

For example, robots must decide walking direction based on **high-level actions** specified by humans—whether to rotate in place or continue forward. Low-level actions such as joint torques applied to each joint originate from strategies adjusted by robots based on high-level instructions.

A **key finding** in motion control research is that simulation doesn't need to pursue perfection—sufficient randomization can achieve robust generalization to real environments. But this principle hasn't been fully extended to robot manipulation domains. The accuracy of simulation and the importance of **simulation-reality gaps** remain unresolved research topics.

For example: if a box rotates 10 degrees in simulation but 12 degrees in reality, this difference might be insignificant; but if a successful grasp in reality fails in simulation due to numerical instability or object slippage, this gap becomes crucial. Therefore, in manipulation tasks, certain aspects of simulation-reality gaps are more decisive than others. Researchers continue exploring the fundamental causes of this gap and simulation characteristics needed for reliable real-world transfer.

Regarding whether robots can surpass human planning capabilities, the answer has subtle differences. Although robots execute low-level actions based on high-level instructions provided by humans, their ability to optimize these plans remains an area to be explored.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image40.png)

Although these videos look impressive, **human operators** often participate in robot path selection. For example, when encountering rocky terrain or obstacles, operators can instruct robots to attempt climbing. If unsuccessful, they might issue alternative high-level instructions to bypass obstacles.

This process also allows humans to understand robot capabilities. Therefore, these videos effectively demonstrate the **limitations and advantages** of low-level controllers, because human-chosen routes highlight these characteristics.

How to achieve autonomous completion of this challenge remains an active area of current research. I will now continue.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image41.png)

I've discussed successful applications of **reinforcement learning** and its limitations. However, we haven't witnessed its widespread deployment in robot manipulation domains.

Unlike humans—who not only learn through trial and error but also build **internal models**—we explore whether robots can also learn models from interaction with environments. These models can then enhance robots' physical interaction capabilities.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image42.png)

Specifically, the current topic focuses on learning approximate representations of the real physical world and how this **virtual approximation** can guide robot behavior in the real world.

For example, if we already have a model similar to human mental models, we can predict how environmental states evolve from time \\(t\\) to \\(t+1\\) given action \\(t\\). This constitutes a **forward model**—predicting the next state based on current state and action.

**Planning problems** are essentially the inverse process of forward models: we need to determine the action sequence required to transition from the current state (blue dot) to the target state (red dot). Initial action guesses can be optimized by using learned models to predict state evolution (green trajectory) and minimizing the distance between predicted states (green) and target states (red) based on gradient methods.

Since models may have errors, usually only the first action is executed. After observing new states, techniques like **gradient descent** are used to re-optimize action sequences.

Recent research uses GPUs and neural dynamic models to achieve **parallel sampling**, supporting large-scale action sequence optimization.

Under this framework, forward models derive action sequences approximating target configurations through inverse optimization. The core question is: what environmental representation is optimal? Over the years, extensive research has continuously explored this challenge for different state representation schemes.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image43.png)

Early research explored using **2D images** as state representations and learning pixel dynamics—predicting how images change after applying specific actions. This research titled *Deep Visual Foresight* laid foundational work in the **world model** field. By learning pixel-based dynamic models, researchers developed strategies that minimize distance between current observations (shown in red) and target states (shown in green), thereby achieving tasks like object rotation and manipulation.

Additionally, **keypoints** can serve as environmental representations for learning keypoint dynamic models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image44.png)

Here, we can track **keypoints** on boxes moving in 3D space and learn **dynamic models** of these keypoints through pushing actions. This enables robots to use forward prediction models for behavior planning, with the goal of tracking specific trajectories to push boxes to target configurations.

However, how do we handle objects with higher degrees of freedom?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image45.png)

By adopting **finer representation levels**, objects can be modeled using **particle collections**—that is, collections of points. This method originated from research I conducted during my postdoctoral period, where we represented granular materials as particle collections to predict their motion under external forces. The forward model constructed from this enabled robots to make inverse decisions, adapting to diverse granular objects of different sizes.

We developed strategies to aggregate these particles into target regions, as shown in the bottom right of each segment. With **environmental feedback**, the same model enabled robots to correct prediction errors and develop highly reliable strategies to converge all particles to specified areas.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image46.png)

This model can generalize to **granular objects of different sizes** and adapt to different target configurations. Robots must develop strategies for non-trivial redistribution operations on these particles. After redistribution, **fine details** must align with target shapes to complete stacking rearrangement tasks.

Specifically, this task involves rearranging granular objects into **letter shapes from A to Z**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image47.png)

With such forward models, we successfully designed a series of strategies—by incorporating environmental feedback—enabling robots to rearrange object components to target areas. **This task is extremely challenging.** Additionally, during my time at Stanford, I participated in subsequent related research work.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image48.png)

We designed a **dumpling-making robot** equipped with 15 different 3D-printed tools. Four RGBD cameras observe the environment to reconstruct the geometric shape of dough. The robot then needs to decide which tool to use and what actions to take to shape the dough into dumplings.

**Key implementation elements** include forward prediction models using particle representations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image49.png)

**Red dots** represent tool contours, while **blue dots** depict object shapes.

The first row shows **open-loop prediction** results from our model, while the second row presents actual effects in the real environment.

This learned model, trained through real-world interaction, can accurately predict dough deformation under different tools and operations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image50.png)

This integrated system enables robots to make dumplings with dough. Notably, in this video, someone continuously interferes with the robot's operations. The robot uses **real-time visual feedback** to perceive dough shape and predicts through learned dynamic models how the environment (especially dough morphology) will change when using tools to apply specific actions.

Based on this forward model, the robot makes inverse decisions at two levels:
- **High-level decisions** select appropriate tools (task-level decisions)
- **Low-level decisions** determine precise actions needed to advance to the next task stage (motion-level decisions)

Despite human interference (such as adding dough pieces or folding dough), the robot still demonstrates excellent robustness in continuous operation. For example, when the robot cuts circular dough skins, humans disrupt the current setup, forcing the robot to restart the task from the beginning, highlighting the system's **tolerance and fault tolerance** to external interference.

These capabilities are driven by **neural dynamic models** that can predict dough shape evolution processes under specific actions. Finally, the robot places the dumpling skin on clamps, moves in filling, and completes sealing with hooks, demonstrating how general-purpose robots equipped with 15 tools can learn models and apply them to downstream model-based planning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image51.png)

For this specific situation, if we want to describe it more rigorously, we didn't use **reinforcement learning**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image52.png)

We learned models and used them for planning. Although plans can be refined into strategies for more efficient execution in real environments, some might call this **model-based reinforcement learning**. Depending on context, you might call it model learning and model-based planning, or model-based reinforcement learning. The **core idea** is learning models from robot-physical world interaction and using this learned model to guide robot decision-making for task advancement.

In this framework, high-level planning and low-level decisions are handled by two independent models. At the high level, given current state and environmental observations, the robot uses a **classifier** to decide which tool to adopt. Based on this classification result, low-level strategies select specific actions to advance to the next task stage.

This research was conducted in 2023 when vision-language models weren't yet developed. For this purpose, human operators performed tasks 10 times to collect data, subsequently used to train tool selection classifiers. This method enabled robots to recover from interference—for example, when humans interfere after the robot completes drawing circles, the system can revert to earlier stages based on current observations.

This methodology combines **sample-based trajectory optimization** with strategy learning. Given the current state of dough, forward prediction models sample actions and tools to predict shape evolution. These prediction results are compared with target shapes (similar to previous examples where green dots represent predicted shapes and red dots represent targets), achieving optimization by evaluating their distances.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image53.png)

This method enables us to select **the most effective actions** to get as close as possible to targets. We can generate large numbers of samples this way. However, sampling during testing is computationally expensive. Therefore, we choose to perform sampling offline to create datasets. These datasets are then used to train strategies that can quickly infer during testing. Strategies themselves are implemented as **neural networks**, obtained by distilling model prediction results from massive samples.

In this research, we didn't use any physics-based simulation. We compared our method with a baseline using the state-of-the-art deformable object simulator **MPM (Material Point Method)**. Research results showed that even through extensive system identification by estimating physics-based simulator parameters, the accuracy of resulting models was far lower than models trained directly from real-world interaction data. For example, as mentioned earlier, the first row shows open-loop prediction effects from our model.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image54.png)

The second row shows **ground truth**. Our model predictions highly match ground truth, demonstrating significantly higher accuracy compared to physics-based simulators.

If there are no other questions, I will continue. We've discussed model learning and its effectiveness in downstream model-based planning. The next class of algorithms is **imitation learning**. Briefly reviewing, we previously discussed reinforcement learning.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image55.png)

Learning strategies directly through trial and error with environments has several challenges, including **sample efficiency** and safety issues.

In contrast, **model learning** belongs to the supervised learning category. In this method, we use existing environmental evolution data to train models through supervised learning, then use this model for model-based planning.

Beyond using supervised learning for model training, researchers are also exploring its application in strategy learning. This concept is called **imitation learning**, whose core is using large-scale datasets demonstrating task execution processes to train such strategies.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image56.png)

I'll show this diagram again. It illustrates the process of learning **strategies**—strategies that take states as input and predict actions. Learning signals and processes originate from large-scale data collected by observing humans demonstrating task execution for robots.

**Learning from demonstrations** is a mature and well-established concept.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image57.png)

This topic has been researched for decades. It also reflects how humans learn to perform **physical interactions** and **social activities** in the real world from childhood.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image58.png)

One of the earliest classic imitation learning algorithms is called **behavioral cloning**. The goal is to learn the mapping from observations \\(O\\) to actions \\(A\\), represented by strategy function \\(\pi\\) with parameters \\(\theta\\).

A **key challenge** of behavioral cloning is **error accumulation**. Unlike supervised learning in computer vision, robot learning involves sequential decision processes where errors accumulate and amplify over time. Initial small errors may cause state distributions to deviate from training data, making strategies produce gradually increasing errors, ultimately significantly deviating from demonstration trajectories.

To solve this problem, imitation learning typically adopts the following process: first use expert demonstration data as supervised learning training data to train strategies, then deploy strategies in real environments to observe failure cases. By collecting additional data or corrective behaviors to expand datasets, ensuring they contain not only initial demonstrations but also corrective data that guide strategies back to successful trajectories. This **iterative process** is a typical method for developing practical imitation learning agents.

Since imitation learning lacks explicit task definitions (tasks are implicit in demonstration data), a class of algorithms called **inverse reinforcement learning** emerged. Traditional reinforcement learning focuses on learning strategies from rewards, while inverse reinforcement learning infers reward functions from demonstration data, enabling standard reinforcement learning to derive strategies.

Early breakthroughs in this field were achieved by Pieter Abbeel and Andrew Ng at Stanford University, who successfully controlled helicopters to perform high-maneuverability flight actions. Despite being from an earlier era, this research remains a **milestone** in physical systems achieving such behaviors.



This demonstrates the powerful capability of **learning from demonstrations**, which can be combined with reinforcement learning to summarize rewards, enabling us to achieve these results.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image59.png)

Over the years, **imitation learning algorithms** have become increasingly efficient, especially when combined with **energy-based models**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image60.png)

Unlike learning explicit strategies shown on the left, this method directly maps observations **\\(O\\)** to actions. By developing **implicit strategies** inspired by energy models (which predict scores through observations and actions), this method can obtain predicted actions **\\(A\\)** through inference.

This enables robots to handle **multi-modal demonstrations** or situations with non-smooth optimization scenarios. Robots can distill strategies from demonstrations to perform complex manipulation tasks.

A significant recent advance in robot learning is **diffusion policies**, which incorporate research achievements from generative models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image61.png)

For example, in research on **implicit behavior modeling**, researchers drew inspiration from the development of **energy-based models** in deep learning, a type of generative model. Another powerful class of models in this field is **diffusion models**, which are being adapted into strategy function classes, enabling agents to inherit their excellent properties.

This research began at Columbia University—my current workplace. The **principal investigator** of this project later moved to Stanford University. Notably, most selected achievements have deep connections with Stanford University, and this principal investigator now works in Stanford's Electrical Engineering Department.

This strategy demonstrates **diverse capabilities**, enabling robots not only to perform planar pushing actions but also complex manipulation tasks. These tasks go beyond simple grasp-and-place operations, covering complex actions like spreading butter on bread, scrambling eggs, peeling potatoes, and sliding books.

By collecting large amounts of demonstration data and adopting **advanced strategy learning mechanisms**, this method ultimately produced strategies that can operate efficiently in real physical environments.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image62.png)

You collect data in the morning and update strategies in the afternoon, enabling **functional strategies** to operate in the real physical world. However, **key considerations** include strategy reliability and generalization ability, as well as the diversity of initial configurations needed for robust performance.

Despite these challenges, **imitation learning** remains the most efficient method for developing strategies with practical application value. To ensure strategy effectiveness and robustness to real-world changes, iterative data collection processes must be implemented to handle unexpected or deviant behaviors.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image63.png)

This lecture focuses on **imitation learning**. If there are no other questions, I'll use the remaining time to discuss the latest advances in the **robot learning** field, particularly **robot foundation models**. This is a complex field where each topic deserves a separate course. Today I'll provide a brief overview, focusing on key concepts.

Robot foundation models are functionally similar to **reinforcement learning** and imitation learning, but unlike traditional models, they lack explicit state representations. For example, these models don't learn environmental dynamics but function as strategies mapping observation goals and actions. This relationship can be effectively visualized through accompanying diagrams.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image64.png)

**Agents** as strategies take current states and goals as input, generating actions that can be executed in the real physical world. Although this might resemble imitation learning and reinforcement learning, what's unique about **robot foundation models**?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image65.png)

This concept is deeply rooted in advances in the **foundation model** field, especially in language-related and vision-language-related foundation models. Essentially, it's a **strategy** aimed at having superior generalization capabilities compared to solutions designed for single specific tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image66.png)

Here's my definition inspired by current vision-language model development: although their outputs may not be perfect, they always generate reasonable responses based on prompts. Similarly, our goal in developing **robot foundation models** is to synthesize solutions that may not be absolutely optimal but can produce **elegant** and **reasonable** action trajectories in the real physical world. "Elegant" refers to smooth, continuous, non-jittery motion, while "reasonable" means following given robot language instructions.

This concept has many names, such as **Vision-Language-Action models (VOA)** or **Large Behavior Models**, but the core idea is consistent: generating action strategies that can generalize to diverse scenarios by receiving observation data and language instructions (or task specifications).

Currently, there's considerable noise in this field, making it difficult to quantify advances in robot foundation models. "Foundation model" implies broad generalization capabilities, which requires substantial evidence support, making evaluation and quantitative measurement quite challenging. However, from empirical videos, significant and specific progress has been made in recent years.

Early exploration began with **RT1** in December 2022, followed by new models emerging approximately every six months, such as **RT2**, **RTX**, **OpenVLA**, and more recently **PI0**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image67.png)

We're making **significant progress** in developing robot foundation models with stronger generalization capabilities. This year has seen numerous such models including **Helix**, **HyRobot**, **Gemini Robotics**, and **PI-Zero**. This field is experiencing extensive research and substantial investment, not only involving funding but also talent, aimed at advancing these models.

Due to time constraints, I can't detail each model individually. However, I recently gave a tutorial at **AAAI** specifically discussing some of these models. If you're interested, I recommend watching it. Today, I'll use PI-Zero as an example to provide a high-level overview of the core components of these foundation models.

**PI-Zero** was first released in October 2024. Its performance demonstrates the potential of robot foundation models to achieve reliable dexterous manipulation in real environments. The model performs excellently in tasks like cloth folding and box folding, reflecting its versatility and reliability. Here's a high-level overview of this framework.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image68.png)

The left side shows the dataset. Any model that wants to be considered a **foundation model** cannot do without a fundamental element—data. They aggregated massive data from academia and their own collection, covering various robot entities performing practical tasks in the real world. This data was used for the pre-training phase.

A key point in pre-training is that it starts with a **pre-trained Vision-Language Model (VLM)**. This model has been trained on massive vision-language data and has semantic knowledge transfer capabilities. Through joint fine-tuning—combining action prediction and visual question-answering dual objectives—the model retains semantic understanding capabilities while gaining new abilities to predict robot actions. This constitutes the core of the pre-training phase.

Many **crucial design characteristics** of robot foundation models lie in the post-training phase, inspired by developments in large language models. Although foundation models can provide reasonable baseline performance, achieving high performance on specific tasks still requires collecting task-specific data for fine-tuning. This post-training mechanism ensures excellent model performance on target tasks.

System evaluation is divided into three major categories:
1. **Foundation model**: Direct use of foundation models, which perform well on simple in-distribution tasks encountered during pre-training.
2. **In-distribution tasks**: Facing more complex in-distribution tasks, post-training can further improve foundation model performance.
3. **Unseen tasks**: Usually requires using task-specific data for post-training to adapt pre-trained models to these new tasks.

**PI-Zero models** are open-source, with checkpoints available for download and use.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image69.png)

Students in my laboratory have begun experimenting with our models and conducting subsequent training, achieving **encouraging results**. If you're interested, I strongly recommend you try it too.

This is an excellent question. You're actually asking about the **efficiency** of current robot foundation models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image70.png)

**Strategies** run slower than humans for multiple reasons. The primary reason stems from how demonstration data is collected—human operators typically perform tasks by remotely controlling robots (such as folding cardboard boxes), and this operation method is inherently more time-consuming than direct hand operation. This inefficiency stems from differences between remote operation interfaces and the body manipulation methods humans are most familiar with.

Another key factor is **visual occlusion** issues. Since robotic arms are in remote operation states, operators need to frequently adjust viewing angles to determine when to enter the next task stage. These limitations in data collection processes collectively lead to strategy execution speeds below human levels, which also drives active exploration of more efficient data collection methods in academia.

In tasks like folding cardboard boxes, considering task complexity, this strategy performance is already excellent. But to extend this method to broader scenarios (like folding clothes, making beds, or sweeping floors), relying solely on single holistic strategies may be insufficient. At this point, **higher-level abstract representations**, scene graphs, or symbolic representations may need to be introduced to effectively regulate vision-language-action models, adapting them to diverse tasks and environments.

This method is built on pre-trained **vision-language models**, fully utilizing semantic knowledge internalized by these models through large-scale pre-training.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image71.png)

This explains why certain **generalization capabilities** naturally emerge, because foundation models can achieve surprisingly good generalization at semantic levels. However, to ensure generalization not only at semantic levels but also at action levels, fine-tuning with robot datasets is necessary.

Due to time constraints, we can discuss questions later. In the remaining few minutes, I'll focus on several **key challenges** in robot learning model development.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image72.png)

One of the main challenges recognized by the community is **evaluation**. Evaluation is mainly conducted in the real world. For example, this is an image from Google's robotics team.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image73.png)

They adopted a grid of remote operation systems (such as **ALOHA**) for data collection and evaluation. Real-world evaluation is not only costly but also has interference noise. They explicitly stated that sufficient budget funding has been reserved for evaluation processes to ensure research progress.

This means evaluation results will fluctuate significantly due to initial configurations, lighting conditions, or even friction parameters provided by manufacturers—these variables all affect downstream strategy robustness. The entire evaluation process is time-consuming, requiring two days to obtain results.

More critically, there's **weak correlation** between training loss and actual success rates—this is the fundamental difference between supervised learning and sequential decision-making (or strategy learning). In supervised learning, training loss directly reflects model quality, while in strategy learning, loss only measures single-step prediction accuracy and often cannot predict long-term task performance.

Even with low training loss, long-cycle task execution may still perform poorly. Due to mismatches between training objectives (such as training cycles) and task-specific metrics (such as task cycles), it's difficult to establish approximate or proxy metrics for strategy performance, forcing researchers to rely on real-world evaluation.

This naturally raises a question: why not evaluate in simulation environments?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image74.png)

Stanford's **Fife Laboratory** and **Meta's Habitat 3.0** have made important advances in robot behavior research. Researchers are developing large-scale simulation environments to evaluate and measure robot strategies, but these simulation systems still face many challenges—although they show good correlation with real-world performance, there are still deficiencies in precise modeling of rigid bodies, deformable objects, and clothing.

Another key issue is **asset generation**—achieving large-scale generalization and asset creation remains difficult. Additionally, how to digitize the real world and procedurally generate realistic and diverse objects, these challenges all constrain the effectiveness of using simulation environments to evaluate robot learning strategies.

Establishing simulation-reality correlation is similar to **ImageNet's** benchmark role in embodied intelligence. ImageNet's success stemmed from its ability to accurately reflect advances in deep learning and computer vision. We're similarly committed to building a platform—where benchmark breakthroughs directly translate into improvements in robot learning capabilities.

We also discussed **foundation strategy** development. Current research also focuses on building foundation world models by utilizing large-scale action-conditioned robot interaction data to train these strategies.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image75.png)

However, this data contains **important dynamic knowledge**. Using it solely for strategy learning would be inefficient. Therefore, we're exploring how to use this large-scale action-conditioned robot interaction data to train **foundation strategies** and world models, as well as their interactions. Existing research has begun exploring methods for constructing such foundation world models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image76.png)

There are several interesting characteristics worth considering: should models adopt **3D structures**? Should they incorporate **structural priors**? How should we balance learning with physical laws? How do we ensure correlation with the real physical world?

Due to time constraints, I'll conclude here. Our vision for the future is to develop a **foundation robot model** capable of broad application in unstructured data environments with strong generalization capabilities.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec17_image77.png)

The next lecture will focus on **human-centered artificial intelligence**. Today's class ends here, thank you all.
