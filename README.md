# Simple Istio Multicluster

Istio Multicluster is by no means simple, as there are so many features Istio provides. This repository tries to showcase some of Istio's capability with the following in mind:

- Simple configurations
- Simple processes / containers
- Simple steps to reproduce

But as this repository aims to provide practical use cases, you will also find:

- Involved cluster / mesh setup
- Detailed description on each step

> 📍 NOTE 📍
>
> This repository does not aim to be exhaustive by any means. Many of the examples are You are expected to be somewhat familiar with Istio's features.

## Contents

| Setup        | Istio Version | Description                                                            |
| ------------ | ------------- | ---------------------------------------------------------------------- |
| [KinD based] | 1.6<br />1.7  | Set up multiple KinD clusters, each having its own Istio Control Plane |
| Argo CD      | WIP           | WIP                                                                    |
| Public Cloud | WIP           | WIP                                                                    |

[kind based]: https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/kind-based/README.md

## Clusters

The clusters used in this repository are given easily identifiable names. They are not meant to convey any meaning.

For some cluster, there are some peculiarities over the others.

- `armadillo`: cluster with shared Istio Control Plane (with `crocodile`)
- `bison`: cluster with dedicated Istio Control Plane
- [WIP] `crocodile`: clustter with shared Istio Control Plane (with `armadillo`)
- [WIP] `dolphin`: cluster with dedicated Istio Control Plane
- [WIP] `zebra`: cluster without Istio, as external cluster
