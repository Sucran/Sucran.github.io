---
title: "租一台云主机玩 K3s + Volcano + Kthena 「安装篇」"
date: 2026-05-19T12:00:00+08:00
draft: false
description: "在 Ubuntu 单节点云主机上安装 K3s、Helm、Kthena 与 Volcano，搭建可用于推理与组调度测试的 Kubernetes 环境。"
---

## K3s + Helm + Kthena + Volcano 安装流程

本文主要是带领大家用晨涧云的云主机, 试着装一下 K3s + Volcano + Kthena, 并进行一些单机单集群的测试.

> 环境：CentOS9 Stream 单节点云主机（示例节点：`centos9-5268`，内网 IP `192.168.10.132`）  
> 目标：搭建可用于测试 [Kthena](https://kthena.volcano.sh/) 的单节点 Kubernetes，并安装 Volcano 以支持组调度等能力。

---

## 一、前置条件

| 项目 | 要求 |
|------|------|
| 系统 | Linux（本文以 CentOS9 Stream 为例） |
| 权限 | 具备 `sudo` |
| 网络 | 能访问国内镜像源；`docker.io` 直连较慢时需配置镜像加速 |
| 资源 | 建议 ≥ 4 CPU、8 GiB 内存（跑 LLM 示例需更高） |

---

## 二、安装 K3s（单节点）

国内环境建议使用 Rancher 中国镜像，并指定阿里云作为系统默认镜像仓库，避免 GitHub / Docker Hub 拉取超时。

```bash
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
  sudo INSTALL_K3S_MIRROR=cn K3S_KUBECONFIG_MODE="644" sh -s - \
  --system-default-registry=registry.cn-hangzhou.aliyuncs.com
```

### 配置 kubectl（非 root 用户）

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$(whoami):$(whoami)" ~/.kube/config
chmod 600 ~/.kube/config
```

### 验证

```bash
kubectl get nodes
kubectl get pods -A
```

预期：节点 `Ready`；`kube-system` 中 CoreDNS、metrics-server、local-path-provisioner 等为 `Running`。

### 卸载（如需）

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## 三、配置 Docker Hub 镜像加速（推荐）

Volcano、部分第三方镜像默认从 `docker.io` 拉取。在国内可在 K3s 中配置 registry mirror：

```bash
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/registries.yaml <<'EOF'
mirrors:
  docker.io:
    endpoint:
      - "https://docker.m.daocloud.io"
      - "https://docker.1panel.live"
EOF

sudo systemctl restart k3s
# 等待约 15 秒后验证
kubectl get nodes
```

> 安装 Kthena 若仅使用 `ghcr.io` 镜像，可不配此项；安装 Volcano 强烈建议配置。

---

## 四、安装 Helm 3

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

本文环境安装版本示例：**v3.21.0**。

---

## 五、安装 Kthena

### 方式：Helm OCI Chart（推荐）

```bash
helm install kthena oci://ghcr.io/volcano-sh/charts/kthena \
  --version v0.4.0 \
  --namespace kthena-system \
  --create-namespace
```

> 若加 `--wait --timeout 10m`，可能因 `kthena-router` 的 LoadBalancer 在云主机上长期 `pending` 导致 Helm 显示 `failed`，但 Pod 通常已正常运行，以 `kubectl get pods` 为准。

### 验证

```bash
kubectl get pods -n kthena-system
kubectl get crd | grep serving.volcano
helm list -n kthena-system
```

预期组件：

| 组件 | 说明 |
|------|------|
| `kthena-controller-manager` | 控制面 |
| `kthena-router` | 推理流量入口（Service 类型常为 LoadBalancer） |

主要 CRD：`ModelBooster`、`ModelServing`、`ModelRoute`、`ModelServer`、`AutoScalingPolicy` 等。

### 访问 Router

```bash
kubectl get svc -n kthena-system kthena-router
```

- 集群内：ClusterIP
- 节点外：K3s 会为 LoadBalancer 分配 NodePort（示例：`80:30921/TCP` → `http://<节点IP>:30921`）

### 卸载

```bash
helm uninstall kthena -n kthena-system
```

---

## 六、安装 Volcano

### 添加 Helm 仓库

```bash
helm repo add volcano-sh https://volcano-sh.github.io/helm-charts
helm repo update
```

### 安装

若 `helm install` 从 GitHub 下载 chart 超时，可使用本地缓存 chart：

```bash
# 首次 repo update 后 chart 位于：
# ~/.cache/helm/repository/volcano-1.14.2.tgz

helm install volcano ~/.cache/helm/repository/volcano-1.14.2.tgz \
  -n volcano-system \
  --create-namespace \
  --timeout 15m
```

或网络正常时：

```bash
helm install volcano volcano-sh/volcano \
  -n volcano-system \
  --create-namespace
```

### 验证

```bash
kubectl get all -n volcano-system
helm list -n volcano-system
```

预期 Pod（均为 `Running`）：

- `volcano-admission`
- `volcano-controllers`
- `volcano-scheduler`

安装前会运行一次性 Job `volcano-admission-init`（完成后可忽略）。

### 卸载

```bash
helm uninstall volcano -n volcano-system
kubectl delete ns volcano-system
```

---

## 七、整体安装顺序小结

{{< mermaid >}}
flowchart TD
  A[安装 K3s] --> B[配置 ~/.kube/config]
  B --> C[可选: registries.yaml 加速 docker.io]
  C --> D[安装 Helm 3]
  D --> E[helm install Kthena]
  E --> F[helm install Volcano]
  F --> G[kubectl 验证各命名空间 Pod]
{{< /mermaid >}}

推荐顺序：

1. **K3s** → 2. **kubectl 配置** → 3. **Docker 镜像加速（Volcano 前）** → 4. **Helm** → 5. **Kthena** → 6. **Volcano**

---

## 八、常用运维命令

```bash
# 集群
kubectl get nodes -o wide
kubectl get pods -A

# Kthena
kubectl get pods,svc -n kthena-system

# Volcano
kubectl get pods -n volcano-system
kubectl get queues.scheduling.volcano.sh

# Helm 发布
helm list -A
```

---

## 九、常见问题

| 现象 | 原因 | 处理 |
|------|------|------|
| K3s 安装卡在 GitHub 下载 | 国际网络慢 | 使用 `INSTALL_K3S_MIRROR=cn` + 国内 install 脚本 |
| Pod `ImagePullBackOff`（docker.io） | Docker Hub 超时 | 配置 `/etc/rancher/k3s/registries.yaml` 并重启 k3s |
| Helm 安装 Kthena 显示 `failed` | `--wait` 等待 LoadBalancer 超时 | 去掉 `--wait` 或忽略，检查 Pod 是否 Running |
| `kthena-router` EXTERNAL-IP `pending` | 单节点无云 LB | 使用 NodePort 或 `kubectl port-forward` |
| Volcano pre-install 超时 | admission-init 镜像拉取失败 | 先配置 docker.io 镜像加速后重装 |

---

## 十、当前环境版本参考

| 组件 | 版本 |
|------|------|
| K3s / Kubernetes | v1.35.4+k3s1 |
| Helm | v3.21.0 |
| Kthena | v0.4.0 |
| Volcano | v1.14.2（chart 1.14.2） |

---

## 参考链接

- [K3s 安装文档](https://docs.k3s.io/installation)
- [Kthena 安装指南](https://kthena.volcano.sh/docs/getting-started/installation)
- [Volcano 安装指南](https://volcano.sh/en/docs/installation/)
