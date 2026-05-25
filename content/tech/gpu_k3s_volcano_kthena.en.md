---
title: "Rent a Cloud VM for K3s + Volcano + Kthena — Installation Guide"
date: 2026-05-19T12:00:00+08:00
draft: false
description: "Install K3s, Helm, Kthena, and Volcano on a single-node cloud VM to build a Kubernetes environment for inference and gang-scheduling tests."
---

## K3s + Helm + Kthena + Volcano Installation

This post walks you through using a Chenjianyun cloud VM to install K3s, Volcano, and Kthena, and run some single-node, single-cluster tests.

> **Environment:** CentOS 9 Stream single-node cloud VM (example node: `centos9-5268`, internal IP `192.168.10.132`)  
> **Goal:** Set up a single-node Kubernetes cluster for testing [Kthena](https://kthena.volcano.sh/), and install Volcano for gang scheduling and related capabilities.

---

## 1. Prerequisites

| Item | Requirement |
|------|-------------|
| OS | Linux (this guide uses CentOS 9 Stream as an example) |
| Privileges | `sudo` access |
| Network | Reachable domestic mirror sources; configure registry mirrors if `docker.io` is slow |
| Resources | ≥ 4 CPU, 8 GiB RAM recommended (LLM examples need more) |

---

## 2. Install K3s (Single Node)

In China, use the Rancher China mirror and set Alibaba Cloud as the default system registry to avoid GitHub / Docker Hub timeouts.

```bash
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
  sudo INSTALL_K3S_MIRROR=cn K3S_KUBECONFIG_MODE="644" sh -s - \
  --system-default-registry=registry.cn-hangzhou.aliyuncs.com
```

### Configure kubectl (non-root user)

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$(whoami):$(whoami)" ~/.kube/config
chmod 600 ~/.kube/config
```

### Verify

```bash
kubectl get nodes
kubectl get pods -A
```

**Expected:** Node status `Ready`; CoreDNS, metrics-server, local-path-provisioner, etc. in `kube-system` are `Running`.

### Uninstall (if needed)

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## 3. Configure Docker Hub Mirror (Recommended)

Volcano and some third-party images pull from `docker.io` by default. In China, configure a registry mirror in K3s:

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
# Wait ~15 seconds, then verify
kubectl get nodes
```

> If Kthena only uses `ghcr.io` images, this step is optional; for Volcano, configuring a mirror is strongly recommended.

---

## 4. Install Helm 3

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

Example version in this environment: **v3.21.0**.

---

## 5. Install Kthena

### Method: Helm OCI Chart (Recommended)

```bash
helm install kthena oci://ghcr.io/volcano-sh/charts/kthena \
  --version v0.4.0 \
  --namespace kthena-system \
  --create-namespace
```

> If you add `--wait --timeout 10m`, Helm may report `failed` because `kthena-router` LoadBalancer stays `pending` on a bare cloud VM—but Pods are usually already running. Trust `kubectl get pods`.

### Verify

```bash
kubectl get pods -n kthena-system
kubectl get crd | grep serving.volcano
helm list -n kthena-system
```

**Expected components:**

| Component | Description |
|-----------|-------------|
| `kthena-controller-manager` | Control plane |
| `kthena-router` | Inference traffic entry (Service type is often LoadBalancer) |

Main CRDs: `ModelBooster`, `ModelServing`, `ModelRoute`, `ModelServer`, `AutoScalingPolicy`, etc.

### Access the Router

```bash
kubectl get svc -n kthena-system kthena-router
```

- In-cluster: ClusterIP
- From outside the node: K3s assigns a NodePort for LoadBalancer (example: `80:30921/TCP` → `http://<node-ip>:30921`)

### Uninstall

```bash
helm uninstall kthena -n kthena-system
```

---

## 6. Install Volcano

### Add Helm repository

```bash
helm repo add volcano-sh https://volcano-sh.github.io/helm-charts
helm repo update
```

### Install

If `helm install` times out downloading the chart from GitHub, use the locally cached chart:

```bash
# After the first repo update, the chart is at:
# ~/.cache/helm/repository/volcano-1.14.2.tgz

helm install volcano ~/.cache/helm/repository/volcano-1.14.2.tgz \
  -n volcano-system \
  --create-namespace \
  --timeout 15m
```

Or when the network is fine:

```bash
helm install volcano volcano-sh/volcano \
  -n volcano-system \
  --create-namespace
```

### Verify

```bash
kubectl get all -n volcano-system
helm list -n volcano-system
```

**Expected Pods (all `Running`):**

- `volcano-admission`
- `volcano-controllers`
- `volcano-scheduler`

A one-off Job `volcano-admission-init` runs before install (can be ignored after completion).

### Uninstall

```bash
helm uninstall volcano -n volcano-system
kubectl delete ns volcano-system
```

---

## 7. Installation Order Summary

{{< mermaid >}}
flowchart TD
  A[Install K3s] --> B[Configure ~/.kube/config]
  B --> C[Optional: registries.yaml for docker.io]
  C --> D[Install Helm 3]
  D --> E[helm install Kthena]
  E --> F[helm install Volcano]
  F --> G[kubectl verify Pods in each namespace]
{{< /mermaid >}}

Recommended order:

1. **K3s** → 2. **kubectl config** → 3. **Docker mirror (before Volcano)** → 4. **Helm** → 5. **Kthena** → 6. **Volcano**

---

## 8. Common Operations

```bash
# Cluster
kubectl get nodes -o wide
kubectl get pods -A

# Kthena
kubectl get pods,svc -n kthena-system

# Volcano
kubectl get pods -n volcano-system
kubectl get queues.scheduling.volcano.sh

# Helm releases
helm list -A
```

---

## 9. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| K3s install stuck on GitHub download | Slow international network | Use `INSTALL_K3S_MIRROR=cn` and the China install script |
| Pod `ImagePullBackOff` (docker.io) | Docker Hub timeout | Configure `/etc/rancher/k3s/registries.yaml` and restart k3s |
| Helm reports Kthena install `failed` | `--wait` timed out on LoadBalancer | Drop `--wait` or ignore; check Pods are Running |
| `kthena-router` EXTERNAL-IP `pending` | No cloud LB on single node | Use NodePort or `kubectl port-forward` |
| Volcano pre-install timeout | admission-init image pull failed | Configure docker.io mirror, then reinstall |

---

## 10. Version Reference (This Environment)

| Component | Version |
|-----------|---------|
| K3s / Kubernetes | v1.35.4+k3s1 |
| Helm | v3.21.0 |
| Kthena | v0.4.0 |
| Volcano | v1.14.2 (chart 1.14.2) |

---

## References

- [K3s installation](https://docs.k3s.io/installation)
- [Kthena installation guide](https://kthena.volcano.sh/docs/getting-started/installation)
- [Volcano installation guide](https://volcano.sh/en/docs/installation/)
