# Simple Istio Multicluster

Istio Multicluster is by no means simple. This repository tries to show involved example with multiple key configurations used in Istio, but with simple steps to follow.

## Steps

- [KinD based setup](https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/kind-based/README.md)  
  This sets up multiple KinD clusters with each having some Istio installation.
- Argo CD based setup - WIP
- AWS EKS + GCP GKE based setup - WIP

## Clusters

The directories here are some clusters.

- `armadillo`: cluster with shared Istio Control Plane (with `crocodile`)
- `bison`: cluster with dedicated Istio Control Plane
- `crocodile`: clustter with shared Istio Control Plane (with `armadillo`)
- `dolphin`: cluster with dedicated Istio Control Plane
- `zebra`: cluster without Istio, as external cluster
