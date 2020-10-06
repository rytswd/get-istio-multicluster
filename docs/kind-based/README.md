# KinD based setup

## Prerequisites

- Docker
- [KinD](https://kind.sigs.k8s.io/)

## Steps

### 1. Start local Kubernetes cluster with KinD

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name kind-armadillo
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name kind-bison
}
```

<details>
<summary>Details</summary>

- Armadillo will set up Istio IngressGateway with 32001 NodePort
- Bison will set up Istio IngressGateway with 32002 NodePort

</details>

---

### 2. Install Istio into clusters

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    istioctl install --context kind-kind-armadillo -f clusters/armadillo/istioctl-input.yaml
    istioctl install --context kind-kind-bison -f clusters/bison/istioctl-input.yaml
}
```

<details>
<summary>Details</summary>

- Armadillo will set up Istio IngressGateway with 32001 NodePort
- Bison will set up Istio IngressGateway with 32002 NodePort

</details>

---
