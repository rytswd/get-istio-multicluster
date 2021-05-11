# Get Istio Multicluster

Istio Multicluster is by no means simple. There are many features Istio provides, and many moving pieces for the setup. This repository tries to showcase some of Istio's capability with the following in mind:

- Simple configurations
- Simple processes / containers
- Simple steps to reproduce

But as this repository aims to provide practical use cases, you will also find:

- Involved cluster / mesh setup
- Detailed description on each step

This should allow you to have a quick deep-dive into the Istio offerings. Many of the useful features are backed by real configurations that could be used with minor tweaks.

#### 📍 NOTE 📍

> This repository does not aim to be exhaustive by any means. The examples here set out the foundation for multicluster communication, and use some features such as fault injections. You are expected to be somewhat familiar with Istio's features.  
> Also, it is worth noting that most of the examples focus on traffic management features as of Oct 2020. You can find more in the [official documentation of Istio concepts](https://istio.io/latest/docs/concepts/).

## 🌅 Contents

### ⚙️ Prerequisites

For most of the setup, you will need the following tools installed:

<!-- == imptr: common-prerequisites / begin from: ./docs/snippets/common-info.md#[common-prerequisites] == -->

- Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [KinD](https://kind.sigs.k8s.io/)
- [istioctl](https://istio.io/latest/docs/setup/install/istioctl/)

<!-- == imptr: common-prerequisites / end == -->

### 📚 Setup Steps

<!-- == imptr: setup-steps / begin from: ./docs/snippets/common-info.md#[setup-steps] == -->

#### [Simple KinD based Setup][1]

**Description**: This setup is the easiest to follow, and takes imperative setup steps.

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | Istio Operator            | [KinD][kind]  |

**Additional Tools involved**: [MetalLB][metallb]

#### [Simple k3d based Setup][2]

**Description**: To be confirmed

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | TBC                       | [k3d]         |

**Additional Tools involved**: [MetalLB][metallb]

#### [Argo CD based GitOps Multicluster][3]

**Description**: Uses Argo CD to wire up all the necessary tools. This allows simple enough installation steps, while providing breadth of other tools useful to have alongside with Istio.

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | Manifest Generation       | [KinD][kind]  |

**Additional Tools involved**: [MetalLB][metallb], [Argo CD][argo-cd], [Prometheus][prometheus], [Grafana][grafana], [Kiali][kiali]

[1]: /docs/2-local-clusters/simple-with-istio-operator.md
[2]: /docs/k3d-based/README.md
[3]: /docs/2-local-clusters/argo-cd-with-generated-manifests.md
[kind]: https://kind.sigs.k8s.io/
[k3d]: https://k3d.io/
[metallb]: https://metallb.universe.tf/
[argo-cd]: https://argo-cd.readthedocs.io/en/latest/
[prometheus]: https://prometheus.io/
[grafana]: https://grafana.com/grafana/
[kiali]: https://kiali.io/

<!-- == imptr: setup-steps / end == -->

### 🌍 Clusters

The clusters used in this repository are given easily identifiable names. They don't convey any special meaning.

For some cluster, there are some peculiarities over the others.

- `armadillo`: cluster with shared Istio Control Plane (with `cougar`)
- `bison`: cluster with dedicated Istio Control Plane
- `cougar` ⚠️ WIP ⚠️: clustter with shared Istio Control Plane (with `armadillo`)
- `dolphin`: cluster with dedicated Istio Control Plane
- `zebra` ⚠️ WIP ⚠️: cluster without Istio, as external cluster
