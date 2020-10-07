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
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name armadillo
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name bison
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
    istioctl install --context kind-armadillo -f clusters/armadillo/istioctl-input.yaml
    istioctl install --context kind-bison -f clusters/bison/istioctl-input.yaml
}
```

<details>
<summary>Details</summary>

Install Istio into each cluster.

</details>

---

### 3. Install Debug Processes

```bash
$ {
    kubectl label --context kind-armadillo namespace default istio-injection=enabled
    kubectl apply --context kind-armadillo -f tools/httpbin/httpbin.yaml
    kubectl apply --context kind-armadillo -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl label --context kind-bison namespace default istio-injection=enabled
    kubectl apply --context kind-bison -f tools/httpbin/httpbin.yaml
    kubectl apply --context kind-bison -f tools/toolkit-alpine/toolkit-alpine.yaml
}
```

<details>
<summary>Details</summary>

- Armadillo will set up Istio IngressGateway with 32001 NodePort
- Bison will set up Istio IngressGateway with 32002 NodePort

</details>

---

## Cleanup

```bash
$ {
    kind delete cluster --name armadillo
    kind delete cluster --name bison
}
```

<details>
<summary>Details</summary>

- Armadillo will set up Istio IngressGateway with 32001 NodePort
- Bison will set up Istio IngressGateway with 32002 NodePort

</details>

---
