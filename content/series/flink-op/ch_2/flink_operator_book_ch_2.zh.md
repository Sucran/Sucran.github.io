---
title: "Operator技术 和 Java Operator SDK"
date: 2024-11-24T16:26:13+08:00
draft: false
description: ""
---

## 2.1 Operator 技术来源

这一切来源于一个现实问题：如何扩展 Kubernetes 的能力？

我们可以从 Kubernetes 能力及现有的扩展手段，整理出如下表格：

| Kubernetes 能力 | 扩展手段 | 详细说明 |
|---|---|---|
| **支持自有基础设施** | Cloud Provider Interface | 通过云服务商接口，Kubernetes 能够直接与云厂商的基础设施集成。例如，服务可以自动获取云端 IP 地址，常见于 AWS、GCP、阿里云等主流云平台。 |
| **网络与存储自定义** | Kubelet Plugins (CNI, CSI) | 通过 kubelet 插件（如 CNI 网络插件、CSI 存储插件），可以为 Pod 提供非默认的网络和存储选项，实现灵活的网络和存储方案。 |
| **提升用户体验** | Kubectl Plugins | 通过 kubectl 插件（如 krew、access-matrix），可以增强命令行工具的功能，提升用户操作体验。例如，krew 作为插件包管理器，access-matrix 可可视化权限。 |
| **细粒度访问控制** | API Access Extensions (Webhooks) | 通过 Admission/Mutating Webhooks，可以在资源请求进入 API Server 时进行拦截、校验或修改，实现更细致的访问控制和安全策略。 |
| **自定义调度逻辑** | Scheduler Extension | 可以编写自定义调度器，决定 Pod 如何分配到节点，实现特殊的调度策略。 |
| **构建自定义 API** | Extension API Server | 通过扩展 API Server，可以为集群添加全新功能，开发自定义 API（如 metrics-server），实现与核心 API 解耦的扩展。 |
| **通过 CRD 增强功能** | CR Controllers (自定义资源控制器) | 通过自定义资源定义（CRD）和控制器，可以为集群添加新功能，自动化管理应用和资源，广泛用于 Operator 模式。 |

这个表格总结了 Kubernetes 的主要扩展能力及其实现手段。每一项扩展手段都对应着 Kubernetes 的一种核心能力，帮助用户根据实际需求灵活扩展和定制集群功能。

其中，CR Controllers 指的是自定义资源控制器， 是 Operator 模式的基础，通过 CRD 和控制器，我们可以为 Kubernetes 添加全新的资源类型和自动化管理能力，这正是 Flink Operator 等众多 Operator 项目的技术基础。

Operator 模式是 Kubernetes 生态系统中的一个重要概念，它扩展了 Kubernetes 的能力，使其能够管理有状态应用程序和复杂的分布式系统。Operator 技术的核心思想是将运维知识编码到软件中，实现自动化管理。

### 2.1.1 Kubernetes 的 API Server

在讲解什么是自定义资源之前，我们需要先回顾一下 Kubernetes 的 API Server。

Kubernetes API Server 是整个 Kubernetes 集群的核心组件，它提供了 RESTful API 接口，用于与集群进行交互。API Server 负责：

- **资源管理**：处理所有 Kubernetes 资源的创建、更新、删除操作
- **认证授权**：验证用户身份并检查权限
- **准入控制**：在资源持久化之前进行验证和修改
- **API 版本管理**：支持多个 API 版本，确保向后兼容性

Kubernetes 的 API 设计遵循 RESTful 原则，所有资源都通过 HTTP 方法进行操作。 API Server 使用 etcd 作为后端存储，保存所有集群状态信息。当 Operator 需要监听资源变化时，实际上是通过 API Server 的 watch 机制来实现的。

### 2.1.2 Kubernetes 的 API 和 API 扩展

Kubernetes 提供了两种扩展 API 的方式，我们能通过一张图片简单地

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/kube-apiserver.png "Api Server架构图示 (出自[Adam Otto](https://www.youtube.com/watch?v=8QoCL1NCVv4&t=5s))")

1. **Aggregated API Server**：通过 API Aggregation 机制扩展 API，需要外部的 api 服务
2. **Custom Resource Definitions (CRD)**：定义自定义资源类型，处于 apiextension 中，不会对原有资源造成影响

正如上文所说，CRD 是 Operator 技术的基石，后续我们将着重讲解。在此之前，我们先谈谈 CRD 的由来。

### 2.1.3 CRD 的由来

#### GVK 和 GVR

在谈论 CRD 的由来之前，我们先回顾一下资源的怎么标识的。

在 Kubernetes 中，每个资源都有唯一的标识符：

- **GVK (Group, Version, Kind)**：
  - Group：API 组，如 apps、batch、flink.apache.org
  - Version：API 版本，如 v1、v1beta1
  - Kind：资源类型，如 Deployment、FlinkDeployment

- **GVR (Group, Version, Resource)**：
  - Resource：资源的复数形式，如 deployments、flinkdeployments

例如，Flink Operator 中定义的 FlinkDeployment 资源的 GVK 是：
```yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment
```

CRD 会定义资源的GVK，作用域(scope)、结构(spec / status)、子资源（subresources）。从下图关于 FlinkDeployment CRD 的例子，就能清晰看出

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/flink-op-crd-exam.png "FlinkDeployment CRD 例子")

从这个代码，笔者已经进行了折叠，原来的代码非常长。你可能会问，难道开发者要进行手写维护？不，这个是由 Fabric8 开发的 crd-generator-apt 的库自动生成的。在讲解 Operator 开发流程时我们会详细展开。接着笔者想继续分享一下 CRD 的由来。

#### CR 和 CRD 的由来

Kubernetes 经历了从 TPR 到 CRD 的演进，极大提升了资源的扩展能力。

在 CRD 出现之前，Kubernetes 使用 TPR（Third Party Resource，第三方资源）来扩展 API。TPR 首次出现在 Kubernetes 1.2 版本，但是由于一些局限性，在 Kubernetes 1.8 版本被移除。

Kubernetes 1.2 版本必然是需要引入很多创新和改动的，在 1.2 版本时 Kubernetes 的 Api Server 组件是只有一个核心组件处理我们现在常见的资源，而 TPR 同时也被这个组件管理。这导致了 TPR 经常会导致 Api Server 的灵活性不足，同时版本升级时需要考虑 TPR 的向后兼容性，时不时又容易引入兼容破坏。除此之外，TPR 仅支持命名空间级别的对象，无法支持集群级别的自定义资源。在那个快速迭代的时期，这样的 TPR 相比于 CRD 显得过于鸡肋，所以被移除。

从 Kubernetes 1.7 开始，引入了 CRD（Custom Resource Definition）作为 TPR 的替代方案，带来了革命性的改进：

**架构优势：**
- **独立处理单元**：CRD 拥有专门的 API Extension 处理单元，不再共享核心组件
- **Kubernetes 风格**：CRD 允许用户以 Kubernetes 风格定义自己的 API，作为集群的扩展

**功能特性：**
- **完整 CRUD 支持**：通过定义 CRD，可以获得支持 CRUD（创建、读取、更新、删除）操作的 API 端点
- **生命周期管理**：API Server 负责整个生命周期管理
- **动态注册**：CRD 支持动态注册，能被 kubectl 等工具直接管理
- **自动继承能力**：自动获得 HTTP、watch/list 等能力

既然 CRD 能够这么具有优势，为什么在当时没有大量应用呢？原因是当初构建 CR Controllers 需要直接使用 client-go 库来构建，对开发者的要求比较高。

### 2.1.4 从 CRD 到早期 Operator 开发

我们使用一张图来表示直接使用 client-go 对开发者提出了什么要求：

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/dev_cr_controller.png "开发 CR Controller 的旧方式 (出自[Adam Otto](https://www.youtube.com/watch?v=8QoCL1NCVv4&t=5s))")

这张图说明了自定义资源改动的过程：
1. Reflector 从 Api Server 监听特定类型的资源，拿到变更通知后，将具体对象推入 DeltaFIFO 队列
2. DeltaFIFO 队列 管理需要处理的资源事件队列
3. Informer 从队列中弹出具体对象
4. Informer 通过 Indexer 将对象和索引丢到本地线程 cache 中
5. Informer 触发相应的事件处理函数 Event Handlers

一般用户需要过滤对象，判断对象是需要处理的自定义资源，就会触发处理逻辑。而所有CURD的相关逻辑，都需要用户自行控制和处理。这个流程，对于新手开发者来说太不友好。

后来就出现了很多 Operator 框架简化了整个开发流程，现如今固化了一些逻辑如图：

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/dev_op_framework.png "Operator 框架固化流程 (出自[Adam Otto](https://www.youtube.com/watch?v=8QoCL1NCVv4&t=5s))")

相当于用户不需要再去和 Event Handlers 和 Indexer 交互，框架层面维护了一个事件队列，自动将要处理的自定义资源的事件过滤出来，同时处理每个事件时，框架会自行通过 Indexer 来获取自定义资源的键值对。用户在写对应逻辑时，可以直接用键值对获取到对象，然后进行CURD的相关逻辑。

## 2.2 Java Operator SDK

Java Operator SDK 是 Fabric8 开发的一个框架，用于简化 Kubernetes Operator 的开发。它提供了高级抽象，让开发者专注于业务逻辑而不是底层的 Kubernetes API 调用。

### 2.2.1 为什么选择 Java Operator SDK

相比其他 Operator 开发框架，Java Operator SDK 具有以下优势：

1. **Java 生态系统**：利用丰富的 Java 库和工具
2. **类型安全**：编译时类型检查，减少运行时错误
3. **IDE 支持**：优秀的开发工具和调试体验
4. **团队熟悉度**：Java 开发者更容易上手
5. **企业级特性**：支持复杂的业务逻辑和集成需求

### 2.2.2 Java Operator SDK 相关术语

我们直接翻译官方网站的“相关术语”一章

> Primary Resource - the resource that represents the desired state that the controller is working to achieve. While this is often a Custom Resource, it can be also be a Kubernetes native resource (Deployment, ConfigMap,…).
>
> 主要资源 - 代表控制器正在努力实现的目标状态的资源。虽然这通常是自定义资源，但也可能是 Kubernetes 原生资源（如 Deployment、ConfigMap 等）。
>
> Secondary Resource - any resource that the controller needs to manage the reach the desired state represented by the primary resource. These resources can be created, updated, deleted or simply read depending on the use case. For example, the Deployment controller manages ReplicaSet instances when trying to realize the state represented by the Deployment. In this scenario, the Deployment is the primary resource while ReplicaSet is one of the secondary resources managed by the Deployment controller.
>
> 次要资源 - 控制器需要管理的任何资源，以实现由主要资源表示的目标状态。根据用例的不同，这些资源可以被创建、更新、删除或仅读取。例如，当 Deployment 控制器试图实现由 Deployment 表示的状态时，它管理 ReplicaSet 实例。在这种情况下，Deployment 是主要资源，而 ReplicaSet 是由 Deployment 控制器管理的次要资源之一。
>
> Dependent Resource - a feature of JOSDK, to make it easier to manage secondary resources. A dependent resource represents a secondary resource with related reconciliation logic.
>
> 依赖资源 - JOSDK 的一个功能，用于简化次要资源的管理。依赖资源表示具有相关协调逻辑的次要资源。
>
> Low-level API - refers to the SDK APIs that don't use any of features (such as Dependent Resources or Workflows) outside of the core Reconciler interface. See the WebPage sample. The same logic is also implemented using Dependent Resource and Workflows.
>
> 低级 API - 指不使用核心 Reconciler 接口之外任何功能（如依赖资源或工作流）的 SDK API。参见 WebPage 示例。相同的逻辑也通过依赖资源和工作流实现。
> 
> Reconciler interface. See the WebPage sample . The same logic is also implemented using Dependent Resource and Workflows
>
> Reconciler 接口。参见 WebPage 示例。相同的逻辑也通过 Dependent Resource 和 Workflows 实现

## 2.3 Java Operator SDK 如何使用

Java Operator SDK 项目本身带有几个案例项目，比较适合初学者的是 WebPage 案例。接下来我们就以这个案例为核心来讲解上述的概念和开发流程。

### 2.3.1 官方 WebPage 案例

WebPage Operator 案例展示了由 Operator 支持的自定义资源如何作为抽象层。该 Operator 将使用 WebPage 资源，它主要包含静态网页的定义，并创建一个由 ConfigMap 支持的 NGINX Deployment，该 ConfigMap 中包含 HTML 内容。

换句话说，WebPage 是主要资源，对应了三个次要资源都是Kubernetes 原生的资源，分别是 Deployment、
ConfigMap、Service 

```yaml
apiVersion: "sample.javaoperatorsdk/v1"
kind: WebPage
metadata:
  name: mynginx-hello
spec:
  html: |
    <html>
      <head>
        <title>Webserver Operator</title>
      </head>
      <body>
        Hello World!
      </body>
    </html>
```

将上述yaml文件存在本地项目的 k8s 文件夹下，并重命名为 mynginx-hello.yaml

当我们启动 Operator 时，通过下列命令创建该自定义资源

```bash
kubectl apply -f k8s/mynginx-hello.yaml
```

## 2.3.2 Operator 的开发流程

### 2.4.1 第一步：创建 Maven 项目

创建一个maven项目，命名为 java-op-example，artifactId 和 groupId 用户可以自行定义，需注意项目依赖 JDK 11+

等待项目创建完成之后，修改pom文件，这里没办法参考 WebPage 项目，所以贴上所有需增加内容

```xml
    <!--版本属性-->
    <properties>
        <java.version>11</java.version>
        <maven.compiler.source>${java.version}</maven.compiler.source>
        <maven.compiler.target>${java.version}</maven.compiler.target>
        <josdk.version>4.9.4</josdk.version>
        <slf4j.version>1.7.36</slf4j.version>
        <junit.version>5.9.2</junit.version>
        <log4j.version>2.20.0</log4j.version>
        <fabric8-client.version>6.13.3</fabric8-client.version>
        <jib-maven-plugin.version>3.4.6</jib-maven-plugin.version>
    </properties>

    <!--依赖管理-->
     <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>io.javaoperatorsdk</groupId>
                <artifactId>operator-framework-bom</artifactId>
                <version>${josdk.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <!--依赖代码包-->
    <dependencies>
        <dependency>
            <groupId>io.javaoperatorsdk</groupId>
            <artifactId>operator-framework</artifactId>
            <version>${josdk.version}</version>
        </dependency>
        <dependency>
            <groupId>io.javaoperatorsdk</groupId>
            <artifactId>operator-framework-junit-5</artifactId>
            <version>${josdk.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>io.fabric8</groupId>
            <artifactId>crd-generator-apt</artifactId>
            <version>${fabric8-client.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
            <version>${slf4j.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-slf4j-impl</artifactId>
            <version>${log4j.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-core</artifactId>
            <version>${log4j.version}</version>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <scope>test</scope>
            <version>${junit.version}</version>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <scope>test</scope>
            <version>${junit.version}</version>
        </dependency>
    </dependencies>
    <!--编译工具-->
    <build>
        <plugins>
            <plugin>
                <groupId>com.google.cloud.tools</groupId>
                <artifactId>jib-maven-plugin</artifactId>
                <version>${jib-maven-plugin.version}</version>
                <configuration>
                    <from>
                        <image>eclipse-temurin:11-jre</image>
                    </from>
                    <to>
                        <image>webpage-operator</image>
                    </to>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
            </plugin>
        </plugins>
    </build>
```

需要注意的是，crd-generator-apt 这个库是必备的。你会发现我们编译工具是不带有任何 CRD 生成相关的过程的，主要是 crd-generator-apt 于 mvn package 过程中会自动根据代码生成 CRD 的 Yaml 文件。

### 2.4.2 第二步：构建自定义资源

刷新依赖之后，读者就能够开始编写自定义资源了，我们这里为了行文简洁，不粘贴 WebPage 的代码

读者可以在 java-op-example/src/main/java 下创建 `<groupId>.<artifaceId>.cr`

然后参考 [Github代码](https://github.com/operator-framework/java-operator-sdk/tree/main/sample-operators/webpage/src/main/java/io/javaoperatorsdk/operator/sample/customresource) 粘贴到目录下

主要有三个文件：WebPage.java WebPageSpec.java WebPageStatus.java

需要注意的是 WebPageSpec.java WebPageStatus.java 其实都是简单的 POJO

不同的是，WebPage.java 的写法：
```java
@Group("sample.javaoperatorsdk")
@Version("v1")
public class WebPage extends CustomResource<WebPageSpec, WebPageStatus>
    implements Namespaced {
    // methods
}
```

这里需要指定 @Group 和 @Version，同时继承 CustomResource 接口，如果 scope 是命名空间级别的，就需要实现 Namespaced 接口。如果不指定的话，crd-generator-apt 于 mvn package 过程中不会自动生成。


### 2.4.3 第三步：Controller 核心调谐逻辑

由于 Flink Operator 本身是使用了 Java Operator SDK 的低级 API 进行构建，我们这里着重提到的也是这个[原生实现](https://github.com/operator-framework/java-operator-sdk/blob/main/sample-operators/webpage/src/main/java/io/javaoperatorsdk/operator/sample/WebPageReconciler.java)

虽然类名称为 WebPageReconciler，但事实上可以被认作是一个 Controller 的核心。

```java
public class WebPageReconciler
    implements Reconciler<WebPage>, ErrorStatusHandler<WebPage>, EventSourceInitializer<WebPage> {
    
    @Override
    public Map<String, EventSource> prepareEventSources(EventSourceContext<WebPage> context) {
      // constrcut configMapEventSource / deploymentEventSource / serviceEventSource
      return EventSourceInitializer.nameEventSources(configMapEventSource,deploymentEventSource, serviceEventSource);
    }

    @Override
    public UpdateControl<WebPage> reconcile(WebPage webPage, Context<WebPage> context) throws Exception {
      // 1. validate webPage content
      // 2. reconcileConfigMap()
        // 2.1. make desiredHtmlConfigMap and get previousConfigMap
        // 2.2 if(!match(desiredHtmlConfigMap, previousConfigMap)) 
          // 2.2.1 update previousConfigMap to desiredHtmlConfigMap using K8sClient
      // 3. reconcileService() similar logic as reconcileConfigMap()
      // 4. reconcileDeployment() similar logic as reconcileConfigMap()
      // 5. if html content changed
        // 5.1 rebuild pod to show new content
      return UpdateControl.patchStatus(webPage);
    }

    @Override
    public ErrorStatusUpdateControl<WebPage> updateErrorStatus(
      WebPage resource, Context<WebPage> context, Exception e) {
      resource.getStatus().setErrorMessage("Error: " + e.getMessage());
      return ErrorStatusUpdateControl.updateStatus(resource);
  }
}
```

如代码所示，上述代码就是 WebPage 项目的低级 API 实现的 Controller 版本，WebPageReconciler 就是对应调谐器，即实现 Operator 的核心。这个类必须要实现 Reconciler 接口，这个接口对应的方法是 reconcile()。原始代码由于使用的是低级 API 实现所以特别冗长，笔者这里使用注释的方式将逻辑进行概括，读者在理解含义之后，可以进一步了解[具体代码](https://github.com/operator-framework/java-operator-sdk/blob/main/sample-operators/webpage/src/main/java/io/javaoperatorsdk/operator/sample/WebPageReconciler.java)。

如果我们只实现 Reconciler 接口也是可以的，但带来的问题是即使状态已经是预期状态了也会重复调用 Kubernetes 的 API 查看资源状态，另外是会有重复的调谐执行，对程序性能并不友好。

同时，当我们接收到一个事件时，如果该特定资源没有正在进行 reconcile() 方法，它就会触发 reconcile() 方法。换句话说，框架保证不会对资源进行并发执行 reconcile() 方法。

所以官方的建议是也同时实现 EventSourceInitializer 接口，这个对应方法是 prepareEventSources() 需要注册事件源。不同的事件源监听并缓存了 WebPage 所管理的次要资源的最新状态，只有当次要资源有变更时，才触发调谐逻辑。这实现了高效的调谐机制。

最后是错误处理，WebPageReconciler 也实现了 ErrorStatusHandler 接口，这个对应方法是 ErrorStatusUpdateControl，如果不实现这个接口，当调谐出现错误时，框架本身会打印输出到日志，但是用户无法从自定义资源上看出任何端倪。读者可以看到这里方法的实现，修改了 WebPage 对象实例的 `status.errorMessage`.

需要注意的是，调谐逻辑里的 match 方法都依赖 resource 文件夹底下已经写好了各种资源的 Yaml 文件来进行读取和对比，所以读者需要自行复制官方示例中的 [Yaml 文件](https://github.com/operator-framework/java-operator-sdk/tree/main/sample-operators/webpage/src/main/resources/io/javaoperatorsdk/operator/sample) 到对应自己包路径的文件夹。

### 2.4.4 第四步：创建 Operator 并增加 Controller

Java Operator SDK 的启动核心也是 Operator 类，我们会将前一步写好的调谐器注册到 Operator，代码如下：

```java
public class WebPageOperator {
    private static final Logger log = LoggerFactory.getLogger(WebPageOperator.class);

    public static void main(String[] args) {
        log.info("WebServer Operator starting!");
        Operator operator = new Operator();
        operator.register(new WebPageReconciler());
        operator.start();
    }
}
```

笔者简化了 WebPageOperator 的代码，让读者更直观的了解到这里其实就是注册调谐逻辑。 整体注册、启动和终止的时序图如下：

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/webop-mermaid.png "Operator 时序图")

图中，ConfigurationService 管理 Operator 的配置和 Kubernetes 的客户端，ExecutorService 管理 Operator 的执行线程池和并发数，ControllerManager 管理注册到 Operator 的 Controller 和 调谐逻辑。 这些属于 Operator 框架内的核心组件。

### 2.4.5 第五步：测试调谐逻辑

Java Operator SDK 有专门的测试框架 operator-framework-junit-5， 这个框架其实比较简单，具体的类图，如下图：

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/test-framework-class.png "测试框架类图")

其中要点在于，LocallyRunOperatorExtension 对应本地执行单元测试，ClusterDeployedOperatorExtension 对应远程集群部署执行集成测试和E2E测试。

在官方的 WebPage 的示例中有相应的[测试代码](https://github.com/operator-framework/java-operator-sdk/tree/main/sample-operators/webpage/src/test/java/io/javaoperatorsdk/operator/sample)，这里我们不再展开。读者只需要复制 WebPageOperatorAbstractTest 和 WebPageOperatorE2E 即可。

实际操作时需要注意的是，需要先对 Operator 程序进行打包操作，再进行测试。因为上述两个测试类，会自动读取打包目录下的 crd Yaml 文件进行部署，所以要通过 crd-generator-apt 库先自动生成。

### 2.4.6 第六步：打包镜像

读者可以自行粘贴测试代码进行测试，测试完成之后，如果要部署 Operator 程序，就需要进行镜像打包。
读者可以返回去看一下 pom 文件的 build 配置，我们有配置了 jib-maven-plugin，这是一个无需写 Dockerfile 就自动构建镜像的 lib。

jib-maven-plugin 的详细配置可以参考 [Github链接](https://github.com/GoogleContainerTools/jib/tree/master/jib-maven-plugin#configuration)

打包镜像时我们需要执行命令：
```shell
mvn clean compile jib:buildTar -Dimage=webpage-operator -Djib.from.image=eclipse-temurin:11-jre
# 如果是 Arm架构的 MacOS / Linux
# mvn clean compile jib:buildTar -Dimage=webpage-operator -Djib.from.image=eclipse-temurin:11-jre -Djib.from.platforms=linux/arm64

# 查看镜像架构命令
# docker inspect webpage-operator:latest | grep -i arch
```
然后就能够看到生成的 `target/jib-image.tar`

### 2.4.7 第七步：Kind 部署和测试

在部署之前，需要先创建自定义资源，使用命令：
```shell
kubectl apply -f target/classes/META-INF/fabric8/webpages.sample.javaoperatorsdk-v1.yml
```
接着，执行如下命令：
```shell
# 加载镜像到 kind 集群
kind load image-archive target/jib-image.tar --name flink-cluster
# 执行 Operator 部署
kubectl apply -f k8s/operator.yaml
# 执行 WebPage Yaml
kubectl apply -f k8s/mynginx-hello.yaml
```

通过这个完整的开发流程，我们可以创建一个功能完整的 WebPage Operator，实现 WebPage 应用程序的自动化管理。