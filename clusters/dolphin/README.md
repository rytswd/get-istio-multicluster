# Cluster `dolphin`

## Prep

For the detailed steps of how these files are used, please check out [KinD based setup](https://github.com/rytswd/get-istio-multicluster/tree/main/docs/kind-based/README.md).

## Configuration Files

### `dolphin-services.yaml`

This file contains VirtualService definitions for Services within the cluster, as well as external service.

### `multicluster-setup.yaml`

This file contains Istio Ingress Gateway configuration, which are fine-tuned to work when mulitple Ingress Gateways are configured.

### `multicluster-setup-1.6.yaml`

Because of breaking change for EnvoyFilter, when using Istio v1.6, you would need to use this file instead of `multicluster-setup.yaml` above.

### `coredns-configmap.yaml` - TO BE ADDED

This is for multicluster DNS routing. Sets up `kube-system/coredns` with `istiocoredns`.

### `istioctl-input.yaml`

This is used for `istioctl install` input.
