# Cluster `armadillo`

## Prep

For the detailed steps of how these files are used, please check out [KinD based setup](https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/kind-based/README.md).

## Configuration Files

### `armadillo-services.yaml`

This file contains VirtualService definitions for Services within the cluster, as well as external service.

### `bison-connections.yaml`

This file contains endpoint details of how to connect to Bison cluster.

### `dolphin-connections.yaml`

This file contains endpoint details of how to connect to Dolphin cluster.

### `coredns-configmap.yaml`

This is for multicluster DNS routing. Sets up `kube-system/coredns` with `istiocoredns`.

### `istioctl-input.yaml`

This is used for `istioctl install` input.
