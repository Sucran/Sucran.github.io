---
title: "Stanford CS231N Deep Learning for Computer Vision | Spring 2025 | Lecture 15: 3D Vision"
date: 2025-09-11T13:30:26+08:00
draft: true
description: ""
---

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image1.png)

I'm honored to introduce our next guest speaker for this course—**Professor Jiajun Wu**. Jiajun is currently an **Assistant Professor of Computer Science at Stanford University** and a core member of the Stanford Vision and Learning Laboratory.

His research focuses on the field of **scene understanding**, particularly multimodal perception, robotics, embodied AI, visual generation, reasoning, and 3D understanding—which is also the theme of today's lecture.

Now let's welcome Jiajun to begin his presentation.



Hello everyone, I'm Jiajun Wu, currently an **Assistant Professor** in the Computer Science Department at Stanford University. A few years ago, I had the privilege of co-teaching this course. This year marks the **tenth anniversary** of the course, and we've invited guest lecturers from different institutions to participate in teaching.

Today's lecture will focus on **3D vision**, which differs from the topics discussed previously. Over the past few weeks, we've covered convolutional neural networks, Transformer architectures, vision-language models, and generative models.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image2.png)

In the field of **3D vision**, I'll first introduce the concept of **3D representation**. Although this initially seems somewhat distant from deep learning, we'll explore how AI has transformed 3D vision and the various ways they can be integrated. We'll also study applications such as **3D generation** and **shape reconstruction**.

Let's start by thinking about how to represent 3D objects. In **2D**, representation is straightforward—we simply use pixels, such as 200x200 PNG or JPEG files. However, representing 3D objects requires different approaches, which we'll explore next.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image3.png)

3D objects can be diverse and exist at different scales.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image4.png)

They can encompass large buildings, trees, and complex structures. When magnified, fine details become clearly visible. **What is the best 3D representation method for capturing these diverse objects at different scales and features?**



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image5.png)

Unlike images that universally use **pixels** (such as 200x200 or 500x500), representing 3D objects involves multiple aspects, including geometry, texture, and materials. Let's start with geometry. For the geometric shape of 3D objects alone, there are multiple representation methods, roughly divided into two categories.

The first category is **explicit representation**, which directly and explicitly represents various parts of objects. Examples include **point clouds** (collections of 3D points), polygonal meshes, and subdivision surfaces that we'll discuss later. The second category is **implicit representation**, such as level sets, algebraic surfaces, and distance functions. These methods represent 3D objects or their geometric shapes as mathematical functions, which may not be as intuitive as point-based representations. However, as we'll explore, implicit representations have unique advantages and disadvantages.

Each representation method is suitable for specific tasks and geometric types. In the context of **deep learning**, these representation methods also exhibit different advantages and disadvantages when combined with deep learning methods. So the question arises: when should we choose a specific representation method?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image6.png)

We need to store **3D shapes**, which is relatively straightforward for pixels since they form matrices, but **3D point clouds** are more irregular. When using **implicit representation** (for example, representing objects as functions), the challenge lies in how to store it through computation and support operations such as creating new shapes. Inputs may include images or language descriptions, requiring various operations on 3D objects—editing, simplification, smoothing, filtering, and repair. Similar operations also apply to images, such as editing through language or brushstrokes.

**Rendering** involves converting 3D objects to 2D pixels, while **3D vision** typically performs this process in reverse, reconstructing 3D objects from 2D images. Other considerations include animation, particularly for 3D humans or animals, and integration with deep learning methods for shape editing, rendering, inverse rendering, and animation.

**Point clouds** are the simplest form of 3D representation, consisting of 3D points without connection relationships. Unlike \\(n \times n\\) pixel matrices, here we use \\(3 \times n\\) matrices to store XYZ coordinates of each point. **Surface normals** can enhance this representation, indicating the orientation of each point, often called "surfels." Surface normals are crucial for achieving realistic rendering because they determine how light interacts with object surfaces.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image7.png)

**Surface normals** are used to enhance rendering realism, as shown here. So the question arises: how do we obtain these points?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image8.png)

**Point clouds** are typically the raw output format of various 3D sensors, including depth sensors and 3D scanners. Modern tools like iPhone's ARKit can achieve 3D object scanning, but the initial output is still 3D point clouds, requiring subsequent processing to fuse and optimize these points into textured objects.

Point clouds can flexibly represent diverse object geometric forms because they're not constrained by topological structure. However, point clouds may contain noise and require **registration** techniques to align multiple scan results into coherent clouds. This flexibility supports free manipulation of points, but uneven sampling (such as dense point clouds in rabbit heads and sparse ones in tails) poses challenges for uniform sampling algorithms.

Their limitations lie in the difficulty of directly performing operations like simplification or subdivision on point clouds, and the lack of topological information—without additional context, it's impossible to distinguish shapes like tori from ring structures. This incomplete representation naturally prompts people to explore **polygonal mesh** techniques that can provide richer structural details.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image9.png)

This representation method not only contains collections of **points** but also their connection relationships. In addition to points, it also covers **faces** and **surfaces**. **It can be said that this is the most widely used 3D object representation method in graphics engines and computer games**, where all objects are essentially represented as polygonal meshes.

However, face representation introduces complexity, especially since each face in raw meshes may contain different numbers of points—three, four, five, or even more. This structural irregularity poses challenges for integration with **neural networks**. Early deep learning methods typically assumed fixed resolution, but raw mesh data naturally has variable dimensions.

This difference constituted a major obstacle when applying deep learning methods to **3D vision**, because 3D object representations lacked the uniformity of images. Therefore, while researchers explored how to handle these complex geometric structures, deep learning progress in 3D vision was once lagging.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image10.png)

Meshes are widely used and can be extremely complex, capable of capturing **delicate details**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image11.png)

For example, after capturing point cloud data using **scanners**, applying **fusion algorithms** can generate large-scale meshes. In this case, a reconstructed model of a sculpture contains 56 million triangular faces and 28 million vertices, with potential for handling even larger 3D reconstruction projects.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image12.png)

Through **Google Earth**, they use trillions of triangles to present global buildings. The advantage of **meshes** lies in supporting operations like subdivision.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image13.png)

To enhance **detail capture**, additional meshes can be utilized. Simplification techniques are equally applicable.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image14.png)

Sometimes, **processing speed** is a priority consideration, and fewer meshes are sufficient. Existing algorithms enable us to simplify meshes accordingly.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image15.png)

**Regularization** is crucial when processing meshes. **Regular meshes** ensure that each face is a triangle, connected by three vertices of roughly equal size. This uniformity not only facilitates processing but also provides favorable properties for various graphics algorithms.

Additionally, regularization can ensure uniform distribution of sampling points in different regions, thereby avoiding situations where sampling density in certain areas (such as rabbit heads or tails) is disproportionate to other areas. Researchers have developed various algorithms to achieve this balance.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image16.png)

This is one of many **shape representation methods**. For example, **parametric representation** is very practical because objects are not completely irregular. Although non-parametric point clouds and meshes are highly versatile, they sometimes lose important information. Taking chairs or tables as examples, they typically contain linear structures—how do we represent these lines? Designers often use parametric representation, defining shapes through functions.

When representing surfaces or curves, their inherent **degrees of freedom** are fewer. For example, curves can be represented by function \\(f(x)\\), obtaining \\(y\\) values by changing \\(x\\). This principle can be extended to 2D and 3D spaces, mapping intrinsic dimensions (usually one-dimensional or two-dimensional) to 3D space. Parametric representation describes 3D objects through function collections.

For curves like circles, one method is to sample points or connect them into meshes; another is parametric representation using sine and cosine functions. By changing a single parameter \\(t\\) (such as angle), all points on the circle can be mapped. This method applies to both 2D and 3D modeling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image17.png)

To represent a **sphere**, only two degree-of-freedom parameters **U** and **V** are needed. These two parameters can map to each point in the sphere's 3D space.

More complex parametric representation methods (such as **Bézier curves** and **Bézier surfaces**) can present flexible and smooth surfaces in 3D space through a finite number of control points.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image18.png)

Essentially, you use these **basis functions** to capture the underlying low-dimensional structure of surfaces, enabling mapping of these low-dimensional representations to flexible forms.

Additionally, they support operations like **subdivision**, allowing incorporation of finer details into surfaces for higher granularity.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image19.png)

This introduces the second category of shape representation methods. **3D objects** can be represented in both non-parametric and parametric forms. Non-parametric representations include unordered point sets or their connectivity graphs, while parametric representations utilize underlying functions controlled by parameters to generate more complex shapes, with these parameters capturing the geometric degrees of freedom of objects.

As mentioned earlier, there are two basic methods for representing object geometry: **explicit** and implicit. The current discussion focuses on explicit representation, where points directly correspond to object positions—whether on surfaces or parametric curves.

These explicit representations have significant advantages, particularly in **direct point mapping**. For example, for parametric surface representation, by sampling points in the underlying UV parameter space and applying mapping functions, corresponding 3D points can be obtained in object space.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image20.png)

I can directly obtain a point on the **3D surface** in space. Essentially, all points are explicitly given, allowing me to access them directly. This makes point sampling very intuitive.

For example, consider this torus represented by function \\(F\\).



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image21.png)

Now, my question is: can we perform point sampling on the object surface? This is simple. By randomly selecting **UMV values** and substituting them into the function, we can obtain **3D points** guaranteed to be on the object surface. The sampling process is very direct.

However, the challenge with **explicit representation** lies in determining whether a point is inside or outside the object. For example, when representing a sphere with a function, although surface points can be easily sampled, testing the position of query points like \\(\left(\frac{3}{4}, \frac{1}{2}, \frac{1}{4}\right)\\) in 3D space is quite difficult.

Explicit representation has its advantages and disadvantages. Although sampling points is easy—which is useful for converting to **point clouds** for network processing—testing point containment is difficult. This limitation troubles modern rendering methods because these methods typically need to query point positions, geometry, density, materials, or radiance. Explicit representation is not suitable for such operations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image22.png)

Naturally, researchers considered other methods for representing geometric shapes, leading to the concept of **implicit representation**. These representation methods were subsequently extended by newer rendering and deep learning techniques, capable of modeling not only geometry but also color and appearance of 3D objects.

The core idea of implicit representation is to classify points based on their relationship with object surfaces. For example, points on a unit sphere must satisfy the constraint \\(x^2 + y^2 + z^2 = 1\\). More generally, this constraint can be expressed as function \\(f(x, y, z) = 0\\) for all points on the surface.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image23.png)

In this case, function \\(f(x, y, z)\\) can be expressed as \\(x^2 + y^2 + z^2 - 1\\). For more complex shapes, these functions may become highly complex, sometimes even without closed-form solutions. In such cases, we can use **neural networks** to represent \\(f\\), expecting the network to learn to approximate this function.

The core idea is that given points on objects satisfy specific function constraints, this method is called **implicit representation**. Although originating from geometry, implicit representation has now been extended to model textures, materials, appearance, and other properties.

The **key advantage** of implicit representation lies in its flexibility. However, a significant disadvantage is the increased difficulty of sampling points from this representation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image24.png)

This is the constraint condition. Consider a torus: for any point \\((x, y, z)\\), if the function value is zero, then the point is on the object surface. However, **sampling these points is challenging** because this requires solving the function. Although simple functions might be solvable with high school mathematics, complex functions describing arbitrary shapes would make this process extremely difficult.

The advantage of **implicit representation** is that it can easily determine whether a point is inside the object. By querying function values: if negative, the point is inside; if positive, it's outside. This test is very direct, while surface point sampling is computationally expensive.

This reflects the trade-off between implicit and explicit representations. **The fundamental difference between these two representations** is crucial, especially when applying deep neural networks to 3D data.

Before discussing the application of deep learning in 3D representation, let's briefly look at other advantages of implicit representation. One notable characteristic is **composability**. Although closed-form representations have precision, they may seem limited due to the regularity of the geometric shapes they describe.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image25.png)

To represent the form of a cow, the question arises: what kind of function can describe it? This is not obvious. However, the **advantage** of implicit representation lies in the convenience of composition—you don't need to define everything at once.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image26.png)

You can perform logical operations on these **implicit functions**. Taking two objects as an example: you can compute their union, intersection, or difference. Since these functions output scalar values for any input \\((X, Y, Z)\\), you can perform arithmetic operations on these values. This achieves construction of complex shapes through **Boolean operations**.

This principle is the foundation of many industrial design processes. For example, in manufacturing, complex parts are often designed through **CAD (Computer-Aided Design)** models, which are precisely constructed by combining implicit functions through logical operations.

In addition to Boolean operations, **distance functions** provide more flexibility. Here, the function value at a point represents the signed distance from that point to the object surface. By summing these functions, smooth shape blending can be achieved—a powerful technique in geometric modeling.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image27.png)

Here, if we represent a vertical line with a **distance function**, then negative values are on the left side of the line, and positive values are on the right side. Another line can be represented with a different function.

When these functions are added together, they naturally interpolate between the two shapes. This example demonstrates the concept in **one-dimensional** space, but it can also be generalized to **three-dimensional** space, achieving blending of different shapes.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image28.png)

These distance functions can be arbitrarily combined to construct complex worlds, as shown here. Although challenging, through clever combination of these functions, people can construct complex environments with **fine features**. Once mastered, they prove to be **highly expressive**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image29.png)

We discussed **parametric representation**, which can be explicit—directly providing points on 3D surfaces—or implicit, verifying through functions whether a point is inside or outside an object. These implicit representations can be combined to construct more complex shapes.

Are there **non-parametric implicit representations**, such as point-based methods, that can still query functions? Indeed, such methods exist, leading to techniques like **level set methods**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image30.png)

The advantage of implicit surfaces lies in easy merging and splitting, but there are challenges when describing complex geometric shapes in closed form. For example, to express complex structures like **cal**, numerous functions need to be combined. Determining whether a point is inside such shapes requires evaluating hundreds of functions and performing addition, subtraction, or logical operations, which is time-consuming.

An alternative is to pre-sample 3D space, for example using a 100×100×100 grid, generating millions of pre-sampled points. For these points, we pre-compute whether they're inside objects and their distances to surfaces, storing these values in a **3D matrix**. Although the example is shown in 2D form, the actual implementation is based on 3D space.

This method converts implicit expressions into **non-parametric expressions** by pre-computing function values for massive points. By observing the matrix, boundaries can be identified when adjacent values change from positive to negative—here function \\(f(x)=0\\), meaning the point is on the surface.

Therefore, by pre-computing sampled points through functions, implicit expressions are converted to non-parametric forms. Based on stored matrix values, this method enables more precise control, supporting visualization and geometric operations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image31.png)

This method is widely used in medical imaging fields, such as CT scans and MRI. A common consideration is whether **precise distance values** are needed. Rather than tracking all points, we might only need to distinguish between inside and outside regions of objects.

Through binarization—assigning positive values (outside) as 1 and negative values (inside) as 0—a simplified representation called **voxels** can be obtained. This method can intuitively present boundary characteristics of implicit functions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image32.png)

Unlike storing functions representing distances from points to surfaces, you can binarize the data. This method only needs to determine whether a point is inside or outside an object, resulting in voxel representation. Voxel grids are essentially 3D matrices (for example, 100×100×100), where each point is assigned a binary value (1 for inside, 0 for outside), providing an intuitive representation for 3D objects.

Voxels share many similarities with pixels, both based on grid representation—pixels for 2D, voxels for 3D. Although voxels are associated with other shape representation methods, their introduction is closely tied to the rise of deep learning. Deep learning emerged around 2010, with Geoff Hinton's breakthrough in speech recognition and AlexNet's success in 2D image classification in 2012 becoming milestones. Naturally, researchers hoped to extend these techniques to 3D data. The challenge at the time was: how to adapt the then-dominant 2D convolutional neural networks to 3D representations like voxels.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image33.png)

Initially, it was researchers in computer vision rather than graphics who first applied **deep learning** to 3D data. Their approach was straightforward: extend 2D methods to 3D. So, building on 2D convolutional neural networks, they developed **voxel convolutional neural networks**. Among various 3D representation methods, **voxels** naturally support volumetric convolution operations, making them the most convenient choice. However, the graphics community quickly pointed out voxels' flaws: computational inefficiency and inferior generation quality compared to meshes or point clouds. Despite this, voxels remained popular due to their conceptual similarity to pixels—only requiring replacement of 2D convolution with 3D convolution, with minimal code changes. This became early practice in deep learning for 3D data.

Before discussing deep learning methods for 3D data, we must mention the importance of **datasets**. Just as ImageNet gave birth to breakthroughs like AlexNet in 2D fields, 3D deep learning also requires massive data support. Before the deep learning era, the **Princeton Shape Benchmark** was the mainstream dataset, containing 1,800 models across 180 categories. Although the number of categories was considerable, with only about 10 models per category on average, this highlighted the urgent need for larger datasets at the time.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image34.png)

At the time, this scale was considered relatively large, and many people thought it was sufficient because existing methods performed poorly on such datasets. **Machine learning** was hardly adopted.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image35.png)

Before 2014, most **3D shape datasets** were relatively small, typically containing at most 10,000 models. However, these models were divided into numerous categories, resulting in only about 10 to 100 models per category.

Subsequently, researchers realized the need for large 3D datasets similar to **ImageNet**. This gave rise to multiple parallel research efforts, eventually integrating to form **ShapeNet**—a large-scale dataset containing 3 million models.

ShapeNet's development was primarily led by Stanford researchers, including **Leo Gibas** and **Silvio Severasi**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image36.png)

Actually, similar to ImageNet, **ShapeNet** also has a widely used core dataset, containing about 50,000 models across 55 categories. On average, each category has about 1,000 models, but the distribution is not uniform.

For example, chairs have significantly more models. This difference led to initial research focusing mainly on chairs and cars, as they were the largest categories in ShapeNet. Researchers realized the **limitations** of this approach and attempted to expand the scope, incorporating more diverse and broader datasets.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image37.png)

In recent years, researchers at the Allen Institute for AI (AI2) in Seattle have constructed significantly larger datasets **Objverse** and **Objverse-XL**, containing about 800,000 and 10 million 3D asset models respectively. These datasets have broader category coverage and higher model quality, with textures attached.

Although these are synthetic datasets, real-world datasets are also developing simultaneously, such as data based on 3D scanning. The **Redwood dataset** released in 2016 contains about 10,000 scans of real objects.

Recently, projects initiated by institutions like **Meta** and **Oxford University** encourage public participation in data collection. Participants use iPhones to shoot 360-degree videos of objects placed on tables and receive small monetary rewards. This initiative has collected 19,000 object videos, representing real objects—which are much more difficult to obtain than synthetic data.

These paired datasets composed of videos/images with 3D geometry and textures are valuable for advancing **3D vision algorithms**.



This is the initial version.



I believe they've released updated versions, possibly **V2** or even V3, with slightly larger sizes. However, **scaling up** remains challenging.

Currently, the dataset contains about 19,000 objects or 90,000 video segments. Although efforts are being made to expand, the total number of real objects hasn't exceeded 100,000 models.

In contrast, **image datasets** are much larger, typically reaching 5 billion images. Companies like **Google** and OpenAI may have even larger datasets.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image38.png)

There's still a significant gap between 2D images or videos and 3D objects in terms of available **data points**. This poses major challenges for advancing **3D vision** research, and multiple solutions are currently being explored.

However, existing datasets have made substantial progress and can train **deep learning models** to some extent. Additionally, there are other datasets containing partial perspective human samples.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image39.png)

This research originated from **Stanford University**, where researchers annotated object parts, their correspondences, and hierarchical structures.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image40.png)

Additionally, there's a dataset called **PartNet**, which not only contains annotations of parts and their semantics but also annotates how these parts can potentially move. This dataset provides **mobility information** for various components, such as the opening and closing mechanism of laptops.

Furthermore, there are datasets for **3D scenes**, covering not only individual objects and their parts but also entire room layouts.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image41.png)

Datasets like **ScanNet** typically require individuals to use 3D scanners to scan home or office environments and annotate data. Although recent technological advances have allowed this process to be completed through devices like iPhones, the scale of such datasets remains relatively limited. The initial version of ScanNet contains 1,500 scan records, and its extended version (**ScanNet++**) covers about 2,000 to 3,000 rooms. Compared to 2D optical data, existing 3D scene data is significantly less abundant, and due to the time and human cost required for manual scanning, this poses challenges for large-scale applications.

When applying deep learning to 3D vision, there are several core task categories:

1. **Generative modeling**: Similar to generating 2D images or videos, models can synthesize 3D shapes and scenes. Such models can be controlled based on input conditions like language or images, achieving tasks such as single-image 3D reconstruction—which requires learning shape priors and shape completion for incomplete objects.
2. **Discriminative models**: Including classifying 3D shapes (such as chairs or tables). Common methods involve rendering 3D objects into 2D images and then using pre-trained vision models (such as **GPT**) for recognition. However, in certain specialized fields (such as 3D cell scan classification), data scarcity brings special challenges.
3. **Joint modeling of 2D and 3D data**: Leveraging massive 2D image and video resources, integrating prior knowledge from 2D foundation models into 3D tasks is increasingly becoming key to improving performance.

These directions highlight the evolving opportunities and constraints in the 3D vision research field.



Understanding the appearance characteristics of images and videos, and how to make them look realistic, can provide basis for more realistic **3D reconstruction**. Due to the richness of large-scale 2D datasets and the existence of advanced protein models, **joint modeling of 2D and 3D data** has significant value. Recent advances in neural rendering and differentiable rendering methods bridge the gap between 3D and 2D worlds. By rendering 3D models into 2D images through differentiable processes or neural network approximation, interconnection of cross-modal data can be achieved. **Differentiable neural networks** make it possible to transfer prior knowledge from 2D data or foundation models to the 3D domain.

In addition to visual data, joint modeling can also integrate text or other sensory inputs, such as tactile data in robotics, or **LiDAR and depth data** in autonomous driving. The challenge lies in how to effectively fuse these diverse data types.

To solve these problems, we first need to think about a fundamental question: when applying **deep learning techniques**, how should we represent 3D data? This discussion will start with exploring **3D shape representation methods**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image42.png)

As I mentioned, **computer vision researchers** initially focused on pixels and images. Naturally, they proposed starting with voxels. This approach represents one of the earliest attempts to apply **deep learning** to 3D vision, and is now experiencing a revival.

The initial idea was intuitive: given a 3D shape—whether mesh or voxel—the goal is to identify objects, such as recognizing a chair. But when input data is 3D, challenges arise.

Before **3D deep learning methods** emerged, common solutions involved rendering 3D objects into images. By placing cameras at different angles, multiple perspective views of objects could be generated, thus utilizing existing mature image models for processing.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image43.png)

This method transforms the problem into the **2D domain**. By applying convolutional neural networks to each view and implementing fusion techniques such as pooling, this task essentially becomes a multi-view image classification problem. This strategy represents one of the early applications of **deep learning** in 3D vision, with the advantage of leveraging 2D networks—due to their proven performance on large-scale datasets like ImageNet, which historically far exceeded the scale of 3D datasets.

As more 3D data emerged, the field subsequently turned to developing native **3D methods**, including innovative solutions connecting 3D and 2D through advanced rendering techniques. However, recent breakthroughs in image and video foundation models (which are trained on data volumes several orders of magnitude larger than 3D datasets) have rekindled interest in exploring 2D representations. For example, models like **VO3** demonstrate the potential of this revival path.

Looking back at the original method, it vividly illustrates how early deep learning achieved success by transforming 3D data into 2D problems, particularly excelling in image-based shape classification tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image44.png)

These shapes need to be classified into different categories and achieve **excellent performance**. Although existing literature on 2D image filtering models can be referenced, this method requires projection. However, input data may contain noise—point clouds or other representations may result in poor rendering quality.

This raises a question: can we develop more **native 3D methods**? Subsequent research explored directly applying deep learning to 3D data. The simplest method was extending pixel-based convolutional neural networks to **volumetric convolutional neural networks**. For example, **Deep Leaf Network** as a generative model integrated 3D convolutional features.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image45.png)

This work was published by **Princeton** in 2015. They developed a **generative model** capable of synthesizing 3D shapes represented by low-resolution voxels. Although limited in resolution by today's standards, this achievement was considered quite remarkable a decade ago.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image46.png)

You can perform **conditional generation** with semantic labels for objects like **bats**, desks, and tables, synthesizing various shapes. Since this is a generative network, it can also be used for classification tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image47.png)

You can also perform **image shape classification**. Later, we attempted to apply this method to **3D voxels**. Just as GANs can generate 2D pixels, they can also generate 3D voxels. This simple adjustment achieved encouraging results in 3D object generation.

Based on this, in collaboration with Qingyin at CMU, we extended this method—not only generating 3D shapes but also rendering them as **2D projections**. By projecting 3D shapes onto 2D surfaces, we obtained **depth maps**. These depth maps were then converted to color images through **CycleGAN**, thus achieving adversarial training not only on 3D shapes but also on 2D images.

The goal was dual: to ensure that generated 3D shapes are indistinguishable from real 3D object data, and to make rendered 2D images indistinguishable from photos of real objects (such as cars). By decoupling **latent vectors** of shape, viewpoint, and texture, we simultaneously achieved controllability in both 3D and 2D generation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image48.png)

You can modify viewpoints, adjust textures, perform interpolation operations, and transfer one car's texture to another car's shape. This technique was explored in 2018, when researchers applied **deep networks** (such as convolutional neural networks and generative adversarial networks) to **3D voxels** rather than 2D pixels.

But voxels have limitations—slow computation, requiring pre-sampling, and often wasting computational power on empty regions or internal points with no informational value. To address these problems, researchers introduced improvements like **octrees**. Octrees optimize computational efficiency while maintaining explicit representation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image49.png)

In a sense, you can consider this a type of **implicit representation**, but it's similar to non-parametric implicit representation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image50.png)

Unlike uniformly representing each point in space, we can use **voxels** for multi-scale partitioning. Space is divided into different regions: fine-scale voxel representation near object surfaces, while larger-scale voxels in empty or non-critical areas.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image51.png)

You can recursively partition space and use different voxel sizes in different regions, achieving **significant scalability**.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image52.png)

Compared to methods around 2019 that commonly used **voxels** directly, **octrees** have significant advantages. They can achieve higher resolution work under the same GPU memory constraints.

For example, voxel-based methods might be limited to 64×64 resolution, while octrees can achieve 256×256 resolution. This method is equally applicable to generation tasks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image53.png)

Alternatively, you can also generate objects similar to voxels but achieve **higher resolution** through more efficient spatial representation. These examples represent early applications of **deep learning** in 3D space.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image54.png)

Initially, researchers considered using **voxels**, but this method was questioned by the graphics community. Compared to mature representation methods like **point clouds**, meshes, and splines, voxels were considered inefficient and poor in visual quality.

The main challenge with point clouds lies in their irregular distribution characteristics, making direct application of convolution operations difficult. Therefore, researchers began developing new **deep learning methods** that could not only handle 3D data but also be compatible with various 3D representations including point clouds.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image55.png)

In **PointNet**, this important work proposed by the Stanford team led by Leo Guibas aimed to develop a new type of deep network capable of directly processing **3D point clouds**. The core idea was to ensure the network has **permutation invariance**—for example, whether point 1 is here and point 2 is there, or their positions are swapped, the output should remain unchanged, because point clouds inherently have no fixed order. This differs from mesh data (for example, top-left coordinates are fixed at (1,1), bottom-right at (100,100)), where point clouds have no predefined permutation order.

Additionally, the network needs **sampling invariance**. Taking a rabbit model as an example: sampling 10 points in the head and 5 points in the tail, versus sampling 10 points in the tail and 5 points in the head, should not affect the final result, because point sampling itself is random.

The proposed solution was elegant and simple: apply **symmetric functions** to point embedding vectors. First, compute embedding vectors for each point (similar to feature extraction for image regions), then perform feature fusion through symmetric functions like maximum or summation, ensuring permutation invariance. This method is both intuitive and efficient.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image56.png)

Given a set of points, first compute their **embedding vectors**, then perform aggregation. Aggregation can be done by taking the maximum or summation of each dimension. This process ultimately generates aggregated embedding vectors for all points.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image57.png)

This process requires passing data through multiple layers of **fully connected networks**, then using these networks to classify point data, determining whether it represents objects like chairs or tables. This method has proven extremely effective. Subsequent improvements include methods to enhance performance metrics, such as achieving scores of 0.9 or higher.

A notable advancement is the application of **graph neural networks**, where points are treated as nodes in graphs, and their proximity relationships define connecting edges. This has given rise to various point cloud processing techniques. Although the original PointNet paper method was simple, its effectiveness remains significant.

Another consideration is measuring output quality. For pixels, this is relatively direct—comparing output images with ground truth through metrics like **L2 loss**. However, for point clouds, especially in generation tasks, this comparison is more complex. Classification tasks can rely on cross-entropy loss, while generation tasks require specialized distance metrics.

Two commonly used metrics are **Chamfer distance** and another distance metric, which help evaluate similarity between output point clouds and ground truth.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image58.png)

The concept of **Chamfer distance** is very intuitive. Given two sets of points, for each point in one set, find its nearest neighbor in the other set. For example, suppose there's a set of red points and a set of blue points, for each red point find its nearest neighbor in the blue point set, and vice versa. The core goal of this distance is to minimize the distance between each point and its nearest neighbor in the other point set.

Another commonly used loss function is **Earth Mover's distance**. This method requires bipartite graph matching between two point sets, establishing one-to-one correspondence, with the optimization goal of minimizing distances between all matched point pairs.

These two metrics are widely used for comparing distances between point clouds. Both can achieve differentiability, thus supporting gradient computation and neural network optimization, which is particularly useful for improving point cloud generation in related tasks. This completes our transition from voxels to point clouds.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image59.png)

This method is very suitable for processing and outputting point cloud data, but we have other **elegant representation methods**, such as spline curves, which perform particularly well in capturing object surfaces. Neural networks that generate voxels or point clouds typically produce rough, non-smooth results. The current challenge lies in developing neural networks that can both understand objects and effectively represent their surfaces.

Researchers have explored combining neural networks with spline curves or similar functions. A **typical example** is AtlasNet, which uses deep learning not to directly output 3D point clouds, but to learn transformation functions from latent shape representations to target forms.

**Parametric representation** of object shapes involves mapping 2D space with U/V coordinates to 3D space (for example, spheres). For simple shapes like spheres, this function can be explicitly defined with sine and cosine. But complex objects lack closed-form solutions.

The solution is to use neural networks implemented with **MLPs** to learn transformation function F. This function takes U/V as input and outputs points in 3D space, achieving mapping from 2D to 3D. Using a single transformation to represent entire objects might be overly complex, so researchers proposed using multiple small neural networks working together.

Imagine folding paper in various ways: each fold shapes the final form. Similarly, these neural networks work together to construct the required 3D representation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image60.png)

You can observe the differences between these three different representation methods. Given an input image, using **voxels** to reconstruct shapes, while showing certain capabilities, is inherently limited by voxel grid resolution.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image61.png)

For **point clouds**, you're no longer limited by resolution constraints, which may provide more details. However, point clouds lack inherent order, making it difficult to derive smooth surfaces from them.

In contrast, **AtlasNet** can generate smoother surfaces by learning transformation parametric patches. This method uses neural networks to map parametric representations from low-dimensional to high-dimensional space. By learning multiple such mappings and combining them, the model ultimately generates 3D geometry conditioned on 2D images.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image62.png)

Essentially, deep networks perform complex functions that map input images in pixel form to final category labels (such as distinguishing **cats**, **dogs**, or **people**). This function is extremely complex, with smaller output space (classification tasks are typically 1,000-dimensional) and much larger input space (for example, 500x500 pixel images correspond to 250,000 dimensions). This function is too complex to express in closed form, so it must be implemented with deep networks.

When considering deep networks in this context, their application to **3D shapes** doesn't fully conform to this paradigm. So the question arises: which representation methods are most suitable for this framework? Around 2019, researchers realized that deep networks essentially serve as **implicit functions**, prompting people to use them to represent implicit functions in 3D object geometry.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image63.png)

Unlike using **voxels** (extending pixels to 3D and applying 3D convolution) to represent space, voxels essentially just mark whether a point is inside or outside an object. Rather than explicitly discretizing space into voxels and applying convolution operations, we can use **deep networks** to directly perform such queries. This eliminates the need for 3D convolution—the network receives 3D space queries and can directly output 1D results, indicating whether the point is inside the 3D shape.

This marks an important transition from point or spline-based representations to **implicit representations**. We no longer use the voxel concept, but think through isosurfaces or implicit functions represented by deep networks. With networks, direct implicit queries can be performed without going through the conversion process from 2D to 3D space.

This evolution gave birth to **deep implicit functions**: around 2019, four papers coincidentally explored almost identical technical paths, becoming important milestones in the field.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image64.png)

Now, they all believe that although **voxels**, **point clouds**, and **meshes** each have advantages and disadvantages, the optimal method is to directly input queries into deep networks.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image65.png)

Deep networks receive inputs (such as **XYZ coordinates**) and output whether the point is inside or outside the object. This concept was proposed in 2019 and is still widely used in 2025.

The network can not only perform **binary classification** but also estimate other properties, such as **signed distance functions** (for measuring distance from points to object surfaces), or density and radiance values at that point.

Since 2019, deep networks have been applied similarly to classification tasks, inferring properties by querying points in **3D space** as implicit functions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image66.png)

People explored using **implicit functions** to represent object collections, not only as deformation components in 3D space but also constructing complex shapes by modeling implicit parts of objects with small neural networks. When representing 3D objects with implicit functions, not only can geometric properties be queried (such as whether a point is inside/outside an object and its distance to the surface), but appearance properties (such as radiance or color) can also be obtained.

**Neural Radiance Fields (NeRF)** technology, which emerged shortly thereafter, uses deep networks to simultaneously query objects' signed distance functions (or density) and radiance. In NeRF, after inputting 3D coordinates and camera viewing direction, the network outputs density and color values, rather than simple inside/outside binary classification results.

Training implicit functions for 3D shapes typically requires **3D supervision signals** (such as ground truth data marking whether points are inside objects). But NeRF operates based on 2D images, through integrating differentiable volume rendering techniques, enabling rendered models to maintain differentiability required for optimization when querying 3D space points.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image67.png)

You can obtain their color, density, and appearance. Then, you can calculate how much light is blocked along the path. This is essentially the **volume rendering** technique used in computer graphics. From the volume rendering equations (which are themselves approximate solutions), very few modifications are needed. However, this approximation ensures differentiability.

Given the neural network's output—density (interpreted as opacity in 3D space) and color—you can calculate how much light is attenuated by sampling points along the light path. Additionally, you can determine the contribution of any point along the light path to the final observed radiance.

**Two key elements** make this method possible:
1. A neural network representing implicit functions of radiance and density
2. Differentiable volume rendering equations, allowing direct learning from 2D images

These innovations eliminate the need for 3D shape training data, requiring only 2D images. Additionally, this method is not limited to geometry or density but can incorporate radiance or appearance features in 3D space.

These advances mark a significant leap from early techniques like **Deep SDF** or neural implicit functions to **NeRF**. Although NeRF seems groundbreaking, it builds on previous research on deep implicit functions, which initially focused only on geometry. The authors also acknowledged these influences in their subsequent publications.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image68.png)

Currently, I focus on dual research of **geometric structure** and **appearance representation**, learning from 2D images rather than 3D shapes.

Here shown are some results of **Neural Radiance Fields (NeRF)**, which you may have encountered before. As discussed earlier, our previous research involved generating 3D shapes and their corresponding 2D appearance representations.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image69.png)

Initially, we adopted **voxel-based representation methods**. But as mentioned earlier, **Neural Radiance Fields (NeRF)** can provide superior performance. Through implicit representation, voxels become unnecessary.

We attempted to replace voxels with radiance fields, implementing a generative neural network to capture implicit radiance fields and density. This method maintains compatibility with **GAN rendering frameworks**, enabling simultaneous 3D object rendering and 2D image generation.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image70.png)

Additionally, you can achieve **controllability** by changing camera viewpoints or object identity (while keeping viewpoint unchanged). These operations are similar to previous methods, but with **Neural Radiance Fields (NeRF)** technology, you can learn directly from images. This eliminates dependency limitations on categories with large amounts of 3D data like cars and chairs.

Generation quality significantly improved to higher realism. This research named **"PyGain"** was led by first author Eric Chen, primarily completed in collaboration with Gordon's team.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image71.png)

**NeRF** is remarkably effective but has a major flaw: it requires extensive sampling of points in 3D space. Unlike pre-sampling and applying volume convolution, NeRF operates similarly to level sets, requiring sampling of all points and continuous evaluation through neural networks. Although it can achieve advanced functions like learning from 2D data, the sampling process remains **computationally expensive** and slow.

This limitation drove further innovation, particularly breakthroughs from the graphics field. People began thinking about how to utilize spatially unconstrained and efficient point and mesh structures. The ensuing question was: can **neural implicit representations** be combined with this approach? The goal was to retain the advantages of implicit representation while breaking free from fixed sampling grid constraints. By avoiding time-consuming large-scale sampling, we hoped to combine the advantages of both methods.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image72.png)

**NeRF** attempts to parameterize scenes extremely densely, requiring sampling of density for all points in 3D space. Similar to voxels, this method wastes computational resources on empty region representation. In NeRF, numerous queries sample empty regions, with networks returning zero density values, resulting in inefficiency.

How should we solve this problem?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image73.png)

What if we adopt sparser sampling? We still retain **implicit representation**, but no longer sample empty regions, instead focusing on areas where objects exist. How to achieve this? The answer lies in **point representation**, particularly Gaussian splatting techniques.

This method uses the same implicit function, modeling density and appearance through neural networks. But unlike continuously querying neural networks, we adopt point representation composed of **3D Gaussian blobs** in space. These blobs can be understood as point clouds, but each point is not a single position—it represents a region.

After knowing the positions of these blobs, when projecting light rays from cameras to 3D space, we don't need uniform sampling but focus only on areas occupied by blobs. The radii of these Gaussians guide us to sample only in regions where objects exist, significantly improving **rendering efficiency**.

Here's a demonstration of reconstruction effects using 3D Gaussian splatting techniques.



In terms of quality, they're comparable.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image74.png)

I think they're comparable to **NeRFs**. Here different evaluation metrics—**PSNR** and **SSIM**—are used to measure rendering quality. Note that the Y-axis doesn't start from zero, which might be slightly misleading, but the numerical differences are actually very small.

In terms of rendering quality, **Gaussian splatting** performs comparably to first-generation NeRF, but Gaussian splatting is significantly more efficient. Its frame rate can reach 150 FPS, while NeRF rendering a single frame might take about 20 seconds.

As the paper authors stated, this achieves about a 1000x speed improvement, because computational resources are no longer wasted on neural network queries for points in empty space.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image75.png)

**Deep learning** has integrated with **3D data** of various representation forms, covering their origins, evolution processes, and relationships with other shape representations.

One aspect we haven't discussed is interesting progress in the field of **object geometry**, which this article will briefly discuss.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image76.png)

This discussion not only covers geometric elements and their **specific part details** but also their **structural properties**. For example, chairs typically exhibit **symmetry**. We'll further explore this concept, particularly in cases involving parametric surfaces, where partial regions can be parameterized through closed-form equations of shapes like spheres, which inherently introduces symmetry.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image77.png)

However, more systematic research has been conducted on **regularity** and structure in object geometry, including repetition and symmetry. Researchers have also proposed various methods to model these repetitive patterns.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image78.png)

How can we effectively represent geometric details of individual parts, such as details in **point clouds**, meshes, or implicit functions? These methods cannot directly capture **structural regularity** like symmetry or repetition. How should we address this limitation?



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image79.png)

Several other methods have also been explored, mainly in the **graphics community**, where objects can be represented as collections of sampled geometric components, similar to part sets.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image80.png)

Some methods use **deep learning** techniques, representing different parts of objects through simple geometric primitives and then combining them, or using implicit functions as discussed earlier.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image81.png)

However, there's also research attempting to go beyond simple part representation methods, instead modeling relationships between these parts. This is particularly important for scene understanding—for example, **beds** are usually placed against walls, **chairs** are often placed next to tables.

The goal is not only to represent objects as collections of unrelated parts but to capture their **hierarchical relationships**. Taking architectural design as an example: when constructing classrooms, the hierarchical structure of desks and chairs needs to be considered, while chairs themselves contain components like seats, backs, and legs.

These hierarchical structures can be combined with **neural networks** to form hierarchical graphs. For example, chair structure can be divided into three levels: base, seat, and back, with legs further subdivided. To ensure stability, symmetrically distributed chair legs must satisfy strict **geometric constraint** conditions.

Researchers have developed various representation methods and deep learning techniques to learn and generate objects that conform to such constraint conditions.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image82.png)

For example, this hierarchical graph encoder-decoder can represent and generate 3D chair models while maintaining **hierarchical constraints**. This work originated from Leo Lieberstein's team in 2019.

Additionally, shapes can be represented through **procedural generation**, utilizing repetitive structures and loop operations. Neural networks can generate such programs to synthesize object shapes and relationships between their parts, which remains an important research direction.

A notable trend has emerged recently: **deep networks** and **large language models** demonstrate excellent performance.



![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/cs231n/lec15_image83.png)

Researchers are exploring whether **large language models** like GPT can generate programs that understand **semantics** and constraint conditions, such as those defining chair structures.

This involves using **implicit functions** to capture specific geometric details of object parts. This represents an emerging research trend in the field.

Thank you.
