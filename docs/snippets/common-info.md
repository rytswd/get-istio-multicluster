## 📚 Setup Steps

<!-- == export: setup-steps / begin == -->

| Step               | # of Clusters | Istio Setup         | Cluster Setup | Tools Involved                               | Description |
| ------------------ | ------------- | ------------------- | ------------- | -------------------------------------------- | ----------- |
| [KinD based][1]    | 2             | Istio Operator      | 2x KinD       | MetalLB                                      | TBD         |
| [k3d based][2]     | 2             |                     | 2x k3d        | TBC                                          | TBD         |
| [Argo CD based][3] | 2             | Manifest Generation | 2x KinD       | MetalLB, Argo CD, Prometheus, Grafana, Kiali | TBD         |

[1]: https://github.com/rytswd/get-istio-multicluster/blob/main/docs/2-local-clusters/simple-with-istio-operator.md
[2]: https://github.com/rytswd/get-istio-multicluster/tree/main/docs/k3d-based/README.md
[3]: https://github.com/rytswd/get-istio-multicluster/blob/main/docs/2-local-clusters/argo-cd-without-istio-operator.md

<!-- == export: setup-steps / end == -->

## Common Prerequisites

<!-- == export: common-prerequisites / begin == -->

- Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [KinD](https://kind.sigs.k8s.io/)
- [istioctl](https://istio.io/latest/docs/setup/install/istioctl/)

<!-- == export: common-prerequisites / end == -->
