# k3d-bsed Setup

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
    make -f ../tools/certs/Makefile.selfsigned.mk dolphin-cacerts

    popd > /dev/null
}
```

### Bison

```bash
{
    k3d cluster create bison --agents 1 -p "32002:32002@agent[0]"

    kubectl create namespace --context k3d-bison istio-system
    kubectl create secret --context k3d-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem

    istioctl install --context k3d-bison -f clusters/bison/istioctl-input.yaml

    kubectl label --context k3d-bison namespace default istio-injection=enabled
    kubectl apply --context k3d-bison \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl apply --context k3d-bison \
        -f clusters/bison/bison-services.yaml \
        -f clusters/bison/multicluster-setup.yaml
}
```

If you are using Istio v1.6 or below, you would need to run the following command as EnvoyFilter change in 1.7 is not compatible.

```bash
{
    kubectl apply --context k3d-bison \
        -f clusters/bison/multicluster-setup-1.6.yaml
}
```

### Dolphin

```bash
{
    k3d cluster create dolphin --agents 1 -p "32004:32004@agent[0]"

    kubectl create namespace --context k3d-dolphin istio-system
    kubectl create secret --context k3d-dolphin \
        generic cacerts -n istio-system \
        --from-file=./certs/dolphin/ca-cert.pem \
        --from-file=./certs/dolphin/ca-key.pem \
        --from-file=./certs/dolphin/root-cert.pem \
        --from-file=./certs/dolphin/cert-chain.pem

    istioctl install --context k3d-dolphin -f clusters/dolphin/istioctl-input.yaml

    kubectl label --context k3d-dolphin namespace default istio-injection=enabled
    kubectl apply --context k3d-dolphin \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl apply --context k3d-dolphin \
        -f clusters/dolphin/dolphin-services.yaml \
        -f clusters/dolphin/multicluster-setup.yaml
}
```

If you are using Istio v1.6 or below, you would need to run the following command as EnvoyFilter change in 1.7 is not compatible.

```bash
{
    kubectl apply --context k3d-dolphin \
        -f clusters/dolphin/multicluster-setup-1.6.yaml
}
```

### Armadillo

**NOTE**: Armadillo has a dependency to Bison and Dolphin, so set up those clusters first.

```bash
{
    k3d cluster create armadillo --agents 1 -p "32001:32001@agent[0]"

    kubectl create namespace --context k3d-armadillo istio-system
    kubectl create secret --context k3d-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem

    istioctl install --context k3d-armadillo -f clusters/armadillo/istioctl-input.yaml

    kubectl label --context k3d-armadillo namespace default istio-injection=enabled
    kubectl apply --context k3d-armadillo \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    export ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context k3d-armadillo \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/armadillo/coredns-configmap.yaml
    kubectl apply --context k3d-armadillo \
        -f clusters/armadillo/armadillo-services.yaml \
        -f clusters/armadillo/coredns-configmap.yaml

    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=k3d-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
    export BISON_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=k3d-bison \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
    if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
        sed -i '' -e "s/15443 # Istio Ingress Gateway port/32002/" \
            clusters/armadillo/bison-connections.yaml
    fi
    kubectl apply --context k3d-armadillo \
        -f clusters/armadillo/bison-connections.yaml

    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=k3d-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/dolphin-connections.yaml
    export DOLPHIN_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=k3d-dolphin \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    sed -i '' -e "s/REPLACE_WITH_DOLPHIN_INGRESS_GATEWAY_ADDRESS/$DOLPHIN_INGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/dolphin-connections.yaml
    if [[ $DOLPHIN_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
        sed -i '' -e "s/15443 # Istio Ingress Gateway port/32004/" \
            clusters/armadillo/dolphin-connections.yaml
    fi
    kubectl apply --context k3d-armadillo \
        -f clusters/armadillo/dolphin-connections.yaml
}
```

</details>

---

## 🧹 Cleanup

```bash
{
    rm -rf certs
    git reset --hard
    k3d cluster delete armadillo
    k3d cluster delete bison
    k3d cluster delete dolphin
}
```

<details>
<summary>Details</summary>

To be updated

<!-- Remove the entire `certs` directory, and `git reset --hard` to remove all the changes.

KinD clusters can be deleted with `kind delete cluster` - and you can provide `--name` to specify one.

As the above steps creates multiple clusters, this step makes sure to delete all.

Because all the Istio components are inside KinD cluster, deleting the cluster will remove everything that was generated / configured / deployed. -->

</details>
