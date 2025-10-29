---
title: "Painless Path from Building K8s Small Cluster to Karmada Cross-Cluster on Alibaba Cloud ECS"
date: 2025-10-28T10:54:12+08:00
draft: false
description: ""
---

This article guides readers through building a K8s cluster using Alibaba Cloud ECS and performing related configuration and usage. We use Kubeadm to build the K8s cluster, and this tutorial involves the use of Alibaba Cloud ECS images, enabling readers to quickly create cluster nodes.

The "5 minutes" mentioned in this article is based on the process of cluster setup after users have already built the initial software image.

## 1. Create ECS Instance

First, readers need to log in to Alibaba Cloud, enter the console, and click on Cloud Server ECS.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-07-04.png)

Then click to create an instance. It is recommended that readers initially try only spot instances, which are lower cost, and the resources of spot instances can be released at any time without incurring additional costs.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-09-19.png)

If spot instances are set to release directly by default, users may not have time to create images, so it is recommended to choose "stop instead of release".

In addition, all operations below are based on Ubuntu 22.04 public images. If switching to other systems, the versions of installed software may differ.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-11-23.png)

Since Alibaba Cloud's fixed bandwidth costs are relatively high, and we want faster software installation rates, we choose pay-as-you-go for traffic.

In addition, it is recommended that users use key pairs for login, which can avoid password leakage risks and facilitate subsequent operations.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-12-52.png)

Next, we click to create an instance and wait for the instance creation to complete.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-50-33.png)

When using a key pair for login, you need to use the key pair file path.

```bash
ssh -i ~/.ssh/your_key_pair_file root@<Public IP>
```

## 2. Install Necessary Software and Create Image

### Pre-step: Configure Kernel Parameters

Before installing necessary software, we need to configure kernel parameters first, otherwise we will encounter some issues during installation.

```bash
# Disable swap
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab
# Kernel modules
sudo tee /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
EOF
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```

### 2.1 Install Docker

The specific Docker and Docker Compose installation steps are detailed in the Alibaba Cloud ECS documentation: [Install and Use Docker](https://help.aliyun.com/zh/ecs/user-guide/install-and-use-docker?spm=a2c4g.11174283.help-menu-25365.d_0_10_5_6.13131db82h5a7C#8dca4cfa3dn0e):

```bash 
# Update package manager
sudo apt-get update
# Add Docker package source
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
sudo curl -fsSL http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=$(dpkg --print-architecture)] http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
# Install Docker Community Edition, container runtime containerd.io, and Docker Build and Compose plugins
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

After installation, start Docker and set it to start automatically at boot:

```bash
# Start Docker
sudo systemctl start docker
# Set Docker daemon to start automatically at system boot
sudo systemctl enable docker
```

Finally, we verify if Docker installation is successful:

```bash
# Verify Docker installation
docker version
```

If the installation is successful, you will see output similar to the following:

```bash
root@k8s-master:~# docker version
Client: Docker Engine - Community
 Version:           28.5.1
 API version:       1.51
 Go version:        go1.24.8
 Git commit:        e180ab8
 Built:             Wed Oct  8 12:17:03 2025
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          28.5.1
  API version:       1.51 (minimum version 1.24)
  Go version:       go1.24.8
  Git commit:       f8215cc
  Built:            Wed Oct  8 12:17:03 2025
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v1.7.28
  GitCommit:        b98a3aace656320842a23f4a392a33f46af97866
 runc:
  Version:          1.3.0
  GitCommit:        v1.3.0-0-g4ca628d1
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

Since Kubernetes and Docker have inconsistent default cgroup (control group) drivers, Kubernetes defaults to systemd, while Docker defaults to cgroupfs.

Therefore, we need to modify Docker's cgroup driver to systemd. Also, due to network operator reasons, pulling images from Docker Hub will fail. Configuring a mirror accelerator can solve this problem.

Edit the `/etc/docker/daemon.json` file and add the following content:

```json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": [
    "https://registry.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://ccr.ccs.tencentyun.com",
    "https://docker.m.daocloud.io",
    "https://docker.nju.edu.cn",
    "https://docker.mirrors.sjtug.sjtu.edu.cn"
  ],
  "insecure-registries": [
    "registry.k8s.io",
    "quay.io",
    "gcr.io",
    "k8s.gcr.io"
  ],
  "max-concurrent-downloads": 10,
  "log-driver": "json-file",
  "log-opts": {"max-size": "100m", "max-file": "3"}
}
```



### 2.2 Install Kubeadm

This process directly follows the Kubernetes official documentation: [Installing kubeadm](https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

```bash
# 1. Install packages required to use Kubernetes apt repository:
# apt-transport-https may be a dummy package; if so, you can skip installing this package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# 2. Download Kubernetes GPG key:
# If the /etc/apt/keyrings directory does not exist, it should be created before the curl command, please read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 3. Add Kubernetes apt repository:
# This operation will overwrite all existing configurations in /etc/apt/sources.list.d/kubernetes.list.
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 4. Install kubelet, kubeadm and kubectl:
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# 5. Mark kubelet, kubeadm and kubectl as hold to prevent them from being automatically updated by the system:
sudo apt-mark hold kubelet kubeadm kubectl
```

### 2.3 Install cri-dockerd

Kubernetes uses Docker as the container runtime, but Docker is no longer maintained, so we need to use cri-dockerd as the container runtime.

```bash
# Download cri-dockerd deb package
wget https://ghproxy.net/https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.debian-bookworm_amd64.deb

# Install cri-dockerd
sudo dpkg -i cri-dockerd_0.3.20.3-0.debian-bookworm_amd64.deb
```

### 2.4 Pre-pull Cluster Images

```bash
kubeadm config images pull \
  --image-repository registry.aliyuncs.com/google_containers \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

Batch update image tags:
```bash
declare -A tagMap=(
  [pause]=3.10.1
  [kube-apiserver]=v1.34.1
  [kube-controller-manager]=v1.34.1
  [kube-scheduler]=v1.34.1
  [kube-proxy]=v1.34.1
  [etcd]=3.6.4-0
  [coredns]=v1.12.1
)

# Batch tag
for img in "${!tagMap[@]}"; do
  docker tag registry.aliyuncs.com/google_containers/${img}:${tagMap[$img]} \
     registry.k8s.io/${img}:${tagMap[$img]}
done

# Add additional 3.10 tag for pause image
docker tag registry.aliyuncs.com/google_containers/pause:3.10.1 registry.k8s.io/pause:3.10
docker tag registry.aliyuncs.com/google_containers/pause:3.10.1 registry.aliyuncs.com/google_containers/pause:3.10
```

Finally, you can see the image list:

```bash
root@k8s-master:~# docker images
REPOSITORY                                                        TAG       IMAGE ID       CREATED        SIZE
registry.aliyuncs.com/google_containers/kube-apiserver            v1.34.1   c3994bc69610   6 weeks ago    88MB
registry.k8s.io/kube-apiserver                                    v1.34.1   c3994bc69610   6 weeks ago    88MB
registry.aliyuncs.com/google_containers/kube-controller-manager   v1.34.1   c80c8dbafe7d   6 weeks ago    74.9MB
registry.k8s.io/kube-controller-manager                           v1.34.1   c80c8dbafe7d   6 weeks ago    74.9MB
registry.aliyuncs.com/google_containers/kube-scheduler            v1.34.1   7dd6aaa1717a   6 weeks ago    52.8MB
registry.k8s.io/kube-scheduler                                    v1.34.1   7dd6aaa1717a   6 weeks ago    52.8MB
registry.aliyuncs.com/google_containers/kube-proxy                v1.34.1   fc25172553d7   6 weeks ago    71.9MB
registry.k8s.io/kube-proxy                                        v1.34.1   fc25172553d7   6 weeks ago    71.9MB
registry.aliyuncs.com/google_containers/etcd                      3.6.4-0   5f1f5298c888   3 months ago   195MB
registry.k8s.io/etcd                                              3.6.4-0   5f1f5298c888   3 months ago   195MB
registry.aliyuncs.com/google_containers/pause                     3.10.1    cd073f4c5f6a   4 months ago   736kB
registry.aliyuncs.com/google_containers/pause                     3.10      cd073f4c5f6a   4 months ago   736kB
registry.k8s.io/pause                                             3.10.1    cd073f4c5f6a   4 months ago   736kB
registry.k8s.io/pause                                             3.10      cd073f4c5f6a   4 months ago   736kB
registry.aliyuncs.com/google_containers/coredns                   v1.12.1   52546a367cc9   7 months ago   75MB
registry.k8s.io/coredns                                           v1.12.1   52546a367cc9   7 months ago   75MB
```


### 2.5 Create Image

The above steps have already pulled the necessary software and images locally. Then we only need to create the instance as an ECS custom image, and then we can quickly create nodes and build clusters.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-18-18-27.png)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-18-07-28.png)

After clicking to create the image, view the image list:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-18-19-11.png)

## 3. Create K8s Three-Node Cluster

### 3.1 Create Multi-Node Instances from Image

First, we need to create a Kubernetes cluster, then use the image we created earlier for initialization. There are 3 nodes in total: 1 Master node and 2 Worker nodes.

Based on information obtained from the Alibaba Cloud console, the 3 machines created are as follows:

- **k8s-master01**: Public IP `120.25.48.211`, Private IP `172.29.186.7`
- **k8s-worker01**: Public IP `47.112.215.1`, Private IP `172.29.186.13`
- **k8s-worker02**: Public IP `47.112.220.167`, Private IP `172.29.186.14`

#### Configure Password-less SSH Login

For the convenience of subsequent cluster deployment, we need to configure password-less SSH login between the three machines and configure `/etc/hosts` to use hostnames for access.

**Step 1: Generate SSH key pairs on each machine**

On the master node:

```bash
ssh -i ~/.ssh/sucran.pem root@120.25.48.211
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' -C 'k8s-cluster'
```

On the worker01 node:

```bash
ssh -i ~/.ssh/sucran.pem root@47.112.215.1
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' -C 'k8s-cluster'
```

On the worker02 node:

```bash
ssh -i ~/.ssh/sucran.pem root@47.112.220.167
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' -C 'k8s-cluster'
```

**Step 2: Configure /etc/hosts**

Configure the hosts file on all three machines and add the following content:

```bash
echo '172.29.186.7 k8s-master01
172.29.186.13 k8s-worker01
172.29.186.14 k8s-worker02' >> /etc/hosts
```

**Step 3: Collect public keys from all nodes and distribute them**

Get the public key from each machine:

```bash
# On master node
cat ~/.ssh/id_rsa.pub

# On worker01 node  
cat ~/.ssh/id_rsa.pub

# On worker02 node
cat ~/.ssh/id_rsa.pub
```

Add the public keys of all three nodes to the `~/.ssh/authorized_keys` file on each machine.

**Step 4: Configure SSH parameters**

To avoid interactive confirmation during SSH connections, configure SSH config on all nodes:

```bash
cat > ~/.ssh/config << 'EOF'
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
```

**Step 5: Verify password-less login**

Test password-less login from the master node:

```bash
ssh root@k8s-worker01 'hostname && pwd'
ssh root@k8s-worker02 'hostname && pwd'
```

If password-less login is successful, the configuration is successful.

> **Note**: When connecting to a new host for the first time, you may see a `Warning: Permanently added ...` message. This is normal SSH behavior. This warning will only appear once, and subsequent connections will not display it.


### 3.2 Initialize Master Node

On the master node, execute:

```bash
kubeadm init \
  --apiserver-advertise-address=172.29.186.7 \
  --apiserver-bind-port=6443 \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --image-repository registry.aliyuncs.com/google_containers \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

After completion, you will see output similar to:

```bash
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.29.186.7:6443 --token xxx \
	--discovery-token-ca-cert-hash sha256:xxxx
```

**Troubleshooting: Initialization Stuck**

If kubeadm init is stuck checking control plane component health, it's usually because the `pause:3.10` image is missing. Troubleshooting steps:

1. **Check kubelet logs**:
```bash
journalctl -u kubelet -n 50 | grep -i 'error\|failed'
```

2. **Check container images**:
```bash
docker images | grep pause
```

If you only have `pause:3.10.1` but not `pause:3.10`, you need to create the missing image tag:
```bash
docker tag registry.k8s.io/pause:3.10.1 registry.k8s.io/pause:3.10
docker tag registry.aliyuncs.com/google_containers/pause:3.10.1 registry.aliyuncs.com/google_containers/pause:3.10
```

3. **Restart kubelet**:
```bash
systemctl restart kubelet
```

After the control plane components start, you will see output similar to the following:


### 3.3 Join Worker Nodes

On each worker node, execute the kubeadm join command to join the cluster:

```bash
kubeadm join 172.29.186.7:6443 \ --image-repository registry.aliyuncs.com/google_containers \ --cri-socket unix:///var/run/cri-dockerd.sock --token xxx \ --discovery-token-ca-cert-hash sha256:xxxx
```

After completion, you will see output similar to:


```bash
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

### 3.4 Configure kubectl and Copy to Worker Nodes

Configure kubectl on the master node:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Verify kubectl configuration:

```bash
export KUBECONFIG=$HOME/.kube/config
kubectl get nodes
```

Copy kubeconfig to worker nodes:

```bash
# Copy to worker01
cat $HOME/.kube/config | ssh root@k8s-worker01 "mkdir -p \$HOME/.kube && cat > \$HOME/.kube/config && chmod 600 \$HOME/.kube/config"

# Copy to worker02
cat $HOME/.kube/config | ssh root@k8s-worker02 "mkdir -p \$HOME/.kube && cat > \$HOME/.kube/config && chmod 600 \$HOME/.kube/config"
```

### 3.5 Install Network Plugin

```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.22.0/Documentation/kube-flannel.yml
```

Here we install the flannel network plugin. You can also install other network plugins such as calico, canal, etc. The installation of this plugin depends on the kernel parameter configuration we did earlier.

After installation, you will see that the nodes are in Ready state.

### 3.6 Install Storage Plugin

Pull the image and tag it on the master node:

```bash
docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/rancher/local-path-provisioner:v0.0.32
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/rancher/local-path-provisioner:v0.0.32 \
        rancher/local-path-provisioner:v0.0.32
```

Synchronize the image to all Worker nodes:

```bash
# Sync to worker01
docker save rancher/local-path-provisioner:v0.0.32 | ssh root@k8s-worker01 "docker load"

# Sync to worker02
docker save rancher/local-path-provisioner:v0.0.32 | ssh root@k8s-worker02 "docker load"
```

Install local-path-provisioner:

```bash
export KUBECONFIG=$HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml
```

Verify installation:

```bash
kubectl get pods -n local-path-storage
kubectl get storageclass
```

You should see Pods running and the `local-path` storage class created.


### 3.7 Verify Cluster

```bash
kubectl get nodes
kubectl get pods -n kube-system
kubectl get pods -n local-path-storage
kubectl get storageclass
```

You should see all nodes in Ready state and the `local-path` storage class created.

## 4. Create K8s High Availability Cluster

Chapter 3 has already created a three-node cluster. Next, we create a high availability cluster with 6 nodes: 3 Master nodes and 3 Worker nodes. When creating a high availability cluster, we do not recommend creating Master node instances as spot instances, but rather suggest using pay-as-you-go instances. We still use the previous image to quickly initialize nodes, then build a high availability cluster through Kubeadm.

It should be noted that the three Master nodes need load balancing configuration. Here we directly use Alibaba Cloud's SLB (Server Load Balancer) NLB (Network Load Balancer) to set this up.

**High Availability Cluster Setup Overview**:

1. Create NLB load balancer, configure backend server group (1 Master node)
2. Use the first master node's IP to initialize the first master node
3. **Regenerate apiserver certificate containing NLB address** (critical step)
4. Update control-plane-endpoint to NLB address
5. Install network plugin
6. Generate join token and certificate key
7. Other master nodes join the cluster
8. Worker nodes join the cluster

**Special Note**: Step 3 is a critical step. If this step is skipped, other master nodes will not be able to join the cluster through the NLB address.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-29-12-49-04.png)

After creating the load balancer, we can add three Master node instances to the load balancer.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-29-12-53-00.png)

Create load balancer NLB with details as follows:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-29-13-17-52.png)

Then configure the server group, corresponding to 1 Master node instance, which corresponds to the first node that will be initialized later.


The health check policy also corresponds to port 6443.

### 4.1 Initialize First Master Node

On the first master node, execute:

```bash
kubeadm init \
  --apiserver-advertise-address=172.29.186.15 \
  --apiserver-bind-port=6443 \
  --control-plane-endpoint=172.29.186.15:6443 \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --image-repository registry.aliyuncs.com/google_containers \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

Configure kubectl:

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

Install network plugin:

```bash
export KUBECONFIG=$HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.22.0/Documentation/kube-flannel.yml
```

Wait for the network plugin to start and verify node status:

```bash
kubectl get nodes
kubectl get pods -n kube-flannel
```

### 4.2 Regenerate apiserver Certificate Containing NLB Address

**This step is very critical!** The default generated apiserver certificate only contains the current node's IP address and does not include the NLB address. If the certificate is not regenerated, other master nodes will not be able to join the cluster through the NLB address and will report an error:

```bash
error: tls: failed to verify certificate: x509: certificate is valid for 10.96.0.1, 172.29.186.15, not 172.29.186.24
```

Steps to regenerate the certificate:

```bash
# Backup old certificate
mv /etc/kubernetes/pki/apiserver.{crt,key} /tmp/

# Regenerate certificate containing NLB address
# NLB has two VIPs: 172.29.186.24 and 172.16.32.76, both need to be added
kubeadm init phase certs apiserver \
  --apiserver-advertise-address=172.29.186.15 \
  --apiserver-cert-extra-sans=172.29.186.24,172.16.32.76

# Restart apiserver to apply new certificate
# Method 1: Delete manifest file to let kubelet automatically rebuild (recommended)
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sleep 10

# Method 2: Use crictl to stop container (kubelet will automatically restart)
# crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock ps | grep kube-apiserver | awk '{print $1}' | xargs crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock stop
# sleep 10
```

Verify that the certificate contains the NLB address:

```bash
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 10 "Subject Alternative Name"
```

You should see the NLB address `172.29.186.24` in the output.

### 4.3 Update control-plane-endpoint to NLB Address

Update control-plane-endpoint to NLB address:

```bash
# Backup current configuration
cp /etc/kubernetes/kubeadm-config.yaml /etc/kubernetes/kubeadm-config.yaml.backup

# Update control-plane-endpoint
kubectl -n kube-system get configmap kubeadm-config -o yaml > /tmp/kubeadm-config.yaml
sed -i 's/172.29.186.15:6443/172.29.186.24:6443/g' /tmp/kubeadm-config.yaml
kubectl -n kube-system apply -f /tmp/kubeadm-config.yaml

# Restart all master nodes
systemctl restart kubelet
```

**Note**: After updating control-plane-endpoint, all master nodes need to restart the kubelet service.

### 4.4 Add Other Master Nodes

Generate join command and certificate key on the first master node:

```bash
# Generate new join token
kubeadm token create --ttl 0 --print-join-command

# Upload certificates to cluster, generate certificate key (valid for 2 hours)
kubeadm init phase upload-certs --upload-certs
```

Record the output certificate key (certificate-key), for example:
```
f999ee3f81acb01b16d164fca40bbf78270a14dc9cae962a4f77fa8862fa4767
```

Execute the join command on other master nodes:

```bash
kubeadm join 172.29.186.15:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key> \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

**Notes**:
- The `--certificate-key` parameter must be added to download control plane certificates
- Certificate key is valid for 2 hours, needs to be regenerated after expiration
- After successfully joining, remember to configure kubectl:

```bash
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

Verify all master node status:

```bash
kubectl get nodes
```

You should see all master nodes in Ready state.

### 4.4.1 Update Certificates for All Master Nodes (Critical Step)

**Important**: The apiserver certificates of newly joined master nodes (master02, master03) **do not contain the NLB address** and must regenerate certificates.

This is because `kubeadm join` uses master01's IP address (172.29.186.15), and the generated certificate only contains:
- The node's own IP
- The address in the join command (172.29.186.15)
- **Does not include the NLB VIP address**

**NLB VIP Explanation**:
- Alibaba Cloud NLB usually has **two VIPs** (Virtual IPs) for high availability
- In this example: `172.29.186.24` and `172.16.32.76`
- **Both VIPs must be added to the certificate** to prevent failure to switch when a single VIP fails

If certificates are not updated, accessing through NLB will report an error:
```bash
tls: failed to verify certificate: x509: certificate is valid for ... not 172.29.186.24
```

**Update certificate on master02**:

```bash
# SSH to master02
ssh root@master02

# Backup old certificate
mv /etc/kubernetes/pki/apiserver.{crt,key} /tmp/

# Regenerate certificate containing NLB address
# NLB has two VIPs: 172.29.186.24 and 172.16.32.76, both need to be added
kubeadm init phase certs apiserver \
  --apiserver-advertise-address=172.16.32.80 \
  --apiserver-cert-extra-sans=172.29.186.24,172.16.32.76,172.29.186.15

# Restart apiserver
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sleep 10
```

**Update certificate on master03**:

```bash
# SSH to master03
ssh root@master03

# Backup old certificate
mv /etc/kubernetes/pki/apiserver.{crt,key} /tmp/

# Regenerate certificate containing NLB address
# NLB has two VIPs: 172.29.186.24 and 172.16.32.76, both need to be added
kubeadm init phase certs apiserver \
  --apiserver-advertise-address=172.16.32.79 \
  --apiserver-cert-extra-sans=172.29.186.24,172.16.32.76,172.29.186.15

# Restart apiserver
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sleep 10
```

**Verify all certificates contain both NLB VIPs**:

```bash
# Verify on master01
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Subject Alternative Name"
# Should see: IP Address:172.29.186.24 and IP Address:172.16.32.76

# Verify on master02
ssh root@master02 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Subject Alternative Name"'
# Should see: IP Address:172.29.186.24 and IP Address:172.16.32.76

# Verify on master03
ssh root@master03 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Subject Alternative Name"'
# Should see: IP Address:172.29.186.24 and IP Address:172.16.32.76

# Or more detailed check
for master in master01 master02 master03; do
  echo "=== $master ==="
  ssh root@$master 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep "IP Address"'
done
```

All node certificates should contain the following IPs:
- `10.96.0.1` (Kubernetes service IP)
- Node's own IP
- `172.29.186.15` (master01 IP)
- `172.29.186.24` (NLB VIP 1) ⭐ Critical
- `172.16.32.76` (NLB VIP 2) ⭐ Critical

### 4.5 Expand NLB Server Group

Since we only configured master01 node initially to ensure NLB health checks work properly, after all Master nodes are initialized, we need to expand the NLB server group to 3 Master node instances.

In the Alibaba Cloud console, expand the NLB server group to 3 Master node instances.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-29-14-50-13.png)

This ensures load balancing across all Master nodes.


### 4.6 Add Worker Nodes

Adding Worker nodes is simpler than master nodes and does not require the `--control-plane` and `--certificate-key` parameters.

Generate join command on the first master node (if the previous token is still valid, you can skip this step):

```bash
kubeadm token create --ttl 0 --print-join-command
```

Example output:
```bash
kubeadm join 172.29.186.15:6443 --token e7xp39.kox3g4jq97nbv1nu --discovery-token-ca-cert-hash sha256:557cda54ed4467576fd88677fc0ade60a56f0291a7cb0c8078484fd419acf515
```

Execute the join command on worker nodes:

```bash
kubeadm join 172.29.186.15:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

**Note**: Worker nodes do not need the `--control-plane` and `--certificate-key` parameters.

Verify worker nodes joined:

```bash
kubectl get nodes
```

You should see output similar to:
```bash
NAME                      STATUS   ROLES           AGE   VERSION
izwz9b786esx09okwzr8azz   Ready    control-plane   21m   v1.34.1
izwz9b786esx09okwzr8b0z   Ready    control-plane   13m   v1.34.1
izwz9b786esx09okwzr8b1z   Ready    control-plane   11m   v1.34.1
izwz95hnhy94jc97w13e6qz   Ready    <none>          3m    v1.34.1
izwz95hnhy94jc97w13e6pz   Ready    <none>          75s   v1.34.1
izwz95hnhy94jc97w13e6oz   Ready    <none>          63s   v1.34.1
```

### 4.7 Verify High Availability Cluster

View complete cluster status:

```bash
kubectl get nodes -o wide
```

Example output:
```bash
NAME                      STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
izwz9b786esx09okwzr8azz   Ready    control-plane   21m   v1.34.1   172.29.186.15   <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz9b786esx09okwzr8b0z   Ready    control-plane   13m   v1.34.1   172.16.32.80    <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz9b786esx09okwzr8b1z   Ready    control-plane   11m   v1.34.1   172.16.32.79    <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz95hnhy94jc97w13e6qz   Ready    <none>          3m    v1.34.1   172.29.186.19   <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz95hnhy94jc97w13e6pz   Ready    <none>          75s   v1.34.1   172.29.186.20   <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz95hnhy94jc97w13e6oz   Ready    <none>          63s   v1.34.1   172.29.186.18   <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
```

Verify all component running status:

```bash
kubectl get pods -A
```

Critical component verification:

```bash
# Verify etcd cluster (3 instances)
kubectl get pods -n kube-system | grep etcd

# Verify apiserver (3 instances)
kubectl get pods -n kube-system | grep apiserver

# Verify controller-manager (3 instances)
kubectl get pods -n kube-system | grep controller-manager

# Verify scheduler (3 instances)
kubectl get pods -n kube-system | grep scheduler

# Verify network plugin (one per node)
kubectl get pods -n kube-flannel
```

Test deployment application:

```bash
# Create test deployment
kubectl create deployment nginx --image=nginx --replicas=3

# View pod distribution
kubectl get pods -o wide

# Verify pods running normally
kubectl get deployment nginx

# Clean up test resources
kubectl delete deployment nginx
```

At this point, the high availability Kubernetes cluster setup is complete! The cluster has the following features:

- ✅ **3 Master nodes**: Provide control plane high availability
- ✅ **3 Worker nodes**: Provide compute resources
- ✅ **etcd cluster high availability**: 3-node distributed storage
- ✅ **NLB load balancing**: Automatically distribute requests to healthy master nodes
- ✅ **Network connectivity**: flannel provides pod network
- ✅ **Production ready**: Can deploy real applications


### 4.8 Verify NLB Load Balancing

Verify that NLB correctly distributes requests to multiple master nodes.

#### Step 1: Update kubeconfig to use NLB address

```bash
# Backup current configuration
cp ~/.kube/config ~/.kube/config.backup

# Update to NLB address
kubectl config set-cluster kubernetes --server=https://172.29.186.24:6443

# Verify update
kubectl config view --minify | grep server
# Should display: server: https://172.29.186.24:6443
```

#### Step 2: Test Connectivity

```bash
# Clear kubectl cache
rm -rf ~/.kube/cache ~/.kube/http-cache

# Test access
kubectl get nodes --request-timeout=60s
```

**Expected Result**: Should successfully list all nodes.

#### Step 3: Verify Load Distribution

Send multiple requests and observe if they are distributed to different master nodes:

```bash
# Send 20 requests
for i in {1..20}; do 
  echo "Request $i"
  kubectl get nodes > /dev/null 2>&1
  sleep 0.5
done
```

**Verification Methods**:
- Check monitoring in Alibaba Cloud NLB console, should see traffic distributed to 3 backends
- Or monitor apiserver logs on each master node

#### Step 4: Failover Test

```bash
# 1. Stop master02's kubelet (simulate failure)
ssh root@master02 'systemctl stop kubelet'

# 2. Wait 60 seconds for NLB health check to mark as unhealthy
sleep 60

# 3. Continue sending requests, should still succeed
for i in {1..10}; do 
  kubectl get nodes > /dev/null 2>&1 && echo "✓ Request $i success"
  sleep 1
done

# 4. Restore master02
ssh root@master02 'systemctl start kubelet'

# 5. Wait for recovery and verify
sleep 60
kubectl get nodes
```

**Expected Results**:
- ✅ During master02 failure, requests still succeed (through master01 and master03)
- ✅ After master02 recovers, automatically rejoins load balancing pool

#### Step 5: Verify in Alibaba Cloud Console

Log in to Alibaba Cloud NLB console and check:

1. **Backend Server Health Status**:
   - All 3 master nodes should show "healthy"
   - Health check pass rate close to 100%

2. **Monitoring Charts**:
   - View "New Connections"
   - View "Active Connections"
   - Should see traffic distributed to multiple backends

#### Troubleshooting

**Issue 1: Connection Timeout**

```bash
# Check if NLB port is reachable
nc -vz 172.29.186.24 6443

# Check apiserver status
kubectl get pods -n kube-system | grep apiserver
```

**Issue 2: Certificate Verification Failure**

```bash
# Check if all master node certificates contain both NLB VIPs
for master in master01 master02 master03; do
  echo "=== $master ==="
  ssh root@$master 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep "IP Address"'
  echo "Should contain: 172.29.186.24 and 172.16.32.76"
  echo ""
done
```

If a node's certificate doesn't contain both NLB VIPs, go back to section 4.4.1 to regenerate the certificate.

**Test both VIPs are accessible**:

```bash
# Test VIP 1
kubectl config set-cluster kubernetes --server=https://172.29.186.24:6443
kubectl get nodes

# Test VIP 2
kubectl config set-cluster kubernetes --server=https://172.16.32.76:6443
kubectl get nodes

# Both VIPs should be accessible normally
```

**Issue 3: All requests go to one node**

Check NLB scheduling algorithm:
- In Alibaba Cloud console: NLB → Listener → Advanced Configuration → Scheduling Algorithm
- Should be "Weighted Round Robin (WRR)" or "Weighted Least Connections (WLC)"

## 5. Create Karmada Multi-Cluster


Karmada is Kubernetes' cross-cluster management solution. It can manage multiple Kubernetes clusters as a whole, enabling cross-cluster resource scheduling, load balancing, failover and other functions.


The best way to install Karmada is through CLI, and Karmada has two types of CLI:
- karmadactl: Standalone CLI tool, designed specifically for Karmada
- kubectl-karmada: kubectl plugin that extends kubectl functionality

The community more commonly uses karmadactl, but since this article is mainly based on Kubernetes cluster management, and readers are more inclined to users familiar with kubectl workflows, we choose to use kubectl-karmada for installation.

kubectl-karmada, as a kubectl plugin, is generally installed through krew, which is kubectl's plugin manager.

Since krew installation requires connecting to GitHub, and Alibaba Cloud ECS often times out when connecting to GitHub, we directly download the krew installation package from GitHub and execute the installation. The installation commands are as follows:


```bash
# Download krew locally then scp to specific master node (scp step omitted)
 curl -fsSLO "https://github.91chi.fun/https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
# Install krew
( set -x; cd "$(mktemp -d)" &&   OS="$(uname | tr '[:upper:]' '[:lower:]')" &&   ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&   KREW="krew-${OS}_${ARCH}" &&   tar zxvf "${KREW}.tar.gz" &&   ./"${KREW}" install krew; )
# Install kubectl-karmada
kubectl krew install --manifest=plugin.yaml --archive=/tmp/kubectl-karmada-linux-amd64.tgz
```

After installing kubectl-karmada, Karmada installation is similar to kubeadm initialization command, as follows:

```bash
kubectl karmada init --kube-image-registry=registry.cn-hangzhou.aliyuncs.com/google_containers --karmada-apiserver-replicas 3 --etcd-replicas 3 --etcd-storage-mode PVC --storage-classes-name local-path
```

This command can install a highly available Karmada control plane on a highly available Kubernetes cluster. After installation, you will see the following output:

```bash
------------------------------------------------------------------------------------------------------
 █████   ████   █████████   ███████████   ██████   ██████   █████████   ██████████     █████████
░░███   ███░   ███░░░░░███ ░░███░░░░░███ ░░██████ ██████   ███░░░░░███ ░░███░░░░███   ███░░░░░███
 ░███  ███    ░███    ░███  ░███    ░███  ░███░█████░███  ░███    ░███  ░███   ░░███ ░███    ░███
 ░███████     ░███████████  ░██████████   ░███░░███ ░███  ░███████████  ░███    ░███ ░███████████
 ░███░░███    ░███░░░░░███  ░███░░░░░███  ░███ ░░░  ░███  ░███░░░░░███  ░███    ░███ ░███░░░░░███
 ░███ ░░███   ░███    ░███  ░███    ░███  ░███      ░███  ░███    ░███  ░███    ███  ░███    ░███
 █████ ░░████ █████   █████ █████   █████ █████     █████ █████   █████ ██████████   █████   █████
░░░░░   ░░░░ ░░░░░   ░░░░░ ░░░░░   ░░░░░ ░░░░░     ░░░░░ ░░░░░   ░░░░░ ░░░░░░░░░░   ░░░░░   ░░░░░
------------------------------------------------------------------------------------------------------
Karmada is installed successfully.

Register Kubernetes cluster to Karmada control plane.

Register cluster with 'Push' mode

Step 1: Use "kubectl karmada join" command to register the cluster to Karmada control plane. --cluster-kubeconfig is kubeconfig of the member cluster.
(In karmada)~# MEMBER_CLUSTER_NAME=$(cat ~/.kube/config  | grep current-context | sed 's/: /\n/g'| sed '1d'| tr -d "\"'")
(In karmada)~# kubectl karmada --kubeconfig /etc/karmada/karmada-apiserver.config  join ${MEMBER_CLUSTER_NAME} --cluster-kubeconfig=$HOME/.kube/config

Step 2: Show members of karmada
(In karmada)~# kubectl --kubeconfig /etc/karmada/karmada-apiserver.config get clusters


Register cluster with 'Pull' mode

Step 1: Create bootstrap token and generate the 'kubectl karmada register' command which will be used later.
~# kubectl karmada token create --print-register-command --kubeconfig=/etc/karmada/karmada-apiserver.config
This command will generate a registration command similar to:

kubectl karmada register 172.18.0.5:5443 --token t8xfio.640u9gp9obc72v5d --discovery-token-ca-cert-hash sha256:9cfa542ff48f43793d1816b1dd0a78ad574e349d8f6e005e6e32e8ab528e4244

Step 2: Use the output from Step 1 to register the cluster to the Karmada control plane.
You need to specify the target member cluster by flag '--kubeconfig'
~# kubectl karmada register 172.18.0.5:5443 --token t8xfio.640u9gp9obc72v5d --discovery-token-ca-cert-hash sha256:9cfa542ff48f43793d1816b1dd0a78ad574e349d8f6e005e6e32e8ab528e4244 --kubeconfig=<path-to-member-cluster-kubeconfig>

Step 3: Show members of Karmada.
~# kubectl karmada --kubeconfig=/etc/karmada/karmada-apiserver.config get clusters

The kubectl karmada register command has several optional parameters for setting the properties of the member cluster. For more details, run:

~# kubectl karmada register --help
```

From the output, we can see that Karmada supports two modes for cluster registration: Push and Pull. Simply put, Push mode is more suitable for cluster registration in the same data center across different availability zones, while Pull mode is suitable for cross-data center or cross-cloud cluster registration. Push mode expects low latency, while Pull mode expects high availability.

After installation is complete, users can use `kubectl karmada get [po / service / deploy / job / etc]` to view Karmada resources. In addition to the regular kubectl output, there will also be a Cluster column indicating which cluster the resource belongs to.

```bash
# Get clusters
kubectl karmada --kubeconfig=/etc/karmada/karmada-apiserver.config get clusters
```





