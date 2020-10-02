# Cluster `armadillo`

## Setup Steps

### 0. Start up cluster

If you are testing with KinD, you can run the following command:

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ kind create cluster --config ./tools/kind-config/config-2-nodes.yaml --name kind-armadillo
```

### 1. Install Istio

Using `istioctl-input.yaml`, install Istio to the cluster.

```bash
$ istioctl install --context kind-kind-armadillo -f clusters/armadillo/istioctl-input.yaml
```

Before proceeding to the next step, all of the Istio components must be up and running.

### 2. Add `istiocoredns` as a part of CoreDNS ConfigMap

```bash
$ export ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})
$ echo $ARMADILLO_ISTIOCOREDNS_CLUSTER_IP
10.xx.xx.xx

$ sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/"
```
