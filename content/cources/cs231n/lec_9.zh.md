---
title: "斯坦福 CS231N | 2025 春季 | 第九讲：目标检测、图像分割、可视化"
date: 2025-09-10T17:47:14+08:00
draft: true
description: ""
---

{{< katex >}}

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image1.png)

今天，我们将讨论各种**核心计算机视觉任务**，包括**检测**与**分割**算法。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image2.png)

我们还将探讨与**可视化**和理解相关的主题，重点关注最**核心的概念**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image3.png)

在上一讲中，我们探讨了从**序列到序列模型**和**循环神经网络**向**Transformer模型**的演进过程。我们深入分析了Transformer模型如何通过其编码器架构进行定义，该架构包含多个层级，具有**多头自注意力机制**、**层归一化**和**多层感知机**等核心组件。这种结构现在通常被称为**序列编码器**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image4.png)

为了将图像或序列解码为输出，解码器采用了类似的架构。解码器以编码器生成的标记作为输入，并生成所需的输出。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image5.png)

贾斯汀在上周的讲座中（很可能是周二）详细讨论了使用循环神经网络（RNNs）及其变体建模序列的差异。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image6.png)

**卷积**是我们讨论过的另一种方法，但**自注意力机制**已成为许多当代应用中的首选方案。尽管自注意力模型计算复杂度更高且需要更大的内存资源，但相较于其他方法，它们提供了更卓越的序列建模能力，并在各类任务中展现出更优的性能表现。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image7.png)

到目前为止，我们主要讨论了**自注意力机制**，并附带介绍了**交叉注意力**及相关概念。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image8.png)

现在我们将转向视觉变换器（ViT）这一主题，它是现代计算机视觉应用中的核心模型。虽然在上节课的最后几分钟已简要提及，但我希望更详细地重新探讨它。  

讨论结束后，我将暂停以解答关于作业或目前所学内容的任何问题或评论。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image9.png)

我们讨论了**Transformer**如何通过将图像分割成小块来处理图像，从而有效地创建一个序列。图像被划分为S×S的小块——在这个例子中，可能是3×3。  

每个小块由**token**表示，通常是将重塑后的图像线性投影为一个向量。这些token是D维向量，如本幻灯片所示。  

然而，通过将图像转换为小块，我们必须考虑在这个过程中可能会丢失哪些信息。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image10.png)

这一过程本质上会丢失图像的**空间位置**和**二维位置信息**。为解决这个问题，我们引入了**位置嵌入**。  

实现位置嵌入有多种方法。一种方法是创建顺序编号系统（1、2、3等），另一种则采用**二维坐标**（X和Y）。  

这些嵌入会与原始标记结合，然后交由**Transformer层**处理——该层包含自注意力机制、层归一化以及前文讨论过的MLP组件。最终输出层会生成适用于各种应用的向量。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image11.png)

计算机视觉的主要应用之一就是图像分类。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image12.png)

在**图像分类**任务中，核心目标是通过编码生成能有效表征类别的输出。为实现这一目标，我们通常会引入一个**特殊标记**——作为额外的输入注入到Transformer中，其维度与其他输入保持一致。该标记是可学习参数，其输出表征会被转换为类别概率向量（具体表现为一个\\(C\\)维向量），这种方法通常被称为**类别标记**。

这是将视觉Transformer（ViT）应用于图像分类任务时最基础、最标准的实现方式之一。但Transformer的应用远不止于分类任务，它还能适配多种其他任务，我们今天就将探讨其中部分案例。

上周我们还讨论了另一种Transformer变体，该架构同样基于相同的标记机制运作。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image13.png)

从这些标记开始，我们进入Transformer层的处理流程。如前所述，这些层由多个Transformer模块组成。**位置嵌入**会被添加到输入中。与需要掩码防止未来信息泄露的语言处理不同，这里我们可以同时处理整幅图像而无需掩码。Transformer会为每个输入图像块输出向量表示。

在此场景下训练Transformer主要有两种方法。**第一种方法**使用独立的类别标记，而**第二种方法**则获取所有输出标记，通过池化操作后将其投影为表示C个类别预测的概率向量。这两种架构代表了基于Transformer的分类模型的主要变体。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image14.png)

我们采用前文讨论的相同方法进行监督：通过定义损失函数（**二元交叉熵**、**softmax** 和 **最大损失**）进行反向传播。这本质上封装了 视觉变换器（ViTs） 的核心思想。  

多年来，这种架构方法在不同应用中始终保持一致。许多现代架构仍沿用这些组件，与本文提出的框架高度相似。  


![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image15.png)

上周的幻灯片中讨论了几种优化方法，我将简要概述。需要理解的是，存在大量微调和优化手段可以提升性能并稳定Transformer的训练过程。

其中一项关键优化涉及**残差连接**。在这种配置中，层归一化被应用于残差连接外部，即对输出进行归一化。然而，这种方法会限制模型复制恒等函数的能力——这正是**ResNet**力图实现的核心特性。解决方案是将层归一化整合到残差路径内部。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image16.png)

我们通常将**归一化**操作置于自注意力层之前，并再次在MLP层之前应用，同时保留恒等映射。还存在其他归一化方法，例如**RMS Norm**（均方根归一化），该方法通过排除特征均值提供了一种更简洁的实现。实证研究表明，这能有效提升训练稳定性。尽管存在理论依据，但采用这些方法的主要动机在于其对训练过程的稳定作用。

另一种改进方案是用**门控变体**SwiGLU MLP替代标准MLP。该方法通过在三元权重矩阵（除传统的w1和w2外新增一个矩阵）中引入门控非线性机制，在保持网络参数量不变的情况下（即使将隐藏层维度设为\\(\frac{8}{3}\\)），既增加了可训练参数，又增强了非线性表达能力。

最后，现代架构普遍采用**专家混合**机制。不同于单一MLP，该方案部署多个专家MLP，并通过路由机制将token分配给特定专家，每次处理时仅激活部分专家（E个中的A个）。这种方法在不过度增加计算开销的前提下，既扩展了参数容量，又提升了模型鲁棒性。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image17.png)

这些均为并行多层感知机(MLPs)，可实现多个专家模型同时运算。如先前所述，它们被应用于所有大语言模型(LLMs)中。据我们所知，目前所有现代LLM都采用了这类改进方案。

以下是我刚讨论的调整要点总结。这与偏置(bias)类似吗？并非如此。  

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image18.png)

这是一个**可训练参数**，既可通过前馈网络优化，也可通过简单的线性投影转换为概率向量。它并非单纯的偏置项。

需注意，模型中存在多个**自注意力层**，这些层通过建立所有标记与分类标记间的交互来整合信息。在此监督机制下，损失函数作用于分类标记，该标记即代表类别概率向量。

由此引出一个关键问题：如何直观理解该框架中不同专家模块的具体作用？



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image19.png)

由于它们是并行训练且初始化方式不同，这些模型通常会学习到**截然不同**但有时又紧密相关的方面。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image20.png)

然而，这种方法主要涉及增加计算资源和参数量，使网络能够在必要时学习多样化概念。例如，在建模多个概率分布时，这些多层感知机（MLPs）通常具备区分不同数据模态的能力。  

随之而来的问题是专家数量是否属于**超参数**。确实如此，它属于超参数范畴。根据现有认知，该数值通常是预先设定的。虽然应避免过度微调，但这些参数本质上都属于超参数这一事实始终成立。  


![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image21.png)

为什么移动**层归一化**有助于学习恒等变换？考虑以下架构。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image22.png)

你能创建任何形式的恒等映射吗？经过残差连接后，特征值会因归一化而发生改变。**你无法在特征中保持恒等性**，因为紧接着就会应用层归一化。这正是我们引入它的原因。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image23.png)

在**计算机视觉**领域，多年来有几项核心任务对各种应用起到了关键作用。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image24.png)

尽管如今我们处理的任务复杂程度大幅提升，**目标检测**只需一行代码即可轻松实现，但过去10到15年间该领域仍取得了重大进展。  

今天，我将重点探讨部分技术突破，为设计新型模型提供方向指引。此外，**可视化与可解释性**始终至关重要，尤其在医疗数据分析等应用场景中。  

解读肿瘤检测结果——理解病灶位置及其判定依据——其实际价值往往超越分类行为本身。  



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image25.png)

我们以一张大家可能非常熟悉的幻灯片开始了这节课。我们讨论了多项任务，包括**物体分类**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image26.png)

在最初的几节课中，我们花了大量时间探讨如何开发一个**分类器**，将图像从像素分类到标签。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image27.png)

然而，另一个同样重要的任务是语义分割。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image28.png)

在**语义分割**任务中，我们的目标是为图像中的每个像素分配一个标签，从而将每个像素转换为场景中对应物体或元素的标签。训练这类模型时，我们的目标是在推理阶段输入图像并输出分割图。

实现这一目标有多种方法。一种简单粗暴的做法是逐个检查每个像素并预测其标签。然而这种方法存在根本性缺陷，因为单个像素缺乏**上下文信息**，无法确定其所属物体。上下文至关重要——必须结合周边区域才能做出准确预测。

更实用的解决方案是采用以每个像素为中心的图像块，同时包含其邻近区域。这样我们就可以训练**卷积神经网络**（或任何合适的架构）来预测中心像素的标签。我们之前讨论过的图像分类架构——如CNN、ResNet或视觉Transformer（ViT）——都可以适配这项任务。

但若对图像中每个像素都应用完整网络计算，会产生极高的计算成本，无法高效生成分割图。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image29.png)

另一种方法是训练一个**神经网络**，将整张图像作为输入，输出完整的**分割图**——即一个由标签组成的矩阵，而非单一标签。这种方法能有效解决分割任务。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image30.png)

为实现这一目标，我们需要一个与图像尺寸匹配的**输入层**，以及一个扩展的输出层。传统的全连接层并不适用，因为我们要生成图像，这要求必须使用全卷积神经网络（FCN）。  

虽然FCN效果显著，但也带来一个挑战：图像尺寸过大会导致网络层数庞大，需要优化的参数数量激增。这种计算需求在早期**GPU性能**有限时尤为棘手，成为算法训练的重大瓶颈。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image31.png)

算法的这一演进过程始于全尺寸图像，通过下采样操作逐步降低空间分辨率。该过程会生成一个通道数增加的低分辨率表征。

随后，我们将其重新上采样至原始图像尺寸以生成输出像素。虽然池化操作和跨步卷积等**下采样技术**已相当成熟，但上采样仍存在挑战，因为我们缺乏类似反向池化或逆跨步卷积的直接对应操作。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image32.png)

为此，我们引入了**新型运算操作**，这些操作本质上能逆转下采样过程。在深入探讨上采样之前，请允许我先简要说明该网络的训练原理。给定一个处理输入图像并输出另一张图像的神经网络，训练过程中的核心工具是**损失函数**。

如何通过损失函数来定义或训练这个网络才是最优方案？我们此前已讨论过**softmax损失函数**、回归损失函数以及SVM损失函数。若选择softmax损失函数，目标就是最小化每个像素的分类损失，这确实是正确的实现路径。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image33.png)

由于每个像素都执行分类操作，因此可以针对每个像素计算**损失函数**。这涉及对图像中所有像素的损失值求和，其中损失函数采用简单的softmax形式，随后便可应用反向传播算法。

**核心问题**在于训练过程是否需要真实标注数据。在本案例中，必须提供真实的分割标签，因为这类算法属于全监督学习。早期训练此类模型需要大量人工标注的像素级标签，但现代工具已无需这种繁琐操作。

关于**上采样**操作，其处理流程相对直观。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image34.png)

我们可以采用**反池化操作**，该操作可通过多种方式实现。其中一种方法是**最近邻插值法**。例如，当从2x2矩阵上采样至4x4矩阵时，我们只需复制低分辨率输入中的每个数值。

另一种方法是Bed of Nails，即在放大后的输出中选择单一位置保留原始值，其余位置设为零。通过连续的卷积层处理，这些零值将逐渐被有效数据填充。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image35.png)

在网络编码部分使用**最大池化**时，我们可以保存所选最大值的位置，并在解码部分的上采样步骤中重复使用这些坐标。这种方法被称为**最大反池化**，其核心是将保存的最大值位置复制到上采样输出的对应位置。

另一种方案是采用**可学习上采样**方法。与之前讨论的无参数操作不同，可学习上采样包含可训练参数。为理解这一点，让我们回顾卷积运算：在标准卷积层中，我们通过对每个像素应用滤波器来生成输出。进行下采样时，我们会使用步长为2（而非1）的跨步卷积。

同样的原理可应用于上采样。上采样图像中的每个区域都对应特定区域，我们通过定义权重将其映射到输出。当区域间出现重叠时，通常会对重叠值进行求和处理。

举例说明：假设存在一维输入值A和B。我们通过学习一个滤波器将这些值映射到更高分辨率的输出。该滤波器会作用于每个输入值，并将结果写入输出。当发生重叠时，来自各位置的输出值会进行叠加求和。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image36.png)

我们讨论了**全卷积神经网络**及其应用。这些是分割任务中最基础且应用最广泛的算法之一。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image37.png)

我想简要介绍一种广泛使用的网络架构——**U-Net**，因其U形设计而得名。该架构至今仍具有高度实用性，尤其在医学图像分割领域。当不使用基础模型时，U-Net及其变体在分割任务中仍能保持**最先进的性能表现**。

U-Net通过两个核心阶段运作：**下采样阶段**通过扩大感受野来缩减空间信息，随后**上采样阶段**会恢复原始图像分辨率。这种架构设计理念与我先前演示的概念完全吻合。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image38.png)

该单元的**关键区别**在于其适用于分割任务，这需要在解码端保留空间信息。下采样操作本质上会降低分辨率，如果在后续上采样过程中不保留这些信息，重建将变得困难。这通常会导致输出中的边界模糊。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image39.png)

为了保留图像中的**结构信息**并生成更清晰的输出，编码器生成的特征图会被复制作为解码器各层的输入。这一概念构成了**U-Net架构**的基础，该架构在实践中得到了广泛应用。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image40.png)

今天，我们讨论了使用全卷积神经网络进行**语义分割**。该架构采用了与之前相同的滤波器进行下采样。为节省时间，我略过了一些幻灯片，这些内容可在演示文稿末尾供您参考。

这里的**关键操作**是**转置卷积**。我们使用一个\\(3 \times 3\\)的矩阵，但并非直接对输入数据进行卷积，而是将卷积应用于输入数据的转置版本。这一操作会生成更大的输出，实质上逆转了标准卷积过程。

一个常见问题是这些滤波器是否经过训练。答案是肯定的——与标准卷积一样，所有滤波器都在训练过程中学习得到。

关于语义分割的讨论到此结束。如需了解更多细节，请查阅补充幻灯片。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image41.png)

如前所述，我们仅获取像素级别的标签。然而，当同一**物体**存在多个实例时，由于输出仅提供像素级标注，我们无法对它们进行区分。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image42.png)

这就引出了**实例分割**的话题，我们不仅要进行像素分类，还要区分不同的实例，例如识别图像中不同的狗。  

为了实现这一点，我们必须理解图像中的多个对象，这自然过渡到**目标检测**的主题。目标检测与图像分类一样，仍然是计算机视觉领域的基础任务之一。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image43.png)

多年来，人们提出了众多用于**目标检测**的算法。我们将简要概述其中部分算法并重点介绍其关键贡献。然而，即使仅限深度学习领域，相关文献数量也远超本文所能涵盖的范围，尤其是过去10至15年间的研究成果。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image44.png)

为了解决**目标检测**中单个物体的问题，我们必须执行分类以生成标签和类别分数，同时获取边界框坐标。具体而言，我们需要输出框坐标\\((x, y, h, w)\\)以及物体的类别。这便定义了目标检测的任务。

解决方案很直接。我们可以为类别分数定义一个**softmax损失函数**，并为框坐标定义一个回归损失函数——**L2损失函数**。将这两个损失函数结合起来，就得到了一个**多任务损失函数**，使我们能够同时解决这两个任务。通过将损失值相加，我们创建了一个复合损失函数，如图所示。这种方法既简单又可行。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image45.png)

如果我们只有一个对象，可以采用我之前讨论的架构来解决这个问题。然而，当场景中存在**多个对象**时，任务会变得更具挑战性。

对于三个对象，我们需要生成12个输出值，随着对象数量的增加，复杂度会进一步提升。这种方法不具备可扩展性，因为它只是将分类问题简单扩展为**目标检测**的初级形式。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image46.png)

在处理多个物体时，一种方法是将**边界框**而非整张图像作为输入。每个边界框可被赋予单一标签，例如*猫*、*狗*或*背景*。通过对每个边界框单独分类，可以应用**滑动窗口技术**。该技术需生成边界框并在图像上滑动，覆盖所有可能的坐标\\((X, Y)\\)和尺寸\\((H, W)\\)组合，以实现物体检测。  

通过此流程，可识别出每个物体对应概率最高的边界框。然而，由于边界框组合数量庞大，该算法存在**难以扩展**的核心缺陷。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image47.png)

在文献的早期阶段，尤其是2014年之前，大量研究集中于识别可能包含物体的高概率区域——这些区域被称为**候选区域**。若能有效定位这些候选区域，问题就会变得更容易处理，因为这与我之前描述的方法思路一致。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image48.png)

对于一张图像，如果我们有**候选区域**，就可以提取出一个图像块并用**卷积神经网络** (CNN)进行处理以完成分类。此外，我们还能通过优化边界框坐标来提升目标检测效果。

这种方法既能对候选区域进行分类，又能根据需要调整边界框。该技术被称为**R-CNN算法**，是CVPR 2014会议上提出的早期目标检测方法之一。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image49.png)

这些方法速度非常慢，因为它们需要为每个边界框运行完整的**卷积神经网络**。不过存在解决方案：我们可以利用卷积操作的**空间保留特性**，而非单独处理每个边界框。

由于卷积运算通过下采样或上采样保留了空间信息，我们可以在像素空间中追踪其位置。因此，我们建议对整个图像实施单次卷积运算，而非单独处理各个图像块。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image50.png)

现在，我们已经得到了特征图中与整张图像对应的各个区域。接下来，我们将对这些区域进行检测，并在其基础上应用一个更小的**卷积神经网络（CNN）**来生成两个输出：用于调整边界框的**框偏移量**以及物体类别。这是我们CNN的快速版本。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image51.png)

这些是基于**卷积神经网络**的基础目标检测算法，包含**边界框定位**功能。候选区域的数量是预先设定的。  

我将简要介绍**区域提议网络**。该流程涉及在图像或其对应的特征图上放置边界框，同时生成类别标签和偏移量以优化检测对象的定位精度。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image52.png)

这要求我们首先使用区域提议网络(RPN)生成边界框区域提议，以识别图像中潜在的感兴趣区域。研究重点在于开发RPN网络，我们通过在图像上随机初始化CNN的候选框位置来实现这一目标。

通过卷积层，我们根据这些区域包含物体的可能性对其进行优化，并利用物体标签和位置信息进行监督优化。RPN会调整具有高物体概率的边界框坐标，最终输出经过优化的边界框。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image53.png)

关于坐标和维度的具体细节，我将留待你稍后自行查阅，因为现在详细讨论会耗费太多时间。  

**关键在于**，针对你的问题，我们通常选择**概率最高的前K个区域**作为该图像的候选提案，这些区域最可能包含目标物体。  

这张图片很简单，只有一个物体，因此大多数区域都集中在它周围。但实际情况通常并非如此。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image54.png)

在不同配置中，**区域提议**可用于以更高置信度分数检测多个目标。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image55.png)

在详细讨论了**RCNN**和**Mask RCNN**之后，重要的是你需要亲自进行相关计算，这将大有裨益。然而，由于计算成本高昂，这些算法如今已不再被广泛使用。  

理解它们的历史意义固然有价值，但其效率低下的根源在于需要两个独立的网络：**区域提议网络**和**分类与边界框优化网络**。这意味着每张图像的目标检测至少需要两次前向传播。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image56.png)

单阶段目标检测器已取得显著进展，例如SSD系列。其中最著名的代表当属**YOLO**算法。若从事计算机视觉领域，您必然对YOLO耳熟能详。即便在今天，YOLO仍保持着重要地位——尽管其早期版本由于采用计算密集的复杂卷积架构而存在较高算力需求。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image57.png)

在许多工业应用中，YOLO（You Only Look Once）因其速度和准确性成为目标检测的基础框架。这种单阶段检测器只需单次处理图像，即可同时生成所有边界框和类别概率。该方法由Redmon等人于2015年提出，在保持高性能的同时实现了**实时目标检测**能力。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image58.png)

该系统的工作原理是将图像划分为一个**S×S网格**——在本例中为7×7网格。对于网格中的每个单元，全卷积网络会输出对象存在的概率，以及边界框的调整参数。具体而言，它会生成**B个边界框**及相关超参数，代表对该单元内检测到的任何对象的调整。此外，它还会为检测到的对象生成类别概率。

例如，当**B=2**时，网络会生成两个具有不同概率的边界框。这一过程在所有网格单元中同步进行，同一网络会为每个边界框生成相应的输出。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image59.png)

它为物体生成多个候选框，每个边界框都关联一个概率值。在本例中，**概率**通过每个方框的边权重来体现。基于这些大量的边界框和物体概率数据，我们现在可以应用阈值处理。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image60.png)

此外，该论文采用了一种涉及**非极大值抑制**和阈值处理的算法来识别最高概率实例。此处不再赘述具体细节。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image61.png)

这展示了一个**目标检测**的直观实现。探索**YOLO代码库**非常有益，因为许多更新版本被广泛应用于医疗、机器人和工业领域。  

关键问题在于：我们如何获得第二张图像，其背后的原理是什么？如前所述，对于每个网格单元，我们会生成\\(B\\)个边界框——本例中为两个。每个框都关联着一个**概率向量**，表示对象存在的可能性。将这些框在所有网格块上聚合，就能得到大量带有对应概率的检测框。  

让我们继续推进。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image62.png)

物体检测领域较新的方法之一是DETR（Detection Transformer），它完全基于transformer架构。正如上周讨论和今天重温的那样，同类型的自注意力与交叉注意力模块可以生成物体检测结果和边界框。

该方法源自2020年的一篇论文（ECCV 2020），虽然现在被认为在实际应用中有些过时，但仍是使用transformer进行物体检测的绝佳范例。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image63.png)

此处的流程与我们先前讨论的类似。图像首先被分割成多个区块，这些区块随后通过卷积神经网络（CNNs）处理生成标记。位置编码会被添加到这些区块上，从而定义出Transformer编码器的输入标记。编码器由多层自注意力机制、层归一化及多层感知机（MLP）构成，最终输出处理后的标记。  

为生成边界框，算法会智能地将编码器输出的标记作为**Transformer**(解码器)的输入。通过引入可训练的查询参数——例如输入五个、十个或二十个查询，即可检测图像中相应数量的目标物体。解码器利用自注意力层和编码器输出的交叉注意力层，为每个查询生成数值。这些数值经由**前馈网络**(FFN)处理后，输出类别标签与边界框坐标，或标记为未检测到目标。  

最终输出包含边界框及其对应类别。需特别说明的是，并非所有可能的边界框都会被输入到Transformer中处理。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image64.png)

输入由可训练参数组成，这些参数作为查询向量，代表期望输出的目标对象。与传统方法不同，该系统没有输入框设计，而是由模型同步生成类别标签和边界框坐标作为输出。这些查询向量在结构上同时规定了需要寻找的对象特征及其在图像中的空间位置。

类别标签采用预定义形式并作为输出的一部分，构成监督学习的基础。算法通过与其他方法相似的类别概率向量来识别待检测的类别类型。输出结果通过计算预测框与真实框之间的L2损失进行监督训练。

查询过程并不会明确指导模型应该寻找什么对象或在哪里寻找。相反，训练过程依赖反向传播机制来自动修正输出误差。初始阶段不提供任何具体指令，查询仅要求最多输出九个对象——这正体现了该方法的核心理念。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image65.png)

通过**自注意力**和**交叉注意力**机制，模型生成输出标记，随后经由**前馈神经网络**操作将其转换为类别和边界框坐标。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image66.png)

你的问题是这些查询是否与图像块相对应。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image67.png)

不，它们并非图像块。这些是作为查询使用的**可训练参数**，用于生成输出结果。对于每个输入，输出包含类别标签和边界框坐标。物体查询初始化为可学习的参数，网络在训练过程中会优化这些参数值。

关于将前馈网络(FFN)分配给特定边界框的问题，并不存在预定义的映射关系。网络通过多层的**自注意力**和**交叉注意力**机制，确保每个查询都能与输出层交互，从而避免冗余输出。监督信号会作用于前馈网络以指导其预测。

该算法训练时不需要像素级分割数据，仅需类别标签和边界框即可运行。但如果存在像素级分割数据，可将其转换为边界框用于训练。

对于未见过的物体类别（新类别标签）的泛化问题，全监督网络通常无法在没有先验知识的情况下处理未知类别。虽然支持背景或"无物体"标签，但这类算法的**零样本学习**扩展方案可能解决这一局限性。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image68.png)

**零样本学习**指的是在训练数据中无需先验示例即可理解新概念的能力。不过，这已超出了我们当前讨论的范畴。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image69.png)

如果场景中的物体数量超过了提供的查询数量，模型通常会为检测到的物体生成**置信度最高**的边界框。为了解决这个问题，增加查询数量有助于捕捉更多物体。

下课后我会继续留在这里解答大家的问题。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image70.png)

不过，我们还有其他几个议题需要讨论，我希望确保能逐一处理。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image71.png)

为了熟悉这些主题，让我们重新审视之前关于**目标检测**的问题。我们如何将这些算法应用到**实例分割**中？这一转变相对简单直接。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image72.png)

我们在**CNN算法**的背景下讨论了这一点，其中CNN被应用于图像处理。随后，**区域提议网络**会提供边界框，这些边界框会被进一步转换为类别标签或精修的边界框坐标。  

这总结了我们之前关于CNN的讨论。现在，我们可以通过增加一个额外的输出来扩展这一架构，以生成掩模预测，从而使模型更加**多任务导向**。其底层结构与我们之前描述的内容保持一致。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image73.png)

此前，我们的方法采用**区域提议**处理图像，通过卷积神经网络（CNN）同时输出类别标签和边界框坐标。  

如今，我们新增了一个**卷积层**，用于生成物体的像素级掩码。该掩码的尺寸可与输入图像保持一致。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image74.png)

在该层本身，当使用**全卷积神经网络**时，这通常是我们获得的输出。对于每个对象，给定其边界框，我们可以推导出相应的掩码。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image75.png)

这把**椅子**可根据箱体配置调节至不同档位。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image76.png)

图片中的**床**和人类**婴儿**。这是R-CNN算法的扩展版本，称为**Mask R-CNN**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image77.png)

借助**Mask R-CNN**，该算法在检测训练过的各类已知物体时表现优异。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image78.png)

众多**目标检测器**的API和开源实现可供探索，相关链接与资源已在此处提供。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image79.png)

这概括了我们旨在涵盖的关键任务，这些任务对于理解**计算机视觉核心概念**仍然**至关重要**。尽管现代计算机视觉已远超这些基础任务范畴，但它们仍是构建该领域专业知识的基石。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image80.png)

在工业应用中，例如生产线质量控制中需要区分**新鲜**和**腐烂番茄**的任务时，**计算机视觉**发挥着关键作用。这要求系统具备目标检测与分类的能力。  

理解这些步骤与流程，并实现实时处理仍然至关重要。不过技术进步推动了**更大规模模型**的发展，这些模型您可能已有所了解。  

以上就是我们关于计算机视觉任务讨论的第一部分。最后约10分钟的环节，我将重点讲解**可视化**与理解相关内容。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image81.png)

本次讲座内容相当丰富。从20世纪50、60年代直到2020年代，甚至更早的2013-2014年间，**神经网络可视化**这一主题始终备受瞩目。它极大地增进了我们对神经网络所学内容的理解。我将总结一些最重要的技术，这些可能在您的实际应用中大有用处。

在继续之前，请允许我回顾先前讨论过的**线性分类器**。我们在线性分类器上投入了大量时间。通过观察这些分类器的线性函数，我们发现可以提取出每个类别的模板。例如，一辆正面朝向的汽车就是汽车类别的模板。这种方法同样适用于神经网络。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image82.png)

如果我们可视化其中一个滤波器，本质上是在检查线性函数的权重。同样的方法可以应用于**神经网络**中滤波器的可视化。对于每个滤波器，网络会学习识别基本形状和方向，如图所示。  

然而，这种可视化仅适用于通道数较少的层。例如，对于三个通道的情况，我们可以将其表示为**RGB图像**以便可视化。但在**卷积神经网络** (CNNs)中，这种情况并不常见。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image83.png)

在**卷积神经网络（CNNs）**中，中间层通常包含大量通道，这使得可视化变得颇具挑战性。然而，这本质上正是我们所观察到的现象。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image84.png)

在通道数较少的初始层中，我们可以可视化网络学习到的模式。这些早期模式较为简单，而**深层网络**则能捕捉更全面、更复杂的特征。虽然**导向反向传播**技术能够实现对这些深层模式的可视化，但该过程相比浅层特征的可视化要复杂得多。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image85.png)

我想重点介绍几种评估和可视化神经网络的方法，这些方法尤为重要。其中一种方法涉及**显著性图**的概念。在许多应用中，识别哪些像素具有重要性至关重要。例如，在医学影像中，对肿瘤进行分类时，必须确定图像中包含肿瘤的具体区域。自动化这一过程不仅需要检测肿瘤的存在，还需在图像中对其进行定位。  

为实现这一目标，我们可以训练一个输出类别标签的**前馈神经网络**。在此之前，需要注意的是，在训练过程中，我们通常计算损失或类别分数相对于网络权重的导数来更新权重。然而，对于显著性图，我们改为计算类别分数相对于输入像素值的梯度。  

该梯度反映了每个像素对类别分数的影响程度。通过可视化这些梯度，我们可以识别对分类任务最关键的像素。例如，改变这些像素的值将直接影响“狗”类别的分数。这种方法利用了先前讨论的**梯度**这一基本概念。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image86.png)

如果你将此应用于网络训练过的各种对象，**你将得到以下结果**。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image87.png)

这是理解**显著性**的一种方法，该方法在许多场景中被证明极为有效。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image88.png)

然而，问题并不总是仅关乎像素值本身。理解各类别激活机制如何运作至关重要，这便引出了**类别激活映射（CAM）**。虽然CAM及稍后将讨论的**Grad-CAM**是卷积神经网络最主流的解释性算法，但它们同样适用于其他架构。不过对于Transformer模型，正如前文所述，我们拥有更高效的解读方法。

在卷积层中，池化操作会生成特征图，这些特征图随后被转化为得分。通过扩展数学表达式，我们可以利用权重值的加权求和来突出类别得分。这使得我们能够将类别预测溯源至特征图及图像中的具体空间位置——因为卷积层本质上就映射着图像的空间维度。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image89.png)

卷积操作在所有处理步骤中**保持空间一致性**，这使得我们能够回溯到原始图像空间。通过观察特征图，我们可以发现**类别激活**如何影响图像中的特定区域。将学习到的权重与特征值相乘，即可生成这些类别激活。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image90.png)

这意味着我们现在拥有一种返回图像空间的方法。只要保持在卷积空间内，我们就能追溯至原始图像并生成**类别激活图**。

例如，针对宫殿、圆顶、教堂、祭坛和修道院等类别，可以创建不同的类别激活图。这些图会突出显示卷积层中影响这些特定类别得分的**权重**、像素或区域。

同样的原理也适用于其他情况，比如针对同一物体在不同图像中的类别激活图。但存在一个局限性：该方法只能应用于最后一个卷积层，因为相关计算仅限于该层。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image91.png)

为解决这一问题，研究人员开发了该算法的变体——**Grad-CAM（梯度加权类激活映射）**。该方法遵循相同的基本原理，但改进了权重计算流程。

不同于简单地计算权重与特征的乘积，我们通过反向传播梯度来创建基于这些梯度的权重。这些**梯度派生权重**取代了原始权重，有效聚合了直至目标层的所有权重与梯度。

最后，我们应用**ReLU激活函数**以仅保留正值。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image92.png)

这一概念同样可以在类别内的图像空间中充分展现。我之前讨论过的**类别激活映射（CAM）**仅应用于最后的卷积层，但这种方法往往不切实际，因为大多数CNN架构并非以单一卷积层结束——它们通常还包含全连接层等其他操作。

为了将类别激活信息通过中间层传递至卷积层，我们经常采用**梯度加权技术**，本质上就是将激活图与聚合梯度相结合。这种方法能够实现有效的可视化，为单个物体生成热力图。



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image93.png)

本次讨论聚焦于**卷积神经网络** (CNNs)，但我们在上一讲中已涵盖**Transformer**架构。Transformer本质上包含激活映射图。  

回顾Justin展示的语言矩阵案例，每个输出词都对应一个输入注意力图。同理，我们可以在像素空间中为每个输出生成这类映射，从而实现**视觉Transformer** (ViT)特征的可视化。  

使用ViT和Transformer架构时，这一过程会变得显著更直观。  





![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec9_image94.png)

我们已有可视化**注意力权重**的方法。对于**卷积神经网络** (CNNs)，通常采用**Grad-CAM**或类似算法。

起初我担心今天能否涵盖所有计划内容。下节课我们将重点讨论**视频理解**领域。

谢谢。  



