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

Install Istio into each cluster. Istio can be installed in a few ways, but `istioctl install` is the most standard way recommended by the official documentation. It is also possible to create a lengthy YAML definition, so that we can even have GitOps as a part of Istio installation.

As to the configurations, Armadillo and Bison have almost identical cluster setup. The main difference is the name used by various components (Ingress and Egress Gateways have `armadillo-` or `bison-` prefix). Also, as the previous step created the KinD cluster with different NodePort for Istio IngressGateway, you can see the corresponding port being used in `istioctl-input.yaml`.

</details>

---

### 3. Install Debug Processes

```bash
$ {
    kubectl label --context kind-armadillo namespace default istio-injection=enabled
    kubectl apply --context kind-armadillo \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl label --context kind-bison namespace default istio-injection=enabled
    kubectl apply --context kind-bison \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml
}
```

<details>
<summary>Details</summary>

There are 2 actions happening, and for 2 clusters (Armadillo and Bison).

Firstly, `kubectl label namespace default istio-injection=enabled` marks that namespace (in this case `default` namespace) as Istio Sidecar enabled. This means any Pod that gets created in this namespace will go through Istio's MutatingWebhook, and Istio's Sidecar component (`istio-proxy`) will be embedded into the same Pod. Without this setup, you will need to add Sidecar separately by running `istioctl` commands, which may be ok for testing, but certainly not scalable.

Second action is to install the testing tools. `httpbin` is a nice Web server which can handle incoming HTTP request and return arbitrary output based on the input path. `toolkit-alpine` is a lightweight container which has a few tools useful for testing, such as `curl`, `dig`, etc.

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

KinD clusters can be deleted with `kind delete cluster` - and you can provide `--name` to specify one.

As the above steps creates multiple clusters, this step makes sure to delete all.

Because all the Istio components are inside KinD cluster, deleting the cluster will remove everything that was generated / configured / deployed.

</details>

---

## Quicker Guide

The below will be quicker than above if you use multiple terminals to run them in parallel.

### Armadillo

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name armadillo
    istioctl install --context kind-armadillo -f clusters/armadillo/istioctl-input.yaml
    kubectl label --context kind-armadillo namespace default istio-injection=enabled
    kubectl apply --context kind-armadillo \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml
}
```

### Bison

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name bison
    istioctl install --context kind-bison -f clusters/bison/istioctl-input.yaml
    kubectl label --context kind-bison namespace default istio-injection=enabled
    kubectl apply --context kind-bison \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml
}
```
