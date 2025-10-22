---
title: "Flink Operator 安装和调试"
date: 2024-10-23T15:24:38+08:00
draft: false
description: ""
---

## 1.1 初识 Flink Operator

Flink Operator 是 Apache Flink 的子项目，是基于 Java Operator SDK 开发的，专门用于管理和操作 Flink 部署的 Kubernetes Operator。

官方网址: https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-main

首页上有一张非常形象的图：

![Flink Operator 架构图](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/arch.png "Flink Operator 架构图")

图中用户提交声明式的 Flink 作业的 Yaml 定义给 Kubernetes 的控制平面，由 Flink Operator 来作业进行验证、部署、升级、监控等功能。

本书会带领读者完成 Flink Operator 的安装部署，以及源码分析。这里的源码基于 v1.10 版本，笔者写稿时的最新版本。

## 1.2 安装 Flink Operator

安装 Flink Operator 的步骤中，我们依赖启动一个 Kubernetes 环境，安装一个生产可用的 Kubernetes 并不简单，一般推荐使用 Kubeadm，对初学者并不友好。我们这里使用 Kind，Kind 工具一般用于 Kubernetes 本身的测试，很多 DevOps 的 CI 流程里会选择 Kind 来快速拉起一个 Kubernetes 环境，然后运行相关测试用例。Kind 可以用于构建单节点或多节点的 Kubernetes。

为什么我们使用 Kind 而不是推荐读者使用 Docker Desktop 更简单的产品呢？因为考虑到用户本地环境的 Kubernetes 版本的冲突，我们直接通过 Kind 拉起测试集群后，不需要的时候可以直接删掉，这样不影响本地的集群。

通过 Kind 拉起测试用的 Kubernetes 环境之后，我们使用 Helm 来安装 Flink Operator。

### 1.2.1 Kind 安装

Kind (Kubernetes in Docker) 是一个用于在本地运行 Kubernetes 集群的工具，它使用 Docker 容器作为集群节点。Kind 主要设计用于测试 Kubernetes 本身，但也可以用于本地开发或 CI 环境。

#### Docker 安装

Docker 是一个开源的容器化平台，Kind 需要 Docker 来创建 Kubernetes 集群节点。

*Linux：*
```bash
# 使用官方便捷脚本安装
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker
```

*macOS：*
```bash
# 使用 Homebrew 安装 Docker Desktop
brew install --cask --appdir=/Applications docker
```

*Windows：*
下载并安装 [Docker Desktop](https://www.docker.com/products/docker-desktop)

#### Go 安装

Go 是由 Google 开发的编程语言，Kind 工具使用 Go 编写，某些高级功能可能需要 Go 环境

*Linux：*
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install golang-go

# CentOS/RHEL/Fedora  
sudo dnf install golang

# 或下载最新版本
wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

*macOS：*
```bash
# 使用 Homebrew
brew install go
```

*Windows：*
下载并安装 [Go 官方安装包](https://go.dev/dl/)

#### Kubectl 安装

kubectl 是 Kubernetes 的命令行工具，用于与 Kubernetes 集群进行交互。

*Linux：*
```bash
# 下载最新版本
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# 安装 kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 或使用包管理器安装
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y kubectl

# CentOS/RHEL/Fedora
sudo dnf install -y kubectl
```

*macOS：*
```bash
# 使用 Homebrew
brew install kubectl

# 或下载二进制文件
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

*Windows：*
```powershell
# 使用 Chocolatey
choco install kubernetes-cli

# 或下载并安装
# 访问 https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

#### 安装Kind

*macOS 用户：*
```bash
# 使用 Homebrew 安装
brew install kind
```

*Linux 用户：*
```bash
# 下载最新版本的 Kind
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

*Windows 用户：*
```bash
# 使用 Chocolatey 安装
choco install kind
```

*验证安装*

```bash
kind version
```

#### 创建 Kubernetes 集群

**创建单节点集群：**
```bash
kind create cluster --name flink-cluster
```

**创建多节点集群：**

首先创建配置文件 `kind-config.yaml`：
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

然后使用配置文件创建集群：
```bash
kind create cluster --name flink-cluster --config kind-config.yaml
```

#### 验证集群状态

```bash
kubectl get nodes
```

你应该看到类似以下的输出：
```
NAME                          STATUS   ROLES           AGE   VERSION
flink-cluster-control-plane   Ready    control-plane   75s   v1.32.2
flink-cluster-worker          Ready    <none>          65s   v1.32.2
flink-cluster-worker2         Ready    <none>          65s   v1.32.2
```

### 1.2.2 Helm 安装

Helm 是 Kubernetes 的包管理器，它简化了 Kubernetes 应用程序的部署和管理。我们将使用 Helm 来安装 Flink Operator。

#### 安装 Helm

**macOS 用户：**
```bash
# 使用 Homebrew 安装
brew install helm

# 或者升级现有版本
brew upgrade helm
```

**Linux 用户：**
```bash
# Ubuntu/Debian
sudo apt-get install helm

# 或者使用安装脚本
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Windows 用户：**
```bash
# 使用 Chocolatey 安装
choco install kubernetes-helm
```

#### 验证 Helm 安装

```bash
helm version
```

### 1.2.3 Flink Operator 安装

现在我们开始安装 Flink Kubernetes Operator。安装过程包括几个步骤：安装证书管理器、添加 Helm 仓库、最后安装 Operator。

#### 1. 安装证书管理器

Flink Operator 需要证书管理器来为其 WebHook 功能颁发 TLS 证书：

Flink Operator 安装过程中如果遇到镜像拉取问题，请检查本地环境 Docker 拉取镜像的配置，建议参考[Docker镜像加速](https://www.runoob.com/docker/docker-mirror-acceleration.html)

```bash
# 安装最新版本的 cert-manager
kubectl create -f https://github.com/jetstack/cert-manager/releases/download/v1.18.1/cert-manager.yaml

# 验证 cert-manager 安装
kubectl get pods -n cert-manager

# 你能看到：
NAME                                      READY   STATUS    RESTARTS   AGE
cert-manager-69f7f6c764-hm42m             1/1     Running   0          23s
cert-manager-cainjector-8fbb9ccfc-jmbg2   1/1     Running   0          5m24s
cert-manager-webhook-667968f47b-6pkbb     1/1     Running   0          5m24s
```

等待所有 cert-manager 的 Pod 都处于 Running 状态。

#### 2. 添加 Flink Operator Helm 仓库

```bash
# 添加 Apache Flink Operator Helm 仓库（使用最新版本 1.12.0）
helm repo add flink-operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-1.10.0/

# 验证仓库添加成功
helm repo list

# 更新仓库
helm repo update
```

#### 3. 安装 Flink Operator

**基础安装：**
```bash
helm install flink-kubernetes-operator flink-operator-repo/flink-kubernetes-operator

# 你会看到类似的输出
NAME: flink-kubernetes-operator
LAST DEPLOYED: Wed May 23 21:05:16 2024
NAMESPACE: flink
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

#### 4. 验证安装

```bash
# 检查 Operator Pod 状态
kubectl get pods

# 查看 Operator 日志
kubectl logs -l app.kubernetes.io/name=flink-kubernetes-operator

# 验证 CRD 安装
kubectl get crd | grep flink
```

你应该看到类似以下的输出：
```
NAME                                                  STATUS   ROLES    AGE
flink-kubernetes-operator-fb5d46f94-ghd8b            2/2      Running  0       4m21s

flinkdeployments.flink.apache.org                    2024-01-20T10:30:45Z
flinksessionjobs.flink.apache.org                    2024-01-20T10:30:45Z
flinkstatesnapshots.flink.apache.org                 2024-01-20T10:30:45Z
```

#### 5. 权限说明

Helm Chart 会创建两个 Kubernetes 角色和相关的服务账户：

- **flink-operator**：用于 Flink Operator 管理 Flink 部署，默认是集群范围的
- **flink**：用于 Flink JobManager 创建 TaskManager Pod，默认是命名空间范围的

如果你想在其他命名空间部署 Flink 作业，需要参考 [Operator RBAC 文档](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-main/docs/operations/rbac/) 创建相应的角色和服务账户。

#### 6. 卸载（可选）

如果需要卸载 Flink Operator：
```bash
# 卸载 Operator
helm uninstall flink-kubernetes-operator

# 删除 Kind 集群（可选）
kind delete cluster --name flink-cluster
```

至此，我们已经成功安装了 Flink Kubernetes Operator。接下来我们将学习如何使用它来部署和管理 Flink 作业。

#### 7. 镜像拉取问题

由于 Kind 本质上是使用 Docker 容器实例来创建 Kubernetes 的节点，也就是节点环境与我们本地环境是不互通的。当我们安装 Flink Operator 时会去拉取对应的镜像，对于中国大陆的用户可能会出现拉取不到镜像报错的问题。这时候可以在本地将镜像打成压缩包，然后通过 Kind 进行镜像加载到节点的镜像列表。

```bash
# 使用本地已经拉取好的镜像
docker pull ghcr.io/apache/flink-kubernetes-operator:c703255
docker save ghcr.io/apache/flink-kubernetes-operator:c703255 > ghcr.tar
# 通过命令加载镜像到 Kind 集群
kind load image-archive ghcr.tar --name flink-cluster
```

## 1.3 Flink Operator 如何用

我们可以直接通过官方的例子进行测试：

```bash
kubectl create -f https://raw.githubusercontent.com/apache/flink-kubernetes-operator/release-1.10/examples/basic.yaml

# 执行完成之后，你会看到
NAME                                         READY   STATUS    RESTARTS   AGE
basic-example-6948f57ff8-7gslt               1/1     Running   0          9s
basic-example-taskmanager-1-1                1/1     Running   0          1s

# 可以通过来映射 Web UI 的端口，你就能访问 localhost:8081 来看到 Web UI 
kubectl port-forward svc/basic-example-rest 8081

```
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/webui-example.png "Flink WebUI的截图")

如果要停止作业，可以执行下列的命令：

```bash
kubectl delete flinkdeployment/basic-example
```

你可以从删除的命令中看到，这与一般常见的 Kubernetes 资源不同，这里的`flinkdeployment`是 Flink Operator 的自定义资源对象。

简单来说，Flink Operator 通过定义自定义资源的内容，用户就能通过声明式的 Yaml 文件来创建一个 FlinkDeployment，我们能够仔细看一下这个例子中的 Yaml 文件内容：

```yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment 
metadata:
  name: basic-example
spec:
  image: flink:1.17
  flinkVersion: v1_17 
  flinkConfiguration: # 对应 Flink Application-mode 集群的 conf.yaml 
    taskmanager.numberOfTaskSlots: "2"
  serviceAccount: flink # 控制权限
  jobManager:
    resource: # 一个JobManager Pod的资源配置
      memory: "2048m"
      cpu: 1
  taskManager:
    resource: # 一个TaskManager Pod资源配置
      memory: "2048m"
      cpu: 1
  job:
    jarURI: local:///opt/flink/examples/streaming/StateMachineExample.jar # 镜像内的地址
    parallelism: 2 # Flink的全局并行度
    upgradeMode: stateless
```

如果你对 Kubernetes 有点印象的话，你会发现有你熟悉的 apiVersion, kind, metadata, spec 等声明配置。这个例子中使用的是 Flink 1.17版本，运行的是 Flink 发行版中流式计算的 StateMachineExample。这里 FlinkDeployment 默认启动的集群是 Application-mode，Yaml 中也声明了 JobManager 和 TaskManager 的资源配置。更进一步的信息，笔者会在后续的章节详细说明。

## 1.4 Flink Operator 源码和调试

首先，读者需要先从Github上拉取 Flink Operator的源码

```bash
git clone https://github.com/apache/flink-kubernetes-operator.git
# 切换到 1.10 版本
git checkout release-1.10.0
```

接着，我们需要从 Flink Operator 的容器中找到启动脚本

```bash
# 获取 flink operator 的容器实例
kubectl get po | grep flink-kubernetes 

# 你会看到类似的输出
flink-kubernetes-operator-6c6c8dc784-45sd6   2/2     Running   0          115m

# 查看对应的 pod 的详情
kubectl describe po flink-kubernetes-operator-6c6c8dc784-45sd6 | grep -A 2 "Command:"

# 你会看到类似的输出
    Command:
      /docker-entrypoint.sh
      operator
--
    Command:
      /docker-entrypoint.sh
      webhook
```

当我们查看 Operator 的容器实例详情时，我们需要注意的是，启动的 Pod 中包含两个容器，一个是 Operator 本身，另外一个是 WebHook。这里我们先只关注，Operator 容器实例的启动过程。不过，从输出中读者可以看到，启动脚本其实是同一个都是`docker-entrypoint.sh`

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/op-docker-entrypoint.png "IDEA docker-entrypoint.sh代码截图")

我们从代码仓库继续查看`docker-entrypoint.sh`，可以看到启动 Operator 时的启动类，以及启动命令中有 `$JVM_ARGS` 即 JVM 启动参数，这是容器实例的一个环境变量。如果我们要进行远程调试，就是要修改这个参数。显而易见，这个环境变量是 Operator 的 Pod 的 Spec 声明写入的，我们可以敲命令验证

```bash
kubectl describe po flink-kubernetes-operator-6c6c8dc784-45sd6 | grep JVM_ARGS 

# 你可以看到类似输出
      JVM_ARGS:            
      JVM_ARGS: 
```

可见 `$JVM_ARGS` 都是没有配置的，那我们要怎么修改呢？我们是利用 Helm 的 Chart 来安装 Flink Operator，可见我们需要对 Chart 进行修改。

### 1.4.1 修改 Helm Chart

在修改 Flink Operator 的 Chart 之前，我们需要先了解 Chart 的结构。以下是拉取和查看 Chart 的步骤：

#### 拉取 Chart 制品到本地

```bash
# 拉取 Flink Operator Chart 到本地
helm pull flink-operator-repo-1.10/flink-kubernetes-operator --untar

# 查看拉取的文件
ls -la flink-kubernetes-operator/
```

你会看到类似以下的目录结构：
```
flink-kubernetes-operator/
├── .helmignore        # Helm 忽略文件
├── Chart.yaml         # Chart 元数据
├── conf/              # 配置文件目录
├── crds/              # 自定义资源定义
├── templates/         # Kubernetes 资源模板
└── values.yaml        # 默认配置值
```

#### 查看 Chart 的默认配置

```bash
# 查看默认的 values.yaml
cat flink-kubernetes-operator/values.yaml

# 或者使用 helm show 命令
helm show values flink-operator-repo/flink-kubernetes-operator

# 查找 jvm 相关的配置
grep  "jvm" flink-kubernetes-operator/values.yaml

# 可以看到类似输出
# Set the jvm start up options for webhook and operator
jvmArgs:
```

这说明，我们可以直接在这里修改，但是我们这里写入的是容器内生效，而IDEA在我们本地环境，两者端口需要做一层映射。如果不做映射的话，IDEA是没有办法进行远程调试的。

所以我们需要进一步查看 Chart 的模板结构。

#### 查看 Chart 的模板结构

```bash
# 查看拉取的文件
ls -la flink-kubernetes-operator/templates

# 你会看到类似以下的目录结构：

flink-kubernetes-operator/templates/
├── _helpers.tpl        # Helm 模板助手函数
├── flink-operator.yaml # Flink Operator 部署配置
├── rbac.yaml          # 角色权限配置
├── serviceaccount.yaml # 服务账户配置
└── webhook.yaml       # Webhook 配置
```

很明显我们只需要修改 `flink-operator.yaml`, 其他文件可以先不用管。

### 1.4.2 修改 flink-operator.yaml

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/debug-port.png "修改flink-operator.yaml")

这里我们直接贴出修改的内容而不过多的展开如何理解 Flink Operator 部署配置模版。其实一句话概括就是，笔者只是往 Flink Operator 的 Pod 的 Operator Container 中增加了一个暴露的 containerPort。理解 Kubernetes 的读者能很快的反应出来，为了外部能够访问这个端口，最好自己再创建一个 Service 来提供外部访问。Service 的 Yaml 文件如下：

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: flink-kubernetes-operator
    app.kubernetes.io/version: 1.4.0
    helm.sh/chart: flink-kubernetes-operator-1.4.0
  name: flink-kubernetes-operator
  namespace: flink
spec:
  type: NodePort
  ports:
  - port: 5008
    nodePort: 31008
    name: debug
    protocol: TCP
    targetPort: debug
  selector:
    app.kubernetes.io/name: flink-kubernetes-operator
```

创建了 Service 之后，我们需要修改 Chart 中的 `values.yaml`，如下图：

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/debug-values-edit.png "values.yaml 的修改内容")

### 1.4.3 启动调试

最后，启动IDEA，配置好远程调试的功能，就能够进行远程调试了

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/idea-debug.png "IDEA debug 配置")

为什么端口号是31008，因为我们创建了 NodePort Service 将容器内的 5008 的调试端口映射到本地环境的 31008 端口了。如果读者有端口占用问题，可以自行修改。但是，一定要确保这些映射关系的正确。 

对应的启动模块是，`flink-kubernetes-operator` 启动类即启动脚本中对应的 `org.apache.flink.kubernetes.operator.FlinkOperator`




