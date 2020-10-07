# Cluster `bison`

## Setup Steps

### 0. Start up cluster

If you are testing with KinD, you can run the following command:

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ kind create cluster --config ./tools/kind-config/config-2-nodes.yaml --name bison
```

### 1. Install Istio

Using `istioctl-input.yaml`, install Istio to the cluster.

```bash
$ istioctl install --context kind-bison -f clusters/bison/istioctl-input.yaml
```

Before proceeding to the next step, all of the Istio components must be up and running.

### 2. Add `istiocoredns` as a part of CoreDNS ConfigMap

```bash
$ export BISON_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc --context kind-bison -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})
$ echo $BISON_ISTIOCOREDNS_CLUSTER_IP
10.xx.xx.xx

$ sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$BISON_ISTIOCOREDNS_CLUSTER_IP/" clusters/bison/coredns-configmap.yaml

$ kubectl create --context kind-bison -f clusters/bison/coredns-configmap.yaml
```

### 3. Add ServiceEntry for Armadillo

Before completing this, make sure the cluster Armadillo is also started, and has completed Istio installation.

```bash
$ export BISON_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
    --context=kind-bison \
    -n istio-system \
    --selector=app=istio-egressgateway \
    -o jsonpath='{.items[0].spec.clusterIP}')

$ sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$BISON_EGRESS_GATEWAY_ADDRESS/" clusters/bison/armadillo-service-entries.yaml

$ export ARMADILLO_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
    --context=kind-kind-armadillo \
    -n istio-system \
    --selector=app=istio-ingressgateway \
    -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '127.0.0.1')

$ {
    sed -i '' -e "s/REPLACE_WITH_ARMADILLO_INGRESS_GATEWAY_ADDRESS/$ARMADILLO_INGRESS_GATEWAY_ADDRESS/" clusters/bison/armadillo-service-entries.yaml
    if [[ $ARMADILLO_INGRESS_GATEWAY_ADDRESS == '127.0.0.1' ]]; then
        sed -i '' -e "s/15443 # Istio Ingress Gateway port/32002/" clusters/bison/armadillo-service-entries.yaml
    fi
}

$ kubectl apply -f clusters/bison/armadillo-service-entries.yaml
```
