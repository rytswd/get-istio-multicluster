## 📚 Setup Steps

<!-- == export: setup-steps / begin == -->

### [Simple KinD based Setup][1]

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | Istio Operator            | KinD          |

**Additional Tools involved**: MetalLB

**Description**: This setup is the easiest to follow, and takes imperative setup steps.

### [Simple k3d based Setup][2]

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | TBC                       | k3d           |

**Additional Tools involved**: MetalLB

**Description**: To be confirmed

### [Argo CD based GitOps Multicluster][3]

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | Manifest Generation       | k3d           |

**Additional Tools involved**: MetalLB, Argo CD, Prometheus, Grafana, Kiali

**Description**: Uses Argo CD to wire up all the necessary tools. This allows simple enough installation steps, while providing breadth of other tools useful to have alongside with Istio.

[1]: https://github.com/rytswd/get-istio-multicluster/blob/main/docs/2-local-clusters/simple-with-istio-operator.md
[2]: https://github.com/rytswd/get-istio-multicluster/tree/main/docs/k3d-based/README.md
[3]: https://github.com/rytswd/get-istio-multicluster/blob/main/docs/2-local-clusters/argo-cd-without-istio-operator.md

<!-- == export: setup-steps / end == -->

## ⚙️ Common Prerequisites

<!-- == export: common-prerequisites / begin == -->

- Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [KinD](https://kind.sigs.k8s.io/)
- [istioctl](https://istio.io/latest/docs/setup/install/istioctl/)

<!-- == export: common-prerequisites / end == -->
