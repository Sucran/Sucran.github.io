---
title: "Flink Operator Installation and Debugging"
date: 2024-10-23T15:24:38+08:00
draft: false
description: ""
---

## 1.1 Introduction to Flink Operator

Flink Operator is a sub-project of Apache Flink, developed based on Java Operator SDK, specifically designed for managing and operating Flink deployments as a Kubernetes Operator.

Official website: https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-main

The homepage features a very illustrative diagram:

![Flink Operator Architecture](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/arch.png "Flink Operator Architecture")

In the diagram, users submit declarative Flink job YAML definitions to the Kubernetes control plane, where Flink Operator handles job validation, deployment, upgrades, monitoring, and other functions.

This book will guide readers through the installation and deployment of Flink Operator, as well as source code analysis. The source code here is based on version v1.10, the latest version at the time of writing.

## 1.2 Installing Flink Operator

In the process of installing Flink Operator, we need to start a Kubernetes environment. Installing a production-ready Kubernetes is not simple, and Kubeadm is generally recommended, which is not beginner-friendly. Here we use Kind, a tool typically used for testing Kubernetes itself. Many DevOps CI pipelines choose Kind to quickly spin up a Kubernetes environment and run related test cases. Kind can be used to build single-node or multi-node Kubernetes clusters.

Why do we use Kind instead of recommending readers to use simpler products like Docker Desktop? Because we consider potential Kubernetes version conflicts in users' local environments. By directly spinning up a test cluster through Kind, we can delete it when not needed, which won't affect the local cluster.

After spinning up a test Kubernetes environment through Kind, we use Helm to install Flink Operator.

### 1.2.1 Kind Installation

Kind (Kubernetes in Docker) is a tool for running Kubernetes clusters locally, using Docker containers as cluster nodes. Kind is primarily designed for testing Kubernetes itself, but can also be used for local development or CI environments.

#### Docker Installation

Docker is an open-source containerization platform. Kind requires Docker to create Kubernetes cluster nodes.

*Linux:*
```bash
# Install using official convenience script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

*macOS:*
```bash
# Install Docker Desktop using Homebrew
brew install --cask --appdir=/Applications docker
```

*Windows:*
Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop)

#### Go Installation

Go is a programming language developed by Google. The Kind tool is written in Go, and some advanced features may require a Go environment.

*Linux:*
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install golang-go

# CentOS/RHEL/Fedora  
sudo dnf install golang

# Or download the latest version
wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

*macOS:*
```bash
# Using Homebrew
brew install go
```

*Windows:*
Download and install the [Go official installation package](https://go.dev/dl/)

#### Kubectl Installation

kubectl is the command-line tool for Kubernetes, used to interact with Kubernetes clusters.

*Linux:*
```bash
# Download the latest version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Or install using package manager
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y kubectl

# CentOS/RHEL/Fedora
sudo dnf install -y kubectl
```

*macOS:*
```bash
# Using Homebrew
brew install kubectl

# Or download binary file
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

*Windows:*
```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or download and install
# Visit https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

#### Installing Kind

*macOS users:*
```bash
# Install using Homebrew
brew install kind
```

*Linux users:*
```bash
# Download the latest version of Kind
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

*Windows users:*
```bash
# Install using Chocolatey
choco install kind
```

*Verify installation*

```bash
kind version
```

#### Creating Kubernetes Cluster

**Create single-node cluster:**
```bash
kind create cluster --name flink-cluster
```

**Create multi-node cluster:**

First, create a configuration file `kind-config.yaml`:
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

Then create the cluster using the configuration file:
```bash
kind create cluster --name flink-cluster --config kind-config.yaml
```

#### Verify Cluster Status

```bash
kubectl get nodes
```

You should see output similar to:
```
NAME                          STATUS   ROLES           AGE   VERSION
flink-cluster-control-plane   Ready    control-plane   75s   v1.32.2
flink-cluster-worker          Ready    <none>          65s   v1.32.2
flink-cluster-worker2         Ready    <none>          65s   v1.32.2
```

### 1.2.2 Helm Installation

Helm is Kubernetes' package manager, which simplifies the deployment and management of Kubernetes applications. We will use Helm to install Flink Operator.

#### Installing Helm

**macOS users:**
```bash
# Install using Homebrew
brew install helm

# Or upgrade existing version
brew upgrade helm
```

**Linux users:**
```bash
# Ubuntu/Debian
sudo apt-get install helm

# Or use installation script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Windows users:**
```bash
# Install using Chocolatey
choco install kubernetes-helm
```

#### Verify Helm Installation

```bash
helm version
```

### 1.2.3 Flink Operator Installation

Now we begin installing Flink Kubernetes Operator. The installation process includes several steps: installing the certificate manager, adding the Helm repository, and finally installing the Operator.

#### 1. Install Certificate Manager

Flink Operator requires a certificate manager to issue TLS certificates for its WebHook functionality:

If you encounter image pull issues during Flink Operator installation, please check your local environment's Docker image pull configuration. It's recommended to refer to [Docker Image Acceleration](https://www.runoob.com/docker/docker-mirror-acceleration.html)

```bash
# Install the latest version of cert-manager
kubectl create -f https://github.com/jetstack/cert-manager/releases/download/v1.18.1/cert-manager.yaml

# Verify cert-manager installation
kubectl get pods -n cert-manager

# You should see:
NAME                                      READY   STATUS    RESTARTS   AGE
cert-manager-69f7f6c764-hm42m             1/1     Running   0          23s
cert-manager-cainjector-8fbb9ccfc-jmbg2   1/1     Running   0          5m24s
cert-manager-webhook-667968f47b-6pkbb     1/1     Running   0          5m24s
```

Wait for all cert-manager Pods to be in Running status.

#### 2. Add Flink Operator Helm Repository

```bash
# Add Apache Flink Operator Helm repository (using latest version 1.12.0)
helm repo add flink-operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-1.10.0/

# Verify repository was added successfully
helm repo list

# Update repository
helm repo update
```

#### 3. Install Flink Operator

**Basic installation:**
```bash
helm install flink-kubernetes-operator flink-operator-repo/flink-kubernetes-operator

# You should see output similar to:
NAME: flink-kubernetes-operator
LAST DEPLOYED: Wed May 23 21:05:16 2024
NAMESPACE: flink
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

#### 4. Verify Installation

```bash
# Check Operator Pod status
kubectl get pods

# View Operator logs
kubectl logs -l app.kubernetes.io/name=flink-kubernetes-operator

# Verify CRD installation
kubectl get crd | grep flink
```

You should see output similar to:
```
NAME                                                  STATUS   ROLES    AGE
flink-kubernetes-operator-fb5d46f94-ghd8b            2/2      Running  0       4m21s

flinkdeployments.flink.apache.org                    2024-01-20T10:30:45Z
flinksessionjobs.flink.apache.org                    2024-01-20T10:30:45Z
flinkstatesnapshots.flink.apache.org                 2024-01-20T10:30:45Z
```

#### 5. Permission Notes

The Helm Chart creates two Kubernetes roles and related service accounts:

- **flink-operator**: Used by Flink Operator to manage Flink deployments, cluster-scoped by default
- **flink**: Used by Flink JobManager to create TaskManager Pods, namespace-scoped by default

If you want to deploy Flink jobs in other namespaces, you need to refer to the [Operator RBAC documentation](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-main/docs/operations/rbac/) to create corresponding roles and service accounts.

#### 6. Uninstall (Optional)

If you need to uninstall Flink Operator:
```bash
# Uninstall Operator
helm uninstall flink-kubernetes-operator

# Delete Kind cluster (optional)
kind delete cluster --name flink-cluster
```

At this point, we have successfully installed Flink Kubernetes Operator. Next, we will learn how to use it to deploy and manage Flink jobs.

#### 7. Image Pull Issues

Since Kind essentially uses Docker container instances to create Kubernetes nodes, the node environment is not interconnected with our local environment. When we install Flink Operator, it will pull corresponding images. For users in mainland China, there may be issues with image pull errors. In this case, you can package the local images into compressed files and then load them into the node's image list through Kind.

```bash
# Use locally pulled images
docker pull ghcr.io/apache/flink-kubernetes-operator:c703255
docker save ghcr.io/apache/flink-kubernetes-operator:c703255 > ghcr.tar
# Load images to Kind cluster via command
kind load image-archive ghcr.tar --name flink-cluster
```

## 1.3 How to Use Flink Operator

We can test directly using the official example:

```bash
kubectl create -f https://raw.githubusercontent.com/apache/flink-kubernetes-operator/release-1.10/examples/basic.yaml

# After execution, you should see:
NAME                                         READY   STATUS    RESTARTS   AGE
basic-example-6948f57ff8-7gslt               1/1     Running   0          9s
basic-example-taskmanager-1-1                1/1     Running   0          1s

# You can map the Web UI port to access localhost:8081 to see the Web UI
kubectl port-forward svc/basic-example-rest 8081

```
![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/webui-example.png "Flink WebUI Screenshot")

To stop the job, you can execute the following command:

```bash
kubectl delete flinkdeployment/basic-example
```

You can see from the delete command that this is different from common Kubernetes resources. Here, `flinkdeployment` is a custom resource object of Flink Operator.

Simply put, Flink Operator defines custom resource content, and users can create a FlinkDeployment through declarative YAML files. Let's carefully examine the YAML file content in this example:

```yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment 
metadata:
  name: basic-example
spec:
  image: flink:1.17
  flinkVersion: v1_17 
  flinkConfiguration: # Corresponds to Flink Application-mode cluster's conf.yaml 
    taskmanager.numberOfTaskSlots: "2"
  serviceAccount: flink # Controls permissions
  jobManager:
    resource: # Resource configuration for one JobManager Pod
      memory: "2048m"
      cpu: 1
  taskManager:
    resource: # Resource configuration for one TaskManager Pod
      memory: "2048m"
      cpu: 1
  job:
    jarURI: local:///opt/flink/examples/streaming/StateMachineExample.jar # Address within the image
    parallelism: 2 # Flink's global parallelism
    upgradeMode: stateless
```

If you have some impression of Kubernetes, you'll find familiar declarative configurations like apiVersion, kind, metadata, spec, etc. This example uses Flink version 1.17 and runs the StateMachineExample from Flink's streaming computation distribution. The FlinkDeployment here starts an Application-mode cluster by default, and the YAML also declares resource configurations for JobManager and TaskManager. For more detailed information, the author will explain in subsequent chapters.

## 1.4 Flink Operator Source Code and Debugging

First, readers need to pull the Flink Operator source code from Github:

```bash
git clone https://github.com/apache/flink-kubernetes-operator.git
# Switch to version 1.10
git checkout release-1.10.0
```

Next, we need to find the startup script from the Flink Operator container:

```bash
# Get flink operator container instances
kubectl get po | grep flink-kubernetes 

# You should see output similar to:
flink-kubernetes-operator-6c6c8dc784-45sd6   2/2     Running   0          115m

# View details of the corresponding pod
kubectl describe po flink-kubernetes-operator-6c6c8dc784-45sd6 | grep -A 2 "Command:"

# You should see output similar to:
    Command:
      /docker-entrypoint.sh
      operator
--
    Command:
      /docker-entrypoint.sh
      webhook
```

When we view the container instance details of the Operator, we need to note that the started Pod contains two containers: one is the Operator itself, and the other is the WebHook. Here we'll first focus only on the startup process of the Operator container instance. However, from the output, readers can see that the startup script is actually the same: `docker-entrypoint.sh`

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/op-docker-entrypoint.png "IDEA docker-entrypoint.sh Code Screenshot")

Continuing to examine `docker-entrypoint.sh` from the code repository, we can see the startup class when starting the Operator, and the startup command includes `$JVM_ARGS`, which are JVM startup parameters. This is an environment variable of the container instance. If we want to perform remote debugging, we need to modify this parameter. Obviously, this environment variable is written into the Pod's Spec declaration by the Operator. We can verify this with a command:

```bash
kubectl describe po flink-kubernetes-operator-6c6c8dc784-45sd6 | grep JVM_ARGS 

# You should see output similar to:
      JVM_ARGS:            
      JVM_ARGS: 
```

It's clear that `$JVM_ARGS` is not configured. So how do we modify it? We use Helm's Chart to install Flink Operator, so we need to modify the Chart.

### 1.4.1 Modifying Helm Chart

Before modifying Flink Operator's Chart, we need to understand the Chart structure. Here are the steps to pull and examine the Chart:

#### Pull Chart Artifacts to Local

```bash
# Pull Flink Operator Chart to local
helm pull flink-operator-repo-1.10/flink-kubernetes-operator --untar

# View pulled files
ls -la flink-kubernetes-operator/
```

You should see a directory structure similar to:
```
flink-kubernetes-operator/
├── .helmignore        # Helm ignore file
├── Chart.yaml         # Chart metadata
├── conf/              # Configuration file directory
├── crds/              # Custom resource definitions
├── templates/         # Kubernetes resource templates
└── values.yaml        # Default configuration values
```

#### View Chart's Default Configuration

```bash
# View default values.yaml
cat flink-kubernetes-operator/values.yaml

# Or use helm show command
helm show values flink-operator-repo/flink-kubernetes-operator

# Search for jvm-related configuration
grep  "jvm" flink-kubernetes-operator/values.yaml

# You should see output similar to:
# Set the jvm start up options for webhook and operator
jvmArgs:
```

This shows that we can modify directly here, but what we write here takes effect inside the container, while IDEA is in our local environment. The ports between the two need to be mapped. Without mapping, IDEA cannot perform remote debugging.

So we need to further examine the Chart's template structure.

#### View Chart's Template Structure

```bash
# View pulled files
ls -la flink-kubernetes-operator/templates

# You should see a directory structure similar to:

flink-kubernetes-operator/templates/
├── _helpers.tpl        # Helm template helper functions
├── flink-operator.yaml # Flink Operator deployment configuration
├── rbac.yaml          # Role permission configuration
├── serviceaccount.yaml # Service account configuration
└── webhook.yaml       # Webhook configuration
```

Clearly, we only need to modify `flink-operator.yaml`. Other files can be left alone for now.

### 1.4.2 Modifying flink-operator.yaml

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/debug-port.png "Modifying flink-operator.yaml")

Here we directly provide the modification content without extensively explaining how to understand the Flink Operator deployment configuration template. In fact, to summarize in one sentence: the author simply added an exposed containerPort to the Operator Container of the Flink Operator Pod. Readers familiar with Kubernetes will quickly realize that to allow external access to this port, it's best to create a Service to provide external access. The Service YAML file is as follows:

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

After creating the Service, we need to modify the `values.yaml` in the Chart, as shown in the figure below:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/debug-values-edit.png "values.yaml Modification Content")

### 1.4.3 Starting Debugging

Finally, start IDEA, configure the remote debugging functionality, and you can perform remote debugging:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/img/flink-op/idea-debug.png "IDEA Debug Configuration")

Why is the port number 31008? Because we created a NodePort Service that maps the debug port 5008 inside the container to port 31008 in the local environment. If readers have port conflicts, they can modify it themselves. However, they must ensure the correctness of these mapping relationships.

The corresponding startup module is `flink-kubernetes-operator`, and the startup class is `org.apache.flink.kubernetes.operator` as mentioned in the startup script. 