# Simple Istio Multicluster

Istio Multicluster is by no means simple. This repository tries to showcase with the following:

- Simple configurations
- Simple processes / containers
- Simple steps to reproduce

But as this repository aims to provide complex scenarios and how Istio can handle them, you will also find:

- Involved cluster / mesh setup
- Detailed description on each step

## Versions

This repository is tested with the following versions of Istio:

- v1.6.8
- v1.7.3

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
