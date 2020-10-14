# Cluster `armadillo`

## Prep

The below steps are only copied from [KinD based setup](https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/kind-based/README.md).

<details>
<summary>Steps</summary>

### Start up cluster

If you are testing with KinD, you can run the following command:

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ kind create cluster --config ./tools/kind-config/config-2-nodes.yaml --name armadillo
```

### Install Istio

Using `istioctl-input.yaml`, install Istio to the cluster.

```bash
$ istioctl install --context kind-armadillo -f clusters/armadillo/istioctl-input.yaml
```

Before proceeding to the next step, all of the Istio components must be up and running.

</details>

## Steps

### 1. Add `istiocoredns` as a part of CoreDNS ConfigMap

```bash
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

To be updated

</details>

---

### 2. Add ServiceEntry for Bison

Before completing this, make sure the cluster Bison is also started, and has completed Istio installation.

```bash
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
