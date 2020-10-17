# KinD based setup

## Prerequisites

- Docker
- [KinD](https://kind.sigs.k8s.io/)

## Steps

### 1. Start local Kubernetes clusters with KinD

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

### 2. Prepare CA Certs

The steps are detailed at [Certificate Preparation steps](https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/cert-prep/README.md).

You need to complete this step before installing Istio to the cluster. Essentially, you need to run the following:

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    pushd certs
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts

    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./armadillo/ca-cert.pem \
        --from-file=./armadillo/ca-key.pem \
        --from-file=./armadillo/root-cert.pem \
        --from-file=./armadillo/cert-chain.pem

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./bison/ca-cert.pem \
        --from-file=./bison/ca-key.pem \
        --from-file=./bison/root-cert.pem \
        --from-file=./bison/cert-chain.pem

    popd
}
```

<details>
<summary>Details</summary>

If you do not create the certificate before Istio is installed to the cluster, Istio will fall back to use its own certificate. This will cause an issue when you try to use your custom cert later on. It's best to get the cert ready first - otherwise you will likely need to run through a bunch of restarts of Istio components to ensure the correct cert is picked up.

</details>

---

### 3. Install Istio into clusters

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

### 4. Install Debug Processes

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

### 5. Apply Istio Custom Resources

Each cluster has different resources. Check out the documentation one by one.

<details>
<summary>For Armadillo</summary>

#### 5.1. Add `istiocoredns` as a part of CoreDNS ConfigMap

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    export ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-armadillo \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    echo $ARMADILLO_ISTIOCOREDNS_CLUSTER_IP
}

10.xx.xx.xx

$ {
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/armadillo/coredns-configmap.yaml
    kubectl apply --context kind-armadillo -f clusters/armadillo/coredns-configmap.yaml
}

Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
configmap/coredns configured
```

<details>
<summary>Details</summary>

Istio's `istiocoredns` handles DNS lookup, and thus, you need to let Kubernetes know that `istiocoredns` gets the DNS request. Get the K8s Service cluster IP in `ARMADILLO_ISTIOCOREDNS_CLUSTER_IP` env variable, so that you can use that in `coredns-configmap.yaml` as the endpoint.

This will then applied to `kube-system/coredns` ConfigMap. As KinD comes with CoreDNS as the default DNS and its own ConfigMap, you will see a warning about the original ConfigMap being overridden with the custom one.

</details>

---

#### 5.2. Add ServiceEntry for Bison

Before completing this, make sure the cluster Bison is also started, and has completed Istio installation.

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=istio-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    echo $ARMADILLO_EGRESS_GATEWAY_ADDRESS
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
}

10.xx.xx.xx

$ {
    export BISON_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-kind-bison \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    echo $BISON_INGRESS_GATEWAY_ADDRESS
    {
        sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/armadillo/bison-connections.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32002/" \
                clusters/armadillo/bison-connections.yaml
        fi
    }
}

172.18.0.1

$ kubectl apply --context kind-armadillo \
    -f clusters/armadillo/armadillo-other-services.yaml \
    -f clusters/armadillo/bison-connections.yaml

serviceentry.networking.istio.io/bison-services created
```

<details>
<summary>Details</summary>

To be updated

</details>

---

</details>

<details>
<summary>For Bison</summary>

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ kubectl apply --context kind-bison \
    -f clusters/bison/bison-virtual-service.yaml \
    -f clusters/bison/bison-exposed-services.yaml
```

<details>
<summary>Details</summary>

To be updated

</details>

</details>

---

## Quicker Guide

The below will be quicker than above if you use multiple terminals to run them in parallel.

<details>
<summary>Details</summary>

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
