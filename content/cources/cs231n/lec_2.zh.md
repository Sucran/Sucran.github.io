---
title: "斯坦福 CS231N | 2025 春季 | 第二讲：线性分类器中的图像分类"
date: 2025-09-04T16:10:02+08:00
draft: false
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image1.png)

今天，我们将延续上一讲的内容，继续探讨**图像分类**这一主题。我们将深入剖析那些引领我们接近**神经网络**的知识点，最终导向卷积神经网络乃至更前沿的领域。


![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image2.png)

我们将从**线性分类器**开始讲解。回顾上节课讨论的教学大纲，我们概括了三大主题类别：

1. **深度学习基础**  
2. 感知与理解视觉世界  
3. 重建与交互视觉世界  

每个类别都包含若干子主题。今天我们将聚焦前三个要点：**数据驱动方法**、**线性分类**以及**k近邻算法**。  

与上节课相同，我们将从计算机视觉的基础任务——**图像分类**这一核心课题切入。该任务是绝佳的算法性能基准，本学期我们将反复以此为例来阐释算法运作原理。  

今天我们将明确图像分类任务的定义，并针对该任务介绍两种数据驱动方法。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image3.png)

其中一个是你的邻居，另一个则是线性分类器。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image4.png)

补充幻灯片中列出了其他方法，您可以在课后查阅。但**本次课程的重点**将放在此处概述的方法上。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image5.png)

图像分类是指为给定图像从一组预设类别（如**狗**、**猫**、**卡车**或**飞机**）中分配对应标签的任务。虽然人类凭借与生俱来的整体视觉信息认知能力可以轻松完成这项任务，但对人工智能系统而言却构成了重大挑战。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image6.png)

然而，当涉及编码并理解计算机如何解析这张图像时，挑战就变得截然不同了。**我们的重点**在于探索机器如何理解这类数据。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image7.png)

图像通常以数据矩阵的形式表示，更广义地说，是**张量**。每个像素值通常在0到255之间，对应一个**8位数据结构**。

对于分辨率为800×600像素的彩色RGB图像，数据会形成一个大小为800×600×3的三维张量，分别代表红、绿、蓝三个通道，如幻灯片所示。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image8.png)

正如你可能已经推断出的那样，这体现了人类对图像的感知与机器解读之间的**语义鸿沟**。为了更好地理解为何这会带来重大挑战，让我们来探讨成像数据中固有的一些变异因素。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image9.png)

举例来说，考虑移动相机的情况。当相机环绕拍摄而猫咪保持完全静止时，**800×600×3图像**中的每个像素值都会发生变化。对人类而言，物体本身并未改变，但从计算机的视角来看，这构成了一个全新的数据点。

这个例子展现了**计算机视觉领域的挑战之一**，当然还存在其他诸多难题。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image10.png)

例如，**光照**是一个重大挑战。在图形学、计算机视觉或工程应用中的数字图像处理等课程中，你会了解到每个像素的**RGB值**取决于表面材质、颜色和光源。  

因此，同一物体（比如一只猫）在不同光照条件下可能呈现数值差异。无论猫是在暗室还是阳光下，它始终是同一只猫，但这种变化却给机器感知带来了困难。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image11.png)

除了我提到的光照和视角变化外，您能否识别出其他可能改变像素值并阻碍物体识别的挑战？**背景杂波**和**物体遮挡**确实是重要因素，我们将在下一张幻灯片中讨论这些内容。  

（注：将"objects"译为"物体遮挡"以更准确传达技术语境中该术语指代物体相互遮挡的含义）



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image12.png)

背景杂波带来了另一项挑战。此外，图像中物体的**尺度**（受放大缩小操作影响）也是一个重要因素。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image13.png)

图像的分辨率构成了一个重大挑战。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image14.png)

然而，在**机器学习模型**或任何旨在识别图像中物体或动作的系统中，由于我们对图像尺寸进行了标准化处理，除非物体存在缩放效果，否则分辨率可能并非关键因素。**遮挡**仍然是主要挑战之一。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image15.png)

作为人类，我们能够轻易识别诸如**猫**这样的物体。即使在最具挑战性的情况下——比如最右侧图像中仅能看到一条尾巴和一小部分爪子——我们也能推断这很可能是一只猫。**情境线索**（例如客厅的环境）支持这一判断。然而除此之外，形变等挑战因素会使识别任务变得更加复杂。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image16.png)

猫展现出显著的形变能力。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image17.png)

这些变化给用于检测和识别物体的算法带来了**重大挑战**。具体而言，**形变**对逐步式物体检测系统构成了主要障碍。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image18.png)

除此之外，**类内差异**也带来了另一项重大挑战。猫的体型、毛色、花纹和品种可能各不相同，但都被归类为猫。然而，机器却难以识别这些类内差异。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image19.png)

一个显著的挑战在于**上下文**。如果算法仅分析图像的右侧部分而忽略更广泛的背景，可能会将其误判为老虎或其他动物。然而，通过考虑阴影等上下文元素，就能更准确地完成分类。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image20.png)

现代分类器在图像分类和目标识别方面表现出色，这主要归功于**ImageNet**等倡议及后续工作，它们为训练更庞大的模型建立了大规模基准。

在本课程中，我们的目标是开发能够识别图像中物体及其他元素的模型。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image21.png)

在本课程的后续部分，我们将系统性地开发构建这些大规模算法所需的**基础组件**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image22.png)

在继续之前，我们必须先审视图像分类的**基础构建模块**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image23.png)

实现此类功能带来了独特的挑战。在传统的计算机科学或工程课程中，诸如**排序**之类的算法是通过包含if-then-else规则和循环的清晰框架构建的，从而形成明确的步骤流程图。然而，这种方法无法有效迁移到图像理解和视觉世界解析领域。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image24.png)

目前尚无方法能够**硬编码**图像分类的步骤，尽管之前在这一领域已有一些尝试。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image25.png)

研究人员尝试通过系统化步骤开发物体识别算法。一种方法首先采用**边缘检测**技术来识别图像中的边缘轮廓。随后，算法会分析角点等重要特征模式，提取角点周边特征或统计特定类型角点数量，最终将这些特征映射到输出类别。

虽然该方法在有限变化范围的图像上取得了一定成效，但仍面临重大挑战：首先，这类算法难以扩展，因为需要为每个物体类别定制不同规则；其次，推导每个物体的**底层逻辑**需要耗费大量人工劳动。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image26.png)

由于这些挑战，基于创建逻辑和程序进行物体检测或图像分类的算法并未取得显著成功。然而，**机器学习**提供了一种数据驱动的方法。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image27.png)

借助这一**全新范式**和数据驱动的方法，我们制定了一个三步流程。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image28.png)

第一步是收集图像及其对应标签的数据集。为了识别特定类型的物体，我们可以从多种来源（如在线数据集或独立数据点）采集数据。过去，这需要借助**搜索引擎**和图片搜索工具来汇编此类数据集。如今，已有现成的数据集可供直接使用。

第二步涉及使用机器学习算法**训练分类器**。这需要构建一个处理训练图像及其标签的函数，从而建立一个能将图像与正确标签关联起来的模型。

最后一步是在新图像上评估分类器。这需要实现一个**预测函数**，该函数接收训练好的模型和测试图像（即未包含在训练集中的图像），并输出预测标签。

这一流程体现的是**数据驱动方法**而非基于逻辑的方法。我们将讨论两种常用分类器，其中之一便是**最近邻分类器**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image29.png)

这代表了最简单的分类形式。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image30.png)

我们将聚焦于这一主题，以便更好地理解构建**分类器**所涉及的概念，因为这有助于阐释**关键细节**。随后，我们将过渡到线性分类的主题。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image31.png)

要构建**最近邻分类器**，我们需要实现训练和预测函数。训练函数只需记忆所有数据及其对应标签，实质上将这些信息存储在内存中而不做额外处理。预测函数则通过将查询图像与存储的数据集进行比对，找出与之最相似的训练图像。这一过程涉及创建图像及其标签的**查找表**，在预测时，函数会检索出最匹配图像的标签。

例如，假设有一个包含五张图像的训练数据集。给定查询图像时，目标是确定哪张训练图像与之最为相似。这需要一个**距离函数**，通过计算相似度指标来评估查询图像与每张训练图像之间的相似性。定义该距离函数的方法有多种。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image32.png)

最广泛使用的距离度量之一是**L1距离**，其定义为两幅图像 \\(I_1\\) 和 \\(I_2\\) 之间逐像素绝对差的总和。

例如，要计算测试图像与训练图像之间的距离，我们进行逐像素减法，取差值的绝对值，然后将它们相加。这个总和即表示图像之间的L1距离。

尽管这是一个基础的距离函数，但它在众多应用中表现出极高的有效性。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image33.png)

在本课程中，你会经常重温**L1距离**及其变体。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image34.png)

基于这个简单的定义，我们旨在探索其实现方式。  

第一步需要**记忆**训练数据。训练函数将数据存储在内存中，而预测函数则利用**NumPy**等Python库计算每个测试样本与训练数据之间的距离。  

随后，它为每个测试样本找出最小距离，并输出最近邻对应的标签。整个过程仅需四行代码即可实现。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image35.png)

**像素值**，在最简单的形式下，构成一个800×600×3维度的张量。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image36.png)

一幅图像由三个通道组成，分别代表每个像素的**RGB值**。像素值通常在0到255之间。这一惯例源自**24位RGB格式**，这是存储图像最广泛使用的标准。

在该格式中，红、绿、蓝三个颜色通道各分配八位，使每个通道可表示256种数值。虽然存在其他框架，但这仍是主流标准。

现在，让我们回到代码并继续下一个问题。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image37.png)

这里许多学生具备**工程学背景**，并接触过一些计算机科学知识。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image38.png)

然而，我们的目标是评估在训练数据集中包含\\(n\\)个样本时，**训练速度**和预测速度。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image39.png)

我希望你对**大O符号**有所了解，这是我们通常用来表示计算复杂度，有时也包括空间复杂度的表示法。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image40.png)

在分析算法时，需重点考量**训练数据**。训练函数中需要处理预测步骤。就训练过程而言，其时间复杂度为\\(O(1)\\)——因为无需执行任何运算操作，仅需将数据副本存储于内存中。

而对于预测阶段，每个测试样本都需要计算其与所有训练样本的距离。若存在\\(n\\)个训练样本，则至少需要进行\\(O(n)\\)量级的运算。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image41.png)

这种方法并非最优选择，因为训练过程效率低下。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image42.png)

然而，在测试和预测过程中，**大量时间**被花费在将每个数据点与训练样本进行比较上。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image43.png)

这类似于查询一个**GPT模型**的过程：每个问题都会促使系统评估并对比潜在答案与海量互联网数据——这一过程可能需要数年才能返回响应。即便对于简单问题，这种方法的扩展性也极不现实。我们过去曾采用过这些方法。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image44.png)

因此，通常需要构建在预测阶段高效的**分类器**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image45.png)

他们执行任务的速度要快得多，但即便**训练过程**耗时较长也是可以接受的，因为这一过程可以离线进行。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image46.png)

考虑到这一点，尽管人们已投入大量精力利用GPU加速**最近邻算法**，但这些进展超出了本课程的范畴。如有兴趣，你可以自行深入探索。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image47.png)

让我们通过一些可视化图表来理解该算法的运作原理。给定一个包含五个类别（**红色**、**蓝色**、**绿色**、**紫色**和**黄色**）的空间，每个点代表对应类别的训练样本。对空间进行逐点划分后，可以观察到五个（在本例中为六个）明显不同的区域。每个区域的颜色标识了该区域内任意测试样本的最近邻类别，这展示了**单最近邻算法**对空间的划分方式。  

但请注意此例中的问题：黄色点完全被绿色点包围，表明它可能是一个**异常值**或噪声。这种情况在我们处理的许多问题中都很常见。中心区域的大片黄色范围仅由这一个点形成，这正是仅依赖单一最近邻所导致的结果。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image48.png)

为了增强**鲁棒性**，我们可以增加考虑的最近邻数量，将最近邻算法转变为**k-最近邻**方法。通常我们会选择多个点或样本，通过多数表决机制来确定给定测试图像的标签。  

但白色区域的出现带来了一个挑战。这些区域表示决策不确定性，因为在邻近样本中包含了来自三个不同类别的等量样本。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image49.png)

无法确定白色区域内示例的标签。若您在自己的问题中创建了此类空白区域，这些区域代表着**需要补充数据收集**的部分，因为目前尚不明确。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image50.png)

该方法能有效识别出**需要**额外数据采集的区域。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image51.png)

**k** 的取值是 K 近邻算法中的关键参数，增大该值可能会影响模型的性能。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image52.png)

还记得我们在**距离函数**的选择上还有另一个决策点。我们讨论过**L1距离**，即像素间差异绝对值的总和。在某些场景下，这被称为**曼哈顿距离**。通过可视化L1距离，该空间中正方形边界上的所有点与原点保持等距，这有助于理解该距离函数的运作机制。

另一种常用的是**L2距离**，它计算差值平方和后开平方根。这会形成圆形可视化效果，圆周上所有点与圆心距离相等。这些可视化图形能直观展现L1与L2距离的核心差异——它们是最基础的距离函数之一。

当涉及**特征旋转**时，这些可视化的价值就显现出来了。这里X和Y代表特征（例如像素值）。旋转这些特征（或采用替代特征）会改变L1距离的框架，但L2距离保持不变。这一区别尤为重要——特别是当特征具有高度特异性且富含意义时。在此类情况下，L1通常更受青睐，因其几何特性能更好地基于原始特征保持并强化距离关系。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image53.png)

然而，如果这些特征更为任意，**L2距离**就会变得更有意义。为了计算该距离，此形状上的所有点都保持与原点相同的距离。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image54.png)

若使用**L1（曼哈顿）距离**，该形状上的点到原点的距离相同。而对于**L2（欧几里得）距离**，圆上的点到圆心距离相等。  

关键区别在于它们在旋转下的表现：当特征轴旋转时，L1距离会完全改变，而L2距离保持不变。这是因为L1对特征值高度敏感，而L2则不然。  

在同一空间中选择不同特征时，距离函数的行为也会相应变化。例如，选择不同的特征方向会改变决策边界的朝向。  

在**k=1最近邻分类**中，这些几何特性直接影响算法如何划分特征空间。选择L1还是L2距离时，应考虑任务中特征保持（L1）或旋转不变性（L2）哪个更为重要。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image55.png)

在使用**L1**和**L2**距离度量时，空间划分情况如下。  

一个显著的观察结果是：**L1距离函数**生成的决策边界往往与特征轴（x1和x2）平行，因此对单个特征的变化极为敏感。  

相比之下，**L2距离**形成的边界分隔更为平滑。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image56.png)

实验室网站上提供了一个在线工具，可用于尝试不同的**距离函数**和**K-最近邻算法**中的**k值**配置。这使您能够探索多种参数组合。

我们采用**K-最近邻方法**主要基于两点考量：首先它是最简单的数据驱动解决方案，堪称理想的入门选择；更重要的是，该方法为讨论**超参数**——这些必须在算法运行前确定的关键变量——提供了绝佳范例。

在此框架下，**k值**（最近邻数量）作为核心超参数，其取值变化将直接影响结果输出。而距离函数的选择则是另一个关键超参数决策，这些选择通常需要结合具体数据集和待解决问题来综合判定。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image57.png)

为了针对每个问题优化性能，我们需要一种方法来识别和调整超参数，这一过程在机器学习和深度学习算法中被称为**超参数调优**。

设定超参数有几种常见方法。一种是根据训练数据选择表现最佳的超参数，例如最小化训练损失。但这种方法存在缺陷，尤其在**k近邻算法**中，当\\(k=1\\)时模型会通过死记硬背训练数据达到100%准确率，这显然不是理想方案。

另一种方法是基于预留测试集来选择超参数。虽然比第一种方法有所改进，但会引发严重问题：这本质上属于作弊行为，因为超参数是针对测试数据优化的。这会导致模型在测试集之外未见数据上的泛化能力受到质疑。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image58.png)

这种方法并不可取，因为我们无法预测模型将如何泛化。正如前文所述，这本质上是一种**作弊**行为。  

更稳健的做法是将训练数据分区，创建独立的**验证集**。仅在训练集部分训练模型，然后利用验证集优化超参数。确定最优超参数后，再将其应用于测试集进行最终评估和预测。  

虽然这种方法更为优越，但它也存在自身的问题——验证集通常规模较小，可能无法充分代表完整的数据分布。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image59.png)

更有效的方法是使用**交叉验证**来设置超参数。具体操作是将训练数据划分为多个分区，例如五折。每一折依次作为验证集使用，这个过程会重复迭代进行五次交叉验证。  

针对每个超参数值，计算其在验证集上的准确率，并取五次迭代的平均值。重复这一流程以确定**最优超参数配置**，最终将该配置应用于测试集。  

虽然这种方法更可靠且能获得更好的结果，但由于在大规模深度学习中对海量数据集多次重复此过程存在**计算挑战**，其实际应用相对较少。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image60.png)

我们常常依赖直觉来设置**超参数**，有时会采用单一验证集的方法。然而，这种做法通常不建议在**计算机视觉**和大规模数据集之外的领域使用。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image61.png)

研究论文通常需要**交叉验证**和统计框架来确保在测试集上获得可复现的结果。为此存在多种方法。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image62.png)

让我们总结一下关于**最近邻**的讨论，并查看一些示例和结果。

现在我将介绍**CIFAR-10数据集**，你们在作业中会经常用到它。该数据集包含10个类别，每个类别都有大量训练和测试图像。这里展示了一些类别的示例。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image63.png)

使用**K近邻算法**时，我们可以为每个测试图像可视化其前10个最近邻样本。需要解决的**关键问题**在于如何确定K的最佳值——究竟应该考虑多少个最近邻？



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image64.png)

让我们来看一个使用**5折交叉验证**的快速实验。每个数据点代表不同K值下的一折结果。如图所示，**K=7**时获得了约28-29%的最佳准确率。虽然这一表现优于随机猜测（在这个10分类问题中随机猜测的准确率为10%），但仍有很大的提升空间。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image65.png)

重新审视这些示例时，许多错误变得显而易见，尤其是最接近的匹配项。例如在第四行中，图像显示的是一只青蛙，但首个示例却被误分类为狗。这种差异源于距离度量是在像素级别进行的。这些图像在大多数像素上具有相似的颜色分布，导致计算得出的距离值偏小。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image66.png)

这个例子连同其他许多案例都表明，基于像素值的距离度量**并非最优选择**。我们在实际应用中并不采用这种方法，因为后续课程将介绍**更优的解决方案**。

作为本专题的总结，请再看一个示例。原始图像与三个修改版本在色彩、遮挡或像素偏移（例如左起第三张图仅向右平移了一个像素）方面存在显著差异。从人类视觉角度来看，这些差异微不足道，但**基于像素的距离度量**却将它们视为与原始图像同等程度的差异。

现在暂停提问环节。总结来说，**核心问题**在于如何在此类情况下做出决策。通常的解决方法是随机选取排名靠前的候选方案之一。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image67.png)

如果你正在收集更多数据——例如，在解决**遗传学**或**医学影像**领域的问题时——



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image68.png)

在最近邻空间中可视化样本或特征时，可能会遇到**样本不足**或存在模糊性的区域。这种情况下，建议寻找在该空间内占据同一区域的额外样本。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image69.png)

在关于**K近邻算法**的讨论总结中，我们重点理解了这一基于数据的基础方法，并探讨了超参数调优，尤其强调了**距离度量**与**K值**选取的关键作用。  

现在我们将转向下一个主题：**线性分类器**。本节课剩余25分钟，我将把剩余时间全部用于讲解这一重要内容。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image70.png)

这是深度学习中最**基础的构建模块**。我们必须理解这种方法的不同之处。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image71.png)

首先，我们来看这与最近邻方法有何不同。**这是一种参数化方法**，我们需要学习一组参数（记作权重\\(w\\)），将输入图像映射为输出类别分数。函数\\(f\\)将输入转换为输出，通常表示为10个输出类别各自的隶属度分数。  

在这个框架下，**线性分类器**利用参数\\(w\\)将输入\\(x\\)映射到输出\\(y\\)。过程非常直观：一张表示为\\(32 \times 32 \times 3\\)数组（共3,072个数字）的图像定义了我们的输入向量\\(x\\)，其维度为\\(3,072 \times 1\\)。由于有10个输出类别，我们需要10个独立的分数，因此输出向量为\\(10 \times 1\\)。  

为实现这一映射，我们定义一个维度为\\(10 \times 3,072\\)的**权重矩阵**\\(w\\)。此外，我们还引入一个**偏置项**——这是一个与输入无关的值，其作用包括对类别分数进行偏移以改善类别分离效果。这一特性将在后续几何可视化中进一步探讨。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image72.png)

如前所述，这些**线性函数**是构建神经网络的基础模块。通过将这些线性分类器和函数按顺序组合，我们可以构建出大规模的神经网络。虽然还需要其他组件，但这仍然是最关键的要素之一。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image73.png)

如果我们审视流行的**神经网络架构**，会发现**线性函数**在其结构中无处不在。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image74.png)

为了更好地理解映射关系和函数运作，让我们重新审视**CIFAR-10**示例中的训练与测试样本。为简化起见，我们将不分析32x32的大尺寸图像，而是考察一个由4个像素组成的2x2输入图像。这样就将输入图像转换成了一个向量。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image75.png)

如图所示，我们需要确定**权重矩阵** \\(W\\) 和**偏置项** \\(B\\)，以将输入图像映射为输出分数。这从代数视角代表了一个线性函数。

输出分数对应三个类别：猫、狗和芯片。该函数将图像向量转换为这些分数。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image76.png)

现在，让我们从代数角度审视线性分类器的视觉视角。每张图像对应矩阵\\(W\\)中的一行，该矩阵充当**特定类别的模板**。例如，当我们用图像乘以\\(W\\)和\\(B\\)时，可以可视化呈现猫、狗和芯片这三个类别对应的模板。

在**CIFAR数据集**上训练模型后，学习到的十个类别模板展现出有趣的特征模式。以汽车类别为例，尽管只是简单的线性分类器，其模板仍清晰地呈现出汽车前部的轮廓特征。这证明了模型捕捉关键视觉特征的能力。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image77.png)

**线性分类器**可以从视觉和几何两个角度来理解。在二维空间中，线性分类器通过识别边界来区分不同类别，如图中红色、蓝色和绿色线条所代表的不同类别所示。  

在更高维度的空间中，这些边界则成为**超平面**，如左侧示例所示。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image78.png)

**偏置项**在此处至关重要。若缺少它，所有直线都将被迫穿过原点，这显然不切实际。偏置的存在使得我们能够构建更可靠的函数和决策边界。

**线性函数**（尤其是线性分类器）在众多应用场景中极具价值，它们不仅是基础工具，更是构成更复杂神经网络的核心组件。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image79.png)

然而，这种方法本身也存在挑战，因为它无法对许多独立数据实例进行分类。例如，若**类别1**对应第一和第三象限，而**类别2**对应第二和第四象限，则线性分割将无法实现。

另一种情况是，当类别1被定义为距原点1到2个单位距离内的点，而类别2包含所有其他点时；同样地，如果数据中类别1分布在三个不连续区域，而类别2占据其余空间，这些情况下要实现分割都极具挑战性。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image80.png)

我们之前讨论了**线性分类器**及其将输入图像映射到输出标签的能力。剩下的挑战在于选择合适的权重值\\( w \\)，以将每张图像转换为类别特定的得分。为此，我们需要定义一个**损失函数**（或目标函数），通过衡量模型得分与训练数据得分之间的差异来量化模型性能。  

一旦建立了损失函数，就需要通过优化过程调整\\( w \\)以最小化该损失，这将在下一讲中详细介绍。为了便于理解，假设一个简化示例：包含三个类别（猫、汽车和青蛙）和一个线性函数。我们需要一个损失函数来评估分类器的性能，该函数由输入图像\\( X_i \\)及其对应标签\\( Y_i \\)参数化。此函数用于衡量预测得分\\( f(X_i, W) \\)与真实值\\( Y_i \\)之间的差异，通常按样本数量归一化。  

**Softmax分类器**是一个典型示例。假设某张图像的得分分别为3.2、5.1和-1.7，我们通过softmax函数将这些无界值转换为概率。首先对得分取指数以确保正值，然后通过求和归一化，生成有效的概率分布。这种方法能为给定输入\\( X_i \\)的每个类别\\( k \\)生成定义明确的概率。



这是一个概率分布函数，其各概率之和为1。这些数值的解读非常直观：当前参数集 **\\(W\\)** 判定该图像为猫的概率为13%。显然，此例中的预测并不正确，表明\\(W\\)尚未达到最优配置，需要进行优化。

这些概率对应的是**未归一化的对数概率**，通常被称为逻辑值（logits）。若您曾学习过机器学习课程或其他领域的逻辑回归，会认出这与您熟悉的框架如出一辙。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image81.png)

该框架与逻辑回归完全相同。由于存在多个类别，它构成了**多项逻辑回归**。  

函数\\(L\\)的定义可以有所不同，但我们的目标是最大化样本属于正确类别的概率——在本例中具体指0.13这个值。然而由于集合中其他值可能更大，我们需要将这个最大化问题转化为最小化问题，这是通过对数值取负来实现的，从而将最大化转换为最小化。  

此外，我们对数值取对数以提升**数值计算的易处理性**。因此，该值的负对数就定义了这个问题的目标函数，或称**损失函数**。  

这个简洁的公式同时作为softmax和逻辑回归的损失函数。正如CS229等课程所述，该方法也被称为**最大似然估计**，代表的是同一种算法。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image82.png)

基于这一思路，**目标函数**（或称**损失函数**）被定义为正确类别的负对数概率。这一设定虽然直观，但该框架还存在其他解读方式。  

一种方法是从估计概率与真实概率分布匹配的角度重构损失函数。这可通过最小化**Kullback-Leibler散度（KL散度）**实现，从而为损失函数提供信息论视角。在此情境下，KL散度会简化为最初定义的负对数函数。  

此外，该公式与**交叉熵函数**等价。将交叉熵分解为真实分布的熵与KL散度后，我们仍会得到负对数函数。当使用独热编码表示类别标签时，熵项归零，因此该函数被称为交叉熵或**二元交叉熵（BCE）**。  

在深度学习领域，尤其是神经网络框架中，BCE作为常用损失函数被广泛采用，上述讨论正与该标准公式相契合。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image83.png)

我们首先采用一种简单的方法，着重比较各方法之间的异同。**损失函数**被定义为概率的负对数，其中概率通过之前讨论过的softmax函数计算得出。优化这一损失函数（这将是下节课的重点）可以得到正确的权重\\( W \\)。

在结束之前，让我们探讨几个关于此定义的问题。损失函数\\( L_i \\)的均值和最大值分别是多少？最大值是无穷大，因为零的负对数趋近于无穷大，但负号确保了损失值保持为正。这一结论是正确的。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image84.png)

但我们也必须考虑到这一点。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/cs231n/lec_2_image85.png)

让我来解答第二个问题。当我们初始化所有权重\\(W\\)为随机值时，每个类别的概率会趋于均等。

对于**softmax损失函数**在\\(C\\)个类别下的情况（尤其是当\\(C=10\\)时），由于概率均等，每个类别的概率约为\\(\\frac{1}{C}\\)，此时损失值为\\(\\log C\\)。

当类别数为10时，\\(\\ln 10 \\approx 2.3\\)，这正是理论预期值。



