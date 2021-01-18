# KinD-bsed Setup - Light

This is a light setup documentation, which should require less machine spec and resource.

For the default setup, the [default README.md] has more detailed information on how the setup is done.

[default readme.md]: https://github.com/rytswd/get-istio-multicluster/tree/main/docs/kind-based/README.md

## 🐾 Steps

### 0. Clone this repository

```bash
$ pwd
/some/path/at

$ git clone https://github.com/rytswd/get-istio-multicluster.git
```

From here on, all the steps are assumed to be run from `/some/path/at/get-istio-multicluster`.

---

### 1. Start local Kubernetes clusters with KinD

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name armadillo
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name bison
}
```

---

### 2. Prepare CA Certs

The steps are detailed at [Certificate Preparation steps](https://github.com/rytswd/get-istio-multicluster/tree/main/docs/cert-prep/README.md).

You need to complete this step before installing Istio to the cluster. Essentially, you need to run the following:

```bash
{
    pushd certs > /dev/null
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts

    popd > /dev/null

    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem
}
```

---

### 3. Install Istio Control Plane into Clusters

```bash
{
    istioctl install --context kind-armadillo \
        -f clusters/armadillo/istio-setup/istio-control-plane.yaml

    istioctl install --context kind-bison \
        -f clusters/bison/istio-setup/istio-control-plane.yaml
}
```

---

### 4. Install Istio Data Plane (i.e. Gateways) into Clusters

```bash
{
    PATH="$HOME/Coding/bin/istio-1.7.5/bin:$PATH"
    istioctl install --context kind-armadillo \
        -f clusters/armadillo/istio-setup/istio-external-gateways.yaml
    istioctl install --context kind-armadillo \
        -f clusters/armadillo/istio-setup/istio-multicluster-gateways.yaml

    istioctl install --context kind-armadillo \
        -f clusters/armadillo/istio-setup/istio-external-gateways.yaml
    istioctl install --context kind-armadillo \
        -f clusters/armadillo/istio-setup/istio-multicluster-gateways.yaml
}
```

---

### 5. Install Debug Processes

```bash
{
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

---

### 6. Apply Istio Custom Resources

Each cluster has different resources. Check out the documentation one by one.

<details>
<summary>For Armadillo</summary>

#### 6.1. Add `istiocoredns` as a part of CoreDNS ConfigMap

```bash
{
    export ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-armadillo \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    echo $ARMADILLO_ISTIOCOREDNS_CLUSTER_IP
}
```

```sh
# OUTPUT
10.xx.xx.xx
```

```bash
{
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/armadillo/coredns-configmap.yaml
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/armadillo-services.yaml \
        -f clusters/armadillo/coredns-configmap.yaml
}
```

```sh
# OUTPUT
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
configmap/coredns configured
```

<details>
<summary>Details</summary>

Istio's `istiocoredns` handles DNS lookup, and thus, you need to let Kubernetes know that `istiocoredns` gets the DNS request. Get the K8s Service cluster IP in `ARMADILLO_ISTIOCOREDNS_CLUSTER_IP` env variable, so that you can use that in `coredns-configmap.yaml` as the endpoint.

This will then be applied to `kube-system/coredns` ConfigMap. As KinD comes with CoreDNS as the default DNS and its own ConfigMap, you will see a warning about the original ConfigMap being overridden with the custom one. This is fine for testing, but you may want to carefully examine the DNS setup as that could have significant impact.

</details>

---

#### 6.2. Add ServiceEntry for Bison

Before completing this, make sure the cluster Bison is also started, and has completed Istio installation.

```bash
{
    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    echo $ARMADILLO_EGRESS_GATEWAY_ADDRESS
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
}
```

```sh
# OUTPUT
10.xx.xx.xx
```

```bash
{
    export BISON_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-bison \
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
```

```sh
# OUTPUT
172.18.0.1
```

```bash
kubectl apply --context kind-armadillo \
    -f clusters/armadillo/bison-connections.yaml
```

```sh
# OUTPUT
serviceentry.networking.istio.io/bison-services created
```

<details>
<summary>Details</summary>

**WARNING**: The current setup does NOT go through EgressGateway, and simply skips it. This needs further investigation.

There are 2 places that are being updated in a single file `clusters/armadillo/bison-connections.yaml`. The first one is for Armadillo's EgressGateway, and the second is for Bison's IngressGateway. This means the traffic follows the below pattern.

```
[ Armadillo Cluster]                                  Cluster Border                                         [ Bison Cluster]
                                                             |
App Container A ==> Istio Sidecar Proxy ==> Egress Gateway ==|==> Ingress Gateway ==> Istio Sidecar Proxy ==> App Container B
                                                             |
```

This means that, when you need App Container A to talk to App Container B on the other cluster, you need to provide 2 endpoints.

In order for 2 KinD clusters to talk to each other, the extra `sed` takes place to fallback to use `172.18.0.1` as endpoint address (which is a mapping outside of cluster), and because Bison's Ingress Gateway is set up with NodePort of `32002`, we replace the default port of `15443` with `32002`.

The command may look confusing, but the update is simple. If you cloned this repo at the step 0, you can easily see from git diff.

</details>

---

</details>

<details>
<summary>For Bison</summary>

```bash
kubectl apply --context kind-bison \
    -f clusters/bison/bison-services.yaml \
    -f clusters/bison/multicluster-setup.yaml
```

If you are using Istio v1.6, you will get an error from the above. You need to run the following command:

```bash
kubectl apply --context kind-bison \
    -f clusters/bison/multicluster-setup-1.6.yaml
```

<details>
<summary>Details</summary>

To be updated

</details>

</details>

---

### 7. Verify

Simple curl to verify connection

```bash
kubectl exec \
    --context kind-armadillo \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -l app=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- curl -vvv httpbin.default.bison.global:8000/status/418
```

Interactive shell from Armadillo cluster

```bash
kubectl exec \
    --context kind-armadillo \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -l app=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- bash
```

For logs

```bash
kubectl logs \
    --context kind-armadillo \
    $(kubectl get pod \
        --context kind-armadillo \
        -l app=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c istio-proxy \
    | less
```

---

## ⚡️ Quicker Paralllel Steps

The below will be quicker than above if you use multiple terminals to run them in parallel.

<details>
<summary>Details</summary>

### Prep - run before all

```bash
{
    pushd certs > /dev/null

    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts

    popd > /dev/null
}
```

### Bison

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name bison

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem

    istioctl install --context kind-bison -f clusters/bison/istioctl-input.yaml

    kubectl label --context kind-bison namespace default istio-injection=enabled
    kubectl apply --context kind-bison \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl apply --context kind-bison \
        -f clusters/bison/bison-services.yaml \
        -f clusters/bison/multicluster-setup.yaml
}
```

### Armadillo

**NOTE**: Armadillo has a dependency to Bison, so set it up first.

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name armadillo

    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem

    istioctl install --context kind-armadillo -f clusters/armadillo/istioctl-input.yaml

    kubectl label --context kind-armadillo namespace default istio-injection=enabled
    kubectl apply --context kind-armadillo \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    export ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-armadillo \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/armadillo/coredns-configmap.yaml
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/armadillo-services.yaml \
        -f clusters/armadillo/coredns-configmap.yaml

    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
    export BISON_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-bison \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
    if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
        sed -i '' -e "s/15443 # Istio Ingress Gateway port/32002/" \
            clusters/armadillo/bison-connections.yaml
    fi
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/bison-connections.yaml
}
```

</details>

---

## 🧹 Cleanup

```bash
{
    rm -rf certs
    git reset --hard
    kind delete cluster --name armadillo
    kind delete cluster --name bison
}
```
