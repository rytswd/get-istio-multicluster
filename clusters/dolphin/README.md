# Cluster `dolphin`

## Prep

For the detailed steps of how these files are used, please check out [KinD based setup](https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/kind-based/README.md).

## Configuration Files

### `dolphin-services.yaml`

This file contains VirtualService definitions for Services within the cluster, as well as external service.

### `multicluster-setup.yaml`

This file contains Istio Ingress Gateway configuration, which are fine-tuned to work when mulitple Ingress Gateways are configured.

### `coredns-configmap.yaml` - TO BE ADDED

This is for multicluster DNS routing. Sets up `kube-system/coredns` with `istiocoredns`.

### `istioctl-input.yaml`

This is used for `istioctl install` input.
