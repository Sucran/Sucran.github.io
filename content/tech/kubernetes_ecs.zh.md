---
title: "从搭建 K8s 小集群到 Karmada 跨集群的阿里云 ECS 无痛路线"
date: 2025-10-28T10:54:12+08:00
draft: false
description: ""
---

本文主要是带领读者使用阿里云 ECS 搭建 K8s 集群，并进行相关的配置和使用, 搭建 K8s 集群时使用 Kubeadm 进行搭建, 本教程会涉及阿里云 ECS 镜像的使用, 这样能让读者快速创建集群节点.

本文说的 5 分钟是基于用户已经构建了初始软件镜像, 进行集群搭建的过程.

## 1. 创建 ECS 实例

首先, 读者需要登陆阿里云, 进入控制台, 点击 云服务器 ECS 

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-07-04.png)

然后点击创建实例, 建议读者在初次尝试时仅开通抢占式实例, 成本较低, 并且抢占式实例的资源可以随时释放, 不会产生额外的费用.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-09-19.png)

抢占式实例如果默认选择直接释放的话, 可能用户会来不及制作镜像, 建议选择节省停机. 

另外, 我们下列所有操作都是基于 Ubuntu 22.04 的公共镜像进行操作的, 如果切换其他系统, 安装软件的版本可能有所不同.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-11-23.png)

由于阿里云的固定带宽费用比较高, 并且我们希望软件安装速率更快一些, 所以选择按使用流量付费. 

另外, 建议用户使用密钥对进行登陆, 这样能避免密码泄露的风险也方便后续操作.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-12-52.png)

接下来, 我们点击创建实例, 等待实例创建完成.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-16-50-33.png)

通过使用密钥对登陆, 则需要使用密钥对的文件路径.

```bash
ssh -i ~/.ssh/your_key_pair_file root@<公网IP>
```

## 2. 安装必要软件并制作镜像

### pre-step 配置内核参数

在安装必要软件之前, 我们需要先配置内核参数, 否则在安装过程中会遇到一些问题.

```bash
# 禁用 swap
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab
# 内核模块
sudo tee /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
EOF
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```

### 2.1 安装 Docker

在阿里云 ECS 的文档 [安装和使用 Docker](https://help.aliyun.com/zh/ecs/user-guide/install-and-use-docker?spm=a2c4g.11174283.help-menu-25365.d_0_10_5_6.13131db82h5a7C#8dca4cfa3dn0e) 中有具体的 Docker 和 Docker Compoase 安装步骤:

```bash 
#更新包管理工具
sudo apt-get update
#添加Docker软件包源
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
sudo curl -fsSL http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=$(dpkg --print-architecture)] http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
#安装Docker社区版本，容器运行时containerd.io，以及Docker构建和Compose插件
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

安装完成后启动设置 Docker 服务启动并开机自启:

```bash
#启动Docker
sudo systemctl start docker
#设置Docker守护进程在系统启动时自动启动
sudo systemctl enable docker
```

最后, 我们验证 Docker 安装是否成功:

```bash
#验证Docker安装
docker version
```

如果安装成功, 你会看到类似以下的输出:

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
  API version:      1.51 (minimum version 1.24)
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

由于 Kubernetes 与 Docker 默认的 cgroup（资源控制组）驱动程序并不一致，Kubernetes 默认为systemd，而 Docker 默认为cgroupfs。

因此, 我们需要修改 Docker 的 cgroup 驱动程序为 systemd. 并且由于运营商网络原因，从Docker Hub拉取镜像会失败。配置镜像加速器可解决该问题。


编辑 `/etc/docker/daemon.json` 文件, 添加以下内容:

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



### 2.2 安装 Kubeadm

这个过程直接参照Kubernetes 官网的文档 [安装Kubeadm](https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

```bash
# 1. 安装使用 Kubernetes apt 仓库所需要的包：
# apt-transport-https 可能是一个虚拟包（dummy package）；如果是的话，你可以跳过安装这个包
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# 2. 下载 Kubernetes 的 GPG 密钥：
# 如果 `/etc/apt/keyrings` 目录不存在，则应在 curl 命令之前创建它，请阅读下面的注释。
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 3. 添加 Kubernetes apt 仓库：
# 此操作会覆盖 /etc/apt/sources.list.d/kubernetes.list 中现存的所有配置。
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 4. 安装 kubelet、kubeadm 和 kubectl：
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# 5. 标记 kubelet、kubeadm 和 kubectl 为 hold 状态，以防止其被系统自动更新：
sudo apt-mark hold kubelet kubeadm kubectl
```

### 2.3 安装 cri-dockerd

Kubernetes 使用 Docker 作为容器运行时, 但是 Docker 已经不再维护, 所以需要使用 cri-dockerd 作为容器运行时.

```bash
# 下载 cri-dockerd 的 deb 包
wget https://ghproxy.net/https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.debian-bookworm_amd64.deb

# 安装 cri-dockerd
sudo dpkg -i cri-dockerd_0.3.20.3-0.debian-bookworm_amd64.deb
```

### 2.4 提前拉取集群镜像

```bash
kubeadm config images pull \
  --image-repository registry.aliyuncs.com/google_containers \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

批量更新镜像的tag:
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

# 批量打 tag
for img in "${!tagMap[@]}"; do
  docker tag registry.aliyuncs.com/google_containers/${img}:${tagMap[$img]} \
     registry.k8s.io/${img}:${tagMap[$img]}
done

# 为 pause 镜像额外添加 3.10 标签
docker tag registry.aliyuncs.com/google_containers/pause:3.10.1 registry.k8s.io/pause:3.10
docker tag registry.aliyuncs.com/google_containers/pause:3.10.1 registry.aliyuncs.com/google_containers/pause:3.10
```

最后能够看到镜像列表:

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


### 2.5 制作镜像

上述步骤已经将必要的软件和镜像拉取到本地了, 接着我们只需要将实例制作成 ECS 的自定义镜像, 然后就能够进行快速的节点创建和集群搭建.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-18-18-27.png)

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-18-07-28.png)

点击创建好镜像后, 查看镜像列表:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-28-18-19-11.png)

## 3. 创建 K8s 三节点集群

### 3.1 根据镜像创建多节点实例

首先, 我们需要创建一个 Kubernetes 集群, 然后使用我们之前制作的镜像进行初始化. 一共是 3 个节点, 1 个 Master 节点, 2 个 Worker 节点.

根据从阿里云控制台获取的信息, 创建的 3 台机器信息如下:

- **k8s-master01**: 公网 IP `120.25.48.211`, 私网 IP `172.29.186.7`
- **k8s-worker01**: 公网 IP `47.112.215.1`, 私网 IP `172.29.186.13`
- **k8s-worker02**: 公网 IP `47.112.220.167`, 私网 IP `172.29.186.14`

#### 配置主机免密登录

为了方便后续的集群部署, 我们需要配置三台机器之间的 SSH 免密登录, 并配置 `/etc/hosts` 以便使用主机名访问.

**步骤 1: 在每台机器上生成 SSH 密钥对**

在 master 节点执行:

```bash
ssh -i ~/.ssh/sucran.pem root@120.25.48.211
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' -C 'k8s-cluster'
```

在 worker01 节点执行:

```bash
ssh -i ~/.ssh/sucran.pem root@47.112.215.1
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' -C 'k8s-cluster'
```

在 worker02 节点执行:

```bash
ssh -i ~/.ssh/sucran.pem root@47.112.220.167
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' -C 'k8s-cluster'
```

**步骤 2: 配置 /etc/hosts**

在所有三台机器上配置 hosts 文件, 添加以下内容:

```bash
echo '172.29.186.7 k8s-master01
172.29.186.13 k8s-worker01
172.29.186.14 k8s-worker02' >> /etc/hosts
```

**步骤 3: 收集所有节点的公钥并分发**

获取每台机器的公钥:

```bash
# 在 master 节点
cat ~/.ssh/id_rsa.pub

# 在 worker01 节点  
cat ~/.ssh/id_rsa.pub

# 在 worker02 节点
cat ~/.ssh/id_rsa.pub
```

将三个节点的公钥都添加到每台机器的 `~/.ssh/authorized_keys` 文件中.

**步骤 4: 配置 SSH 参数**

为了避免 SSH 连接时的交互式确认, 在所有节点配置 SSH config:

```bash
cat > ~/.ssh/config << 'EOF'
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
```

**步骤 5: 验证免密登录**

从 master 节点测试免密登录:

```bash
ssh root@k8s-worker01 'hostname && pwd'
ssh root@k8s-worker02 'hostname && pwd'
```

如果能够无密码登录, 说明配置成功.

> **注意**: 首次连接到新主机时可能会看到 `Warning: Permanently added ...` 的提示, 这是 SSH 的正常行为. 该警告只会在第一次出现, 之后的连接不会再显示.


### 3.2 初始化 Master 节点

在 master 节点执行:

```bash
kubeadm init \
  --apiserver-advertise-address=172.29.186.7 \
  --apiserver-bind-port=6443 \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --image-repository registry.aliyuncs.com/google_containers \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

完成后能看到类似输出:

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

**常见问题排查：初始化卡住**

如果 kubeadm init 卡在检查控制平面组件健康状态, 通常是因为缺少 `pause:3.10` 镜像. 排查步骤:

1. **检查 kubelet 日志**:
```bash
journalctl -u kubelet -n 50 | grep -i 'error\|failed'
```

2. **检查容器镜像**:
```bash
docker images | grep pause
```

如果只有 `pause:3.10.1` 而没有 `pause:3.10`, 需要创建缺失的镜像 tag:
```bash
docker tag registry.k8s.io/pause:3.10.1 registry.k8s.io/pause:3.10
docker tag registry.aliyuncs.com/google_containers/pause:3.10.1 registry.aliyuncs.com/google_containers/pause:3.10
```

3. **重启 kubelet**:
```bash
systemctl restart kubelet
```

等待控制平面组件启动后, 会看到类似以下输出:


### 3.3 加入 Worker 节点

在每个worker 节点上执行 kubeadm join 命令, 加入集群:

```bash
kubeadm join 172.29.186.7:6443 \ --image-repository registry.aliyuncs.com/google_containers \ --cri-socket unix:///var/run/cri-dockerd.sock --token xxx \ --discovery-token-ca-cert-hash sha256:xxxx
```

完成后能看到类似输出:


```bash
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

### 3.4 配置 kubectl 并复制到 Worker 节点

在 master 节点配置 kubectl:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

验证 kubectl 配置:

```bash
export KUBECONFIG=$HOME/.kube/config
kubectl get nodes
```

将 kubeconfig 复制到 worker 节点:

```bash
# 复制到 worker01
cat $HOME/.kube/config | ssh root@k8s-worker01 "mkdir -p \$HOME/.kube && cat > \$HOME/.kube/config && chmod 600 \$HOME/.kube/config"

# 复制到 worker02
cat $HOME/.kube/config | ssh root@k8s-worker02 "mkdir -p \$HOME/.kube && cat > \$HOME/.kube/config && chmod 600 \$HOME/.kube/config"
```

### 3.5 安装网络插件

```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.22.0/Documentation/kube-flannel.yml
```

我们这里安装 flannel 网络插件, 也可以安装其他网络插件, 如 calico, canal, etc. 这个插件的安装依赖我们前面对内核参数的配置.

安装完成后, 就能够看到节点是 Ready 状态.

### 3.6 安装存储插件

在 master 节点拉取镜像并打 tag:

```bash
docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/rancher/local-path-provisioner:v0.0.32
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/rancher/local-path-provisioner:v0.0.32 \
        rancher/local-path-provisioner:v0.0.32
```

将镜像同步到所有 Worker 节点:

```bash
# 同步到 worker01
docker save rancher/local-path-provisioner:v0.0.32 | ssh root@k8s-worker01 "docker load"

# 同步到 worker02
docker save rancher/local-path-provisioner:v0.0.32 | ssh root@k8s-worker02 "docker load"
```

安装 local-path-provisioner:

```bash
export KUBECONFIG=$HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml
```

验证安装:

```bash
kubectl get pods -n local-path-storage
kubectl get storageclass
```

应该看到 Pod 运行并且 `local-path` 存储类已创建.


### 3.7 验证集群

```bash
kubectl get nodes
kubectl get pods -n kube-system
kubectl get pods -n local-path-storage
kubectl get storageclass
```

应该看到所有节点都处于 Ready 状态, 并且 `local-path` 存储类已创建.

## 4. 创建 K8s 高可用集群

第三章节就已经创建完成一个三节点集群, 接下来我们创建一个高可用集群, 一共是 6 个节点, 3 个 Master 节点, 3 个 Worker 节点. 创建高可用集群时我们不建议 Master 节点实例创建为抢占式实例, 而是建议使用按量付费的实例. 我们仍旧使用之前的镜像快速初始化节点, 然后通过 Kubeadm 来搭建高可用集群. 

需要注意的是, 三个 Master 节点需要配置负载均衡, 这里我们直接使用阿里云的 SLB(Server Load Balancer)中的 NLB(Network Load Balancer) 来搭建.

**高可用集群搭建流程总览**:

1. 创建 NLB 负载均衡器，配置后端服务器组（1 个 Master 节点）
2. 使用第一个 master 节点的 IP 初始化第一个 master 节点
3. **重新生成包含 NLB 地址的 apiserver 证书**（关键步骤）
4. 更新 control-plane-endpoint 为 NLB 地址
5. 安装网络插件
6. 生成 join token 和证书密钥
7. 其他 master 节点加入集群
8. Worker 节点加入集群

**特别注意**: 步骤 3 是关键步骤，如果跳过这一步，其他 master 节点将无法通过 NLB 地址加入集群。

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-29-12-49-04.png)

创建好负载均衡后, 我们就可以在负载均衡后添加三个 Master 节点实例. 

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-29-12-53-00.png)

创建负载均衡 NLB, 详情如下:

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-29-13-17-52.png)

然后配置 服务器组, 对应 1 个 Master 节点实例, 这里对应等会要初始化的第一个节点.


健康检查的策略也是对应 6443 端口.

### 4.1 初始化第一个 Master 节点

在第一个 master 节点执行:

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

配置 kubectl:

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

安装网络插件:

```bash
export KUBECONFIG=$HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.22.0/Documentation/kube-flannel.yml
```

等待网络插件启动并验证节点状态:

```bash
kubectl get nodes
kubectl get pods -n kube-flannel
```

### 4.2 重新生成包含 NLB 地址的 apiserver 证书

**这一步非常关键！** 默认生成的 apiserver 证书只包含当前节点的 IP 地址，不包含 NLB 地址。如果不重新生成证书，其他 master 节点将无法通过 NLB 地址加入集群，会报错：

```bash
error: tls: failed to verify certificate: x509: certificate is valid for 10.96.0.1, 172.29.186.15, not 172.29.186.24
```

重新生成证书的步骤：

```bash
# 备份旧证书
mv /etc/kubernetes/pki/apiserver.{crt,key} /tmp/

# 重新生成包含 NLB 地址的证书
# NLB 有两个 VIP：172.29.186.24 和 172.16.32.76，都需要添加
kubeadm init phase certs apiserver \
  --apiserver-advertise-address=172.29.186.15 \
  --apiserver-cert-extra-sans=172.29.186.24,172.16.32.76

# 重启 apiserver 使新证书生效
# 方法1：删除 manifest 文件让 kubelet 自动重建（推荐）
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sleep 10

# 方法2：使用 crictl 停止容器（kubelet 会自动重启）
# crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock ps | grep kube-apiserver | awk '{print $1}' | xargs crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock stop
# sleep 10
```

验证证书是否包含 NLB 地址:

```bash
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 10 "Subject Alternative Name"
```

应该看到输出中包含 NLB 地址 `172.29.186.24`。

### 4.3 更新 control-plane-endpoint 为 NLB 地址

更新 control-plane-endpoint 为 NLB 地址:

```bash
# 备份当前配置
cp /etc/kubernetes/kubeadm-config.yaml /etc/kubernetes/kubeadm-config.yaml.backup

# 更新 control-plane-endpoint
kubectl -n kube-system get configmap kubeadm-config -o yaml > /tmp/kubeadm-config.yaml
sed -i 's/172.29.186.15:6443/172.29.186.24:6443/g' /tmp/kubeadm-config.yaml
kubectl -n kube-system apply -f /tmp/kubeadm-config.yaml

# 重启所有 master 节点
systemctl restart kubelet
```

**注意**: 更新 control-plane-endpoint 后，所有 master 节点都需要重启 kubelet 服务。

### 4.4 添加其他 Master 节点

在第一个 master 节点上生成 join 命令和证书密钥:

```bash
# 生成新的 join token
kubeadm token create --ttl 0 --print-join-command

# 上传证书到集群，生成证书密钥（有效期 2 小时）
kubeadm init phase upload-certs --upload-certs
```

记录输出的证书密钥（certificate-key），例如：
```
f999ee3f81acb01b16d164fca40bbf78270a14dc9cae962a4f77fa8862fa4767
```

在其他 master 节点上执行 join 命令:

```bash
kubeadm join 172.29.186.15:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key> \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

**注意事项**:
- `--certificate-key` 参数必须添加，用于下载控制平面证书
- 证书密钥有效期为 2 小时，过期后需要重新生成
- 加入成功后，记得配置 kubectl：

```bash
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

验证所有 master 节点状态:

```bash
kubectl get nodes
```

应该看到所有 master 节点都处于 Ready 状态。

### 4.4.1 为所有 Master 节点更新证书（关键步骤）

**重要**：新加入的 master 节点（master02、master03）的 apiserver 证书**不包含 NLB 地址**，必须重新生成证书。

这是因为 `kubeadm join` 使用的是 master01 的 IP 地址（172.29.186.15），生成的证书只包含：
- 节点自己的 IP
- join 命令中的地址（172.29.186.15）
- **不包含 NLB 的 VIP 地址**

**NLB 的 VIP 说明**：
- 阿里云 NLB 通常有**两个 VIP**（虚拟IP）用于高可用
- 本例中：`172.29.186.24` 和 `172.16.32.76`
- **必须将两个 VIP 都添加到证书中**，防止单个 VIP 故障时无法切换

如果不更新证书，通过 NLB 访问时会报错：
```bash
tls: failed to verify certificate: x509: certificate is valid for ... not 172.29.186.24
```

**在 master02 上更新证书**：

```bash
# SSH 到 master02
ssh root@master02

# 备份旧证书
mv /etc/kubernetes/pki/apiserver.{crt,key} /tmp/

# 重新生成包含 NLB 地址的证书
# NLB 有两个 VIP：172.29.186.24 和 172.16.32.76，都需要添加
kubeadm init phase certs apiserver \
  --apiserver-advertise-address=172.16.32.80 \
  --apiserver-cert-extra-sans=172.29.186.24,172.16.32.76,172.29.186.15

# 重启 apiserver
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sleep 10
```

**在 master03 上更新证书**：

```bash
# SSH 到 master03
ssh root@master03

# 备份旧证书
mv /etc/kubernetes/pki/apiserver.{crt,key} /tmp/

# 重新生成包含 NLB 地址的证书
# NLB 有两个 VIP：172.29.186.24 和 172.16.32.76，都需要添加
kubeadm init phase certs apiserver \
  --apiserver-advertise-address=172.16.32.79 \
  --apiserver-cert-extra-sans=172.29.186.24,172.16.32.76,172.29.186.15

# 重启 apiserver
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sleep 10
```

**验证所有证书都包含 NLB 的两个 VIP**：

```bash
# 在 master01 上验证
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Subject Alternative Name"
# 应该看到：IP Address:172.29.186.24 和 IP Address:172.16.32.76

# 在 master02 上验证
ssh root@master02 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Subject Alternative Name"'
# 应该看到：IP Address:172.29.186.24 和 IP Address:172.16.32.76

# 在 master03 上验证
ssh root@master03 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Subject Alternative Name"'
# 应该看到：IP Address:172.29.186.24 和 IP Address:172.16.32.76

# 或者更详细的检查
for master in master01 master02 master03; do
  echo "=== $master ==="
  ssh root@$master 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep "IP Address"'
done
```

所有节点的证书都应该包含以下 IP：
- `10.96.0.1` (Kubernetes service IP)
- 节点自己的 IP
- `172.29.186.15` (master01 IP)
- `172.29.186.24` (NLB VIP 1) ⭐ 关键
- `172.16.32.76` (NLB VIP 2) ⭐ 关键

### 4.5 扩展 NLB 的服务器组

由于先前配置时需要确保 NLB 的健康检查正常, 所以只配置了 master01 节点, 所有 Master 节点初始化完成后, 需要扩展 NLB 的服务器组, 改成 3 个 Master 节点实例.

在阿里云控制台中, 扩展 NLB 的服务器组, 改成 3 个 Master 节点实例.

![](https://congo-blog.oss-cn-beijing.aliyuncs.com/blog-images/tech/2025-10-29-14-50-13.png)

如此一来, 就能够确保所有 Master 节点的负载均衡.


### 4.6 添加 Worker 节点

Worker 节点的加入比 master 节点简单，不需要 `--control-plane` 和 `--certificate-key` 参数。

在第一个 master 节点上生成 join 命令（如果之前的 token 还有效，可以跳过这一步）：

```bash
kubeadm token create --ttl 0 --print-join-command
```

输出示例：
```bash
kubeadm join 172.29.186.15:6443 --token e7xp39.kox3g4jq97nbv1nu --discovery-token-ca-cert-hash sha256:557cda54ed4467576fd88677fc0ade60a56f0291a7cb0c8078484fd419acf515
```

在 worker 节点上执行 join 命令：

```bash
kubeadm join 172.29.186.15:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

**注意**：Worker 节点不需要 `--control-plane` 和 `--certificate-key` 参数。

验证 worker 节点加入：

```bash
kubectl get nodes
```

应该看到类似输出：
```bash
NAME                      STATUS   ROLES           AGE   VERSION
izwz9b786esx09okwzr8azz   Ready    control-plane   21m   v1.34.1
izwz9b786esx09okwzr8b0z   Ready    control-plane   13m   v1.34.1
izwz9b786esx09okwzr8b1z   Ready    control-plane   11m   v1.34.1
izwz95hnhy94jc97w13e6qz   Ready    <none>          3m    v1.34.1
izwz95hnhy94jc97w13e6pz   Ready    <none>          75s   v1.34.1
izwz95hnhy94jc97w13e6oz   Ready    <none>          63s   v1.34.1
```

### 4.7 验证高可用集群

查看完整的集群状态：

```bash
kubectl get nodes -o wide
```

输出示例：
```bash
NAME                      STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
izwz9b786esx09okwzr8azz   Ready    control-plane   21m   v1.34.1   172.29.186.15   <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz9b786esx09okwzr8b0z   Ready    control-plane   13m   v1.34.1   172.16.32.80    <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz9b786esx09okwzr8b1z   Ready    control-plane   11m   v1.34.1   172.16.32.79    <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz95hnhy94jc97w13e6qz   Ready    <none>          3m    v1.34.1   172.29.186.19   <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz95hnhy94jc97w13e6pz   Ready    <none>          75s   v1.34.1   172.29.186.20   <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
izwz95hnhy94jc97w13e6oz   Ready    <none>          63s   v1.34.1   172.29.186.18   <none>        Ubuntu 22.04.5 LTS   5.15.0-153-generic   docker://28.5.1
```

验证所有组件运行状态：

```bash
kubectl get pods -A
```

关键组件验证：

```bash
# 验证 etcd 集群（3 个实例）
kubectl get pods -n kube-system | grep etcd

# 验证 apiserver（3 个实例）
kubectl get pods -n kube-system | grep apiserver

# 验证 controller-manager（3 个实例）
kubectl get pods -n kube-system | grep controller-manager

# 验证 scheduler（3 个实例）
kubectl get pods -n kube-system | grep scheduler

# 验证网络插件（每个节点一个）
kubectl get pods -n kube-flannel
```

测试部署应用：

```bash
# 创建测试 deployment
kubectl create deployment nginx --image=nginx --replicas=3

# 查看 pod 分布
kubectl get pods -o wide

# 验证 pod 运行正常
kubectl get deployment nginx

# 清理测试资源
kubectl delete deployment nginx
```

至此，高可用 Kubernetes 集群搭建完成！集群具备以下特性：

- ✅ **3 个 Master 节点**：提供控制平面高可用
- ✅ **3 个 Worker 节点**：提供计算资源
- ✅ **etcd 集群高可用**：3 节点分布式存储
- ✅ **NLB 负载均衡**：自动分发请求到健康的 master 节点
- ✅ **网络互通**：flannel 提供 pod 网络
- ✅ **生产就绪**：可以部署实际应用


### 4.8 验证 NLB 负载均衡

验证 NLB 是否正确将请求分发到多个 master 节点。

#### 步骤 1：更新 kubeconfig 使用 NLB 地址

```bash
# 备份当前配置
cp ~/.kube/config ~/.kube/config.backup

# 更新为 NLB 地址
kubectl config set-cluster kubernetes --server=https://172.29.186.24:6443

# 验证更新
kubectl config view --minify | grep server
# 应该显示：server: https://172.29.186.24:6443
```

#### 步骤 2：测试连通性

```bash
# 清理 kubectl 缓存
rm -rf ~/.kube/cache ~/.kube/http-cache

# 测试访问
kubectl get nodes --request-timeout=60s
```

**预期结果**：应该成功列出所有节点。

#### 步骤 3：验证负载分发

发送多个请求，观察是否分发到不同的 master 节点：

```bash
# 发送 20 个请求
for i in {1..20}; do 
  echo "Request $i"
  kubectl get nodes > /dev/null 2>&1
  sleep 0.5
done
```

**验证方法**：
- 在阿里云 NLB 控制台查看监控，应该看到流量分发到 3 个后端
- 或者在每个 master 节点上监控 apiserver 日志

#### 步骤 4：故障切换测试

```bash
# 1. 停止 master02 的 kubelet（模拟故障）
ssh root@master02 'systemctl stop kubelet'

# 2. 等待 60 秒让 NLB 健康检查标记为不健康
sleep 60

# 3. 继续发送请求，应该仍然成功
for i in {1..10}; do 
  kubectl get nodes > /dev/null 2>&1 && echo "✓ Request $i success"
  sleep 1
done

# 4. 恢复 master02
ssh root@master02 'systemctl start kubelet'

# 5. 等待恢复并验证
sleep 60
kubectl get nodes
```

**预期结果**：
- ✅ master02 故障期间，请求仍然成功（通过 master01 和 master03）
- ✅ master02 恢复后，自动重新加入负载均衡池

#### 步骤 5：在阿里云控制台验证

登录阿里云 NLB 控制台，检查：

1. **后端服务器健康状态**：
   - 所有 3 个 master 节点应该显示"健康"
   - 健康检查通过率接近 100%

2. **监控图表**：
   - 查看"新建连接数"
   - 查看"活跃连接数"
   - 应该看到流量分发到多个后端

#### 常见问题排查

**问题 1：连接超时**

```bash
# 检查 NLB 端口是否可达
nc -vz 172.29.186.24 6443

# 检查 apiserver 状态
kubectl get pods -n kube-system | grep apiserver
```

**问题 2：证书验证失败**

```bash
# 检查所有 master 节点的证书是否包含 NLB 的两个 VIP
for master in master01 master02 master03; do
  echo "=== $master ==="
  ssh root@$master 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep "IP Address"'
  echo "应该包含：172.29.186.24 和 172.16.32.76"
  echo ""
done
```

如果某个节点证书不包含 NLB 的两个 VIP，回到 4.4.1 节重新生成证书。

**测试两个 VIP 都可访问**：

```bash
# 测试 VIP 1
kubectl config set-cluster kubernetes --server=https://172.29.186.24:6443
kubectl get nodes

# 测试 VIP 2
kubectl config set-cluster kubernetes --server=https://172.16.32.76:6443
kubectl get nodes

# 两个 VIP 都应该可以正常访问
```

**问题 3：所有请求只到一个节点**

检查 NLB 调度算法：
- 在阿里云控制台：NLB → 监听 → 高级配置 → 调度算法
- 应该是"加权轮询（WRR）"或"加权最小连接数（WLC）"

## 5. 创建 Karmada 多集群


Karmada 是 Kubernetes 的跨集群管理解决方案, 它能够将多个 Kubernetes 集群作为一个整体进行管理, 实现跨集群的资源调度、负载均衡、故障转移等功能.


安装 Karmada 的最佳方式是通过 CLI 进行安装, 而 Karmada 的 CLI 有两种:
- karmadactl：独立的 CLI 工具，专为 Karmada 设计
- kubectl-karmada：kubectl 插件，扩展 kubectl 功能

社区更普遍的使用 karmadactl, 但本文主要是基于 Kubernetes 集群的管理, 读者更偏向于熟悉 kubectl 工作流的用户. 因此, 我们选择使用 kubectl-karmada 进行安装.

kubectl-karmada 作为 kubectl 的插件, 一般是通过 krew 进行安装, krew 是 kubectl 的插件管理器.

由于 krew 安装需要连接 github, 阿里云的 ECS 对 github 连接时常超时. 所以, 我们直接从 github 下载 krew 的安装包, 并执行安装, 安装命令如下:


```bash
# 本地下载 krew 然后 scp 到 特定 master 节点 (scp步骤省略)
 curl -fsSLO "https://github.91chi.fun/https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
# 安装 krew
( set -x; cd "$(mktemp -d)" &&   OS="$(uname | tr '[:upper:]' '[:lower:]')" &&   ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&   KREW="krew-${OS}_${ARCH}" &&   tar zxvf "${KREW}.tar.gz" &&   ./"${KREW}" install krew; )
# 安装 kubectl-karmada
kubectl krew install --manifest=plugin.yaml --archive=/tmp/kubectl-karmada-linux-amd64.tgz
```

安装好 kubectl-karmada 之后, karmada 的安装也类似于 kubeadm 的初始化命令, 如下:

```bash
kubectl karmada init --kube-image-registry=registry.cn-hangzhou.aliyuncs.com/google_containers --karmada-apiserver-replicas 3 --etcd-replicas 3 --etcd-storage-mode PVC --storage-classes-name local-path
```

这个命令能够在高可用的 Kubernetes 集群上安装高可用的 Karmada 控制面. 安装完毕后你能看到如下输出:

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

从输出中可以看出, Karmada 支持 Push 和 Pull 两种模式进行集群注册, 简单来说, Push 模式更适合同一数据中心不同可用区的集群注册, 而 Pull 模式适合跨数据中心或跨云的集群注册. Push 模式期望低延迟, 而 Pull 模式期望高可用.

当完成安装之后, 用户就能够通过 `kubectl karmada get [po / service / deploy / job / etc]` 来查看 Karmada 的资源, 而对应常规的 kubectl 输出以外, 还会有一列 Cluster 表明该资源的所属集群.

```bash
# 获取集群
kubectl karmada --kubeconfig=/etc/karmada/karmada-apiserver.config get clusters
```








