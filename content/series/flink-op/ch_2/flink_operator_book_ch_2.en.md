---
title: "Operator Technology and Java Operator SDK"
date: 2025-07-24T16:26:13+08:00
draft: false
description: ""
---

## 2.1 Origin of Operator Technology

This all stems from a real-world problem: how to extend Kubernetes capabilities?

We can organize the following table from Kubernetes capabilities and existing extension methods:

| Kubernetes Capability | Extension Method | Detailed Description |
|---|---|---|
| **Supporting Custom Infrastructure** | Cloud Provider Interface | Through cloud provider interfaces, Kubernetes can directly integrate with cloud vendors' infrastructure. For example, services can automatically obtain cloud IP addresses, commonly seen in major cloud platforms like AWS, GCP, and Alibaba Cloud. |
| **Custom Network and Storage** | Kubelet Plugins (CNI, CSI) | Through kubelet plugins (such as CNI network plugins and CSI storage plugins), non-default network and storage options can be provided for Pods, achieving flexible network and storage solutions. |
| **Enhanced User Experience** | Kubectl Plugins | Through kubectl plugins (such as krew and access-matrix), the functionality of command-line tools can be enhanced, improving the user operation experience. For example, krew serves as a plugin package manager, while access-matrix provides permission visualization. |
| **Fine-grained Access Control** | API Access Extensions (Webhooks) | Through Admission/Mutating Webhooks, resource requests can be intercepted, validated, or modified when entering the API Server, achieving more granular access control and security policies. |
| **Custom Scheduling Logic** | Scheduler Extension | Custom schedulers can be written to determine how Pods are assigned to nodes, implementing special scheduling strategies. |
| **Building Custom APIs** | Extension API Server | Through extending the API Server, new functionality can be added to the cluster by developing custom APIs (such as metrics-server), achieving decoupling from core APIs. |
| **Enhancing Functionality via CRD** | CR Controllers (Custom Resource Controllers) | Through Custom Resource Definitions (CRD) and controllers, new functionality can be added to the cluster to automate application and resource management, widely used in the Operator pattern. |

This table summarizes Kubernetes' main extension capabilities and their implementation methods. Each extension method corresponds to a core capability of Kubernetes, helping users flexibly extend and customize cluster functionality according to actual needs.

Among these, CR Controllers refer to Custom Resource Controllers, which form the foundation of the Operator pattern. Through CRD and controllers, we can add new resource types and automated management capabilities to Kubernetes. This is the technical foundation for many Operator projects, including Flink Operator.

The Operator pattern is an important concept in the Kubernetes ecosystem. It extends Kubernetes capabilities to manage stateful applications and complex distributed systems. The core idea of Operator technology is to encode operational knowledge into software to achieve automated management.

### 2.1.1 Kubernetes API Server

Before explaining what custom resources are, we need to review the Kubernetes API Server.

The Kubernetes API Server is the core component of the entire Kubernetes cluster. It provides RESTful API interfaces for interacting with the cluster. The API Server is responsible for:

- **Resource Management**: Handling creation, update, and deletion operations for all Kubernetes resources
- **Authentication and Authorization**: Verifying user identity and checking permissions
- **Admission Control**: Validating and modifying resources before persistence
- **API Version Management**: Supporting multiple API versions to ensure backward compatibility

Kubernetes API design follows RESTful principles, with all resources operated via HTTP methods. The API Server uses etcd as the backend storage to save all cluster state information. When an Operator needs to listen for resource changes, it actually implements this through the API Server's watch mechanism.

### 2.1.2 Kubernetes API and API Extensions

Kubernetes provides two ways to extend APIs. We can illustrate this simply with an image:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/kube-apiserver.png "API Server Architecture Diagram (from [Adam Otto](https://www.youtube.com/watch?v=8QoCL1NCVv4&t=5s))")

1. **Aggregated API Server**: Extending APIs through the API Aggregation mechanism, requiring external API services
2. **Custom Resource Definitions (CRD)**: Defining custom resource types within apiextension, without affecting existing resources

As mentioned above, CRD is the cornerstone of Operator technology, which we will focus on later. Before that, let's discuss the origin of CRD.

### 2.1.3 Origin of CRD

#### GVK and GVR

Before discussing the origin of CRD, let's review how resources are identified.

In Kubernetes, each resource has a unique identifier:

- **GVK (Group, Version, Kind)**:
  - Group: API group, such as apps, batch, flink.apache.org
  - Version: API version, such as v1, v1beta1
  - Kind: Resource type, such as Deployment, FlinkDeployment

- **GVR (Group, Version, Resource)**:
  - Resource: Plural form of the resource, such as deployments, flinkdeployments

For example, the GVK of FlinkDeployment resource defined in Flink Operator is:
```yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment
```

CRD defines the resource's GVK, scope, structure (spec/status), and subresources. From the following example of FlinkDeployment CRD, we can see this clearly:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/flink-op-crd-exam.png "FlinkDeployment CRD Example")

The code shown here has been collapsed - the original code is very long. You might ask, do developers need to manually maintain this? No, this is automatically generated by the crd-generator-apt library developed by Fabric8. We will elaborate on this when discussing the Operator development process. Next, I want to continue sharing the origin of CRD.

#### Origin of CR and CRD

Kubernetes evolved from TPR to CRD, greatly enhancing resource extension capabilities.

Before CRD existed, Kubernetes used TPR (Third Party Resource) to extend APIs. TPR first appeared in Kubernetes 1.2 but was removed in Kubernetes 1.8 due to certain limitations.

Kubernetes 1.2 version inevitably introduced many innovations and changes. In version 1.2, Kubernetes' API Server component was a single core component handling all the common resources we know today, while TPR was also managed by this component. This led to TPR often causing insufficient flexibility in the API Server. During version upgrades, backward compatibility with TPR had to be considered, which occasionally introduced compatibility breaks. Additionally, TPR only supported namespace-level objects and couldn't support cluster-level custom resources. In that rapidly iterating era, such TPR appeared too limited compared to CRD, hence it was removed.

Starting from Kubernetes 1.7, CRD (Custom Resource Definition) was introduced as a replacement for TPR, bringing revolutionary improvements:

**Architectural Advantages:**
- **Independent Processing Unit**: CRD has a dedicated API Extension processing unit, no longer sharing core components
- **Kubernetes Style**: CRD allows users to define their own APIs in Kubernetes style as cluster extensions

**Functional Features:**
- **Complete CRUD Support**: By defining CRD, you can obtain API endpoints supporting CRUD (Create, Read, Update, Delete) operations
- **Lifecycle Management**: The API Server handles the entire lifecycle management
- **Dynamic Registration**: CRD supports dynamic registration and can be directly managed by kubectl and other tools
- **Automatic Capability Inheritance**: Automatically inherits HTTP, watch/list capabilities and more

Since CRD has such advantages, why wasn't it widely applied at the time? The reason was that building CR Controllers at that time required directly using the client-go library, which had relatively high requirements for developers.

### 2.1.4 From CRD to Early Operator Development

We use a diagram to represent what direct use of client-go required from developers:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/dev_cr_controller.png "Old Way of Developing CR Controller (from [Adam Otto](https://www.youtube.com/watch?v=8QoCL1NCVv4&t=5s))")

This diagram illustrates the process of custom resource changes:
1. Reflector listens for specific resource types from the API Server, receives change notifications, and pushes specific objects into the DeltaFIFO queue
2. DeltaFIFO queue manages the queue of resource events that need processing
3. Informer pops specific objects from the queue
4. Informer throws objects and indexes into the local thread cache through Indexer
5. Informer triggers corresponding event handler functions

Generally, users need to filter objects, determine if they are custom resources that need processing, and then trigger processing logic. All CRUD-related logic needs to be controlled and handled by the user. This process is too unfriendly for novice developers.

Later, many Operator frameworks simplified the entire development process. Today, some logic has been standardized as shown in the figure:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/dev_op_framework.png "Operator Framework Standardized Process (from [Adam Otto](https://www.youtube.com/watch?v=8QoCL1NCVv4&t=5s))")

This means users no longer need to interact with Event Handlers and Indexer. The framework level maintains an event queue and automatically filters out events for custom resources that need processing. When processing each event, the framework automatically obtains key-value pairs of custom resources through Indexer. When writing corresponding logic, users can directly use key-value pairs to obtain objects and then perform CRUD-related logic.

## 2.2 Java Operator SDK

Java Operator SDK is a framework developed by Fabric8 for simplifying Kubernetes Operator development. It provides high-level abstractions, allowing developers to focus on business logic rather than underlying Kubernetes API calls.

### 2.2.1 Why Choose Java Operator SDK

Compared to other Operator development frameworks, Java Operator SDK has the following advantages:

1. **Java Ecosystem**: Utilizes rich Java libraries and tools
2. **Type Safety**: Compile-time type checking reduces runtime errors
3. **IDE Support**: Excellent development tools and debugging experience
4. **Team Familiarity**: Java developers can get started more easily
5. **Enterprise Features**: Supports complex business logic and integration requirements

### 2.2.2 Java Operator SDK Terminology

We directly translate the "Related Terms" chapter from the official website:

> Primary Resource - the resource that represents the desired state that the controller is working to achieve. While this is often a Custom Resource, it can also be a Kubernetes native resource (Deployment, ConfigMap,…).
>
> Primary Resource - represents the target state that the controller is working to achieve. While this is typically a custom resource, it can also be a Kubernetes native resource (such as Deployment, ConfigMap, etc.).
>
> Secondary Resource - any resource that the controller needs to manage to reach the desired state represented by the primary resource. These resources can be created, updated, deleted or simply read depending on the use case. For example, the Deployment controller manages ReplicaSet instances when trying to realize the state represented by the Deployment. In this scenario, the Deployment is the primary resource while ReplicaSet is one of the secondary resources managed by the Deployment controller.
>
> Secondary Resource - any resource that the controller needs to manage to achieve the target state represented by the primary resource. Depending on the use case, these resources can be created, updated, deleted, or simply read. For example, when the Deployment controller tries to achieve the state represented by Deployment, it manages ReplicaSet instances. In this case, Deployment is the primary resource, and ReplicaSet is one of the secondary resources managed by the Deployment controller.
>
> Dependent Resource - a feature of JOSDK, to make it easier to manage secondary resources. A dependent resource represents a secondary resource with related reconciliation logic.
>
> Dependent Resource - a feature of JOSDK to simplify the management of secondary resources. A dependent resource represents a secondary resource with related reconciliation logic.
>
> Low-level API - refers to the SDK APIs that don't use any features (such as Dependent Resources or Workflows) outside of the core Reconciler interface. See the WebPage sample. The same logic is also implemented using Dependent Resource and Workflows.
>
> Low-level API - refers to SDK APIs that don't use any features outside the core Reconciler interface (such as Dependent Resources or Workflows). See the WebPage sample. The same logic is also implemented using Dependent Resources and Workflows.
>
> Reconciler interface. See the WebPage sample. The same logic is also implemented using Dependent Resource and Workflows
>
> Reconciler interface. See the WebPage sample. The same logic is also implemented using Dependent Resources and Workflows

## 2.3 How to Use Java Operator SDK

The Java Operator SDK project itself comes with several example projects. The WebPage example is most suitable for beginners. Next, we will use this example as the core to explain the above concepts and development process.

### 2.3.1 Official WebPage Example

The WebPage Operator example demonstrates how custom resources supported by Operators serve as an abstraction layer. This Operator will use the WebPage resource, which mainly contains the definition of a static web page, and create an NGINX Deployment backed by a ConfigMap containing HTML content.

In other words, WebPage is the primary resource, corresponding to three secondary resources which are all Kubernetes native resources: Deployment, ConfigMap, and Service.

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

Save the above YAML file in the local project's k8s folder and rename it to mynginx-hello.yaml.

When we start the Operator, create this custom resource with the following command:

```bash
kubectl apply -f k8s/mynginx-hello.yaml
```

## 2.3.2 Operator Development Process

### 2.4.1 Step 1: Create Maven Project

Create a Maven project named java-op-example. Users can define their own artifactId and groupId, noting that the project requires JDK 11+.

After waiting for project creation, modify the pom file. Since we cannot reference the WebPage project here, all necessary content is provided:

```xml
    <!--Version Properties-->
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

    <!--Dependency Management-->
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

    <!--Dependencies-->
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
    <!--Build Tools-->
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

Note that the crd-generator-apt library is essential. You'll notice that our build tools don't include any CRD generation processes. This is because crd-generator-apt automatically generates CRD YAML files during the mvn package process based on the code.

### 2.4.2 Step 2: Build Custom Resources

After refreshing dependencies, readers can start writing custom resources. For brevity, we won't paste the WebPage code here.

Readers can create `<groupId>.<artifactId>.cr` under java-op-example/src/main/java

Then refer to [GitHub Code](https://github.com/operator-framework/java-operator-sdk/tree/main/sample-operators/webpage/src/main/java/io/javaoperatorsdk/operator/sample/customresource) and paste it to the directory.

There are mainly three files: WebPage.java, WebPageSpec.java, WebPageStatus.java

Note that WebPageSpec.java and WebPageStatus.java are actually simple POJOs.

The difference is in the WebPage.java writing style:
```java
@Group("sample.javaoperatorsdk")
@Version("v1")
public class WebPage extends CustomResource<WebPageSpec, WebPageStatus>
    implements Namespaced {
    // methods
}
```

Here you need to specify @Group and @Version, inherit the CustomResource interface, and if the scope is namespace-level, implement the Namespaced interface. If not specified, crd-generator-apt will not automatically generate during mvn package process.

### 2.4.3 Step 3: Controller Core Reconciliation Logic

Since Flink Operator itself is built using the low-level API of Java Operator SDK, we focus on this [native implementation](https://github.com/operator-framework/java-operator-sdk/blob/main/sample-operators/webpage/src/main/java/io/javaoperatorsdk/operator/sample/WebPageReconciler.java).

Although the class name is WebPageReconciler, it can actually be considered as the core of a Controller.

```java
public class WebPageReconciler
    implements Reconciler<WebPage>, ErrorStatusHandler<WebPage>, EventSourceInitializer<WebPage> {
    
    @Override
    public Map<String, EventSource> prepareEventSources(EventSourceContext<WebPage> context) {
      // construct configMapEventSource / deploymentEventSource / serviceEventSource
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

As shown in the code, the above represents the low-level API implementation version of the Controller in the WebPage project. WebPageReconciler is the corresponding reconciler, which is the core of implementing the Operator. This class must implement the Reconciler interface, with the corresponding method being reconcile(). The original code is particularly lengthy due to using the low-level API, so I use comments here to summarize the logic. After understanding the meaning, readers can further understand the [specific code](https://github.com/operator-framework/java-operator-sdk/blob/main/sample-operators/webpage/src/main/java/io/javaoperatorsdk/operator/sample/WebPageReconciler.java).

If we only implement the Reconciler interface, it can work, but the problem is that it will repeatedly call Kubernetes APIs to check resource status even when the state is already as expected. Additionally, there will be duplicate reconciliation executions, which is not performance-friendly.

At the same time, when we receive an event, if the specific resource doesn't have a reconcile() method in progress, it will trigger the reconcile() method. In other words, the framework guarantees that resources won't have concurrent reconciliation executions.

Therefore, the official recommendation is to also implement the EventSourceInitializer interface. The corresponding method prepareEventSources() needs to register event sources. Different event sources listen to and cache the latest status of secondary resources managed by WebPage. Reconciliation logic is only triggered when secondary resources change. This achieves efficient reconciliation mechanism.

Finally, there's error handling. WebPageReconciler also implements the ErrorStatusHandler interface. The corresponding method is ErrorStatusUpdateControl. If this interface is not implemented, when reconciliation errors occur, the framework itself will print logs, but users won't see any indication from the custom resource. Readers can see here that the method implementation modifies the `status.errorMessage` of the WebPage object instance.

Note that the match methods in reconciliation logic depend on various resource YAML files already written under the resource folder for reading and comparison. Therefore, readers need to copy the [YAML files](https://github.com/operator-framework/java-operator-sdk/tree/main/sample-operators/webpage/src/main/resources/io/javaoperatorsdk/operator/sample) from the official example to the corresponding package path folder.

### 2.4.4 Step 4: Create Operator and Add Controller

The startup core of Java Operator SDK is also the Operator class. We will register the previously written reconciler to the Operator, with code as follows:

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

I simplified the WebPageOperator code to let readers more intuitively understand that this is actually registering reconciliation logic. The overall registration, startup, and termination sequence diagram is as follows:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/webop-mermaid.png "Operator Sequence Diagram")

In the diagram, ConfigurationService manages Operator configuration and Kubernetes clients, ExecutorService manages Operator execution thread pools and concurrency, and ControllerManager manages Controllers registered to the Operator and reconciliation logic. These belong to the core components within the Operator framework.

### 2.4.5 Step 5: Test Reconciliation Logic

Java Operator SDK has a dedicated testing framework operator-framework-junit-5. This framework is actually quite simple. The specific class diagram is shown below:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/test-framework-class.png "Testing Framework Class Diagram")

The key points are that LocallyRunOperatorExtension corresponds to local unit testing execution, and ClusterDeployedOperatorExtension corresponds to remote cluster deployment for integration testing and E2E testing.

The official WebPage example has corresponding [test code](https://github.com/operator-framework/java-operator-sdk/tree/main/sample-operators/webpage/src/test/java/io/javaoperatorsdk/operator/sample). We won't elaborate here. Readers only need to copy WebPageOperatorAbstractTest and WebPageOperatorE2E.

During actual operation, note that you need to package the Operator program first before testing. This is because the above two test classes will automatically read the CRD YAML files under the packaged directory for deployment. Therefore, you need to use the crd-generator-apt library to generate them automatically.

### 2.4.6 Step 6: Package Image

Readers can paste the test code for testing themselves. After testing is complete, to deploy the Operator program, image packaging is needed.
Readers can refer back to the build configuration in the pom file. We have configured jib-maven-plugin, which is a library that automatically builds images without writing a Dockerfile.

Detailed configuration for jib-maven-plugin can be found in [GitHub link](https://github.com/GoogleContainerTools/jib/tree/master/jib-maven-plugin#configuration)

When packaging images, we need to execute the command:
```shell
mvn clean compile jib:buildTar -Dimage=webpage-operator -Djib.from.image=eclipse-temurin:11-jre
# For Arm architecture MacOS / Linux
# mvn clean compile jib:buildTar -Dimage=webpage-operator -Djib.from.image=eclipse-temurin:11-jre -Djib.from.platforms=linux/arm64

# Check image architecture command
# docker inspect webpage-operator:latest | grep -i arch
```
Then you can see the generated `target/jib-image.tar`

### 2.4.7 Step 7: Kind Deployment and Testing

Before deployment, you first need to create custom resources using the command:
```shell
kubectl apply -f target/classes/META-INF/fabric8/webpages.sample.javaoperatorsdk-v1.yml
```
Next, execute the following commands:
```shell
# Load image to kind cluster
kind load image-archive target/jib-image.tar --name flink-cluster
# Execute Operator deployment
kubectl apply -f k8s/operator.yaml
# Execute WebPage YAML
kubectl apply -f k8s/mynginx-hello.yaml
```

Through this complete development process, we can create a fully functional WebPage Operator to achieve automated management of WebPage applications.