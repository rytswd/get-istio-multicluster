## 📚 Setup Steps

<!-- == export: setup-steps / begin == -->

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

<!-- == export: setup-steps / end == -->

## ⚙️ Common Prerequisites

<!-- == export: common-prerequisites / begin == -->

- Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [KinD](https://kind.sigs.k8s.io/)
- [istioctl](https://istio.io/latest/docs/setup/install/istioctl/)

<!-- == export: common-prerequisites / end == -->
